from __future__ import annotations

from typing import Any

import pandas as pd

from .performance import TRADE_COLUMNS, analyze_performance


def compare_llm_shadow(trades: pd.DataFrame, initial_balance: float) -> dict[str, Any]:
    """同じ決済履歴で、LLM未適用と記録済みVETO適用の反実仮想を比較する。"""
    if "llm_status" not in trades.columns:
        raise ValueError("llm_status column is required")
    if not trades["llm_status"].isin(["ALLOW", "VETO"]).all():
        raise ValueError("llm_status must be ALLOW or VETO")
    baseline = trades[TRADE_COLUMNS].copy()
    applied = trades.loc[trades["llm_status"] != "VETO", TRADE_COLUMNS].copy()
    baseline_metrics, _, _ = analyze_performance(baseline, initial_balance)
    applied_metrics, _, _ = analyze_performance(applied, initial_balance)
    return {
        "schema_version": "1.0",
        "mode_a_no_llm_filter": baseline_metrics.to_dict(),
        "mode_b_llm_veto_applied": applied_metrics.to_dict(),
        "vetoed_trade_count": int((trades["llm_status"] == "VETO").sum()),
        "warning": "観測ログの反実仮想比較であり、因果効果や統計的有意性を単独では証明しません。",
    }
