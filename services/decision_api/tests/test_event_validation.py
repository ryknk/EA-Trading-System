import json
import unittest

from decision_api.errors import ApiError
from decision_api.event_validation import parse_and_validate_event
from support import trade_event


class EventValidationTests(unittest.TestCase):
    def test_supported_events_are_accepted(self) -> None:
        for event_type in (
            "CANDIDATE", "EXTERNAL_DECISION", "RISK_DECISION", "ORDER_SUBMISSION",
            "DEAL", "POSITION_SNAPSHOT", "TRADE_CLOSED", "ACCOUNT_SNAPSHOT", "SYSTEM_ERROR",
        ):
            event = trade_event(event_type)
            parsed = parse_and_validate_event(json.dumps(event, separators=(",", ":")).encode())
            self.assertEqual(event_type, parsed["event_type"])

    def test_unknown_missing_duplicate_and_non_finite_are_rejected(self) -> None:
        unknown = trade_event(); unknown["unknown"] = 1
        missing = trade_event(); missing["payload"].pop("volume")
        non_finite = trade_event(); non_finite["payload"]["volume"] = float("nan")
        cases = [json.dumps(unknown).encode(), json.dumps(missing).encode(),
                 json.dumps(non_finite, allow_nan=True).encode(),
                 b'{"schema_version":"1.0","schema_version":"1.0"}']
        for raw in cases:
            with self.subTest(raw=raw), self.assertRaises(ApiError):
                parse_and_validate_event(raw)

    def test_payload_type_must_match_event_type(self) -> None:
        event = trade_event("DEAL"); event["payload"]["direction"] = "BUY"
        with self.assertRaises(ApiError) as raised:
            parse_and_validate_event(json.dumps(event).encode())
        self.assertEqual("INVALID_EVENT_PAYLOAD", raised.exception.code)


if __name__ == "__main__":
    unittest.main()
