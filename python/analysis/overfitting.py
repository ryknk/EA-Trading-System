"""IS / OOS / Walk ForwardのパフォーマンスサマリーからEAの過学習疑いを診断する。

`python.analysis.reports` が出力する `performance-summary.json` の `metrics` を入力とし、
In-Sampleを基準にOut-of-SampleおよびWalk Forward各Foldの性能劣化率を計算する。
単一指標のみで過学習を断定せず、複数指標の劣化度合いをスコア化して総合判定する。
Final Holdout（2025-01〜2026-08）はパラメータ調整用ではないため、本モジュールの
判定対象（IS/OOS/Walk Forward比較）には含めない。
"""
from __future__ import annotations

import argparse
import json
import math
from dataclasses import asdict, dataclass, field, fields
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "1.0"

# 高いほど良い指標と、低いほど良い指標を分けて扱う。
_HIGHER_IS_BETTER = ("profit_factor", "sharpe_ratio", "expectancy", "net_profit")
_LOWER_IS_BETTER = ("max_drawdown_rate",)
EVALUATED_METRICS = _HIGHER_IS_BETTER + _LOWER_IS_BETTER

_SEVERITY_SCORE = {"HIGH": 2.0, "MODERATE": 1.0, "LOW": 0.0, "UNKNOWN": 0.0}
_CLASSIFICATION_RANK = {"LOW": 0, "MODERATE": 1, "HIGH": 2}


@dataclass(frozen=True)
class OverfittingThresholds:
    """過学習疑い判定の閾値。ハードコードせず設定可能にする。"""

    degradation_moderate_rate: float = 0.30
    degradation_high_rate: float = 0.50
    score_moderate: float = 2.0
    score_high: float = 5.0
    minimum_trade_count: int = 30
    # Max Drawdownなど、IS側の値がほぼゼロで相対劣化率が発散する場合の下限（絶対値の分母）
    drawdown_relative_floor: float = 0.05

    def __post_init__(self) -> None:
        if self.degradation_moderate_rate < 0 or self.degradation_high_rate < 0:
            raise ValueError("degradation thresholds must be non-negative")
        if self.degradation_high_rate < self.degradation_moderate_rate:
            raise ValueError("degradation_high_rate must be >= degradation_moderate_rate")
        if self.score_moderate < 0 or self.score_high < 0:
            raise ValueError("score thresholds must be non-negative")
        if self.score_high < self.score_moderate:
            raise ValueError("score_high must be >= score_moderate")
        if self.minimum_trade_count < 1:
            raise ValueError("minimum_trade_count must be at least 1")
        if self.drawdown_relative_floor <= 0:
            raise ValueError("drawdown_relative_floor must be positive")

    @staticmethod
    def from_dict(data: dict[str, Any]) -> "OverfittingThresholds":
        known = {item.name for item in fields(OverfittingThresholds)}
        unknown = set(data) - known
        if unknown:
            raise ValueError(f"unknown threshold keys: {sorted(unknown)}")
        return OverfittingThresholds(**data)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass(frozen=True)
class MetricComparison:
    metric: str
    in_sample_value: float | None
    comparison_value: float | None
    degradation_rate: float | None
    severity: str

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass(frozen=True)
class PeriodComparison:
    period: str
    in_sample_trade_count: int | None
    comparison_trade_count: int | None
    trade_count_sufficient: bool
    score: float
    max_score: float
    classification: str
    metric_comparisons: list[MetricComparison] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        result = asdict(self)
        result["metric_comparisons"] = [item.to_dict() for item in self.metric_comparisons]
        return result


@dataclass(frozen=True)
class OverfittingAssessment:
    schema_version: str
    generated_at: str
    classification: str
    reliability_warning: bool
    reasons: list[str]
    thresholds: dict[str, Any]
    oos: dict[str, Any] | None
    walk_forward_folds: list[dict[str, Any]]
    walk_forward_summary: dict[str, Any] | None

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


def _degradation_rate(
    metric: str, is_value: float | None, other_value: float | None, thresholds: OverfittingThresholds,
) -> float | None:
    if is_value is None or other_value is None:
        return None
    if not math.isfinite(is_value) or not math.isfinite(other_value):
        return None
    if metric in _LOWER_IS_BETTER:
        denominator = max(abs(is_value), thresholds.drawdown_relative_floor)
        return (other_value - is_value) / denominator
    if is_value == 0:
        return None
    return (is_value - other_value) / abs(is_value)


def _severity(degradation_rate: float | None, thresholds: OverfittingThresholds) -> str:
    if degradation_rate is None:
        return "UNKNOWN"
    if degradation_rate >= thresholds.degradation_high_rate:
        return "HIGH"
    if degradation_rate >= thresholds.degradation_moderate_rate:
        return "MODERATE"
    return "LOW"


def _classify_score(score: float, thresholds: OverfittingThresholds) -> str:
    if score >= thresholds.score_high:
        return "HIGH"
    if score >= thresholds.score_moderate:
        return "MODERATE"
    return "LOW"


def compare_period(
    period: str, in_sample_metrics: dict[str, Any], comparison_metrics: dict[str, Any],
    thresholds: OverfittingThresholds,
) -> PeriodComparison:
    comparisons = []
    for metric in EVALUATED_METRICS:
        is_value = in_sample_metrics.get(metric)
        other_value = comparison_metrics.get(metric)
        rate = _degradation_rate(metric, is_value, other_value, thresholds)
        comparisons.append(MetricComparison(
            metric=metric, in_sample_value=is_value, comparison_value=other_value,
            degradation_rate=rate, severity=_severity(rate, thresholds),
        ))
    score = sum(_SEVERITY_SCORE[item.severity] for item in comparisons)
    in_sample_count = in_sample_metrics.get("number_of_trades")
    comparison_count = comparison_metrics.get("number_of_trades")
    trade_count_sufficient = (
        in_sample_count is not None and comparison_count is not None
        and in_sample_count >= thresholds.minimum_trade_count
        and comparison_count >= thresholds.minimum_trade_count
    )
    return PeriodComparison(
        period=period, in_sample_trade_count=in_sample_count, comparison_trade_count=comparison_count,
        trade_count_sufficient=trade_count_sufficient, score=score,
        max_score=len(EVALUATED_METRICS) * 2.0, classification=_classify_score(score, thresholds),
        metric_comparisons=comparisons,
    )


def _reasons_for_period(result: PeriodComparison) -> list[str]:
    reasons = [
        f"{result.period}: 判定スコア {result.score:.1f}/{result.max_score:.1f} → {result.classification}",
    ]
    for comparison in result.metric_comparisons:
        if comparison.severity in ("MODERATE", "HIGH"):
            rate_text = "算出不能" if comparison.degradation_rate is None else f"{comparison.degradation_rate:.1%}"
            reasons.append(
                f"{result.period}/{comparison.metric}: IS={comparison.in_sample_value} → "
                f"{comparison.comparison_value} (劣化率{rate_text}, {comparison.severity})"
            )
    if not result.trade_count_sufficient:
        reasons.append(
            f"{result.period}: 取引数不足の疑い "
            f"(IS={result.in_sample_trade_count}, {result.period}={result.comparison_trade_count})"
        )
    return reasons


def assess_overfitting(
    in_sample_metrics: dict[str, Any],
    oos_metrics: dict[str, Any] | None = None,
    walk_forward_fold_metrics: list[tuple[str, dict[str, Any]]] | None = None,
    thresholds: OverfittingThresholds | None = None,
    generated_at: datetime | None = None,
) -> OverfittingAssessment:
    if oos_metrics is None and not walk_forward_fold_metrics:
        raise ValueError("at least one of oos_metrics or walk_forward_fold_metrics is required")
    thresholds = thresholds or OverfittingThresholds()

    reasons: list[str] = []
    classifications: list[str] = []
    reliability_warning = False

    oos_result: PeriodComparison | None = None
    if oos_metrics is not None:
        oos_result = compare_period("OOS", in_sample_metrics, oos_metrics, thresholds)
        reasons.extend(_reasons_for_period(oos_result))
        classifications.append(oos_result.classification)
        reliability_warning = reliability_warning or not oos_result.trade_count_sufficient

    fold_results: list[PeriodComparison] = []
    walk_forward_summary: dict[str, Any] | None = None
    if walk_forward_fold_metrics:
        for label, fold_metrics in walk_forward_fold_metrics:
            fold_result = compare_period(label, in_sample_metrics, fold_metrics, thresholds)
            fold_results.append(fold_result)
            reasons.extend(_reasons_for_period(fold_result))
            reliability_warning = reliability_warning or not fold_result.trade_count_sufficient
        mean_score = sum(item.score for item in fold_results) / len(fold_results)
        worst_result = max(fold_results, key=lambda item: item.score)
        wf_classification = _classify_score(mean_score, thresholds)
        classifications.append(wf_classification)
        walk_forward_summary = {
            "fold_count": len(fold_results),
            "mean_score": mean_score,
            "worst_fold": worst_result.period,
            "worst_fold_score": worst_result.score,
            "classification": wf_classification,
        }
        reasons.append(
            f"Walk Forward総合: {len(fold_results)}Fold平均スコア {mean_score:.1f}/"
            f"{fold_results[0].max_score:.1f} → {wf_classification} "
            f"(最悪Fold: {worst_result.period}, スコア {worst_result.score:.1f})"
        )

    if reliability_warning:
        classification = "INSUFFICIENT_DATA"
        reasons.append(
            f"取引数が閾値({thresholds.minimum_trade_count}件)未満の期間があるため、"
            "過学習判定の信頼性は低い。判定はINSUFFICIENT_DATAとする。"
        )
    else:
        classification = max(classifications, key=lambda item: _CLASSIFICATION_RANK[item])

    return OverfittingAssessment(
        schema_version=SCHEMA_VERSION,
        generated_at=(generated_at or datetime.now(UTC)).isoformat().replace("+00:00", "Z"),
        classification=classification, reliability_warning=reliability_warning, reasons=reasons,
        thresholds=thresholds.to_dict(),
        oos=None if oos_result is None else oos_result.to_dict(),
        walk_forward_folds=[item.to_dict() for item in fold_results],
        walk_forward_summary=walk_forward_summary,
    )


def _load_metrics(path: Path) -> dict[str, Any]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if "metrics" not in data:
        raise ValueError(f"performance-summary.json must contain 'metrics': {path}")
    return data["metrics"]


def _markdown(assessment: OverfittingAssessment) -> str:
    value = assessment.to_dict()
    lines = [
        "# 過学習疑い診断レポート", "",
        "本レポートは過学習を断定するものではなく、疑いを検出する診断である。",
        "Final Holdout期間は本判定に使用していない。", "",
        f"- 総合判定: **{value['classification']}**",
        f"- 判定信頼性の警告: {'あり（取引数不足）' if value['reliability_warning'] else 'なし'}",
        "", "## 判定理由", "",
    ]
    lines.extend(f"- {reason}" for reason in value["reasons"])
    lines.extend(["", "## 閾値設定", "", "```json", json.dumps(value["thresholds"], ensure_ascii=False, indent=2), "```", ""])
    if value["oos"] is not None:
        lines.extend(["## OOS比較", "", "```json", json.dumps(value["oos"], ensure_ascii=False, indent=2), "```", ""])
    if value["walk_forward_folds"]:
        lines.extend([
            "## Walk Forward比較", "",
            "```json", json.dumps(value["walk_forward_folds"], ensure_ascii=False, indent=2), "```", "",
            "```json", json.dumps(value["walk_forward_summary"], ensure_ascii=False, indent=2), "```", "",
        ])
    return "\n".join(lines)


def write_report(output_directory: Path, assessment: OverfittingAssessment) -> dict[str, Path]:
    output_directory.mkdir(parents=True, exist_ok=True)
    paths = {
        "json": output_directory / "overfitting-assessment.json",
        "markdown": output_directory / "overfitting-report.md",
    }
    paths["json"].write_text(
        json.dumps(assessment.to_dict(), ensure_ascii=False, indent=2, allow_nan=False) + "\n", encoding="utf-8",
    )
    paths["markdown"].write_text(_markdown(assessment), encoding="utf-8")
    return paths


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="IS/OOS/Walk Forwardバックテスト結果から過学習疑いを診断する")
    parser.add_argument("--in-sample", type=Path, required=True, help="In-Sampleのperformance-summary.json")
    parser.add_argument("--oos", type=Path, help="Out-of-Sampleのperformance-summary.json")
    parser.add_argument(
        "--walk-forward-fold", action="append", default=[],
        help="LABEL=performance-summary.jsonの形式。複数指定可（例: FOLD1=results/fold1/performance-summary.json）",
    )
    parser.add_argument("--thresholds-json", type=Path, help="閾値を上書きするJSONファイル")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(argv)

    in_sample_metrics = _load_metrics(args.in_sample)
    oos_metrics = _load_metrics(args.oos) if args.oos else None

    fold_metrics: list[tuple[str, dict[str, Any]]] = []
    for entry in args.walk_forward_fold:
        if "=" not in entry:
            raise ValueError(f"--walk-forward-fold must be LABEL=PATH: {entry}")
        label, raw_path = entry.split("=", 1)
        fold_metrics.append((label, _load_metrics(Path(raw_path))))

    thresholds = OverfittingThresholds()
    if args.thresholds_json:
        thresholds = OverfittingThresholds.from_dict(json.loads(args.thresholds_json.read_text(encoding="utf-8")))

    assessment = assess_overfitting(in_sample_metrics, oos_metrics, fold_metrics or None, thresholds)
    write_report(args.output, assessment)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
