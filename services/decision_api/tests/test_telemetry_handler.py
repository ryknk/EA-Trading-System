import json
import os
import unittest
from unittest.mock import patch

from decision_api import telemetry_handler
from support import FakeSecrets, MemoryRepository, NOW, signed_headers, trade_event


class Context:
    aws_request_id = "telemetry-test-id"


def api_event(body: dict, repository: MemoryRepository):
    raw = json.dumps(body, separators=(",", ":")).encode()
    headers = signed_headers(raw, body["event_id"], canonical_path="/v1/trade-events")
    event = {"requestContext": {"http": {"method": "POST"}}, "body": raw.decode(), "headers": headers}
    dependencies = patch.object(telemetry_handler, "_dependencies", return_value=(repository, FakeSecrets()))
    return event, dependencies


class TelemetryHandlerTests(unittest.TestCase):
    def setUp(self) -> None:
        os.environ["ENVIRONMENT"] = "dev"

    def test_authenticated_event_is_stored_and_retry_is_duplicate(self) -> None:
        body = trade_event(); repository = MemoryRepository(); event, dependencies = api_event(body, repository)
        with dependencies, patch("decision_api.auth.time.time", return_value=NOW):
            first = telemetry_handler.lambda_handler(event, Context())
        event, dependencies = api_event(body, repository)
        with dependencies, patch("decision_api.auth.time.time", return_value=NOW):
            second = telemetry_handler.lambda_handler(event, Context())
        self.assertEqual("ACCEPTED", json.loads(first["body"])["status"])
        self.assertEqual("DUPLICATE", json.loads(second["body"])["status"])
        self.assertEqual(1, len(repository.events))

    def test_wrong_signature_path_and_idempotency_key_are_rejected(self) -> None:
        body = trade_event(); raw = json.dumps(body, separators=(",", ":")).encode()
        headers = signed_headers(raw, body["event_id"])
        event = {"requestContext": {"http": {"method": "POST"}}, "body": raw.decode(), "headers": headers}
        with patch.object(telemetry_handler, "_dependencies", return_value=(MemoryRepository(), FakeSecrets())), \
             patch("decision_api.auth.time.time", return_value=NOW):
            response = telemetry_handler.lambda_handler(event, Context())
        self.assertEqual(401, response["statusCode"])
        headers["Idempotency-Key"] = "wrong"
        response = telemetry_handler.lambda_handler(event, Context())
        self.assertEqual(400, response["statusCode"])

    def test_storage_error_returns_500_without_retrying_trade(self) -> None:
        body = trade_event(); event, _ = api_event(body, MemoryRepository())
        repository = MemoryRepository()
        with patch.object(repository, "save_trade_event", side_effect=RuntimeError("ddb down")), \
             patch.object(telemetry_handler, "_dependencies", return_value=(repository, FakeSecrets())), \
             patch("decision_api.auth.time.time", return_value=NOW):
            response = telemetry_handler.lambda_handler(event, Context())
        self.assertEqual(500, response["statusCode"])


if __name__ == "__main__":
    unittest.main()
