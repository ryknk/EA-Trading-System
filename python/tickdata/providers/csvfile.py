from __future__ import annotations

import shutil
import zipfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterator

from ..chunks import Chunk
from ..model import RejectedRow, Tick, REASON_PARSE_ERROR
from ..timeutil import ServerTimeRule
from .base import ProviderError, TickProvider, iter_header_csv_rows


class CsvFileProvider(TickProvider):
    """取得済みのtick CSV（OANDA証券のMT5標準タブ形式など）を共通形式へ取り込むProvider。

    provider_options:
      source_dir: 元ファイルのフォルダ
      source_pattern: ファイル名パターン。{yyyy}・{mm}・{dd}を使える（.zipは単一メンバーを展開）
      source_format: "mt5-tab"（<DATE> <TIME> <BID> <ASK>のタブ区切り）または"header-csv"（列名 timestamp,bid,ask）
      source_time: mt5-tabの時刻の基準（server_timeと同じ形式: {"mode":"utc"|"fixed"|"ny_close",...}）。必須
    """

    name = "csvfile"

    def __init__(self, config) -> None:
        super().__init__(config)
        self._format = str(self.options.get("source_format", "mt5-tab"))
        if self._format not in {"mt5-tab", "header-csv"}:
            raise ProviderError(f"source_formatが不正です: {self._format!r}", retryable=False)
        self.source_format = (
            "MT5 tab CSV (<DATE> <TIME> <BID> <ASK>, source_time基準)" if self._format == "mt5-tab"
            else "header CSV (timestamp=UTC epoch ms, bid, ask, bid_volume, ask_volume)"
        )
        self._source_time = None
        if self._format == "mt5-tab":
            try:
                self._source_time = ServerTimeRule.from_config(self.options.get("source_time"))
            except ValueError as error:
                raise ProviderError(f"provider_options.source_time: {error}", retryable=False) from error

    def _source_file(self, chunk: Chunk) -> Path:
        directory, pattern = self.options.get("source_dir"), self.options.get("source_pattern")
        if not directory or not pattern:
            raise ProviderError("provider_optionsにsource_dirとsource_patternが必要です。", retryable=False)
        name = str(pattern).format(
            yyyy=f"{chunk.first_date.year:04d}", mm=f"{chunk.first_date.month:02d}", dd=f"{chunk.first_date.day:02d}"
        )
        return Path(directory) / name

    def download_chunk(self, chunk: Chunk, destination: Path) -> None:
        source = self._source_file(chunk)
        if not source.exists():
            raise ProviderError(f"元ファイルが見つかりません: {source}", retryable=False)
        if source.suffix.lower() == ".zip":
            with zipfile.ZipFile(source) as archive:
                members = [item for item in archive.infolist() if not item.is_dir()]
                if len(members) != 1:
                    raise ProviderError(f"zip内のファイルが1つではありません: {source}", retryable=False)
                with archive.open(members[0]) as reader, destination.open("wb") as writer:
                    shutil.copyfileobj(reader, writer, 1024 * 1024)
        else:
            shutil.copyfile(source, destination)

    def iter_rows(self, raw_path: Path) -> Iterator[Tick | RejectedRow]:
        if self._format == "header-csv":
            return iter_header_csv_rows(raw_path, "timestamp", "bid", "ask", "bid_volume", "ask_volume")
        return self._iter_mt5_tab(raw_path)

    def _iter_mt5_tab(self, raw_path: Path) -> Iterator[Tick | RejectedRow]:
        rule = self._source_time
        day_cache: dict[str, int] = {}
        with raw_path.open("r", encoding="utf-8", errors="replace", newline="") as handle:
            for line_number, line in enumerate(handle, start=1):
                if line_number == 1 and line.startswith("<"):
                    continue  # ヘッダー行
                parts = line.rstrip("\r\n").split("\t")
                if len(parts) < 4:
                    if line.strip():
                        yield RejectedRow(line_number, REASON_PARSE_ERROR)
                    continue
                try:
                    wall_ms = _parse_wall_ms(parts[0], parts[1], day_cache)
                    yield Tick(rule.server_wall_ms_to_utc_ms(wall_ms), float(parts[2]), float(parts[3]))
                except (ValueError, IndexError):
                    yield RejectedRow(line_number, REASON_PARSE_ERROR)


def _parse_wall_ms(date_text: str, time_text: str, day_cache: dict[str, int]) -> int:
    day_ms = day_cache.get(date_text)
    if day_ms is None:
        year, month, day = (int(part) for part in date_text.split("."))
        day_ms = int(datetime(year, month, day, tzinfo=timezone.utc).timestamp()) * 1000
        day_cache[date_text] = day_ms
    clock, _, fraction = time_text.partition(".")
    hour, minute, second = (int(part) for part in clock.split(":"))
    millis = int(fraction.ljust(3, "0")[:3]) if fraction else 0
    return day_ms + ((hour * 60 + minute) * 60 + second) * 1000 + millis
