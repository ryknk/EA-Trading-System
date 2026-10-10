from __future__ import annotations

import argparse
import json
import os
import sys
import zipfile
from pathlib import Path
from typing import Any

# OANDA証券のWeb版tickダウンロードのzip（1ファイル=タブ区切りCSV 1本）を展開しつつ、
# 行数・最初と最後のtick時刻を数える。Importerが読むCSVの用意と、投入後の件数照合の期待値作りに使う。
CHUNK_BYTES = 16 * 1024 * 1024
EXPECTED_HEADER = "<DATE>\t<TIME>\t<BID>\t<ASK>\t<LAST>\t<VOLUME>"


def _first_last_time(line: bytes) -> str:
    parts = line.decode("ascii", errors="replace").rstrip("\r\n").split("\t")
    return f"{parts[0]} {parts[1]}"


def prepare_zip(zip_path: Path, out_dir: Path) -> dict[str, Any]:
    """zipの唯一のCSVを展開し、データ行数（ヘッダー除く）と最初・最後のtick時刻を返す。"""
    out_dir.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(zip_path) as archive:
        members = [item for item in archive.infolist() if not item.is_dir()]
        if len(members) != 1:
            raise ValueError(f"zip内のファイルが1つではありません: {zip_path.name}")
        member = members[0]
        target = out_dir / Path(member.filename).name
        part = target.with_name(target.name + ".part")

        newlines = 0
        head = b""
        tail = b""
        ends_with_newline = True
        with archive.open(member) as source, part.open("wb") as destination:
            while chunk := source.read(CHUNK_BYTES):
                destination.write(chunk)
                newlines += chunk.count(b"\n")
                if head.count(b"\n") < 2:
                    head += chunk[:65536]
                tail = (tail + chunk)[-65536:]
                ends_with_newline = chunk.endswith(b"\n")
        os.replace(part, target)

    head_lines = head.split(b"\n")
    header = head_lines[0].decode("ascii", errors="replace").rstrip("\r")
    tail_lines = [line for line in tail.split(b"\n") if line.strip()]
    if len(head_lines) < 3 or not tail_lines:
        raise ValueError(f"tick行がありません: {zip_path.name}")
    data_lines = newlines - 1 + (0 if ends_with_newline else 1)
    return {
        "zip": zip_path.name,
        "csv": target.name,
        "csv_bytes": target.stat().st_size,
        "header": header,
        "header_ok": header == EXPECTED_HEADER,
        "lines": data_lines,
        "first_time": _first_last_time(head_lines[1]),
        "last_time": _first_last_time(tail_lines[-1]),
    }


def count_ticks_in_range(csv_path: Path, from_text: str, to_text: str) -> int:
    """`YYYY.MM.DD HH:MM:SS.mmm`表記の時刻が[from, to)に入る行数（文字列比較で足りる形式）。"""
    count = 0
    with csv_path.open("rb") as handle:
        handle.readline()
        for line in handle:
            stamp = line[:23].decode("ascii", errors="replace").replace("\t", " ")
            if from_text <= stamp < to_text:
                count += 1
    return count


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="OANDA tick zipの展開と行数・時刻範囲の集計")
    commands = parser.add_subparsers(dest="command", required=True)
    prepare = commands.add_parser("prepare", help="zipを展開して行数・時刻範囲を集計する")
    prepare.add_argument("--zip-dir", type=Path, required=True)
    prepare.add_argument("--out-dir", type=Path, required=True)
    prepare.add_argument("--scan-out", type=Path, required=True, help="集計結果JSON（既存の展開済みファイルはスキップ）")
    prepare.add_argument("--glob", default="*.zip")
    count = commands.add_parser("count", help="CSVの指定時刻範囲[from, to)の行数を出力する")
    count.add_argument("--csv", type=Path, required=True)
    count.add_argument("--from", dest="from_text", required=True, help="YYYY.MM.DD HH:MM:SS.mmm")
    count.add_argument("--to", dest="to_text", required=True)
    args = parser.parse_args(argv)
    if args.command == "count":
        print(count_ticks_in_range(args.csv, args.from_text, args.to_text))
        return 0

    scan: dict[str, Any] = {}
    if args.scan_out.exists():
        scan = json.loads(args.scan_out.read_text(encoding="utf-8"))
    zips = sorted(args.zip_dir.glob(args.glob))
    if not zips:
        print(f"zipが見つかりません: {args.zip_dir}", file=sys.stderr)
        return 2
    for index, zip_path in enumerate(zips, start=1):
        known = scan.get(zip_path.name)
        if known and (args.out_dir / known["csv"]).exists() and (args.out_dir / known["csv"]).stat().st_size == known["csv_bytes"]:
            print(f"[{index}/{len(zips)}] skip {zip_path.name}", flush=True)
            continue
        scan[zip_path.name] = prepare_zip(zip_path, args.out_dir)
        args.scan_out.parent.mkdir(parents=True, exist_ok=True)
        args.scan_out.write_text(json.dumps(scan, ensure_ascii=False, indent=1), encoding="utf-8")
        print(f"[{index}/{len(zips)}] {zip_path.name} lines={scan[zip_path.name]['lines']}", flush=True)
    bad = [name for name, entry in scan.items() if not entry["header_ok"]]
    if bad:
        print(f"ヘッダーが想定と異なるファイル: {bad}", file=sys.stderr)
        return 3
    return 0


if __name__ == "__main__":
    sys.exit(main())
