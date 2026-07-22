from __future__ import annotations

from datetime import datetime, timedelta, timezone
import math
import re
from typing import Any, Protocol

from .errors import ApiError, ConditionalWriteFailed
from .llm import LlmDecisionProvider, UnavailableLlmProvider
from .ml import MlInferenceProvider, UnavailableMlProvider


class DecisionRepository(Protocol):
    def get_decision(self, request_id: str) -> dict[str, Any] | None: ...
    def save_decision(self, request_id: str, body_hash: str, response: dict[str, Any], ttl: int,
                      audit: dict[str, Any] | None = None) -> None: ...


def _iso(value: datetime) -> str:
    return value.astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


class DecisionService:
    """ML通過時だけLLM異常環境フィルターを評価する。"""

    def __init__(self, repository: DecisionRepository,
                 ml_provider: MlInferenceProvider | None = None,
                 llm_provider: LlmDecisionProvider | None = None,
                 min_win_probability: float = 0.60,
                 min_expected_return: float = 0.0,
                 response_ttl_seconds: int = 30,
                 llm_shadow_mode: bool = False) -> None:
        self._repository = repository
        self._ml_provider = ml_provider or UnavailableMlProvider()
        self._llm_provider = llm_provider or UnavailableLlmProvider()
        if not 0.0 <= min_win_probability <= 1.0 or not math.isfinite(min_expected_return):
            raise ValueError("ML thresholds are invalid")
        self._min_win_probability = min_win_probability
        self._min_expected_return = min_expected_return
        self._response_ttl_seconds = response_ttl_seconds
        self._llm_shadow_mode = llm_shadow_mode

    def decide(self, request: dict[str, Any], body_hash: str,
               now: datetime | None = None) -> dict[str, Any]:
        request_id = request["request_id"]
        existing = self._repository.get_decision(request_id)
        if existing:
            if existing["body_hash"] != body_hash:
                raise ApiError(409, "IDEMPOTENCY_CONFLICT", "request_id was used with a different body")
            return existing["response"]

        created = (now or datetime.now(timezone.utc)).astimezone(timezone.utc)
        expires = created + timedelta(seconds=self._response_ttl_seconds)
        final_decision = "VETO"
        llm = {"status": "NOT_CALLED"}
        audit: dict[str, Any] = {
            "trade_candidate_id": request["trade_candidate_id"],
            "ea_id": request["ea_id"], "symbol": request["symbol"],
            "timeframe": request["timeframe"], "direction": request["direction"],
            "strategy_pattern": request["strategy"]["pattern"],
            "strategy_reason_code": request["strategy"]["reason_code"],
            "strategy_reason": request["strategy"]["reason"],
        }
        try:
            prediction = self._ml_provider.predict(request)
            if (not math.isfinite(prediction.win_probability)
                    or not 0.0 <= prediction.win_probability <= 1.0
                    or not math.isfinite(prediction.expected_return)
                    or not re.fullmatch(r"[A-Za-z0-9._-]{1,64}", prediction.model_version)):
                raise ValueError("ML prediction is invalid")
            passed = (prediction.win_probability >= self._min_win_probability
                      and prediction.expected_return >= self._min_expected_return)
            ml = {
                "status": "PASSED" if passed else "REJECTED",
                "win_probability": prediction.win_probability,
                "expected_return": prediction.expected_return,
                "model_version": prediction.model_version,
            }
            reason_code = "ML_PASSED" if passed else "ML_THRESHOLD_NOT_MET"
        except Exception:
            try:
                error_model_version = self._ml_provider.model_version
            except Exception:
                error_model_version = "unavailable"
            if not isinstance(error_model_version, str) or not re.fullmatch(r"[A-Za-z0-9._-]{1,64}", error_model_version):
                error_model_version = "invalid-model"
            ml = {"status": "ERROR", "model_version": error_model_version}
            reason_code = "ML_INFERENCE_ERROR"

        audit.update({
            "ml_status": ml["status"], "ml_model_version": ml["model_version"],
        })
        if "win_probability" in ml:
            audit["ml_win_probability"] = ml["win_probability"]
            audit["ml_expected_return"] = ml["expected_return"]

        if ml["status"] == "PASSED":
            llm_started = _iso(datetime.now(timezone.utc))
            try:
                llm_decision = self._llm_provider.decide(request, ml)
                if llm_decision.decision not in {"ALLOW", "VETO"}:
                    raise ValueError("LLM decision is invalid")
                if (not math.isfinite(llm_decision.confidence)
                        or not 0.0 <= llm_decision.confidence <= 1.0):
                    raise ValueError("LLM confidence is invalid")
                identifiers = (
                    (llm_decision.provider, 32), (llm_decision.model, 64),
                    (llm_decision.prompt_version, 32),
                )
                if any(not isinstance(value, str) or not 1 <= len(value) <= limit
                       or not re.fullmatch(r"[A-Za-z0-9._-]+", value)
                       for value, limit in identifiers):
                    raise ValueError("LLM identity is invalid")
                if (not isinstance(llm_decision.reason, str)
                        or not 1 <= len(llm_decision.reason) <= 512
                        or any(ord(char) < 32 for char in llm_decision.reason)):
                    raise ValueError("LLM reason is invalid")
                try:
                    llm_request_time = datetime.fromisoformat(llm_decision.request_time.replace("Z", "+00:00"))
                    llm_response_time = datetime.fromisoformat(llm_decision.response_time.replace("Z", "+00:00"))
                except (AttributeError, ValueError) as exc:
                    raise ValueError("LLM audit time is invalid") from exc
                if (not llm_decision.request_time.endswith("Z")
                        or not llm_decision.response_time.endswith("Z")
                        or llm_response_time < llm_request_time):
                    raise ValueError("LLM audit time ordering is invalid")
                llm = {
                    "status": llm_decision.decision,
                    "provider": llm_decision.provider,
                    "model": llm_decision.model,
                    "prompt_version": llm_decision.prompt_version,
                    "confidence": llm_decision.confidence,
                    "reason": llm_decision.reason,
                }
                final_decision = llm_decision.decision
                reason_code = "APPROVED" if final_decision == "ALLOW" else "LLM_VETO"
                if self._llm_shadow_mode and llm_decision.decision == "VETO":
                    final_decision = "ALLOW"
                    reason_code = "LLM_SHADOW_VETO_RECORDED"
                audit.update({
                    "llm_provider": llm_decision.provider,
                    "llm_model": llm_decision.model,
                    "llm_prompt_version": llm_decision.prompt_version,
                    "llm_request_time": llm_decision.request_time,
                    "llm_response_time": llm_decision.response_time,
                    "llm_decision": llm_decision.decision,
                    "llm_confidence": llm_decision.confidence,
                    "llm_reason": llm_decision.reason,
                    "llm_shadow_mode": self._llm_shadow_mode,
                    "llm_applied": not self._llm_shadow_mode,
                })
            except Exception:
                llm = {"status": "ERROR"}
                reason_code = "LLM_INFERENCE_ERROR"
                def safe_identity(value: Any, maximum: int, fallback: str) -> str:
                    return value if isinstance(value, str) and 1 <= len(value) <= maximum \
                        and re.fullmatch(r"[A-Za-z0-9._-]+", value) else fallback
                try:
                    provider_name = self._llm_provider.provider_name
                    model_name = self._llm_provider.model_name
                    prompt_version = self._llm_provider.prompt_version
                except Exception:
                    provider_name, model_name, prompt_version = "unavailable", "unavailable", "unavailable"
                audit.update({
                    "llm_provider": safe_identity(provider_name, 32, "unavailable"),
                    "llm_model": safe_identity(model_name, 64, "unavailable"),
                    "llm_prompt_version": safe_identity(prompt_version, 32, "unavailable"),
                    "llm_request_time": llm_started,
                    "llm_response_time": _iso(datetime.now(timezone.utc)),
                    "llm_decision": "ERROR",
                })

        response = {
            "schema_version": "1.0",
            "request_id": request_id,
            "decision": final_decision,
            "reason_code": reason_code,
            "ml": ml,
            "llm": llm,
            "created_at": _iso(created),
            "expires_at": _iso(expires),
        }
        try:
            self._repository.save_decision(
                request_id, body_hash, response, int(expires.timestamp()) + 86_400, audit
            )
        except ConditionalWriteFailed:
            existing = self._repository.get_decision(request_id)
            if not existing or existing["body_hash"] != body_hash:
                raise ApiError(409, "IDEMPOTENCY_CONFLICT", "concurrent request conflict")
            return existing["response"]
        return response
