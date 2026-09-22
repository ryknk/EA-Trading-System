from __future__ import annotations

import logging
import os
from pathlib import Path
from typing import Any, TextIO

from .chunks import Chunk
from .download import STATUS_COMPLETE
from .model import format_number, parse_normalized_row
from .store import DatasetStore, sha256_file, utc_now_iso
from .timeutil import ServerTimeRule, WallClockFormatter, utc_ms_to_iso
from .validate import dataset_fingerprint

LOGGER = logging.getLogger("tickdata")

# MT5形式の出力仕様を変えたら更新する。
CONVERSION_VERSION = "1"
MT5_TARGET = "mt5-tab"
MT5_HEADER = "<DATE>\t<TIME>\t<BID>\t<ASK>\t<LAST>\t<VOLUME>"


class ConversionRefused(RuntimeError):
    """検証未完了・不整合のデータをMT5形式へ変換しないための拒否。"""


def mt5_file_name(symbol: str, provider: str, month_key: str) -> str:
    return f"ticks_{symbol}-{provider.upper()}_{month_key}.csv"


class _MonthFile:
    """サーバー時刻の暦月ごとの出力ファイル。完成するまで.partとして書き、最後にrenameする。"""

    def __init__(self, directory: Path, name: str) -> None:
        self.final_path = directory / name
        self.part_path = directory / (name + ".part")
        self.handle: TextIO = self.part_path.open("w", encoding="ascii", newline="\n")
        self.handle.write(MT5_HEADER + "\n")
        self.ticks = 0
        self.first_wall = ""
        self.last_wall = ""

    def write(self, date_text: str, time_text: str, line: str) -> None:
        self.handle.write(line)
        self.ticks += 1
        if not self.first_wall:
            self.first_wall = f"{date_text} {time_text}"
        self.last_wall = f"{date_text} {time_text}"

    def close(self) -> dict[str, Any]:
        self.handle.close()
        os.replace(self.part_path, self.final_path)
        return {
            "name": self.final_path.name, "ticks": self.ticks, "bytes": self.final_path.stat().st_size,
            "sha256": sha256_file(self.final_path), "first_server_time": self.first_wall, "last_server_time": self.last_wall,
        }


def _is_up_to_date(store: DatasetStore, convert: dict[str, Any] | None, fingerprint: str, rule: ServerTimeRule) -> bool:
    if not convert or convert.get("status") != STATUS_COMPLETE:
        return False
    return (
        convert.get("dataset_fingerprint") == fingerprint
        and convert.get("conversion_version") == CONVERSION_VERSION
        and convert.get("server_time") == rule.describe()
        and all((store.mt5_dir / item["name"]).exists() for item in convert["files"])
    )


def run_convert(
    store: DatasetStore, manifest: dict[str, Any], chunks: list[Chunk], rule: ServerTimeRule, force: bool = False,
) -> dict[str, Any]:
    """検証済みの正規化データを、既存Importer（ImportOandaTicks.mq5）が読むMT5タブCSV（サーバー時刻・月次）へ変換する。"""
    validation = manifest.get("validation")
    fingerprint = dataset_fingerprint(manifest)
    if not validation or validation["status"] not in ("PASS", "WARN"):
        raise ConversionRefused("先にvalidateを成功（PASSまたはWARN）させてください。")
    if validation["dataset_fingerprint"] != fingerprint:
        raise ConversionRefused("検証後にデータが更新されています。validateをやり直してください。")

    if not force and _is_up_to_date(store, manifest.get("convert"), fingerprint, rule):
        LOGGER.info("convert: 最新のため変換済みファイルを再利用します")
        return manifest["convert"]

    store.mt5_dir.mkdir(parents=True, exist_ok=True)
    for stale in [*store.mt5_dir.glob("ticks_*.csv"), *store.mt5_dir.glob("ticks_*.csv.part")]:
        stale.unlink()

    formatter = WallClockFormatter()
    files: list[dict[str, Any]] = []
    current: _MonthFile | None = None
    current_month = ""
    previous_wall = -1
    total = 0
    first_utc = last_utc = None

    try:
        for chunk in chunks:
            entry = manifest["chunks"][chunk.chunk_id]
            if entry["normalize"]["status"] != STATUS_COMPLETE:
                continue
            with store.normalized_path(chunk.chunk_id).open("r", encoding="utf-8") as handle:
                handle.readline()
                for line in handle:
                    tick = parse_normalized_row(line)
                    wall_ms = rule.utc_ms_to_server_wall_ms(tick.timestamp_ms)
                    if wall_ms < previous_wall:
                        raise ConversionRefused(
                            f"サーバー時刻へ変換後に時刻が逆行します（{utc_ms_to_iso(tick.timestamp_ms)}、"
                            f"server_time={rule.describe()}）。ルールを見直してください。"
                        )
                    previous_wall = wall_ms
                    date_text, time_text = formatter.format(wall_ms)
                    month_key = date_text[:7].replace(".", "-")
                    if month_key != current_month:
                        if current is not None:
                            files.append(current.close())
                        current = _MonthFile(store.mt5_dir, mt5_file_name(store.config.symbol, store.config.provider, month_key))
                        current_month = month_key
                    current.write(
                        date_text, time_text,
                        f"{date_text}\t{time_text}\t{format_number(tick.bid)}\t{format_number(tick.ask)}\t\t\n",
                    )
                    total += 1
                    first_utc = tick.timestamp_ms if first_utc is None else first_utc
                    last_utc = tick.timestamp_ms
        if current is not None:
            files.append(current.close())
    except BaseException:
        if current is not None:
            current.handle.close()
            current.part_path.unlink(missing_ok=True)
        raise

    convert = {
        "status": STATUS_COMPLETE,
        "target": MT5_TARGET,
        "conversion_version": CONVERSION_VERSION,
        "converted_at": utc_now_iso(),
        "server_time": rule.describe(),
        "dataset_fingerprint": fingerprint,
        "tick_count": total,
        "first_server_time": files[0]["first_server_time"] if files else None,
        "last_server_time": files[-1]["last_server_time"] if files else None,
        "first_utc": utc_ms_to_iso(first_utc) if first_utc is not None else None,
        "last_utc": utc_ms_to_iso(last_utc) if last_utc is not None else None,
        "files": files,
    }
    manifest["convert"] = convert
    manifest.pop("import", None)
    manifest.pop("mt5_verification", None)
    manifest.pop("history_quality", None)
    store.save_manifest(manifest)
    LOGGER.info("convert: %d ticks -> %d files", total, len(files))
    return convert
