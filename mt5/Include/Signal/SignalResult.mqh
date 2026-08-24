#ifndef EA_TRADING_SYSTEM_SIGNAL_RESULT_MQH
#define EA_TRADING_SYSTEM_SIGNAL_RESULT_MQH

#include <EaTradingSystem/Filter/MarketRegimeClassifier.mqh>

enum ESignalStatus
  {
   SIGNAL_STATUS_NONE=0,
   SIGNAL_STATUS_CANDIDATE=1,
   SIGNAL_STATUS_ERROR=2
  };

enum ESignalDirection
  {
   SIGNAL_DIRECTION_NONE=0,
   SIGNAL_DIRECTION_BUY=1,
   SIGNAL_DIRECTION_SELL=-1
  };

enum EEntryPattern
  {
   ENTRY_PATTERN_NONE=0,
   ENTRY_PATTERN_BREAKOUT=1,
   ENTRY_PATTERN_PULLBACK=2,
   ENTRY_PATTERN_MEAN_REVERSION=3
  };

struct SSignalResult
  {
   ESignalStatus      status;
   ESignalDirection   direction;
   EEntryPattern      entry_pattern;
   string             trade_candidate_id;
   string             symbol;
   ENUM_TIMEFRAMES    timeframe;
   datetime           signal_bar_time;
   double             entry_price;
   double             stop_loss;
   double             take_profit;
   double             risk_reward_ratio;
   double             rsi;
   double             atr;
   double             adx;
   double             ema_fast;
   double             ema_slow;
   double             ema_distance_ratio;
   double             recent_return;
   double             volatility;
   int                hour;
   int                day_of_week;
   EMarketRegimeTrend       market_regime_trend;
   EMarketRegimeVolatility  market_regime_volatility;
   string             reason_code;
   string             reason;
   // 段階的Entry判定パイプライン（InpEntryUseStagedPipeline有効時のみ意味を持つ）専用の診断フィールド。
   // Market Regime -> HTF Bias -> Setup -> Entry Triggerの各段階の合否をログ・分析用に個別保持する。
   // 既存のstatus/direction/entry_pattern/reason_code/reasonによる最終判定には一切影響しない。
   bool               staged_pipeline_used;
   string             stage_market_regime;
   bool               stage_market_regime_passed;
   string             stage_htf_bias;
   bool               stage_htf_bias_passed;
   bool               stage_breakout_setup_passed;
   bool               stage_breakout_trigger_passed;
   bool               stage_pullback_setup_passed;
   bool               stage_pullback_trigger_passed;
  };

void ResetSignalResult(SSignalResult &result)
  {
   ZeroMemory(result);
   result.status=SIGNAL_STATUS_NONE;
   result.direction=SIGNAL_DIRECTION_NONE;
   result.entry_pattern=ENTRY_PATTERN_NONE;
   result.market_regime_trend=MARKET_REGIME_TREND_UNKNOWN;
   result.market_regime_volatility=MARKET_REGIME_VOLATILITY_UNKNOWN;
   result.reason_code="NO_SIGNAL";
   result.staged_pipeline_used=false;
   result.stage_market_regime="NotEvaluated";
   result.stage_htf_bias="NONE";
  }

string SignalDirectionToString(const ESignalDirection direction)
  {
   if(direction==SIGNAL_DIRECTION_BUY) return "BUY";
   if(direction==SIGNAL_DIRECTION_SELL) return "SELL";
   return "NONE";
  }

string EntryPatternToString(const EEntryPattern pattern)
  {
   if(pattern==ENTRY_PATTERN_BREAKOUT) return "BREAKOUT";
   if(pattern==ENTRY_PATTERN_PULLBACK) return "PULLBACK";
   if(pattern==ENTRY_PATTERN_MEAN_REVERSION) return "MEAN_REVERSION";
   return "NONE";
  }

#endif
