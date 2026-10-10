from __future__ import annotations

import random
import zlib
from datetime import timedelta
from pathlib import Path
from typing import Iterator

from ..chunks import Chunk
from ..model import RejectedRow, Tick
from ..timeutil import utc_date_to_ms
from .base import ProviderError, TickProvider, iter_header_csv_rows


class MockProvider(TickProvider):
    """ネットワーク不要の決定的な合成tick。テスト・配線確認専用で、市場データとして使ってはならない。

    provider_options:
      ticks_per_day: 1日あたりのtick数（既定200）
      base_price / spread: 初期価格・スプレッド
      fail_chunks: {chunk_id: 失敗させる回数}（リトライ・resumeの試験用）
    """

    name = "mock"
    source_format = "mock CSV (timestamp=UTC epoch ms, bid, ask, bid_volume, ask_volume)"

    def __init__(self, config) -> None:
        super().__init__(config)
        self._failures_left: dict[str, int] = dict(self.options.get("fail_chunks", {}))
        self.download_calls: list[str] = []

    def download_chunk(self, chunk: Chunk, destination: Path) -> None:
        self.download_calls.append(chunk.chunk_id)
        if self._failures_left.get(chunk.chunk_id, 0) > 0:
            self._failures_left[chunk.chunk_id] -= 1
            raise ProviderError(f"mock: 意図的な失敗 chunk={chunk.chunk_id}")

        ticks_per_day = int(self.options.get("ticks_per_day", 200))
        spread = float(self.options.get("spread", 0.003))
        price = float(self.options.get("base_price", 100.0))
        seed = zlib.crc32(f"{self.config.symbol}:{chunk.chunk_id}".encode("ascii"))
        generator = random.Random(seed)
        lines = ["timestamp,bid,ask,bid_volume,ask_volume"]
        day = chunk.first_date
        while day <= chunk.last_date:
            if day.weekday() != 5:  # 土曜は市場休場のため空にする
                day_start = utc_date_to_ms(day)
                # 1日全体へ散らばる、重複のない昇順の時刻
                for offset in sorted(generator.sample(range(1000, 86_399_000), ticks_per_day)):
                    price = round(max(1.0, price + generator.uniform(-0.01, 0.01)), 3)
                    lines.append(f"{day_start + offset},{price:.3f},{price + spread:.3f},1.0,1.5")
            day += timedelta(days=1)
        destination.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")

    def iter_rows(self, raw_path: Path) -> Iterator[Tick | RejectedRow]:
        return iter_header_csv_rows(raw_path, "timestamp", "bid", "ask", "bid_volume", "ask_volume")
