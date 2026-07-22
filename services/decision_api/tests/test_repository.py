import json
import unittest
from decimal import Decimal

from decision_api.repository import DynamoRepository


class Table:
    def __init__(self) -> None:
        self.items = []

    def put_item(self, **kwargs):
        self.items.append(kwargs["Item"])
        return {}

    def get_item(self, **kwargs):
        return {}


class RepositoryTests(unittest.TestCase):
    def test_llm_audit_is_stored_without_raw_prompt_or_float(self) -> None:
        table = Table(); repository = DynamoRepository(table)
        response = {"decision": "ALLOW", "reason_code": "APPROVED"}
        audit = {
            "llm_provider": "openai", "llm_model": "test-model",
            "llm_prompt_version": "trade-filter-v1", "llm_confidence": 0.8,
            "llm_reason": "No anomaly.", "llm_request_time": "2025-06-15T15:06:40Z",
            "llm_response_time": "2025-06-15T15:06:41Z", "llm_decision": "ALLOW",
        }
        repository.save_decision("id", "a" * 64, response, 123, audit)
        item = table.items[0]
        self.assertEqual(Decimal("0.8"), item["audit_llm_confidence"])
        self.assertNotIn("prompt", item)
        self.assertNotIn("provider_response", item)
        self.assertEqual("openai", item["audit_llm_provider"])


if __name__ == "__main__":
    unittest.main()
