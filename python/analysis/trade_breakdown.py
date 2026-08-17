"""バックテスト結果を条件別（方向・時間帯・曜日・ATR/ADX帯・保有時間・MFE/MAE・市場レジーム・
決済トリガー・Giveback等）に集計する分析モジュール。

監査JSONL（CANDIDATE, RISK_DECISION, TRADE_CLOSED, TRADE_ANALYTICS）から1トレードごとの
文脈情報（エントリー時ATR/ADX/Spread/市場レジーム、決済トリガー（close_reason）、
R換算損益、MFE、MAE、保有時間、Entry/Exit時点の曜日・Session、Giveback比率）を
再構成し、分類ごとの成績（Trades, Win Rate, Profit Factor, Expectancy, Net Profit,
平均利益・平均損失）を出力する。ここでは分析結果に基づく自動的な閾値変更は一切行わない。

決済トリガー（close_reason: SL/TP/SO/EXPERT等）とGiveback比率（giveback_ratio、
MFE到達後に決済までへ手放した利益の割合）は、エントリー条件ではなくExit（決済）品質を
分析するための指標であり、TRADE_CLOSEDペイロードのDEAL_REASON・MFE/MAEから算出する。

市場レジーム（market_regime_trend: TrendUp/TrendDown/Range、market_regime_volatility:
HighVolatility/NormalVolatility/LowVolatility）は、EA側（CMarketRegimeClassifier）が
Entry時点の確定足データのみで判定した結果をCANDIDATEイベントのpayloadへ記録したものを
そのまま集計する。本モジュールは判定ロジックを持たず、EA側の判定結果を再構成するのみ。
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd

from .performance import aggregate_trade_group
from .reports import load_analysis_inputs, read_json_lines

# UTC時刻に基づく簡易Session区分。実際のFXセッションは相互に重なり、DSTでも変動するため、
# ここでは非DSTの概算境界による単純な排他分類とする（既知の簡略化、DECISIONS.md未記載の暫定値）。
SESSION_BOUNDARIES: tuple[tuple[int, int, str], ...] = (
    (0, 8, "Tokyo"),
    (8, 13, "London"),
    (13, 17, "London_NewYork_Overlap"),
    (17, 22, "NewYork"),
    (22, 24, "Tokyo"),
)
WEEKDAY_NAMES = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
BREAKDOWN_COLUMNS = [
    "direction", "session", "weekday", "atr_band", "adx_band",
    "hold_time_band", "mfe_band", "mae_band",
    "market_regime_trend", "market_regime_volatility",
    "close_reason", "close_session", "close_weekday", "giveback_band",
]


def _session_for_hour(hour_utc: int) -> str:
    for start, end, name in SESSION_BOUNDARIES:
        if start <= hour_utc < end:
            return name
    return "UNKNOWN"


def _extract_candidate_context(records: list[dict[str, Any]]) -> pd.DataFrame:
    rows: list[dict[str, Any]] = []
    seen: set[str] = set()
    for record in records:
        if record.get("event_type") != "CANDIDATE":
            continue
        candidate_id = record.get("trade_candidate_id")
        payload = record.get("payload")
        if not isinstance(candidate_id, str) or candidate_id in seen or not isinstance(payload, dict):
            continue
        seen.add(candidate_id)
        rows.append({
            "trade_candidate_id": candidate_id,
            "entry_atr": payload.get("atr"),
            "entry_adx": payload.get("adx"),
            "entry_spread_points": payload.get("spread_points"),
            "market_regime_trend": payload.get("market_regime_trend"),
            "market_regime_volatility": payload.get("market_regime_volatility"),
        })
    return pd.DataFrame(rows, columns=[
        "trade_candidate_id", "entry_atr", "entry_adx", "entry_spread_points",
        "market_regime_trend", "market_regime_volatility",
    ])


def _extract_risk_context(records: list[dict[str, Any]]) -> pd.DataFrame:
    rows: list[dict[str, Any]] = []
    seen: set[str] = set()
    for record in records:
        if record.get("event_type") != "RISK_DECISION":
            continue
        candidate_id = record.get("trade_candidate_id")
        payload = record.get("payload")
        if not isinstance(candidate_id, str) or not isinstance(payload, dict):
            continue
        if payload.get("status") != "APPROVED" or candidate_id in seen:
            continue
        seen.add(candidate_id)
        rows.append({"trade_candidate_id": candidate_id, "risk_budget": payload.get("risk_budget")})
    return pd.DataFrame(rows, columns=["trade_candidate_id", "risk_budget"])


def _extract_analytics_context(records: list[dict[str, Any]]) -> pd.DataFrame:
    rows: list[dict[str, Any]] = []
    seen: set[str] = set()
    for record in records:
        if record.get("event_type") != "TRADE_ANALYTICS":
            continue
        candidate_id = record.get("trade_candidate_id")
        payload = record.get("payload")
        if not isinstance(candidate_id, str) or candidate_id in seen or not isinstance(payload, dict):
            continue
        seen.add(candidate_id)
        rows.append({"trade_candidate_id": candidate_id, "mfe": payload.get("mfe"), "mae": payload.get("mae")})
    return pd.DataFrame(rows, columns=["trade_candidate_id", "mfe", "mae"])


def _extract_closed_context(records: list[dict[str, Any]]) -> pd.DataFrame:
    rows: list[dict[str, Any]] = []
    seen: set[str] = set()
    for record in records:
        if record.get("event_type") != "TRADE_CLOSED":
            continue
        candidate_id = record.get("trade_candidate_id")
        payload = record.get("payload")
        if not isinstance(candidate_id, str) or candidate_id in seen or not isinstance(payload, dict):
            continue
        seen.add(candidate_id)
        rows.append({"trade_candidate_id": candidate_id, "close_reason": payload.get("close_reason")})
    return pd.DataFrame(rows, columns=["trade_candidate_id", "close_reason"])


def _quantile_band(series: pd.Series, prefix: str, bins: int = 3) -> pd.Series:
    """分位点ベースの帯分類。境界値をハードコードせず、実際のデータ分布から算出する。"""
    empty = pd.Series([None] * len(series), index=series.index, dtype=object)
    if series.dropna().nunique() < 2:
        return empty
    try:
        bucketed = pd.qcut(series, q=bins, duplicates="drop")
    except ValueError:
        return empty
    labelled = bucketed.apply(lambda interval: (
        None if pd.isna(interval) else f"{prefix}_{interval.left:.4g}-{interval.right:.4g}"
    ))
    return labelled.astype(object)


def build_trade_context(paths: list[Path]) -> pd.DataFrame:
    """監査JSONL/CSVから、分類分析に必要な列を付加したトレード単位のDataFrameを構築する。"""
    inputs = load_analysis_inputs(paths)
    trades = inputs.trades.copy()
    context_columns = [
        "entry_atr", "entry_adx", "entry_spread_points", "risk_budget", "mfe", "mae",
        "hold_time_hours", "weekday", "session", "r_multiple", "mfe_r", "mae_r",
        "reached_unrealized_profit_before_loss",
        "atr_band", "adx_band", "hold_time_band", "mfe_band", "mae_band",
        "market_regime_trend", "market_regime_volatility",
        "close_reason", "close_weekday", "close_session", "giveback_ratio", "giveback_band",
    ]
    if trades.empty:
        for column in context_columns:
            trades[column] = pd.Series(dtype=object)
        return trades

    records: list[dict[str, Any]] = []
    for path in paths:
        if path.suffix.lower() in {".jsonl", ".ndjson"}:
            records.extend(read_json_lines(path))

    enriched = trades.merge(_extract_candidate_context(records), on="trade_candidate_id", how="left")
    enriched = enriched.merge(_extract_risk_context(records), on="trade_candidate_id", how="left")
    enriched = enriched.merge(_extract_analytics_context(records), on="trade_candidate_id", how="left")
    enriched = enriched.merge(_extract_closed_context(records), on="trade_candidate_id", how="left")
    for column in ("entry_atr", "entry_adx", "entry_spread_points", "risk_budget", "mfe", "mae"):
        enriched[column] = pd.to_numeric(enriched[column], errors="coerce")

    hold_time = enriched["close_time"] - enriched["open_time"]
    enriched["hold_time_hours"] = hold_time.dt.total_seconds() / 3600.0
    enriched["weekday"] = enriched["open_time"].apply(lambda ts: WEEKDAY_NAMES[ts.weekday()])
    enriched["session"] = enriched["open_time"].apply(lambda ts: _session_for_hour(ts.hour))
    enriched["close_weekday"] = enriched["close_time"].apply(lambda ts: WEEKDAY_NAMES[ts.weekday()])
    enriched["close_session"] = enriched["close_time"].apply(lambda ts: _session_for_hour(ts.hour))

    risk_budget = enriched["risk_budget"].where(enriched["risk_budget"] != 0.0)
    enriched["r_multiple"] = enriched["net_pnl"] / risk_budget
    enriched["mfe_r"] = enriched["mfe"] / risk_budget
    enriched["mae_r"] = enriched["mae"] / risk_budget
    enriched["reached_unrealized_profit_before_loss"] = (
        enriched["mfe"].notna() & (enriched["mfe"] > 0.0) & (enriched["net_pnl"] < 0.0)
    )
    # 一度到達したMFE（含み益ピーク）のうち、決済までに手放した割合。1.0以上は損益ゼロ以下まで完全反転したことを示す。
    mfe = enriched["mfe"]
    enriched["giveback_ratio"] = ((mfe - enriched["net_pnl"]) / mfe).where(mfe > 0.0)

    enriched["atr_band"] = _quantile_band(enriched["entry_atr"], "ATR")
    enriched["adx_band"] = _quantile_band(enriched["entry_adx"], "ADX")
    enriched["hold_time_band"] = _quantile_band(enriched["hold_time_hours"], "HOLD_H")
    enriched["mfe_band"] = _quantile_band(enriched["mfe"], "MFE")
    enriched["mae_band"] = _quantile_band(enriched["mae"], "MAE")
    enriched["giveback_band"] = _quantile_band(enriched["giveback_ratio"], "GIVEBACK")
    return enriched


def breakdown_by(trades: pd.DataFrame, column: str) -> list[dict[str, Any]]:
    working = trades.dropna(subset=[column])
    if working.empty:
        return []
    return [
        {column: str(name), **aggregate_trade_group(part["net_pnl"])}
        for name, part in working.groupby(column, sort=True, observed=True)
    ]


def reversal_from_profit_summary(trades: pd.DataFrame) -> dict[str, Any]:
    """負けトレードのうち、一度含み益（MFE>0）になってから損失決済に至った割合を要約する。"""
    losses = trades[trades["net_pnl"] < 0]
    with_mfe = losses.dropna(subset=["mfe"])
    reached_profit = with_mfe[with_mfe["mfe"] > 0.0]
    return {
        "losing_trades_total": int(len(losses)),
        "losing_trades_with_mfe_data": int(len(with_mfe)),
        "losing_trades_that_reached_unrealized_profit": int(len(reached_profit)),
        "share_of_losing_trades_with_data": (
            None if with_mfe.empty else float(len(reached_profit) / len(with_mfe))
        ),
        "average_mfe_before_reversal": (
            None if reached_profit.empty else float(reached_profit["mfe"].mean())
        ),
    }


def giveback_summary(trades: pd.DataFrame) -> dict[str, Any]:
    """勝敗を問わず、一度到達した含み益（MFE）に対し、決済時点でどれだけ手放したかを要約する。"""
    with_mfe = trades.dropna(subset=["mfe", "net_pnl"])
    with_mfe = with_mfe[with_mfe["mfe"] > 0.0]
    ratios = (with_mfe["mfe"] - with_mfe["net_pnl"]) / with_mfe["mfe"]
    full_reversal = ratios[ratios >= 1.0]
    return {
        "trades_with_unrealized_profit": int(len(with_mfe)),
        "average_giveback_ratio": None if ratios.empty else float(ratios.mean()),
        "median_giveback_ratio": None if ratios.empty else float(ratios.median()),
        "trades_that_fully_reversed_to_breakeven_or_loss": int(len(full_reversal)),
        "share_that_fully_reversed": (
            None if ratios.empty else float(len(full_reversal) / len(ratios))
        ),
    }


def _markdown(
    breakdowns: dict[str, list[dict[str, Any]]],
    reversal: dict[str, Any],
    giveback: dict[str, Any],
) -> str:
    lines = [
        "# トレード条件別分析レポート", "",
        "分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、",
        "本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。", "",
        "## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）", "",
        f"- 負けトレード数: {reversal['losing_trades_total']}",
        f"- MFEデータのある負けトレード数: {reversal['losing_trades_with_mfe_data']}",
        f"- うち一度含み益になった数: {reversal['losing_trades_that_reached_unrealized_profit']}",
    ]
    share = reversal["share_of_losing_trades_with_data"]
    lines.append(f"- 割合: {'算出不能' if share is None else f'{share:.2%}'}")
    average_mfe = reversal["average_mfe_before_reversal"]
    lines.append(f"- 反転前の平均含み益: {'算出不能' if average_mfe is None else f'{average_mfe:.2f}'}")
    lines.append("")
    lines += [
        "## 決済時点でのGiveback（含み益ピークからの取りこぼし）", "",
        f"- 含み益（MFE>0）に達したトレード数: {giveback['trades_with_unrealized_profit']}",
    ]
    average_giveback = giveback["average_giveback_ratio"]
    lines.append(f"- 平均Giveback比率: {'算出不能' if average_giveback is None else f'{average_giveback:.2%}'}")
    median_giveback = giveback["median_giveback_ratio"]
    lines.append(f"- 中央値Giveback比率: {'算出不能' if median_giveback is None else f'{median_giveback:.2%}'}")
    share_full_reversal = giveback["share_that_fully_reversed"]
    lines.append(
        "- 損益ゼロ以下まで完全反転した割合: "
        + ("算出不能" if share_full_reversal is None else f"{share_full_reversal:.2%}")
    )
    lines.append("")
    for name, rows in breakdowns.items():
        lines += [f"## {name}別", "", "```json", json.dumps(rows, ensure_ascii=False, indent=2), "```", ""]
    return "\n".join(lines)


def write_report(
    output_directory: Path,
    trades: pd.DataFrame,
    generated_at: datetime | None = None,
) -> dict[str, Path]:
    output_directory.mkdir(parents=True, exist_ok=True)
    breakdowns = {column: breakdown_by(trades, column) for column in BREAKDOWN_COLUMNS}
    reversal = reversal_from_profit_summary(trades)
    giveback = giveback_summary(trades)
    report = {
        "schema_version": "1.0",
        "generated_at": (generated_at or datetime.now(UTC)).isoformat().replace("+00:00", "Z"),
        "currency": "ACCOUNT_CURRENCY",
        "definitions": {
            "session": "UTCの概算時間帯によるSession区分、Entry時刻基準（DST未考慮の簡略化）",
            "atr_band": "エントリー時H1 ATRの実データ分位点による帯（区間はデータ依存で固定値ではない）",
            "adx_band": "エントリー時H1 ADXの実データ分位点による帯",
            "hold_time_band": "保有時間（時間単位）の実データ分位点による帯",
            "mfe_band": "MFE（最大含み益、口座通貨、手数料除く）の実データ分位点による帯",
            "mae_band": "MAE（最大含み損、口座通貨、手数料除く）の実データ分位点による帯",
            "r_multiple": "net_pnl / risk_budget（RISK_DECISIONで承認されたリスク額）",
            "market_regime_trend": "EA側CMarketRegimeClassifierによるEntry時点のトレンド判定（TrendUp/TrendDown/Range、判定不能時はUnknown）",
            "market_regime_volatility": "EA側CMarketRegimeClassifierによるEntry時点のボラティリティ判定（HighVolatility/NormalVolatility/LowVolatility、判定不能時はUnknown）",
            "close_reason": "決済トリガー（SL/TP/SO/EXPERT/CLIENT等、MT5 DEAL_REASONをそのまま文字列化。EXPERTはEA発注によるEmergency Close等）",
            "close_session": "UTCの概算時間帯によるSession区分、Exit（決済）時刻基準",
            "close_weekday": "決済時刻の曜日（UTC基準）",
            "giveback_ratio": "(mfe - net_pnl) / mfe。MFE到達後、決済までに手放した利益の割合。1.0以上は損益ゼロ以下まで完全反転したことを示す。MFE<=0のトレードはNaN",
            "giveback_band": "giveback_ratioの実データ分位点による帯",
        },
        "reversal_from_profit": reversal,
        "giveback_from_peak_profit": giveback,
        "breakdowns": breakdowns,
    }
    paths = {
        "json": output_directory / "trade-breakdown-report.json",
        "markdown": output_directory / "trade-breakdown-report.md",
        "trades": output_directory / "trades-with-context.csv",
    }
    paths["json"].write_text(
        json.dumps(report, ensure_ascii=False, indent=2, allow_nan=False) + "\n", encoding="utf-8",
    )
    paths["markdown"].write_text(_markdown(breakdowns, reversal, giveback), encoding="utf-8")
    trades.to_csv(paths["trades"], index=False)
    return paths


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="バックテスト結果の条件別（Buy/Sell、時間帯、曜日、ATR/ADX帯等）分析")
    parser.add_argument("--input", type=Path, action="append", required=True, help="監査JSONL。複数指定可")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(argv)
    trades = build_trade_context(args.input)
    write_report(args.output, trades)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
