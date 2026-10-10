from __future__ import annotations

import math
from dataclasses import dataclass
from decimal import Decimal

# 正規化済みtickの形式識別子。列構成を変えるときは必ず更新する。
NORMALIZED_FORMAT = "tickdata-csv-v1"
NORMALIZED_HEADER = "timestamp_ms,bid,ask,bid_volume,ask_volume"

REASON_PARSE_ERROR = "PARSE_ERROR"
REASON_NON_FINITE = "NON_FINITE_VALUE"
REASON_NON_POSITIVE_PRICE = "NON_POSITIVE_PRICE"
REASON_CROSSED_QUOTE = "CROSSED_QUOTE"
REASON_INVALID_VOLUME = "INVALID_VOLUME"
REASON_OUT_OF_RANGE = "TIMESTAMP_OUT_OF_RANGE"


@dataclass(frozen=True, slots=True)
class Tick:
    """UTCエポックミリ秒を時刻とする共通tick。symbol・providerはデータセット単位のmanifestで持つ。"""

    timestamp_ms: int
    bid: float
    ask: float
    bid_volume: float = 0.0
    ask_volume: float = 0.0


@dataclass(frozen=True, slots=True)
class RejectedRow:
    """Providerがパースできなかった行。数だけをmanifestへ記録し、データには含めない。"""

    line_number: int
    reason: str


def find_invalid_reason(tick: Tick) -> str | None:
    """MT5へ渡してはならないtickの理由コードを返す（正常ならNone）。"""
    values = (tick.bid, tick.ask, tick.bid_volume, tick.ask_volume)
    if not all(math.isfinite(value) for value in values):
        return REASON_NON_FINITE
    if tick.bid <= 0.0 or tick.ask <= 0.0:
        return REASON_NON_POSITIVE_PRICE
    if tick.bid > tick.ask:
        return REASON_CROSSED_QUOTE
    if tick.bid_volume < 0.0 or tick.ask_volume < 0.0:
        return REASON_INVALID_VOLUME
    return None


def format_number(value: float) -> str:
    """指数表記を避けた最短のround-trip表現（MT5のStringToDoubleが扱える形式）。"""
    text = repr(value)
    return format(Decimal(text), "f") if "e" in text or "E" in text else text


def format_normalized_row(tick: Tick) -> str:
    return (
        f"{tick.timestamp_ms},{format_number(tick.bid)},{format_number(tick.ask)},"
        f"{format_number(tick.bid_volume)},{format_number(tick.ask_volume)}"
    )


def parse_normalized_row(line: str) -> Tick:
    """正規化CSVの1行をTickへ変換する。不正な行はValueErrorを送出する。"""
    parts = line.split(",")
    if len(parts) != 5:
        raise ValueError(f"列数が不正です: {line!r}")
    return Tick(int(parts[0]), float(parts[1]), float(parts[2]), float(parts[3]), float(parts[4]))
