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
    # 通知先未設定のままAlarmだけが存在する状態を、staging・productionではsynth時に拒否する。
    require_alarm_email: bool = False
    # EAを常時稼働させない環境で誤報を出さないよう、devは既定無効（contextで有効化可能）。
    heartbeat_alarm_enabled: bool = False
    heartbeat_stale_minutes: int = 5
    secret_cache_ttl_seconds: int = 300
    # タイムアウト予算: LLM timeout + 予備 <= Decision deadline < EA WebRequest(既定4.5秒)
    #                  < API Gateway integration <= Lambda timeout
    decision_integration_timeout_ms: int = 5_000
    decision_deadline_seconds: float = 4.0
    llm_timeout_seconds: float = 3.0
    llm_deadline_reserve_seconds: float = 0.5


ENVIRONMENTS = {
    "dev": EnvironmentConfig("dev", 14, False, False),
    "staging": EnvironmentConfig("staging", 30, True, True, require_alarm_email=True, heartbeat_alarm_enabled=True),
    "production": EnvironmentConfig("production", 90, True, True, require_alarm_email=True, heartbeat_alarm_enabled=True),
}

# MQL5 CoreEAの既定InpDecisionApiTimeoutMs。サーバー側deadlineはこれより短くする。
EA_DECISION_TIMEOUT_MS = 4_500


def environment_config(name: str) -> EnvironmentConfig:
    try:
        return ENVIRONMENTS[name]
    except KeyError as exc:
        raise ValueError("environment must be dev, staging, or production") from exc


def validate_timeout_budget(config: EnvironmentConfig) -> None:
    """LLM遅延時もEA timeout前にVETOを返せる順序になっていることをsynth時に検証する。"""
    if not 0.1 <= config.llm_timeout_seconds <= 4.0 or config.llm_deadline_reserve_seconds <= 0:
        raise ValueError("LLM timeout budget is invalid")
    if config.llm_timeout_seconds + config.llm_deadline_reserve_seconds > config.decision_deadline_seconds:
        raise ValueError("LLM timeout plus reserve must fit within the decision deadline")
    if config.decision_deadline_seconds * 1000 >= EA_DECISION_TIMEOUT_MS:
        raise ValueError("decision deadline must be shorter than the EA WebRequest timeout")
    if EA_DECISION_TIMEOUT_MS >= config.decision_integration_timeout_ms:
        raise ValueError("EA WebRequest timeout must be shorter than the API Gateway integration timeout")
    if config.decision_integration_timeout_ms > config.lambda_timeout_seconds * 1000:
        raise ValueError("API Gateway integration timeout must not exceed the Lambda timeout")
