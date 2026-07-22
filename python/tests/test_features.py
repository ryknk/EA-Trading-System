import unittest

import numpy as np
import pandas as pd

from decision_api.ml import feature_vector
from python.ml.features.generation import generate_feature_matrix, validate_training_frame
from python.ml.features.labels import first_touch_label
from support import request_dict


def frame_from_request() -> pd.DataFrame:
    request = request_dict(); market = request["market_features"]; proposal = request["trade_proposal"]
    return pd.DataFrame([{
        "timestamp": request["timestamp"], "symbol": request["symbol"],
        "timeframe": request["timeframe"], "direction": request["direction"],
        "current_price": market["current_price"], "spread_points": market["spread_points"],
        "rsi": market["rsi"], "atr": market["atr"],
        "ema_distance_ratio": market["ema_distance_ratio"], "recent_return": market["recent_return"],
        "volatility": market["volatility"], "hour": market["hour"], "day_of_week": market["day_of_week"],
        "entry_price": proposal["entry_price"], "stop_loss": proposal["stop_loss"],
        "take_profit": proposal["take_profit"], "risk_reward_ratio": proposal["risk_reward_ratio"],
        "label_win": 1, "label_return": 0.002,
    }, {
        "timestamp": "2025-06-15T16:06:40Z", "symbol": request["symbol"],
        "timeframe": request["timeframe"], "direction": "SELL",
        "current_price": 145.0, "spread_points": 10.0, "rsi": 42.0, "atr": 0.7,
        "ema_distance_ratio": -0.01, "recent_return": -0.002, "volatility": 0.006,
        "hour": 16, "day_of_week": 0, "entry_price": 145.0, "stop_loss": 145.8,
        "take_profit": 143.4, "risk_reward_ratio": 2.0, "label_win": 0, "label_return": -0.001,
    }])


class FeatureTests(unittest.TestCase):
    def test_training_and_lambda_features_are_identical(self) -> None:
        matrix = generate_feature_matrix(frame_from_request())
        np.testing.assert_allclose(matrix[0], feature_vector(request_dict()), rtol=0, atol=1e-12)

    def test_malformed_training_data_is_rejected(self) -> None:
        for mutate in (
            lambda x: x.drop(columns=["rsi"]),
            lambda x: x.assign(rsi=np.nan),
            lambda x: x.assign(timestamp=[x["timestamp"].iloc[0]] * len(x)),
            lambda x: x.assign(stop_loss=146.0),
        ):
            with self.subTest(mutate=mutate), self.assertRaises(ValueError):
                validate_training_frame(mutate(frame_from_request()))

    def test_first_touch_labels_tp_sl_and_cost(self) -> None:
        tp = first_touch_label("BUY", 100, 99, 102, pd.DataFrame({"high": [101, 102], "low": [99.5, 100]}), 0.001)
        self.assertEqual("TP", tp.outcome)
        self.assertEqual(1, tp.label_win)
        self.assertAlmostEqual(0.019, tp.label_return)
        sl = first_touch_label("SELL", 100, 101, 98, pd.DataFrame({"high": [101], "low": [99]}))
        self.assertEqual("SL", sl.outcome)
        self.assertEqual(0, sl.label_win)

    def test_same_bar_tp_and_sl_is_ambiguous_not_optimistic(self) -> None:
        label = first_touch_label("BUY", 100, 99, 102, pd.DataFrame({"high": [103], "low": [98]}))
        self.assertEqual("AMBIGUOUS", label.outcome)
        self.assertIsNone(label.label_win)

    def test_no_touch_is_censored(self) -> None:
        label = first_touch_label("BUY", 100, 99, 102, pd.DataFrame({"high": [101], "low": [99.5]}))
        self.assertEqual("CENSORED", label.outcome)
        self.assertIsNone(label.label_return)


if __name__ == "__main__":
    unittest.main()
