from __future__ import annotations

import hashlib
import hmac
import json
import math
import re
from dataclasses import dataclass
from typing import Any, Protocol

MODEL_TYPE = "linear_logistic_ridge_v1"
MODEL_FIELDS = {
    "schema_version", "feature_schema_version", "model_version", "model_type",
    "symbol", "timeframe", "feature_names", "mean", "scale",
    "win_coefficients", "win_intercept", "calibration_coefficient",
    "calibration_intercept", "return_coefficients", "return_intercept",
}
FEATURE_NAMES = (
    "direction", "rsi", "atr_ratio", "ema_distance_ratio",
    "directional_ema_distance", "recent_return", "volatility",
    "spread_points", "hour_sin", "hour_cos", "day_sin", "day_cos",
    "risk_reward_ratio", "stop_distance_ratio", "take_distance_ratio",
)
MODEL_VERSION_RE = re.compile(r"^[A-Za-z0-9._-]{1,64}$")
MAX_MODEL_BYTES = 65_536


class MlInferenceProvider(Protocol):
    @property
    def model_version(self) -> str: ...
    def predict(self, request: dict[str, Any]) -> "MlPrediction": ...


@dataclass(frozen=True)
class MlPrediction:
    win_probability: float
    expected_return: float
    model_version: str


class UnavailableMlProvider:
    def __init__(self, model_version: str = "not-configured") -> None:
        self._model_version = model_version

    @property
    def model_version(self) -> str:
        return self._model_version

    def predict(self, request: dict[str, Any]) -> MlPrediction:
        raise RuntimeError("ML model is unavailable")


def feature_vector(request: dict[str, Any]) -> list[float]:
    market = request["market_features"]
    proposal = request["trade_proposal"]
    direction = 1.0 if request["direction"] == "BUY" else -1.0
    price = float(market["current_price"])
    hour_angle = 2.0 * math.pi * float(market["hour"]) / 24.0
    day_angle = 2.0 * math.pi * float(market["day_of_week"]) / 7.0
    entry = float(proposal["entry_price"])
    values = [
        direction,
        float(market["rsi"]),
        float(market["atr"]) / price,
        float(market["ema_distance_ratio"]),
        direction * float(market["ema_distance_ratio"]),
        float(market["recent_return"]),
        float(market["volatility"]),
        float(market["spread_points"]),
        math.sin(hour_angle), math.cos(hour_angle),
        math.sin(day_angle), math.cos(day_angle),
        float(proposal["risk_reward_ratio"]),
        abs(entry - float(proposal["stop_loss"])) / entry,
        abs(float(proposal["take_profit"]) - entry) / entry,
    ]
    if not all(math.isfinite(value) for value in values):
        raise ValueError("feature vector contains a non-finite value")
    return values


def _strict_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate model field: {key}")
        result[key] = value
    return result


def _finite_number(value: Any, name: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError(f"{name} must be numeric")
    result = float(value)
    if not math.isfinite(result):
        raise ValueError(f"{name} must be finite")
    return result


def _vector(value: Any, name: str, positive: bool = False) -> tuple[float, ...]:
    if not isinstance(value, list) or len(value) != len(FEATURE_NAMES):
        raise ValueError(f"{name} has an invalid length")
    result = tuple(_finite_number(item, name) for item in value)
    if positive and any(item <= 0 for item in result):
        raise ValueError(f"{name} values must be positive")
    return result


def _sigmoid(value: float) -> float:
    if value >= 0:
        return 1.0 / (1.0 + math.exp(-value))
    exp_value = math.exp(value)
    return exp_value / (1.0 + exp_value)


class LinearJsonMlProvider:
    def __init__(self, artifact: dict[str, Any]) -> None:
        if set(artifact) != MODEL_FIELDS:
            raise ValueError("model fields do not match the contract")
        if artifact["schema_version"] != "1.0" or artifact["feature_schema_version"] != "1.0":
            raise ValueError("unsupported model schema")
        if artifact["model_type"] != MODEL_TYPE:
            raise ValueError("unsupported model type")
        if tuple(artifact["feature_names"]) != FEATURE_NAMES:
            raise ValueError("feature order does not match the runtime")
        if not MODEL_VERSION_RE.fullmatch(str(artifact["model_version"])):
            raise ValueError("model version is invalid")
        if not isinstance(artifact["symbol"], str) or not isinstance(artifact["timeframe"], str):
            raise ValueError("model scope is invalid")
        self._model_version = artifact["model_version"]
        self._symbol = artifact["symbol"]
        self._timeframe = artifact["timeframe"]
        self._mean = _vector(artifact["mean"], "mean")
        self._scale = _vector(artifact["scale"], "scale", positive=True)
        self._win_coefficients = _vector(artifact["win_coefficients"], "win_coefficients")
        self._return_coefficients = _vector(artifact["return_coefficients"], "return_coefficients")
        self._win_intercept = _finite_number(artifact["win_intercept"], "win_intercept")
        self._calibration_coefficient = _finite_number(artifact["calibration_coefficient"], "calibration_coefficient")
        self._calibration_intercept = _finite_number(artifact["calibration_intercept"], "calibration_intercept")
        self._return_intercept = _finite_number(artifact["return_intercept"], "return_intercept")

    @classmethod
    def from_bytes(cls, raw: bytes) -> "LinearJsonMlProvider":
        if not raw or len(raw) > MAX_MODEL_BYTES:
            raise ValueError("model artifact is empty or too large")
        try:
            artifact = json.loads(
                raw.decode("utf-8", errors="strict"), object_pairs_hook=_strict_object,
                parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)),
            )
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise ValueError("model artifact is invalid JSON") from exc
        if not isinstance(artifact, dict):
            raise ValueError("model artifact must be an object")
        return cls(artifact)

    @property
    def model_version(self) -> str:
        return self._model_version

    def predict(self, request: dict[str, Any]) -> MlPrediction:
        if request["symbol"] != self._symbol or request["timeframe"] != self._timeframe:
            raise ValueError("request is outside the model scope")
        raw = feature_vector(request)
        standardized = [(value - mean) / scale for value, mean, scale in zip(raw, self._mean, self._scale)]
        win_logit = self._win_intercept + sum(c * x for c, x in zip(self._win_coefficients, standardized))
        calibrated_probability = _sigmoid(
            self._calibration_intercept + self._calibration_coefficient * win_logit
        )
        expected_return = self._return_intercept + sum(
            c * x for c, x in zip(self._return_coefficients, standardized)
        )
        if not math.isfinite(calibrated_probability) or not math.isfinite(expected_return):
            raise ValueError("model output is non-finite")
        return MlPrediction(calibrated_probability, expected_return, self._model_version)


class S3MlProvider:
    def __init__(self, client: Any, bucket: str, key: str, expected_sha256: str) -> None:
        self._client = client
        self._bucket = bucket
        self._key = key
        self._expected_sha256 = expected_sha256.lower()
        self._provider: LinearJsonMlProvider | None = None

    @property
    def model_version(self) -> str:
        return self._provider.model_version if self._provider else "not-loaded"

    def _load(self) -> LinearJsonMlProvider:
        if self._provider is not None:
            return self._provider
        if not re.fullmatch(r"[0-9a-f]{64}", self._expected_sha256):
            raise ValueError("ML_MODEL_SHA256 is not configured")
        response = self._client.get_object(Bucket=self._bucket, Key=self._key)
        raw = response["Body"].read(MAX_MODEL_BYTES + 1)
        actual = hashlib.sha256(raw).hexdigest()
        if not hmac.compare_digest(actual, self._expected_sha256):
            raise ValueError("model checksum does not match")
        self._provider = LinearJsonMlProvider.from_bytes(raw)
        return self._provider

    def predict(self, request: dict[str, Any]) -> MlPrediction:
        return self._load().predict(request)

