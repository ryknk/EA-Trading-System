from __future__ import annotations

from typing import Callable

from ..config import DatasetConfig
from .base import ProviderError, TickProvider
from .csvfile import CsvFileProvider
from .dukascopy import DukascopyProvider
from .mock import MockProvider

_REGISTRY: dict[str, Callable[[DatasetConfig], TickProvider]] = {
    "dukascopy": DukascopyProvider,
    "csvfile": CsvFileProvider,
    "mock": MockProvider,
}


def register_provider(name: str, factory: Callable[[DatasetConfig], TickProvider]) -> None:
    """新しいデータソースのAdapterを追加する入口（後段は変更不要）。"""
    _REGISTRY[name.lower()] = factory


def create_provider(config: DatasetConfig) -> TickProvider:
    try:
        factory = _REGISTRY[config.provider]
    except KeyError as error:
        raise ProviderError(
            f"未対応のproviderです: {config.provider!r}（対応: {sorted(_REGISTRY)}）", retryable=False
        ) from error
    return factory(config)
