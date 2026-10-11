#property copyright "EA Trading System"
#property version   "1.13"
#property strict
#property description "Phase 12 production-gated EA with local Risk authority and auditable external filters."

// CoreEAは研究ビルドであり、研究計測（Entry/Breakout Timing比較）と外部連携（Decision API・ML/LLM、Telemetry、
// Heartbeat、Tester判断Mock）を含める。既存のStrategy Testerテンプレート・CaseFileの挙動を変えないため。
// 販売・試験運用に使う製品ビルドはProductEA.mq5である（DECISIONS.md DEC-045・DEC-046）。
#define EA_TRADING_SYSTEM_RESEARCH_BUILD
#include <EaTradingSystem/Core/EAEntryPoint.mqh>
