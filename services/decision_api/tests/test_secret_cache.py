import io
import json
import logging
import os
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch

from decision_api import handler
from decision_api.handler import SsmOpenAiApiKeyProvider, SsmSecretProvider, TtlSecretCache
from support import KEY_ID, NOW, SECRET, MemoryRepository, raw_request, request_dict, signed_headers


class Clock:
    def __init__(self) -> None:
        self.now = 1_000.0

    def __call__(self) -> float:
        return self.now


class FakeSsm:
    def __init__(self, values: dict[str, str]) -> None:
        self.values = values
        self.calls: list[str] = []
        self.error: Exception | None = None

    def get_parameter(self, Name: str, WithDecryption: bool) -> dict:
        assert WithDecryption is True
        self.calls.append(Name)
        if self.error:
            raise self.error
        return {"Parameter": {"Value": self.values[Name]}}


CREDENTIAL = f"/ea-trading-system/dev/credentials/{KEY_ID}"
OPENAI_KEY = "/ea-trading-system/dev/providers/openai/api-key"


class TtlSecretCacheTests(unittest.TestCase):
    def test_secret_is_reused_until_ttl_expires(self) -> None:
        clock = Clock(); ssm = FakeSsm({CREDENTIAL: SECRET})
        provider = SsmSecretProvider(ssm, "dev", TtlSecretCache(300, clock))
        self.assertEqual(SECRET, provider.get_secret(KEY_ID))
        clock.now += 299.9
        self.assertEqual(SECRET, provider.get_secret(KEY_ID))
        self.assertEqual(1, len(ssm.calls))
        # TTL経過後は必ず再取得し、Parameter更新が最大TTL秒で反映される。
        ssm.values[CREDENTIAL] = "f" * 32
        clock.now += 0.1
        self.assertEqual("f" * 32, provider.get_secret(KEY_ID))
        self.assertEqual(2, len(ssm.calls))

    def test_zero_ttl_disables_cache(self) -> None:
        ssm = FakeSsm({CREDENTIAL: SECRET})
        provider = SsmSecretProvider(ssm, "dev", TtlSecretCache(0, Clock()))
        provider.get_secret(KEY_ID); provider.get_secret(KEY_ID)
        self.assertEqual(2, len(ssm.calls))

    def test_failures_and_invalid_values_are_never_cached(self) -> None:
        clock = Clock(); ssm = FakeSsm({CREDENTIAL: "short"})
        provider = SsmSecretProvider(ssm, "dev", TtlSecretCache(300, clock))
        with self.assertRaises(ValueError):
            provider.get_secret(KEY_ID)
        ssm.error = RuntimeError("simulated SSM outage")
        with self.assertRaises(RuntimeError):
            provider.get_secret(KEY_ID)
        ssm.error = None; ssm.values[CREDENTIAL] = SECRET
        self.assertEqual(SECRET, provider.get_secret(KEY_ID))
        self.assertEqual(3, len(ssm.calls))

    def test_openai_key_uses_same_cache_and_validation(self) -> None:
        ssm = FakeSsm({OPENAI_KEY: "k" * 40})
        cache = TtlSecretCache(300, Clock())
        provider = SsmOpenAiApiKeyProvider(ssm, "dev", cache)
        provider.get_api_key(); provider.get_api_key()
        self.assertEqual([OPENAI_KEY], ssm.calls)
        with self.assertRaises(ValueError):
            SsmOpenAiApiKeyProvider(FakeSsm({OPENAI_KEY: "short"}), "dev", cache=TtlSecretCache(300)).get_api_key()

    def test_invalid_ttl_is_rejected(self) -> None:
        for ttl in (-1, 3_601, float("nan"), float("inf")):
            with self.subTest(ttl=ttl), self.assertRaises(ValueError):
                TtlSecretCache(ttl)


class SecretOutageHandlerTests(unittest.TestCase):
    def setUp(self) -> None:
        os.environ["MAX_CLOCK_SKEW_SECONDS"] = "60"

    def test_ssm_outage_rejects_decision_and_does_not_log_secret(self) -> None:
        ssm = FakeSsm({CREDENTIAL: SECRET}); ssm.error = RuntimeError("simulated SSM outage")
        provider = SsmSecretProvider(ssm, "dev", TtlSecretCache(300, Clock()))
        request = request_dict(); raw = raw_request(request)
        event = {"requestContext": {"http": {"method": "POST"}}, "body": raw.decode(),
                 "headers": signed_headers(raw, request["request_id"])}
        output = io.StringIO()
        with patch.object(handler, "_dependencies", return_value=(MemoryRepository(), provider)), \
             patch("decision_api.auth.time.time", return_value=NOW), redirect_stdout(output), \
             self.assertLogs(handler.LOGGER, level=logging.INFO) as logs:
            response = handler.lambda_handler(event, type("Context", (), {"aws_request_id": "x"})())
        self.assertEqual(401, response["statusCode"])
        self.assertEqual("AUTHENTICATION_FAILED", json.loads(response["body"])["error"]["code"])
        self.assertNotIn(SECRET, output.getvalue() + "\n".join(logs.output) + response["body"])


if __name__ == "__main__":
    unittest.main()
