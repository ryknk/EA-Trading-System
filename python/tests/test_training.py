import unittest
import hashlib
import json
import tempfile
from pathlib import Path

import numpy as np
import pandas as pd

from decision_api.ml import LinearJsonMlProvider
from python.ml.training.train_baseline import (
    chronological_boundaries, evaluate_probability_thresholds, train, write_artifacts,
)


def synthetic_frame(rows: int = 300) -> pd.DataFrame:
    index = np.arange(rows)
    signal = np.sin(index / 9.0)
    direction = np.where(index % 2 == 0, "BUY", "SELL")
    entry = 145.0 + index * 0.001
    return pd.DataFrame({
        "timestamp": pd.date_range("2024-01-01", periods=rows, freq="h", tz="UTC"),
        "symbol": "USDJPY", "timeframe": "H1", "direction": direction,
        "current_price": entry, "spread_points": 10.0 + index % 3,
        "rsi": 50.0 + signal * 20.0, "atr": 0.7 + (index % 5) * 0.01,
        "ema_distance_ratio": signal * 0.01, "recent_return": signal * 0.003,
        "volatility": 0.006 + (index % 7) * 0.0001,
        "hour": index % 24, "day_of_week": (index // 24) % 7,
        "entry_price": entry,
        "stop_loss": np.where(direction == "BUY", entry - 0.8, entry + 0.8),
        "take_profit": np.where(direction == "BUY", entry + 1.6, entry - 1.6),
        "risk_reward_ratio": 2.0,
        "label_win": (signal + np.where(direction == "BUY", 0.15, -0.15) > 0).astype(int),
        "label_return": signal * 0.002,
    })


class TrainingTests(unittest.TestCase):
    def test_threshold_evaluation_uses_declared_grid(self) -> None:
        probability = np.array([0.49, 0.51, 0.61, 0.71])
        label_win = np.array([0, 1, 0, 1])
        label_return = np.array([-0.01, 0.02, -0.03, 0.04])
        rows = evaluate_probability_thresholds(probability, label_win, label_return)
        self.assertEqual([row["threshold"] for row in rows], [0.50, 0.55, 0.60, 0.65, 0.70])
        self.assertEqual(rows[0]["trade_count"], 3)
        self.assertEqual(rows[-1]["trade_count"], 1)

    def test_chronological_split_has_explicit_gaps(self) -> None:
        split = chronological_boundaries(300, 0.2, 0.2, gap=3)
        self.assertEqual(300, split.total)
        self.assertEqual(3, split.calibration_start - split.train_end)
        self.assertEqual(3, split.oos_start - split.calibration_end)

    def test_training_exports_runtime_contract_and_oos_metrics(self) -> None:
        artifact, metadata = train(synthetic_frame(), "baseline-v1", gap=2)
        runtime_model = LinearJsonMlProvider(artifact)
        self.assertEqual("linear_logistic_ridge_v1", artifact["model_type"])
        self.assertEqual("baseline-v1", runtime_model.model_version)
        self.assertEqual(15, len(artifact["feature_names"]))
        self.assertGreaterEqual(metadata["walk_forward"]["folds"], 1)
        self.assertGreaterEqual(metadata["oos_metrics"]["brier_score"], 0.0)
        self.assertLessEqual(metadata["oos_metrics"]["brier_score"], 1.0)

    def test_oos_values_do_not_change_training_scaler(self) -> None:
        frame = synthetic_frame()
        baseline, _ = train(frame, "baseline-v1")
        frame.loc[240:, "recent_return"] = 100.0
        shifted, _ = train(frame, "baseline-v1")
        self.assertAlmostEqual(baseline["mean"][5], shifted["mean"][5], places=15)

    def test_written_model_checksum_matches_exact_bytes(self) -> None:
        artifact, metadata = train(synthetic_frame(), "baseline-v1")
        with tempfile.TemporaryDirectory() as directory:
            checksum = write_artifacts(artifact, metadata, Path(directory))
            raw = (Path(directory) / "model.json").read_bytes()
            stored = json.loads((Path(directory) / "metadata.json").read_text(encoding="utf-8"))
        self.assertEqual(hashlib.sha256(raw).hexdigest(), checksum)
        self.assertEqual(checksum, stored["model_sha256"])


if __name__ == "__main__":
    unittest.main()
