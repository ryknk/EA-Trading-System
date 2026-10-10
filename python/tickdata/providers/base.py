from __future__ import annotations

from abc import ABC, abstractmethod
from pathlib import Path
from typing import Iterator

from ..chunks import Chunk
from ..config import DatasetConfig
from ..model import RejectedRow, Tick, REASON_PARSE_ERROR


class ProviderError(RuntimeError):
    """取得失敗。retryable=Falseは環境・設定不備で、再試行しても直らない失敗。"""

    def __init__(self, message: str, retryable: bool = True) -> None:
        super().__init__(message)
        self.retryable = retryable


class TickProvider(ABC):
    """データソース固有の取得・パースを閉じ込めるAdapter。後段は共通Tickだけを扱う。"""

    name: str = ""
    raw_suffix: str = ".csv"
    source_format: str = ""

    def __init__(self, config: DatasetConfig) -> None:
        self.config = config
        self.options = config.provider_options

    @abstractmethod
    def download_chunk(self, chunk: Chunk, destination: Path) -> None:
        """chunkの範囲のrawデータをdestinationへ書く（呼び出し側が.partを渡し、完了後にrenameする）。"""

    @abstractmethod
    def iter_rows(self, raw_path: Path) -> Iterator[Tick | RejectedRow]:
        """rawファイルを1行ずつ共通Tickへ変換する。全件をメモリへ読み込まないこと。"""


def iter_header_csv_rows(
    raw_path: Path, timestamp_column: str, bid_column: str, ask_column: str,
    bid_volume_column: str | None, ask_volume_column: str | None,
) -> Iterator[Tick | RejectedRow]:
    """ヘッダー付きCSV（UTCエポックミリ秒）の共通パーサ。列順ではなく列名で対応付ける。"""
    with raw_path.open("r", encoding="utf-8", newline="") as handle:
        header = handle.readline().strip().split(",")
        if header == [""]:
            return
        try:
            index = {name: header.index(name) for name in (timestamp_column, bid_column, ask_column)}
            bid_volume_index = header.index(bid_volume_column) if bid_volume_column in header else None
            ask_volume_index = header.index(ask_volume_column) if ask_volume_column in header else None
        except ValueError as error:
            raise ProviderError(f"rawファイルの列が想定と異なります: {raw_path.name}: {error}", retryable=False) from error

        for line_number, line in enumerate(handle, start=2):
            parts = line.strip().split(",")
            if not parts or parts == [""]:
                continue
            try:
                yield Tick(
                    int(float(parts[index[timestamp_column]])),
                    float(parts[index[bid_column]]),
                    float(parts[index[ask_column]]),
                    float(parts[bid_volume_index]) if bid_volume_index is not None else 0.0,
                    float(parts[ask_volume_index]) if ask_volume_index is not None else 0.0,
                )
            except (ValueError, IndexError):
                yield RejectedRow(line_number, REASON_PARSE_ERROR)
