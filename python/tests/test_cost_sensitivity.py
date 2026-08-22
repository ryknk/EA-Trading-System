import json
import tempfile
import unittest
import uuid
from pathlib import Path

from python.analysis.cost_sensitivity import (
    build_cost_context,
    cost_summary,
    tier_breakdown,
    write_report,
)


def audit_event(event_type: str, candidate: str, timestamp: str, payload: dict) -> dict:
    return {
        "schema_version": "1.0", "event_id": str(uuid.uuid4()),
        "trade_candidate_id": candidate, "request_id": "", "ea_id": "trend-ea-v1",
        "timestamp": timestamp, "event_type": event_type, "symbol": "USDJPY", "payload": payload,
    }


# 3トレード: point_value取得可否、Spread/Slippage/Commission/Swapの符号違いを網羅し、
# コスト内訳の算出（口座通貨換算・total_cost・pnl_before_cost）を検証する。
TRADES = [
    dict(
        id="cost-a", direction="BUY", open="2025-02-03T02:00:00Z", close="2025-02-03T05:00:00Z",
        entry_spread=10.0, entry_slippage=2.0, order_status="ACCEPTED",
        exit_spread=5.0, point_value=100.0, commission=-10.0, swap=-1.0, pnl=100.0,
    ),
    dict(
        id="cost-b", direction="SELL", open="2025-02-04T02:00:00Z", close="2025-02-04T05:00:00Z",
        entry_spread=8.0, entry_slippage=1.0, order_status="BLOCKED",
        exit_spread=4.0, point_value=0.0, commission=-5.0, swap=0.0, pnl=-50.0,
    ),
    dict(
        id="cost-c", direction="BUY", open="2025-02-05T02:00:00Z", close="2025-02-05T05:00:00Z",
        entry_spread=12.0, entry_slippage=3.0, order_status="ACCEPTED",
        exit_spread=6.0, point_value=50.0, commission=-8.0, swap=2.0, pnl=200.0,
    ),
]


def write_audit_file(directory: Path) -> Path:
    records = []
    for index, trade in enumerate(TRADES):
        records.append(audit_event("CANDIDATE", trade["id"], trade["open"], {
            "direction": trade["direction"], "pattern": "BREAKOUT", "entry_price": 145.0,
            "stop_loss": 144.0, "take_profit": 147.0, "risk_reward_ratio": 2.0,
            "atr": 0.1, "adx": 20.0, "spread_points": trade["entry_spread"],
            "market_regime_trend": "TrendUp", "market_regime_volatility": "NormalVolatility",
            "hour": 2, "day_of_week": 0,
            "reason_code": "TREND_BREAKOUT", "reason": "Aligned.",
        }))
        records.append(audit_event("ORDER_SUBMISSION", trade["id"], trade["open"], {
            "status": trade["order_status"], "reason_code": "ORDER_ACCEPTED", "reason": "ok",
            "order_ticket": str(2000 + index), "deal_ticket": str(3000 + index),
            "broker_retcode": 10009,
            "requested_price": 145.0, "confirmed_price": 145.0 + trade["entry_slippage"] * 0.001,
            "requested_volume": 0.1, "confirmed_volume": 0.1,
            "slippage_points": trade["entry_slippage"],
        }))
        records.append(audit_event("TRADE_CLOSED", trade["id"], trade["close"], {
            "position_ticket": str(1000 + index), "direction": trade["direction"],
            "open_time": trade["open"], "close_time": trade["close"],
            "volume": 0.1, "open_price": 145.0, "close_price": 145.5,
            "close_reason": "TP", "pnl": trade["pnl"],
            "commission": trade["commission"], "swap": trade["swap"],
            "exit_spread_points": trade["exit_spread"], "point_value": trade["point_value"],
        }))
    path = directory / "audit-20250203.jsonl"
    path.write_text("\n".join(json.dumps(row) for row in records), encoding="utf-8")
    return path


class CostSensitivityTests(unittest.TestCase):
    def test_build_cost_context_converts_points_to_money_when_point_value_available(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            trades = build_cost_context([path])
        by_id = trades.set_index("trade_candidate_id")

        row_a = by_id.loc["cost-a"]
        self.assertTrue(bool(row_a["cost_data_available"]))
        self.assertAlmostEqual(1000.0, row_a["entry_spread_cost"])  # 10pt * 100
        self.assertAlmostEqual(500.0, row_a["exit_spread_cost"])  # 5pt * 100
        self.assertAlmostEqual(200.0, row_a["entry_slippage_cost"])  # 2pt * 100
        # total_cost = (1000+500) + 200 - (-10) - (-1) = 1711
        self.assertAlmostEqual(1711.0, row_a["total_cost"])
        self.assertAlmostEqual(1811.0, row_a["pnl_before_cost"])

    def test_build_cost_context_treats_missing_point_value_as_zero_spread_cost(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            trades = build_cost_context([path])
        by_id = trades.set_index("trade_candidate_id")

        row_b = by_id.loc["cost-b"]
        self.assertFalse(bool(row_b["cost_data_available"]))
        self.assertAlmostEqual(0.0, row_b["entry_spread_cost"])
        self.assertAlmostEqual(0.0, row_b["exit_spread_cost"])
        # BLOCKEDのORDER_SUBMISSIONはslippage_pointsを持たないためEntry Slippageコストも0。
        self.assertAlmostEqual(0.0, row_b["entry_slippage_cost"])
        # total_cost = 0 - (-5) - 0 = 5
        self.assertAlmostEqual(5.0, row_b["total_cost"])
        self.assertAlmostEqual(-45.0, row_b["pnl_before_cost"])

    def test_build_cost_context_accounts_for_positive_swap_as_cost_reduction(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            trades = build_cost_context([path])
        by_id = trades.set_index("trade_candidate_id")

        row_c = by_id.loc["cost-c"]
        # total_spread=(12+6)*50=900, slippage=3*50=150, total_cost=900+150-(-8)-2=1056
        self.assertAlmostEqual(1056.0, row_c["total_cost"])
        self.assertAlmostEqual(1256.0, row_c["pnl_before_cost"])

    def test_cost_summary_aggregates_across_trades(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            trades = build_cost_context([path])
        summary = cost_summary(trades)
        self.assertEqual(3, summary["trades_total"])
        self.assertEqual(2, summary["trades_with_cost_data"])
        self.assertAlmostEqual(1711.0 + 5.0 + 1056.0, summary["total_cost"])

    def test_tier_breakdown_covers_all_trades_with_distinct_costs(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            trades = build_cost_context([path])
        rows = tier_breakdown(trades, initial_balance=1000.0)
        total_trades_in_tiers = sum(row["trades"] for row in rows)
        self.assertEqual(3, total_trades_in_tiers)
        tiers_present = {row["cost_tier"] for row in rows}
        self.assertEqual({"Low Cost", "Normal Cost", "High Cost"}, tiers_present)

    def test_write_report_produces_schema_compatible_json_and_csv(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = write_audit_file(root)
            trades = build_cost_context([path])
            paths = write_report(root / "report", trades, initial_balance=1000.0)
            report = json.loads(paths["json"].read_text(encoding="utf-8"))
            self.assertEqual("1.0", report["schema_version"])
            self.assertEqual("ACCOUNT_CURRENCY", report["currency"])
            self.assertEqual(3, report["performance_with_cost"]["number_of_trades"])
            self.assertEqual(3, report["performance_before_cost"]["number_of_trades"])
            # コスト除外時の推定純利益は、実績の純利益 + 総取引コストと一致する。
            self.assertAlmostEqual(
                report["performance_with_cost"]["net_profit"] + report["cost_summary"]["total_cost"],
                report["performance_before_cost"]["net_profit"],
            )
            self.assertTrue(paths["markdown"].exists())
            self.assertTrue(paths["trades"].exists())


if __name__ == "__main__":
    unittest.main()
