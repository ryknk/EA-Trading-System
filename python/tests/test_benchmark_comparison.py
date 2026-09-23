import json
import math
import tempfile
import unittest
from datetime import date
from pathlib import Path

import pandas as pd

from python.analysis.benchmark_comparison import (
    TAX_RATE,
    MonthlyReturn,
    apply_annual_tax,
    benchmark_metrics,
    benchmark_monthly_returns,
    compare_period,
    ea_monthly_returns,
    main,
    month_range,
)
from python.analysis.performance import TRADE_COLUMNS, normalize_closed_trades

ROOT = Path(__file__).resolve().parents[2]


def trade(trade_id: str, close_time: str, pnl: float) -> dict:
    return {
        "trade_id": trade_id, "trade_candidate_id": trade_id, "symbol": "USDJPY_HIST",
        "strategy": "BREAKOUT", "direction": "BUY", "open_time": close_time, "close_time": close_time,
        "volume": 0.1, "open_price": 150.0, "close_price": 150.1, "net_pnl": pnl,
        "commission": 0.0, "swap": 0.0,
    }


def trades_frame(rows: list[dict]) -> pd.DataFrame:
    return normalize_closed_trades(pd.DataFrame(rows, columns=TRADE_COLUMNS))


def yearly_returns(values: dict[int, float]) -> list[MonthlyReturn]:
    """各年の1月だけに収益率を置き、残りの月は0とする。"""
    result: list[MonthlyReturn] = []
    for year, value in sorted(values.items()):
        result.append(MonthlyReturn(f"{year}-01", value))
        result.extend(MonthlyReturn(f"{year}-{month:02d}", 0.0) for month in range(2, 13))
    return result


class AnnualTaxTests(unittest.TestCase):
    def test_loss_is_carried_forward_and_offsets_later_gain(self) -> None:
        years = apply_annual_tax(yearly_returns({2020: -0.10, 2021: 0.20}))
        self.assertAlmostEqual(0.9, years[0].wealth_end)
        self.assertEqual(0.0, years[0].tax)
        self.assertAlmostEqual(0.18, years[1].gain)
        self.assertAlmostEqual(0.10, years[1].carryforward_used)
        self.assertAlmostEqual(0.08 * TAX_RATE, years[1].tax)
        self.assertAlmostEqual(1.08 - 0.08 * TAX_RATE, years[1].wealth_end)
        self.assertEqual([], years[1].carryforward_remaining)

    def test_loss_is_usable_for_three_years_only(self) -> None:
        usable = apply_annual_tax(yearly_returns({2020: -0.10, 2021: 0.0, 2022: 0.0, 2023: 0.10}))
        self.assertAlmostEqual(0.09, usable[-1].carryforward_used)
        self.assertEqual(0.0, usable[-1].tax)
        expired = apply_annual_tax(yearly_returns({2020: -0.10, 2021: 0.0, 2022: 0.0, 2023: 0.0, 2024: 0.10}))
        self.assertEqual(0.0, expired[-1].carryforward_used)
        self.assertAlmostEqual(0.09 * TAX_RATE, expired[-1].tax)

    def test_partial_final_year_is_taxed(self) -> None:
        years = apply_annual_tax([MonthlyReturn("2025-01", 0.0), MonthlyReturn("2026-08", 0.05)])
        self.assertEqual([2025, 2026], [item.year for item in years])
        self.assertAlmostEqual(0.05 * TAX_RATE, years[-1].tax)


class BenchmarkTests(unittest.TestCase):
    def test_benchmark_is_taxed_once_at_period_end(self) -> None:
        returns = benchmark_monthly_returns({"2019-12": 100.0, "2020-01": 110.0, "2020-02": 121.0},
                                            ["2020-01", "2020-02"], 0.0)
        metrics = benchmark_metrics(returns)
        self.assertAlmostEqual(0.21 * TAX_RATE, metrics.total_tax)
        self.assertAlmostEqual(1.21 - 0.21 * TAX_RATE, metrics.after_tax_ending_multiple)
        self.assertAlmostEqual(1.21 ** 6 - 1.0, metrics.pre_tax_cagr)

    def test_annual_fee_is_deducted_monthly(self) -> None:
        levels = {f"2020-{month:02d}": 100.0 for month in range(1, 13)} | {"2019-12": 100.0}
        returns = benchmark_monthly_returns(levels, month_range("2020-01", "2020-12"), 0.12)
        multiple = math.prod(1.0 + item.return_rate for item in returns)
        self.assertAlmostEqual(0.88, multiple)

    def test_missing_benchmark_month_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "missing"):
            benchmark_monthly_returns({"2020-01": 100.0}, ["2020-01"], 0.0)


class EaMonthlyReturnTests(unittest.TestCase):
    def test_months_are_split_in_tokyo_time(self) -> None:
        trades = trades_frame([trade("a", "2024-12-31T16:00:00Z", 1000.0)])
        returns = ea_monthly_returns(trades, 100000.0, ["2024-12", "2025-01"])
        self.assertEqual([0.0, 0.01], [item.return_rate for item in returns])
        with self.assertRaisesRegex(ValueError, "outside"):
            ea_monthly_returns(trades, 100000.0, ["2024-12"])

    def test_return_uses_realized_balance_at_month_start(self) -> None:
        trades = trades_frame([trade("a", "2025-01-10T00:00:00Z", 10000.0), trade("b", "2025-02-10T00:00:00Z", 11000.0)])
        returns = ea_monthly_returns(trades, 100000.0, ["2025-01", "2025-02"])
        self.assertAlmostEqual(0.10, returns[0].return_rate)
        self.assertAlmostEqual(0.10, returns[1].return_rate)


class ComparePeriodTests(unittest.TestCase):
    LEVELS = {"2024-12": 100.0, "2025-01": 101.0, "2025-02": 100.5, "2025-03": 102.0}

    def test_ea_must_exceed_both_after_tax_cagr_and_sharpe(self) -> None:
        strong = trades_frame([
            trade("a", "2025-01-10T00:00:00Z", 5000.0), trade("b", "2025-02-10T00:00:00Z", 4000.0),
            trade("c", "2025-03-10T00:00:00Z", 6000.0),
        ])
        result = compare_period("final_holdout", strong, 100000.0, "2025-01", "2025-03", self.LEVELS, 0.0)
        self.assertTrue(result.after_tax_cagr_exceeds_benchmark)
        self.assertTrue(result.sharpe_exceeds_benchmark)
        self.assertTrue(result.criteria_met)

        losing = trades_frame([trade("a", "2025-01-10T00:00:00Z", -5000.0)])
        result = compare_period("final_holdout", losing, 100000.0, "2025-01", "2025-03", self.LEVELS, 0.0)
        self.assertFalse(result.after_tax_cagr_exceeds_benchmark)
        self.assertFalse(result.criteria_met)

    def test_undefined_sharpe_fails_the_criteria(self) -> None:
        # 取引なしでは月次収益率の標準偏差が0となりSharpe比が算出不能になる
        empty = trades_frame([])
        result = compare_period("walk_forward", empty, 100000.0, "2025-01", "2025-03", self.LEVELS, 0.0)
        self.assertIsNone(result.ea.sharpe_ratio)
        self.assertFalse(result.sharpe_exceeds_benchmark)
        self.assertFalse(result.criteria_met)


class CommandLineTests(unittest.TestCase):
    def test_writes_report_from_case_directories(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            for case, rows in {
                "A": [trade("a", "2025-01-10T00:00:00Z", 5000.0), trade("b", "2025-02-10T00:00:00Z", -1000.0)],
                "B": [trade("c", "2025-03-10T00:00:00Z", 6000.0)],
            }.items():
                report_dir = directory / "cases" / case / "performance-report"
                report_dir.mkdir(parents=True)
                pd.DataFrame(rows, columns=TRADE_COLUMNS).to_csv(report_dir / "trades-normalized.csv", index=False)
            benchmark = directory / "acwi.csv"
            pd.DataFrame({"month": list(ComparePeriodTests.LEVELS), "level": list(ComparePeriodTests.LEVELS.values())}).to_csv(
                benchmark, index=False)
            output = directory / "out"
            exit_code = main([
                "--period", "final_holdout", "2025-01", "2025-03",
                "--input", "final_holdout", str(directory / "cases"),
                "--initial-balance", "100000", "--benchmark-csv", str(benchmark),
                "--benchmark-source", "test", "--benchmark-retrieved-on", "2026-09-23",
                "--benchmark-annual-fee", "0.0005775", "--output", str(output),
            ])
            self.assertEqual(0, exit_code)
            report = json.loads((output / "benchmark-comparison.json").read_text(encoding="utf-8"))
            schema = json.loads((ROOT / "contracts" / "benchmark-comparison-report.schema.json").read_text(encoding="utf-8"))
            self.assertEqual(set(schema["required"]), set(report))
            self.assertEqual(set(schema["$defs"]["returnMetrics"]["required"]), set(report["periods"][0]["ea"]))
            self.assertEqual(set(schema["properties"]["periods"]["items"]["required"]), set(report["periods"][0]))
            self.assertEqual(3, report["periods"][0]["number_of_trades"])
            self.assertEqual(date(2026, 9, 23).isoformat(), report["benchmark"]["retrieved_on"])
            self.assertEqual(report["criteria_met"], report["periods"][0]["criteria_met"])
            self.assertIn("# ベンチマーク比較レポート", (output / "benchmark-comparison.md").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
