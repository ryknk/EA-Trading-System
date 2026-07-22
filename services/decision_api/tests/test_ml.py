import hashlib
import json
import unittest

from decision_api.ml import LinearJsonMlProvider, S3MlProvider, feature_vector
from support import model_artifact, request_dict


class Body:
    def __init__(self, raw: bytes) -> None:
        self.raw = raw

    def read(self, size: int) -> bytes:
        return self.raw[:size]


class S3:
    def __init__(self, raw: bytes) -> None:
        self.raw = raw

    def get_object(self, **kwargs):
        return {"Body": Body(self.raw)}


class MlRuntimeTests(unittest.TestCase):
    def test_feature_vector_and_linear_prediction(self) -> None:
        values = feature_vector(request_dict())
        self.assertEqual(15, len(values))
        provider = LinearJsonMlProvider(model_artifact())
        prediction = provider.predict(request_dict())
        self.assertAlmostEqual(0.5, prediction.win_probability)
        self.assertAlmostEqual(0.001, prediction.expected_return)

    def test_rejects_scope_feature_order_and_non_finite_artifact(self) -> None:
        scope = LinearJsonMlProvider(model_artifact())
        request = request_dict(); request["symbol"] = "EURUSD"
        with self.assertRaises(ValueError):
            scope.predict(request)
        wrong_order = model_artifact(); wrong_order["feature_names"][0] = "wrong"
        with self.assertRaises(ValueError):
            LinearJsonMlProvider(wrong_order)
        non_finite = model_artifact(); non_finite["win_intercept"] = float("nan")
        with self.assertRaises(ValueError):
            LinearJsonMlProvider(non_finite)

    def test_strict_json_rejects_duplicate_field(self) -> None:
        raw = b'{"schema_version":"1.0","schema_version":"1.0"}'
        with self.assertRaises(ValueError):
            LinearJsonMlProvider.from_bytes(raw)

    def test_s3_checksum_is_required_and_verified(self) -> None:
        raw = json.dumps(model_artifact(), separators=(",", ":")).encode()
        checksum = hashlib.sha256(raw).hexdigest()
        prediction = S3MlProvider(S3(raw), "bucket", "model.json", checksum).predict(request_dict())
        self.assertEqual("baseline-v1", prediction.model_version)
        with self.assertRaises(ValueError):
            S3MlProvider(S3(raw), "bucket", "model.json", "0" * 64).predict(request_dict())


if __name__ == "__main__":
    unittest.main()

