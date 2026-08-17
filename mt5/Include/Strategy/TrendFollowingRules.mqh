#ifndef EA_TRADING_SYSTEM_TREND_FOLLOWING_RULES_MQH
#define EA_TRADING_SYSTEM_TREND_FOLLOWING_RULES_MQH

#include <EaTradingSystem/Signal/SignalResult.mqh>

class CTrendFollowingRules
  {
public:
   static ESignalDirection TrendDirection(const double daily_close,
                                          const double daily_slow_ema,
                                          const double h4_fast_ema,
                                          const double h4_slow_ema)
     {
      if(daily_close>daily_slow_ema && h4_fast_ema>h4_slow_ema)
         return SIGNAL_DIRECTION_BUY;
      if(daily_close<daily_slow_ema && h4_fast_ema<h4_slow_ema)
         return SIGNAL_DIRECTION_SELL;
      return SIGNAL_DIRECTION_NONE;
     }

   static bool MomentumAllowed(const ESignalDirection direction,
                               const double rsi,
                               const double buy_min,
                               const double buy_max,
                               const double sell_min,
                               const double sell_max)
     {
      if(direction==SIGNAL_DIRECTION_BUY)
         return rsi>=buy_min && rsi<=buy_max;
      if(direction==SIGNAL_DIRECTION_SELL)
         return rsi>=sell_min && rsi<=sell_max;
      return false;
     }

   static bool IsBreakout(const ESignalDirection direction,
                          const double close_price,
                          const double previous_high,
                          const double previous_low,
                          const double buffer_price)
     {
      if(direction==SIGNAL_DIRECTION_BUY)
         return close_price>previous_high+buffer_price;
      if(direction==SIGNAL_DIRECTION_SELL)
         return close_price<previous_low-buffer_price;
      return false;
     }

   static bool IsPullback(const ESignalDirection direction,
                          const double entry_open,
                          const double entry_high,
                          const double entry_low,
                          const double entry_close,
                          const double entry_fast_ema,
                          const double touch_high,
                          const double touch_low,
                          const double touch_fast_ema,
                          const double atr,
                          const double atr_tolerance)
     {
      const double tolerance=atr*atr_tolerance;
      if(direction==SIGNAL_DIRECTION_BUY)
         return touch_low<=touch_fast_ema+tolerance &&
                entry_close>entry_fast_ema && entry_close>entry_open && entry_close>touch_high;
      if(direction==SIGNAL_DIRECTION_SELL)
         return touch_high>=touch_fast_ema-tolerance &&
                entry_close<entry_fast_ema && entry_close<entry_open && entry_close<touch_low;
      return false;
     }
  };

#endif
