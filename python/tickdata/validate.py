from __future__ import annotations

import hashlib
import json
import logging
from collections import Counter
from typing import Any

from .chunks import Chunk
from .download import STATUS_COMPLETE, STATUS_EMPTY
from .model import NORMALIZED_HEADER, find_invalid_reason, parse_normalized_row
from .store import DatasetStore, atomic_write_text, utc_now_iso
from .timeutil import utc_ms_to_iso

LOGGER = logging.getLogger("tickdata")

_DAY_MS = 86_400_000
_MAX_EXAMPLES = 5
_MAX_LISTED_EVENTS = 20


def dataset_fingerprint(manifest: dict[str, Any]) -> str:
    """全Chunkの正規化済みchecksumから作る識別子。validate・convert結果が最新データに対応するかの判定に使う。"""
    digest = hashlib.sha256()
    for chunk_id, entry in manifest["chunks"].items():
        digest.update(f"{chunk_id}:{entry['normalize'].get('sha256', '-')}:{entry['normalize'].get('status')}\n".encode("ascii"))
    return digest.hexdigest()


def _spans_weekend(previous_ms: int, current_ms: int) -> bool:
    """区間内に土曜（UTC）正午を含む＝週末休場による欠落とみなす。"""
    for day in range(previous_ms // _DAY_MS, current_ms // _DAY_MS + 1):
        if (day + 3) % 7 == 5 and previous_ms <= day * _DAY_MS + _DAY_MS // 2 <= current_ms:
            return True
    return False


class _Findings:
    def __init__(self) -> None:
        self.counts: Counter[str] = Counter()
        self.examples: dict[str, list[str]] = {}

    def add(self, code: str, example: str, count: int = 1) -> None:
        self.counts[code] += count
        samples = self.examples.setdefault(code, [])
        if len(samples) < _MAX_EXAMPLES:
            samples.append(example)


def validate_dataset(store: DatasetStore, manifest: dict[str, Any], chunks: list[Chunk]) -> dict[str, Any]:
    policy = store.config.validation
    max_gap_ms = policy.max_gap_seconds * 1000
    errors, warnings = _Findings(), _Findings()
    largest_gaps: list[dict[str, Any]] = []
    largest_jumps: list[dict[str, Any]] = []
    gap_count = jump_count = duplicate_count = 0

    if manifest.get("symbol") != store.config.symbol:
        errors.add("SYMBOL_MISMATCH", f"manifest={manifest.get('symbol')} config={store.config.symbol}")

    tick_count = normalized_bytes = raw_bytes = 0
    first_ts = last_ts = None
    previous = None
    rows_in = rows_rejected = 0
    rejected_by_reason: Counter[str] = Counter()
    status_counts: Counter[str] = Counter()

    for chunk in chunks:
        entry = manifest["chunks"].get(chunk.chunk_id)
        download, normalize = (entry["download"], entry["normalize"]) if entry else ({"status": "missing"}, {"status": "missing"})
        status_counts[download["status"] if download["status"] not in (STATUS_COMPLETE, STATUS_EMPTY) else normalize["status"]] += 1
        raw_bytes += download.get("bytes", 0)
        if download["status"] not in (STATUS_COMPLETE, STATUS_EMPTY):
            errors.add("INCOMPLETE_CHUNKS", f"{chunk.chunk_id}: download={download['status']}")
            continue
        if normalize["status"] not in (STATUS_COMPLETE, STATUS_EMPTY) or normalize.get("raw_sha256") != download.get("sha256"):
            errors.add("NOT_NORMALIZED", f"{chunk.chunk_id}: normalize={normalize['status']}")
            continue
        rows_in += normalize.get("ticks_in", 0)
        for reason, count in normalize.get("rejected", {}).items():
            rejected_by_reason[reason] += count
            rows_rejected += count
        if normalize["status"] == STATUS_EMPTY:
            if not chunk.is_saturday_only:
                warnings.add("EMPTY_CHUNK_UNEXPECTED", f"{chunk.chunk_id} ({chunk.first_date:%a})")
            continue

        path = store.normalized_path(chunk.chunk_id)
        if not path.exists():
            errors.add("NOT_NORMALIZED", f"{chunk.chunk_id}: ファイルがありません")
            continue
        digest = hashlib.sha256()
        with path.open("rb") as handle:
            header = handle.readline()
            digest.update(header)
            if header.decode("utf-8").strip() != NORMALIZED_HEADER:
                errors.add("NORMALIZED_HEADER_MISMATCH", chunk.chunk_id)
                continue
            for raw_line in handle:
                digest.update(raw_line)
                try:
                    tick = parse_normalized_row(raw_line.decode("utf-8").strip())
                except ValueError:
                    errors.add("NON_FINITE_VALUE", f"{chunk.chunk_id}: 解析不能な行")
                    continue
                tick_count += 1
                reason = find_invalid_reason(tick)
                if reason is not None:
                    errors.add(reason, f"{utc_ms_to_iso(tick.timestamp_ms)}")
                if not chunk.start_ms <= tick.timestamp_ms < chunk.end_ms:
                    errors.add("TIMESTAMP_OUT_OF_RANGE", f"{chunk.chunk_id}: {utc_ms_to_iso(tick.timestamp_ms)}")
                if first_ts is None:
                    first_ts = tick.timestamp_ms
                if previous is not None and reason is None:
                    if tick.timestamp_ms < previous.timestamp_ms:
                        errors.add("TIMESTAMP_NOT_MONOTONIC",
                                   f"{utc_ms_to_iso(previous.timestamp_ms)} -> {utc_ms_to_iso(tick.timestamp_ms)}")
                    elif tick == previous:
                        duplicate_count += 1
                    else:
                        gap_ms = tick.timestamp_ms - previous.timestamp_ms
                        if gap_ms > max_gap_ms and not _spans_weekend(previous.timestamp_ms, tick.timestamp_ms):
                            gap_count += 1
                            _keep_largest(largest_gaps, {
                                "from": utc_ms_to_iso(previous.timestamp_ms),
                                "to": utc_ms_to_iso(tick.timestamp_ms), "seconds": gap_ms // 1000,
                            }, "seconds")
                        previous_mid = (previous.bid + previous.ask) / 2
                        ratio = abs((tick.bid + tick.ask) / 2 / previous_mid - 1.0)
                        if ratio > policy.max_price_jump_ratio:
                            jump_count += 1
                            _keep_largest(largest_jumps, {
                                "at": utc_ms_to_iso(tick.timestamp_ms), "ratio": round(ratio, 6),
                            }, "ratio")
                if reason is None:
                    previous = tick
                last_ts = tick.timestamp_ms
        normalized_bytes += path.stat().st_size
        if digest.hexdigest() != normalize.get("sha256"):
            errors.add("CHECKSUM_MISMATCH", chunk.chunk_id)

    if tick_count == 0:
        errors.add("NO_TICKS", "有効なtickが1件もありません。")
    rejected_ratio = (rows_rejected / rows_in) if rows_in else 0.0
    if rows_rejected:
        code = "REJECTED_RATIO_EXCEEDED" if rejected_ratio > policy.max_rejected_ratio else "REJECTED_ROWS"
        target = errors if code == "REJECTED_RATIO_EXCEEDED" else warnings
        target.add(code, f"{rows_rejected}/{rows_in} {dict(rejected_by_reason)}", rows_rejected)
    if duplicate_count:
        warnings.add("DUPLICATE_TICKS", "Chunk境界をまたぐ連続重複", duplicate_count)
    if gap_count:
        warnings.add("LARGE_GAP", f"{policy.max_gap_seconds}秒超（週末を除く）", gap_count)
    if jump_count:
        warnings.add("PRICE_JUMP", f"連続tick間で{policy.max_price_jump_ratio:.1%}超", jump_count)

    checks = _checks(errors, "error") + _checks(warnings, "warning")
    status = "FAIL" if errors.counts else ("WARN" if warnings.counts else "PASS")
    report = {
        "schema_version": "1.0",
        "dataset_id": store.config.dataset_id,
        "checked_at": utc_now_iso(),
        "status": status,
        "provider": store.config.provider,
        "symbol": store.config.symbol,
        "timezone": store.config.timezone,
        "requested_range": manifest["requested_range"],
        "actual_range": {
            "first_timestamp_ms": first_ts, "last_timestamp_ms": last_ts,
            "first_timestamp": utc_ms_to_iso(first_ts) if first_ts is not None else None,
            "last_timestamp": utc_ms_to_iso(last_ts) if last_ts is not None else None,
        },
        "tick_count": tick_count,
        "raw_bytes": raw_bytes,
        "normalized_bytes": normalized_bytes,
        "chunk_status_counts": dict(status_counts),
        "rejected_rows": dict(rejected_by_reason),
        "rejected_ratio": rejected_ratio,
        "duplicate_ticks": duplicate_count,
        "large_gap_count": gap_count,
        "largest_gaps": largest_gaps,
        "price_jump_count": jump_count,
        "largest_price_jumps": largest_jumps,
        "policy": {
            "max_gap_seconds": policy.max_gap_seconds,
            "max_price_jump_ratio": policy.max_price_jump_ratio,
            "max_rejected_ratio": policy.max_rejected_ratio,
        },
        "checks": checks,
    }
    atomic_write_text(store.validation_path, json.dumps(report, ensure_ascii=False, indent=2) + "\n")
    manifest["actual_range"] = report["actual_range"]
    manifest["tick_count"] = tick_count
    manifest["validation"] = {
        "status": status,
        "checked_at": report["checked_at"],
        "tick_count": tick_count,
        "error_codes": sorted(errors.counts),
        "warning_codes": sorted(warnings.counts),
        "report_file": store.validation_path.name,
        "dataset_fingerprint": dataset_fingerprint(manifest),
    }
    return report


def _keep_largest(items: list[dict[str, Any]], item: dict[str, Any], key: str) -> None:
    items.append(item)
    items.sort(key=lambda value: value[key], reverse=True)
    del items[_MAX_LISTED_EVENTS:]


def _checks(findings: _Findings, severity: str) -> list[dict[str, Any]]:
    return [
        {"code": code, "severity": severity, "count": count, "examples": findings.examples.get(code, [])}
        for code, count in sorted(findings.counts.items())
    ]
