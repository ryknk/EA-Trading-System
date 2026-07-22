import json
import os
import unittest
from unittest.mock import patch

from decision_api import handler
from decision_api.llm import LlmDecision
from decision_api.ml import MlPrediction
from support import FakeSecrets, MemoryRepository, raw_request, request_dict, signed_headers


class Context:
    aws_request_id = "lambda-test-id"


class PassingMl:
    model_version = "baseline-v1"
    def predict(self, request): return MlPrediction(0.7, 0.002, self.model_version)


class AllowingLlm:
    provider_name = "openai"
    model_name = "test-model"
    prompt_version = "trade-filter-v1"
    def decide(self, request, ml):
        return LlmDecision("ALLOW", 0.8, "No material anomaly is visible.",
                           self.provider_name, self.model_name, self.prompt_version,
                           "2025-06-15T15:06:40Z", "2025-06-15T15:06:41Z")


class HandlerTests(unittest.TestCase):
    def setUp(self) -> None:
        os.environ["MAX_CLOCK_SKEW_SECONDS"] = "60"

    def test_authenticated_request_returns_fail_safe_veto(self) -> None:
        request = request_dict(); raw = raw_request(request)
        event = {
            "requestContext": {"http": {"method": "POST"}}, "body": raw.decode(),
            "headers": signed_headers(raw, request["request_id"]), "isBase64Encoded": False,
        }
        with patch.object(handler, "_dependencies", return_value=(MemoryRepository(), FakeSecrets())), \
             patch("decision_api.auth.time.time", return_value=1_750_000_000):
            response = handler.lambda_handler(event, Context())
        body = json.loads(response["body"])
        self.assertEqual(200, response["statusCode"])
        self.assertEqual("VETO", body["decision"])

    def test_idempotency_header_mismatch_is_400(self) -> None:
        request = request_dict(); raw = raw_request(request); headers = signed_headers(raw, request["request_id"])
        headers["Idempotency-Key"] = "different"
        event = {"requestContext": {"http": {"method": "POST"}}, "body": raw.decode(), "headers": headers}
        response = handler.lambda_handler(event, Context())
        self.assertEqual(400, response["statusCode"])
        self.assertEqual("IDEMPOTENCY_KEY_MISMATCH", json.loads(response["body"])["error"]["code"])

    def test_ml_pass_and_llm_allow_return_allow(self) -> None:
        request = request_dict(); raw = raw_request(request); repository = MemoryRepository()
        event = {"requestContext": {"http": {"method": "POST"}}, "body": raw.decode(),
                 "headers": signed_headers(raw, request["request_id"])}
        with patch.object(handler, "_dependencies", return_value=(repository, FakeSecrets())), \
             patch.object(handler, "_ml_dependency", return_value=PassingMl()), \
             patch.object(handler, "_llm_dependency", return_value=AllowingLlm()), \
             patch("decision_api.auth.time.time", return_value=1_750_000_000):
            response = handler.lambda_handler(event, Context())
        body = json.loads(response["body"])
        self.assertEqual(200, response["statusCode"])
        self.assertEqual("ALLOW", body["decision"])
        self.assertEqual("APPROVED", body["reason_code"])
        self.assertEqual("ALLOW", body["llm"]["status"])
        self.assertIn(request["request_id"], repository.audits)

    def test_signed_timestamp_must_match_body(self) -> None:
        request = request_dict(); request["timestamp"] = "2025-06-15T15:06:39Z"
        raw = raw_request(request)
        event = {"requestContext": {"http": {"method": "POST"}}, "body": raw.decode(),
                 "headers": signed_headers(raw, request["request_id"])}
        with patch.object(handler, "_dependencies", return_value=(MemoryRepository(), FakeSecrets())), \
             patch("decision_api.auth.time.time", return_value=1_750_000_000):
            response = handler.lambda_handler(event, Context())
        self.assertEqual(400, response["statusCode"])
        self.assertEqual("SIGNED_TIMESTAMP_MISMATCH", json.loads(response["body"])["error"]["code"])

    def test_malformed_input_and_unhandled_dependency_error_fail_closed(self) -> None:
        malformed = {"requestContext": {"http": {"method": "POST"}}, "body": "{"}
        self.assertEqual(400, handler.lambda_handler(malformed, Context())["statusCode"])
        request = request_dict(); raw = raw_request(request)
        event = {"requestContext": {"http": {"method": "POST"}}, "body": raw.decode(),
                 "headers": signed_headers(raw, request["request_id"])}
        with patch.object(handler, "_dependencies", side_effect=TimeoutError("simulated timeout")):
            response = handler.lambda_handler(event, Context())
        self.assertEqual(500, response["statusCode"])
        self.assertEqual("INTERNAL_ERROR", json.loads(response["body"])["error"]["code"])


if __name__ == "__main__":
    unittest.main()
