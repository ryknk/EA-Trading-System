from __future__ import annotations

import base64
import json
import logging
import os
import time
from datetime import datetime
from typing import Any

from .auth import verify_request
from .errors import ApiError
from .ml import MlInferenceProvider, S3MlProvider, UnavailableMlProvider
from .monitoring import emit_emf
from .llm import LlmDecisionProvider, OpenAiResponsesProvider, UnavailableLlmProvider
from .repository import DynamoRepository
from .service import DecisionService
from .validation import parse_and_validate_request

LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(os.environ.get("LOG_LEVEL", "INFO").upper())
_repository: DynamoRepository | None = None
_ml: MlInferenceProvider | None = None
_llm: LlmDecisionProvider | None = None


class SsmSecretProvider:
    def __init__(self, client: Any, environment: str) -> None:
        self._client = client
        self._prefix = f"/ea-trading-system/{environment}/credentials/"

    def get_secret(self, key_id: str) -> str:
        response = self._client.get_parameter(Name=self._prefix + key_id, WithDecryption=True)
        secret = response["Parameter"]["Value"]
        if not 32 <= len(secret) <= 256:
            raise ValueError("secret length is invalid")
        return secret


class SsmOpenAiApiKeyProvider:
    def __init__(self, client: Any, environment: str) -> None:
        self._client = client
        self._name = f"/ea-trading-system/{environment}/providers/openai/api-key"

    def get_api_key(self) -> str:
        return self._client.get_parameter(Name=self._name, WithDecryption=True)["Parameter"]["Value"]


def _dependencies() -> tuple[DynamoRepository, SsmSecretProvider]:
    global _repository
    import boto3
    if _repository is None:
        _repository = DynamoRepository(boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"]))
    return _repository, SsmSecretProvider(boto3.client("ssm"), os.environ["ENVIRONMENT"])


def _ml_dependency() -> MlInferenceProvider:
    global _ml
    if _ml is None:
        checksum = os.environ.get("ML_MODEL_SHA256", "")
        if not checksum:
            _ml = UnavailableMlProvider()
        else:
            import boto3
            _ml = S3MlProvider(
                boto3.client("s3"), os.environ["ARTIFACT_BUCKET"],
                os.environ["ML_MODEL_KEY"], checksum,
            )
    return _ml


def _llm_dependency() -> LlmDecisionProvider:
    global _llm
    if _llm is None:
        provider = os.environ.get("LLM_PROVIDER", "").lower()
        model = os.environ.get("LLM_MODEL", "")
        if provider != "openai" or not model:
            _llm = UnavailableLlmProvider()
        else:
            import boto3
            temperature_text = os.environ.get("LLM_TEMPERATURE", "0")
            _llm = OpenAiResponsesProvider(
                SsmOpenAiApiKeyProvider(boto3.client("ssm"), os.environ["ENVIRONMENT"]),
                model, os.environ.get("LLM_PROMPT_VERSION", "trade-filter-v1"),
                timeout_seconds=float(os.environ.get("LLM_TIMEOUT_SECONDS", "3.0")),
                temperature=None if temperature_text == "" else float(temperature_text),
            )
    return _llm


def _response(status: int, body: dict[str, Any]) -> dict[str, Any]:
    return {
        "statusCode": status,
        "headers": {"content-type": "application/json", "cache-control": "no-store"},
        "body": json.dumps(body, separators=(",", ":"), ensure_ascii=True),
    }


def _strict_bool(name: str, default: str = "false") -> bool:
    value = os.environ.get(name, default).lower()
    if value not in {"true", "false"}:
        raise ValueError(f"{name} must be true or false")
    return value == "true"


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    started = time.perf_counter()
    metrics: dict[str, tuple[float | int, str]] = {"DecisionRequestCount": (1, "Count")}
    properties: dict[str, Any] = {"outcome": "INTERNAL_ERROR"}
    try:
        if event.get("requestContext", {}).get("http", {}).get("method") != "POST":
            raise ApiError(405, "METHOD_NOT_ALLOWED", "only POST is allowed")
        encoded = event.get("body") or ""
        try:
            raw_body = base64.b64decode(encoded, validate=True) if event.get("isBase64Encoded") else encoded.encode("utf-8")
        except (ValueError, UnicodeError) as exc:
            raise ApiError(400, "INVALID_BODY_ENCODING", "request body encoding is invalid") from exc
        request = parse_and_validate_request(raw_body)
        idempotency_key = {str(k).lower(): str(v) for k, v in (event.get("headers") or {}).items()}.get("idempotency-key")
        if idempotency_key != request["request_id"]:
            raise ApiError(400, "IDEMPOTENCY_KEY_MISMATCH", "Idempotency-Key must equal request_id")
        repository, secrets = _dependencies()
        auth = verify_request(
            event.get("headers"), raw_body, secrets, repository,
            max_clock_skew_seconds=int(os.environ.get("MAX_CLOCK_SKEW_SECONDS", "60")),
        )
        body_timestamp = int(datetime.fromisoformat(request["timestamp"].replace("Z", "+00:00")).timestamp())
        if body_timestamp != auth.timestamp:
            raise ApiError(400, "SIGNED_TIMESTAMP_MISMATCH", "body timestamp must equal X-EA-Timestamp")
        result = DecisionService(
            repository,
            _ml_dependency(),
            _llm_dependency(),
            float(os.environ.get("ML_MIN_WIN_PROBABILITY", "0.60")),
            float(os.environ.get("ML_MIN_EXPECTED_RETURN", "0.0")),
            int(os.environ.get("RESPONSE_TTL_SECONDS", "30")),
            _strict_bool("LLM_SHADOW_MODE", "false"),
        ).decide(request, auth.body_hash)
        LOGGER.info(json.dumps({"event": "decision_completed", "request_id": request["request_id"],
                                "ea_id": request["ea_id"], "decision": result["decision"],
                                "reason_code": result["reason_code"]}))
        metrics[f"Decision{result['decision'].title()}Count"] = (1, "Count")
        if result["reason_code"] == "ML_INFERENCE_ERROR":
            metrics["MlErrorCount"] = (1, "Count")
        if result["reason_code"] == "LLM_INFERENCE_ERROR":
            metrics["LlmErrorCount"] = (1, "Count")
        properties = {
            "outcome": result["decision"], "reason_code": result["reason_code"],
            "ml_status": result["ml"]["status"], "llm_status": result["llm"]["status"],
        }
        return _response(200, result)
    except ApiError as exc:
        LOGGER.warning(json.dumps({"event": "request_rejected", "code": exc.code}))
        if exc.code == "REPLAY_DETECTED":
            metrics["SecurityReplayRejectedCount"] = (1, "Count")
        properties = {"outcome": "REJECTED", "reason_code": exc.code, "status_code": exc.status_code}
        return _response(exc.status_code, {"error": {"code": exc.code, "message": exc.message}})
    except Exception:
        request_id = getattr(context, "aws_request_id", "unknown")
        LOGGER.exception("unhandled decision API error request=%s", request_id)
        metrics["DecisionInternalErrorCount"] = (1, "Count")
        return _response(500, {"error": {"code": "INTERNAL_ERROR", "message": "request failed safely"}})
    finally:
        metrics["DecisionLatencyMs"] = ((time.perf_counter() - started) * 1000.0, "Milliseconds")
        emit_emf("DecisionApi", metrics, properties)
