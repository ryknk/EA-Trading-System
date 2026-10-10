from __future__ import annotations

import logging
import os
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable

from .chunks import Chunk
from .providers import ProviderError, TickProvider
from .store import DatasetStore, sha256_file, utc_now_iso
from .timeutil import utc_ms_to_iso

LOGGER = logging.getLogger("tickdata")

STATUS_COMPLETE = "complete"
STATUS_EMPTY = "empty"
STATUS_FAILED = "failed"


@dataclass
class StageResult:
    done: list[str] = field(default_factory=list)
    skipped: list[str] = field(default_factory=list)
    failed: list[str] = field(default_factory=list)

    @property
    def ok(self) -> bool:
        return not self.failed


def ensure_chunk_entries(manifest: dict[str, Any], chunks: list[Chunk]) -> None:
    """計画したChunkを、未取得（pending）として先にmanifestへ登録する。"""
    entries = manifest["chunks"]
    for chunk in chunks:
        entries.setdefault(chunk.chunk_id, {
            "start": utc_ms_to_iso(chunk.start_ms),
            "end": utc_ms_to_iso(chunk.end_ms),
            "download": {"status": "pending"},
            "normalize": {"status": "pending"},
        })


def is_empty_raw(path: Path) -> bool:
    """0バイト、またはヘッダー行しかないrawファイルは空データとみなす。"""
    if path.stat().st_size == 0:
        return True
    with path.open("rb") as handle:
        handle.readline()
        return handle.readline().strip() == b""


def _already_downloaded(entry: dict[str, Any], raw_path: Path) -> bool:
    download = entry["download"]
    if download["status"] == STATUS_EMPTY:
        return True
    return download["status"] == STATUS_COMPLETE and raw_path.exists() and raw_path.stat().st_size == download["bytes"]


def run_download(
    store: DatasetStore, provider: TickProvider, manifest: dict[str, Any], chunks: list[Chunk],
    force: bool = False, sleep: Callable[[float], None] = time.sleep,
) -> StageResult:
    """未完了のChunkだけを取得する。完了判定はmanifestの記録とファイルサイズで行い、
    途中で止まった.partファイルは完了扱いにしない。"""
    result = StageResult()
    policy = store.config.retry
    store.raw_dir.mkdir(parents=True, exist_ok=True)

    for index, chunk in enumerate(chunks, start=1):
        entry = manifest["chunks"][chunk.chunk_id]
        raw_path = store.raw_path(chunk.chunk_id, provider.raw_suffix)
        if not force and _already_downloaded(entry, raw_path):
            result.skipped.append(chunk.chunk_id)
            continue

        part_path = raw_path.with_name(raw_path.name + ".part")
        entry["download"] = {"status": "pending"}
        entry["normalize"] = {"status": "pending"}
        last_error = ""
        for attempt in range(1, policy.max_attempts + 1):
            part_path.unlink(missing_ok=True)
            try:
                provider.download_chunk(chunk, part_path)
                if not part_path.exists():
                    raise ProviderError("Providerがrawファイルを出力しませんでした。")
                empty = is_empty_raw(part_path)
                os.replace(part_path, raw_path)
                entry["download"] = {
                    "status": STATUS_EMPTY if empty else STATUS_COMPLETE,
                    "attempts": attempt,
                    "downloaded_at": utc_now_iso(),
                    "raw_file": raw_path.name,
                    "bytes": raw_path.stat().st_size,
                    "sha256": sha256_file(raw_path),
                }
                result.done.append(chunk.chunk_id)
                LOGGER.info("chunk %s: %s (%d/%d, attempt %d)", chunk.chunk_id, entry["download"]["status"], index, len(chunks), attempt)
                break
            except ProviderError as error:
                last_error = str(error)
                if not error.retryable:
                    part_path.unlink(missing_ok=True)
                    raise
            except OSError as error:
                last_error = f"{type(error).__name__}: {error}"
            LOGGER.warning("chunk %s: 取得失敗 attempt %d/%d: %s", chunk.chunk_id, attempt, policy.max_attempts, last_error)
            if attempt < policy.max_attempts:
                sleep(policy.backoff_seconds(attempt))
        else:
            part_path.unlink(missing_ok=True)
            entry["download"] = {"status": STATUS_FAILED, "attempts": policy.max_attempts, "error": last_error}
            result.failed.append(chunk.chunk_id)
        store.save_manifest(manifest)
    return result
