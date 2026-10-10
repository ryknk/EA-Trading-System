from __future__ import annotations

import logging
import os
from collections import Counter
from pathlib import Path
from typing import Any

from .chunks import Chunk
from .download import STATUS_COMPLETE, STATUS_EMPTY, StageResult
from .model import (
    NORMALIZED_FORMAT, NORMALIZED_HEADER, REASON_OUT_OF_RANGE, RejectedRow, Tick,
    find_invalid_reason, format_normalized_row,
)
from .providers import TickProvider
from .store import DatasetStore, sha256_file, utc_now_iso

LOGGER = logging.getLogger("tickdata")

# 正規化ロジックを変えたら更新する。古いバージョンで作ったnormalizedは再生成の対象になる。
NORMALIZER_VERSION = "1"


def normalize_file(provider: TickProvider, chunk: Chunk, raw_path: Path, output_path: Path) -> dict[str, Any]:
    """rawを1行ずつ読み、不正tickの除外・連続重複の除去・範囲外の除外をして書き出す（全件をメモリへ載せない）。"""
    rejected: Counter[str] = Counter()
    ticks_in = ticks_out = duplicates = 0
    first_ts = last_ts = None
    previous: Tick | None = None

    part_path = output_path.with_name(output_path.name + ".part")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with part_path.open("w", encoding="utf-8", newline="\n") as writer:
        writer.write(NORMALIZED_HEADER + "\n")
        for row in provider.iter_rows(raw_path):
            ticks_in += 1
            if isinstance(row, RejectedRow):
                rejected[row.reason] += 1
                continue
            reason = find_invalid_reason(row)
            if reason is None and not chunk.start_ms <= row.timestamp_ms < chunk.end_ms:
                reason = REASON_OUT_OF_RANGE
            if reason is not None:
                rejected[reason] += 1
                continue
            if row == previous:
                duplicates += 1
                continue
            writer.write(format_normalized_row(row) + "\n")
            previous = row
            ticks_out += 1
            if first_ts is None:
                first_ts = row.timestamp_ms
            last_ts = row.timestamp_ms
    os.replace(part_path, output_path)
    return {
        "ticks_in": ticks_in,
        "ticks_out": ticks_out,
        "duplicates_removed": duplicates,
        "rejected": dict(rejected),
        "first_timestamp_ms": first_ts,
        "last_timestamp_ms": last_ts,
    }


def run_normalize(
    store: DatasetStore, provider: TickProvider, manifest: dict[str, Any], chunks: list[Chunk], force: bool = False,
) -> StageResult:
    result = StageResult()
    manifest["normalized_format"] = NORMALIZED_FORMAT
    manifest["normalizer_version"] = NORMALIZER_VERSION

    for chunk in chunks:
        entry = manifest["chunks"][chunk.chunk_id]
        download = entry["download"]
        if download["status"] not in (STATUS_COMPLETE, STATUS_EMPTY):
            result.failed.append(chunk.chunk_id)
            continue

        output_path = store.normalized_path(chunk.chunk_id)
        current = entry["normalize"]
        up_to_date = (
            not force
            and current.get("status") in (STATUS_COMPLETE, STATUS_EMPTY)
            and current.get("raw_sha256") == download.get("sha256")
            and current.get("normalizer_version") == NORMALIZER_VERSION
            and (current["status"] == STATUS_EMPTY or output_path.exists())
        )
        if up_to_date:
            result.skipped.append(chunk.chunk_id)
            continue

        if download["status"] == STATUS_EMPTY:
            output_path.unlink(missing_ok=True)
            entry["normalize"] = {
                "status": STATUS_EMPTY, "raw_sha256": download.get("sha256"),
                "normalizer_version": NORMALIZER_VERSION, "normalized_at": utc_now_iso(), "ticks_out": 0,
            }
        else:
            raw_path = store.raw_path(chunk.chunk_id, provider.raw_suffix)
            stats = normalize_file(provider, chunk, raw_path, output_path)
            entry["normalize"] = {
                "status": STATUS_COMPLETE if stats["ticks_out"] > 0 else STATUS_EMPTY,
                "raw_sha256": download["sha256"],
                "normalizer_version": NORMALIZER_VERSION,
                "normalized_at": utc_now_iso(),
                "file": output_path.name,
                "bytes": output_path.stat().st_size,
                "sha256": sha256_file(output_path),
                **stats,
            }
        result.done.append(chunk.chunk_id)
        LOGGER.info("chunk %s: normalized (%s)", chunk.chunk_id, entry["normalize"]["status"])
        store.save_manifest(manifest)
    return result
