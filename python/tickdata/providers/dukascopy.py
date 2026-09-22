from __future__ import annotations

import shutil
import subprocess
from pathlib import Path
from typing import Iterator

from ..chunks import Chunk
from ..model import RejectedRow, Tick
from ..timeutil import utc_ms_to_iso
from .base import ProviderError, TickProvider, iter_header_csv_rows

_TOOL_DIR = Path(__file__).resolve().parents[3] / "tools" / "tick-data"


class DukascopyProvider(TickProvider):
    """dukascopy-node（Node.js）を1チャンクごとに呼び出す。chunk・retry・resumeはPython側が担う。"""

    name = "dukascopy"
    source_format = "dukascopy-node CSV (timestamp=UTC epoch ms, askPrice, bidPrice, askVolume, bidVolume)"

    def download_chunk(self, chunk: Chunk, destination: Path) -> None:
        node = shutil.which(str(self.options.get("node_executable", "node")))
        if node is None:
            raise ProviderError("Node.jsが見つかりません（Node 18以上が必要）。", retryable=False)
        script = _TOOL_DIR / "dukascopy-download.mjs"
        if not (_TOOL_DIR / "node_modules" / "dukascopy-node").is_dir():
            raise ProviderError(
                f"dukascopy-nodeが未インストールです。`npm ci --prefix {_TOOL_DIR}`を実行してください。",
                retryable=False,
            )
        instrument = str(self.options.get("instrument", self.config.symbol.lower()))
        command = [
            node, str(script),
            "--instrument", instrument,
            "--from", utc_ms_to_iso(chunk.start_ms),
            "--to", utc_ms_to_iso(chunk.end_ms),
            "--out", str(destination),
        ]
        # HTTP 429（レート制限）対策の、1時間ごとの待機・再試行。provider_optionsで調整できる
        for option, argument in (("batch_pause_ms", "--batch-pause-ms"), ("retry_count", "--retry-count"),
                                 ("retry_pause_ms", "--retry-pause-ms")):
            if option in self.options:
                command += [argument, str(int(self.options[option]))]
        try:
            completed = subprocess.run(
                command, capture_output=True, text=True, timeout=self.config.retry.timeout_seconds, check=False
            )
        except subprocess.TimeoutExpired as error:
            raise ProviderError(f"dukascopy-nodeがタイムアウトしました: chunk={chunk.chunk_id}") from error
        if completed.returncode != 0:
            tail = (completed.stderr or completed.stdout).strip().splitlines()[-3:]
            raise ProviderError(f"dukascopy-nodeが失敗しました(exit={completed.returncode}): {' | '.join(tail)}")

    def iter_rows(self, raw_path: Path) -> Iterator[Tick | RejectedRow]:
        return iter_header_csv_rows(raw_path, "timestamp", "bidPrice", "askPrice", "bidVolume", "askVolume")
