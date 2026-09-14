import json
import tempfile
import unittest
import uuid
from pathlib import Path

from python.analysis.breakout_timing import (
    build_breakout_timing_context,
    confirmation_hold_summary,
    variant_summary,
    write_report,
)


def audit_event(event_type: str, candidate: str, timestamp: str, payload: dict) -> dict:
    return {
        "schema_version": "1.0", "event_id": str(uuid.uuid4()),
        "trade_candidate_id": candidate, "request_id": "", "ea_id": "trend-ea-v1",
        "timestamp": timestamp, "event_type": event_type, "symbol": "USDJPY_HIST", "payload": payload,
    }


# 2つのSetup: s1は1本後・2本後は維持、3本後は反転（ダマシ）。s2は1本後で既に反転（ダマシ）。
def write_audit_file(directory: Path) -> Path:
    records = [
        audit_event("BREAKOUT_TIMING_SETUP", "s1", "2018-01-02T01:00:00Z", {
            "setup_bar_time": "2018-01-02T01:00:00Z", "direction": "BUY",
            "pre_entry_mfe_r": 0.30, "pre_entry_mae_r": -0.50,
            "confirm_1_bar_held": True, "confirm_2_bars_held": True, "confirm_3_bars_held": False,
        }),
        audit_event("BREAKOUT_TIMING_TRADE", "s1", "2018-01-02T01:00:00Z", {
            "variant": "IMMEDIATE", "entry_bar_time": "2018-01-02T01:00:00Z", "direction": "BUY",
            "wait_bars": 0, "bars_held": 5, "mfe_r": 1.2, "mae_r": -0.4,
            "exit_reason": "TP", "pnl_r": 2.0,
            "checkpoint_r": {"bars_1": 0.2, "bars_2": 0.5, "bars_3": 0.8},
        }),
        audit_event("BREAKOUT_TIMING_TRADE", "s1", "2018-01-02T02:00:00Z", {
            "variant": "CONFIRM_1_BAR", "entry_bar_time": "2018-01-02T02:00:00Z", "direction": "BUY",
            "wait_bars": 1, "bars_held": 4, "mfe_r": 1.0, "mae_r": -0.3,
            "exit_reason": "TP", "pnl_r": 2.0,
            "checkpoint_r": {"bars_1": 0.3, "bars_2": 0.6},
        }),
        audit_event("BREAKOUT_TIMING_TRADE", "s1", "2018-01-02T03:00:00Z", {
            "variant": "CONFIRM_2_BARS", "entry_bar_time": "2018-01-02T03:00:00Z", "direction": "BUY",
            "wait_bars": 2, "bars_held": 3, "mfe_r": 0.5, "mae_r": -1.0,
            "exit_reason": "SL", "pnl_r": -1.0,
            "checkpoint_r": {"bars_1": -0.2},
        }),
        # CONFIRM_3_BARSは反転(confirm_3_bars_held=False)のためTrade自体が生成されない。
        audit_event("BREAKOUT_TIMING_SETUP", "s2", "2018-01-05T09:00:00Z", {
            "setup_bar_time": "2018-01-05T09:00:00Z", "direction": "SELL",
            "pre_entry_mfe_r": 0.10, "pre_entry_mae_r": -0.20,
            "confirm_1_bar_held": False, "confirm_2_bars_held": False, "confirm_3_bars_held": False,
        }),
        audit_event("BREAKOUT_TIMING_TRADE", "s2", "2018-01-05T09:00:00Z", {
            "variant": "IMMEDIATE", "entry_bar_time": "2018-01-05T09:00:00Z", "direction": "SELL",
            "wait_bars": 0, "bars_held": 20, "mfe_r": 0.4, "mae_r": -0.9,
            "exit_reason": "EXPIRED", "pnl_r": -0.6,
            "checkpoint_r": {"bars_1": 0.1, "bars_2": -0.1, "bars_3": -0.2, "bars_5": -0.3, "bars_10": -0.5, "bars_20": -0.6},
        }),
    ]
    path = directory / "audit-20180102.jsonl"
    path.write_text("\n".join(json.dumps(row) for row in records), encoding="utf-8")
    return path


class BreakoutTimingTests(unittest.TestCase):
    def test_build_breakout_timing_context_parses_setups_and_trades(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            setups, trades = build_breakout_timing_context([path])
        self.assertEqual(2, len(setups))
        self.assertEqual(4, len(trades))
        by_id = setups.set_index("setup_id")
        self.assertEqual("BUY", by_id.loc["s1", "direction"])
        self.assertTrue(bool(by_id.loc["s1", "confirm_1_bar_held"]))
        self.assertFalse(bool(by_id.loc["s1", "confirm_3_bars_held"]))
        self.assertFalse(bool(by_id.loc["s2", "confirm_1_bar_held"]))

    def test_build_breakout_timing_context_is_empty_without_events(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "audit-empty.jsonl"
            path.write_text("", encoding="utf-8")
            setups, trades = build_breakout_timing_context([path])
        self.assertEqual(0, len(setups))
        self.assertEqual(0, len(trades))

    def test_variant_summary_splits_trades_by_variant(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            _, trades = build_breakout_timing_context([path])
        summary = variant_summary(trades)
        self.assertEqual(2, summary["IMMEDIATE"]["trades"])
        self.assertEqual(1, summary["CONFIRM_1_BAR"]["trades"])
        self.assertEqual(1, summary["CONFIRM_2_BARS"]["trades"])
        self.assertEqual(0, summary["CONFIRM_3_BARS"]["trades"])
        # IMMEDIATE: pnl_r=[2.0, -0.6] -> win_rate=0.5, net_profit=1.4
        self.assertAlmostEqual(0.5, summary["IMMEDIATE"]["win_rate"])
        self.assertAlmostEqual(1.4, summary["IMMEDIATE"]["net_profit_r"])
        self.assertAlmostEqual(1.0, summary["CONFIRM_1_BAR"]["win_rate"])
        self.assertIsNone(summary["CONFIRM_3_BARS"]["profit_factor"])

    def test_confirmation_hold_summary_reports_hold_rates_and_excursions(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            setups, _ = build_breakout_timing_context([path])
        summary = confirmation_hold_summary(setups)
        self.assertEqual(2, summary["setups_observed"])
        self.assertAlmostEqual(0.5, summary["confirm_1_bar_held_rate"])
        self.assertAlmostEqual(0.5, summary["confirm_2_bars_held_rate"])
        self.assertAlmostEqual(0.0, summary["confirm_3_bars_held_rate"])
        self.assertAlmostEqual(-0.35, summary["average_pre_entry_mae_r"])
        self.assertAlmostEqual(0.20, summary["average_pre_entry_mfe_r"])

    def test_confirmation_hold_summary_handles_empty_setups(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "audit-empty.jsonl"
            path.write_text("", encoding="utf-8")
            setups, _ = build_breakout_timing_context([path])
        summary = confirmation_hold_summary(setups)
        self.assertEqual(0, summary["setups_observed"])
        self.assertIsNone(summary["confirm_1_bar_held_rate"])

    def test_write_report_produces_schema_compatible_json(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = write_audit_file(root)
            setups, trades = build_breakout_timing_context([path])
            paths = write_report(root / "report", setups, trades)
            report = json.loads(paths["json"].read_text(encoding="utf-8"))
            self.assertEqual("1.0", report["schema_version"])
            self.assertEqual("R_MULTIPLE", report["currency"])
            self.assertIn("confirmation_hold", report)
            self.assertEqual(set(["IMMEDIATE", "CONFIRM_1_BAR", "CONFIRM_2_BARS", "CONFIRM_3_BARS"]),
                              set(report["variants"].keys()))
            self.assertTrue(paths["markdown"].exists())
            self.assertTrue(paths["setups"].exists())
            self.assertTrue(paths["trades"].exists())


if __name__ == "__main__":
    unittest.main()
