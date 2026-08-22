from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Any, Iterable

import pandas as pd

from .performance import (
    SNAPSHOT_COLUMNS,
    TRADE_COLUMNS,
    PerformanceMetrics,
    aggregate_trade_group,
    analyze_performance,
    normalize_closed_trades,
    normalize_equity_snapshots,
)

AUDIT_ROOT_FIELDS = {
    "schema_version", "event_id", "trade_candidate_id", "request_id", "ea_id",
    "timestamp", "event_type", "symbol", "payload",
}
SUPPORTED_AUDIT_EVENTS = {
    "CANDIDATE", "EXTERNAL_DECISION", "RISK_DECISION", "ORDER_SUBMISSION", "DEAL",
    "POSITION_SNAPSHOT", "TRADE_CLOSED", "ACCOUNT_SNAPSHOT", "SYSTEM_ERROR",
    "TRADE_ANALYTICS", "TIME_STOP_EXIT", "ENTRY_PIPELINE",
    "ENTRY_TIMING_SETUP", "ENTRY_TIMING_TRADE",
}


@dataclass(frozen=True)
class AnalysisInputs:
    trades: pd.DataFrame
    equity_snapshots: pd.DataFrame


def _strict_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON field: {key}")
        result[key] = value
    return result


def read_json_lines(path: Path) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8-sig") as stream:
        for line_number, raw in enumerate(stream, start=1):
            if not raw.strip():
                continue
            try:
                record = json.loads(
                    raw, object_pairs_hook=_strict_object,
                    parse_constant=lambda token: (_ for _ in ()).throw(ValueError(token)),
                )
            except (json.JSONDecodeError, ValueError) as exc:
                raise ValueError(f"invalid JSONL at {path}:{line_number}") from exc
            if not isinstance(record, dict):
                raise ValueError(f"JSONL record must be an object at {path}:{line_number}")
            records.append(record)
    return records


def _audit_inputs(records: list[dict[str, Any]]) -> AnalysisInputs:
    strategies: dict[str, str] = {}
    for record in records:
        if set(record) != AUDIT_ROOT_FIELDS or record.get("schema_version") != "1.0":
            raise ValueError("audit event does not match schema version 1.0")
        if record.get("event_type") not in SUPPORTED_AUDIT_EVENTS:
            raise ValueError("unsupported audit event type")
        if not isinstance(record.get("payload"), dict):
            raise ValueError("audit payload must be an object")
        if record["event_type"] == "CANDIDATE":
            pattern = record["payload"].get("pattern")
            if not isinstance(pattern, str) or not pattern:
                raise ValueError("candidate pattern is missing")
            strategies.setdefault(record["trade_candidate_id"], pattern)

    trades: list[dict[str, Any]] = []
    snapshots: list[dict[str, Any]] = []
    for record in records:
        payload = record["payload"]
        if record["event_type"] == "TRADE_CLOSED":
            required = {
                "position_ticket", "direction", "open_time", "close_time", "volume",
                "open_price", "close_price", "close_reason", "pnl", "commission", "swap",
                "exit_spread_points", "point_value",
            }
            if set(payload) != required:
                raise ValueError("TRADE_CLOSED payload fields do not match Phase 9")
            candidate_id = record["trade_candidate_id"]
            trades.append({
                "trade_id": f"{candidate_id}:{payload['position_ticket']}",
                "trade_candidate_id": candidate_id,
                "symbol": record["symbol"],
                "strategy": strategies.get(candidate_id, "UNKNOWN"),
                "direction": payload["direction"],
                "open_time": payload["open_time"], "close_time": payload["close_time"],
                "volume": payload["volume"], "open_price": payload["open_price"],
                "close_price": payload["close_price"],
                # Phase 9のpnlはcommission/swap/fee込み。再加算しない。
                "net_pnl": payload["pnl"], "commission": payload["commission"],
                "swap": payload["swap"],
            })
        elif record["event_type"] == "ACCOUNT_SNAPSHOT":
            if "equity" not in payload:
                raise ValueError("ACCOUNT_SNAPSHOT equity is missing")
            snapshots.append({"timestamp": record["timestamp"], "equity": payload["equity"]})
    return AnalysisInputs(
        normalize_closed_trades(pd.DataFrame(trades, columns=TRADE_COLUMNS)),
        normalize_equity_snapshots(pd.DataFrame(snapshots, columns=SNAPSHOT_COLUMNS)),
    )


def load_analysis_inputs(paths: Iterable[Path]) -> AnalysisInputs:
    trade_frames: list[pd.DataFrame] = []
    snapshot_frames: list[pd.DataFrame] = []
    audit_records: list[dict[str, Any]] = []
    for path in paths:
        if path.suffix.lower() == ".csv":
            trade_frames.append(normalize_closed_trades(pd.read_csv(path)))
        elif path.suffix.lower() in {".jsonl", ".ndjson"}:
            records = read_json_lines(path)
            if records and "event_type" not in records[0]:
                trade_frames.append(normalize_closed_trades(pd.DataFrame(records)))
            else:
                audit_records.extend(records)
        else:
            raise ValueError(f"unsupported input extension: {path.suffix}")
    if audit_records:
        parsed = _audit_inputs(audit_records)
        trade_frames.append(parsed.trades)
        snapshot_frames.append(parsed.equity_snapshots)
    trades = pd.concat(trade_frames, ignore_index=True) if trade_frames else pd.DataFrame(columns=TRADE_COLUMNS)
    snapshots = (
        pd.concat(snapshot_frames, ignore_index=True)
        if snapshot_frames else pd.DataFrame(columns=SNAPSHOT_COLUMNS)
    )
    return AnalysisInputs(normalize_closed_trades(trades), normalize_equity_snapshots(snapshots))


def load_snapshot_csv(path: Path) -> pd.DataFrame:
    return normalize_equity_snapshots(pd.read_csv(path))


def grouped_performance(trades: pd.DataFrame, group: str) -> list[dict[str, Any]]:
    if group not in {"strategy", "symbol"}:
        raise ValueError("group must be strategy or symbol")
    return [
        {group: str(name), **aggregate_trade_group(part["net_pnl"])}
        for name, part in trades.groupby(group, sort=True)
    ]


def monthly_performance(trades: pd.DataFrame, initial_balance: float) -> pd.DataFrame:
    columns = ["month", "net_profit", "number_of_trades", "starting_balance", "return_rate"]
    if trades.empty:
        return pd.DataFrame(columns=columns)
    grouped = trades.set_index("close_time").resample("MS")["net_pnl"].agg(["sum", "count"])
    grouped = grouped[grouped["count"] > 0]
    grouped["starting_balance"] = initial_balance + grouped["sum"].cumsum().shift(1, fill_value=0.0)
    grouped["return_rate"] = grouped["sum"] / grouped["starting_balance"]
    return pd.DataFrame({
        "month": grouped.index.strftime("%Y-%m"), "net_profit": grouped["sum"].to_numpy(),
        "number_of_trades": grouped["count"].astype(int).to_numpy(),
        "starting_balance": grouped["starting_balance"].to_numpy(),
        "return_rate": grouped["return_rate"].to_numpy(),
    }, columns=columns)


def _markdown(metrics: PerformanceMetrics, by_strategy: list[dict[str, Any]], by_symbol: list[dict[str, Any]]) -> str:
    value = metrics.to_dict()
    def percent(number: float | None) -> str:
        return "算出不能" if number is None else f"{number:.2%}"
    def number(number_value: float | None) -> str:
        return "算出不能" if number_value is None else f"{number_value:.4f}"
    lines = [
        "# パフォーマンス分析レポート", "",
        f"- 取引数: {value['number_of_trades']}",
        f"- 純利益: {value['net_profit']:.2f}",
        f"- 収益率: {percent(value['return_rate'])}",
        f"- CAGR: {percent(value['cagr'])}",
        f"- 最大ドローダウン: {value['max_drawdown_amount']:.2f} ({percent(value['max_drawdown_rate'])})",
        f"- ドローダウン算出元: {value['drawdown_source']}",
        f"- プロフィットファクター: {number(value['profit_factor'])}",
        f"- シャープレシオ: {number(value['sharpe_ratio'])}",
        f"- 勝率: {percent(value['win_rate'])}",
        f"- 期待値: {value['expectancy']:.2f}",
        f"- 最大連敗: {value['maximum_consecutive_losses']}", "",
        "バックテスト結果だけを本番移行理由にしないでください。OOS、ウォークフォワード、デモ、小額実口座の順に検証します。",
        "", "## Strategy別", "", "```json", json.dumps(by_strategy, ensure_ascii=False, indent=2), "```",
        "", "## Symbol別", "", "```json", json.dumps(by_symbol, ensure_ascii=False, indent=2), "```", "",
    ]
    return "\n".join(lines)


def write_report(
    output_directory: Path,
    metrics: PerformanceMetrics,
    equity_curve: pd.DataFrame,
    trades: pd.DataFrame,
    generated_at: datetime | None = None,
) -> dict[str, Path]:
    output_directory.mkdir(parents=True, exist_ok=True)
    by_strategy = grouped_performance(trades, "strategy")
    by_symbol = grouped_performance(trades, "symbol")
    monthly = monthly_performance(trades, metrics.starting_balance)
    report = {
        "schema_version": "1.0",
        "generated_at": (generated_at or datetime.now(UTC)).isoformat().replace("+00:00", "Z"),
        "currency": "ACCOUNT_CURRENCY",
        "definitions": {
            "net_pnl": "手数料・スワップ・fee込みの決済済み取引損益",
            "sharpe": f"{metrics.sharpe_source}の暦日の日次収益率、標本標準偏差、年率化係数sqrt(365.2425)",
            "max_drawdown": metrics.drawdown_source,
        },
        "metrics": metrics.to_dict(), "by_strategy": by_strategy, "by_symbol": by_symbol,
    }
    paths = {
        "json": output_directory / "performance-summary.json",
        "markdown": output_directory / "report.md",
        "trades": output_directory / "trades-normalized.csv",
        "equity": output_directory / "equity-curve.csv",
        "monthly": output_directory / "monthly-performance.csv",
    }
    paths["json"].write_text(
        json.dumps(report, ensure_ascii=False, indent=2, allow_nan=False) + "\n", encoding="utf-8",
    )
    paths["markdown"].write_text(_markdown(metrics, by_strategy, by_symbol), encoding="utf-8")
    trades.to_csv(paths["trades"], index=False)
    equity_curve.to_csv(paths["equity"], index=False)
    monthly.to_csv(paths["monthly"], index=False)
    return paths


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="EA取引監査ログのパフォーマンス分析")
    parser.add_argument("--input", type=Path, action="append", required=True, help="CSVまたは監査JSONL。複数指定可")
    parser.add_argument("--snapshot-csv", type=Path, help="timestamp,equity形式の追加口座スナップショット")
    parser.add_argument("--initial-balance", type=float, required=True)
    parser.add_argument("--annual-risk-free-rate", type=float, default=0.0)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(argv)
    inputs = load_analysis_inputs(args.input)
    snapshots = load_snapshot_csv(args.snapshot_csv) if args.snapshot_csv else inputs.equity_snapshots
    metrics, curve, trades = analyze_performance(
        inputs.trades, args.initial_balance, snapshots, args.annual_risk_free_rate,
    )
    write_report(args.output, metrics, curve, trades)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
