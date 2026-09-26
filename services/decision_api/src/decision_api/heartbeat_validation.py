from __future__ import annotations

import json
import re
from typing import Any

from .errors import ApiError
from .event_validation import _reject_duplicates, _utc, _uuid4

MAX_HEARTBEAT_BYTES = 2_048
MIN_INTERVAL_SECONDS = 30
MAX_INTERVAL_SECONDS = 900
ROOT_FIELDS = {
    "schema_version", "heartbeat_id", "ea_id", "timestamp", "symbol", "interval_seconds",
    "terminal_connected", "trade_mutations_enabled", "kill_switch_active",
}
EA_ID_RE = re.compile(r"^[A-Za-z0-9._-]{1,64}$")
SYMBOL_RE = re.compile(r"^[A-Za-z0-9._-]{1,32}$")


def parse_and_validate_heartbeat(raw_body: bytes) -> dict[str, Any]:
    """EA稼働監視用Heartbeatを検証する。状態項目は監視情報であり取引判断には使用しない。"""
    if not raw_body or len(raw_body) > MAX_HEARTBEAT_BYTES:
        raise ApiError(400, "INVALID_HEARTBEAT", "heartbeat body is empty or too large")
    try:
        heartbeat = json.loads(
            raw_body.decode("utf-8", errors="strict"), object_pairs_hook=_reject_duplicates,
            parse_constant=lambda token: (_ for _ in ()).throw(ValueError(token)),
        )
    except (UnicodeDecodeError, json.JSONDecodeError, ValueError) as exc:
        raise ApiError(400, "INVALID_HEARTBEAT_JSON", "heartbeat must be strict UTF-8 JSON") from exc
    if not isinstance(heartbeat, dict) or set(heartbeat) != ROOT_FIELDS:
        raise ApiError(400, "INVALID_HEARTBEAT", "heartbeat fields do not match the contract")
    if heartbeat["schema_version"] != "1.0":
        raise ApiError(400, "UNSUPPORTED_HEARTBEAT_SCHEMA", "schema_version must be 1.0")
    try:
        _uuid4(heartbeat["heartbeat_id"], "heartbeat_id")
        _utc(heartbeat["timestamp"], "timestamp")
    except ApiError as exc:
        raise ApiError(400, "INVALID_HEARTBEAT", exc.message) from exc
    if not isinstance(heartbeat["ea_id"], str) or not EA_ID_RE.fullmatch(heartbeat["ea_id"]):
        raise ApiError(400, "INVALID_HEARTBEAT", "ea_id is invalid")
    if not isinstance(heartbeat["symbol"], str) or not SYMBOL_RE.fullmatch(heartbeat["symbol"]):
        raise ApiError(400, "INVALID_HEARTBEAT", "symbol is invalid")
    interval = heartbeat["interval_seconds"]
    if (isinstance(interval, bool) or not isinstance(interval, int)
            or not MIN_INTERVAL_SECONDS <= interval <= MAX_INTERVAL_SECONDS):
        raise ApiError(400, "INVALID_HEARTBEAT", "interval_seconds is invalid")
    for field in ("terminal_connected", "trade_mutations_enabled", "kill_switch_active"):
        if not isinstance(heartbeat[field], bool):
            raise ApiError(400, "INVALID_HEARTBEAT", f"{field} must be boolean")
    return heartbeat
