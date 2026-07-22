from __future__ import annotations

from dataclasses import asdict, dataclass
from typing import Any

import numpy as np
import pandas as pd


@dataclass(frozen=True)
class DrawdownStats:
    max_drawdown_amount: float
    max_drawdown_rate: float
    peak_time: str | None
    trough_time: str | None
    recovery_time: str | None

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


def _iso(value: pd.Timestamp | None) -> str | None:
    if value is None or pd.isna(value):
        return None
    return value.tz_convert("UTC").isoformat().replace("+00:00", "Z")


def build_drawdown_curve(points: pd.DataFrame) -> pd.DataFrame:
    """timestamp/equity列からピークとドローダウン系列を作る。"""
    if set(points.columns) != {"timestamp", "equity"}:
        raise ValueError("drawdown input must contain exactly timestamp and equity")
    curve = points.copy()
    curve["timestamp"] = pd.to_datetime(curve["timestamp"], utc=True, errors="raise")
    curve["equity"] = pd.to_numeric(curve["equity"], errors="raise")
    if curve.empty:
        return pd.DataFrame(columns=[
            "timestamp", "equity", "peak_equity", "drawdown_amount", "drawdown_rate",
        ])
    if not np.isfinite(curve["equity"].to_numpy(dtype=float)).all() or (curve["equity"] <= 0).any():
        raise ValueError("equity must be finite and positive")
    curve = curve.sort_values("timestamp", kind="stable").reset_index(drop=True)
    if curve["timestamp"].duplicated().any():
        raise ValueError("equity timestamps must be unique")
    curve["peak_equity"] = curve["equity"].cummax()
    curve["drawdown_amount"] = curve["peak_equity"] - curve["equity"]
    curve["drawdown_rate"] = curve["drawdown_amount"] / curve["peak_equity"]
    return curve


def summarize_drawdown(curve: pd.DataFrame) -> DrawdownStats:
    if curve.empty:
        return DrawdownStats(0.0, 0.0, None, None, None)
    required = {"timestamp", "equity", "peak_equity", "drawdown_amount", "drawdown_rate"}
    if set(curve.columns) != required:
        raise ValueError("invalid drawdown curve")
    trough_index = int(curve["drawdown_rate"].to_numpy().argmax())
    trough = curve.iloc[trough_index]
    if float(trough["drawdown_amount"]) <= 0:
        return DrawdownStats(0.0, 0.0, None, None, None)
    peak_candidates = curve.iloc[: trough_index + 1]
    peak_candidates = peak_candidates[peak_candidates["equity"] == trough["peak_equity"]]
    peak = peak_candidates.iloc[-1]
    recovered = curve.iloc[trough_index + 1 :]
    recovered = recovered[recovered["equity"] >= trough["peak_equity"]]
    recovery_time = None if recovered.empty else _iso(recovered.iloc[0]["timestamp"])
    return DrawdownStats(
        max_drawdown_amount=float(trough["drawdown_amount"]),
        max_drawdown_rate=float(trough["drawdown_rate"]),
        peak_time=_iso(peak["timestamp"]),
        trough_time=_iso(trough["timestamp"]),
        recovery_time=recovery_time,
    )
