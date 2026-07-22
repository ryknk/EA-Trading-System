import json
import unittest
import urllib.error
from unittest.mock import patch

from decision_api.llm import OpenAiResponsesProvider, UrllibTransport, parse_llm_decision
from support import request_dict


class Keys:
    def get_api_key(self) -> str:
        return "unit-test-api-key-01234567890123456789"


class Transport:
    def __init__(self, decision_text: str | None = None, error: Exception | None = None) -> None:
        self.decision_text = decision_text
        self.error = error
        self.calls = []

    def post(self, url, headers, body, timeout_seconds):
        self.calls.append((url, headers, body, timeout_seconds))
        if self.error:
            raise self.error
        response = {"status": "completed", "output": [{"type": "message", "content": [
            {"type": "output_text", "text": self.decision_text}
        ]}]}
        return json.dumps(response, separators=(",", ":")).encode()


def passed_ml() -> dict:
    return {"status": "PASSED", "win_probability": 0.70,
            "expected_return": 0.002, "model_version": "baseline-v1"}


class LlmProviderTests(unittest.TestCase):
    def test_openai_request_is_structured_minimal_and_direction_is_fixed(self) -> None:
        transport = Transport('{"decision":"ALLOW","confidence":0.8,"reason":"No material anomaly is visible."}')
        provider = OpenAiResponsesProvider(Keys(), "test-model", "trade-filter-v1", transport)
        decision = provider.decide(request_dict(), passed_ml())
        self.assertEqual("ALLOW", decision.decision)
        self.assertEqual(1, len(transport.calls))
        url, headers, raw, timeout = transport.calls[0]
        body = json.loads(raw)
        context = json.loads(body["input"])
        self.assertEqual("https://api.openai.com/v1/responses", url)
        self.assertEqual(0, body["temperature"])
        self.assertTrue(body["text"]["format"]["strict"])
        self.assertEqual("BUY", context["fixed_direction"])
        self.assertNotIn("account", body["input"].lower())
        self.assertNotIn("stop_loss", body["input"])
        self.assertTrue(headers["Authorization"].startswith("Bearer "))

    def test_decision_parser_rejects_malformed_duplicate_and_forbidden_direction(self) -> None:
        invalid = [
            "",
            "```json\n{}\n```",
            '{"confidence":0.5,"reason":"x"}',
            '{"decision":"ALLOW","decision":"VETO","confidence":0.5,"reason":"x"}',
            '{"decision":"BUY","confidence":0.5,"reason":"x"}',
            '{"decision":"SELL","confidence":0.5,"reason":"x"}',
            '{"decision":"UNKNOWN","confidence":0.5,"reason":"x"}',
            '{"decision":"ALLOW","confidence":1.01,"reason":"x"}',
            '{"decision":"ALLOW","confidence":-0.01,"reason":"x"}',
            '{"decision":"ALLOW","confidence":true,"reason":"x"}',
            '{"decision":"ALLOW","confidence":0.5,"reason":""}',
            '{"decision":"ALLOW","confidence":0.5,"reason":"x","extra":1}',
        ]
        for value in invalid:
            with self.subTest(value=value), self.assertRaises(ValueError):
                parse_llm_decision(value)

    def test_provider_timeout_and_invalid_provider_json_propagate_to_fail_safe_boundary(self) -> None:
        provider = OpenAiResponsesProvider(Keys(), "test-model", "trade-filter-v1",
                                           Transport(error=TimeoutError("timeout")))
        with self.assertRaises(TimeoutError):
            provider.decide(request_dict(), passed_ml())
        invalid = OpenAiResponsesProvider(Keys(), "test-model", "trade-filter-v1", Transport("not-json"))
        with self.assertRaises(ValueError):
            invalid.decide(request_dict(), passed_ml())

    def test_refusal_and_multiple_outputs_are_rejected(self) -> None:
        class RefusalTransport:
            def post(self, *args):
                return json.dumps({"status": "completed", "output": [{"type": "message", "content": [
                    {"type": "refusal", "refusal": "cannot comply"}
                ]}]}).encode()
        provider = OpenAiResponsesProvider(Keys(), "test-model", "trade-filter-v1", RefusalTransport())
        with self.assertRaises(ValueError):
            provider.decide(request_dict(), passed_ml())

    def test_http_429_500_and_empty_response_are_transport_errors(self) -> None:
        transport = UrllibTransport()
        for status in (429, 500):
            error = urllib.error.HTTPError("https://example.invalid", status, "error", {}, None)
            with self.subTest(status=status), patch("urllib.request.urlopen", side_effect=error), \
                    self.assertRaisesRegex(RuntimeError, str(status)):
                transport.post("https://example.invalid", {}, b"{}", 0.1)

        class EmptyResponse:
            def __enter__(self): return self
            def __exit__(self, *args): return False
            def read(self, size): return b""
        with patch("urllib.request.urlopen", return_value=EmptyResponse()), \
                self.assertRaisesRegex(RuntimeError, "empty"):
            transport.post("https://example.invalid", {}, b"{}", 0.1)


if __name__ == "__main__":
    unittest.main()
