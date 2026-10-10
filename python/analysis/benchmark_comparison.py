"""EAの成績をベンチマーク（MSCI ACWI 配当込み・円換算）と比較し、Release Gateのベンチマーク受入基準を判定する。

基準の正本は`docs/release-gate.md`「ベンチマーク受入基準」（`DECISIONS.md` DEC-041）である。

- 月・暦年はAsia/Tokyoで区切る（国内の課税年度と、円建てベンチマークの月末基準に合わせるため）。
- EAの月次収益率は、決済済み取引の損益（手数料・スワップ込み）を月初の実現残高で割って算出する。
  複数ケースの取引は、ケースごとに算出された口座通貨建て損益をそのまま1口座へ合算する。
- EAは暦年ごとの純利益へ課税し、損失は翌年以降3年間繰り越して控除する。期間末の途中年も、
  その時点までの利益へ課税する。繰越控除しきれなかった損失は価値ゼロとして扱う。
- ベンチマークは期間中は課税せず、期間末に全額売却したものとして譲渡益へ課税する。
- Sharpe比は税引き前の月次収益率（リスクフリーレート0、標本標準偏差、年率化係数sqrt(12)）から算出する。
"""

from __future__ import annotations

import argparse
import json
import math
import re
from dataclasses import asdict, dataclass
from datetime import UTC, date, datetime
from pathlib import Path
from typing import Any

import pandas as pd

from .reports import load_analysis_inputs

TAX_RATE = 0.20315
LOSS_CARRYFORWARD_YEARS = 3
MONTHS_PER_YEAR = 12
TAX_TIMEZONE = "Asia/Tokyo"
DEFAULT_BENCHMARK_NAME = "MSCI ACWI (配当込み・円換算)"
MONTH_PATTERN = re.compile(r"^\d{4}-(0[1-9]|1[0-2])$")


@dataclass(frozen=True)
class MonthlyReturn:
    month: str
    return_rate: float


@dataclass(frozen=True)
class TaxYear:
    year: int
    pre_tax_return: float
    wealth_start: float
    gain: float
    carryforward_used: float
    taxable_income: float
    tax: float
    wealth_end: float
    carryforward_remaining: list[dict[str, float]]


@dataclass(frozen=True)
class ReturnMetrics:
    months: int
    pre_tax_cagr: float
    after_tax_cagr: float
    after_tax_ending_multiple: float
    total_tax: float
    sharpe_ratio: float | None


@dataclass(frozen=True)
class PeriodComparison:
    label: str
    start_month: str
    end_month: str
    initial_balance: float
    number_of_trades: int
    ea: ReturnMetrics
    benchmark: ReturnMetrics
    ea_tax_years: list[TaxYear]
    ea_monthly_returns: list[MonthlyReturn]
    benchmark_monthly_returns: list[MonthlyReturn]
    after_tax_cagr_exceeds_benchmark: bool
    sharpe_exceeds_benchmark: bool
    criteria_met: bool

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


def _parse_month(value: str) -> pd.Period:
    if not MONTH_PATTERN.match(value):
        raise ValueError(f"month must be YYYY-MM: {value}")
    return pd.Period(value, freq="M")


def month_range(start: str, end: str) -> list[str]:
    first = _parse_month(start)
    last = _parse_month(end)
    if last < first:
        raise ValueError("end month must not precede start month")
    return [str(period) for period in pd.period_range(first, last, freq="M")]


def _require_finite(value: float, name: str) -> None:
    if not math.isfinite(value):
        raise ValueError(f"{name} must be finite")


def ea_monthly_returns(trades: pd.DataFrame, initial_balance: float, months: list[str]) -> list[MonthlyReturn]:
    """決済済み取引を東京時間の月へ集計し、月初の実現残高に対する収益率へ変換する。"""
    _require_finite(initial_balance, "initial_balance")
    if initial_balance <= 0:
        raise ValueError("initial_balance must be positive")
    close_months = trades["close_time"].dt.tz_convert(TAX_TIMEZONE).dt.strftime("%Y-%m")
    outside = sorted(set(close_months) - set(months))
    if outside:
        raise ValueError(f"trades closed outside the evaluation period: {outside[:3]}")
    pnl_by_month = trades.groupby(close_months)["net_pnl"].sum()
    equity = initial_balance
    result: list[MonthlyReturn] = []
    for month in months:
        pnl = float(pnl_by_month.get(month, 0.0))
        result.append(MonthlyReturn(month, pnl / equity))
        equity += pnl
        if equity <= 0:
            raise ValueError("realized equity reached zero or below")
    return result


def load_benchmark_levels(path: Path) -> dict[str, float]:
    frame = pd.read_csv(path, dtype={"month": str})
    if list(frame.columns) != ["month", "level"]:
        raise ValueError("benchmark CSV columns must be month,level")
    levels: dict[str, float] = {}
    for month, level in zip(frame["month"], frame["level"], strict=True):
        _parse_month(str(month))
        value = float(level)
        _require_finite(value, "benchmark level")
        if value <= 0:
            raise ValueError("benchmark level must be positive")
        if month in levels:
            raise ValueError(f"duplicate benchmark month: {month}")
        levels[str(month)] = value
    return levels


def benchmark_monthly_returns(levels: dict[str, float], months: list[str], annual_fee: float) -> list[MonthlyReturn]:
    """月末値の変化率から、信託報酬（年率）を月割りで控除した月次収益率を算出する。"""
    _require_finite(annual_fee, "annual_fee")
    if not 0.0 <= annual_fee < 1.0:
        raise ValueError("annual_fee must be in [0, 1)")
    base_month = str(_parse_month(months[0]) - 1)
    missing = [month for month in [base_month, *months] if month not in levels]
    if missing:
        raise ValueError(f"benchmark levels are missing: {missing[:3]}")
    monthly_fee_factor = (1.0 - annual_fee) ** (1.0 / MONTHS_PER_YEAR)
    result: list[MonthlyReturn] = []
    previous = levels[base_month]
    for month in months:
        current = levels[month]
        result.append(MonthlyReturn(month, current / previous * monthly_fee_factor - 1.0))
        previous = current
    return result


def _compound(returns: list[MonthlyReturn]) -> float:
    multiple = 1.0
    for item in returns:
        multiple *= 1.0 + item.return_rate
    return multiple


def _annualize(multiple: float, months: int) -> float:
    if multiple <= 0:
        return -1.0
    return multiple ** (MONTHS_PER_YEAR / months) - 1.0


def monthly_sharpe(returns: list[MonthlyReturn]) -> float | None:
    if len(returns) < 2:
        return None
    series = pd.Series([item.return_rate for item in returns], dtype=float)
    standard_deviation = float(series.std(ddof=1))
    if standard_deviation == 0.0 or not math.isfinite(standard_deviation):
        return None
    return float(series.mean() / standard_deviation * math.sqrt(MONTHS_PER_YEAR))


def apply_annual_tax(returns: list[MonthlyReturn]) -> list[TaxYear]:
    """暦年ごとの純利益へ課税し、損失を翌年以降3年間繰り越す（EA側）。資産1.0を起点に計算する。"""
    yearly: dict[int, float] = {}
    for item in returns:
        year = int(item.month[:4])
        yearly[year] = yearly.get(year, 1.0) * (1.0 + item.return_rate)
    wealth = 1.0
    carryforward: list[tuple[int, float]] = []
    result: list[TaxYear] = []
    for year, multiple in sorted(yearly.items()):
        carryforward = [(origin, loss) for origin, loss in carryforward if year - origin <= LOSS_CARRYFORWARD_YEARS]
        wealth_start = wealth
        gain = wealth_start * (multiple - 1.0)
        used = 0.0
        if gain > 0:
            remaining_gain = gain
            updated: list[tuple[int, float]] = []
            for origin, loss in carryforward:
                applied = min(loss, remaining_gain)
                remaining_gain -= applied
                used += applied
                if loss - applied > 0:
                    updated.append((origin, loss - applied))
            carryforward = updated
        elif gain < 0:
            carryforward.append((year, -gain))
        taxable = max(0.0, gain - used)
        tax = taxable * TAX_RATE
        wealth = wealth_start + gain - tax
        result.append(TaxYear(
            year=year, pre_tax_return=multiple - 1.0, wealth_start=wealth_start, gain=gain,
            carryforward_used=used, taxable_income=taxable, tax=tax, wealth_end=wealth,
            carryforward_remaining=[{"origin_year": origin, "loss": loss} for origin, loss in carryforward],
        ))
    return result


def ea_metrics(returns: list[MonthlyReturn]) -> tuple[ReturnMetrics, list[TaxYear]]:
    tax_years = apply_annual_tax(returns)
    ending = tax_years[-1].wealth_end
    metrics = ReturnMetrics(
        months=len(returns), pre_tax_cagr=_annualize(_compound(returns), len(returns)),
        after_tax_cagr=_annualize(ending, len(returns)), after_tax_ending_multiple=ending,
        total_tax=sum(item.tax for item in tax_years), sharpe_ratio=monthly_sharpe(returns),
    )
    return metrics, tax_years


def benchmark_metrics(returns: list[MonthlyReturn]) -> ReturnMetrics:
    """期間末に全額売却したものとして、譲渡益だけへ課税する（課税繰延を反映）。"""
    multiple = _compound(returns)
    tax = max(0.0, multiple - 1.0) * TAX_RATE
    ending = multiple - tax
    return ReturnMetrics(
        months=len(returns), pre_tax_cagr=_annualize(multiple, len(returns)),
        after_tax_cagr=_annualize(ending, len(returns)), after_tax_ending_multiple=ending,
        total_tax=tax, sharpe_ratio=monthly_sharpe(returns),
    )


def compare_period(
    label: str,
    trades: pd.DataFrame,
    initial_balance: float,
    start_month: str,
    end_month: str,
    benchmark_levels: dict[str, float],
    benchmark_annual_fee: float,
) -> PeriodComparison:
    months = month_range(start_month, end_month)
    ea_returns = ea_monthly_returns(trades, initial_balance, months)
    bench_returns = benchmark_monthly_returns(benchmark_levels, months, benchmark_annual_fee)
    ea, tax_years = ea_metrics(ea_returns)
    benchmark = benchmark_metrics(bench_returns)
    cagr_ok = ea.after_tax_cagr > benchmark.after_tax_cagr
    # Sharpe比が算出不能な場合は、上回ったと判断できないため不合格とする。
    sharpe_ok = (
        ea.sharpe_ratio is not None and benchmark.sharpe_ratio is not None
        and ea.sharpe_ratio > benchmark.sharpe_ratio
    )
    return PeriodComparison(
        label=label, start_month=start_month, end_month=end_month,
        initial_balance=float(initial_balance), number_of_trades=int(len(trades)),
        ea=ea, benchmark=benchmark, ea_tax_years=tax_years,
        ea_monthly_returns=ea_returns, benchmark_monthly_returns=bench_returns,
        after_tax_cagr_exceeds_benchmark=cagr_ok, sharpe_exceeds_benchmark=sharpe_ok,
        criteria_met=cagr_ok and sharpe_ok,
    )


def resolve_trade_inputs(paths: list[Path]) -> list[Path]:
    """ディレクトリ指定時は、配下の`trades-normalized.csv`（複数ケース実行の出力）をすべて対象にする。"""
    resolved: list[Path] = []
    for path in paths:
        if path.is_dir():
            found = sorted(path.rglob("trades-normalized.csv"))
            if not found:
                raise ValueError(f"trades-normalized.csv not found under {path}")
            resolved.extend(found)
        else:
            resolved.append(path)
    return resolved


def build_report(
    comparisons: list[PeriodComparison],
    benchmark_name: str,
    benchmark_source: str,
    benchmark_retrieved_on: date,
    benchmark_annual_fee: float,
    generated_at: datetime | None = None,
) -> dict[str, Any]:
    if not comparisons:
        raise ValueError("at least one period is required")
    return {
        "schema_version": "1.0",
        "generated_at": (generated_at or datetime.now(UTC)).isoformat().replace("+00:00", "Z"),
        "currency": "JPY",
        "benchmark": {
            "name": benchmark_name, "source": benchmark_source,
            "retrieved_on": benchmark_retrieved_on.isoformat(), "annual_fee": benchmark_annual_fee,
        },
        "definitions": {
            "criteria": "税引き後CAGRとSharpe比の両方がベンチマークを上回ること（全期間で必須）",
            "month_boundary": TAX_TIMEZONE,
            "ea_monthly_return": "決済済み取引損益（手数料・スワップ込み）÷月初の実現残高。複数ケースは損益を1口座へ合算",
            "benchmark_monthly_return": "月末値の変化率から信託報酬（年率）を月割りで控除",
            "ea_tax": f"暦年ごとの純利益へ{TAX_RATE}、損失は翌年以降{LOSS_CARRYFORWARD_YEARS}年間繰越控除",
            "benchmark_tax": f"期間末に全額売却したものとして譲渡益へ{TAX_RATE}",
            "sharpe": "税引き前の月次収益率、リスクフリーレート0、標本標準偏差、年率化係数sqrt(12)",
        },
        "periods": [comparison.to_dict() for comparison in comparisons],
        "criteria_met": all(comparison.criteria_met for comparison in comparisons),
    }


def _percent(value: float | None) -> str:
    return "算出不能" if value is None else f"{value:.2%}"


def _number(value: float | None) -> str:
    return "算出不能" if value is None else f"{value:.4f}"


def _markdown(report: dict[str, Any]) -> str:
    benchmark = report["benchmark"]
    lines = [
        "# ベンチマーク比較レポート", "",
        f"- 総合判定: {'合格' if report['criteria_met'] else '不合格'}",
        f"- ベンチマーク: {benchmark['name']}",
        f"- データ源: {benchmark['source']}（取得日 {benchmark['retrieved_on']}）",
        f"- 控除した信託報酬（年率）: {benchmark['annual_fee']:.4%}", "",
    ]
    for period in report["periods"]:
        ea, bench = period["ea"], period["benchmark"]
        lines += [
            f"## {period['label']}（{period['start_month']}〜{period['end_month']}）", "",
            f"- 判定: {'合格' if period['criteria_met'] else '不合格'}（取引数 {period['number_of_trades']}、"
            f"初期資金 {period['initial_balance']:,.0f}円）", "",
            "| 指標 | EA | ベンチマーク | EAが上回る |", "|---|---:|---:|---|",
            f"| 税引き前CAGR | {_percent(ea['pre_tax_cagr'])} | {_percent(bench['pre_tax_cagr'])} | - |",
            f"| 税引き後CAGR | {_percent(ea['after_tax_cagr'])} | {_percent(bench['after_tax_cagr'])} | "
            f"{'はい' if period['after_tax_cagr_exceeds_benchmark'] else 'いいえ'} |",
            f"| Sharpe比 | {_number(ea['sharpe_ratio'])} | {_number(bench['sharpe_ratio'])} | "
            f"{'はい' if period['sharpe_exceeds_benchmark'] else 'いいえ'} |", "",
            "EAの年次課税（資産は期間開始時を1.0とした倍率）:", "",
            "| 年 | 税引き前収益率 | 損益 | 繰越控除 | 課税所得 | 税額 | 年末資産 |",
            "|---|---:|---:|---:|---:|---:|---:|",
        ]
        for year in period["ea_tax_years"]:
            lines.append(
                f"| {year['year']} | {_percent(year['pre_tax_return'])} | {year['gain']:.4f} | "
                f"{year['carryforward_used']:.4f} | {year['taxable_income']:.4f} | {year['tax']:.4f} | "
                f"{year['wealth_end']:.4f} |"
            )
        lines += ["", f"ベンチマークの期間末課税: {bench['total_tax']:.4f}（税引き後資産 {bench['after_tax_ending_multiple']:.4f}）", ""]
    return "\n".join(lines)


def write_report(output_directory: Path, report: dict[str, Any]) -> dict[str, Path]:
    output_directory.mkdir(parents=True, exist_ok=True)
    paths = {
        "json": output_directory / "benchmark-comparison.json",
        "markdown": output_directory / "benchmark-comparison.md",
    }
    paths["json"].write_text(
        json.dumps(report, ensure_ascii=False, indent=2, allow_nan=False) + "\n", encoding="utf-8",
    )
    paths["markdown"].write_text(_markdown(report), encoding="utf-8")
    return paths


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="EAとベンチマークの税引き後CAGR・Sharpe比の比較")
    parser.add_argument("--period", nargs=3, action="append", required=True, metavar=("LABEL", "START", "END"),
                        help="評価期間（START/ENDはYYYY-MM、両端を含む）。複数指定可")
    parser.add_argument("--input", nargs=2, action="append", required=True, metavar=("LABEL", "PATH"),
                        help="期間LABELの取引CSV・監査JSONL、またはtrades-normalized.csvを含むディレクトリ。複数指定可")
    parser.add_argument("--initial-balance", type=float, required=True)
    parser.add_argument("--benchmark-csv", type=Path, required=True, help="month,level形式の月末値（YYYY-MM）")
    parser.add_argument("--benchmark-source", required=True, help="ベンチマークのデータ源")
    parser.add_argument("--benchmark-retrieved-on", type=date.fromisoformat, required=True, help="取得日（YYYY-MM-DD）")
    parser.add_argument("--benchmark-annual-fee", type=float, required=True, help="控除する信託報酬（年率、例: 0.0005775）")
    parser.add_argument("--benchmark-name", default=DEFAULT_BENCHMARK_NAME)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(argv)

    labels = [label for label, _, _ in args.period]
    if len(set(labels)) != len(labels):
        parser.error("period labels must be unique")
    inputs: dict[str, list[Path]] = {label: [] for label in labels}
    for label, path in args.input:
        if label not in inputs:
            parser.error(f"--input label has no matching --period: {label}")
        inputs[label].append(Path(path))
    levels = load_benchmark_levels(args.benchmark_csv)
    comparisons: list[PeriodComparison] = []
    for label, start, end in args.period:
        if not inputs[label]:
            parser.error(f"--period has no --input: {label}")
        trades = load_analysis_inputs(resolve_trade_inputs(inputs[label])).trades
        comparisons.append(compare_period(
            label, trades, args.initial_balance, start, end, levels, args.benchmark_annual_fee,
        ))
    report = build_report(
        comparisons, args.benchmark_name, args.benchmark_source,
        args.benchmark_retrieved_on, args.benchmark_annual_fee,
    )
    write_report(args.output, report)
    print(f"BENCHMARK_CRITERIA_MET={str(report['criteria_met']).lower()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
