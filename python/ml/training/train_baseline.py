from __future__ import annotations

import argparse
import hashlib
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path

import numpy as np
import pandas as pd
import sklearn
from sklearn.linear_model import LogisticRegression, Ridge
from sklearn.metrics import (
    brier_score_loss, f1_score, log_loss, mean_absolute_error,
    precision_score, recall_score, roc_auc_score,
)
from sklearn.model_selection import TimeSeriesSplit
from sklearn.preprocessing import StandardScaler

from python.ml.features.generation import FEATURE_NAMES, generate_feature_matrix, validate_training_frame


@dataclass(frozen=True)
class SplitBoundaries:
    train_end: int
    calibration_start: int
    calibration_end: int
    oos_start: int
    total: int


def chronological_boundaries(total: int, oos_fraction: float, calibration_fraction: float,
                             gap: int, minimum_train: int = 50) -> SplitBoundaries:
    if total < 100 or not 0.10 <= oos_fraction <= 0.40 or not 0.10 <= calibration_fraction <= 0.40:
        raise ValueError("dataset or split fraction is invalid")
    oos_start = int(total * (1.0 - oos_fraction))
    calibration_size = max(20, int(oos_start * calibration_fraction))
    calibration_start = oos_start - gap - calibration_size
    train_end = calibration_start - gap
    if train_end < minimum_train or calibration_start >= oos_start or gap < 0:
        raise ValueError("not enough observations after applying split gaps")
    return SplitBoundaries(train_end, calibration_start, oos_start - gap, oos_start, total)


def _fit_models(x_train: np.ndarray, y_win: np.ndarray, y_return: np.ndarray):
    scaler = StandardScaler().fit(x_train)
    standardized = scaler.transform(x_train)
    classifier = LogisticRegression(C=1.0, max_iter=2_000, solver="lbfgs", random_state=42).fit(standardized, y_win)
    return_model = Ridge(alpha=1.0).fit(standardized, y_return)
    return scaler, classifier, return_model


def _walk_forward(x: np.ndarray, y: np.ndarray, gap: int) -> dict[str, float]:
    split = TimeSeriesSplit(n_splits=5, gap=gap)
    scores: list[float] = []
    for train_index, test_index in split.split(x):
        if np.unique(y[train_index]).size != 2:
            continue
        scaler = StandardScaler().fit(x[train_index])
        model = LogisticRegression(C=1.0, max_iter=2_000, solver="lbfgs", random_state=42).fit(
            scaler.transform(x[train_index]), y[train_index]
        )
        probability = model.predict_proba(scaler.transform(x[test_index]))[:, 1]
        scores.append(float(brier_score_loss(y[test_index], probability)))
    if not scores:
        raise ValueError("walk-forward folds do not contain both classes")
    return {"folds": len(scores), "mean_brier": float(np.mean(scores)), "std_brier": float(np.std(scores))}


def evaluate_probability_thresholds(probability: np.ndarray, label_win: np.ndarray,
                                    label_return: np.ndarray,
                                    thresholds: tuple[float, ...] = (0.50, 0.55, 0.60, 0.65, 0.70)) -> list[dict]:
    """事前宣言した閾値を比較する。結果をOOSパラメータ調整には使用しない。"""
    if probability.ndim != 1 or probability.shape != label_win.shape or probability.shape != label_return.shape:
        raise ValueError("threshold arrays must be aligned one-dimensional arrays")
    rows: list[dict] = []
    for threshold in thresholds:
        selected = probability >= threshold
        returns = label_return[selected]
        wins = returns[returns > 0]
        losses = returns[returns < 0]
        cumulative = np.cumsum(returns) if returns.size else np.array([], dtype=float)
        equity = np.concatenate(([0.0], cumulative))
        peaks = np.maximum.accumulate(equity)
        rows.append({
            "threshold": threshold,
            "trade_count": int(selected.sum()),
            "net_return_sum": float(returns.sum()),
            "profit_factor": None if losses.size == 0 else float(wins.sum() / abs(losses.sum())),
            "max_drawdown_return": float(np.max(peaks - equity)),
            "expectancy_return": 0.0 if returns.size == 0 else float(returns.mean()),
        })
    return rows


def train(frame: pd.DataFrame, model_version: str, oos_fraction: float = 0.20,
          calibration_fraction: float = 0.20, gap: int = 1,
          min_win_probability: float = 0.60) -> tuple[dict, dict]:
    if not re.fullmatch(r"[A-Za-z0-9._-]{1,64}", model_version):
        raise ValueError("model_version is invalid")
    data = validate_training_frame(frame)
    x = generate_feature_matrix(data)
    y_win = data["label_win"].to_numpy(dtype=int)
    y_return = data["label_return"].to_numpy(dtype=float)
    boundaries = chronological_boundaries(len(data), oos_fraction, calibration_fraction, gap)

    train_slice = slice(0, boundaries.train_end)
    calibration_slice = slice(boundaries.calibration_start, boundaries.calibration_end)
    oos_slice = slice(boundaries.oos_start, boundaries.total)
    if np.unique(y_win[train_slice]).size != 2 or np.unique(y_win[calibration_slice]).size != 2:
        raise ValueError("training and calibration windows must contain both classes")

    scaler, classifier, return_model = _fit_models(x[train_slice], y_win[train_slice], y_return[train_slice])
    calibration_logits = classifier.decision_function(scaler.transform(x[calibration_slice])).reshape(-1, 1)
    calibrator = LogisticRegression(C=1_000.0, max_iter=2_000, solver="lbfgs", random_state=42).fit(
        calibration_logits, y_win[calibration_slice]
    )

    oos_standardized = scaler.transform(x[oos_slice])
    oos_logits = classifier.decision_function(oos_standardized).reshape(-1, 1)
    probability = calibrator.predict_proba(oos_logits)[:, 1]
    expected_return = return_model.predict(oos_standardized)
    selected = probability >= min_win_probability
    metrics = {
        "brier_score": float(brier_score_loss(y_win[oos_slice], probability)),
        "roc_auc": float(roc_auc_score(y_win[oos_slice], probability)),
        "log_loss": float(log_loss(y_win[oos_slice], probability, labels=[0, 1])),
        "precision": float(precision_score(y_win[oos_slice], probability >= 0.5, zero_division=0)),
        "recall": float(recall_score(y_win[oos_slice], probability >= 0.5, zero_division=0)),
        "f1": float(f1_score(y_win[oos_slice], probability >= 0.5, zero_division=0)),
        "precision_at_threshold": float(precision_score(y_win[oos_slice][selected], np.ones(selected.sum()), zero_division=0)) if selected.any() else 0.0,
        "selection_rate": float(selected.mean()),
        "return_mae": float(mean_absolute_error(y_return[oos_slice], expected_return)),
    }
    artifact = {
        "schema_version": "1.0",
        "feature_schema_version": "1.0",
        "model_version": model_version,
        "model_type": "linear_logistic_ridge_v1",
        "symbol": str(data["symbol"].iloc[0]),
        "timeframe": str(data["timeframe"].iloc[0]),
        "feature_names": list(FEATURE_NAMES),
        "mean": scaler.mean_.tolist(),
        "scale": scaler.scale_.tolist(),
        "win_coefficients": classifier.coef_[0].tolist(),
        "win_intercept": float(classifier.intercept_[0]),
        "calibration_coefficient": float(calibrator.coef_[0, 0]),
        "calibration_intercept": float(calibrator.intercept_[0]),
        "return_coefficients": return_model.coef_.tolist(),
        "return_intercept": float(return_model.intercept_),
    }
    metadata = {
        "model_version": model_version,
        "feature_schema_version": "1.0",
        "sklearn_version": sklearn.__version__,
        "row_count": len(data),
        "training_start": data["timestamp"].iloc[0].isoformat(),
        "training_end": data["timestamp"].iloc[boundaries.train_end - 1].isoformat(),
        "calibration_start": data["timestamp"].iloc[boundaries.calibration_start].isoformat(),
        "oos_start": data["timestamp"].iloc[boundaries.oos_start].isoformat(),
        "split": asdict(boundaries),
        "oos_metrics": metrics,
        "walk_forward": _walk_forward(x[:boundaries.oos_start], y_win[:boundaries.oos_start], gap),
        "thresholds": {"min_win_probability": min_win_probability},
        "threshold_analysis": evaluate_probability_thresholds(
            probability, y_win[oos_slice], y_return[oos_slice]
        ),
    }
    return artifact, metadata


def write_artifacts(artifact: dict, metadata: dict, output_directory: Path) -> str:
    output_directory.mkdir(parents=True, exist_ok=True)
    model_bytes = json.dumps(artifact, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode("utf-8")
    checksum = hashlib.sha256(model_bytes).hexdigest()
    (output_directory / "model.json").write_bytes(model_bytes)
    metadata = dict(metadata, model_sha256=checksum)
    (output_directory / "metadata.json").write_text(
        json.dumps(metadata, indent=2, sort_keys=True, ensure_ascii=False), encoding="utf-8"
    )
    return checksum


def main() -> None:
    parser = argparse.ArgumentParser(description="時系列分割で基準MLモデルを学習する")
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--model-version", required=True)
    parser.add_argument("--gap", type=int, default=1)
    args = parser.parse_args()
    frame = pd.read_csv(args.input)
    artifact, metadata = train(frame, args.model_version, gap=args.gap)
    checksum = write_artifacts(artifact, metadata, args.output)
    print(json.dumps({"model_version": args.model_version, "sha256": checksum,
                      "oos_metrics": metadata["oos_metrics"]}, ensure_ascii=False))


if __name__ == "__main__":
    main()
