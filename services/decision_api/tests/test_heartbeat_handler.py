import io
import json
import os
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch

from decision_api import heartbeat_handler
from decision_api.errors import ApiError
from decision_api.heartbeat_validation import parse_and_validate_heartbeat
from support import FakeSecrets, MemoryRepository, NOW, SECRET, heartbeat_dict, signed_headers


class Context:
    aws_request_id = "heartbeat-test-id"


class FailingSecrets:
    def get_secret(self, key_id: str) -> str:
        raise RuntimeError("simulated SSM outage")


class FailingRepository(MemoryRepository):
    def record_heartbeat(self, *args, **kwargs) -> bool:
        raise RuntimeError("simulated DynamoDB outage")


def api_event(body: dict, canonical_path: str = "/v1/heartbeats", timestamp: int = NOW) -> dict:
    raw = json.dumps(body, separators=(",", ":")).encode()
    headers = signed_headers(raw, body["heartbeat_id"], timestamp=timestamp, canonical_path=canonical_path)
    return {"requestContext": {"http": {"method": "POST"}}, "body": raw.decode(), "headers": headers}


def invoke(event: dict, repository=None, secrets=None, now: int = NOW) -> tuple[dict, list[dict]]:
    output = io.StringIO()
    with patch.object(heartbeat_handler, "_dependencies",
                      return_value=(repository or MemoryRepository(), secrets or FakeSecrets())), \
         patch("decision_api.auth.time.time", return_value=now), redirect_stdout(output):
        response = heartbeat_handler.lambda_handler(event, Context())
    records = [json.loads(line) for line in output.getvalue().splitlines() if line.startswith("{")]
    return response, records


class HeartbeatValidationTests(unittest.TestCase):
    def test_contract_fields_and_types_are_strict(self) -> None:
        valid = heartbeat_dict()
        self.assertEqual(valid, parse_and_validate_heartbeat(json.dumps(valid).encode()))
        for field, value in (("interval_seconds", 29), ("interval_seconds", True), ("terminal_connected", 1),
                             ("ea_id", "bad id"), ("timestamp", "2025-06-15T15:06:40+09:00"),
                             ("heartbeat_id", "not-a-uuid"), ("schema_version", "2.0")):
            body = heartbeat_dict(); body[field] = value
            with self.subTest(field=field, value=value), self.assertRaises(ApiError):
                parse_and_validate_heartbeat(json.dumps(body).encode())
        extra = heartbeat_dict(); extra["order"] = "BUY"
        with self.assertRaises(ApiError):
            parse_and_validate_heartbeat(json.dumps(extra).encode())
        with self.assertRaises(ApiError):
            parse_and_validate_heartbeat(b'{"schema_version":"1.0","schema_version":"1.0"}')


class HeartbeatHandlerTests(unittest.TestCase):
    def setUp(self) -> None:
        os.environ["ENVIRONMENT"] = "dev"
        os.environ["METRICS_ENABLED"] = "true"
        os.environ["METRIC_NAMESPACE"] = "EaTradingSystem"
        os.environ["HEARTBEAT_MONITORED_EA_IDS"] = "trend-ea-v1"

    def tearDown(self) -> None:
        os.environ.pop("HEARTBEAT_MONITORED_EA_IDS", None)

    def test_authenticated_heartbeat_records_last_time_and_emits_ea_metric(self) -> None:
        repository = MemoryRepository(); body = heartbeat_dict()
        response, records = invoke(api_event(body), repository)
        self.assertEqual(200, response["statusCode"])
        self.assertEqual({"schema_version": "1.0", "heartbeat_id": body["heartbeat_id"], "status": "ACCEPTED"},
                         json.loads(response["body"]))
        stored = next(iter(repository.heartbeats.values()))
        self.assertEqual("2025-06-15T15:06:40Z", stored["last_heartbeat_at"])
        self.assertEqual(NOW, stored["last_heartbeat_epoch"])
        dimension_sets = [record["_aws"]["CloudWatchMetrics"][0]["Dimensions"][0] for record in records]
        self.assertIn(["Environment", "Service"], dimension_sets)
        self.assertIn(["Environment", "Service", "EaId"], dimension_sets)
        per_ea = next(record for record in records if "EaId" in record)
        self.assertEqual(("trend-ea-v1", 1), (per_ea["EaId"], per_ea["HeartbeatReceivedCount"]))

    def test_unmonitored_ea_id_does_not_create_new_metric_dimension(self) -> None:
        body = heartbeat_dict(); body["ea_id"] = "unlisted-ea"
        response, records = invoke(api_event(body))
        self.assertEqual(200, response["statusCode"])
        self.assertTrue(all("EaId" not in record for record in records))

    def test_older_heartbeat_does_not_overwrite_latest(self) -> None:
        repository = MemoryRepository()
        invoke(api_event(heartbeat_dict("2025-06-15T15:06:40Z")), repository)
        older = heartbeat_dict("2025-06-15T15:06:10Z")
        response, records = invoke(api_event(older, timestamp=NOW - 30), repository)
        self.assertEqual("STALE", json.loads(response["body"])["status"])
        self.assertEqual(NOW, next(iter(repository.heartbeats.values()))["last_heartbeat_epoch"])
        self.assertTrue(all("HeartbeatReceivedCount" not in record for record in records))

    def test_replay_wrong_path_and_expired_timestamp_are_rejected(self) -> None:
        repository = MemoryRepository(); event = api_event(heartbeat_dict())
        self.assertEqual(200, invoke(event, repository)[0]["statusCode"])
        replay, records = invoke(event, repository)
        self.assertEqual(409, replay["statusCode"])
        self.assertEqual(1, records[0]["SecurityReplayRejectedCount"])
        # Telemetry用署名をHeartbeatへ流用できない。
        wrong_path, _ = invoke(api_event(heartbeat_dict(), canonical_path="/v1/trade-events"))
        self.assertEqual(401, wrong_path["statusCode"])
        expired, _ = invoke(api_event(heartbeat_dict()), now=NOW + 61)
        self.assertEqual("REQUEST_TIMESTAMP_EXPIRED", json.loads(expired["body"])["error"]["code"])

    def test_ssm_outage_fails_closed_without_leaking_secret(self) -> None:
        response, records = invoke(api_event(heartbeat_dict()), secrets=FailingSecrets())
        self.assertEqual(401, response["statusCode"])
        self.assertEqual("AUTHENTICATION_FAILED", json.loads(response["body"])["error"]["code"])
        self.assertNotIn(SECRET, response["body"] + json.dumps(records))

    def test_dynamodb_outage_returns_500_and_internal_error_metric(self) -> None:
        response, records = invoke(api_event(heartbeat_dict()), FailingRepository())
        self.assertEqual(500, response["statusCode"])
        self.assertEqual("INTERNAL_ERROR", json.loads(response["body"])["error"]["code"])
        self.assertEqual(1, records[0]["HeartbeatInternalErrorCount"])
        self.assertNotIn("HeartbeatReceivedCount", records[0])


if __name__ == "__main__":
    unittest.main()
