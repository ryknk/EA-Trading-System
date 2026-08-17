#ifndef EA_TRADING_SYSTEM_SIGNAL_RESULT_MQH
#define EA_TRADING_SYSTEM_SIGNAL_RESULT_MQH

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
   ENTRY_PATTERN_PULLBACK=2
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
   string             reason_code;
   string             reason;
  };

void ResetSignalResult(SSignalResult &result)
  {
   ZeroMemory(result);
   result.status=SIGNAL_STATUS_NONE;
   result.direction=SIGNAL_DIRECTION_NONE;
   result.entry_pattern=ENTRY_PATTERN_NONE;
   result.reason_code="NO_SIGNAL";
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
   return "NONE";
  }

#endif
