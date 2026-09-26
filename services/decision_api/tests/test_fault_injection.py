"""外部サービス障害時に新規注文がFail Closed（VETOまたは非200）になることを検証する。"""
import hashlib
import io
import json
import os
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch

from decision_api import handler
from decision_api.llm import LlmDecision, OpenAiResponsesProvider
from decision_api.ml import MlPrediction
from decision_api.service import DecisionService
from support import FakeSecrets, MemoryRepository, NOW, raw_request, request_dict, signed_headers
from test_llm import Keys, Transport, passed_ml


class Context:
    aws_request_id = "fault-test-id"

    def __init__(self, remaining_ms: int = 5_000) -> None:
        self.remaining_ms = remaining_ms

    def get_remaining_time_in_millis(self) -> int:
        return self.remaining_ms


class PassingMl:
    model_version = "baseline-v1"
    def predict(self, request): return MlPrediction(0.7, 0.002, self.model_version)


class FailingMl:
    model_version = "baseline-v1"
    def predict(self, request): raise RuntimeError("simulated S3 model outage")


class CountingLlm:
    provider_name = "openai"
    model_name = "test-model"
    prompt_version = "trade-filter-v1"

    def __init__(self, decision: str = "ALLOW") -> None:
        self.calls = 0
        self.decision = decision

    def decide(self, request, ml):
        self.calls += 1
        return LlmDecision(self.decision, 0.8, "No material anomaly is visible.",
                           self.provider_name, self.model_name, self.prompt_version,
                           "2025-06-15T15:06:40Z", "2025-06-15T15:06:41Z")


class FailingNonceRepository(MemoryRepository):
    def claim_nonce(self, key_id, nonce, expires_epoch):
        raise RuntimeError("simulated DynamoDB outage")


class FailingDecisionWriteRepository(MemoryRepository):
    def save_decision(self, *args, **kwargs):
        raise RuntimeError("simulated DynamoDB write outage")


def decision_event() -> dict:
    request = request_dict(); raw = raw_request(request)
    return {"requestContext": {"http": {"method": "POST"}}, "body": raw.decode(),
            "headers": signed_headers(raw, request["request_id"])}


def invoke(repository=None, ml=None, llm=None, context=None) -> tuple[dict, dict]:
    output = io.StringIO()
    with patch.object(handler, "_dependencies", return_value=(repository or MemoryRepository(), FakeSecrets())), \
         patch.object(handler, "_ml_dependency", return_value=ml or PassingMl()), \
         patch.object(handler, "_llm_dependency", return_value=llm or CountingLlm()), \
         patch("decision_api.auth.time.time", return_value=NOW), redirect_stdout(output):
        response = handler.lambda_handler(decision_event(), context or Context())
    metrics = [json.loads(line) for line in output.getvalue().splitlines() if line.startswith("{")]
    return response, (metrics[-1] if metrics else {})


class DecisionFaultInjectionTests(unittest.TestCase):
    def setUp(self) -> None:
        os.environ.update({"MAX_CLOCK_SKEW_SECONDS": "60", "METRICS_ENABLED": "true", "ENVIRONMENT": "dev",
                           "LLM_TIMEOUT_SECONDS": "3.0", "LLM_DEADLINE_RESERVE_SECONDS": "0.5",
                           "DECISION_DEADLINE_SECONDS": "4.0", "LLM_SHADOW_MODE": "true"})

    def tearDown(self) -> None:
        for name in ("LLM_TIMEOUT_SECONDS", "LLM_DEADLINE_RESERVE_SECONDS", "DECISION_DEADLINE_SECONDS",
                     "LLM_SHADOW_MODE"):
            os.environ.pop(name, None)

    def test_llm_is_called_when_time_budget_remains(self) -> None:
        llm = CountingLlm()
        response, _ = invoke(llm=llm)
        self.assertEqual("ALLOW", json.loads(response["body"])["decision"])
        self.assertEqual(1, llm.calls)

    def test_lambda_near_timeout_skips_llm_and_vetoes_even_in_shadow_mode(self) -> None:
        llm = CountingLlm()
        response, metrics = invoke(llm=llm, context=Context(remaining_ms=3_000))
        body = json.loads(response["body"])
        self.assertEqual(200, response["statusCode"])
        self.assertEqual(("VETO", "LLM_INFERENCE_ERROR", "ERROR"),
                         (body["decision"], body["reason_code"], body["llm"]["status"]))
        self.assertEqual(0, llm.calls)
        self.assertEqual(1, metrics["LlmErrorCount"])

    def test_slow_preprocessing_consumes_deadline_and_skips_llm(self) -> None:
        llm = CountingLlm()
        # perf_counter: handler開始=0秒、LLM直前=0.6秒（4.0 - 0.6 < 3.0 + 0.5）。
        with patch("decision_api.handler.time.perf_counter", side_effect=[0.0, 0.6, 0.7]):
            response, _ = invoke(llm=llm)
        self.assertEqual("VETO", json.loads(response["body"])["decision"])
        self.assertEqual(0, llm.calls)

    def test_ml_outage_vetoes_without_calling_llm(self) -> None:
        llm = CountingLlm()
        response, metrics = invoke(ml=FailingMl(), llm=llm)
        body = json.loads(response["body"])
        self.assertEqual(("VETO", "ML_INFERENCE_ERROR"), (body["decision"], body["reason_code"]))
        self.assertEqual(0, llm.calls)
        self.assertEqual(1, metrics["MlErrorCount"])

    def test_dynamodb_outage_never_returns_allow(self) -> None:
        for repository in (FailingNonceRepository(), FailingDecisionWriteRepository()):
            response, metrics = invoke(repository=repository)
            with self.subTest(repository=type(repository).__name__):
                self.assertEqual(500, response["statusCode"])
                self.assertNotIn("ALLOW", response["body"])
                self.assertEqual(1, metrics["DecisionInternalErrorCount"])

    def test_invalid_deadline_configuration_fails_closed(self) -> None:
        os.environ["DECISION_DEADLINE_SECONDS"] = "nan"
        response, _ = invoke()
        self.assertEqual(500, response["statusCode"])


class LlmLatencyTests(unittest.TestCase):
    def test_provider_rejects_response_after_total_timeout(self) -> None:
        provider = OpenAiResponsesProvider(
            Keys(), "test-model", "trade-filter-v1",
            Transport('{"decision":"ALLOW","confidence":0.9,"reason":"Late but valid."}'), timeout_seconds=3.0,
        )
        with patch("decision_api.llm.time.monotonic", side_effect=[100.0, 103.2]):
            with self.assertRaises(TimeoutError):
                provider.decide(request_dict(), passed_ml())

    def test_service_turns_late_llm_into_veto_and_keeps_shadow_mode_fail_closed(self) -> None:
        provider = OpenAiResponsesProvider(
            Keys(), "test-model", "trade-filter-v1",
            Transport('{"decision":"ALLOW","confidence":0.9,"reason":"Late but valid."}'), timeout_seconds=3.0,
        )
        request = request_dict(); body_hash = hashlib.sha256(raw_request(request)).hexdigest()
        with patch("decision_api.llm.time.monotonic", side_effect=[100.0, 103.2]):
            response = DecisionService(
                MemoryRepository(), PassingMl(), provider, llm_shadow_mode=True,
            ).decide(request, body_hash)
        self.assertEqual(("VETO", "LLM_INFERENCE_ERROR"), (response["decision"], response["reason_code"]))

    def test_service_rejects_invalid_deadline_settings(self) -> None:
        for value in (-1.0, float("nan")):
            with self.subTest(value=value), self.assertRaises(ValueError):
                DecisionService(MemoryRepository(), llm_min_remaining_seconds=value)


if __name__ == "__main__":
    unittest.main()
