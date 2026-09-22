from __future__ import annotations

import json
import re
from dataclasses import dataclass, field, replace
from datetime import date
from pathlib import Path
from typing import Any

from .chunks import CHUNK_UNITS
from .timeutil import ServerTimeRule, parse_date

_SYMBOL_PATTERN = re.compile(r"^[A-Za-z0-9._-]{1,32}$")


class ConfigError(ValueError):
    """設定不正。CLIではexit code 2へ対応させる。"""


@dataclass(frozen=True)
class RetryPolicy:
    max_attempts: int = 4
    initial_backoff_seconds: float = 2.0
    max_backoff_seconds: float = 60.0
    timeout_seconds: int = 600

    def backoff_seconds(self, failed_attempts: int) -> float:
        return min(self.initial_backoff_seconds * (2 ** (failed_attempts - 1)), self.max_backoff_seconds)


@dataclass(frozen=True)
class ValidationPolicy:
    max_gap_seconds: int = 4 * 3600
    max_price_jump_ratio: float = 0.05
    max_rejected_ratio: float = 0.001


@dataclass(frozen=True)
class Mt5Target:
    source_symbol: str = ""
    custom_symbol: str = ""
    custom_path: str = "EaTradingSystem\\History"


@dataclass(frozen=True)
class DatasetConfig:
    provider: str
    symbol: str
    from_date: date
    to_date: date
    timezone: str = "UTC"
    chunk_unit: str = "day"
    storage_root: Path = Path("tick/pipeline")
    provider_options: dict[str, Any] = field(default_factory=dict)
    retry: RetryPolicy = field(default_factory=RetryPolicy)
    validation: ValidationPolicy = field(default_factory=ValidationPolicy)
    server_time: dict[str, Any] | None = None
    mt5: Mt5Target = field(default_factory=Mt5Target)

    @property
    def dataset_id(self) -> str:
        return f"{self.provider}-{self.symbol}-{self.from_date:%Y%m%d}-{self.to_date:%Y%m%d}"

    @property
    def dataset_dir(self) -> Path:
        return self.storage_root / self.dataset_id

    def server_time_rule(self) -> ServerTimeRule:
        return ServerTimeRule.from_config(self.server_time)


def _known_keys(section: dict[str, Any], allowed: set[str], name: str) -> None:
    unknown = set(section) - allowed
    if unknown:
        raise ConfigError(f"{name}に未知のキーがあります: {sorted(unknown)}")


def load_config(path: Path | None, overrides: dict[str, Any] | None = None) -> DatasetConfig:
    """JSON設定ファイルとCLI上書きからDatasetConfigを作る。秘密情報は設定へ持たせない。"""
    raw: dict[str, Any] = {}
    if path is not None:
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as error:
            raise ConfigError(f"設定ファイルを読み込めません: {path}: {error}") from error
    for key, value in (overrides or {}).items():
        if value is None:
            continue
        raw[key] = {**raw[key], **value} if isinstance(value, dict) and isinstance(raw.get(key), dict) else value

    _known_keys(
        raw,
        {"provider", "symbol", "from", "to", "timezone", "chunk_unit", "storage_root",
         "provider_options", "retry", "validation", "server_time", "mt5", "_comment"},
        "設定",
    )
    for required in ("provider", "symbol", "from", "to"):
        if not raw.get(required):
            raise ConfigError(f"設定に{required}が必要です。")

    symbol = str(raw["symbol"]).strip()
    if not _SYMBOL_PATTERN.match(symbol):
        raise ConfigError(f"symbolに使えない文字が含まれています: {symbol!r}")
    try:
        from_date, to_date = parse_date(str(raw["from"])), parse_date(str(raw["to"]))
    except ValueError as error:
        raise ConfigError(str(error)) from error
    if to_date < from_date:
        raise ConfigError(f"toがfromより前です: from={from_date} to={to_date}")

    chunk_unit = str(raw.get("chunk_unit", "day"))
    if chunk_unit not in CHUNK_UNITS:
        raise ConfigError(f"chunk_unitはday・monthのいずれかです: {chunk_unit!r}")
    timezone = str(raw.get("timezone", "UTC"))
    if timezone.upper() != "UTC":
        raise ConfigError("timezoneは現在UTCのみ対応です（Provider側でUTCへ揃えること）。")

    retry_raw = dict(raw.get("retry", {}))
    validation_raw = dict(raw.get("validation", {}))
    mt5_raw = dict(raw.get("mt5", {}))
    _known_keys(retry_raw, set(RetryPolicy.__dataclass_fields__), "retry")
    _known_keys(validation_raw, set(ValidationPolicy.__dataclass_fields__), "validation")
    _known_keys(mt5_raw, set(Mt5Target.__dataclass_fields__), "mt5")

    retry = RetryPolicy(**retry_raw)
    if retry.max_attempts < 1 or retry.timeout_seconds < 1:
        raise ConfigError("retry.max_attemptsとretry.timeout_secondsは1以上にしてください。")

    mt5 = Mt5Target(**{"source_symbol": symbol, **mt5_raw})
    return DatasetConfig(
        provider=str(raw["provider"]).lower(),
        symbol=symbol.upper(),
        from_date=from_date,
        to_date=to_date,
        timezone="UTC",
        chunk_unit=chunk_unit,
        storage_root=Path(raw.get("storage_root", "tick/pipeline")),
        provider_options=dict(raw.get("provider_options", {})),
        retry=retry,
        validation=ValidationPolicy(**validation_raw),
        server_time=raw.get("server_time"),
        mt5=replace(mt5, source_symbol=mt5.source_symbol.upper()),
    )
