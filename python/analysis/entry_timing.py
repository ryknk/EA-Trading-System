"""Entry Timing比較分析モジュール。

同一のプルバックSetupについて、EA側`CEntryTimingAnalyzer`（`mt5/Include/Logging/EntryTimingAnalyzer.mqh`、
`InpEnableEntryTimingAnalysis=true`時のみ動作）が実注文なしでシミュレートした4方式のShadow Trade
（IMMEDIATE=Setup成立時に即Entry、WAIT_1_BAR=1本待ち、WAIT_2_BARS=2本待ち、WAIT_TRIGGER=Trigger成立待ち）
の監査ログ（`ENTRY_TIMING_SETUP`・`ENTRY_TIMING_TRADE`イベント）を集計する。

損益はすべてR倍数（Shadow Trade自身の当初SL距離を1Rとする）で表現する。Shadow Tradeは実ポジション・
実注文を伴わないため、Position Sizing（Risk Manager管轄）を経由せず、口座通貨建ての損益は算出できない。

目的はEntryを早める/遅らせることで成績やMFE/MAEがどう変化するかを分析し仮説を立てることであり、
本モジュールは過去データに最も適合する待機方式を自動選択する処理を一切行わない。
"""

from __future__ import annotations

import argparse
import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import pandas as pd

from .drawdown import build_drawdown_curve, summarize_drawdown
from .performance import aggregate_trade_group
from .reports import read_json_lines

VARIANTS = ["IMMEDIATE", "WAIT_1_BAR", "WAIT_2_BARS", "WAIT_TRIGGER"]
CHECKPOINT_BAR_OFFSETS = (1, 2, 3, 5, 10, 20)
DRAWDOWN_BASELINE_R = 100.0


def _extract_setups(records: list[dict[str, Any]]) -> pd.DataFrame:
    rows: list[dict[str, Any]] = []
    for record in records:
        if record.get("event_type") != "ENTRY_TIMING_SETUP":
            continue
        payload = record.get("payload")
        if not isinstance(payload, dict):
            continue
        rows.append({
            "setup_id": record.get("trade_candidate_id"),
            "setup_bar_time": payload.get("setup_bar_time"),
            "direction": payload.get("direction"),
            "pre_entry_mfe_r": payload.get("pre_entry_mfe_r"),
            "pre_entry_mae_r": payload.get("pre_entry_mae_r"),
            "trigger_found": payload.get("trigger_found"),
            "trigger_wait_bars": payload.get("trigger_wait_bars"),
        })
    columns = [
        "setup_id", "setup_bar_time", "direction", "pre_entry_mfe_r", "pre_entry_mae_r",
        "trigger_found", "trigger_wait_bars",
    ]
    frame = pd.DataFrame(rows, columns=columns)
    if not frame.empty:
        frame["setup_bar_time"] = pd.to_datetime(frame["setup_bar_time"], utc=True, errors="raise")
        for column in ("pre_entry_mfe_r", "pre_entry_mae_r"):
            frame[column] = pd.to_numeric(frame[column], errors="coerce")
    return frame


def _extract_trades(records: list[dict[str, Any]]) -> pd.DataFrame:
    rows: list[dict[str, Any]] = []
    for record in records:
        if record.get("event_type") != "ENTRY_TIMING_TRADE":
            continue
        payload = record.get("payload")
        if not isinstance(payload, dict):
            continue
        checkpoints = payload.get("checkpoint_r")
        row = {
            "setup_id": record.get("trade_candidate_id"),
            "variant": payload.get("variant"),
            "entry_bar_time": payload.get("entry_bar_time"),
            "direction": payload.get("direction"),
            "wait_bars": payload.get("wait_bars"),
            "bars_held": payload.get("bars_held"),
            "mfe_r": payload.get("mfe_r"),
            "mae_r": payload.get("mae_r"),
            "exit_reason": payload.get("exit_reason"),
            "pnl_r": payload.get("pnl_r"),
        }
        for offset in CHECKPOINT_BAR_OFFSETS:
            row[f"checkpoint_r_bars_{offset}"] = (
                checkpoints.get(f"bars_{offset}") if isinstance(checkpoints, dict) else None
            )
        rows.append(row)
    columns = [
        "setup_id", "variant", "entry_bar_time", "direction", "wait_bars", "bars_held",
        "mfe_r", "mae_r", "exit_reason", "pnl_r",
    ] + [f"checkpoint_r_bars_{offset}" for offset in CHECKPOINT_BAR_OFFSETS]
    frame = pd.DataFrame(rows, columns=columns)
    if not frame.empty:
        frame["entry_bar_time"] = pd.to_datetime(frame["entry_bar_time"], utc=True, errors="raise")
        numeric_columns = ["mfe_r", "mae_r", "pnl_r"] + [f"checkpoint_r_bars_{offset}" for offset in CHECKPOINT_BAR_OFFSETS]
        for column in numeric_columns:
            frame[column] = pd.to_numeric(frame[column], errors="coerce")
    return frame


def _equity_curve_from_pnl_r(trades: pd.DataFrame, baseline: float = DRAWDOWN_BASELINE_R) -> pd.DataFrame:
    if trades.empty:
        return pd.DataFrame({
            "timestamp": pd.Series(dtype="datetime64[ns, UTC]"),
            "equity": pd.Series(dtype=float),
        })
    pnl = trades.groupby("entry_bar_time", sort=True)["pnl_r"].sum()
    equity = baseline + pnl.cumsum()
    return pd.DataFrame({"timestamp": equity.index, "equity": equity.to_numpy(dtype=float)})


def variant_summary(trades: pd.DataFrame) -> dict[str, dict[str, Any]]:
    """Variant別（IMMEDIATE/WAIT_1_BAR/WAIT_2_BARS/WAIT_TRIGGER）にTrades・Win Rate・Profit Factor・
    Expectancy・Net Profit（R倍数）・Max Drawdown（R倍数、基準値100Rからの下落幅）・平均MFE/MAE・
    価格推移チェックポイント平均を集計する。"""
    summary: dict[str, dict[str, Any]] = {}
    for variant in VARIANTS:
        part = trades[trades["variant"] == variant]
        base = aggregate_trade_group(part["pnl_r"]) if not part.empty else aggregate_trade_group(pd.Series(dtype=float))
        curve = build_drawdown_curve(_equity_curve_from_pnl_r(part))
        drawdown = summarize_drawdown(curve)
        checkpoint_averages = {
            f"bars_{offset}": (
                None if part.empty or part[f"checkpoint_r_bars_{offset}"].dropna().empty
                else float(part[f"checkpoint_r_bars_{offset}"].dropna().mean())
            )
            for offset in CHECKPOINT_BAR_OFFSETS
        }
        summary[variant] = {
            "trades": base["number_of_trades"],
            "win_rate": base["win_rate"],
            "profit_factor": base["profit_factor"],
            "expectancy_r": base["expectancy"],
            "net_profit_r": base["net_profit"],
            "max_drawdown_r": drawdown.max_drawdown_amount,
            "average_mfe_r": None if part.empty else float(part["mfe_r"].mean()),
            "average_mae_r": None if part.empty else float(part["mae_r"].mean()),
            "average_checkpoint_r": checkpoint_averages,
        }
    return summary


def pre_entry_excursion_summary(setups: pd.DataFrame) -> dict[str, Any]:
    """Setup成立からEntryまでの間に、想定方向と逆側へどれだけ動いてから順行したかを要約する。
    pre_entry_mae_r（逆行側極値のR換算、Setup成立bar終値基準）とpre_entry_mfe_r（順行側極値）の
    分布、およびTrigger成立率を返す。"""
    if setups.empty:
        return {
            "setups_observed": 0, "trigger_found_count": 0, "trigger_found_rate": None,
            "average_pre_entry_mae_r": None, "median_pre_entry_mae_r": None,
            "average_pre_entry_mfe_r": None, "median_pre_entry_mfe_r": None,
        }
    trigger_found = setups["trigger_found"].fillna(False).astype(bool)
    mae = setups["pre_entry_mae_r"].dropna()
    mfe = setups["pre_entry_mfe_r"].dropna()
    return {
        "setups_observed": int(len(setups)),
        "trigger_found_count": int(trigger_found.sum()),
        "trigger_found_rate": float(trigger_found.mean()),
        "average_pre_entry_mae_r": None if mae.empty else float(mae.mean()),
        "median_pre_entry_mae_r": None if mae.empty else float(mae.median()),
        "average_pre_entry_mfe_r": None if mfe.empty else float(mfe.mean()),
        "median_pre_entry_mfe_r": None if mfe.empty else float(mfe.median()),
    }


def build_entry_timing_context(paths: list[Path]) -> tuple[pd.DataFrame, pd.DataFrame]:
    """監査JSONLからENTRY_TIMING_SETUP/ENTRY_TIMING_TRADEを再構成する。
    `InpEnableEntryTimingAnalysis=false`（既定値）で取得した監査ログには対象イベントが存在せず、
    両DataFrameとも空になる。"""
    records: list[dict[str, Any]] = []
    for path in paths:
        if path.suffix.lower() in {".jsonl", ".ndjson"}:
            records.extend(read_json_lines(path))
    return _extract_setups(records), _extract_trades(records)


def _markdown(variants: dict[str, dict[str, Any]], pre_entry: dict[str, Any]) -> str:
    lines = [
        "# Entry Timing比較レポート", "",
        "同一のプルバックSetupに対する4方式（即時Entry・1本待ち・2本待ち・Trigger待ち）を",
        "実注文なしのShadow Tradeとして比較した結果です。損益はR倍数（Shadow Trade自身の",
        "当初SL距離を1R）で表しており、口座通貨建てではありません。", "",
        "本レポートは仮説の発見にのみ使用し、待機方式の自動選択・適用は行っていません。", "",
        "## Setup成立からEntryまでの逆行・順行", "",
        f"- 観測したSetup数: {pre_entry['setups_observed']}",
        f"- Trigger成立数: {pre_entry['trigger_found_count']}",
    ]
    rate = pre_entry["trigger_found_rate"]
    lines.append(f"- Trigger成立率: {'算出不能' if rate is None else f'{rate:.2%}'}")
    average_mae = pre_entry["average_pre_entry_mae_r"]
    lines.append(f"- 平均逆行(MAE) R: {'算出不能' if average_mae is None else f'{average_mae:.4f}'}")
    average_mfe = pre_entry["average_pre_entry_mfe_r"]
    lines.append(f"- 平均順行(MFE) R: {'算出不能' if average_mfe is None else f'{average_mfe:.4f}'}")
    lines.append("")
    lines += ["## Variant別成績", "", "```json", json.dumps(variants, ensure_ascii=False, indent=2), "```", ""]
    return "\n".join(lines)


def write_report(
    output_directory: Path,
    setups: pd.DataFrame,
    trades: pd.DataFrame,
    generated_at: datetime | None = None,
) -> dict[str, Path]:
    output_directory.mkdir(parents=True, exist_ok=True)
    variants = variant_summary(trades)
    pre_entry = pre_entry_excursion_summary(setups)
    report = {
        "schema_version": "1.0",
        "generated_at": (generated_at or datetime.now(UTC)).isoformat().replace("+00:00", "Z"),
        "currency": "R_MULTIPLE",
        "definitions": {
            "pnl_r": "Shadow Tradeの損益（当初SL距離を1Rとした倍数）。SL到達は-1.0、TP到達は+risk_reward_ratio、期限切れ(EXPIRED)は決済想定時点の実際のR",
            "max_drawdown_r": f"pnl_rの累積値（基準値{DRAWDOWN_BASELINE_R}Rから開始）に対する最大下落幅。Variant間比較専用の相対指標であり口座資金とは無関係",
            "average_checkpoint_r": "Entry後の固定バー数(1/2/3/5/10/20)時点の価格をR換算した平均値。SL/TP到達等でShadow Tradeが先に終了した場合、到達しなかった本数は集計対象外",
            "pre_entry_mae_r": "Setup成立bar終値を基準に、Entry確定までの間に想定方向と逆側へ最も動いた距離のR換算",
            "pre_entry_mfe_r": "Setup成立bar終値を基準に、Entry確定までの間に想定方向へ最も動いた距離のR換算",
            "trigger_found_rate": "Setup成立後、InpEntryTimingMaxWaitBars以内にTrigger（再加速）が成立した割合",
        },
        "pre_entry_excursion": pre_entry,
        "variants": variants,
    }
    paths = {
        "json": output_directory / "entry-timing-report.json",
        "markdown": output_directory / "entry-timing-report.md",
        "setups": output_directory / "entry-timing-setups.csv",
        "trades": output_directory / "entry-timing-trades.csv",
    }
    paths["json"].write_text(
        json.dumps(report, ensure_ascii=False, indent=2, allow_nan=False) + "\n", encoding="utf-8",
    )
    paths["markdown"].write_text(_markdown(variants, pre_entry), encoding="utf-8")
    setups.to_csv(paths["setups"], index=False)
    trades.to_csv(paths["trades"], index=False)
    return paths


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Entry Timing比較分析（IMMEDIATE/WAIT_1_BAR/WAIT_2_BARS/WAIT_TRIGGER）")
    parser.add_argument("--input", type=Path, action="append", required=True, help="監査JSONL。複数指定可")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(argv)
    setups, trades = build_entry_timing_context(args.input)
    write_report(args.output, setups, trades)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
