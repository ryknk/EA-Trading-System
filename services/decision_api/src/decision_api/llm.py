from __future__ import annotations

import json
import math
import re
import urllib.error
import urllib.request
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Protocol

MAX_PROVIDER_RESPONSE_BYTES = 65_536
DECISION_FIELDS = {"decision", "confidence", "reason"}
SAFE_ID_RE = re.compile(r"^[A-Za-z0-9._-]+$")


def _iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


@dataclass(frozen=True)
class LlmDecision:
    decision: str
    confidence: float
    reason: str
    provider: str
    model: str
    prompt_version: str
    request_time: str
    response_time: str


class LlmDecisionProvider(Protocol):
    @property
    def provider_name(self) -> str: ...
    @property
    def model_name(self) -> str: ...
    @property
    def prompt_version(self) -> str: ...
    def decide(self, request: dict[str, Any], ml: dict[str, Any]) -> LlmDecision: ...


class ApiKeyProvider(Protocol):
    def get_api_key(self) -> str: ...


class HttpTransport(Protocol):
    def post(self, url: str, headers: dict[str, str], body: bytes, timeout_seconds: float) -> bytes: ...


class UnavailableLlmProvider:
    @property
    def provider_name(self) -> str:
        return "unavailable"

    @property
    def model_name(self) -> str:
        return "not-configured"

    @property
    def prompt_version(self) -> str:
        return "not-configured"

    def decide(self, request: dict[str, Any], ml: dict[str, Any]) -> LlmDecision:
        raise RuntimeError("LLM provider is unavailable")


class UrllibTransport:
    def post(self, url: str, headers: dict[str, str], body: bytes, timeout_seconds: float) -> bytes:
        request = urllib.request.Request(url, data=body, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
                raw = response.read(MAX_PROVIDER_RESPONSE_BYTES + 1)
        except urllib.error.HTTPError as exc:
            raise RuntimeError(f"provider HTTP status {exc.code}") from exc
        except (urllib.error.URLError, TimeoutError) as exc:
            raise RuntimeError("provider transport failed") from exc
        if not raw or len(raw) > MAX_PROVIDER_RESPONSE_BYTES:
            raise RuntimeError("provider response is empty or too large")
        return raw


def _strict_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON field: {key}")
        result[key] = value
    return result


def parse_llm_decision(raw_text: str) -> tuple[str, float, str]:
    if not isinstance(raw_text, str) or not raw_text or len(raw_text.encode("utf-8")) > 2_048:
        raise ValueError("LLM decision text is empty or too large")
    try:
        value = json.loads(
            raw_text, object_pairs_hook=_strict_object,
            parse_constant=lambda token: (_ for _ in ()).throw(ValueError(token)),
        )
    except json.JSONDecodeError as exc:
        raise ValueError("LLM decision is not strict JSON") from exc
    if not isinstance(value, dict) or set(value) != DECISION_FIELDS:
        raise ValueError("LLM decision fields do not match the contract")
    decision, confidence, reason = value["decision"], value["confidence"], value["reason"]
    if decision not in {"ALLOW", "VETO"}:
        raise ValueError("LLM decision is invalid")
    if isinstance(confidence, bool) or not isinstance(confidence, (int, float)):
        raise ValueError("LLM confidence is invalid")
    confidence = float(confidence)
    if not math.isfinite(confidence) or not 0.0 <= confidence <= 1.0:
        raise ValueError("LLM confidence is outside its range")
    if not isinstance(reason, str) or not 1 <= len(reason) <= 512 or any(ord(char) < 32 for char in reason):
        raise ValueError("LLM reason is invalid")
    return decision, confidence, reason


def _extract_output_text(raw: bytes) -> str:
    try:
        response = json.loads(
            raw.decode("utf-8", errors="strict"), object_pairs_hook=_strict_object,
            parse_constant=lambda token: (_ for _ in ()).throw(ValueError(token)),
        )
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ValueError("provider response is invalid JSON") from exc
    if not isinstance(response, dict) or response.get("status") != "completed":
        raise ValueError("provider response is incomplete")
    texts: list[str] = []
    output = response.get("output")
    if not isinstance(output, list):
        raise ValueError("provider output is missing")
    for item in output:
        if not isinstance(item, dict) or item.get("type") != "message":
            continue
        content = item.get("content")
        if not isinstance(content, list):
            continue
        for part in content:
            if isinstance(part, dict) and part.get("type") == "output_text" and isinstance(part.get("text"), str):
                texts.append(part["text"])
            elif isinstance(part, dict) and part.get("type") == "refusal":
                raise ValueError("provider refused the request")
    if len(texts) != 1:
        raise ValueError("provider must return exactly one output text")
    return texts[0]


class OpenAiResponsesProvider:
    ENDPOINT = "https://api.openai.com/v1/responses"

    def __init__(self, api_key_provider: ApiKeyProvider, model: str, prompt_version: str,
                 transport: HttpTransport | None = None, timeout_seconds: float = 3.0,
                 temperature: float | None = 0.0) -> None:
        if not model or len(model) > 64 or not SAFE_ID_RE.fullmatch(model):
            raise ValueError("OpenAI model is invalid")
        if not prompt_version or len(prompt_version) > 32 or not SAFE_ID_RE.fullmatch(prompt_version):
            raise ValueError("prompt version is invalid")
        if not 0.1 <= timeout_seconds <= 4.0:
            raise ValueError("LLM timeout is invalid")
        if temperature is not None and (not math.isfinite(temperature) or not 0.0 <= temperature <= 2.0):
            raise ValueError("LLM temperature is invalid")
        self._keys = api_key_provider
        self._model = model
        self._prompt_version = prompt_version
        self._transport = transport or UrllibTransport()
        self._timeout_seconds = timeout_seconds
        self._temperature = temperature

    @property
    def provider_name(self) -> str:
        return "openai"

    @property
    def model_name(self) -> str:
        return self._model

    @property
    def prompt_version(self) -> str:
        return self._prompt_version

    def _market_context(self, request: dict[str, Any], ml: dict[str, Any]) -> dict[str, Any]:
        market, proposal = request["market_features"], request["trade_proposal"]
        price = float(market["current_price"])
        entry = float(proposal["entry_price"])
        return {
            "context_schema_version": "1.0",
            "observed_at": market["observed_at"],
            "symbol": request["symbol"], "timeframe": request["timeframe"],
            "fixed_direction": request["direction"],
            "market": {
                "spread_points": market["spread_points"], "rsi": market["rsi"],
                "atr_ratio": float(market["atr"]) / price,
                "ema_distance_ratio": market["ema_distance_ratio"],
                "recent_return": market["recent_return"], "volatility": market["volatility"],
                "hour": market["hour"], "day_of_week": market["day_of_week"],
            },
            "proposal": {
                "risk_reward_ratio": proposal["risk_reward_ratio"],
                "stop_distance_ratio": abs(entry - float(proposal["stop_loss"])) / entry,
                "take_distance_ratio": abs(float(proposal["take_profit"]) - entry) / entry,
            },
            "ml": {
                "win_probability": ml["win_probability"],
                "expected_return": ml["expected_return"],
                "model_version": ml["model_version"],
            },
        }

    def decide(self, request: dict[str, Any], ml: dict[str, Any]) -> LlmDecision:
        api_key = self._keys.get_api_key()
        if not isinstance(api_key, str) or not 20 <= len(api_key) <= 512:
            raise ValueError("OpenAI API key is invalid")
        context = self._market_context(request, ml)
        schema = {
            "type": "object", "additionalProperties": False,
            "required": ["decision", "confidence", "reason"],
            "properties": {
                "decision": {"type": "string", "enum": ["ALLOW", "VETO"]},
                "confidence": {"type": "number", "minimum": 0, "maximum": 1},
                "reason": {"type": "string", "minLength": 1, "maxLength": 512},
            },
        }
        body = {
            "model": self._model,
            "instructions": (
                "You are a conservative anomaly filter for an automated trading candidate. "
                "The EA has already fixed the BUY or SELL direction; never choose or change direction. "
                "Return ALLOW or VETO only through the required JSON schema. VETO only for material "
                "inconsistency, abnormality, or uncertainty visible in the supplied structured values. "
                "Do not claim knowledge of news or external facts not supplied. Do not provide hidden reasoning; "
                "give one brief factual reason. Confidence never changes position size."
            ),
            "input": json.dumps(context, separators=(",", ":"), ensure_ascii=True),
            "max_output_tokens": 160,
            "text": {"format": {
                "type": "json_schema", "name": "trade_filter_decision",
                "strict": True, "schema": schema,
            }},
        }
        if self._temperature is not None:
            body["temperature"] = self._temperature
        request_time = _iso_now()
        raw = self._transport.post(
            self.ENDPOINT,
            {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json",
             "User-Agent": "ea-trading-system/1.0"},
            json.dumps(body, separators=(",", ":"), ensure_ascii=True).encode("utf-8"),
            self._timeout_seconds,
        )
        response_time = _iso_now()
        decision, confidence, reason = parse_llm_decision(_extract_output_text(raw))
        return LlmDecision(decision, confidence, reason, self.provider_name, self._model,
                           self._prompt_version, request_time, response_time)
