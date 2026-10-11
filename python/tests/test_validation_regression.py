"""検証基盤の回帰テスト。

Strategy Tester Runner（tools/run-strategy-tester.ps1）がケース単位の成績を得る経路
（CoreEA形式の監査JSONL → python.analysis.reports CLI → performance-summary.json → summary.csv）を、
手計算した期待値で固定する。検証基盤の変更によってEAの成績が誤って評価されることを検出する目的。
"""

import json
import re
import tempfile
import unittest
from pathlib import Path

from python.analysis.reports import main

ROOT = Path(__file__).resolve().parents[2]
RUNNER = ROOT / "tools" / "run-strategy-tester.ps1"
INITIAL_BALANCE = 10_000.0

# (候補時刻, 決済時刻, pnl, commission)。commissionはpnlへ再加算しない（既存の集計仕様）。
GOLDEN_TRADES = [
    ("2025-01-06T01:00:00Z", "2025-01-06T05:00:00Z", 200.0, 0.0),
    ("2025-01-07T01:00:00Z", "2025-01-07T05:00:00Z", -100.0, -5.0),
    ("2025-01-08T01:00:00Z", "2025-01-08T05:00:00Z", -50.0, 0.0),
    ("2025-01-09T01:00:00Z", "2025-01-09T05:00:00Z", 150.0, 0.0),
]


def _event(event_type: str, candidate: str, timestamp: str, payload: dict, index: int) -> dict:
    return {
        "schema_version": "1.0", "event_id": f"00000000-0000-4000-8000-{index:012d}",
        "trade_candidate_id": candidate, "request_id": "", "ea_id": "trend-ea-v1",
        "timestamp": timestamp, "event_type": event_type, "symbol": "USDJPY_HIST", "payload": payload,
    }


def golden_audit_records() -> list[dict]:
    records: list[dict] = []
    for number, (opened, closed, pnl, commission) in enumerate(GOLDEN_TRADES, start=1):
        candidate = f"trend-ea-v1-USDJPY_HIST-{number}"
        records.append(_event("CANDIDATE", candidate, opened, {
            "direction": "BUY", "pattern": "PULLBACK", "entry_price": 110.0,
            "stop_loss": 109.5, "take_profit": 111.0, "risk_reward_ratio": 2.0,
            "reason_code": "TREND_PULLBACK", "reason": "Aligned.",
        }, number * 10))
        records.append(_event("TRADE_CLOSED", candidate, closed, {
            "position_ticket": str(number), "direction": "BUY",
            "open_time": opened, "close_time": closed, "volume": 0.1,
            "open_price": 110.0, "close_price": 110.0, "close_reason": "EXPERT",
            "pnl": pnl, "commission": commission, "swap": 0.0,
            "exit_spread_points": 3.0, "point_value": 10.0,
        }, number * 10 + 1))
    return records


def run_reports_cli(directory: Path) -> dict:
    audit = directory / "audit" / "_merged-for-analysis.jsonl"
    audit.parent.mkdir(parents=True)
    audit.write_text("\n".join(json.dumps(row) for row in golden_audit_records()) + "\n", encoding="utf-8")
    output = directory / "performance-report"
    result = main([
        "--input", str(audit), "--initial-balance", str(INITIAL_BALANCE),
        "--annual-risk-free-rate", "0.0", "--output", str(output),
    ])
    if result != 0:
        raise AssertionError(f"reports CLI exit={result}")
    return json.loads((output / "performance-summary.json").read_text(encoding="utf-8"))


class GoldenAuditReportTests(unittest.TestCase):
    def test_runner_analysis_path_reproduces_hand_calculated_metrics(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            metrics = run_reports_cli(Path(directory))["metrics"]
        # 純損益 = 200 - 100 - 50 + 150 = 200。commission(-5)は再加算しない。
        self.assertEqual(4, metrics["number_of_trades"])
        self.assertEqual(200.0, metrics["net_profit"])
        self.assertEqual(INITIAL_BALANCE + 200.0, metrics["ending_balance"])
        self.assertEqual(350.0, metrics["gross_profit"])
        self.assertEqual(-150.0, metrics["gross_loss"])
        self.assertAlmostEqual(350.0 / 150.0, metrics["profit_factor"])
        self.assertEqual(0.5, metrics["win_rate"])
        self.assertEqual(175.0, metrics["average_win"])
        self.assertEqual(-75.0, metrics["average_loss"])
        self.assertEqual(50.0, metrics["expectancy"])
        self.assertEqual(2, metrics["maximum_consecutive_losses"])
        # 決済済み損益の残高曲線 10000→10200→10100→10050→10200 の最大DDは 150 / 10200。
        self.assertEqual("CLOSED_TRADES", metrics["drawdown_source"])
        self.assertEqual(150.0, metrics["max_drawdown_amount"])
        self.assertAlmostEqual(150.0 / 10_200.0, metrics["max_drawdown_rate"])

    def test_reordered_audit_lines_do_not_change_metrics(self) -> None:
        with tempfile.TemporaryDirectory() as first, tempfile.TemporaryDirectory() as second:
            baseline = run_reports_cli(Path(first))["metrics"]
            reversed_audit = Path(second) / "audit" / "_merged-for-analysis.jsonl"
            reversed_audit.parent.mkdir(parents=True)
            reversed_audit.write_text(
                "\n".join(json.dumps(row) for row in reversed(golden_audit_records())) + "\n", encoding="utf-8",
            )
            output = Path(second) / "performance-report"
            self.assertEqual(0, main([
                "--input", str(reversed_audit), "--initial-balance", str(INITIAL_BALANCE), "--output", str(output),
            ]))
            reordered = json.loads((output / "performance-summary.json").read_text(encoding="utf-8"))["metrics"]
        for key in ("net_profit", "profit_factor", "win_rate", "expectancy", "maximum_consecutive_losses",
                    "number_of_trades", "max_drawdown_amount"):
            with self.subTest(key=key):
                self.assertEqual(baseline[key], reordered[key])


class RunnerSummaryContractTests(unittest.TestCase):
    def test_metrics_read_by_runner_exist_in_performance_summary(self) -> None:
        # Runnerがsummary.csvへ転記するキー名が分析出力から消える・改名されると、
        # 該当列が黙って空欄になり成績を誤読する。Runnerのソースから参照キーを抽出して照合する。
        runner_source = RUNNER.read_text(encoding="utf-8-sig")
        referenced = sorted(set(re.findall(r"\$performanceSummary\.metrics\.([A-Za-z_]+)", runner_source)))
        self.assertGreaterEqual(len(referenced), 10)
        with tempfile.TemporaryDirectory() as directory:
            metrics = run_reports_cli(Path(directory))["metrics"]
        for key in referenced:
            with self.subTest(key=key):
                self.assertIn(key, metrics)


if __name__ == "__main__":
    unittest.main()
