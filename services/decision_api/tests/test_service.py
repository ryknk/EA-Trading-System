import hashlib
import unittest
from datetime import datetime, timezone

from decision_api.errors import ApiError
from decision_api.ml import MlPrediction
from decision_api.llm import LlmDecision
from decision_api.service import DecisionService
from support import MemoryRepository, raw_request, request_dict


class FixedProvider:
    def __init__(self, prediction: MlPrediction) -> None:
        self.prediction = prediction

    @property
    def model_version(self) -> str:
        return self.prediction.model_version

    def predict(self, request: dict) -> MlPrediction:
        return self.prediction


class FixedLlmProvider:
    def __init__(self, decision: LlmDecision | None = None, error: Exception | None = None) -> None:
        self.decision = decision
        self.error = error
        self.calls = 0

    @property
    def provider_name(self) -> str: return "openai"
    @property
    def model_name(self) -> str: return "test-model"
    @property
    def prompt_version(self) -> str: return "trade-filter-v1"

    def decide(self, request: dict, ml: dict) -> LlmDecision:
        self.calls += 1
        if self.error:
            raise self.error
        assert self.decision is not None
        return self.decision


def llm_decision(decision: str = "ALLOW") -> LlmDecision:
    return LlmDecision(decision, 0.75, "Structured values are internally consistent.",
                       "openai", "test-model", "trade-filter-v1",
                       "2025-06-15T15:06:40Z", "2025-06-15T15:06:41Z")


class DecisionServiceTests(unittest.TestCase):
    def test_missing_ml_fails_safe(self) -> None:
        request = request_dict(); body_hash = hashlib.sha256(raw_request(request)).hexdigest()
        response = DecisionService(MemoryRepository()).decide(
            request, body_hash, datetime(2025, 6, 15, 15, 6, 40, tzinfo=timezone.utc))
        self.assertEqual("VETO", response["decision"])
        self.assertEqual("ML_INFERENCE_ERROR", response["reason_code"])
        self.assertEqual("ERROR", response["ml"]["status"])
        self.assertEqual("NOT_CALLED", response["llm"]["status"])
        self.assertEqual("2025-06-15T15:07:10Z", response["expires_at"])

    def test_ml_threshold_rejection_does_not_call_llm(self) -> None:
        provider = FixedProvider(MlPrediction(0.59, 0.01, "baseline-v1"))
        llm = FixedLlmProvider(llm_decision())
        request = request_dict(); body_hash = hashlib.sha256(raw_request(request)).hexdigest()
        response = DecisionService(MemoryRepository(), provider, llm).decide(request, body_hash)
        self.assertEqual("ML_THRESHOLD_NOT_MET", response["reason_code"])
        self.assertEqual("REJECTED", response["ml"]["status"])
        self.assertEqual("NOT_CALLED", response["llm"]["status"])
        self.assertEqual(0, llm.calls)

    def test_ml_and_llm_allow_produce_external_allow_and_audit(self) -> None:
        provider = FixedProvider(MlPrediction(0.70, 0.002, "baseline-v1"))
        llm = FixedLlmProvider(llm_decision("ALLOW")); repository = MemoryRepository()
        request = request_dict(); body_hash = hashlib.sha256(raw_request(request)).hexdigest()
        response = DecisionService(repository, provider, llm).decide(request, body_hash)
        self.assertEqual("ALLOW", response["decision"])
        self.assertEqual("APPROVED", response["reason_code"])
        self.assertEqual("PASSED", response["ml"]["status"])
        self.assertEqual("ALLOW", response["llm"]["status"])
        self.assertEqual("openai", repository.audits[request["request_id"]]["llm_provider"])

    def test_llm_veto_is_final(self) -> None:
        provider = FixedProvider(MlPrediction(0.70, 0.002, "baseline-v1"))
        request = request_dict(); body_hash = hashlib.sha256(raw_request(request)).hexdigest()
        response = DecisionService(MemoryRepository(), provider,
                                   FixedLlmProvider(llm_decision("VETO"))).decide(request, body_hash)
        self.assertEqual("VETO", response["decision"])
        self.assertEqual("LLM_VETO", response["reason_code"])

    def test_llm_shadow_records_veto_but_does_not_apply_it(self) -> None:
        provider = FixedProvider(MlPrediction(0.70, 0.002, "baseline-v1"))
        repository = MemoryRepository()
        request = request_dict(); body_hash = hashlib.sha256(raw_request(request)).hexdigest()
        response = DecisionService(
            repository, provider, FixedLlmProvider(llm_decision("VETO")),
            llm_shadow_mode=True,
        ).decide(request, body_hash)
        self.assertEqual("ALLOW", response["decision"])
        self.assertEqual("VETO", response["llm"]["status"])
        self.assertEqual("LLM_SHADOW_VETO_RECORDED", response["reason_code"])
        audit = repository.audits[request["request_id"]]
        self.assertTrue(audit["llm_shadow_mode"])
        self.assertFalse(audit["llm_applied"])

    def test_llm_error_remains_veto_in_shadow_mode(self) -> None:
        provider = FixedProvider(MlPrediction(0.70, 0.002, "baseline-v1"))
        request = request_dict(); body_hash = hashlib.sha256(raw_request(request)).hexdigest()
        response = DecisionService(
            MemoryRepository(), provider, FixedLlmProvider(error=TimeoutError("timeout")),
            llm_shadow_mode=True,
        ).decide(request, body_hash)
        self.assertEqual("VETO", response["decision"])
        self.assertEqual("LLM_INFERENCE_ERROR", response["reason_code"])

    def test_llm_error_and_invalid_output_fail_safe(self) -> None:
        provider = FixedProvider(MlPrediction(0.70, 0.002, "baseline-v1"))
        invalid = LlmDecision("BUY", 0.9, "Invalid direction decision.", "openai", "test-model",
                              "trade-filter-v1", "2025-06-15T15:06:40Z", "2025-06-15T15:06:41Z")
        for llm in (FixedLlmProvider(error=TimeoutError("timeout")), FixedLlmProvider(invalid)):
            request = request_dict(); body_hash = hashlib.sha256(raw_request(request)).hexdigest()
            response = DecisionService(MemoryRepository(), provider, llm).decide(request, body_hash)
            self.assertEqual("VETO", response["decision"])
            self.assertEqual("LLM_INFERENCE_ERROR", response["reason_code"])
            self.assertEqual("ERROR", response["llm"]["status"])

    def test_same_request_is_idempotent(self) -> None:
        repository = MemoryRepository(); service = DecisionService(repository)
        request = request_dict(); body_hash = hashlib.sha256(raw_request(request)).hexdigest()
        first = service.decide(request, body_hash); second = service.decide(request, body_hash)
        self.assertEqual(first, second)

    def test_same_request_id_with_different_body_is_rejected(self) -> None:
        repository = MemoryRepository(); service = DecisionService(repository)
        request = request_dict(); service.decide(request, "a" * 64)
        with self.assertRaises(ApiError) as raised:
            service.decide(request, "b" * 64)
        self.assertEqual("IDEMPOTENCY_CONFLICT", raised.exception.code)


if __name__ == "__main__":
    unittest.main()
