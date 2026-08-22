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
      return IsPullbackSetup(direction,touch_high,touch_low,touch_fast_ema,atr,atr_tolerance) &&
             IsPullbackTrigger(direction,entry_open,entry_close,entry_fast_ema,touch_high,touch_low);
     }

   // Setup: 押し目/戻り成立判定。タッチ足(shift2)がEMAへ許容幅内まで接近したかのみを見る
   // （エントリー方向への調整局面が形成されたか）。IsPullbackから抽出した段階的Entry判定パイプライン専用の分解。
   static bool IsPullbackSetup(const ESignalDirection direction,
                               const double touch_high,
                               const double touch_low,
                               const double touch_fast_ema,
                               const double atr,
                               const double atr_tolerance)
     {
      const double tolerance=atr*atr_tolerance;
      if(direction==SIGNAL_DIRECTION_BUY)
         return touch_low<=touch_fast_ema+tolerance;
      if(direction==SIGNAL_DIRECTION_SELL)
         return touch_high>=touch_fast_ema-tolerance;
      return false;
     }

   // Entry Trigger: Setup成立後の再加速判定。確認足(shift1)がEMA・自身の始値・タッチ足高安値を
   // 上回る/下回るかを見る（トレンド方向への再加速）。Setup成立を前提とせず独立して評価できる。
   static bool IsPullbackTrigger(const ESignalDirection direction,
                                 const double entry_open,
                                 const double entry_close,
                                 const double entry_fast_ema,
                                 const double touch_high,
                                 const double touch_low)
     {
      if(direction==SIGNAL_DIRECTION_BUY)
         return entry_close>entry_fast_ema && entry_close>entry_open && entry_close>touch_high;
      if(direction==SIGNAL_DIRECTION_SELL)
         return entry_close<entry_fast_ema && entry_close<entry_open && entry_close<touch_low;
      return false;
     }
  };

#endif
