from __future__ import annotations

import json
import math
import os
import time
from typing import Any, Mapping

MetricValue = tuple[float | int, str]
ALLOWED_UNITS = {"Count", "Milliseconds"}


def emit_emf(service: str, metrics: Mapping[str, MetricValue], properties: Mapping[str, Any] | None = None) -> None:
    """1 invocation分のEMFを出力する。監視障害をAPI処理へ波及させない。"""
    try:
        if os.environ.get("METRICS_ENABLED", "true").lower() not in {"1", "true", "yes"}:
            return
        environment = os.environ.get("ENVIRONMENT", "unknown")
        namespace = os.environ.get("METRIC_NAMESPACE", "EaTradingSystem")
        if not service or not environment or not namespace:
            return
        definitions: list[dict[str, str]] = []
        payload: dict[str, Any] = {
            "Environment": environment,
            "Service": service,
        }
        for name, (value, unit) in metrics.items():
            numeric = float(value)
            if (not name.replace("_", "").isalnum() or unit not in ALLOWED_UNITS
                    or not math.isfinite(numeric) or numeric < 0):
                continue
            definitions.append({"Name": name, "Unit": unit})
            payload[name] = value
        if not definitions:
            return
        for key, value in (properties or {}).items():
            if (key not in payload and key != "_aws" and isinstance(value, (str, int, float, bool))
                    and not (isinstance(value, float) and not math.isfinite(value))):
                payload[key] = value
        payload["_aws"] = {
            "Timestamp": int(time.time() * 1000),
            "CloudWatchMetrics": [{
                "Namespace": namespace,
                "Dimensions": [["Environment", "Service"]],
                "Metrics": definitions,
            }],
        }
        print(json.dumps(payload, separators=(",", ":"), ensure_ascii=True), flush=True)
    except Exception:
        # Monitoring is best-effort and must never change ALLOW/VETO or telemetry responses.
        return
