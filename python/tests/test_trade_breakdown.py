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
    entry_pipeline_funnel_summary,
    giveback_summary,
    range_exit_summary,
    reversal_from_profit_summary,
    time_stop_summary,
    trend_reversal_exit_summary,
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
         regime_trend="TrendDown", regime_volatility="NormalVolatility", close_reason="SL",
         range_exit_reason_code="RANGE_BREAK"),
    dict(id="c3", direction="BUY", open="2025-01-08T15:00:00Z", close="2025-01-08T20:00:00Z",
         pnl=-100.0, atr=0.10, adx=22.0, spread=9.0, mfe=-20.0, mae=-110.0,
         regime_trend="TrendUp", regime_volatility="NormalVolatility", close_reason="EXPERT",
         trend_reversal_trend_direction="TrendUp", trend_reversal_peak_mfe_r_multiple=0.3,
         trend_reversal_retracement_r_multiple=0.6, trend_reversal_confirmation_count=5),
    dict(id="c4", direction="SELL", open="2025-01-09T19:00:00Z", close="2025-01-10T02:00:00Z",
         pnl=200.0, atr=0.12, adx=25.0, spread=11.0, mfe=210.0, mae=-40.0,
         regime_trend="TrendDown", regime_volatility="HighVolatility", close_reason="TP"),
    dict(id="c5", direction="BUY", open="2025-01-10T23:00:00Z", close="2025-01-11T08:00:00Z",
         pnl=-30.0, atr=0.15, adx=30.0, spread=13.0, mfe=10.0, mae=-35.0,
         regime_trend="TrendUp", regime_volatility="HighVolatility", close_reason="EXPERT",
         time_stop_reason_code="MAX_HOLDING_BARS"),
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
            "exit_spread_points": 1.0, "point_value": 100.0,
        }))
        records.append(audit_event("TRADE_ANALYTICS", trade["id"], trade["close"], {
            "position_ticket": str(1000 + index), "mfe": trade["mfe"], "mae": trade["mae"],
        }))
        time_stop_reason_code = trade.get("time_stop_reason_code")
        if time_stop_reason_code is not None:
            records.append(audit_event("TIME_STOP_EXIT", trade["id"], trade["close"], {
                "position_ticket": str(1000 + index), "reason_code": time_stop_reason_code,
                "elapsed_bars": 20, "mfe_r_multiple": 0.1,
            }))
        range_exit_reason_code = trade.get("range_exit_reason_code")
        if range_exit_reason_code is not None:
            records.append(audit_event("RANGE_EXIT", trade["id"], trade["close"], {
                "position_ticket": str(1000 + index), "reason_code": range_exit_reason_code,
                "elapsed_bars": 5,
            }))
        trend_reversal_trend_direction = trade.get("trend_reversal_trend_direction")
        if trend_reversal_trend_direction is not None:
            records.append(audit_event("TREND_REVERSAL_EXIT", trade["id"], trade["close"], {
                "position_ticket": str(1000 + index), "reason_code": "TrendReversalConfirmed",
                "trend_direction": trend_reversal_trend_direction, "peak_price": 146.0,
                "peak_mfe_r_multiple": trade["trend_reversal_peak_mfe_r_multiple"],
                "retracement_r_multiple": trade["trend_reversal_retracement_r_multiple"],
                "confirmation_count": trade["trend_reversal_confirmation_count"],
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

    def test_build_trade_context_computes_peak_timing_and_post_peak_reversal(self) -> None:
        # SL到達トレードの「Peak到達までの時間」「Peak後の最大逆行」「Peak到達後クローズまでの時間」
        # 「MFEがTP相当R以上に達したか」を検証する（2026-09-06追加、TRADE_ANALYTICS.mfe_time/
        # post_peak_maeを新設した際の回帰テスト）。
        records = [
            audit_event("CANDIDATE", "peak1", "2025-02-01T00:00:00Z", {
                "direction": "BUY", "pattern": "MEAN_REVERSION", "entry_price": 145.0,
                "stop_loss": 144.0, "take_profit": 147.0, "risk_reward_ratio": 2.0,
                "atr": 0.1, "adx": 20.0, "spread_points": 10.0,
                "market_regime_trend": "Range", "market_regime_volatility": "NormalVolatility",
                "hour": 0, "day_of_week": 5, "reason_code": "RANGE_REVERSAL_ENTRY", "reason": "ok",
            }),
            audit_event("RISK_DECISION", "peak1", "2025-02-01T00:00:00Z", {
                "status": "APPROVED", "reason_code": "OK", "reason": "ok", "volume": 0.1,
                "risk_budget": 1000.0, "estimated_stop_loss": -1000.0, "required_margin": 100.0,
                "daily_loss_rate": 0.0, "drawdown_rate": 0.0,
            }),
            audit_event("TRADE_CLOSED", "peak1", "2025-02-01T05:00:00Z", {
                "position_ticket": "1", "direction": "BUY",
                "open_time": "2025-02-01T00:00:00Z", "close_time": "2025-02-01T05:00:00Z",
                "volume": 0.1, "open_price": 145.0, "close_price": 144.0,
                "close_reason": "SL", "pnl": -400.0, "commission": -10.0, "swap": 0.0,
                "exit_spread_points": 1.0, "point_value": 100.0,
            }),
            audit_event("TRADE_ANALYTICS", "peak1", "2025-02-01T05:00:00Z", {
                "position_ticket": "1", "mfe": 1800.0, "mae": -400.0,
                "mfe_time": "2025-02-01T02:00:00Z", "post_peak_mae": -400.0,
            }),
            audit_event("CANDIDATE", "peak2", "2025-02-02T00:00:00Z", {
                "direction": "BUY", "pattern": "MEAN_REVERSION", "entry_price": 145.0,
                "stop_loss": 144.0, "take_profit": 147.0, "risk_reward_ratio": 2.0,
                "atr": 0.1, "adx": 20.0, "spread_points": 10.0,
                "market_regime_trend": "Range", "market_regime_volatility": "NormalVolatility",
                "hour": 0, "day_of_week": 6, "reason_code": "RANGE_REVERSAL_ENTRY", "reason": "ok",
            }),
            audit_event("RISK_DECISION", "peak2", "2025-02-02T00:00:00Z", {
                "status": "APPROVED", "reason_code": "OK", "reason": "ok", "volume": 0.1,
                "risk_budget": 1000.0, "estimated_stop_loss": -1000.0, "required_margin": 100.0,
                "daily_loss_rate": 0.0, "drawdown_rate": 0.0,
            }),
            audit_event("TRADE_CLOSED", "peak2", "2025-02-02T04:00:00Z", {
                "position_ticket": "2", "direction": "BUY",
                "open_time": "2025-02-02T00:00:00Z", "close_time": "2025-02-02T04:00:00Z",
                "volume": 0.1, "open_price": 145.0, "close_price": 144.0,
                "close_reason": "SL", "pnl": -100.0, "commission": -10.0, "swap": 0.0,
                "exit_spread_points": 1.0, "point_value": 100.0,
            }),
            audit_event("TRADE_ANALYTICS", "peak2", "2025-02-02T04:00:00Z", {
                "position_ticket": "2", "mfe": 2500.0, "mae": -100.0,
                "mfe_time": "2025-02-02T01:00:00Z", "post_peak_mae": -100.0,
            }),
        ]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "audit-peak.jsonl"
            path.write_text("\n".join(json.dumps(row) for row in records), encoding="utf-8")
            trades = build_trade_context([path])

        by_id = trades.set_index("trade_candidate_id")
        # peak1: 開始0時、Peak(MFE)到達2時間後、クローズ5時間後 → Peakまで2h、Peakからクローズまで3h。
        self.assertAlmostEqual(2.0, by_id.loc["peak1", "time_to_peak_hours"])
        self.assertAlmostEqual(3.0, by_id.loc["peak1", "peak_to_close_hours"])
        # post_peak_mae(-400) - mfe(1800) = -2200、risk_budget=1000 → -2.2R（Peakから収支ゼロ以下まで丸ごと反転）。
        self.assertAlmostEqual(-2.2, by_id.loc["peak1", "post_peak_mae_r"])
        # mfe_r=1.8 < risk_reward_ratio=2.0 → TP相当には届いていない。
        self.assertFalse(bool(by_id.loc["peak1", "reached_tp_equivalent_r"]))

        # peak2: mfe_r=2.5 >= risk_reward_ratio=2.0 → TP相当以上に到達していたが結局SLで反転した。
        self.assertAlmostEqual(1.0, by_id.loc["peak2", "time_to_peak_hours"])
        self.assertAlmostEqual(3.0, by_id.loc["peak2", "peak_to_close_hours"])
        self.assertTrue(bool(by_id.loc["peak2", "reached_tp_equivalent_r"]))

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
        self.assertEqual(1, rows["SL"]["number_of_trades"])
        self.assertEqual(2, rows["EXPERT"]["number_of_trades"])

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

    def test_build_trade_context_flags_time_stop_triggered_trades(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            trades = build_trade_context([path])
        by_id = trades.set_index("trade_candidate_id")
        self.assertEqual("MAX_HOLDING_BARS", by_id.loc["c5", "time_stop_reason_code"])
        self.assertTrue(bool(by_id.loc["c5", "time_stop_triggered"]))
        for candidate_id in ("c1", "c2", "c3", "c4"):
            self.assertFalse(bool(by_id.loc[candidate_id, "time_stop_triggered"]))
            self.assertTrue(pd.isna(by_id.loc[candidate_id, "time_stop_reason_code"]))

    def test_time_stop_summary_counts_trades_and_pnl(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            trades = build_trade_context([path])
        summary = time_stop_summary(trades)
        self.assertEqual(1, summary["trades_closed_by_time_stop"])
        self.assertAlmostEqual(-30.0, summary["net_profit"])
        self.assertAlmostEqual(0.0, summary["win_rate"])

    def test_build_trade_context_flags_range_exit_triggered_trades(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            trades = build_trade_context([path])
        by_id = trades.set_index("trade_candidate_id")
        self.assertEqual("RANGE_BREAK", by_id.loc["c2", "range_exit_reason_code"])
        self.assertTrue(bool(by_id.loc["c2", "range_exit_triggered"]))
        for candidate_id in ("c1", "c3", "c4", "c5"):
            self.assertFalse(bool(by_id.loc[candidate_id, "range_exit_triggered"]))
            self.assertTrue(pd.isna(by_id.loc[candidate_id, "range_exit_reason_code"]))

    def test_range_exit_summary_counts_trades_and_pnl_by_reason(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            trades = build_trade_context([path])
        summary = range_exit_summary(trades)
        self.assertEqual(1, summary["trades_closed_by_range_exit"])
        self.assertAlmostEqual(-50.0, summary["net_profit"])
        self.assertAlmostEqual(0.0, summary["win_rate"])
        self.assertIn("RANGE_BREAK", summary["by_reason_code"])
        self.assertEqual(1, summary["by_reason_code"]["RANGE_BREAK"]["number_of_trades"])

    def test_build_trade_context_flags_trend_reversal_triggered_trades(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            trades = build_trade_context([path])
        by_id = trades.set_index("trade_candidate_id")
        self.assertEqual("TrendReversalConfirmed", by_id.loc["c3", "trend_reversal_reason_code"])
        self.assertEqual("TrendUp", by_id.loc["c3", "trend_reversal_trend_direction"])
        self.assertAlmostEqual(0.3, by_id.loc["c3", "trend_reversal_peak_mfe_r_multiple"])
        self.assertAlmostEqual(0.6, by_id.loc["c3", "trend_reversal_retracement_r_multiple"])
        self.assertTrue(bool(by_id.loc["c3", "trend_reversal_triggered"]))
        for candidate_id in ("c1", "c2", "c4", "c5"):
            self.assertFalse(bool(by_id.loc[candidate_id, "trend_reversal_triggered"]))
            self.assertTrue(pd.isna(by_id.loc[candidate_id, "trend_reversal_reason_code"]))

    def test_trend_reversal_exit_summary_counts_trades_and_pnl_by_direction(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            trades = build_trade_context([path])
        summary = trend_reversal_exit_summary(trades)
        self.assertEqual(1, summary["trades_closed_by_trend_reversal_exit"])
        self.assertAlmostEqual(-100.0, summary["net_profit"])
        self.assertAlmostEqual(0.0, summary["win_rate"])
        self.assertAlmostEqual(0.3, summary["average_peak_mfe_r_multiple"])
        self.assertAlmostEqual(0.6, summary["average_retracement_r_multiple"])
        self.assertIn("TrendUp", summary["by_trend_direction"])
        self.assertEqual(1, summary["by_trend_direction"]["TrendUp"]["number_of_trades"])
        # c3のmfe(-20)は一度も含み益に転じていないため、TP相当到達済みの取りこぼし候補ではない。
        self.assertEqual(0, summary["trades_that_would_likely_have_reached_tp"])

    def test_trend_reversal_exit_summary_flags_trades_that_would_likely_have_reached_tp(self) -> None:
        # 反転Exitで決済されたが、MFEがTP相当R以上に達していた（早期Exitで利益機会を
        # 取りこぼした可能性がある）ケースを検証する。risk_reward_ratio=2.0、risk_budget=1000.0のため、
        # mfe=2500(mfe_r=2.5)はTP相当R以上に到達している。
        records = [
            audit_event("CANDIDATE", "tr1", "2025-03-01T00:00:00Z", {
                "direction": "BUY", "pattern": "TREND_BREAKOUT", "entry_price": 145.0,
                "stop_loss": 144.0, "take_profit": 147.0, "risk_reward_ratio": 2.0,
                "atr": 0.1, "adx": 25.0, "spread_points": 10.0,
                "market_regime_trend": "TrendUp", "market_regime_volatility": "NormalVolatility",
                "hour": 0, "day_of_week": 5, "reason_code": "TREND_BREAKOUT", "reason": "ok",
            }),
            audit_event("RISK_DECISION", "tr1", "2025-03-01T00:00:00Z", {
                "status": "APPROVED", "reason_code": "OK", "reason": "ok", "volume": 0.1,
                "risk_budget": 1000.0, "estimated_stop_loss": -1000.0, "required_margin": 100.0,
                "daily_loss_rate": 0.0, "drawdown_rate": 0.0,
            }),
            audit_event("TRADE_CLOSED", "tr1", "2025-03-01T05:00:00Z", {
                "position_ticket": "1", "direction": "BUY",
                "open_time": "2025-03-01T00:00:00Z", "close_time": "2025-03-01T05:00:00Z",
                "volume": 0.1, "open_price": 145.0, "close_price": 145.8,
                "close_reason": "EXPERT", "pnl": 800.0, "commission": -10.0, "swap": 0.0,
                "exit_spread_points": 1.0, "point_value": 100.0,
            }),
            audit_event("TRADE_ANALYTICS", "tr1", "2025-03-01T05:00:00Z", {
                "position_ticket": "1", "mfe": 2500.0, "mae": -100.0,
                "mfe_time": "2025-03-01T02:00:00Z", "post_peak_mae": 800.0,
            }),
            audit_event("TREND_REVERSAL_EXIT", "tr1", "2025-03-01T05:00:00Z", {
                "position_ticket": "1", "reason_code": "TrendReversalConfirmed",
                "trend_direction": "TrendUp", "peak_price": 147.5,
                "peak_mfe_r_multiple": 2.5, "retracement_r_multiple": 0.55, "confirmation_count": 5,
            }),
        ]
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "audit-trend-reversal.jsonl"
            path.write_text("\n".join(json.dumps(row) for row in records), encoding="utf-8")
            trades = build_trade_context([path])
        by_id = trades.set_index("trade_candidate_id")
        self.assertTrue(bool(by_id.loc["tr1", "reached_tp_equivalent_r"]))
        summary = trend_reversal_exit_summary(trades)
        self.assertEqual(1, summary["trades_closed_by_trend_reversal_exit"])
        self.assertEqual(1, summary["trades_that_would_likely_have_reached_tp"])
        self.assertAlmostEqual(800.0, summary["net_pnl_of_trades_that_would_likely_have_reached_tp"])

    def test_entry_pipeline_funnel_summary_counts_stages_when_events_present(self) -> None:
        records = [
            audit_event("ENTRY_PIPELINE", "p1", "2025-01-06T00:00:00Z", {
                "stage_market_regime": "Range", "stage_market_regime_passed": False,
                "stage_htf_bias": "NONE", "stage_htf_bias_passed": False,
                "stage_breakout_setup_passed": False, "stage_breakout_trigger_passed": False,
                "stage_pullback_setup_passed": False, "stage_pullback_trigger_passed": False,
                "final_status": "REJECTED", "reason_code": "REGIME_NOT_TRENDING", "reason": "not trending",
            }),
            audit_event("ENTRY_PIPELINE", "p2", "2025-01-06T01:00:00Z", {
                "stage_market_regime": "TrendUp", "stage_market_regime_passed": True,
                "stage_htf_bias": "NONE", "stage_htf_bias_passed": False,
                "stage_breakout_setup_passed": False, "stage_breakout_trigger_passed": False,
                "stage_pullback_setup_passed": False, "stage_pullback_trigger_passed": False,
                "final_status": "REJECTED", "reason_code": "TREND_NOT_ALIGNED", "reason": "not aligned",
            }),
            audit_event("ENTRY_PIPELINE", "p3", "2025-01-06T02:00:00Z", {
                "stage_market_regime": "TrendUp", "stage_market_regime_passed": True,
                "stage_htf_bias": "BUY", "stage_htf_bias_passed": True,
                "stage_breakout_setup_passed": True, "stage_breakout_trigger_passed": False,
                "stage_pullback_setup_passed": True, "stage_pullback_trigger_passed": False,
                "final_status": "REJECTED", "reason_code": "ENTRY_PATTERN_NOT_FOUND", "reason": "no pattern",
            }),
            audit_event("ENTRY_PIPELINE", "p4", "2025-01-06T03:00:00Z", {
                "stage_market_regime": "TrendUp", "stage_market_regime_passed": True,
                "stage_htf_bias": "BUY", "stage_htf_bias_passed": True,
                "stage_breakout_setup_passed": True, "stage_breakout_trigger_passed": True,
                "stage_pullback_setup_passed": False, "stage_pullback_trigger_passed": False,
                "final_status": "CANDIDATE", "reason_code": "TREND_BREAKOUT", "reason": "ok",
            }),
        ]
        summary = entry_pipeline_funnel_summary(records)
        self.assertEqual(4, summary["total_bars_evaluated"])
        self.assertEqual(1, summary["reached_final_candidate"])
        self.assertEqual(1, summary["rejected_by_stage"]["market_regime"])
        self.assertEqual(1, summary["rejected_by_stage"]["htf_bias"])
        self.assertEqual(1, summary["rejected_by_stage"]["setup_or_trigger"])
        self.assertEqual(0, summary["rejected_by_stage"]["trend_strength_or_momentum_filter"])
        self.assertEqual({"REGIME_NOT_TRENDING": 1, "TREND_NOT_ALIGNED": 1, "ENTRY_PATTERN_NOT_FOUND": 1},
                          summary["rejection_reason_counts"])

    def test_build_trade_context_tolerates_entry_pipeline_events_mixed_into_audit_log(self) -> None:
        # ENTRY_PIPELINE（InpEntryUseStagedPipeline=true時のみ記録）が監査ログへ混在していても、
        # 既存のtrade_breakdown/reports.load_analysis_inputsが例外を起こさないことを検証する回帰テスト。
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            extra = [audit_event("ENTRY_PIPELINE", "unlinked", "2025-01-06T00:00:00Z", {
                "stage_market_regime": "Range", "stage_market_regime_passed": False,
                "stage_htf_bias": "NONE", "stage_htf_bias_passed": False,
                "stage_breakout_setup_passed": False, "stage_breakout_trigger_passed": False,
                "stage_pullback_setup_passed": False, "stage_pullback_trigger_passed": False,
                "final_status": "REJECTED", "reason_code": "REGIME_NOT_TRENDING", "reason": "not trending",
            })]
            with path.open("a", encoding="utf-8") as stream:
                for record in extra:
                    stream.write("\n" + json.dumps(record))
            trades = build_trade_context([path])
        self.assertEqual(5, len(trades))

    def test_entry_pipeline_funnel_summary_is_empty_when_staged_pipeline_not_used(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = write_audit_file(Path(directory))
            records = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line]
        summary = entry_pipeline_funnel_summary(records)
        self.assertEqual(0, summary["total_bars_evaluated"])
        self.assertEqual(0, summary["reached_final_candidate"])

    def test_write_report_includes_entry_pipeline_funnel_only_when_input_paths_given(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = write_audit_file(root)
            trades = build_trade_context([path])
            without_paths = write_report(root / "report-no-funnel", trades)
            report_without = json.loads(without_paths["json"].read_text(encoding="utf-8"))
            self.assertNotIn("entry_pipeline_funnel", report_without)
            with_paths = write_report(root / "report-with-funnel", trades, input_paths=[path])
            report_with = json.loads(with_paths["json"].read_text(encoding="utf-8"))
            self.assertIn("entry_pipeline_funnel", report_with)
            self.assertEqual(0, report_with["entry_pipeline_funnel"]["total_bars_evaluated"])

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
            self.assertEqual(1, report["time_stop"]["trades_closed_by_time_stop"])
            self.assertEqual(1, report["range_exit"]["trades_closed_by_range_exit"])
            self.assertEqual(1, report["trend_reversal_exit"]["trades_closed_by_trend_reversal_exit"])
            self.assertTrue(paths["markdown"].exists())
            self.assertTrue(paths["trades"].exists())


if __name__ == "__main__":
    unittest.main()
