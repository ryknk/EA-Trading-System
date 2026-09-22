from __future__ import annotations

from dataclasses import dataclass
from datetime import date, timedelta

from .timeutil import utc_date_to_ms

CHUNK_UNITS = ("day", "month")


@dataclass(frozen=True)
class Chunk:
    """取得・正規化の最小単位。UTC基準の半開区間[start_ms, end_ms)。"""

    chunk_id: str
    start_ms: int
    end_ms: int
    first_date: date
    last_date: date

    @property
    def is_saturday_only(self) -> bool:
        return self.first_date == self.last_date and self.first_date.weekday() == 5


def _next_month_start(day: date) -> date:
    return date(day.year + (day.month == 12), day.month % 12 + 1, 1)


def plan_chunks(from_date: date, to_date: date, unit: str) -> list[Chunk]:
    """要求期間（両端を含むUTC日付）を、日または暦月のChunkへ分割する。"""
    if unit not in CHUNK_UNITS:
        raise ValueError(f"chunk_unitはday・monthのいずれかです: {unit!r}")
    if to_date < from_date:
        raise ValueError(f"toがfromより前です: from={from_date} to={to_date}")

    chunks: list[Chunk] = []
    cursor = from_date
    while cursor <= to_date:
        if unit == "day":
            last = cursor
            chunk_id = cursor.strftime("%Y%m%d")
        else:
            last = min(_next_month_start(cursor) - timedelta(days=1), to_date)
            chunk_id = cursor.strftime("%Y%m")
        chunks.append(Chunk(chunk_id, utc_date_to_ms(cursor), utc_date_to_ms(last + timedelta(days=1)), cursor, last))
        cursor = last + timedelta(days=1)
    return chunks
