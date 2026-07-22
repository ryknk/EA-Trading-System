from __future__ import annotations

import math

import numpy as np
import pandas as pd

FEATURE_NAMES = (
    "direction", "rsi", "atr_ratio", "ema_distance_ratio",
    "directional_ema_distance", "recent_return", "volatility",
    "spread_points", "hour_sin", "hour_cos", "day_sin", "day_cos",
    "risk_reward_ratio", "stop_distance_ratio", "take_distance_ratio",
)
REQUIRED_COLUMNS = {
    "timestamp", "symbol", "timeframe", "direction", "current_price",
    "spread_points", "rsi", "atr", "ema_distance_ratio", "recent_return",
    "volatility", "hour", "day_of_week", "entry_price", "stop_loss",
    "take_profit", "risk_reward_ratio", "label_win", "label_return",
}


def validate_training_frame(frame: pd.DataFrame) -> pd.DataFrame:
    missing = REQUIRED_COLUMNS - set(frame.columns)
    if missing:
        raise ValueError(f"required training columns are missing: {sorted(missing)}")
    result = frame.copy()
    result["timestamp"] = pd.to_datetime(result["timestamp"], utc=True, errors="raise")
    result = result.sort_values("timestamp", kind="stable").reset_index(drop=True)
    if result["timestamp"].duplicated().any():
        raise ValueError("timestamps must be unique for a single model scope")
    if result["symbol"].nunique() != 1 or result["timeframe"].nunique() != 1:
        raise ValueError("one artifact must contain exactly one symbol and timeframe")
    if not result["direction"].isin(["BUY", "SELL"]).all():
        raise ValueError("direction must be BUY or SELL")
    if not result["label_win"].isin([0, 1]).all() or result["label_win"].nunique() != 2:
        raise ValueError("label_win must contain both binary classes")
    numeric = REQUIRED_COLUMNS - {"timestamp", "symbol", "timeframe", "direction"}
    values = result[list(numeric)].apply(pd.to_numeric, errors="raise").to_numpy(dtype=float)
    if not np.isfinite(values).all():
        raise ValueError("training data contains NaN or Infinity")
    if not result["hour"].between(0, 23).all() or not result["day_of_week"].between(0, 6).all():
        raise ValueError("calendar feature is outside its range")
    if not result["rsi"].between(0, 100).all():
        raise ValueError("rsi is outside its range")
    if (result[["spread_points", "volatility"]] < 0).any().any():
        raise ValueError("non-negative features must not be negative")
    if (result[["current_price", "atr", "entry_price", "stop_loss", "take_profit", "risk_reward_ratio"]] <= 0).any().any():
        raise ValueError("positive price features must be greater than zero")
    buy_valid = (result["direction"] != "BUY") | ((result["stop_loss"] < result["entry_price"]) & (result["entry_price"] < result["take_profit"]))
    sell_valid = (result["direction"] != "SELL") | ((result["take_profit"] < result["entry_price"]) & (result["entry_price"] < result["stop_loss"]))
    if not (buy_valid & sell_valid).all():
        raise ValueError("trade price geometry is invalid")
    return result


def generate_feature_matrix(frame: pd.DataFrame) -> np.ndarray:
    data = validate_training_frame(frame)
    direction = np.where(data["direction"].to_numpy() == "BUY", 1.0, -1.0)
    price = data["current_price"].to_numpy(dtype=float)
    entry = data["entry_price"].to_numpy(dtype=float)
    hour_angle = 2.0 * math.pi * data["hour"].to_numpy(dtype=float) / 24.0
    day_angle = 2.0 * math.pi * data["day_of_week"].to_numpy(dtype=float) / 7.0
    ema_distance = data["ema_distance_ratio"].to_numpy(dtype=float)
    matrix = np.column_stack([
        direction,
        data["rsi"].to_numpy(dtype=float),
        data["atr"].to_numpy(dtype=float) / price,
        ema_distance,
        direction * ema_distance,
        data["recent_return"].to_numpy(dtype=float),
        data["volatility"].to_numpy(dtype=float),
        data["spread_points"].to_numpy(dtype=float),
        np.sin(hour_angle), np.cos(hour_angle),
        np.sin(day_angle), np.cos(day_angle),
        data["risk_reward_ratio"].to_numpy(dtype=float),
        np.abs(entry - data["stop_loss"].to_numpy(dtype=float)) / entry,
        np.abs(data["take_profit"].to_numpy(dtype=float) - entry) / entry,
    ])
    if matrix.shape[1] != len(FEATURE_NAMES) or not np.isfinite(matrix).all():
        raise ValueError("generated feature matrix is invalid")
    return matrix
