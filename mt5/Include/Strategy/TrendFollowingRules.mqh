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
                          const double open_price,
                          const double high_price,
                          const double low_price,
                          const double close_price,
                          const double fast_ema,
                          const double atr,
                          const double atr_tolerance)
     {
      const double tolerance=atr*atr_tolerance;
      if(direction==SIGNAL_DIRECTION_BUY)
         return low_price<=fast_ema+tolerance && close_price>fast_ema && close_price>open_price;
      if(direction==SIGNAL_DIRECTION_SELL)
         return high_price>=fast_ema-tolerance && close_price<fast_ema && close_price<open_price;
      return false;
     }
  };

#endif
