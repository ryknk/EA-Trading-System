#property copyright "EA Trading System"
#property version   "1.13"
#property strict
#property description "Product build: rule-based strategy with local Risk authority. No external services."

// 製品ビルド（販売・試験運用用）。EA_TRADING_SYSTEM_RESEARCH_BUILDを定義しないため、研究計測と外部連携
// （Decision API・ML/LLM、Telemetry、Heartbeat、Tester判断Mock）を含まず、MQL5だけで新規注文の判断まで完結する。
// 新規注文はローカルの戦略・フィルタ・Risk Manager・OrderCheckで判断する（DECISIONS.md DEC-046）。
#include <EaTradingSystem/Core/EAEntryPoint.mqh>
