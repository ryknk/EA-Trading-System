"""バックテスト結果へ取引コスト（Entry/Exit Spread・手数料・Swap・Slippage）の感応度分析を追加するモジュール。

目的は、Profit Factorの低さが「Entry/Exitロジック自体の問題」なのか「薄いエッジが取引コストによって
失われている」のかを切り分けることである。過去データへ最も都合よく適合するコスト条件を自動採用する
処理は行わない。MT5テスターが提供する実際のSpread・Commission・Swapをそのまま記録するのみで、
EA内部で市場コストを変更・偽装するロジックは持たない。

コストの内訳（すべてMT5テスターが実際に生成した値であり、本モジュールが推定・偽装するものではない）:

- Entry Spread: CANDIDATE.spread_points（Entry候補生成Tick時点のSpread、Point単位）
- Exit Spread: TRADE_CLOSED.exit_spread_points（決済検知Tick時点のSpread、Point単位のベストエフォート値。
  決済自体はブローカー側SL/TP等で発生するため、約定Tickそのものの値ではない近似値）
- Entry Slippage: ORDER_SUBMISSION.slippage_points（発注時の要求価格と約定価格の差、Point単位）
- Exit Slippage: 未対応。決済の大半はブローカー側SL/TP自動決済であり、Entry側のOrderManagerのような
  「要求価格」に相当する値を安全に取得する手段が現アーキテクチャにはないため、Entry側のみ記録する
  （既知の制約。EXPERT/CLIENT close_reasonの決済もEA発注だが、本モジュールでは未計測）。
- Commission・Swap: TRADE_CLOSED.commission/swapをそのまま使用（net_pnlへ既に加算済み）。

Point単位のコストは、TRADE_CLOSED.point_value（該当トレードのVolumeにおける1 Point変動の
口座通貨換算値。EA側でOrderCalcProfitにより算出、PositionSizerと同じAPIを再利用）を用いて
口座通貨へ換算する。point_valueが取得できない（0または欠落）トレードは、Spread/Slippageコストを
0として扱う（Commission/Swapには影響しない）。この場合、控除後損益（pnl_before_cost）は
実際のコストを過小評価する可能性がある点に注意すること。
"""

from __future__ import annotations

import argparse
import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import pandas as pd

from .performance import TRADE_COLUMNS, PerformanceMetrics, analyze_performance
from .reports import read_json_lines
from .trade_breakdown import build_trade_context

COST_TIER_LABELS = ["Low Cost", "Normal Cost", "High Cost"]
COST_CONTEXT_COLUMNS = [
    "entry_slippage_points", "entry_spread_cost", "exit_spread_cost", "entry_slippage_cost",
    "total_spread_cost", "total_cost", "pnl_before_cost", "cost_data_available", "cost_tier",
]


def _extract_order_submission_context(records: list[dict[str, Any]]) -> pd.DataFrame:
    rows: list[dict[str, Any]] = []
    seen: set[str] = set()
    for record in records:
        if record.get("event_type") != "ORDER_SUBMISSION":
            continue
        candidate_id = record.get("trade_candidate_id")
        payload = record.get("payload")
        if not isinstance(candidate_id, str) or candidate_id in seen or not isinstance(payload, dict):
            continue
        if payload.get("status") != "ACCEPTED":
            continue
        seen.add(candidate_id)
        rows.append({"trade_candidate_id": candidate_id, "entry_slippage_points": payload.get("slippage_points")})
    return pd.DataFrame(rows, columns=["trade_candidate_id", "entry_slippage_points"])


def cost_tier_band(total_cost: pd.Series) -> pd.Series:
    """total_costの実データ三分位からLow/Normal/High Costを算出する。固定しきい値は使用しない。
    過去データへ最も都合よく適合するコスト条件を選ぶ処理ではなく、実際に発生したコスト分布を
    3分割して成績を比較するための分類にすぎない。"""
    empty = pd.Series([None] * len(total_cost), index=total_cost.index, dtype=object)
    if total_cost.dropna().nunique() < 3:
        return empty
    try:
        bucketed = pd.qcut(total_cost, q=3, labels=COST_TIER_LABELS)
    except ValueError:
        return empty
    return bucketed.astype(object)


def build_cost_context(paths: list[Path]) -> pd.DataFrame:
    """trade_breakdown.build_trade_contextへEntry Slippage（ORDER_SUBMISSION）とコスト内訳列を追加する。"""
    trades = build_trade_context(paths)
    if trades.empty:
        for column in COST_CONTEXT_COLUMNS:
            trades[column] = pd.Series(dtype=object)
        return trades

    records: list[dict[str, Any]] = []
    for path in paths:
        if path.suffix.lower() in {".jsonl", ".ndjson"}:
            records.extend(read_json_lines(path))
    trades = trades.merge(_extract_order_submission_context(records), on="trade_candidate_id", how="left")
    trades["entry_slippage_points"] = pd.to_numeric(trades["entry_slippage_points"], errors="coerce")

    point_value = trades["point_value"]
    trades["cost_data_available"] = point_value.notna() & (point_value > 0.0)
    safe_point_value = point_value.where(trades["cost_data_available"], 0.0)
    trades["entry_spread_cost"] = trades["entry_spread_points"].fillna(0.0) * safe_point_value
    trades["exit_spread_cost"] = trades["exit_spread_points"].fillna(0.0) * safe_point_value
    trades["entry_slippage_cost"] = trades["entry_slippage_points"].fillna(0.0) * safe_point_value
    trades["total_spread_cost"] = trades["entry_spread_cost"] + trades["exit_spread_cost"]
    # commission・swapはnet_pnlへ既に（符号付きで）加算済み。-commission-swapは、それらが損益から
    # 差し引いた金額を正の値として表す（swapがプラス、すなわちスワップ収益の場合は総コストを押し下げる）。
    trades["total_cost"] = (
        trades["total_spread_cost"] + trades["entry_slippage_cost"] - trades["commission"] - trades["swap"]
    )
    trades["pnl_before_cost"] = trades["net_pnl"] + trades["total_cost"]
    trades["cost_tier"] = cost_tier_band(trades["total_cost"])
    return trades


def _metrics_for_frame(trades: pd.DataFrame, pnl_column: str, initial_balance: float) -> PerformanceMetrics | None:
    if trades.empty:
        return None
    working = trades[TRADE_COLUMNS].copy()
    working["net_pnl"] = trades[pnl_column]
    metrics, _, _ = analyze_performance(working, initial_balance)
    return metrics


def cost_summary(trades: pd.DataFrame) -> dict[str, Any]:
    with_data = trades[trades["cost_data_available"] == True]  # noqa: E712 (pandasのbool列比較)
    return {
        "trades_total": int(len(trades)),
        "trades_with_cost_data": int(len(with_data)),
        "total_cost": float(trades["total_cost"].sum()) if len(trades) else 0.0,
        "average_cost_per_trade": (None if trades.empty else float(trades["total_cost"].mean())),
        "total_spread_cost": float(trades["total_spread_cost"].sum()) if len(trades) else 0.0,
        "total_slippage_cost": float(trades["entry_slippage_cost"].sum()) if len(trades) else 0.0,
        "total_commission": float(trades["commission"].sum()) if len(trades) else 0.0,
        "total_swap": float(trades["swap"].sum()) if len(trades) else 0.0,
    }


def tier_breakdown(trades: pd.DataFrame, initial_balance: float) -> list[dict[str, Any]]:
    working = trades.dropna(subset=["cost_tier"])
    rows: list[dict[str, Any]] = []
    for label in COST_TIER_LABELS:
        part = working[working["cost_tier"] == label]
        if part.empty:
            continue
        metrics = _metrics_for_frame(part, "net_pnl", initial_balance)
        row: dict[str, Any] = {
            "cost_tier": label,
            "trades": int(len(part)),
            "average_cost_per_trade": float(part["total_cost"].mean()),
        }
        if metrics is not None:
            row.update(metrics.to_dict())
        rows.append(row)
    return rows


def _fmt_metrics(metrics: PerformanceMetrics | None) -> list[str]:
    if metrics is None:
        return ["- トレードなし（算出不能）"]
    value = metrics.to_dict()
    def number(x: float | None) -> str:
        return "算出不能" if x is None else f"{x:.4f}"
    def percent(x: float | None) -> str:
        return "算出不能" if x is None else f"{x:.2%}"
    return [
        f"- 取引数: {value['number_of_trades']}",
        f"- 純利益: {value['net_profit']:.2f}",
        f"- プロフィットファクター: {number(value['profit_factor'])}",
        f"- 勝率: {percent(value['win_rate'])}",
        f"- 期待値: {value['expectancy']:.2f}",
        f"- 最大ドローダウン: {value['max_drawdown_amount']:.2f} ({percent(value['max_drawdown_rate'])})",
    ]


def _markdown(
    with_cost: PerformanceMetrics | None,
    before_cost: PerformanceMetrics | None,
    summary: dict[str, Any],
    tiers: list[dict[str, Any]],
) -> str:
    lines = [
        "# コスト感応度分析レポート", "",
        "本レポートはPFの低さが「Entry/Exitロジック自体の問題」か「取引コストによるエッジの消失」かを",
        "切り分けるための分析専用機能です。過去データへ最も都合よく適合するコスト条件の自動採用は行っていません。",
        "MT5テスターが実際に生成したSpread・Commission・Swap・Slippageをそのまま使用しています。", "",
        "## コスト集計", "",
        f"- 対象トレード数: {summary['trades_total']}",
        f"- コスト金額換算可能なトレード数（point_value取得済み）: {summary['trades_with_cost_data']}",
        f"- 総取引コスト: {summary['total_cost']:.2f}",
        ("- 1トレードあたり平均コスト: 算出不能" if summary["average_cost_per_trade"] is None
         else f"- 1トレードあたり平均コスト: {summary['average_cost_per_trade']:.2f}"),
        f"  - うちSpreadコスト合計: {summary['total_spread_cost']:.2f}",
        f"  - うちSlippageコスト合計（Entry側のみ）: {summary['total_slippage_cost']:.2f}",
        f"  - うちCommission合計: {summary['total_commission']:.2f}",
        f"  - うちSwap合計: {summary['total_swap']:.2f}",
        "", "## 実績（コスト込み） vs コスト除外時の推定成績", "",
        "### 実績（net_pnl、コスト込み）", "",
        *_fmt_metrics(with_cost), "",
        "### コスト除外時の推定成績（pnl_before_cost、Spread・Slippage・Commission・Swapを除いた場合の推定損益）", "",
        *_fmt_metrics(before_cost), "",
        "コスト除外時の推定成績が実績を大きく上回る場合、薄いエッジが取引コストで失われている可能性を示唆します。",
        "逆に両者が近い、あるいはコスト除外時も成績が悪い場合、Entry/Exitロジック自体に課題がある可能性を示唆します。", "",
        "## コスト水準別（Low/Normal/High Cost、実データ三分位）", "",
        "```json", json.dumps(tiers, ensure_ascii=False, indent=2), "```", "",
    ]
    return "\n".join(lines)


def write_report(
    output_directory: Path,
    trades: pd.DataFrame,
    initial_balance: float,
    generated_at: datetime | None = None,
) -> dict[str, Path]:
    output_directory.mkdir(parents=True, exist_ok=True)
    with_cost = _metrics_for_frame(trades, "net_pnl", initial_balance)
    before_cost = _metrics_for_frame(trades, "pnl_before_cost", initial_balance)
    summary = cost_summary(trades)
    tiers = tier_breakdown(trades, initial_balance)
    report = {
        "schema_version": "1.0",
        "generated_at": (generated_at or datetime.now(UTC)).isoformat().replace("+00:00", "Z"),
        "currency": "ACCOUNT_CURRENCY",
        "definitions": {
            "entry_spread_cost": "CANDIDATE.spread_points（Point）× point_valueによる口座通貨換算コスト",
            "exit_spread_cost": "TRADE_CLOSED.exit_spread_points（Point、決済検知Tick時点のベストエフォート値）× point_value",
            "entry_slippage_cost": "ORDER_SUBMISSION.slippage_points（Point）× point_value。Exit側のSlippageは未対応",
            "total_cost": "total_spread_cost + entry_slippage_cost - commission - swap（口座通貨、正の値ほど損益を押し下げたコスト）",
            "pnl_before_cost": "net_pnl + total_cost。Spread・Slippage・Commission・Swapを除いた場合の推定損益",
            "cost_data_available": "point_valueが取得できた（>0）トレードはTrue。Falseのトレードはtotal_costのSpread/Slippage分を0として扱う",
            "cost_tier": "total_costの実データ三分位によるLow/Normal/High Cost分類。固定しきい値は使用しない",
        },
        "cost_summary": summary,
        "performance_with_cost": None if with_cost is None else with_cost.to_dict(),
        "performance_before_cost": None if before_cost is None else before_cost.to_dict(),
        "cost_tier_breakdown": tiers,
    }
    output_paths = {
        "json": output_directory / "cost-sensitivity-report.json",
        "markdown": output_directory / "cost-sensitivity-report.md",
        "trades": output_directory / "trades-with-cost.csv",
    }
    output_paths["json"].write_text(
        json.dumps(report, ensure_ascii=False, indent=2, allow_nan=False) + "\n", encoding="utf-8",
    )
    output_paths["markdown"].write_text(_markdown(with_cost, before_cost, summary, tiers), encoding="utf-8")
    trades.to_csv(output_paths["trades"], index=False)
    return output_paths


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="バックテスト結果の取引コスト感応度分析（Spread/Commission/Swap/Slippage）")
    parser.add_argument("--input", type=Path, action="append", required=True, help="監査JSONL。複数指定可")
    parser.add_argument("--initial-balance", type=float, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(argv)
    trades = build_cost_context(args.input)
    write_report(args.output, trades, args.initial_balance)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
