from __future__ import annotations

import time
from dataclasses import dataclass
from datetime import date, datetime, timezone
from zoneinfo import ZoneInfo

_NEW_YORK = ZoneInfo("America/New_York")
_MS_PER_HOUR = 3_600_000
# NY 17:00クローズを日付境界とするFXブローカーのサーバー時刻 = NY現地時刻 + 7時間
_NY_CLOSE_SHIFT_MS = 7 * _MS_PER_HOUR


def utc_ms_to_iso(timestamp_ms: int) -> str:
    seconds, millis = divmod(timestamp_ms, 1000)
    moment = datetime.fromtimestamp(seconds, tz=timezone.utc)
    return moment.strftime("%Y-%m-%dT%H:%M:%S") + f".{millis:03d}Z"


def wall_text_to_ms(text: str) -> int:
    """MT5タブCSV表記`YYYY.MM.DD HH:MM:SS.mmm`（サーバー時刻の時計表示）をエポックミリ秒へ変換する。"""
    moment = datetime.strptime(text[:19], "%Y.%m.%d %H:%M:%S").replace(tzinfo=timezone.utc)
    return int(moment.timestamp()) * 1000 + int(text[20:23])


def utc_date_to_ms(day: date) -> int:
    return int(datetime(day.year, day.month, day.day, tzinfo=timezone.utc).timestamp()) * 1000


def parse_date(value: str) -> date:
    """`2016-09-01`・`2016.09.01`・`2016/09/01`を受け付ける。"""
    normalized = value.strip().replace(".", "-").replace("/", "-")
    try:
        return date.fromisoformat(normalized)
    except ValueError as error:
        raise ValueError(f"日付を解釈できません（YYYY-MM-DD / YYYY.MM.DD）: {value!r}") from error


@dataclass(frozen=True)
class ServerTimeRule:
    """UTCからMT5サーバー時刻（時計表示をそのままエポック秒として保持する値）への変換規則。

    MT5のtick履歴・バーはサーバー時刻の時計表示をエポック秒として扱うため、
    D1・H4バーの境界は、ここで選んだ規則に依存する。
    """

    mode: str
    offset_hours: float = 0.0

    def __post_init__(self) -> None:
        if self.mode not in {"utc", "fixed", "ny_close"}:
            raise ValueError(f"server_time.modeはutc・fixed・ny_closeのいずれかです: {self.mode!r}")
        if self.mode == "fixed" and not -14.0 <= self.offset_hours <= 14.0:
            raise ValueError(f"server_time.offset_hoursが範囲外です: {self.offset_hours}")

    @classmethod
    def from_config(cls, value: dict | None) -> "ServerTimeRule":
        if not value or "mode" not in value:
            raise ValueError(
                "server_timeが未指定です。MT5サーバー時刻はBrokerごとに異なるため、"
                "utc・fixed（offset_hours）・ny_closeのいずれかを明示してください。"
            )
        return cls(str(value["mode"]), float(value.get("offset_hours", 0.0)))

    def describe(self) -> dict:
        return {"mode": self.mode, "offset_hours": self.offset_hours}

    def offset_ms_at(self, timestamp_ms: int) -> int:
        if self.mode == "utc":
            return 0
        if self.mode == "fixed":
            return int(self.offset_hours * _MS_PER_HOUR)
        return _ny_offset_ms_for_hour(timestamp_ms // _MS_PER_HOUR) + _NY_CLOSE_SHIFT_MS

    def utc_ms_to_server_wall_ms(self, timestamp_ms: int) -> int:
        return timestamp_ms + self.offset_ms_at(timestamp_ms)

    def server_wall_ms_to_utc_ms(self, wall_ms: int) -> int:
        # DST切替の重複・欠落時刻（市場休場中）を除き一意に戻せる。2回の不動点反復で収束する。
        utc_ms = wall_ms - self.offset_ms_at(wall_ms)
        return wall_ms - self.offset_ms_at(utc_ms)


_ny_offset_cache: dict[int, int] = {}


def _ny_offset_ms_for_hour(hour_index: int) -> int:
    # 米国のDST切替は必ずUTCの整時で起きるため、1時間単位でキャッシュして問題ない
    cached = _ny_offset_cache.get(hour_index)
    if cached is None:
        moment = datetime.fromtimestamp(hour_index * 3600, tz=_NEW_YORK)
        cached = int(moment.utcoffset().total_seconds()) * 1000
        _ny_offset_cache[hour_index] = cached
    return cached


class WallClockFormatter:
    """MT5タブCSVの`YYYY.MM.DD` / `HH:MM:SS.mmm`表記。同一秒の連続呼び出しを高速化する。"""

    def __init__(self) -> None:
        self._second = -1
        self._date = ""
        self._time = ""

    def format(self, wall_ms: int) -> tuple[str, str]:
        second, millis = divmod(wall_ms, 1000)
        if second != self._second:
            parts = time.gmtime(second)
            self._second = second
            self._date = f"{parts.tm_year:04d}.{parts.tm_mon:02d}.{parts.tm_mday:02d}"
            self._time = f"{parts.tm_hour:02d}:{parts.tm_min:02d}:{parts.tm_sec:02d}"
        return self._date, f"{self._time}.{millis:03d}"
