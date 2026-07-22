import json
import math
import unittest

from decision_api.errors import ApiError
from decision_api.validation import parse_and_validate_request
from support import raw_request, request_dict


class ValidationTests(unittest.TestCase):
    def test_valid_request(self) -> None:
        parsed = parse_and_validate_request(raw_request())
        self.assertEqual("USDJPY", parsed["symbol"])

    def test_rejects_malformed_json_and_duplicate_keys(self) -> None:
        for raw in (b"{", b'{"schema_version":"1.0","schema_version":"1.0"}'):
            with self.subTest(raw=raw), self.assertRaises(ApiError) as raised:
                parse_and_validate_request(raw)
            self.assertEqual("INVALID_JSON", raised.exception.code)

    def test_rejects_unknown_and_missing_fields(self) -> None:
        for mutate in (lambda x: x.update({"unknown": 1}), lambda x: x.pop("symbol")):
            request = request_dict()
            mutate(request)
            with self.subTest(request=request), self.assertRaises(ApiError) as raised:
                parse_and_validate_request(raw_request(request))
            self.assertEqual("INVALID_REQUEST", raised.exception.code)

    def test_rejects_bool_nan_and_invalid_trade_geometry(self) -> None:
        cases = []
        boolean = request_dict(); boolean["market_features"]["rsi"] = True; cases.append(boolean)
        nan = request_dict(); nan["market_features"]["atr"] = math.nan; cases.append(nan)
        geometry = request_dict(); geometry["trade_proposal"]["stop_loss"] = 146; cases.append(geometry)
        for request in cases:
            with self.subTest(request=request), self.assertRaises(ApiError):
                parse_and_validate_request(json.dumps(request, allow_nan=True).encode())

    def test_rejects_oversized_body(self) -> None:
        with self.assertRaises(ApiError):
            parse_and_validate_request(b" " * 16_385)


if __name__ == "__main__":
    unittest.main()

