from __future__ import annotations

import re
from pathlib import Path
from typing import Any, Iterable

from .store import DatasetStore, utc_now_iso
from .timeutil import wall_text_to_ms

_FILE_IMPORTED = re.compile(r"FILE_IMPORTED file=(\S+) ticks=(-?\d+) skipped=(-?\d+) parse_failures=(-?\d+)")
_IMPORT_COMPLETED = re.compile(
    r"IMPORT_COMPLETED symbol=(\S+) files=(\d+) total_ticks=(-?\d+) skipped_ticks=(-?\d+) elapsed_ms=(\d+)"
)
_IMPORT_ABORTED = re.compile(r"IMPORT_ABORTED\S* (.*)")
_VERIFY_RESULT = re.compile(
    r"TICKVERIFY_RESULT symbol=(\S+) ticks=(-?\d+) first_msc=(-?\d+) last_msc=(-?\d+) windows=(\d+) failed_windows=(\d+)"
)


def parse_import_log(lines: Iterable[str]) -> dict[str, Any]:
    """MT5 Journalの取込マーカー（ImportOandaTicks.mq5が出力）を集計する。"""
    files: list[dict[str, Any]] = []
    completed: dict[str, Any] | None = None
    aborted: str | None = None
    for line in lines:
        if match := _FILE_IMPORTED.search(line):
            files.append({
                "file": match[1], "ticks": int(match[2]), "skipped": int(match[3]), "parse_failures": int(match[4]),
            })
        elif match := _IMPORT_COMPLETED.search(line):
            completed = {
                "symbol": match[1], "files": int(match[2]), "total_ticks": int(match[3]),
                "skipped_ticks": int(match[4]), "elapsed_ms": int(match[5]),
            }
        elif match := _IMPORT_ABORTED.search(line):
            aborted = match[1].strip()
    return {"files": files, "completed": completed, "aborted": aborted}


def parse_verify_log(lines: Iterable[str]) -> dict[str, Any] | None:
    result = None
    for line in lines:
        if match := _VERIFY_RESULT.search(line):
            result = {
                "symbol": match[1], "ticks": int(match[2]), "first_msc": int(match[3]), "last_msc": int(match[4]),
                "windows": int(match[5]), "failed_windows": int(match[6]),
            }
    return result


def record_import(store: DatasetStore, manifest: dict[str, Any], parsed: dict[str, Any], custom_symbol: str) -> dict[str, Any]:
    """取込結果をmanifestへ記録する。IMPORT_COMPLETEDが無い・ファイル数不一致は「完了」にしない。"""
    convert = manifest.get("convert") or {}
    completed = parsed["completed"]
    expected_files = len(convert.get("files", []))
    parse_failures = sum(item["parse_failures"] for item in parsed["files"])
    problems: list[str] = []
    if completed is None:
        problems.append(f"IMPORT_COMPLETEDが確認できません（aborted={parsed['aborted']}）")
    else:
        if completed["files"] != expected_files:
            problems.append(f"取込ファイル数が変換結果と一致しません: {completed['files']} != {expected_files}")
        accepted = completed["total_ticks"] + completed["skipped_ticks"]
        if accepted != convert.get("tick_count"):
            problems.append(f"tick数が変換結果と一致しません: 受理{completed['total_ticks']}+skip{completed['skipped_ticks']} != {convert.get('tick_count')}")
    if parse_failures:
        problems.append(f"Importerのパース失敗が{parse_failures}行あります")

    skipped = completed["skipped_ticks"] if completed else 0
    status = "incomplete" if problems else ("complete_with_skips" if skipped else "complete")
    if skipped and not problems:
        problems.append(f"MT5が{skipped}件のtickを受理しませんでした。既存履歴への再投入でないか確認してください（verifyは受理分だけを期待値にします）")
    record = {
        "status": status,
        "imported_at": utc_now_iso(),
        "custom_symbol": custom_symbol,
        "convert_dataset_fingerprint": convert.get("dataset_fingerprint"),
        "summary": completed,
        "files": parsed["files"],
        "problems": problems,
    }
    manifest["import"] = record
    manifest.pop("mt5_verification", None)
    store.save_manifest(manifest)
    return record


def record_verify(store: DatasetStore, manifest: dict[str, Any], result: dict[str, Any] | None) -> dict[str, Any]:
    """MT5上のCustom Symbolのtick数・最初/最後の時刻を、変換結果（期待値）と突き合わせる。"""
    convert = manifest.get("convert") or {}
    imported = (manifest.get("import") or {}).get("summary") or {}
    if result is None:
        record = {"status": "failed", "checked_at": utc_now_iso(), "problems": ["TICKVERIFY_RESULTが確認できません"]}
    else:
        expected_ticks = convert.get("tick_count", 0) - imported.get("skipped_ticks", 0)
        first_expected = wall_text_to_ms(convert["first_server_time"]) if convert.get("first_server_time") else None
        last_expected = wall_text_to_ms(convert["last_server_time"]) if convert.get("last_server_time") else None
        problems = []
        if result["failed_windows"]:
            problems.append(f"tick取得に失敗した区間が{result['failed_windows']}件あります")
        if result["ticks"] != expected_ticks:
            problems.append(f"tick数が期待値と一致しません: MT5={result['ticks']} 期待={expected_ticks}")
        if result["first_msc"] != first_expected:
            problems.append(f"最初のtick時刻が一致しません: MT5={result['first_msc']} 期待={first_expected}")
        if result["last_msc"] != last_expected:
            problems.append(f"最後のtick時刻が一致しません: MT5={result['last_msc']} 期待={last_expected}")
        record = {
            "status": "verified" if not problems else "mismatch",
            "checked_at": utc_now_iso(),
            "expected_ticks": expected_ticks,
            "mt5_ticks": result["ticks"],
            "first_server_time_matches": result["first_msc"] == first_expected,
            "last_server_time_matches": result["last_msc"] == last_expected,
            "problems": problems,
        }
    manifest["mt5_verification"] = record
    store.save_manifest(manifest)
    return record


def parse_tester_report(report_path: Path) -> dict[str, Any]:
    """Strategy Testerが出力したHTMLレポートから、ヒストリー品質・tick数・バー数を取り出す。"""
    raw = report_path.read_bytes()
    text = raw.decode("utf-16") if raw[:2] in (b"\xff\xfe", b"\xfe\xff") else raw.decode("utf-8", errors="replace")
    plain = re.sub(r"<[^>]+>", "|", text)
    plain = re.sub(r"\|[\s|]*\|", "|", plain)

    def find(labels: tuple[str, ...]) -> str | None:
        for label in labels:
            if match := re.search(rf"{label}\s*:\s*\|\s*([^|]+)\|", plain):
                return match[1].strip()
        return None

    def count(labels: tuple[str, ...]) -> int | None:
        digits = re.sub(r"\D", "", find(labels) or "")
        return int(digits) if digits else None

    quality_text = find(("ヒストリー品質", "History Quality"))
    quality = re.match(r"(\d+)%", quality_text) if quality_text else None
    return {
        "quality_percent": int(quality[1]) if quality else None,
        "quality_text": quality_text,
        "ticks": count(("ティック", "Ticks")),
        "bars": count(("バー", "Bars")),
    }


def record_quality(store: DatasetStore, manifest: dict[str, Any], report: dict[str, Any], details: dict[str, Any]) -> dict[str, Any]:
    # tick数0のテストは「100%」でも何も検証していないため、成功にしない
    if not report["ticks"]:
        status = "no_ticks_tested"
    else:
        status = "verified" if report["quality_percent"] == 100 else "not_100_percent"
    record = {
        "status": status,
        "checked_at": utc_now_iso(),
        **report,
        **details,
    }
    manifest["history_quality"] = record
    store.save_manifest(manifest)
    return record
