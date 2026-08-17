from __future__ import annotations

import hashlib
import hmac
import json
import uuid
from copy import deepcopy

from decision_api.errors import ConditionalWriteFailed

NOW = 1_750_000_000
SECRET = "0123456789abcdef0123456789abcdef"
KEY_ID = "trend-ea-dev"


def request_dict() -> dict:
    return {
        "schema_version": "1.0",
        "request_id": str(uuid.uuid4()),
        "trade_candidate_id": "trend-ea-v1-USDJPY-1750000000",
        "ea_id": "trend-ea-v1",
        "timestamp": "2025-06-15T15:06:40Z",
        "symbol": "USDJPY",
        "timeframe": "H1",
        "direction": "BUY",
        "strategy": {
            "pattern": "BREAKOUT", "reason_code": "TREND_BREAKOUT",
            "reason": "Daily and H4 trends align with the H1 breakout.",
        },
        "market_features": {
            "feature_schema_version": "1.0", "observed_at": "2025-06-15T15:00:00Z",
            "current_price": 145.2, "spread_points": 12.0, "rsi": 58.0,
            "atr": 0.8, "ema50": 145.0, "ema200": 143.0,
            "ema_distance_ratio": 0.0139, "recent_return": 0.002,
            "volatility": 0.006, "hour": 15, "day_of_week": 0,
        },
        "trade_proposal": {
            "entry_price": 145.2, "stop_loss": 144.4,
            "take_profit": 146.8, "risk_reward_ratio": 2.0,
        },
    }


def raw_request(request: dict | None = None) -> bytes:
    return json.dumps(request or request_dict(), separators=(",", ":")).encode()


def signed_headers(raw: bytes, request_id: str, timestamp: int = NOW,
                   nonce: str | None = None, secret: str = SECRET,
                   canonical_path: str = "/v1/trade-decisions") -> dict[str, str]:
    nonce = nonce or str(uuid.uuid4())
    body_hash = hashlib.sha256(raw).hexdigest()
    canonical = f"POST\n{canonical_path}\n{timestamp}\n{nonce}\n{body_hash}"
    signature = hmac.new(secret.encode(), canonical.encode(), hashlib.sha256).hexdigest()
    return {
        "Content-Type": "application/json", "X-EA-Key-Id": KEY_ID,
        "X-EA-Timestamp": str(timestamp), "X-EA-Nonce": nonce,
        "X-EA-Signature": signature, "Idempotency-Key": request_id,
    }


class FakeSecrets:
    def get_secret(self, key_id: str) -> str:
        if key_id != KEY_ID:
            raise KeyError(key_id)
        return SECRET


class MemoryRepository:
    def __init__(self) -> None:
        self.nonces: set[tuple[str, str]] = set()
        self.decisions: dict[str, dict] = {}
        self.audits: dict[str, dict] = {}
        self.events: dict[tuple[str, str, str], dict] = {}

    def claim_nonce(self, key_id: str, nonce: str, expires_epoch: int) -> None:
        key = (key_id, nonce)
        if key in self.nonces:
            raise ConditionalWriteFailed()
        self.nonces.add(key)

    def get_decision(self, request_id: str) -> dict | None:
        value = self.decisions.get(request_id)
        return deepcopy(value) if value else None

    def save_decision(self, request_id: str, body_hash: str, response: dict, ttl: int,
                      audit: dict | None = None) -> None:
        if request_id in self.decisions:
            raise ConditionalWriteFailed()
        self.decisions[request_id] = {"body_hash": body_hash, "response": deepcopy(response)}
        if audit:
            self.audits[request_id] = deepcopy(audit)

    def save_trade_event(self, source_id: str, event: dict, body_hash: str) -> bool:
        key = (source_id, event["timestamp"], event["event_id"])
        if key in self.events:
            if self.events[key]["body_hash"] != body_hash:
                raise ConditionalWriteFailed()
            return False
        self.events[key] = {"body_hash": body_hash, "event": deepcopy(event)}
        return True


def trade_event(event_type: str = "RISK_DECISION") -> dict:
    payloads = {
        "CANDIDATE": {
            "direction": "BUY", "pattern": "BREAKOUT", "entry_price": 145.2,
            "stop_loss": 144.4, "take_profit": 146.8, "risk_reward_ratio": 2.0,
            "reason_code": "TREND_BREAKOUT", "reason": "Trend and breakout align.",
        },
        "EXTERNAL_DECISION": {
            "decision": "ALLOW", "reason_code": "APPROVED", "ml_status": "PASSED",
            "ml_win_probability": 0.7, "ml_expected_return": 0.002,
            "ml_model_version": "baseline-v1", "llm_status": "ALLOW",
            "llm_provider": "openai", "llm_model": "test-model",
            "llm_prompt_version": "trade-filter-v1", "llm_confidence": 0.8,
            "llm_reason": "No material anomaly.",
        },
        "RISK_DECISION": {
            "status": "APPROVED", "reason_code": "RISK_APPROVED", "reason": "Risk limits passed.",
            "volume": 0.1, "risk_budget": 5000.0, "estimated_stop_loss": 4900.0,
            "required_margin": 10000.0, "daily_loss_rate": 0.002, "drawdown_rate": 0.01,
        },
        "ORDER_SUBMISSION": {
            "status": "ACCEPTED", "reason_code": "ORDER_ACCEPTED", "reason": "Request accepted.",
            "order_ticket": "123", "deal_ticket": "456", "broker_retcode": 10009,
            "requested_price": 145.2, "confirmed_price": 145.21,
            "requested_volume": 0.1, "confirmed_volume": 0.1, "slippage_points": 1.0,
        },
        "DEAL": {
            "deal_ticket": "456", "order_ticket": "123", "position_ticket": "789",
            "entry": "IN", "price": 145.21, "volume": 0.1, "pnl": 0.0,
        },
        "POSITION_SNAPSHOT": {
            "position_ticket": "789", "direction": "BUY", "volume": 0.1,
            "open_price": 145.21, "current_price": 145.30, "stop_loss": 144.70,
            "take_profit": 146.20, "unrealized_pnl": 900.0,
        },
        "TRADE_CLOSED": {
            "position_ticket": "789", "direction": "BUY",
            "open_time": "2025-06-15T15:06:40Z", "close_time": "2025-06-16T02:00:00Z",
            "volume": 0.1, "open_price": 145.21, "close_price": 146.00,
            "close_reason": "TP", "pnl": 7900.0, "commission": -100.0, "swap": -20.0,
        },
        "ACCOUNT_SNAPSHOT": {
            "balance": 1000000.0, "equity": 1000100.0, "margin": 10000.0,
            "free_margin": 990100.0, "margin_level": 10001.0, "open_positions": 1,
        },
        "SYSTEM_ERROR": {"component": "TELEMETRY", "reason_code": "UPLOAD_FAILED", "reason": "Upload failed."},
    }
    return {
        "schema_version": "1.0", "event_id": str(uuid.uuid4()),
        "trade_candidate_id": "trend-ea-v1-USDJPY-1750000000", "request_id": "",
        "ea_id": "trend-ea-v1", "timestamp": "2025-06-15T15:06:40Z",
        "event_type": event_type, "symbol": "USDJPY", "payload": payloads[event_type],
    }


def model_artifact() -> dict:
    feature_count = 15
    return {
        "schema_version": "1.0", "feature_schema_version": "1.0",
        "model_version": "baseline-v1", "model_type": "linear_logistic_ridge_v1",
        "symbol": "USDJPY", "timeframe": "H1",
        "feature_names": [
            "direction", "rsi", "atr_ratio", "ema_distance_ratio",
            "directional_ema_distance", "recent_return", "volatility",
            "spread_points", "hour_sin", "hour_cos", "day_sin", "day_cos",
            "risk_reward_ratio", "stop_distance_ratio", "take_distance_ratio",
        ],
        "mean": [0.0] * feature_count, "scale": [1.0] * feature_count,
        "win_coefficients": [0.0] * feature_count, "win_intercept": 0.0,
        "calibration_coefficient": 1.0, "calibration_intercept": 0.0,
        "return_coefficients": [0.0] * feature_count, "return_intercept": 0.001,
    }
