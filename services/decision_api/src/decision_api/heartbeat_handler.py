from __future__ import annotations

import base64
import hashlib
import json
import logging
import os
import time
from datetime import datetime, timezone
from typing import Any

from .auth import verify_request
from .errors import ApiError
from .handler import SsmSecretProvider, _shared_secret_cache
from .heartbeat_validation import parse_and_validate_heartbeat
from .monitoring import emit_emf
from .repository import DynamoRepository

LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(os.environ.get("LOG_LEVEL", "INFO").upper())
_repository: DynamoRepository | None = None


def _dependencies() -> tuple[DynamoRepository, SsmSecretProvider]:
    global _repository
    import boto3
    if _repository is None:
        _repository = DynamoRepository(boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"]))
    return _repository, SsmSecretProvider(boto3.client("ssm"), os.environ["ENVIRONMENT"], _shared_secret_cache())


def _monitored_ea_ids() -> set[str]:
    """EaId dimensionを付けるEAを、CDKで明示した集合に限定しメトリクスの高カーディナリティ化を防ぐ。"""
    return {value.strip() for value in os.environ.get("HEARTBEAT_MONITORED_EA_IDS", "").split(",") if value.strip()}


def _response(status: int, body: dict[str, Any]) -> dict[str, Any]:
    return {
        "statusCode": status,
        "headers": {"content-type": "application/json", "cache-control": "no-store"},
        "body": json.dumps(body, separators=(",", ":"), ensure_ascii=True),
    }


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """EA稼働監視専用。取引判断・Telemetryとは分離し、応答をEAの売買可否へ使用させない。"""
    started = time.perf_counter()
    metrics: dict[str, tuple[float | int, str]] = {"HeartbeatRequestCount": (1, "Count")}
    properties: dict[str, Any] = {"outcome": "INTERNAL_ERROR"}
    monitored_ea_id: str | None = None
    try:
        if event.get("requestContext", {}).get("http", {}).get("method") != "POST":
            raise ApiError(405, "METHOD_NOT_ALLOWED", "only POST is allowed")
        encoded = event.get("body") or ""
        try:
            raw_body = base64.b64decode(encoded, validate=True) if event.get("isBase64Encoded") else encoded.encode("utf-8")
        except (ValueError, UnicodeError) as exc:
            raise ApiError(400, "INVALID_BODY_ENCODING", "heartbeat body encoding is invalid") from exc
        heartbeat = parse_and_validate_heartbeat(raw_body)
        headers = {str(key).lower(): str(value) for key, value in (event.get("headers") or {}).items()}
        if headers.get("idempotency-key") != heartbeat["heartbeat_id"]:
            raise ApiError(400, "IDEMPOTENCY_KEY_MISMATCH", "Idempotency-Key must equal heartbeat_id")
        repository, secrets = _dependencies()
        auth = verify_request(
            event.get("headers"), raw_body, secrets, repository,
            max_clock_skew_seconds=int(os.environ.get("MAX_CLOCK_SKEW_SECONDS", "60")),
            canonical_path="/v1/heartbeats",
        )
        body_timestamp = int(datetime.fromisoformat(heartbeat["timestamp"].replace("Z", "+00:00")).timestamp())
        if body_timestamp != auth.timestamp:
            raise ApiError(400, "SIGNED_TIMESTAMP_MISMATCH", "body timestamp must equal X-EA-Timestamp")
        source_id = hashlib.sha256(
            f"{os.environ['ENVIRONMENT']}|{auth.key_id}|{heartbeat['ea_id']}".encode("utf-8")
        ).hexdigest()[:32]
        received_at = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
        updated = repository.record_heartbeat(source_id, heartbeat, body_timestamp, received_at, auth.body_hash)
        status = "ACCEPTED" if updated else "STALE"
        if updated:
            metrics["HeartbeatReceivedCount"] = (1, "Count")
            if heartbeat["ea_id"] in _monitored_ea_ids():
                monitored_ea_id = heartbeat["ea_id"]
        LOGGER.info(json.dumps({
            "event": "heartbeat_recorded", "heartbeat_id": heartbeat["heartbeat_id"],
            "ea_id": heartbeat["ea_id"], "status": status,
        }))
        properties = {"outcome": status}
        return _response(200, {"schema_version": "1.0", "heartbeat_id": heartbeat["heartbeat_id"], "status": status})
    except ApiError as exc:
        LOGGER.warning(json.dumps({"event": "heartbeat_rejected", "code": exc.code}))
        if exc.code == "REPLAY_DETECTED":
            metrics["SecurityReplayRejectedCount"] = (1, "Count")
        properties = {"outcome": "REJECTED", "reason_code": exc.code, "status_code": exc.status_code}
        return _response(exc.status_code, {"error": {"code": exc.code, "message": exc.message}})
    except Exception:
        request_id = getattr(context, "aws_request_id", "unknown")
        LOGGER.exception("unhandled heartbeat error request=%s", request_id)
        metrics["HeartbeatInternalErrorCount"] = (1, "Count")
        return _response(500, {"error": {"code": "INTERNAL_ERROR", "message": "heartbeat failed safely"}})
    finally:
        metrics["HeartbeatLatencyMs"] = ((time.perf_counter() - started) * 1000.0, "Milliseconds")
        emit_emf("HeartbeatApi", metrics, properties)
        if monitored_ea_id is not None:
            # 停止検知AlarmはEA別の受信件数を監視する。欠損はAlarm側でBREACHINGとして扱う。
            emit_emf("HeartbeatApi", {"HeartbeatReceivedCount": (1, "Count")},
                     extra_dimensions={"EaId": monitored_ea_id})
