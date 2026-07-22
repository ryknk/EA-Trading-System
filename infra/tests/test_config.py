import unittest

from config import environment_config


class EnvironmentConfigTests(unittest.TestCase):
    def test_environment_isolated_retention_and_safety(self) -> None:
        self.assertEqual(14, environment_config("dev").log_retention_days)
        self.assertFalse(environment_config("dev").retain_data)
        self.assertEqual(90, environment_config("production").log_retention_days)
        self.assertTrue(environment_config("production").point_in_time_recovery)
        self.assertTrue(environment_config("production").retain_data)

    def test_unknown_environment_is_rejected(self) -> None:
        with self.assertRaises(ValueError):
            environment_config("local")


if __name__ == "__main__":
    unittest.main()

