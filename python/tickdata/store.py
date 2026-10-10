from __future__ import annotations

import hashlib
import json
import os
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterator

from .config import DatasetConfig

MANIFEST_SCHEMA_VERSION = "1.0"


class DatasetLockedError(RuntimeError):
    """同じデータセットを別プロセスが処理中（またはロックが残っている）。"""


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def atomic_write_text(path: Path, text: str) -> None:
    """一時ファイルへ書いてからos.replaceする。途中停止で壊れたファイルを残さない。"""
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + ".part")
    temporary.write_text(text, encoding="utf-8", newline="\n")
    os.replace(temporary, path)


class DatasetStore:
    """データセット1件のディレクトリ配置とmanifest（=進捗状態）の読み書き。"""

    def __init__(self, config: DatasetConfig) -> None:
        self.config = config
        self.root = config.dataset_dir
        self.raw_dir = self.root / "raw"
        self.normalized_dir = self.root / "normalized"
        self.mt5_dir = self.root / "mt5"
        self.manifest_path = self.root / "dataset.json"
        self.validation_path = self.root / "validation.json"
        self.lock_path = self.root / "dataset.lock"

    def raw_path(self, chunk_id: str, suffix: str) -> Path:
        return self.raw_dir / f"{chunk_id}{suffix}"

    def normalized_path(self, chunk_id: str) -> Path:
        return self.normalized_dir / f"{chunk_id}.csv"

    def new_manifest(self, source_format: str) -> dict[str, Any]:
        config = self.config
        return {
            "schema_version": MANIFEST_SCHEMA_VERSION,
            "dataset_id": config.dataset_id,
            "provider": config.provider,
            "symbol": config.symbol,
            "requested_range": {"from": config.from_date.isoformat(), "to": config.to_date.isoformat()},
            "timezone": config.timezone,
            "chunk_unit": config.chunk_unit,
            "source_format": source_format,
            "created_at": utc_now_iso(),
            "chunks": {},
        }

    def load_manifest(self, source_format: str) -> dict[str, Any]:
        if not self.manifest_path.exists():
            return self.new_manifest(source_format)
        manifest = json.loads(self.manifest_path.read_text(encoding="utf-8"))
        if manifest.get("dataset_id") != self.config.dataset_id:
            raise ValueError(f"manifestのdataset_idが設定と一致しません: {self.manifest_path}")
        return manifest

    def save_manifest(self, manifest: dict[str, Any]) -> None:
        manifest["updated_at"] = utc_now_iso()
        atomic_write_text(self.manifest_path, json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")

    @contextmanager
    def locked(self) -> Iterator[None]:
        self.root.mkdir(parents=True, exist_ok=True)
        try:
            descriptor = os.open(self.lock_path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        except FileExistsError as error:
            raise DatasetLockedError(
                f"データセットが処理中です。他に実行中のプロセスがない場合は{self.lock_path}を削除してください。"
            ) from error
        try:
            os.write(descriptor, f"pid={os.getpid()}\n".encode("ascii"))
            os.close(descriptor)
            yield
        finally:
            self.lock_path.unlink(missing_ok=True)
