"""バックテスト・フォワードテスト共通の分析基盤。"""

from .performance import PerformanceMetrics, analyze_performance, normalize_closed_trades

__all__ = ["PerformanceMetrics", "analyze_performance", "normalize_closed_trades"]
