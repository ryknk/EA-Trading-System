import unittest
from dataclasses import replace

from config import environment_config, validate_timeout_budget


class EnvironmentConfigTests(unittest.TestCase):
    def test_environment_isolated_retention_and_safety(self) -> None:
        self.assertEqual(14, environment_config("dev").log_retention_days)
        self.assertFalse(environment_config("dev").retain_data)
        self.assertEqual(90, environment_config("production").log_retention_days)
        self.assertTrue(environment_config("production").point_in_time_recovery)
        self.assertTrue(environment_config("production").retain_data)

    def test_production_requires_notification_and_heartbeat_monitoring(self) -> None:
        self.assertFalse(environment_config("dev").require_alarm_email)
        self.assertFalse(environment_config("dev").heartbeat_alarm_enabled)
        for name in ("staging", "production"):
            self.assertTrue(environment_config(name).require_alarm_email)
            self.assertTrue(environment_config(name).heartbeat_alarm_enabled)

    def test_timeout_budget_keeps_llm_inside_ea_timeout(self) -> None:
        for name in ("dev", "staging", "production"):
            validate_timeout_budget(environment_config(name))
        base = environment_config("dev")
        for broken in (
            replace(base, llm_timeout_seconds=3.8),
            replace(base, decision_deadline_seconds=4.5),
            replace(base, decision_integration_timeout_ms=4_500),
            replace(base, lambda_timeout_seconds=4),
        ):
            with self.assertRaises(ValueError):
                validate_timeout_budget(broken)

    def test_unknown_environment_is_rejected(self) -> None:
        with self.assertRaises(ValueError):
            environment_config("local")


if __name__ == "__main__":
    unittest.main()

