from __future__ import annotations

import base64
import hashlib
import json
import logging
import os
import time
from datetime import datetime
from typing import Any

from .auth import verify_request
from .errors import ApiError, ConditionalWriteFailed
from .event_validation import parse_and_validate_event
from .handler import SsmSecretProvider
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
    return _repository, SsmSecretProvider(boto3.client("ssm"), os.environ["ENVIRONMENT"])


def _response(status: int, body: dict[str, Any]) -> dict[str, Any]:
    return {
        "statusCode": status,
        "headers": {"content-type": "application/json", "cache-control": "no-store"},
        "body": json.dumps(body, separators=(",", ":"), ensure_ascii=True),
    }


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    started = time.perf_counter()
    metrics: dict[str, tuple[float | int, str]] = {"TelemetryRequestCount": (1, "Count")}
    properties: dict[str, Any] = {"outcome": "INTERNAL_ERROR"}
    try:
        if event.get("requestContext", {}).get("http", {}).get("method") != "POST":
            raise ApiError(405, "METHOD_NOT_ALLOWED", "only POST is allowed")
        encoded = event.get("body") or ""
        try:
            raw_body = base64.b64decode(encoded, validate=True) if event.get("isBase64Encoded") else encoded.encode("utf-8")
        except (ValueError, UnicodeError) as exc:
            raise ApiError(400, "INVALID_BODY_ENCODING", "event body encoding is invalid") from exc
        trade_event = parse_and_validate_event(raw_body)
        headers = {str(key).lower(): str(value) for key, value in (event.get("headers") or {}).items()}
        if headers.get("idempotency-key") != trade_event["event_id"]:
            raise ApiError(400, "IDEMPOTENCY_KEY_MISMATCH", "Idempotency-Key must equal event_id")
        repository, secrets = _dependencies()
        auth = verify_request(
            event.get("headers"), raw_body, secrets, repository,
            max_clock_skew_seconds=int(os.environ.get("MAX_CLOCK_SKEW_SECONDS", "60")),
            canonical_path="/v1/trade-events",
        )
        body_timestamp = int(datetime.fromisoformat(trade_event["timestamp"].replace("Z", "+00:00")).timestamp())
        if body_timestamp != auth.timestamp:
            raise ApiError(400, "SIGNED_TIMESTAMP_MISMATCH", "body timestamp must equal X-EA-Timestamp")
        source_id = hashlib.sha256(
            f"{os.environ['ENVIRONMENT']}|{auth.key_id}|{trade_event['ea_id']}".encode("utf-8")
        ).hexdigest()[:32]
        try:
            created = repository.save_trade_event(source_id, trade_event, auth.body_hash)
        except ConditionalWriteFailed as exc:
            raise ApiError(409, "EVENT_ID_CONFLICT", "event identity was reused with different content") from exc
        status = "ACCEPTED" if created else "DUPLICATE"
        LOGGER.info(json.dumps({
            "event": "trade_event_stored", "event_id": trade_event["event_id"],
            "trade_candidate_id": trade_event["trade_candidate_id"],
            "event_type": trade_event["event_type"], "status": status,
        }))
        if (created and trade_event["event_type"] == "RISK_DECISION"
                and trade_event["payload"].get("status") == "REJECTED"):
            metrics["RiskRejectedCount"] = (1, "Count")
        properties = {"outcome": status, "event_type": trade_event["event_type"]}
        return _response(200, {"schema_version": "1.0", "event_id": trade_event["event_id"], "status": status})
    except ApiError as exc:
        LOGGER.warning(json.dumps({"event": "trade_event_rejected", "code": exc.code}))
        if exc.code == "REPLAY_DETECTED":
            metrics["SecurityReplayRejectedCount"] = (1, "Count")
        properties = {"outcome": "REJECTED", "reason_code": exc.code, "status_code": exc.status_code}
        return _response(exc.status_code, {"error": {"code": exc.code, "message": exc.message}})
    except Exception:
        request_id = getattr(context, "aws_request_id", "unknown")
        LOGGER.exception("unhandled telemetry error request=%s", request_id)
        metrics["TelemetryInternalErrorCount"] = (1, "Count")
        return _response(500, {"error": {"code": "INTERNAL_ERROR", "message": "event failed safely"}})
    finally:
        metrics["TelemetryLatencyMs"] = ((time.perf_counter() - started) * 1000.0, "Milliseconds")
        emit_emf("TelemetryApi", metrics, properties)
