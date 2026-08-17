import json
import tempfile
import unittest
import uuid
from pathlib import Path

import pandas as pd

from python.analysis.trade_breakdown import (
    BREAKDOWN_COLUMNS,
    breakdown_by,
    build_trade_context,
    giveback_summary,
    reversal_from_profit_summary,
    write_report,
)


def audit_event(event_type: str, candidate: str, timestamp: str, payload: dict) -> dict:
    return {
        "schema_version": "1.0", "event_id": str(uuid.uuid4()),
        "trade_candidate_id": candidate, "request_id": "", "ea_id": "trend-ea-v1",
        "timestamp": timestamp, "event_type": event_type, "symbol": "USDJPY", "payload": payload,
    }


# 5トレード: 方向・曜日・Session・ATR/ADX・保有時間・MFE/MAE・市場レジーム・決済理由をそれぞれ変化させ、
# 分類集計とMFE反転（含み益からの反転）・Giveback診断の両方を検証する。
TRADES = [
    dict(id="c1", direction="BUY", open="2025-01-06T02:00:00Z", close="2025-01-06T03:00:00Z",
         pnl=100.0, atr=0.05, adx=15.0, spread=10.0, mfe=120.0, mae=-30.0,
         regime_trend="Range", regime_volatility="LowVolatility", close_reason="TP"),
    dict(id="c2", direction="SELL", open="2025-01-07T10:00:00Z", close="2025-01-07T13:00:00Z",
         pnl=-50.0, atr=0.08, adx=18.0, spread=12.0, mfe=80.0, mae=-60.0,
         regime_trend="TrendDown", regime_volatility="NormalVolatility", close_reason="SL"),
    dict(id="c3", direction="BUY", open="2025-01-08T15:00:00Z", close="2025-01-08T20:00:00Z",
         pnl=-100.0, atr=0.10, adx=22.0, spread=9.0, mfe=-20.0, mae=-110.0,
         regime_trend="TrendUp", regime_volatility="NormalVolatility", close_reason="SL"),
    dict(id="c4", direction="SELL", open="2025-01-09T19:00:00Z", close="2025-01-10T02:00:00Z",
         pnl=200.0, atr=0.12, adx=25.0, spread=11.0, mfe=210.0, mae=-40.0,
         regime_trend="TrendDown", regime_volatility="HighVolatility", close_reason="TP"),
    dict(id="c5", direction="BUY", open="2025-01-10T23:00:00Z", close="2025-01-11T08:00:00Z",
         pnl=-30.0, atr=0.15, adx=30.0, spread=13.0, mfe=10.0, mae=-35.0,
         regime_trend="TrendUp", regime_volatility="HighVolatility", close_reason="EXPERT"),
]


def write_audit_file(directory: Path) -> Path:
    records = []
    for index, trade in enumerate(TRADES):
        records.append(audit_event("CANDIDATE", trade["id"], trade["open"], {
            "direction": trade["direction"], "pattern": "BREAKOUT", "entry_price": 145.0,
            "stop_loss": 144.0, "take_profit": 147.0, "risk_reward_ratio": 2.0,
            "atr": trade["atr"], "adx": trade["adx"], "spread_points": trade["spread"],
            "market_regime_trend": trade["regime_trend"],
            "market_regime_volatility": trade["regime_volatility"],
            "hour": 0, "day_of_week": 0,
            "reason_code": "TREND_BREAKOUT", "reason": "Aligned.",
        }))
        records.append(audit_event("RISK_DECISION", trade["id"], trade["open"], {
            "status": "APPROVED", "reason_code": "OK", "reason": "ok", "volume": 0.1,
            "risk_budget": 1000.0, "estimated_stop_loss": -1000.0, "required_margin": 100.0,
            "daily_loss_rate": 0.0, "drawdown_rate": 0.0,
        }))
        records.append(audit_event("TRADE_CLOSED", trade["id"], trade["close"], {
            "position_ticket": str(1000 + index), "direction": trade["direction"],
            "open_time": trade["open"], "close_time": trade["close"],
            "volume": 0.1, "open_price": 145.0, "close_price": 145.5,
            "close_reason": trade["close_reason"], "pnl": trade["pnl"], "commission": -10.0, "swap": 0.0,
        }))
        records.append(audit_event("TRADE_ANALYTICS", trade["id"], trade["close"], {
            "position_ticket": str(1000 + index), "mfe": trade["mfe"], "mae": trade["mae"],
        }))
    path = directory / "audit-20250106.jsonl"
    path.write_text("\n".join(json.dumps(row) for row in records), encoding="utf-8")
    return path


class TradeBreakdownTests(unittest.TestCase):
    def test_build_trade_context_joins_candidate_risk_and_analytics_events(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            trades = build_trade_context([path])

        self.assertEqual(5, len(trades))
        by_id = trades.set_index("trade_candidate_id")
        self.assertEqual("Mon", by_id.loc["c1", "weekday"])
        self.assertEqual("Tokyo", by_id.loc["c1", "session"])
        self.assertEqual("Tue", by_id.loc["c2", "weekday"])
        self.assertEqual("London", by_id.loc["c2", "session"])
        self.assertEqual("Wed", by_id.loc["c3", "weekday"])
        self.assertEqual("London_NewYork_Overlap", by_id.loc["c3", "session"])
        self.assertEqual("Thu", by_id.loc["c4", "weekday"])
        self.assertEqual("NewYork", by_id.loc["c4", "session"])
        self.assertEqual("Fri", by_id.loc["c5", "weekday"])
        self.assertEqual("Tokyo", by_id.loc["c5", "session"])
        self.assertAlmostEqual(0.1, by_id.loc["c1", "r_multiple"])
        self.assertAlmostEqual(-0.05, by_id.loc["c2", "r_multiple"])
        for column in ("atr_band", "adx_band", "hold_time_band", "mfe_band", "mae_band"):
            self.assertFalse(trades[column].isna().any(), f"{column} should be populated")
        self.assertEqual("Range", by_id.loc["c1", "market_regime_trend"])
        self.assertEqual("LowVolatility", by_id.loc["c1", "market_regime_volatility"])
        self.assertEqual("TrendUp", by_id.loc["c3", "market_regime_trend"])
        self.assertEqual("HighVolatility", by_id.loc["c5", "market_regime_volatility"])
        self.assertEqual("TP", by_id.loc["c1", "close_reason"])
        self.assertEqual("SL", by_id.loc["c2", "close_reason"])
        self.assertEqual("EXPERT", by_id.loc["c5", "close_reason"])
        self.assertEqual("Mon", by_id.loc["c1", "close_weekday"])
        self.assertEqual("Tokyo", by_id.loc["c1", "close_session"])
        self.assertEqual("Tue", by_id.loc["c2", "close_weekday"])
        self.assertEqual("London_NewYork_Overlap", by_id.loc["c2", "close_session"])
        self.assertEqual("Fri", by_id.loc["c4", "close_weekday"])
        self.assertEqual("Tokyo", by_id.loc["c4", "close_session"])
        self.assertAlmostEqual(1 / 6, by_id.loc["c1", "giveback_ratio"])
        self.assertAlmostEqual(1.625, by_id.loc["c2", "giveback_ratio"])
        self.assertTrue(pd.isna(by_id.loc["c3", "giveback_ratio"]), "mfe<=0 trades should have no giveback ratio")

    def test_reversal_from_profit_counts_losses_that_had_unrealized_gain(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            trades = build_trade_context([path])
        summary = reversal_from_profit_summary(trades)
        self.assertEqual(3, summary["losing_trades_total"])
        self.assertEqual(3, summary["losing_trades_with_mfe_data"])
        self.assertEqual(2, summary["losing_trades_that_reached_unrealized_profit"])
        self.assertAlmostEqual(2 / 3, summary["share_of_losing_trades_with_data"])
        self.assertAlmostEqual(45.0, summary["average_mfe_before_reversal"])

    def test_breakdown_by_direction_splits_buy_and_sell(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            trades = build_trade_context([path])
        rows = {row["direction"]: row for row in breakdown_by(trades, "direction")}
        self.assertEqual(3, rows["BUY"]["number_of_trades"])
        self.assertEqual(2, rows["SELL"]["number_of_trades"])

    def test_breakdown_by_market_regime_splits_trend_and_volatility(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            trades = build_trade_context([path])
        trend_rows = {row["market_regime_trend"]: row for row in breakdown_by(trades, "market_regime_trend")}
        self.assertEqual(1, trend_rows["Range"]["number_of_trades"])
        self.assertEqual(2, trend_rows["TrendDown"]["number_of_trades"])
        self.assertEqual(2, trend_rows["TrendUp"]["number_of_trades"])
        volatility_rows = {
            row["market_regime_volatility"]: row for row in breakdown_by(trades, "market_regime_volatility")
        }
        self.assertEqual(1, volatility_rows["LowVolatility"]["number_of_trades"])
        self.assertEqual(2, volatility_rows["NormalVolatility"]["number_of_trades"])
        self.assertEqual(2, volatility_rows["HighVolatility"]["number_of_trades"])

    def test_breakdown_by_close_reason_splits_exit_triggers(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            trades = build_trade_context([path])
        rows = {row["close_reason"]: row for row in breakdown_by(trades, "close_reason")}
        self.assertEqual(2, rows["TP"]["number_of_trades"])
        self.assertEqual(2, rows["SL"]["number_of_trades"])
        self.assertEqual(1, rows["EXPERT"]["number_of_trades"])

    def test_giveback_summary_computes_ratio_and_full_reversal_share(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            trades = build_trade_context([path])
        summary = giveback_summary(trades)
        self.assertEqual(4, summary["trades_with_unrealized_profit"])
        self.assertAlmostEqual(1.4598214285714286, summary["average_giveback_ratio"])
        self.assertAlmostEqual(0.8958333333333334, summary["median_giveback_ratio"])
        self.assertEqual(2, summary["trades_that_fully_reversed_to_breakeven_or_loss"])
        self.assertAlmostEqual(0.5, summary["share_that_fully_reversed"])

    def test_write_report_produces_schema_compatible_json(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = write_audit_file(root)
            trades = build_trade_context([path])
            paths = write_report(root / "report", trades)
            report = json.loads(paths["json"].read_text(encoding="utf-8"))
            self.assertEqual("1.0", report["schema_version"])
            self.assertEqual("ACCOUNT_CURRENCY", report["currency"])
            self.assertEqual(set(BREAKDOWN_COLUMNS), set(report["breakdowns"].keys()))
            self.assertIn("reversal_from_profit", report)
            self.assertTrue(paths["markdown"].exists())
            self.assertTrue(paths["trades"].exists())


if __name__ == "__main__":
    unittest.main()
