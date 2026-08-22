from __future__ import annotations

import json
import math
import re
import uuid
from datetime import datetime
from typing import Any

from .errors import ApiError

MAX_EVENT_BYTES = 16_384
ROOT_FIELDS = {
    "schema_version", "event_id", "trade_candidate_id", "request_id", "ea_id",
    "timestamp", "event_type", "symbol", "payload",
}
PAYLOAD_FIELDS = {
    "CANDIDATE": {
        "direction", "pattern", "entry_price", "stop_loss", "take_profit",
        "risk_reward_ratio", "reason_code", "reason",
    },
    "EXTERNAL_DECISION": {
        "decision", "reason_code", "ml_status", "ml_win_probability",
        "ml_expected_return", "ml_model_version", "llm_status", "llm_provider",
        "llm_model", "llm_prompt_version", "llm_confidence", "llm_reason",
    },
    "RISK_DECISION": {
        "status", "reason_code", "reason", "volume", "risk_budget",
        "estimated_stop_loss", "required_margin", "daily_loss_rate", "drawdown_rate",
    },
    "ORDER_SUBMISSION": {
        "status", "reason_code", "reason", "order_ticket", "deal_ticket", "broker_retcode",
        "requested_price", "confirmed_price", "requested_volume", "confirmed_volume", "slippage_points",
    },
    "DEAL": {"deal_ticket", "order_ticket", "position_ticket", "entry", "price", "volume", "pnl"},
    "POSITION_SNAPSHOT": {
        "position_ticket", "direction", "volume", "open_price", "current_price",
        "stop_loss", "take_profit", "unrealized_pnl",
    },
    "TRADE_CLOSED": {
        "position_ticket", "direction", "open_time", "close_time", "volume",
        "open_price", "close_price", "close_reason", "pnl", "commission", "swap",
    },
    "ACCOUNT_SNAPSHOT": {"balance", "equity", "margin", "free_margin", "margin_level", "open_positions"},
    "SYSTEM_ERROR": {"component", "reason_code", "reason"},
}
SAFE_TEXT_FIELDS = {
    "status", "reason_code", "entry", "direction", "component", "pattern", "decision",
    "ml_status", "ml_model_version", "llm_status", "llm_provider", "llm_model", "llm_prompt_version",
    "close_reason",
}
TICKET_FIELDS = {"order_ticket", "deal_ticket", "position_ticket"}
TIME_FIELDS = {"open_time", "close_time"}


def _reject_duplicates(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate field: {key}")
        result[key] = value
    return result


def _uuid4(value: Any, field: str) -> str:
    if not isinstance(value, str):
        raise ApiError(400, "INVALID_EVENT", f"{field} must be a string")
    try:
        parsed = uuid.UUID(value)
    except ValueError as exc:
        raise ApiError(400, "INVALID_EVENT", f"{field} must be UUIDv4") from exc
    if parsed.version != 4 or str(parsed) != value.lower():
        raise ApiError(400, "INVALID_EVENT", f"{field} must be canonical UUIDv4")
    return value


def _utc(value: Any, field: str) -> datetime:
    if not isinstance(value, str) or not value.endswith("Z"):
        raise ApiError(400, "INVALID_EVENT", f"{field} must be UTC ISO-8601")
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise ApiError(400, "INVALID_EVENT", f"{field} must be UTC ISO-8601") from exc


def _safe_string(value: Any, field: str, maximum: int = 64) -> str:
    if (not isinstance(value, str) or not 1 <= len(value) <= maximum
            or any(ord(character) < 32 for character in value)):
        raise ApiError(400, "INVALID_EVENT", f"{field} is invalid")
    return value


def _finite_number(value: Any, field: str) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(float(value)):
        raise ApiError(400, "INVALID_EVENT", f"{field} must be finite")
    return float(value)


def parse_and_validate_event(raw_body: bytes) -> dict[str, Any]:
    if not raw_body or len(raw_body) > MAX_EVENT_BYTES:
        raise ApiError(400, "INVALID_EVENT", "event body is empty or too large")
    try:
        event = json.loads(
            raw_body.decode("utf-8", errors="strict"), object_pairs_hook=_reject_duplicates,
            parse_constant=lambda token: (_ for _ in ()).throw(ValueError(token)),
        )
    except (UnicodeDecodeError, json.JSONDecodeError, ValueError) as exc:
        raise ApiError(400, "INVALID_EVENT_JSON", "event must be strict UTF-8 JSON") from exc
    if not isinstance(event, dict) or set(event) != ROOT_FIELDS:
        raise ApiError(400, "INVALID_EVENT", "event fields do not match the contract")
    if event["schema_version"] != "1.0":
        raise ApiError(400, "UNSUPPORTED_EVENT_SCHEMA", "schema_version must be 1.0")
    _uuid4(event["event_id"], "event_id")
    candidate_id = _safe_string(event["trade_candidate_id"], "trade_candidate_id", 128)
    if not re.fullmatch(r"[A-Za-z0-9._:-]+", candidate_id):
        raise ApiError(400, "INVALID_EVENT", "trade_candidate_id is invalid")
    request_id = event["request_id"]
    if request_id != "":
        _uuid4(request_id, "request_id")
    if not re.fullmatch(r"[A-Za-z0-9._-]{1,64}", _safe_string(event["ea_id"], "ea_id")):
        raise ApiError(400, "INVALID_EVENT", "ea_id is invalid")
    _utc(event["timestamp"], "timestamp")
    if not re.fullmatch(r"[A-Z0-9._-]{1,32}", _safe_string(event["symbol"], "symbol", 32)):
        raise ApiError(400, "INVALID_EVENT", "symbol is invalid")
    event_type = event["event_type"]
    if event_type not in PAYLOAD_FIELDS:
        raise ApiError(400, "INVALID_EVENT_TYPE", "event_type is invalid")
    payload = event["payload"]
    if not isinstance(payload, dict) or set(payload) != PAYLOAD_FIELDS[event_type]:
        raise ApiError(400, "INVALID_EVENT_PAYLOAD", "payload fields do not match event_type")

    for field, value in payload.items():
        if field in {"reason", "llm_reason"}:
            _safe_string(value, f"payload.{field}", 512)
        elif field in SAFE_TEXT_FIELDS:
            text = _safe_string(value, f"payload.{field}", 64)
            if not re.fullmatch(r"[A-Za-z0-9._:-]+", text):
                raise ApiError(400, "INVALID_EVENT_PAYLOAD", f"payload.{field} is invalid")
        elif field in TICKET_FIELDS:
            if not isinstance(value, str) or not re.fullmatch(r"[0-9]{1,20}", value):
                raise ApiError(400, "INVALID_EVENT_PAYLOAD", f"payload.{field} is invalid")
        elif field in TIME_FIELDS:
            _utc(value, f"payload.{field}")
        elif field == "open_positions":
            if isinstance(value, bool) or not isinstance(value, int) or not 0 <= value <= 1_000:
                raise ApiError(400, "INVALID_EVENT_PAYLOAD", "payload.open_positions is invalid")
        else:
            _finite_number(value, f"payload.{field}")
    return event
