from __future__ import annotations

import hashlib
import hmac
import re
import time
import uuid
from dataclasses import dataclass
from typing import Mapping, Protocol

from .errors import ApiError, ConditionalWriteFailed

KEY_ID_RE = re.compile(r"^[A-Za-z0-9._-]{1,64}$")
SIGNATURE_RE = re.compile(r"^[0-9a-f]{64}$")


class SecretProvider(Protocol):
    def get_secret(self, key_id: str) -> str: ...


class ReplayStore(Protocol):
    def claim_nonce(self, key_id: str, nonce: str, expires_epoch: int) -> None: ...


@dataclass(frozen=True)
class AuthContext:
    key_id: str
    timestamp: int
    nonce: str
    body_hash: str


def _headers(headers: Mapping[str, str] | None) -> dict[str, str]:
    return {str(k).lower(): str(v).strip() for k, v in (headers or {}).items()}


def verify_request(headers: Mapping[str, str] | None, raw_body: bytes,
                   secret_provider: SecretProvider, replay_store: ReplayStore,
                   now_epoch: int | None = None, max_clock_skew_seconds: int = 60,
                   canonical_path: str = "/v1/trade-decisions") -> AuthContext:
    values = _headers(headers)
    required = ("x-ea-key-id", "x-ea-timestamp", "x-ea-nonce", "x-ea-signature", "idempotency-key")
    if any(not values.get(name) for name in required):
        raise ApiError(401, "AUTH_HEADERS_MISSING", "required authentication headers are missing")

    key_id = values["x-ea-key-id"]
    nonce = values["x-ea-nonce"].lower()
    signature = values["x-ea-signature"]
    if not KEY_ID_RE.fullmatch(key_id):
        raise ApiError(401, "INVALID_KEY_ID", "key id is invalid")
    try:
        parsed_nonce = uuid.UUID(nonce)
        timestamp = int(values["x-ea-timestamp"])
    except ValueError as exc:
        raise ApiError(401, "INVALID_AUTH_FORMAT", "timestamp or nonce is invalid") from exc
    if str(parsed_nonce) != nonce or parsed_nonce.version != 4 or not SIGNATURE_RE.fullmatch(signature):
        raise ApiError(401, "INVALID_AUTH_FORMAT", "nonce or signature is invalid")

    now = int(time.time()) if now_epoch is None else now_epoch
    if abs(now - timestamp) > max_clock_skew_seconds:
        raise ApiError(401, "REQUEST_TIMESTAMP_EXPIRED", "request timestamp is outside the allowed window")

    body_hash = hashlib.sha256(raw_body).hexdigest()
    if canonical_path not in {"/v1/trade-decisions", "/v1/trade-events"}:
        raise ApiError(401, "INVALID_AUTH_PATH", "signed path is invalid")
    canonical = f"POST\n{canonical_path}\n{timestamp}\n{nonce}\n{body_hash}"
    try:
        secret = secret_provider.get_secret(key_id)
    except Exception as exc:
        raise ApiError(401, "AUTHENTICATION_FAILED", "authentication failed") from exc
    expected = hmac.new(secret.encode("utf-8"), canonical.encode("utf-8"), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, signature):
        raise ApiError(401, "AUTHENTICATION_FAILED", "authentication failed")

    try:
        replay_store.claim_nonce(key_id, nonce, now + max_clock_skew_seconds * 2)
    except ConditionalWriteFailed as exc:
        raise ApiError(409, "REPLAY_DETECTED", "nonce has already been used") from exc
    return AuthContext(key_id, timestamp, nonce, body_hash)
