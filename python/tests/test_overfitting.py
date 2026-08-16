import json
import tempfile
import unittest
from pathlib import Path

from python.analysis.overfitting import (
    OverfittingThresholds,
    assess_overfitting,
    compare_period,
    main,
)


def metrics(
    profit_factor=1.8, sharpe_ratio=1.2, expectancy=500.0, net_profit=50000.0,
    max_drawdown_rate=0.10, number_of_trades=100,
) -> dict:
    return {
        "profit_factor": profit_factor, "sharpe_ratio": sharpe_ratio, "expectancy": expectancy,
        "net_profit": net_profit, "max_drawdown_rate": max_drawdown_rate, "number_of_trades": number_of_trades,
    }


class ThresholdTests(unittest.TestCase):
    def test_unknown_key_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "unknown threshold keys"):
            OverfittingThresholds.from_dict({"typo_field": 1.0})

    def test_invalid_ordering_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "score_high must be"):
            OverfittingThresholds(score_moderate=5.0, score_high=1.0)

    def test_thresholds_round_trip(self) -> None:
        custom = OverfittingThresholds.from_dict({"degradation_high_rate": 0.6, "minimum_trade_count": 50})
        self.assertEqual(0.6, custom.degradation_high_rate)
        self.assertEqual(50, custom.minimum_trade_count)


class ComparePeriodTests(unittest.TestCase):
    def test_mild_degradation_is_low(self) -> None:
        is_metrics = metrics()
        oos_metrics = metrics(profit_factor=1.7, sharpe_ratio=1.1, expectancy=480.0, net_profit=48000.0, max_drawdown_rate=0.11)
        result = compare_period("OOS", is_metrics, oos_metrics, OverfittingThresholds())
        self.assertEqual("LOW", result.classification)

    def test_single_metric_high_degradation_alone_is_only_moderate(self) -> None:
        is_metrics = metrics()
        # profit_factorだけが大きく劣化し、他は横ばい。単一指標のみでHIGHへ断定しない。
        oos_metrics = metrics(profit_factor=0.5, sharpe_ratio=1.15, expectancy=490.0, net_profit=49000.0, max_drawdown_rate=0.10)
        result = compare_period("OOS", is_metrics, oos_metrics, OverfittingThresholds())
        self.assertEqual("MODERATE", result.classification)
        pf_comparison = next(item for item in result.metric_comparisons if item.metric == "profit_factor")
        self.assertEqual("HIGH", pf_comparison.severity)

    def test_multiple_metrics_corroborate_high(self) -> None:
        is_metrics = metrics()
        oos_metrics = metrics(
            profit_factor=0.6, sharpe_ratio=0.2, expectancy=-50.0, net_profit=-5000.0, max_drawdown_rate=0.25,
        )
        result = compare_period("OOS", is_metrics, oos_metrics, OverfittingThresholds())
        self.assertEqual("HIGH", result.classification)

    def test_trade_count_below_minimum_is_flagged(self) -> None:
        is_metrics = metrics(number_of_trades=100)
        oos_metrics = metrics(number_of_trades=5)
        result = compare_period("OOS", is_metrics, oos_metrics, OverfittingThresholds())
        self.assertFalse(result.trade_count_sufficient)

    def test_zero_in_sample_value_is_unknown_not_crash(self) -> None:
        is_metrics = metrics(net_profit=0.0)
        oos_metrics = metrics(net_profit=1000.0)
        result = compare_period("OOS", is_metrics, oos_metrics, OverfittingThresholds())
        net_profit_comparison = next(item for item in result.metric_comparisons if item.metric == "net_profit")
        self.assertIsNone(net_profit_comparison.degradation_rate)
        self.assertEqual("UNKNOWN", net_profit_comparison.severity)

    def test_near_zero_drawdown_uses_relative_floor(self) -> None:
        is_metrics = metrics(max_drawdown_rate=0.001)
        oos_metrics = metrics(max_drawdown_rate=0.02)
        thresholds = OverfittingThresholds()
        result = compare_period("OOS", is_metrics, oos_metrics, thresholds)
        dd_comparison = next(item for item in result.metric_comparisons if item.metric == "max_drawdown_rate")
        expected_rate = (0.02 - 0.001) / thresholds.drawdown_relative_floor
        self.assertAlmostEqual(expected_rate, dd_comparison.degradation_rate)


class AssessOverfittingTests(unittest.TestCase):
    def test_requires_oos_or_walk_forward(self) -> None:
        with self.assertRaisesRegex(ValueError, "oos_metrics or walk_forward_fold_metrics"):
            assess_overfitting(metrics())

    def test_insufficient_trade_count_overrides_classification(self) -> None:
        is_metrics = metrics(number_of_trades=100)
        oos_metrics = metrics(number_of_trades=10, profit_factor=0.6)
        assessment = assess_overfitting(is_metrics, oos_metrics)
        self.assertEqual("INSUFFICIENT_DATA", assessment.classification)
        self.assertTrue(assessment.reliability_warning)

    def test_walk_forward_folds_are_combined_by_mean_score(self) -> None:
        is_metrics = metrics()
        folds = [
            ("FOLD1", metrics(profit_factor=1.75, sharpe_ratio=1.15, max_drawdown_rate=0.11)),
            ("FOLD2", metrics(profit_factor=0.5, sharpe_ratio=0.2, expectancy=-50.0, net_profit=-5000.0, max_drawdown_rate=0.30)),
        ]
        assessment = assess_overfitting(is_metrics, walk_forward_fold_metrics=folds)
        self.assertEqual(2, assessment.walk_forward_summary["fold_count"])
        self.assertEqual("FOLD2", assessment.walk_forward_summary["worst_fold"])
        self.assertFalse(assessment.reliability_warning)

    def test_oos_and_walk_forward_combine_to_worse_classification(self) -> None:
        is_metrics = metrics()
        oos_metrics = metrics(profit_factor=1.7, sharpe_ratio=1.1, max_drawdown_rate=0.11)
        folds = [("FOLD1", metrics(
            profit_factor=0.6, sharpe_ratio=0.2, expectancy=-50.0, net_profit=-5000.0, max_drawdown_rate=0.30,
        ))]
        assessment = assess_overfitting(is_metrics, oos_metrics, folds)
        self.assertEqual("HIGH", assessment.classification)
        self.assertTrue(any("Walk Forward総合" in reason for reason in assessment.reasons))

    def test_cli_writes_json_and_markdown(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            is_path = root / "is-performance-summary.json"
            oos_path = root / "oos-performance-summary.json"
            fold_path = root / "fold1-performance-summary.json"
            is_path.write_text(json.dumps({"metrics": metrics()}), encoding="utf-8")
            oos_path.write_text(json.dumps({"metrics": metrics(profit_factor=0.6, sharpe_ratio=0.2, max_drawdown_rate=0.30)}), encoding="utf-8")
            fold_path.write_text(json.dumps({"metrics": metrics(profit_factor=1.7)}), encoding="utf-8")
            output = root / "report"
            result = main([
                "--in-sample", str(is_path), "--oos", str(oos_path),
                "--walk-forward-fold", f"FOLD1={fold_path}",
                "--output", str(output),
            ])
            self.assertEqual(0, result)
            report = json.loads((output / "overfitting-assessment.json").read_text(encoding="utf-8"))
            self.assertIn(report["classification"], {"LOW", "MODERATE", "HIGH", "INSUFFICIENT_DATA"})
            self.assertTrue((output / "overfitting-report.md").exists())

    def test_cli_rejects_malformed_walk_forward_argument(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            is_path = root / "is-performance-summary.json"
            is_path.write_text(json.dumps({"metrics": metrics()}), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "LABEL=PATH"):
                main([
                    "--in-sample", str(is_path), "--walk-forward-fold", "no-equals-sign",
                    "--output", str(root / "report"),
                ])


if __name__ == "__main__":
    unittest.main()
