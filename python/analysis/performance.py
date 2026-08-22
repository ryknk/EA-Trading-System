from __future__ import annotations

import math
from dataclasses import asdict, dataclass
from typing import Any

import numpy as np
import pandas as pd

from .drawdown import DrawdownStats, build_drawdown_curve, summarize_drawdown

TRADE_COLUMNS = [
    "trade_id", "trade_candidate_id", "symbol", "strategy", "direction",
    "open_time", "close_time", "volume", "open_price", "close_price",
    "net_pnl", "commission", "swap",
]
SNAPSHOT_COLUMNS = ["timestamp", "equity"]
SECONDS_PER_YEAR = 365.2425 * 24 * 60 * 60


@dataclass(frozen=True)
class PerformanceMetrics:
    starting_balance: float
    ending_balance: float
    net_profit: float
    return_rate: float
    cagr: float | None
    gross_profit: float
    gross_loss: float
    profit_factor: float | None
    sharpe_ratio: float | None
    sharpe_source: str
    win_rate: float
    average_win: float | None
    average_loss: float | None
    expectancy: float
    maximum_consecutive_losses: int
    number_of_trades: int
    analysis_start: str | None
    analysis_end: str | None
    duration_days: float
    drawdown_source: str
    max_drawdown_amount: float
    max_drawdown_rate: float
    drawdown_peak_time: str | None
    drawdown_trough_time: str | None
    drawdown_recovery_time: str | None
    closed_trade_max_drawdown_amount: float
    closed_trade_max_drawdown_rate: float

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


def _require_timezone(values: pd.Series, name: str) -> None:
    for value in values.dropna():
        if isinstance(value, str) and not (value.endswith("Z") or "+" in value[10:] or "-" in value[10:]):
            raise ValueError(f"{name} must include a UTC offset")
        if isinstance(value, (pd.Timestamp,)) and value.tzinfo is None:
            raise ValueError(f"{name} must be timezone-aware")


def normalize_closed_trades(frame: pd.DataFrame) -> pd.DataFrame:
    missing = set(TRADE_COLUMNS) - set(frame.columns)
    unknown = set(frame.columns) - set(TRADE_COLUMNS)
    if missing or unknown:
        raise ValueError(f"trade columns mismatch: missing={sorted(missing)}, unknown={sorted(unknown)}")
    result = frame[TRADE_COLUMNS].copy()
    if result.empty:
        result["open_time"] = pd.to_datetime(result["open_time"], utc=True)
        result["close_time"] = pd.to_datetime(result["close_time"], utc=True)
        return result
    for column in ("trade_id", "trade_candidate_id", "symbol", "strategy", "direction"):
        if result[column].isna().any() or (result[column].astype(str).str.len() == 0).any():
            raise ValueError(f"{column} must be non-empty")
        result[column] = result[column].astype(str)
    if result["trade_id"].duplicated().any():
        raise ValueError("trade_id must be unique")
    if not result["direction"].isin(["BUY", "SELL"]).all():
        raise ValueError("direction must be BUY or SELL")
    _require_timezone(result["open_time"], "open_time")
    _require_timezone(result["close_time"], "close_time")
    result["open_time"] = pd.to_datetime(result["open_time"], utc=True, errors="raise")
    result["close_time"] = pd.to_datetime(result["close_time"], utc=True, errors="raise")
    if (result["close_time"] < result["open_time"]).any():
        raise ValueError("close_time must not precede open_time")
    numeric = ["volume", "open_price", "close_price", "net_pnl", "commission", "swap"]
    for column in numeric:
        result[column] = pd.to_numeric(result[column], errors="raise")
    if not np.isfinite(result[numeric].to_numpy(dtype=float)).all():
        raise ValueError("trade numeric values must be finite")
    if (result[["volume", "open_price", "close_price"]] <= 0).any().any():
        raise ValueError("volume and prices must be positive")
    return result.sort_values(["close_time", "trade_id"], kind="stable").reset_index(drop=True)


def normalize_equity_snapshots(frame: pd.DataFrame | None) -> pd.DataFrame:
    if frame is None:
        return pd.DataFrame(columns=SNAPSHOT_COLUMNS)
    if set(frame.columns) != set(SNAPSHOT_COLUMNS):
        raise ValueError("snapshot columns must be timestamp and equity")
    result = frame[SNAPSHOT_COLUMNS].copy()
    if result.empty:
        result["timestamp"] = pd.to_datetime(result["timestamp"], utc=True)
        return result
    _require_timezone(result["timestamp"], "timestamp")
    result["timestamp"] = pd.to_datetime(result["timestamp"], utc=True, errors="raise")
    result["equity"] = pd.to_numeric(result["equity"], errors="raise")
    if not np.isfinite(result["equity"].to_numpy(dtype=float)).all() or (result["equity"] <= 0).any():
        raise ValueError("snapshot equity must be finite and positive")
    if result["timestamp"].duplicated().any():
        raise ValueError("snapshot timestamps must be unique")
    return result.sort_values("timestamp", kind="stable").reset_index(drop=True)


def realized_equity_curve(trades: pd.DataFrame, initial_balance: float) -> pd.DataFrame:
    if trades.empty:
        return pd.DataFrame({
            "timestamp": pd.Series(dtype="datetime64[ns, UTC]"),
            "equity": pd.Series(dtype=float),
        })
    pnl = trades.groupby("close_time", sort=True)["net_pnl"].sum()
    equity = initial_balance + pnl.cumsum()
    if (equity <= 0).any():
        raise ValueError("realized equity reached zero or below")
    return pd.DataFrame({"timestamp": equity.index, "equity": equity.to_numpy(dtype=float)})


def _daily_returns(trades: pd.DataFrame, initial_balance: float) -> pd.Series:
    if trades.empty:
        return pd.Series(dtype=float)
    daily_pnl = trades.set_index("close_time")["net_pnl"].resample("1D").sum()
    previous_equity = initial_balance + daily_pnl.cumsum().shift(1, fill_value=0.0)
    if (previous_equity <= 0).any():
        raise ValueError("daily starting equity reached zero or below")
    return daily_pnl / previous_equity


def _snapshot_daily_returns(snapshots: pd.DataFrame, initial_balance: float) -> pd.Series:
    if snapshots.empty:
        return pd.Series(dtype=float)
    daily_equity = snapshots.set_index("timestamp")["equity"].resample("1D").last().ffill()
    returns = daily_equity.pct_change()
    returns.iloc[0] = float(daily_equity.iloc[0]) / initial_balance - 1.0
    return returns


def _sharpe(daily_returns: pd.Series, annual_risk_free_rate: float) -> float | None:
    if annual_risk_free_rate <= -1 or not math.isfinite(annual_risk_free_rate):
        raise ValueError("annual_risk_free_rate must be finite and greater than -1")
    if len(daily_returns) < 2:
        return None
    daily_rf = (1.0 + annual_risk_free_rate) ** (1.0 / 365.2425) - 1.0
    excess = daily_returns - daily_rf
    standard_deviation = float(excess.std(ddof=1))
    if standard_deviation == 0.0 or not math.isfinite(standard_deviation):
        return None
    return float(excess.mean() / standard_deviation * math.sqrt(365.2425))


def aggregate_trade_group(pnl: pd.Series) -> dict[str, Any]:
    wins = pnl[pnl > 0]
    losses = pnl[pnl < 0]
    gross_profit = float(wins.sum())
    gross_loss = float(losses.sum())
    return {
        "number_of_trades": int(len(pnl)),
        "net_profit": float(pnl.sum()) if len(pnl) else 0.0,
        "win_rate": float((pnl > 0).sum() / len(pnl)) if len(pnl) else 0.0,
        "profit_factor": None if gross_loss == 0 else gross_profit / abs(gross_loss),
        "expectancy": float(pnl.mean()) if len(pnl) else 0.0,
        "average_win": None if wins.empty else float(wins.mean()),
        "average_loss": None if losses.empty else float(losses.mean()),
    }


def _max_consecutive_losses(pnl: pd.Series) -> int:
    maximum = current = 0
    for value in pnl:
        current = current + 1 if value < 0 else 0
        maximum = max(maximum, current)
    return maximum


def _iso(value: pd.Timestamp | None) -> str | None:
    if value is None:
        return None
    return value.tz_convert("UTC").isoformat().replace("+00:00", "Z")


def analyze_performance(
    trades: pd.DataFrame,
    initial_balance: float,
    equity_snapshots: pd.DataFrame | None = None,
    annual_risk_free_rate: float = 0.0,
) -> tuple[PerformanceMetrics, pd.DataFrame, pd.DataFrame]:
    if not math.isfinite(initial_balance) or initial_balance <= 0:
        raise ValueError("initial_balance must be finite and positive")
    normalized = normalize_closed_trades(trades)
    snapshots = normalize_equity_snapshots(equity_snapshots)
    ending_balance = initial_balance + float(normalized["net_pnl"].sum())
    if ending_balance <= 0:
        raise ValueError("ending balance reached zero or below")

    realized = realized_equity_curve(normalized, initial_balance)
    realized_points = pd.concat([
        pd.DataFrame({
            "timestamp": [normalized["open_time"].min()] if not normalized.empty else [],
            "equity": [initial_balance] if not normalized.empty else [],
        }),
        realized,
    ], ignore_index=True)
    if not realized_points.empty:
        realized_points = realized_points.groupby("timestamp", as_index=False, sort=True)["equity"].last()
    realized_dd_curve = build_drawdown_curve(realized_points)
    realized_dd = summarize_drawdown(realized_dd_curve)

    selected_dd: DrawdownStats = realized_dd
    drawdown_source = "CLOSED_TRADES"
    selected_curve = realized_dd_curve
    sharpe_returns = _daily_returns(normalized, initial_balance)
    sharpe_source = "CLOSED_TRADES"
    if not snapshots.empty:
        first_snapshot_time = snapshots["timestamp"].min()
        baseline_time = normalized["open_time"].min() if not normalized.empty else first_snapshot_time
        if baseline_time >= first_snapshot_time:
            baseline_time = first_snapshot_time - pd.Timedelta(nanoseconds=1)
        snapshot_points = pd.concat([
            pd.DataFrame({"timestamp": [baseline_time], "equity": [initial_balance]}), snapshots,
        ], ignore_index=True)
        snapshot_curve = build_drawdown_curve(snapshot_points)
        selected_dd = summarize_drawdown(snapshot_curve)
        drawdown_source = "ACCOUNT_EQUITY_SNAPSHOTS"
        selected_curve = snapshot_curve
        sharpe_returns = _snapshot_daily_returns(snapshots, initial_balance)
        sharpe_source = "ACCOUNT_EQUITY_SNAPSHOTS"

    pnl = normalized["net_pnl"]
    wins = pnl[pnl > 0]
    losses = pnl[pnl < 0]
    gross_profit = float(wins.sum())
    gross_loss = float(losses.sum())
    profit_factor = None if gross_loss == 0 else gross_profit / abs(gross_loss)
    start = None if normalized.empty else normalized["open_time"].min()
    end = None if normalized.empty else normalized["close_time"].max()
    duration_seconds = 0.0 if start is None or end is None else max(0.0, (end - start).total_seconds())
    cagr = None
    if duration_seconds >= 86400.0:
        annualized_log_return = math.log(ending_balance / initial_balance) * SECONDS_PER_YEAR / duration_seconds
        if annualized_log_return <= 709.0:
            cagr = math.expm1(annualized_log_return)

    metrics = PerformanceMetrics(
        starting_balance=float(initial_balance), ending_balance=float(ending_balance),
        net_profit=float(ending_balance - initial_balance),
        return_rate=float(ending_balance / initial_balance - 1.0), cagr=cagr,
        gross_profit=gross_profit, gross_loss=gross_loss, profit_factor=profit_factor,
        sharpe_ratio=_sharpe(sharpe_returns, annual_risk_free_rate), sharpe_source=sharpe_source,
        win_rate=0.0 if normalized.empty else float(len(wins) / len(normalized)),
        average_win=None if wins.empty else float(wins.mean()),
        average_loss=None if losses.empty else float(losses.mean()),
        expectancy=0.0 if normalized.empty else float(pnl.mean()),
        maximum_consecutive_losses=_max_consecutive_losses(pnl), number_of_trades=len(normalized),
        analysis_start=_iso(start), analysis_end=_iso(end),
        duration_days=duration_seconds / 86400.0, drawdown_source=drawdown_source,
        max_drawdown_amount=selected_dd.max_drawdown_amount,
        max_drawdown_rate=selected_dd.max_drawdown_rate,
        drawdown_peak_time=selected_dd.peak_time, drawdown_trough_time=selected_dd.trough_time,
        drawdown_recovery_time=selected_dd.recovery_time,
        closed_trade_max_drawdown_amount=realized_dd.max_drawdown_amount,
        closed_trade_max_drawdown_rate=realized_dd.max_drawdown_rate,
    )
    return metrics, selected_curve, normalized
