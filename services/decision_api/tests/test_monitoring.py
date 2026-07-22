import io
import json
import os
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch

from decision_api import handler, telemetry_handler
from decision_api.errors import ApiError
from decision_api.monitoring import emit_emf
from support import FakeSecrets, MemoryRepository, NOW, raw_request, request_dict, signed_headers, trade_event


class Context:
    aws_request_id = "monitoring-test-id"


class MonitoringTests(unittest.TestCase):
    def setUp(self) -> None:
        os.environ["ENVIRONMENT"] = "dev"
        os.environ["METRIC_NAMESPACE"] = "EaTradingSystem"
        os.environ["METRICS_ENABLED"] = "true"

    def test_emf_has_only_low_cardinality_dimensions(self) -> None:
        output = io.StringIO()
        with patch("decision_api.monitoring.time.time", return_value=1_750_000_000.123), redirect_stdout(output):
            emit_emf("DecisionApi", {
                "DecisionRequestCount": (1, "Count"), "DecisionLatencyMs": (12.5, "Milliseconds"),
            }, {"reason_code": "APPROVED", "trade_candidate_id": "not-a-dimension"})
        payload = json.loads(output.getvalue())
        definition = payload["_aws"]["CloudWatchMetrics"][0]
        self.assertEqual([["Environment", "Service"]], definition["Dimensions"])
        self.assertEqual(1_750_000_000_123, payload["_aws"]["Timestamp"])
        self.assertEqual("not-a-dimension", payload["trade_candidate_id"])

    def test_disabled_invalid_or_broken_monitoring_never_raises(self) -> None:
        os.environ["METRICS_ENABLED"] = "false"
        output = io.StringIO()
        with redirect_stdout(output):
            emit_emf("DecisionApi", {"Count": (1, "Count")})
        self.assertEqual("", output.getvalue())
        os.environ["METRICS_ENABLED"] = "true"
        with patch("builtins.print", side_effect=OSError("log unavailable")):
            emit_emf("DecisionApi", {"Count": (1, "Count")})

    def test_decision_handler_emits_veto_and_internal_error_metrics(self) -> None:
        request = request_dict(); raw = raw_request(request)
        event = {"requestContext": {"http": {"method": "POST"}}, "body": raw.decode(),
                 "headers": signed_headers(raw, request["request_id"])}
        with patch.object(handler, "_dependencies", return_value=(MemoryRepository(), FakeSecrets())), \
             patch("decision_api.auth.time.time", return_value=NOW), \
             patch.object(handler, "emit_emf") as emit:
            response = handler.lambda_handler(event, Context())
        self.assertEqual(200, response["statusCode"])
        metrics = emit.call_args.args[1]
        self.assertEqual((1, "Count"), metrics["DecisionVetoCount"])
        self.assertIn("DecisionLatencyMs", metrics)

        with patch.object(handler, "_dependencies", side_effect=TimeoutError("down")), \
             patch.object(handler, "emit_emf") as emit:
            response = handler.lambda_handler(event, Context())
        self.assertEqual(500, response["statusCode"])
        self.assertEqual((1, "Count"), emit.call_args.args[1]["DecisionInternalErrorCount"])

    def test_telemetry_risk_rejection_metric_is_separate_from_response(self) -> None:
        body = trade_event("RISK_DECISION")
        body["payload"]["status"] = "REJECTED"
        raw = json.dumps(body, separators=(",", ":")).encode()
        event = {"requestContext": {"http": {"method": "POST"}}, "body": raw.decode(),
                 "headers": signed_headers(raw, body["event_id"], canonical_path="/v1/trade-events")}
        with patch.object(telemetry_handler, "_dependencies", return_value=(MemoryRepository(), FakeSecrets())), \
             patch("decision_api.auth.time.time", return_value=NOW), \
             patch.object(telemetry_handler, "emit_emf") as emit:
            response = telemetry_handler.lambda_handler(event, Context())
        self.assertEqual(200, response["statusCode"])
        self.assertEqual((1, "Count"), emit.call_args.args[1]["RiskRejectedCount"])

    def test_replay_rejection_emits_security_metric(self) -> None:
        request = request_dict(); raw = raw_request(request)
        event = {"requestContext": {"http": {"method": "POST"}}, "body": raw.decode(),
                 "headers": signed_headers(raw, request["request_id"])}
        with patch.object(handler, "_dependencies", return_value=(MemoryRepository(), FakeSecrets())), \
             patch.object(handler, "verify_request", side_effect=ApiError(409, "REPLAY_DETECTED", "replayed")), \
             patch.object(handler, "emit_emf") as emit:
            response = handler.lambda_handler(event, Context())
        self.assertEqual(409, response["statusCode"])
        self.assertEqual((1, "Count"), emit.call_args.args[1]["SecurityReplayRejectedCount"])


if __name__ == "__main__":
    unittest.main()
