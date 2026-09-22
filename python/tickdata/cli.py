from __future__ import annotations

import argparse
import json
import logging
import sys
from pathlib import Path
from typing import Any

from .chunks import plan_chunks
from .config import ConfigError, DatasetConfig, load_config
from .convert import ConversionRefused, run_convert
from .download import STATUS_COMPLETE, STATUS_EMPTY, ensure_chunk_entries, run_download
from .mt5results import (
    parse_import_log, parse_tester_report, parse_verify_log, record_import, record_quality, record_verify,
)
from .normalize import run_normalize
from .providers import ProviderError, create_provider
from .store import DatasetLockedError, DatasetStore
from .validate import validate_dataset

LOGGER = logging.getLogger("tickdata")

EXIT_OK = 0
EXIT_ERROR = 1
EXIT_CONFIG = 2
EXIT_PARTIAL = 3
EXIT_VALIDATION_FAILED = 4
EXIT_MT5_FAILED = 5
EXIT_PROVIDER_ENVIRONMENT = 6
EXIT_LOCKED = 7
EXIT_DIFFERENT = 8


def _parse_server_time(value: str | None) -> dict[str, Any] | None:
    if value is None:
        return None
    text = value.strip().lower()
    if text in {"utc", "ny_close"}:
        return {"mode": text}
    if text.startswith("fixed:"):
        return {"mode": "fixed", "offset_hours": float(text[6:])}
    raise ConfigError(f"--server-timeはutc・ny_close・fixed:<時間>のいずれかです: {value!r}")


def _build_parser() -> argparse.ArgumentParser:
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--config", type=Path, help="データセット設定JSON")
    common.add_argument("--provider")
    common.add_argument("--symbol")
    common.add_argument("--from", dest="from_date", help="開始日 YYYY-MM-DD（UTC、含む）")
    common.add_argument("--to", dest="to_date", help="終了日 YYYY-MM-DD（UTC、含む）")
    common.add_argument("--storage-root", type=Path)
    common.add_argument("--chunk-unit", choices=("day", "month"))
    common.add_argument("--server-time", help="utc / ny_close / fixed:<時間>（MT5サーバー時刻の規則）")
    common.add_argument("--source-symbol", help="MT5で仕様の複製元にする実Symbol")
    common.add_argument("--custom-symbol", help="MT5へ作成・投入するCustom Symbol名")
    common.add_argument("--force", action="store_true", help="完了済みでも再実行する")
    common.add_argument("-v", "--verbose", action="store_true")

    parser = argparse.ArgumentParser(prog="python -m python.tickdata", description="tickデータ取得・MT5変換パイプライン")
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("download", "normalize", "validate", "convert", "run"):
        commands.add_parser(name, parents=[common])
    status = commands.add_parser("status", parents=[common])
    status.add_argument("--json", action="store_true")
    diff = commands.add_parser("diff", parents=[common])
    diff.add_argument("--other", type=Path, required=True, help="比較対象のdataset.json")
    for name in ("record-import", "record-verify"):
        recorder = commands.add_parser(name, parents=[common])
        recorder.add_argument("--log", type=Path, required=True, help="MT5 Journalから抜き出したログ")
    quality = commands.add_parser("record-quality", parents=[common])
    quality.add_argument("--report", type=Path, required=True, help="Strategy TesterのHTMLレポート")
    quality.add_argument("--case", default="", help="実行したTesterケースの識別情報")
    return parser


def _config_from_args(args: argparse.Namespace) -> DatasetConfig:
    mt5: dict[str, Any] = {}
    if args.source_symbol:
        mt5["source_symbol"] = args.source_symbol
    if args.custom_symbol:
        mt5["custom_symbol"] = args.custom_symbol
    return load_config(args.config, {
        "provider": args.provider, "symbol": args.symbol, "from": args.from_date, "to": args.to_date,
        "storage_root": str(args.storage_root) if args.storage_root else None,
        "chunk_unit": args.chunk_unit, "server_time": _parse_server_time(args.server_time), "mt5": mt5 or None,
    })


def _summarize(manifest: dict[str, Any], config: DatasetConfig, store: DatasetStore) -> dict[str, Any]:
    chunks = manifest["chunks"]
    def counts(stage: str) -> dict[str, int]:
        result: dict[str, int] = {}
        for entry in chunks.values():
            result[entry[stage]["status"]] = result.get(entry[stage]["status"], 0) + 1
        return result
    incomplete = [cid for cid, entry in chunks.items() if entry["download"]["status"] not in (STATUS_COMPLETE, STATUS_EMPTY)]
    return {
        "dataset_id": manifest["dataset_id"],
        "dataset_dir": str(store.root.resolve()),
        "mt5_dir": str(store.mt5_dir.resolve()),
        "source_symbol": config.mt5.source_symbol,
        "custom_symbol": config.mt5.custom_symbol,
        "custom_path": config.mt5.custom_path,
        "provider": manifest["provider"],
        "symbol": manifest["symbol"],
        "requested_range": manifest["requested_range"],
        "acquisition_complete": bool(chunks) and not incomplete,
        "chunks_total": len(chunks),
        "download": counts("download"),
        "normalize": counts("normalize"),
        "incomplete_chunks": incomplete[:20],
        "tick_count": manifest.get("tick_count"),
        "actual_range": manifest.get("actual_range"),
        "validation": manifest.get("validation", {}).get("status"),
        "convert": (manifest.get("convert") or {}).get("status"),
        "convert_files": len((manifest.get("convert") or {}).get("files", [])),
        "convert_tick_count": (manifest.get("convert") or {}).get("tick_count"),
        "convert_first_server_time": (manifest.get("convert") or {}).get("first_server_time"),
        "convert_last_server_time": (manifest.get("convert") or {}).get("last_server_time"),
        "import": (manifest.get("import") or {}).get("status"),
        "mt5_verification": (manifest.get("mt5_verification") or {}).get("status"),
        "history_quality": (manifest.get("history_quality") or {}).get("quality_text"),
    }


def _diff(left: dict[str, Any], right: dict[str, Any]) -> list[str]:
    differences: list[str] = []
    for chunk_id in sorted(set(left["chunks"]) | set(right["chunks"])):
        a, b = left["chunks"].get(chunk_id), right["chunks"].get(chunk_id)
        if a is None or b is None:
            differences.append(f"{chunk_id}: 片方のmanifestにのみ存在")
        elif (a["download"].get("sha256"), a["download"]["status"]) != (b["download"].get("sha256"), b["download"]["status"]):
            differences.append(
                f"{chunk_id}: raw sha256/status が異なる "
                f"(ticks {a['normalize'].get('ticks_out')} vs {b['normalize'].get('ticks_out')})"
            )
    return differences


def _run(args: argparse.Namespace) -> int:
    config = _config_from_args(args)
    store = DatasetStore(config)
    provider = create_provider(config)
    chunks = plan_chunks(config.from_date, config.to_date, config.chunk_unit)

    if args.command == "diff":
        other = json.loads(args.other.read_text(encoding="utf-8"))
        differences = _diff(store.load_manifest(provider.source_format), other)
        for line in differences:
            print(line)
        print(f"差分: {len(differences)}件")
        return EXIT_OK if not differences else EXIT_DIFFERENT

    if args.command == "status":
        manifest = store.load_manifest(provider.source_format)
        ensure_chunk_entries(manifest, chunks)
        summary = _summarize(manifest, config, store)
        print(json.dumps(summary, ensure_ascii=False, indent=None if args.json else 2))
        return EXIT_OK

    with store.locked():
        manifest = store.load_manifest(provider.source_format)
        ensure_chunk_entries(manifest, chunks)
        manifest["source_format"] = provider.source_format
        store.save_manifest(manifest)
        return _dispatch(args, config, store, provider, manifest, chunks)


def _dispatch(args, config, store, provider, manifest, chunks) -> int:
    command, force = args.command, args.force
    if command in ("download", "run"):
        result = run_download(store, provider, manifest, chunks, force=force)
        LOGGER.info("download: done=%d skipped=%d failed=%d", len(result.done), len(result.skipped), len(result.failed))
        if not result.ok:
            LOGGER.error("取得に失敗したChunk: %s（同じコマンドの再実行で未完了分だけ再開します）", result.failed[:20])
            return EXIT_PARTIAL
    if command in ("normalize", "run"):
        result = run_normalize(store, provider, manifest, chunks, force=force)
        LOGGER.info("normalize: done=%d skipped=%d failed=%d", len(result.done), len(result.skipped), len(result.failed))
        if not result.ok:
            LOGGER.error("未取得のため正規化できないChunk: %s", result.failed[:20])
            return EXIT_PARTIAL
    if command in ("validate", "run", "convert"):
        if command != "convert":
            report = validate_dataset(store, manifest, chunks)
            store.save_manifest(manifest)
            LOGGER.info("validate: %s ticks=%d errors=%s", report["status"], report["tick_count"],
                        [c["code"] for c in report["checks"] if c["severity"] == "error"])
            if report["status"] == "FAIL":
                return EXIT_VALIDATION_FAILED
    if command in ("convert", "run"):
        if command == "run" and config.server_time is None:
            LOGGER.info("server_time未指定のためconvertは実行しません（download〜validateまで完了）。")
            return EXIT_OK
        run_convert(store, manifest, chunks, config.server_time_rule(), force=force)
    if command == "record-import":
        record = record_import(store, manifest, parse_import_log(args.log.read_text(encoding="utf-8", errors="replace").splitlines()),
                               config.mt5.custom_symbol)
        print(json.dumps({"status": record["status"], "problems": record["problems"]}, ensure_ascii=False))
        return EXIT_OK if record["status"] in ("complete", "complete_with_skips") else EXIT_MT5_FAILED
    if command == "record-verify":
        record = record_verify(store, manifest, parse_verify_log(args.log.read_text(encoding="utf-8", errors="replace").splitlines()))
        print(json.dumps(record, ensure_ascii=False))
        return EXIT_OK if record["status"] == "verified" else EXIT_MT5_FAILED
    if command == "record-quality":
        report = parse_tester_report(args.report)
        record = record_quality(store, manifest, report, {"case": args.case, "report_file": args.report.name})
        print(json.dumps(record, ensure_ascii=False))
        return EXIT_OK if record["status"] == "verified" else EXIT_MT5_FAILED
    return EXIT_OK


def main(argv: list[str] | None = None) -> int:
    args = _build_parser().parse_args(argv)
    logging.basicConfig(level=logging.DEBUG if args.verbose else logging.INFO, stream=sys.stderr,
                        format="%(asctime)s %(levelname)s %(message)s")
    try:
        return _run(args)
    except ConfigError as error:
        LOGGER.error("設定エラー: %s", error)
        return EXIT_CONFIG
    except ConversionRefused as error:
        LOGGER.error("変換を拒否しました: %s", error)
        return EXIT_VALIDATION_FAILED
    except ProviderError as error:
        LOGGER.error("Provider環境エラー: %s", error)
        return EXIT_PROVIDER_ENVIRONMENT
    except DatasetLockedError as error:
        LOGGER.error("%s", error)
        return EXIT_LOCKED
    except ValueError as error:
        LOGGER.error("入力エラー: %s", error)
        return EXIT_CONFIG
