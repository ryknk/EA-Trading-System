from __future__ import annotations

import json
import math
import re
import uuid
from datetime import datetime
from typing import Any

from .errors import ApiError

MAX_BODY_BYTES = 16_384
IDENTIFIER_RE = re.compile(r"^[A-Za-z0-9._-]{1,64}$")
SYMBOL_RE = re.compile(r"^[A-Z0-9._-]{1,32}$")
TIMEFRAMES = {"M15", "M30", "H1", "H4", "D1"}
DIRECTIONS = {"BUY", "SELL"}

ROOT_FIELDS = {
    "schema_version", "request_id", "trade_candidate_id", "ea_id", "timestamp", "symbol",
    "timeframe", "direction", "strategy", "market_features", "trade_proposal",
}
STRATEGY_FIELDS = {"pattern", "reason_code", "reason"}
FEATURE_FIELDS = {
    "feature_schema_version", "observed_at", "current_price", "spread_points",
    "rsi", "atr", "ema50", "ema200", "ema_distance_ratio", "recent_return",
    "volatility", "hour", "day_of_week",
}
PROPOSAL_FIELDS = {"entry_price", "stop_loss", "take_profit", "risk_reward_ratio"}


def _reject_duplicates(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate field: {key}")
        result[key] = value
    return result


def _reject_constant(value: str) -> None:
    raise ValueError(f"non-finite number: {value}")


def _exact_fields(value: Any, expected: set[str], path: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ApiError(400, "INVALID_REQUEST", f"{path} must be an object")
    missing = expected - value.keys()
    extra = value.keys() - expected
    if missing or extra:
        raise ApiError(400, "INVALID_REQUEST", f"{path} fields do not match the contract")
    return value


def _string(value: Any, path: str) -> str:
    if not isinstance(value, str):
        raise ApiError(400, "INVALID_REQUEST", f"{path} must be a string")
    return value


def _number(value: Any, path: str, minimum: float | None = None,
            maximum: float | None = None, exclusive_minimum: bool = False) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ApiError(400, "INVALID_REQUEST", f"{path} must be a number")
    number = float(value)
    if not math.isfinite(number):
        raise ApiError(400, "INVALID_REQUEST", f"{path} must be finite")
    if minimum is not None and (number <= minimum if exclusive_minimum else number < minimum):
        raise ApiError(400, "INVALID_REQUEST", f"{path} is below its minimum")
    if maximum is not None and number > maximum:
        raise ApiError(400, "INVALID_REQUEST", f"{path} exceeds its maximum")
    return number


def _integer(value: Any, path: str, minimum: int, maximum: int) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or not minimum <= value <= maximum:
        raise ApiError(400, "INVALID_REQUEST", f"{path} must be an integer in range")
    return value


def _date_time(value: Any, path: str) -> datetime:
    text = _string(value, path)
    if not text.endswith("Z"):
        raise ApiError(400, "INVALID_REQUEST", f"{path} must be UTC with Z suffix")
    try:
        parsed = datetime.fromisoformat(text.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ApiError(400, "INVALID_REQUEST", f"{path} is not ISO-8601") from exc
    return parsed


def _canonical_uuid(value: Any, path: str) -> str:
    text = _string(value, path)
    try:
        parsed = uuid.UUID(text)
    except ValueError as exc:
        raise ApiError(400, "INVALID_REQUEST", f"{path} is not a UUID") from exc
    if str(parsed) != text.lower() or parsed.version != 4:
        raise ApiError(400, "INVALID_REQUEST", f"{path} must be a canonical UUIDv4")
    return text


def parse_and_validate_request(raw_body: bytes) -> dict[str, Any]:
    if not raw_body or len(raw_body) > MAX_BODY_BYTES:
        raise ApiError(400, "INVALID_REQUEST", "body is empty or too large")
    try:
        text = raw_body.decode("utf-8", errors="strict")
        value = json.loads(text, object_pairs_hook=_reject_duplicates, parse_constant=_reject_constant)
    except (UnicodeDecodeError, json.JSONDecodeError, ValueError) as exc:
        raise ApiError(400, "INVALID_JSON", "body must be strict UTF-8 JSON") from exc

    root = _exact_fields(value, ROOT_FIELDS, "request")
    if root["schema_version"] != "1.0":
        raise ApiError(400, "UNSUPPORTED_SCHEMA", "schema_version must be 1.0")
    _canonical_uuid(root["request_id"], "request_id")
    candidate_id = _string(root["trade_candidate_id"], "trade_candidate_id")
    if not re.fullmatch(r"[A-Za-z0-9._:-]{1,128}", candidate_id):
        raise ApiError(400, "INVALID_REQUEST", "trade_candidate_id is invalid")
    if not IDENTIFIER_RE.fullmatch(_string(root["ea_id"], "ea_id")):
        raise ApiError(400, "INVALID_REQUEST", "ea_id is invalid")
    _date_time(root["timestamp"], "timestamp")
    if not SYMBOL_RE.fullmatch(_string(root["symbol"], "symbol")):
        raise ApiError(400, "INVALID_REQUEST", "symbol is invalid")
    if root["timeframe"] not in TIMEFRAMES or root["direction"] not in DIRECTIONS:
        raise ApiError(400, "INVALID_REQUEST", "timeframe or direction is invalid")

    strategy = _exact_fields(root["strategy"], STRATEGY_FIELDS, "strategy")
    if strategy["pattern"] not in {"BREAKOUT", "PULLBACK"}:
        raise ApiError(400, "INVALID_REQUEST", "strategy.pattern is invalid")
    if not re.fullmatch(r"[A-Z0-9_]{1,64}", _string(strategy["reason_code"], "strategy.reason_code")):
        raise ApiError(400, "INVALID_REQUEST", "strategy.reason_code is invalid")
    reason = _string(strategy["reason"], "strategy.reason")
    if not 1 <= len(reason) <= 512 or any(ord(character) < 32 for character in reason):
        raise ApiError(400, "INVALID_REQUEST", "strategy.reason is invalid")

    features = _exact_fields(root["market_features"], FEATURE_FIELDS, "market_features")
    if features["feature_schema_version"] != "1.0":
        raise ApiError(400, "UNSUPPORTED_FEATURE_SCHEMA", "feature_schema_version must be 1.0")
    _date_time(features["observed_at"], "market_features.observed_at")
    for name in ("current_price", "atr", "ema50", "ema200"):
        _number(features[name], f"market_features.{name}", 0, exclusive_minimum=True)
    _number(features["spread_points"], "market_features.spread_points", 0)
    _number(features["rsi"], "market_features.rsi", 0, 100)
    _number(features["ema_distance_ratio"], "market_features.ema_distance_ratio")
    _number(features["recent_return"], "market_features.recent_return")
    _number(features["volatility"], "market_features.volatility", 0)
    _integer(features["hour"], "market_features.hour", 0, 23)
    _integer(features["day_of_week"], "market_features.day_of_week", 0, 6)

    proposal = _exact_fields(root["trade_proposal"], PROPOSAL_FIELDS, "trade_proposal")
    for name in PROPOSAL_FIELDS:
        _number(proposal[name], f"trade_proposal.{name}", 0, exclusive_minimum=True)
    entry, stop, take = proposal["entry_price"], proposal["stop_loss"], proposal["take_profit"]
    geometry_valid = stop < entry < take if root["direction"] == "BUY" else take < entry < stop
    if not geometry_valid:
        raise ApiError(400, "INVALID_TRADE_GEOMETRY", "SL/entry/TP ordering is invalid")
    return root
