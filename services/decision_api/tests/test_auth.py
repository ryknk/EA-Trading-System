import unittest
import uuid

from decision_api.auth import verify_request
from decision_api.errors import ApiError
from support import FakeSecrets, MemoryRepository, NOW, raw_request, request_dict, signed_headers


class AuthTests(unittest.TestCase):
    def setUp(self) -> None:
        self.raw = raw_request()
        self.request_id = request_dict()["request_id"]

    def test_accepts_mql5_canonical_signature(self) -> None:
        request = request_dict(); self.raw = raw_request(request)
        context = verify_request(signed_headers(self.raw, request["request_id"]), self.raw,
                                 FakeSecrets(), MemoryRepository(), NOW)
        self.assertEqual(64, len(context.body_hash))

    def test_rejects_bad_signature_and_expired_timestamp(self) -> None:
        request = request_dict(); raw = raw_request(request)
        bad = signed_headers(raw, request["request_id"]); bad["X-EA-Signature"] = "0" * 64
        for headers, code in ((bad, "AUTHENTICATION_FAILED"),
                              (signed_headers(raw, request["request_id"], NOW - 61), "REQUEST_TIMESTAMP_EXPIRED")):
            with self.subTest(code=code), self.assertRaises(ApiError) as raised:
                verify_request(headers, raw, FakeSecrets(), MemoryRepository(), NOW)
            self.assertEqual(code, raised.exception.code)

    def test_rejects_replayed_nonce(self) -> None:
        request = request_dict(); raw = raw_request(request); nonce = str(uuid.uuid4())
        headers = signed_headers(raw, request["request_id"], nonce=nonce)
        store = MemoryRepository()
        verify_request(headers, raw, FakeSecrets(), store, NOW)
        with self.assertRaises(ApiError) as raised:
            verify_request(headers, raw, FakeSecrets(), store, NOW)
        self.assertEqual("REPLAY_DETECTED", raised.exception.code)

    def test_rejects_missing_headers(self) -> None:
        with self.assertRaises(ApiError) as raised:
            verify_request({}, self.raw, FakeSecrets(), MemoryRepository(), NOW)
        self.assertEqual("AUTH_HEADERS_MISSING", raised.exception.code)


if __name__ == "__main__":
    unittest.main()

