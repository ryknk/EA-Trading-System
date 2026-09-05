import json
import tempfile
import unittest
import uuid
from datetime import UTC, datetime
from pathlib import Path

import pandas as pd

from python.analysis.drawdown import build_drawdown_curve, summarize_drawdown
from python.analysis.performance import TRADE_COLUMNS, analyze_performance, normalize_closed_trades
from python.analysis.reports import load_analysis_inputs, main, write_report
from python.analysis.shadow_evaluation import compare_llm_shadow


def trades_frame(pnls=(100.0, -50.0, -100.0, 200.0, 0.0)) -> pd.DataFrame:
    rows = []
    for index, pnl in enumerate(pnls):
        rows.append({
            "trade_id": f"trade-{index}", "trade_candidate_id": f"candidate-{index}",
            "symbol": "USDJPY" if index < 3 else "EURUSD",
            "strategy": "BREAKOUT" if index % 2 == 0 else "PULLBACK",
            "direction": "BUY" if index % 2 == 0 else "SELL",
            "open_time": f"2025-01-{index + 1:02d}T00:00:00Z",
            "close_time": f"2025-01-{index + 1:02d}T12:00:00Z",
            "volume": 0.1, "open_price": 145.0, "close_price": 145.5,
            "net_pnl": pnl, "commission": -10.0, "swap": 0.0,
        })
    return pd.DataFrame(rows, columns=TRADE_COLUMNS)


def audit_event(event_type: str, candidate: str, timestamp: str, payload: dict) -> dict:
    return {
        "schema_version": "1.0", "event_id": str(uuid.uuid4()),
        "trade_candidate_id": candidate, "request_id": "", "ea_id": "trend-ea-v1",
        "timestamp": timestamp, "event_type": event_type, "symbol": "USDJPY", "payload": payload,
    }


class DrawdownTests(unittest.TestCase):
    def test_peak_trough_and_recovery_are_identified(self) -> None:
        points = pd.DataFrame({
            "timestamp": pd.to_datetime([
                "2025-01-01T00:00:00Z", "2025-01-02T00:00:00Z",
                "2025-01-03T00:00:00Z", "2025-01-04T00:00:00Z",
            ], utc=True),
            "equity": [1000.0, 1100.0, 900.0, 1100.0],
        })
        stats = summarize_drawdown(build_drawdown_curve(points))
        self.assertEqual(200.0, stats.max_drawdown_amount)
        self.assertAlmostEqual(200.0 / 1100.0, stats.max_drawdown_rate)
        self.assertEqual("2025-01-02T00:00:00Z", stats.peak_time)
        self.assertEqual("2025-01-04T00:00:00Z", stats.recovery_time)


class PerformanceTests(unittest.TestCase):
    def test_llm_shadow_comparison_excludes_only_vetoed_trades(self) -> None:
        frame = trades_frame((100.0, -50.0, 200.0))
        frame["llm_status"] = ["ALLOW", "VETO", "ALLOW"]
        comparison = compare_llm_shadow(frame, 1_000.0)
        self.assertEqual(comparison["vetoed_trade_count"], 1)
        self.assertEqual(comparison["mode_a_no_llm_filter"]["number_of_trades"], 3)
        self.assertEqual(comparison["mode_b_llm_veto_applied"]["number_of_trades"], 2)

    def test_required_metrics_use_net_pnl_once(self) -> None:
        metrics, curve, normalized = analyze_performance(trades_frame(), 1000.0)
        self.assertEqual(5, metrics.number_of_trades)
        self.assertEqual(150.0, metrics.net_profit)
        self.assertEqual(1150.0, metrics.ending_balance)
        self.assertEqual(300.0, metrics.gross_profit)
        self.assertEqual(-150.0, metrics.gross_loss)
        self.assertEqual(2.0, metrics.profit_factor)
        self.assertEqual(0.4, metrics.win_rate)
        self.assertEqual(150.0, metrics.average_win)
        self.assertEqual(-75.0, metrics.average_loss)
        self.assertEqual(30.0, metrics.expectancy)
        self.assertEqual(2, metrics.maximum_consecutive_losses)
        self.assertAlmostEqual(150.0 / 1100.0, metrics.max_drawdown_rate)
        self.assertEqual("CLOSED_TRADES", metrics.drawdown_source)
        self.assertIsNotNone(metrics.sharpe_ratio)
        self.assertEqual(len(normalized), 5)
        self.assertFalse(curve.empty)

    def test_account_snapshots_override_closed_trade_drawdown(self) -> None:
        snapshots = pd.DataFrame({
            "timestamp": ["2025-01-01T00:00:00Z", "2025-01-02T00:00:00Z", "2025-01-03T00:00:00Z"],
            "equity": [1000.0, 800.0, 1050.0],
        })
        metrics, _, _ = analyze_performance(trades_frame(), 1000.0, snapshots)
        self.assertEqual("ACCOUNT_EQUITY_SNAPSHOTS", metrics.drawdown_source)
        self.assertEqual("ACCOUNT_EQUITY_SNAPSHOTS", metrics.sharpe_source)
        self.assertEqual(200.0, metrics.max_drawdown_amount)
        self.assertEqual(0.2, metrics.max_drawdown_rate)
        self.assertAlmostEqual(150.0 / 1100.0, metrics.closed_trade_max_drawdown_rate)

    def test_first_snapshot_drawdown_is_measured_from_initial_balance(self) -> None:
        snapshots = pd.DataFrame({
            "timestamp": ["2025-01-01T00:00:00Z", "2025-01-02T00:00:00Z"],
            "equity": [800.0, 900.0],
        })
        metrics, _, _ = analyze_performance(trades_frame((10.0,)), 1000.0, snapshots)
        self.assertEqual(200.0, metrics.max_drawdown_amount)
        self.assertEqual(0.2, metrics.max_drawdown_rate)

    def test_no_losses_has_null_profit_factor_and_strict_json_report(self) -> None:
        metrics, curve, trades = analyze_performance(trades_frame((10.0, 20.0)), 1000.0)
        self.assertIsNone(metrics.profit_factor)
        with tempfile.TemporaryDirectory() as directory:
            paths = write_report(
                Path(directory), metrics, curve, trades,
                generated_at=datetime(2025, 1, 1, tzinfo=UTC),
            )
            report = json.loads(paths["json"].read_text(encoding="utf-8"))
            self.assertIsNone(report["metrics"]["profit_factor"])
            self.assertTrue(paths["monthly"].exists())
            self.assertEqual(2, sum(row["number_of_trades"] for row in report["by_symbol"]))

    def test_malformed_input_is_rejected(self) -> None:
        naive = trades_frame((10.0,))
        naive.loc[0, "open_time"] = "2025-01-01T00:00:00"
        with self.assertRaisesRegex(ValueError, "UTC offset"):
            normalize_closed_trades(naive)
        duplicate = trades_frame((10.0, 20.0))
        duplicate.loc[1, "trade_id"] = duplicate.loc[0, "trade_id"]
        with self.assertRaisesRegex(ValueError, "unique"):
            normalize_closed_trades(duplicate)
        non_finite = trades_frame((10.0,))
        non_finite.loc[0, "net_pnl"] = float("nan")
        with self.assertRaisesRegex(ValueError, "finite"):
            normalize_closed_trades(non_finite)


class AuditInputTests(unittest.TestCase):
    def test_phase9_jsonl_is_correlated_without_double_counting_costs(self) -> None:
        candidate = "trend-ea-v1-USDJPY-1"
        records = [
            audit_event("CANDIDATE", candidate, "2025-01-01T00:00:00Z", {
                "direction": "BUY", "pattern": "BREAKOUT", "entry_price": 145.0,
                "stop_loss": 144.0, "take_profit": 147.0, "risk_reward_ratio": 2.0,
                "reason_code": "TREND_BREAKOUT", "reason": "Aligned.",
            }),
            audit_event("ACCOUNT_SNAPSHOT", "system", "2025-01-01T00:00:00Z", {
                "balance": 1000.0, "equity": 980.0, "margin": 10.0,
                "free_margin": 970.0, "margin_level": 9800.0, "open_positions": 1,
            }),
            audit_event("TRADE_CLOSED", candidate, "2025-01-02T00:00:00Z", {
                "position_ticket": "123", "direction": "BUY",
                "open_time": "2025-01-01T00:00:00Z", "close_time": "2025-01-02T00:00:00Z",
                "volume": 0.1, "open_price": 145.0, "close_price": 146.0,
                "close_reason": "TP", "pnl": 90.0, "commission": -10.0, "swap": 0.0,
                "exit_spread_points": 1.5, "point_value": 100.0,
            }),
        ]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "audit.jsonl"
            path.write_text("\n".join(json.dumps(row) for row in records), encoding="utf-8")
            inputs = load_analysis_inputs([path])
        self.assertEqual("BREAKOUT", inputs.trades.iloc[0]["strategy"])
        self.assertEqual(90.0, inputs.trades.iloc[0]["net_pnl"])
        self.assertEqual(980.0, inputs.equity_snapshots.iloc[0]["equity"])

    def test_breakout_timing_events_do_not_block_reports_analysis(self) -> None:
        # BREAKOUT_TIMING_SETUP/TRADE（InpEnableBreakoutTimingAnalysis=true時のみ生成される
        # 分析専用イベント）が同一の監査JSONLに混在していても、通常のTRADE_CLOSED集計を妨げない
        # ことを確認する回帰テスト（SUPPORTED_AUDIT_EVENTSへの追加漏れで一度失敗した経緯がある）。
        candidate = "trend-ea-v1-USDJPY-breakout-timing"
        records = [
            audit_event("BREAKOUT_TIMING_SETUP", "BT-trend-ea-v1-USDJPY-1", "2025-01-01T00:00:00Z", {
                "setup_bar_time": "2025-01-01T00:00:00Z", "direction": "BUY",
                "breakout_level_high": 145.5, "breakout_level_low": 144.0,
                "pre_entry_mfe_price": 146.0, "pre_entry_mfe_r": 0.5,
                "pre_entry_mfe_time": "2025-01-01T02:00:00Z",
                "pre_entry_mae_price": 145.2, "pre_entry_mae_r": -0.1,
                "pre_entry_mae_time": "2025-01-01T01:00:00Z",
                "confirm_1_bar_held": True, "confirm_2_bars_held": True, "confirm_3_bars_held": False,
            }),
            audit_event("BREAKOUT_TIMING_TRADE", "BT-trend-ea-v1-USDJPY-1", "2025-01-01T00:00:00Z", {
                "variant": "IMMEDIATE", "entry_bar_time": "2025-01-01T00:00:00Z", "direction": "BUY",
                "entry_price": 145.6, "stop_loss": 144.6, "take_profit": 147.6,
                "wait_bars": 0, "bars_held": 3, "mfe_r": 1.0, "mae_r": -0.2,
                "exit_reason": "TP", "exit_price": 147.6, "pnl_r": 2.0, "checkpoint_r": {"bars_1": 0.3},
            }),
            audit_event("CANDIDATE", candidate, "2025-01-01T00:00:00Z", {
                "direction": "BUY", "pattern": "BREAKOUT", "entry_price": 145.0,
                "stop_loss": 144.0, "take_profit": 147.0, "risk_reward_ratio": 2.0,
                "reason_code": "TREND_BREAKOUT", "reason": "Aligned.",
            }),
            audit_event("TRADE_CLOSED", candidate, "2025-01-02T00:00:00Z", {
                "position_ticket": "999", "direction": "BUY",
                "open_time": "2025-01-01T00:00:00Z", "close_time": "2025-01-02T00:00:00Z",
                "volume": 0.1, "open_price": 145.0, "close_price": 146.0,
                "close_reason": "TP", "pnl": 90.0, "commission": -10.0, "swap": 0.0,
                "exit_spread_points": 1.5, "point_value": 100.0,
            }),
        ]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "audit.jsonl"
            path.write_text("\n".join(json.dumps(row) for row in records), encoding="utf-8")
            inputs = load_analysis_inputs([path])
        self.assertEqual(1, len(inputs.trades))
        self.assertEqual(90.0, inputs.trades.iloc[0]["net_pnl"])

    def test_candidate_and_close_are_correlated_across_daily_files(self) -> None:
        candidate = "trend-ea-v1-USDJPY-cross-day"
        candidate_record = audit_event("CANDIDATE", candidate, "2025-01-01T00:00:00Z", {
            "direction": "BUY", "pattern": "PULLBACK", "entry_price": 145.0,
            "stop_loss": 144.0, "take_profit": 147.0, "risk_reward_ratio": 2.0,
            "reason_code": "TREND_PULLBACK", "reason": "Aligned.",
        })
        closed_record = audit_event("TRADE_CLOSED", candidate, "2025-01-02T00:00:00Z", {
            "position_ticket": "321", "direction": "BUY",
            "open_time": "2025-01-01T00:00:00Z", "close_time": "2025-01-02T00:00:00Z",
            "volume": 0.1, "open_price": 145.0, "close_price": 146.0,
            "close_reason": "TP", "pnl": 100.0, "commission": 0.0, "swap": 0.0,
            "exit_spread_points": 1.2, "point_value": 100.0,
        })
        with tempfile.TemporaryDirectory() as directory:
            first = Path(directory) / "audit-20250101.jsonl"
            second = Path(directory) / "audit-20250102.jsonl"
            first.write_text(json.dumps(candidate_record) + "\n", encoding="utf-8")
            second.write_text(json.dumps(closed_record) + "\n", encoding="utf-8")
            inputs = load_analysis_inputs([first, second])
        self.assertEqual("PULLBACK", inputs.trades.iloc[0]["strategy"])

    def test_duplicate_json_key_and_duplicate_trade_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            invalid = Path(directory) / "invalid.jsonl"
            invalid.write_text('{"event_type":"DEAL","event_type":"DEAL"}\n', encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "invalid JSONL"):
                load_analysis_inputs([invalid])

            csv_path = Path(directory) / "trades.csv"
            duplicated = trades_frame((10.0, 20.0))
            duplicated.loc[1, "trade_id"] = duplicated.loc[0, "trade_id"]
            duplicated.to_csv(csv_path, index=False)
            with self.assertRaisesRegex(ValueError, "unique"):
                load_analysis_inputs([csv_path])

    def test_cli_writes_dashboard_ready_artifacts(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            input_path = root / "trades.csv"
            output = root / "report"
            trades_frame().to_csv(input_path, index=False)
            result = main([
                "--input", str(input_path), "--initial-balance", "1000",
                "--output", str(output),
            ])
            self.assertEqual(0, result)
            self.assertEqual(5, json.loads((output / "performance-summary.json").read_text(encoding="utf-8"))["metrics"]["number_of_trades"])
            self.assertTrue((output / "equity-curve.csv").exists())
            self.assertTrue((output / "report.md").exists())


if __name__ == "__main__":
    unittest.main()
