from __future__ import annotations

import math
from dataclasses import dataclass
from typing import Literal

import pandas as pd

Outcome = Literal["TP", "SL", "CENSORED", "AMBIGUOUS"]


@dataclass(frozen=True)
class FirstTouchLabel:
    outcome: Outcome
    label_win: int | None
    label_return: float | None
    bars_to_outcome: int | None


def first_touch_label(direction: str, entry_price: float, stop_loss: float,
                      take_profit: float, future_bars: pd.DataFrame,
                      round_trip_cost_return: float = 0.0) -> FirstTouchLabel:
    """将来OHLCからTP/SLの先着だけを判定する。同一バー両到達は推測しない。"""
    if direction not in {"BUY", "SELL"}:
        raise ValueError("direction must be BUY or SELL")
    if not {"high", "low"}.issubset(future_bars.columns) or future_bars.empty:
        raise ValueError("future bars with high and low are required")
    numbers = [entry_price, stop_loss, take_profit, round_trip_cost_return]
    if not all(math.isfinite(value) for value in numbers) or min(entry_price, stop_loss, take_profit) <= 0:
        raise ValueError("label price input is invalid")
    if round_trip_cost_return < 0:
        raise ValueError("round trip cost must not be negative")
    geometry_valid = stop_loss < entry_price < take_profit if direction == "BUY" else take_profit < entry_price < stop_loss
    if not geometry_valid:
        raise ValueError("trade geometry is invalid")

    for offset, row in enumerate(future_bars.itertuples(index=False), start=1):
        high, low = float(row.high), float(row.low)
        if not math.isfinite(high) or not math.isfinite(low) or low > high:
            raise ValueError("future OHLC is invalid")
        tp_hit = high >= take_profit if direction == "BUY" else low <= take_profit
        sl_hit = low <= stop_loss if direction == "BUY" else high >= stop_loss
        if tp_hit and sl_hit:
            return FirstTouchLabel("AMBIGUOUS", None, None, offset)
        if tp_hit or sl_hit:
            exit_price = take_profit if tp_hit else stop_loss
            signed_return = (exit_price - entry_price) / entry_price
            if direction == "SELL":
                signed_return = -signed_return
            net_return = signed_return - round_trip_cost_return
            return FirstTouchLabel("TP" if tp_hit else "SL", 1 if tp_hit else 0, net_return, offset)
    return FirstTouchLabel("CENSORED", None, None, None)

