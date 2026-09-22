import math
import tempfile
import unittest
import zipfile
from datetime import date, datetime, timezone
from pathlib import Path
from unittest import mock

from python.tickdata import providers as provider_registry
from python.tickdata.chunks import plan_chunks
from python.tickdata.config import ConfigError, load_config
from python.tickdata.model import (
    REASON_CROSSED_QUOTE, REASON_INVALID_VOLUME, REASON_NON_FINITE, REASON_NON_POSITIVE_PRICE,
    RejectedRow, Tick, find_invalid_reason, format_normalized_row, format_number, parse_normalized_row,
)
from python.tickdata.providers import ProviderError, create_provider
from python.tickdata.providers import dukascopy as dukascopy_module
from python.tickdata.timeutil import ServerTimeRule, WallClockFormatter, parse_date, utc_ms_to_iso, wall_text_to_ms


def utc_ms(year, month, day, hour=0, minute=0, second=0, millis=0):
    moment = datetime(year, month, day, hour, minute, second, tzinfo=timezone.utc)
    return int(moment.timestamp()) * 1000 + millis


def make_config(tmp: Path, **overrides):
    values = {
        "provider": "mock", "symbol": "USDJPY", "from": "2020-03-05", "to": "2020-03-08",
        "storage_root": str(tmp), "server_time": {"mode": "utc"},
    }
    values.update(overrides)
    return load_config(None, values)


class TimeTests(unittest.TestCase):
    def test_parse_date_accepts_dotted_slashed_and_iso(self) -> None:
        for text in ("2016.09.01", "2016/09/01", "2016-09-01"):
            self.assertEqual(parse_date(text), date(2016, 9, 1))
        with self.assertRaises(ValueError):
            parse_date("2016-13-01")

    def test_ny_close_rule_follows_us_dst(self) -> None:
        rule = ServerTimeRule("ny_close")
        winter = utc_ms(2020, 1, 15, 12)
        summer = utc_ms(2020, 7, 15, 12)
        self.assertEqual(rule.utc_ms_to_server_wall_ms(winter) - winter, 2 * 3_600_000)
        self.assertEqual(rule.utc_ms_to_server_wall_ms(summer) - summer, 3 * 3_600_000)

    def test_ny_close_dst_switch_happens_at_us_transition_not_eu(self) -> None:
        rule = ServerTimeRule("ny_close")
        # 2020-03-08(米国DST開始)前の3/6はまだ+2、3/9は+3。欧州DST開始(3/29)より前に切り替わる
        self.assertEqual(rule.offset_ms_at(utc_ms(2020, 3, 6, 12)), 2 * 3_600_000)
        self.assertEqual(rule.offset_ms_at(utc_ms(2020, 3, 9, 12)), 3 * 3_600_000)

    def test_server_wall_round_trip(self) -> None:
        for rule in (ServerTimeRule("utc"), ServerTimeRule("fixed", 2.0), ServerTimeRule("ny_close")):
            for stamp in (utc_ms(2020, 1, 15, 12, 30, 1, 123), utc_ms(2020, 7, 15, 3, 0, 0, 1), utc_ms(2020, 3, 10, 0)):
                with self.subTest(rule=rule.mode, stamp=stamp):
                    self.assertEqual(rule.server_wall_ms_to_utc_ms(rule.utc_ms_to_server_wall_ms(stamp)), stamp)

    def test_server_time_must_be_explicit_and_valid(self) -> None:
        with self.assertRaises(ValueError):
            ServerTimeRule.from_config(None)
        with self.assertRaises(ValueError):
            ServerTimeRule("local")
        with self.assertRaises(ValueError):
            ServerTimeRule("fixed", 30)

    def test_wall_clock_formatter_and_parser_agree(self) -> None:
        formatter = WallClockFormatter()
        wall = utc_ms(2016, 9, 1, 0, 0, 1, 5)
        date_text, time_text = formatter.format(wall)
        self.assertEqual((date_text, time_text), ("2016.09.01", "00:00:01.005"))
        self.assertEqual(wall_text_to_ms(f"{date_text} {time_text}"), wall)
        self.assertEqual(utc_ms_to_iso(wall), "2016-09-01T00:00:01.005Z")


class ChunkTests(unittest.TestCase):
    def test_day_chunks_cover_range_without_gaps(self) -> None:
        chunks = plan_chunks(date(2020, 2, 27), date(2020, 3, 2), "day")
        self.assertEqual([c.chunk_id for c in chunks], ["20200227", "20200228", "20200229", "20200301", "20200302"])
        for left, right in zip(chunks, chunks[1:]):
            self.assertEqual(left.end_ms, right.start_ms)
        self.assertEqual(chunks[0].end_ms - chunks[0].start_ms, 86_400_000)

    def test_month_chunks_are_clipped_to_requested_range(self) -> None:
        chunks = plan_chunks(date(2020, 11, 20), date(2021, 1, 10), "month")
        self.assertEqual([c.chunk_id for c in chunks], ["202011", "202012", "202101"])
        self.assertEqual(chunks[0].start_ms, utc_ms(2020, 11, 20))
        self.assertEqual(chunks[-1].end_ms, utc_ms(2021, 1, 11))

    def test_invalid_ranges_are_rejected(self) -> None:
        with self.assertRaises(ValueError):
            plan_chunks(date(2020, 1, 2), date(2020, 1, 1), "day")
        with self.assertRaises(ValueError):
            plan_chunks(date(2020, 1, 1), date(2020, 1, 2), "week")

    def test_saturday_only_chunk(self) -> None:
        saturday = plan_chunks(date(2020, 3, 7), date(2020, 3, 7), "day")[0]
        self.assertTrue(saturday.is_saturday_only)
        self.assertFalse(plan_chunks(date(2020, 3, 6), date(2020, 3, 6), "day")[0].is_saturday_only)


class ModelTests(unittest.TestCase):
    def test_invalid_reasons(self) -> None:
        self.assertIsNone(find_invalid_reason(Tick(1, 100.0, 100.003)))
        self.assertIsNone(find_invalid_reason(Tick(1, 100.0, 100.0)))
        self.assertEqual(find_invalid_reason(Tick(1, 100.1, 100.0)), REASON_CROSSED_QUOTE)
        self.assertEqual(find_invalid_reason(Tick(1, math.nan, 100.0)), REASON_NON_FINITE)
        self.assertEqual(find_invalid_reason(Tick(1, 100.0, math.inf)), REASON_NON_FINITE)
        self.assertEqual(find_invalid_reason(Tick(1, 0.0, 100.0)), REASON_NON_POSITIVE_PRICE)
        self.assertEqual(find_invalid_reason(Tick(1, -1.0, 100.0)), REASON_NON_POSITIVE_PRICE)
        self.assertEqual(find_invalid_reason(Tick(1, 100.0, 100.1, -1.0, 0.0)), REASON_INVALID_VOLUME)

    def test_normalized_row_round_trip(self) -> None:
        tick = Tick(1583366513697, 109.123, 109.126, 0.75, 1.5)
        self.assertEqual(parse_normalized_row(format_normalized_row(tick)), tick)
        with self.assertRaises(ValueError):
            parse_normalized_row("1,2,3")

    def test_format_number_avoids_exponent_notation(self) -> None:
        self.assertEqual(format_number(109.123), "109.123")
        self.assertNotIn("e", format_number(0.00001))
        self.assertEqual(format_number(0.0), "0.0")


class ConfigTests(unittest.TestCase):
    def test_minimal_config_and_derived_paths(self) -> None:
        config = load_config(None, {"provider": "Dukascopy", "symbol": "usdjpy", "from": "2016.09.01", "to": "2020.12.31"})
        self.assertEqual(config.provider, "dukascopy")
        self.assertEqual(config.symbol, "USDJPY")
        self.assertEqual(config.dataset_id, "dukascopy-USDJPY-20160901-20201231")
        self.assertEqual(config.mt5.source_symbol, "USDJPY")
        self.assertIsNone(config.server_time)
        with self.assertRaises(ValueError):
            config.server_time_rule()

    def test_invalid_config_is_rejected(self) -> None:
        base = {"provider": "mock", "symbol": "USDJPY", "from": "2020-01-01", "to": "2020-01-02"}
        cases = [
            {"symbol": "USD/JPY"}, {"timezone": "Asia/Tokyo"}, {"chunk_unit": "week"}, {"to": "2019-01-01"},
            {"unknown_key": 1}, {"retry": {"bogus": 1}}, {"retry": {"max_attempts": 0}}, {"provider": ""},
        ]
        for override in cases:
            with self.subTest(override=override), self.assertRaises(ConfigError):
                load_config(None, {**base, **override})

    def test_file_config_is_merged_with_section_overrides(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "config.json"
            path.write_text(
                '{"provider":"mock","symbol":"USDJPY","from":"2020-01-01","to":"2020-01-02",'
                '"mt5":{"custom_symbol":"USDJPY_A","custom_path":"X"}}', encoding="utf-8")
            config = load_config(path, {"mt5": {"custom_symbol": "USDJPY_B"}})
        self.assertEqual((config.mt5.custom_symbol, config.mt5.custom_path), ("USDJPY_B", "X"))

    def test_retry_backoff_is_exponential_and_capped(self) -> None:
        config = load_config(None, {"provider": "mock", "symbol": "A", "from": "2020-01-01", "to": "2020-01-02",
                                    "retry": {"initial_backoff_seconds": 2, "max_backoff_seconds": 10}})
        self.assertEqual([config.retry.backoff_seconds(n) for n in (1, 2, 3, 4)], [2, 4, 8, 10])


class ProviderTests(unittest.TestCase):
    def test_unknown_provider_is_a_non_retryable_error(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ProviderError) as context:
                create_provider(make_config(Path(directory), provider="nope"))
        self.assertFalse(context.exception.retryable)

    def test_register_provider_extends_registry(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            sentinel = object()
            provider_registry.register_provider("Custom-Test", lambda config: sentinel)
            try:
                self.assertIs(create_provider(make_config(Path(directory), provider="custom-test")), sentinel)
            finally:
                provider_registry._REGISTRY.pop("custom-test")

    def test_dukascopy_parser_maps_columns_by_name(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            raw = Path(directory) / "raw.csv"
            raw.write_text(
                "timestamp,askPrice,bidPrice,askVolume,bidVolume\n"
                "1583366513697,109.126,109.123,0.5,0.75\n"
                "broken,line\n"
                "\n", encoding="utf-8")
            rows = list(create_provider(make_config(Path(directory), provider="dukascopy")).iter_rows(raw))
        self.assertEqual(rows[0], Tick(1583366513697, 109.123, 109.126, 0.75, 0.5))
        self.assertIsInstance(rows[1], RejectedRow)
        self.assertEqual(len(rows), 2)

    def test_dukascopy_download_builds_command_and_reports_failures(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            tool_dir = Path(directory) / "tool"
            (tool_dir / "node_modules" / "dukascopy-node").mkdir(parents=True)
            config = make_config(Path(directory), provider="dukascopy", provider_options={"instrument": "usdjpy"})
            chunk = plan_chunks(date(2020, 3, 5), date(2020, 3, 5), "day")[0]
            provider = create_provider(config)
            with mock.patch.object(dukascopy_module, "_TOOL_DIR", tool_dir), \
                    mock.patch.object(dukascopy_module.shutil, "which", return_value="node"):
                with mock.patch.object(dukascopy_module.subprocess, "run") as run:
                    run.return_value = mock.Mock(returncode=0, stdout="", stderr="")
                    provider.download_chunk(chunk, Path(directory) / "out.csv")
                command = run.call_args.args[0]
                self.assertIn("2020-03-05T00:00:00.000Z", command)
                self.assertIn("2020-03-06T00:00:00.000Z", command)
                self.assertEqual(command[command.index("--instrument") + 1], "usdjpy")
                with mock.patch.object(dukascopy_module.subprocess, "run",
                                       return_value=mock.Mock(returncode=1, stdout="", stderr="boom")):
                    with self.assertRaises(ProviderError) as context:
                        provider.download_chunk(chunk, Path(directory) / "out.csv")
                    self.assertTrue(context.exception.retryable)

    def test_dukascopy_missing_node_or_package_is_not_retryable(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            chunk = plan_chunks(date(2020, 3, 5), date(2020, 3, 5), "day")[0]
            provider = create_provider(make_config(Path(directory), provider="dukascopy"))
            with mock.patch.object(dukascopy_module.shutil, "which", return_value=None):
                with self.assertRaises(ProviderError) as context:
                    provider.download_chunk(chunk, Path(directory) / "out.csv")
                self.assertFalse(context.exception.retryable)
            with mock.patch.object(dukascopy_module.shutil, "which", return_value="node"), \
                    mock.patch.object(dukascopy_module, "_TOOL_DIR", Path(directory) / "missing"):
                with self.assertRaises(ProviderError) as context:
                    provider.download_chunk(chunk, Path(directory) / "out.csv")
                self.assertFalse(context.exception.retryable)

    def test_csvfile_mt5_tab_converts_source_time_to_utc(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "ticks_2020-01.csv"
            source.write_text(
                "<DATE>\t<TIME>\t<BID>\t<ASK>\t<LAST>\t<VOLUME>\n"
                "2020.01.15\t02:00:00.123\t109.100\t109.103\t\t\n"
                "2020.01.15\t02:00:00.5\t109.101\t109.104\t\t\n"
                "bad line\n", encoding="utf-8")
            config = make_config(
                Path(directory), provider="csvfile",
                provider_options={"source_time": {"mode": "ny_close"}, "source_dir": directory, "source_pattern": "x"})
            rows = list(create_provider(config).iter_rows(source))
        self.assertEqual(rows[0], Tick(utc_ms(2020, 1, 15, 0, 0, 0, 123), 109.1, 109.103))
        self.assertEqual(rows[1].timestamp_ms, utc_ms(2020, 1, 15, 0, 0, 0, 500))
        self.assertIsInstance(rows[2], RejectedRow)

    def test_csvfile_requires_explicit_source_time_for_mt5_tab(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ProviderError):
                create_provider(make_config(Path(directory), provider="csvfile"))

    def test_csvfile_download_extracts_zip_and_reports_missing_file(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with zipfile.ZipFile(root / "ticks_2020-03.zip", "w") as archive:
                archive.writestr("inner.csv", "<DATE>\t<TIME>\t<BID>\t<ASK>\n")
            config = make_config(
                root, provider="csvfile", chunk_unit="month",
                provider_options={"source_time": {"mode": "utc"}, "source_dir": str(root),
                                  "source_pattern": "ticks_{yyyy}-{mm}.zip"})
            provider = create_provider(config)
            chunk = plan_chunks(date(2020, 3, 5), date(2020, 3, 8), "month")[0]
            provider.download_chunk(chunk, root / "out.csv")
            self.assertTrue((root / "out.csv").read_text().startswith("<DATE>"))
            missing = plan_chunks(date(2020, 4, 1), date(2020, 4, 2), "month")[0]
            with self.assertRaises(ProviderError) as context:
                provider.download_chunk(missing, root / "out2.csv")
            self.assertFalse(context.exception.retryable)


if __name__ == "__main__":
    unittest.main()
