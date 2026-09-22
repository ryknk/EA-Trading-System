import json
import tempfile
import unittest
import zipfile
from pathlib import Path

from python.tickdata.oanda_zip import EXPECTED_HEADER, count_ticks_in_range, main, prepare_zip

ROWS = [
    "2016.08.31\t18:00:00.027\t103.478\t103.486\t\t",
    "2016.08.31\t18:00:00.136\t103.483\t103.489\t\t",
    "2016.09.30\t17:59:59.972\t102.100\t102.108\t\t",
]


def make_zip(directory: Path, name: str, text: str) -> Path:
    path = directory / name
    with zipfile.ZipFile(path, "w") as archive:
        archive.writestr(name.replace(".zip", ".csv"), text)
    return path


class OandaZipTests(unittest.TestCase):
    def setUp(self) -> None:
        self._directory = tempfile.TemporaryDirectory()
        self.addCleanup(self._directory.cleanup)
        self.tmp = Path(self._directory.name)

    def test_prepare_extracts_and_counts_lines_and_time_range(self) -> None:
        zip_path = make_zip(self.tmp, "ticks_X_2016-09.zip", EXPECTED_HEADER + "\n" + "\n".join(ROWS) + "\n")
        result = prepare_zip(zip_path, self.tmp / "out")
        self.assertEqual(result["lines"], 3)
        self.assertEqual(result["first_time"], "2016.08.31 18:00:00.027")
        self.assertEqual(result["last_time"], "2016.09.30 17:59:59.972")
        self.assertTrue(result["header_ok"])
        self.assertEqual((self.tmp / "out" / "ticks_X_2016-09.csv").stat().st_size, result["csv_bytes"])
        self.assertFalse(list((self.tmp / "out").glob("*.part")))

    def test_last_line_without_trailing_newline_is_counted(self) -> None:
        zip_path = make_zip(self.tmp, "ticks_X_2016-09.zip", EXPECTED_HEADER + "\n" + "\n".join(ROWS))
        self.assertEqual(prepare_zip(zip_path, self.tmp / "out")["lines"], 3)

    def test_rejects_header_only_and_multi_member_zip(self) -> None:
        empty = make_zip(self.tmp, "ticks_E_2016-09.zip", EXPECTED_HEADER + "\n")
        with self.assertRaises(ValueError):
            prepare_zip(empty, self.tmp / "out")
        multi = self.tmp / "multi.zip"
        with zipfile.ZipFile(multi, "w") as archive:
            archive.writestr("a.csv", "x")
            archive.writestr("b.csv", "y")
        with self.assertRaises(ValueError):
            prepare_zip(multi, self.tmp / "out")

    def test_cli_writes_scan_and_skips_already_extracted_files(self) -> None:
        zips = self.tmp / "zips"
        zips.mkdir()
        make_zip(zips, "ticks_X_2016-09.zip", EXPECTED_HEADER + "\n" + "\n".join(ROWS) + "\n")
        scan = self.tmp / "scan.json"
        args = ["prepare", "--zip-dir", str(zips), "--out-dir", str(self.tmp / "csv"), "--scan-out", str(scan)]
        self.assertEqual(main(args), 0)
        first = json.loads(scan.read_text(encoding="utf-8"))
        csv_path = self.tmp / "csv" / "ticks_X_2016-09.csv"
        before = csv_path.stat().st_mtime_ns
        self.assertEqual(main(args), 0)
        self.assertEqual(csv_path.stat().st_mtime_ns, before)
        self.assertEqual(json.loads(scan.read_text(encoding="utf-8")), first)

    def test_cli_fails_on_unexpected_header_or_missing_zips(self) -> None:
        zips = self.tmp / "zips"
        zips.mkdir()
        self.assertEqual(main(["prepare", "--zip-dir", str(zips), "--out-dir", str(self.tmp / "o"), "--scan-out", str(self.tmp / "s.json")]), 2)
        make_zip(zips, "ticks_X_2016-09.zip", "<DATE>\t<TIME>\n" + ROWS[0] + "\n")
        self.assertEqual(main(["prepare", "--zip-dir", str(zips), "--out-dir", str(self.tmp / "o"), "--scan-out", str(self.tmp / "s.json")]), 3)

    def test_count_ticks_in_range_is_half_open(self) -> None:
        csv_path = self.tmp / "t.csv"
        csv_path.write_text(EXPECTED_HEADER + "\n" + "\n".join(ROWS) + "\n", encoding="ascii")
        self.assertEqual(count_ticks_in_range(csv_path, "2016.08.31 00:00:00.000", "2016.09.01 00:00:00.000"), 2)
        self.assertEqual(count_ticks_in_range(csv_path, "2016.08.31 18:00:00.136", "2016.09.30 17:59:59.972"), 1)
        self.assertEqual(count_ticks_in_range(csv_path, "2017.01.01 00:00:00.000", "2017.02.01 00:00:00.000"), 0)


if __name__ == "__main__":
    unittest.main()
