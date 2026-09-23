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
_CSV_HEADER = "timestamp,askPrice,bidPrice,askVolume,bidVolume\n"
_HOUR_MS = 3_600_000
# 実データ（AUDUSD、2020-01〜2022-05、Friday 123件・Sunday 122件）で確認した休場境界。
# 金曜は21:59:59を超えるtickが1件も無く、日曜は21:00:00より前のtickが1件も無かった（DECISIONS.md DEC-038）。
_FRIDAY_CLOSE_HOUR_UTC = 22
_SUNDAY_OPEN_HOUR_UTC = 21


class DukascopyProvider(TickProvider):
    """dukascopy-node（Node.js）を1チャンクごとに呼び出す。chunk・retry・resumeはPython側が担う。"""

    name = "dukascopy"
    source_format = "dukascopy-node CSV (timestamp=UTC epoch ms, askPrice, bidPrice, askVolume, bidVolume)"

    def download_chunk(self, chunk: Chunk, destination: Path) -> None:
        # 既定true: 本プロジェクトの本番ブローカーはOANDA証券のみ（DECISIONS.md DEC-023）であり、
        # OANDA証券はMT5で暗号資産等の週末取引銘柄を一切扱っていないことを確認済み（DEC-038、2026-09-23）。
        # 一般のMT5ブローカーには週末も取引される銘柄（暗号資産CFD等）を提供するところがあるため、
        # そのような銘柄をこのProviderで取得する場合は、provider_optionsで明示的にfalseを指定すること。
        skip_weekend = self.options.get("skip_weekend_closed_hours", True)
        if chunk.is_saturday_only and skip_weekend:
            # 土曜（UTC全体）はFX市場が休場でtickが存在しない（AUDUSD実データ、122/122サンプルで確認済み）。
            # 1時間ごとの取得・待機を24回行っても常に空になるだけなので、要求を送らず直接空ファイルを書く。
            destination.write_text(_CSV_HEADER, encoding="utf-8", newline="\n")
            return
        from_ms, to_ms = chunk.start_ms, chunk.end_ms
        if skip_weekend and chunk.is_friday_only:
            # 金曜の休場開始（22:00 UTC）以降は要求しない（実測で21:59:59を超えるtickは無い）。
            to_ms = min(to_ms, chunk.start_ms + _FRIDAY_CLOSE_HOUR_UTC * _HOUR_MS)
        elif skip_weekend and chunk.is_sunday_only:
            # 日曜の再開（21:00 UTC）より前は要求しない（実測で21:00:00より前のtickは無い）。
            from_ms = max(from_ms, chunk.start_ms + _SUNDAY_OPEN_HOUR_UTC * _HOUR_MS)

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
            "--from", utc_ms_to_iso(from_ms),
            "--to", utc_ms_to_iso(to_ms),
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
