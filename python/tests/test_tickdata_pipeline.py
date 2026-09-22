import json
import tempfile
import unittest
from datetime import date
from pathlib import Path

from python.tickdata import cli
from python.tickdata.chunks import plan_chunks
from python.tickdata.config import DatasetConfig, load_config
from python.tickdata.convert import ConversionRefused, run_convert
from python.tickdata.download import ensure_chunk_entries, run_download
from python.tickdata.mt5results import (
    parse_import_log, parse_tester_report, parse_verify_log, record_import, record_quality, record_verify,
)
from python.tickdata.normalize import normalize_file, run_normalize
from python.tickdata.providers import ProviderError, create_provider, register_provider
from python.tickdata.providers.base import TickProvider, iter_header_csv_rows
from python.tickdata.providers.csvfile import CsvFileProvider
from python.tickdata.store import DatasetStore
from python.tickdata.validate import dataset_fingerprint, validate_dataset
from python.tests.test_tickdata_core import make_config, utc_ms

NO_SLEEP = lambda seconds: None


class ScriptedProvider(TickProvider):
    """テスト用: チャンクごとにrawへ書く内容を指定できるProvider。"""

    name = "scripted"
    source_format = "scripted CSV"
    contents: dict[str, str] = {}

    def download_chunk(self, chunk, destination) -> None:
        destination.write_text(self.contents.get(chunk.chunk_id, "timestamp,bid,ask,bid_volume,ask_volume\n"), encoding="utf-8")

    def iter_rows(self, raw_path):
        return iter_header_csv_rows(raw_path, "timestamp", "bid", "ask", "bid_volume", "ask_volume")


def raw_csv(*rows: tuple) -> str:
    return "timestamp,bid,ask,bid_volume,ask_volume\n" + "".join(",".join(str(v) for v in row) + "\n" for row in rows)


class PipelineCase(unittest.TestCase):
    def setUp(self) -> None:
        self._directory = tempfile.TemporaryDirectory()
        self.addCleanup(self._directory.cleanup)
        self.tmp = Path(self._directory.name)

    def build(self, **overrides) -> tuple[DatasetConfig, DatasetStore, TickProvider, dict, list]:
        overrides.setdefault("provider_options", {"ticks_per_day": 50})
        overrides.setdefault("retry", {"max_attempts": 2, "initial_backoff_seconds": 0.0})
        config = make_config(self.tmp, **overrides)
        store = DatasetStore(config)
        provider = create_provider(config)
        chunks = plan_chunks(config.from_date, config.to_date, config.chunk_unit)
        manifest = store.load_manifest(provider.source_format)
        ensure_chunk_entries(manifest, chunks)
        return config, store, provider, manifest, chunks

    def run_through_validate(self, store, provider, manifest, chunks) -> dict:
        run_download(store, provider, manifest, chunks, sleep=NO_SLEEP)
        run_normalize(store, provider, manifest, chunks)
        return validate_dataset(store, manifest, chunks)


class DownloadTests(PipelineCase):
    def test_failed_chunk_is_recorded_and_resume_only_retries_it(self) -> None:
        config, store, provider, manifest, chunks = self.build(
            provider_options={"ticks_per_day": 20, "fail_chunks": {"20200306": 5}})
        result = run_download(store, provider, manifest, chunks, sleep=NO_SLEEP)
        self.assertEqual(result.failed, ["20200306"])
        self.assertEqual(manifest["chunks"]["20200306"]["download"]["status"], "failed")
        self.assertFalse(list(store.raw_dir.glob("*.part")))

        # 取得済みChunkは再取得されず、失敗Chunkだけが再開される
        provider.download_calls.clear()
        provider._failures_left.clear()
        result = run_download(store, provider, manifest, chunks, sleep=NO_SLEEP)
        self.assertEqual(provider.download_calls, ["20200306"])
        self.assertTrue(result.ok)
        self.assertEqual(len(result.skipped), len(chunks) - 1)

    def test_manifest_on_disk_survives_interruption_and_resumes(self) -> None:
        config, store, provider, manifest, chunks = self.build()
        run_download(store, provider, manifest, chunks[:2], sleep=NO_SLEEP)
        reloaded = store.load_manifest(provider.source_format)
        provider.download_calls.clear()
        result = run_download(store, provider, reloaded, chunks, sleep=NO_SLEEP)
        self.assertEqual(provider.download_calls, [c.chunk_id for c in chunks[2:]])
        self.assertEqual(len(result.skipped), 2)

    def test_stale_part_file_and_truncated_raw_are_not_treated_as_complete(self) -> None:
        config, store, provider, manifest, chunks = self.build()
        run_download(store, provider, manifest, chunks, sleep=NO_SLEEP)
        target = chunks[0].chunk_id
        raw = store.raw_path(target, provider.raw_suffix)
        raw.write_text("truncated", encoding="utf-8")
        raw.with_name(raw.name + ".part").write_text("stale", encoding="utf-8")
        provider.download_calls.clear()
        run_download(store, provider, manifest, chunks, sleep=NO_SLEEP)
        self.assertEqual(provider.download_calls, [target])
        self.assertFalse(raw.with_name(raw.name + ".part").exists())

    def test_retry_uses_exponential_backoff(self) -> None:
        config, store, provider, manifest, chunks = self.build(
            provider_options={"ticks_per_day": 5, "fail_chunks": {"20200305": 3}},
            retry={"max_attempts": 4, "initial_backoff_seconds": 1.0, "max_backoff_seconds": 60.0})
        delays: list[float] = []
        result = run_download(store, provider, manifest, chunks[:1], sleep=delays.append)
        self.assertTrue(result.ok)
        self.assertEqual(delays, [1.0, 2.0, 4.0])
        self.assertEqual(manifest["chunks"]["20200305"]["download"]["attempts"], 4)

    def test_non_retryable_error_aborts_without_recording_completion(self) -> None:
        class BrokenEnvironment(ScriptedProvider):
            def download_chunk(self, chunk, destination) -> None:
                raise ProviderError("環境不備", retryable=False)

        register_provider("broken-env", BrokenEnvironment)
        config, store, provider, manifest, chunks = self.build(provider="broken-env")
        with self.assertRaises(ProviderError):
            run_download(store, provider, manifest, chunks, sleep=NO_SLEEP)
        self.assertEqual(manifest["chunks"][chunks[0].chunk_id]["download"]["status"], "pending")

    def test_header_only_raw_is_recorded_as_empty(self) -> None:
        register_provider("scripted", ScriptedProvider)
        ScriptedProvider.contents = {}
        config, store, provider, manifest, chunks = self.build(provider="scripted")
        run_download(store, provider, manifest, chunks, sleep=NO_SLEEP)
        self.assertEqual({e["download"]["status"] for e in manifest["chunks"].values()}, {"empty"})


class NormalizeTests(PipelineCase):
    def normalize(self, content: str):
        register_provider("scripted", ScriptedProvider)
        config = make_config(self.tmp, provider="scripted")
        provider = create_provider(config)
        chunk = plan_chunks(date(2020, 3, 5), date(2020, 3, 5), "day")[0]
        raw = self.tmp / "raw.csv"
        raw.write_text(content, encoding="utf-8")
        output = self.tmp / "out" / "n.csv"
        return normalize_file(provider, chunk, raw, output), output

    def test_invalid_rows_are_rejected_and_counted_by_reason(self) -> None:
        base = utc_ms(2020, 3, 5, 1)
        stats, output = self.normalize(raw_csv(
            (base, 100.0, 100.003, 1, 1),
            (base + 1, 100.1, 100.0, 1, 1),          # bid > ask
            (base + 2, "nan", 100.0, 1, 1),          # 非有限
            (base + 3, 0, 100.0, 1, 1),              # 価格0
            (base + 4, 100.0, 100.1, -1, 1),         # 負のvolume
            (utc_ms(2020, 3, 6, 1), 100, 100.1, 1, 1),  # Chunk範囲外
            (base + 5, 100.0, 100.003, 1, 1),
        ) + "garbage\n")
        self.assertEqual(stats["ticks_out"], 2)
        self.assertEqual(stats["rejected"], {
            "CROSSED_QUOTE": 1, "NON_FINITE_VALUE": 1, "NON_POSITIVE_PRICE": 1,
            "INVALID_VOLUME": 1, "TIMESTAMP_OUT_OF_RANGE": 1, "PARSE_ERROR": 1,
        })
        self.assertEqual(len(output.read_text().splitlines()), 3)  # ヘッダー + 2tick

    def test_consecutive_exact_duplicates_are_removed_but_same_time_different_price_is_kept(self) -> None:
        base = utc_ms(2020, 3, 5, 1)
        stats, _ = self.normalize(raw_csv(
            (base, 100.0, 100.003, 1, 1), (base, 100.0, 100.003, 1, 1),
            (base, 100.001, 100.004, 1, 1), (base, 100.0, 100.003, 1, 1),
        ))
        self.assertEqual((stats["ticks_out"], stats["duplicates_removed"]), (3, 1))
        self.assertEqual((stats["first_timestamp_ms"], stats["last_timestamp_ms"]), (base, base))

    def test_normalize_is_idempotent_and_reruns_when_raw_changes(self) -> None:
        config, store, provider, manifest, chunks = self.build()
        run_download(store, provider, manifest, chunks, sleep=NO_SLEEP)
        first = run_normalize(store, provider, manifest, chunks)
        second = run_normalize(store, provider, manifest, chunks)
        self.assertEqual(len(second.skipped), len(first.done))
        self.assertEqual(second.done, [])
        run_download(store, provider, manifest, chunks[:1], force=True, sleep=NO_SLEEP)
        third = run_normalize(store, provider, manifest, chunks)
        self.assertEqual(third.done, [chunks[0].chunk_id])

    def test_normalize_reports_chunks_that_were_not_downloaded(self) -> None:
        config, store, provider, manifest, chunks = self.build()
        result = run_normalize(store, provider, manifest, chunks)
        self.assertEqual(len(result.failed), len(chunks))


class ValidateTests(PipelineCase):
    def test_clean_mock_dataset_passes_with_only_expected_warnings(self) -> None:
        config, store, provider, manifest, chunks = self.build(
            provider_options={"ticks_per_day": 500}, validation={"max_gap_seconds": 6 * 3600})
        report = self.run_through_validate(store, provider, manifest, chunks)
        self.assertNotEqual(report["status"], "FAIL")
        self.assertEqual(report["tick_count"], 500 * 3)  # 3/5(木)・3/6(金)・3/8(日)。3/7(土)は休場
        self.assertEqual(report["actual_range"]["first_timestamp"][:10], "2020-03-05")
        self.assertTrue(store.validation_path.exists())
        self.assertEqual(manifest["validation"]["status"], report["status"])
        self.assertEqual(manifest["validation"]["dataset_fingerprint"], dataset_fingerprint(manifest))
        self.assertNotIn("EMPTY_CHUNK_UNEXPECTED", [c["code"] for c in report["checks"]])  # 土曜の空は想定内

    def test_incomplete_dataset_fails(self) -> None:
        config, store, provider, manifest, chunks = self.build(
            provider_options={"ticks_per_day": 10, "fail_chunks": {"20200306": 9}})
        report = self.run_through_validate(store, provider, manifest, chunks)
        self.assertEqual(report["status"], "FAIL")
        self.assertIn("INCOMPLETE_CHUNKS", [c["code"] for c in report["checks"]])

    def tamper(self, store, chunk_id: str, mutate) -> None:
        path = store.normalized_path(chunk_id)
        lines = path.read_text().splitlines()
        path.write_text("\n".join(mutate(lines)) + "\n")

    def codes(self, report, severity="error") -> set[str]:
        return {c["code"] for c in report["checks"] if c["severity"] == severity}

    def test_tampered_normalized_files_are_detected(self) -> None:
        config, store, provider, manifest, chunks = self.build(provider_options={"ticks_per_day": 30})
        self.run_through_validate(store, provider, manifest, chunks)
        day = "20200305"

        def break_order_and_quotes(lines):
            lines[1], lines[2] = lines[2], lines[1]                     # 時刻逆行
            lines[3] = ",".join([lines[3].split(",")[0], "101.0", "100.0", "1", "1"])  # bid > ask
            lines[4] = ",".join([lines[4].split(",")[0], "nan", "100.0", "1", "1"])
            return lines

        self.tamper(store, day, break_order_and_quotes)
        report = validate_dataset(store, manifest, chunks)
        self.assertEqual(report["status"], "FAIL")
        self.assertTrue({"TIMESTAMP_NOT_MONOTONIC", "CROSSED_QUOTE", "NON_FINITE_VALUE", "CHECKSUM_MISMATCH"} <= self.codes(report))

    def test_out_of_range_timestamp_and_non_positive_price_are_detected(self) -> None:
        config, store, provider, manifest, chunks = self.build(provider_options={"ticks_per_day": 30})
        self.run_through_validate(store, provider, manifest, chunks)
        self.tamper(store, "20200305", lambda lines: [lines[0], f"{utc_ms(2020, 3, 9)},-1.0,100.1,1,1", *lines[1:]])
        report = validate_dataset(store, manifest, chunks)
        self.assertTrue({"TIMESTAMP_OUT_OF_RANGE", "NON_POSITIVE_PRICE"} <= self.codes(report))

    def test_gaps_jumps_and_weekend_handling(self) -> None:
        register_provider("scripted", ScriptedProvider)
        friday, sunday = utc_ms(2020, 3, 6, 21), utc_ms(2020, 3, 8, 22)
        ScriptedProvider.contents = {
            "20200304": raw_csv((utc_ms(2020, 3, 4, 1), 100.0, 100.003, 1, 1), (utc_ms(2020, 3, 4, 9), 100.0, 100.003, 1, 1),
                                (utc_ms(2020, 3, 4, 9, 0, 1), 110.0, 110.003, 1, 1)),
            "20200306": raw_csv((friday, 110.0, 110.003, 1, 1)),
            "20200308": raw_csv((sunday, 110.0, 110.003, 1, 1)),
        }
        config, store, provider, manifest, chunks = self.build(
            provider="scripted", **{"from": "2020-03-04", "to": "2020-03-08"})
        report = self.run_through_validate(store, provider, manifest, chunks)
        self.assertEqual(report["status"], "WARN")
        self.assertEqual(self.codes(report, "warning"), {"LARGE_GAP", "PRICE_JUMP", "EMPTY_CHUNK_UNEXPECTED"})
        gap_count = next(c for c in report["checks"] if c["code"] == "LARGE_GAP")["count"]
        # 3/4 01:00→09:00(8h)と、3/4 09:00:01→3/6 21:00(平日の長い空白)の2件。金→日の週末ギャップは除外
        self.assertEqual(gap_count, 2)

    def test_rejected_ratio_above_policy_fails_but_small_ratio_only_warns(self) -> None:
        register_provider("scripted", ScriptedProvider)
        rows = [(utc_ms(2020, 3, 5, 1, 0, s), 100.0, 100.003, 1, 1) for s in range(10)]
        ScriptedProvider.contents = {"20200305": raw_csv(*rows, (utc_ms(2020, 3, 5, 2), 101.0, 100.0, 1, 1))}
        config, store, provider, manifest, chunks = self.build(
            provider="scripted", **{"from": "2020-03-05", "to": "2020-03-05"}, validation={"max_rejected_ratio": 0.5})
        report = self.run_through_validate(store, provider, manifest, chunks)
        self.assertEqual(report["status"], "WARN")
        self.assertIn("REJECTED_ROWS", self.codes(report, "warning"))
        strict = validate_dataset(DatasetStore(load_config(None, {
            "provider": "scripted", "symbol": "USDJPY", "from": "2020-03-05", "to": "2020-03-05",
            "storage_root": str(self.tmp), "validation": {"max_rejected_ratio": 0.01}})), manifest, chunks)
        self.assertEqual(strict["status"], "FAIL")

    def test_empty_dataset_fails(self) -> None:
        register_provider("scripted", ScriptedProvider)
        ScriptedProvider.contents = {}
        config, store, provider, manifest, chunks = self.build(provider="scripted")
        self.assertIn("NO_TICKS", self.codes(self.run_through_validate(store, provider, manifest, chunks)))


class ConvertTests(PipelineCase):
    def validated(self, **overrides):
        overrides.setdefault("provider_options", {"ticks_per_day": 40})
        config, store, provider, manifest, chunks = self.build(**overrides)
        report = self.run_through_validate(store, provider, manifest, chunks)
        self.assertNotEqual(report["status"], "FAIL")
        return config, store, provider, manifest, chunks

    def test_convert_requires_a_passing_validation_of_current_data(self) -> None:
        config, store, provider, manifest, chunks = self.build()
        run_download(store, provider, manifest, chunks, sleep=NO_SLEEP)
        run_normalize(store, provider, manifest, chunks)
        with self.assertRaises(ConversionRefused):
            run_convert(store, manifest, chunks, config.server_time_rule())
        validate_dataset(store, manifest, chunks)
        run_download(store, provider, manifest, chunks[:1], force=True, sleep=NO_SLEEP)
        manifest["chunks"][chunks[0].chunk_id]["normalize"]["sha256"] = "changed"
        with self.assertRaises(ConversionRefused):
            run_convert(store, manifest, chunks, config.server_time_rule())

    def test_output_matches_importer_format_and_splits_by_server_month(self) -> None:
        config, store, provider, manifest, chunks = self.validated(
            **{"from": "2020-01-30", "to": "2020-02-02"}, server_time={"mode": "ny_close"})
        convert = run_convert(store, manifest, chunks, config.server_time_rule())
        names = [item["name"] for item in convert["files"]]
        self.assertEqual(names, ["ticks_USDJPY-MOCK_2020-01.csv", "ticks_USDJPY-MOCK_2020-02.csv"])
        lines = (store.mt5_dir / names[0]).read_text().splitlines()
        self.assertEqual(lines[0], "<DATE>\t<TIME>\t<BID>\t<ASK>\t<LAST>\t<VOLUME>")
        parts = lines[1].split("\t")
        self.assertGreaterEqual(len(parts), 4)
        self.assertRegex(parts[0], r"^\d{4}\.\d{2}\.\d{2}$")
        self.assertRegex(parts[1], r"^\d{2}:\d{2}:\d{2}\.\d{3}$")
        self.assertLessEqual(float(parts[2]), float(parts[3]))
        # サーバー時刻はUTC+2なので、UTC 1/31の22:00以降は2月ファイルへ入る
        self.assertTrue(lines[-1].startswith("2020.01.31"))
        self.assertTrue((store.mt5_dir / names[1]).read_text().splitlines()[1].startswith("2020.02.01"))
        self.assertEqual(sum(item["ticks"] for item in convert["files"]), convert["tick_count"])
        self.assertEqual(convert["tick_count"], manifest["tick_count"])
        self.assertEqual(convert["server_time"], {"mode": "ny_close", "offset_hours": 0.0})

    def test_convert_then_reimport_through_csvfile_provider_restores_ticks(self) -> None:
        config, store, provider, manifest, chunks = self.validated(
            **{"from": "2020-03-05", "to": "2020-03-11"}, server_time={"mode": "ny_close"})  # 米国DST切替を含む
        convert = run_convert(store, manifest, chunks, config.server_time_rule())
        originals = []
        for chunk in chunks:
            path = store.normalized_path(chunk.chunk_id)
            if path.exists():
                originals += [line for line in path.read_text().splitlines()[1:]]
        reader = CsvFileProvider(make_config(
            self.tmp, provider="csvfile",
            provider_options={"source_time": {"mode": "ny_close"}, "source_dir": ".", "source_pattern": "x"}))
        restored = []
        for item in convert["files"]:
            for row in reader.iter_rows(store.mt5_dir / item["name"]):
                restored.append(f"{row.timestamp_ms},{row.bid},{row.ask}")
        self.assertEqual(len(restored), len(originals))
        self.assertEqual(restored, [",".join(line.split(",")[:3]) for line in originals])

    def test_convert_is_reused_until_inputs_change_and_force_rebuilds(self) -> None:
        config, store, provider, manifest, chunks = self.validated()
        first = run_convert(store, manifest, chunks, config.server_time_rule())
        marker = store.mt5_dir / first["files"][0]["name"]
        before = marker.stat().st_mtime_ns
        second = run_convert(store, manifest, chunks, config.server_time_rule())
        self.assertEqual(marker.stat().st_mtime_ns, before)
        self.assertEqual(first["converted_at"], second["converted_at"])
        run_convert(store, manifest, chunks, config.server_time_rule(), force=True)
        self.assertGreater(marker.stat().st_mtime_ns, before)

    def test_changed_server_time_regenerates_and_clears_downstream_records(self) -> None:
        from python.tickdata.timeutil import ServerTimeRule

        config, store, provider, manifest, chunks = self.validated()
        run_convert(store, manifest, chunks, ServerTimeRule("utc"))
        manifest["import"] = {"status": "complete"}
        convert = run_convert(store, manifest, chunks, ServerTimeRule("fixed", 3.0))
        self.assertEqual(convert["server_time"]["offset_hours"], 3.0)
        self.assertNotIn("import", manifest)

    def test_stale_month_files_are_removed(self) -> None:
        config, store, provider, manifest, chunks = self.validated()
        store.mt5_dir.mkdir(parents=True, exist_ok=True)
        stale = store.mt5_dir / "ticks_USDJPY-MOCK_1999-01.csv"
        stale.write_text("old")
        run_convert(store, manifest, chunks, config.server_time_rule())
        self.assertFalse(stale.exists())


IMPORT_LOG = """\
XX\t0\t10:00:00.000\tScript ImportOandaTicks (USDJPY,M1)\tCUSTOM_SYMBOL_CREATED symbol=USDJPY_TEST cloned_from=USDJPY
XX\t0\t10:00:01.000\tScript ImportOandaTicks (USDJPY,M1)\tFILE_IMPORTED file=ticks_USDJPY-MOCK_2020-03.csv ticks=2090 skipped=10 parse_failures=0
XX\t0\t10:00:02.000\tScript ImportOandaTicks (USDJPY,M1)\tIMPORT_COMPLETED symbol=USDJPY_TEST files=1 total_ticks=2090 skipped_ticks=10 elapsed_ms=1500
"""

VERIFY_LOG = "XX\t0\t10:05:00.000\tScript VerifyCustomSymbolTicks (USDJPY,M1)\tTICKVERIFY_RESULT symbol=USDJPY_TEST ticks={ticks} first_msc={first} last_msc={last} windows=8 failed_windows=0\n"


class Mt5ResultsTests(PipelineCase):
    def converted_manifest(self):
        config, store, provider, manifest, chunks = self.build(
            provider_options={"ticks_per_day": 700}, **{"from": "2020-03-05", "to": "2020-03-05"},
            validation={"max_gap_seconds": 86400})
        self.run_through_validate(store, provider, manifest, chunks)
        convert = run_convert(store, manifest, chunks, config.server_time_rule())
        return store, manifest, convert

    def test_parse_import_log(self) -> None:
        parsed = parse_import_log(IMPORT_LOG.splitlines())
        self.assertEqual(parsed["completed"]["total_ticks"], 2090)
        self.assertEqual(parsed["files"][0]["skipped"], 10)
        self.assertIsNone(parsed["aborted"])
        aborted = parse_import_log(["... IMPORT_ABORTED_AT file=a.csv files_done=0 total_ticks_so_far=5"])
        self.assertIsNone(aborted["completed"])
        self.assertIn("file=a.csv", aborted["aborted"])

    def test_record_import_requires_completion_and_matching_counts(self) -> None:
        store, manifest, convert = self.converted_manifest()
        self.assertEqual(convert["tick_count"], 700)
        self.assertEqual(record_import(store, manifest, parse_import_log(IMPORT_LOG.splitlines()), "USDJPY_TEST")["status"], "incomplete")
        good = (IMPORT_LOG.replace("2090", "700").replace("skipped=10", "skipped=0").replace("skipped_ticks=10", "skipped_ticks=0")
                .replace("ticks_USDJPY-MOCK_2020-03.csv", convert["files"][0]["name"]))
        self.assertEqual(record_import(store, manifest, parse_import_log(good.splitlines()), "USDJPY_TEST")["status"], "complete")
        self.assertEqual(record_import(store, manifest, parse_import_log([]), "USDJPY_TEST")["status"], "incomplete")
        skipped = "IMPORT_COMPLETED symbol=X files=1 total_ticks=1 skipped_ticks=699 elapsed_ms=1"
        self.assertEqual(record_import(store, manifest, parse_import_log([skipped]), "X")["status"], "complete_with_skips")
        persisted = json.loads(store.manifest_path.read_text(encoding="utf-8"))
        self.assertEqual(persisted["import"]["status"], "complete_with_skips")

    def test_record_verify_compares_count_and_first_last_timestamps(self) -> None:
        from python.tickdata.timeutil import wall_text_to_ms

        store, manifest, convert = self.converted_manifest()
        manifest["import"] = {"summary": {"skipped_ticks": 0}}
        first, last = wall_text_to_ms(convert["first_server_time"]), wall_text_to_ms(convert["last_server_time"])
        ok = parse_verify_log(VERIFY_LOG.format(ticks=700, first=first, last=last).splitlines())
        self.assertEqual(record_verify(store, manifest, ok)["status"], "verified")
        bad = parse_verify_log(VERIFY_LOG.format(ticks=699, first=first + 1, last=last).splitlines())
        record = record_verify(store, manifest, bad)
        self.assertEqual(record["status"], "mismatch")
        self.assertEqual(len(record["problems"]), 2)
        self.assertEqual(record_verify(store, manifest, None)["status"], "failed")

    def test_parse_tester_report_reads_quality_from_utf16_html(self) -> None:
        html = (
            "<table><tr><td>ヒストリー品質:</td><td><b>100% リアルティック</b></td></tr>"
            "<tr><td>バー:</td><td><b>408</b></td></tr><tr><td>ティック:</td><td><b>1234567</b></td></tr></table>"
        )
        path = self.tmp / "report.htm"
        path.write_bytes(b"\xff\xfe" + html.encode("utf-16-le"))
        parsed = parse_tester_report(path)
        self.assertEqual(parsed["quality_percent"], 100)
        self.assertEqual((parsed["bars"], parsed["ticks"]), (408, 1234567))
        english = self.tmp / "en.htm"
        english.write_text("<td>History Quality:</td><td><b>2% real ticks</b></td>", encoding="utf-8")
        self.assertEqual(parse_tester_report(english)["quality_percent"], 2)
        zero = self.tmp / "zero.htm"
        zero.write_text("<td>ヒストリー品質:</td><td><b>100% リアルティック</b></td><td>ティック:</td><td><b>0</b></td>", encoding="utf-8")
        store, manifest, _ = self.converted_manifest()
        self.assertEqual(record_quality(store, manifest, parse_tester_report(zero), {})["status"], "no_ticks_tested")
        empty = self.tmp / "none.htm"
        empty.write_text("<html></html>", encoding="utf-8")
        self.assertIsNone(parse_tester_report(empty)["quality_percent"])


class CliTests(PipelineCase):
    def write_config(self, **overrides) -> Path:
        values = {
            "provider": "mock", "symbol": "USDJPY", "from": "2020-03-05", "to": "2020-03-09",
            "storage_root": str(self.tmp / "data"), "provider_options": {"ticks_per_day": 30},
            "retry": {"max_attempts": 2, "initial_backoff_seconds": 0}, "server_time": {"mode": "ny_close"},
            "mt5": {"custom_symbol": "USDJPY_MOCKTEST"},
        }
        values.update(overrides)
        path = self.tmp / "config.json"
        path.write_text(json.dumps(values), encoding="utf-8")
        return path

    def test_run_executes_download_to_convert_and_is_idempotent(self) -> None:
        config = self.write_config()
        self.assertEqual(cli.main(["run", "--config", str(config)]), cli.EXIT_OK)
        dataset = self.tmp / "data" / "mock-USDJPY-20200305-20200309"
        manifest = json.loads((dataset / "dataset.json").read_text(encoding="utf-8"))
        for key in ("provider", "symbol", "requested_range", "actual_range", "tick_count", "source_format",
                    "normalized_format", "validation", "convert", "created_at", "updated_at"):
            self.assertIn(key, manifest)
        self.assertEqual(manifest["validation"]["status"] in ("PASS", "WARN"), True)
        self.assertTrue(all(len(item["sha256"]) == 64 for item in manifest["convert"]["files"]))
        self.assertTrue((dataset / "validation.json").exists())
        self.assertFalse((dataset / "dataset.lock").exists())
        before = manifest["convert"]["converted_at"]
        self.assertEqual(cli.main(["run", "--config", str(config)]), cli.EXIT_OK)
        again = json.loads((dataset / "dataset.json").read_text(encoding="utf-8"))
        self.assertEqual(again["convert"]["converted_at"], before)

    def test_partial_download_exits_3_and_resume_completes(self) -> None:
        config = self.write_config(provider_options={"ticks_per_day": 30, "fail_chunks": {"20200306": 2}})
        self.assertEqual(cli.main(["download", "--config", str(config)]), cli.EXIT_PARTIAL)
        # 新しいプロセスでは失敗カウンタが初期化されるため、失敗設定を外して再開する
        self.write_config()
        self.assertEqual(cli.main(["run", "--config", str(config)]), cli.EXIT_OK)

    def test_exit_codes_for_invalid_input_and_provider_environment(self) -> None:
        self.assertEqual(cli.main(["run", "--config", str(self.tmp / "missing.json")]), cli.EXIT_CONFIG)
        self.assertEqual(cli.main(["run", "--config", str(self.write_config(symbol="BAD/SYMBOL"))]), cli.EXIT_CONFIG)
        self.assertEqual(cli.main(["run", "--config", str(self.write_config(provider="nope"))]), cli.EXIT_PROVIDER_ENVIRONMENT)
        self.assertEqual(cli.main(["convert", "--config", str(self.write_config())]), cli.EXIT_VALIDATION_FAILED)  # 未検証

    def test_convert_without_server_time_is_a_config_error(self) -> None:
        config = self.write_config(server_time=None)
        self.assertEqual(cli.main(["run", "--config", str(config)]), cli.EXIT_OK)  # convertまでは行わない
        self.assertEqual(cli.main(["convert", "--config", str(config)]), cli.EXIT_CONFIG)
        self.assertEqual(cli.main(["convert", "--config", str(config), "--server-time", "fixed:2"]), cli.EXIT_OK)

    def test_validation_failure_exits_4_and_blocks_convert(self) -> None:
        config = self.write_config(retry={"max_attempts": 1, "initial_backoff_seconds": 0})
        self.assertEqual(cli.main(["run", "--config", str(config)]), cli.EXIT_OK)
        dataset = self.tmp / "data" / "mock-USDJPY-20200305-20200309"
        target = dataset / "normalized" / "20200305.csv"
        lines = target.read_text().splitlines()
        lines[1], lines[2] = lines[2], lines[1]
        target.write_text("\n".join(lines) + "\n")
        self.assertEqual(cli.main(["validate", "--config", str(config)]), cli.EXIT_VALIDATION_FAILED)
        self.assertEqual(cli.main(["convert", "--config", str(config), "--force"]), cli.EXIT_VALIDATION_FAILED)

    def test_locked_dataset_exits_7(self) -> None:
        config = self.write_config()
        dataset = self.tmp / "data" / "mock-USDJPY-20200305-20200309"
        dataset.mkdir(parents=True)
        (dataset / "dataset.lock").write_text("pid=1")
        self.assertEqual(cli.main(["download", "--config", str(config)]), cli.EXIT_LOCKED)

    def test_status_and_diff(self) -> None:
        config = self.write_config()
        self.assertEqual(cli.main(["status", "--config", str(config), "--json"]), cli.EXIT_OK)
        cli.main(["run", "--config", str(config)])
        dataset = self.tmp / "data" / "mock-USDJPY-20200305-20200309"
        copy = self.tmp / "other.json"
        copy.write_text((dataset / "dataset.json").read_text(encoding="utf-8"), encoding="utf-8")
        self.assertEqual(cli.main(["diff", "--config", str(config), "--other", str(copy)]), cli.EXIT_OK)
        altered = json.loads(copy.read_text(encoding="utf-8"))
        altered["chunks"]["20200305"]["download"]["sha256"] = "0" * 64
        copy.write_text(json.dumps(altered), encoding="utf-8")
        self.assertEqual(cli.main(["diff", "--config", str(config), "--other", str(copy)]), cli.EXIT_DIFFERENT)

    def test_record_commands_write_results_to_manifest(self) -> None:
        config = self.write_config(**{"from": "2020-03-05", "to": "2020-03-05"}, provider_options={"ticks_per_day": 700},
                                   validation={"max_gap_seconds": 86400})
        cli.main(["run", "--config", str(config)])
        dataset = self.tmp / "data" / "mock-USDJPY-20200305-20200305"
        manifest = json.loads((dataset / "dataset.json").read_text(encoding="utf-8"))
        name = manifest["convert"]["files"][0]["name"]
        log = self.tmp / "import.log"
        log.write_text(IMPORT_LOG.replace("2090", "700").replace("skipped=10", "skipped=0").replace("skipped_ticks=10", "skipped_ticks=0")
                       .replace("ticks_USDJPY-MOCK_2020-03.csv", name), encoding="utf-8")
        self.assertEqual(cli.main(["record-import", "--config", str(config), "--log", str(log)]), cli.EXIT_OK)
        report = self.tmp / "report.htm"
        report.write_bytes(b"\xff\xfe" + "<td>ヒストリー品質:</td><td><b>100% リアルティック</b></td><td>ティック:</td><td><b>5 000</b></td>".encode("utf-16-le"))
        self.assertEqual(cli.main(["record-quality", "--config", str(config), "--report", str(report)]), cli.EXIT_OK)
        stored = json.loads((dataset / "dataset.json").read_text(encoding="utf-8"))
        self.assertEqual((stored["import"]["status"], stored["history_quality"]["quality_percent"]), ("complete", 100))


if __name__ == "__main__":
    unittest.main()
