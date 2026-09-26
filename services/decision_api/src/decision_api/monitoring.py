from __future__ import annotations

import json
import math
import os
import re
import time
from typing import Any, Mapping

MetricValue = tuple[float | int, str]
ALLOWED_UNITS = {"Count", "Milliseconds"}
EXTRA_DIMENSION_NAMES = {"EaId"}
DIMENSION_VALUE_RE = re.compile(r"^[A-Za-z0-9._-]{1,64}$")


def emit_emf(service: str, metrics: Mapping[str, MetricValue], properties: Mapping[str, Any] | None = None,
             extra_dimensions: Mapping[str, str] | None = None) -> None:
    """1 invocation分のEMFを出力する。監視障害をAPI処理へ波及させない。

    extra_dimensionsは許可済みの低カーディナリティ名だけを受け付け、呼び出し側で値の集合を制限する。
    """
    try:
        dimension_values: dict[str, str] = {}
        for name, value in (extra_dimensions or {}).items():
            if name not in EXTRA_DIMENSION_NAMES or not isinstance(value, str) or not DIMENSION_VALUE_RE.fullmatch(value):
                return
            dimension_values[name] = value
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
            **dimension_values,
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
                "Dimensions": [["Environment", "Service", *dimension_values]],
                "Metrics": definitions,
            }],
        }
        print(json.dumps(payload, separators=(",", ":"), ensure_ascii=True), flush=True)
    except Exception:
        # Monitoring is best-effort and must never change ALLOW/VETO or telemetry responses.
        return
