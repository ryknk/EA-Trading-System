from dataclasses import dataclass


@dataclass(frozen=True)
class EnvironmentConfig:
    name: str
    log_retention_days: int
    point_in_time_recovery: bool
    retain_data: bool
    lambda_memory_mb: int = 256
    lambda_timeout_seconds: int = 5
    replay_alarm_count: int = 3
    log_level: str = "INFO"


ENVIRONMENTS = {
    "dev": EnvironmentConfig("dev", 14, False, False),
    "staging": EnvironmentConfig("staging", 30, True, True),
    "production": EnvironmentConfig("production", 90, True, True),
}


def environment_config(name: str) -> EnvironmentConfig:
    try:
        return ENVIRONMENTS[name]
    except KeyError as exc:
        raise ValueError("environment must be dev, staging, or production") from exc
