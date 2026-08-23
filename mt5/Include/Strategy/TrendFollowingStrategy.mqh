#ifndef EA_TRADING_SYSTEM_TREND_FOLLOWING_STRATEGY_MQH
#define EA_TRADING_SYSTEM_TREND_FOLLOWING_STRATEGY_MQH

#include <EaTradingSystem/Strategy/IStrategy.mqh>
#include <EaTradingSystem/Strategy/TrendFollowingRules.mqh>
#include <EaTradingSystem/Filter/MarketRegimeClassifier.mqh>

class CTrendFollowingStrategy : public IStrategy
  {
private:
   SEaConfig m_config;
   int m_d1_slow_handle;
   int m_h4_fast_handle;
   int m_h4_slow_handle;
   int m_h1_fast_handle;
   int m_h1_rsi_handle;
   int m_h1_atr_handle;
   int m_h1_adx_handle;
   int m_h4_adx_handle;
   bool m_initialized;

   bool ReadIndicator(const int handle,const int shift,double &value)
     {
      if(handle==INVALID_HANDLE || BarsCalculated(handle)<=shift)
         return false;
      double values[1];
      if(CopyBuffer(handle,0,shift,1,values)!=1)
         return false;
      value=values[0];
      return MathIsValidNumber(value);
     }

   bool ReadEntryBar(MqlRates &bar)
     {
      MqlRates rates[1];
      if(CopyRates(m_config.symbol,m_config.entry_timeframe,1,1,rates)!=1)
         return false;
      bar=rates[0];
      return bar.time>0 && bar.close>0.0;
     }

   // レジーム判定専用のATRベースライン（過去N本の単純平均）。既存のATR Indicatorハンドルを再利用し、
   // 新規Indicatorは作成しない。確定足（shift>=1）のみを参照し、look-ahead biasを発生させない。
   bool ReadAtrBaseline(const int shift,const int period,double &average)
     {
      if(period<2) return false;
      double values[];
      if(CopyBuffer(m_h1_atr_handle,0,shift,period,values)!=period)
         return false;
      double sum=0.0;
      for(int index=0; index<period; index++)
        {
         if(!MathIsValidNumber(values[index]))
            return false;
         sum+=values[index];
        }
      average=sum/period;
      return true;
     }

   bool ReadBreakoutRange(double &previous_high,double &previous_low)
     {
      previous_high=-DBL_MAX;
      previous_low=DBL_MAX;
      for(int shift=2; shift<m_config.breakout_lookback+2; shift++)
        {
         const double high=iHigh(m_config.symbol,m_config.entry_timeframe,shift);
         const double low=iLow(m_config.symbol,m_config.entry_timeframe,shift);
         if(high<=0.0 || low<=0.0)
            return false;
         if(high>previous_high) previous_high=high;
         if(low<previous_low) previous_low=low;
        }
      return previous_high>-DBL_MAX && previous_low<DBL_MAX;
     }

   void SetDataError(SSignalResult &result,const string code,const string message)
     {
      result.status=SIGNAL_STATUS_ERROR;
      result.reason_code=code;
      result.reason=message;
     }

public:
   CTrendFollowingStrategy(void)
     {
      m_d1_slow_handle=INVALID_HANDLE;
      m_h4_fast_handle=INVALID_HANDLE;
      m_h4_slow_handle=INVALID_HANDLE;
      m_h1_fast_handle=INVALID_HANDLE;
      m_h1_rsi_handle=INVALID_HANDLE;
      m_h1_atr_handle=INVALID_HANDLE;
      m_h1_adx_handle=INVALID_HANDLE;
      m_h4_adx_handle=INVALID_HANDLE;
      m_initialized=false;
     }

   virtual string Name(void) const { return "TrendFollowingStrategyV1"; }

   virtual bool Initialize(const SEaConfig &config,string &error)
     {
      Shutdown();
      m_config=config;
      error="";
      if(!SymbolSelect(m_config.symbol,true))
        { error="SYMBOL_SELECT_FAILED"; return false; }

      m_d1_slow_handle=iMA(m_config.symbol,m_config.trend_timeframe,m_config.slow_ema_period,0,MODE_EMA,PRICE_CLOSE);
      m_h4_fast_handle=iMA(m_config.symbol,m_config.confirmation_timeframe,m_config.fast_ema_period,0,MODE_EMA,PRICE_CLOSE);
      m_h4_slow_handle=iMA(m_config.symbol,m_config.confirmation_timeframe,m_config.slow_ema_period,0,MODE_EMA,PRICE_CLOSE);
      m_h1_fast_handle=iMA(m_config.symbol,m_config.entry_timeframe,m_config.fast_ema_period,0,MODE_EMA,PRICE_CLOSE);
      m_h1_rsi_handle=iRSI(m_config.symbol,m_config.entry_timeframe,m_config.rsi_period,PRICE_CLOSE);
      m_h1_atr_handle=iATR(m_config.symbol,m_config.entry_timeframe,m_config.atr_period);
      m_h1_adx_handle=iADX(m_config.symbol,m_config.entry_timeframe,m_config.adx_period);
      m_h4_adx_handle=iADX(m_config.symbol,m_config.confirmation_timeframe,m_config.adx_period);

      if(m_d1_slow_handle==INVALID_HANDLE || m_h4_fast_handle==INVALID_HANDLE ||
         m_h4_slow_handle==INVALID_HANDLE || m_h1_fast_handle==INVALID_HANDLE ||
         m_h1_rsi_handle==INVALID_HANDLE || m_h1_atr_handle==INVALID_HANDLE ||
         m_h1_adx_handle==INVALID_HANDLE || m_h4_adx_handle==INVALID_HANDLE)
        {
         error="INDICATOR_HANDLE_FAILED";
         Shutdown();
         return false;
        }
      m_initialized=true;
      return true;
     }

   virtual void Shutdown(void)
     {
      if(m_d1_slow_handle!=INVALID_HANDLE) IndicatorRelease(m_d1_slow_handle);
      if(m_h4_fast_handle!=INVALID_HANDLE) IndicatorRelease(m_h4_fast_handle);
      if(m_h4_slow_handle!=INVALID_HANDLE) IndicatorRelease(m_h4_slow_handle);
      if(m_h1_fast_handle!=INVALID_HANDLE) IndicatorRelease(m_h1_fast_handle);
      if(m_h1_rsi_handle!=INVALID_HANDLE) IndicatorRelease(m_h1_rsi_handle);
      if(m_h1_atr_handle!=INVALID_HANDLE) IndicatorRelease(m_h1_atr_handle);
      if(m_h1_adx_handle!=INVALID_HANDLE) IndicatorRelease(m_h1_adx_handle);
      if(m_h4_adx_handle!=INVALID_HANDLE) IndicatorRelease(m_h4_adx_handle);
      m_d1_slow_handle=INVALID_HANDLE;
      m_h4_fast_handle=INVALID_HANDLE;
      m_h4_slow_handle=INVALID_HANDLE;
      m_h1_fast_handle=INVALID_HANDLE;
      m_h1_rsi_handle=INVALID_HANDLE;
      m_h1_atr_handle=INVALID_HANDLE;
      m_h1_adx_handle=INVALID_HANDLE;
      m_h4_adx_handle=INVALID_HANDLE;
      m_initialized=false;
     }

   virtual bool Evaluate(SSignalResult &result)
     {
      ResetSignalResult(result);
      result.symbol=m_config.symbol;
      result.timeframe=m_config.entry_timeframe;
      if(!m_initialized)
        { SetDataError(result,"STRATEGY_NOT_INITIALIZED","Strategy is not initialized."); return false; }

      MqlRates entry_bar;
      double d1_slow,h4_fast,h4_slow,h1_fast,rsi,atr,adx,h4_adx;
      const double d1_close=iClose(m_config.symbol,m_config.trend_timeframe,1);
      if(d1_close<=0.0 || !ReadEntryBar(entry_bar) ||
         !ReadIndicator(m_d1_slow_handle,1,d1_slow) ||
         !ReadIndicator(m_h4_fast_handle,1,h4_fast) ||
         !ReadIndicator(m_h4_slow_handle,1,h4_slow) ||
         !ReadIndicator(m_h1_fast_handle,1,h1_fast) ||
         !ReadIndicator(m_h1_rsi_handle,1,rsi) ||
         !ReadIndicator(m_h1_atr_handle,1,atr) ||
         !ReadIndicator(m_h1_adx_handle,1,adx) ||
         !ReadIndicator(m_h4_adx_handle,1,h4_adx))
        { SetDataError(result,"MARKET_DATA_UNAVAILABLE","Closed-bar indicator data is unavailable."); return false; }

      const double point=SymbolInfoDouble(m_config.symbol,SYMBOL_POINT);
      const int digits=(int)SymbolInfoInteger(m_config.symbol,SYMBOL_DIGITS);
      if(point<=0.0 || atr<=0.0)
        { SetDataError(result,"INVALID_SYMBOL_DATA","Point or ATR is invalid."); return false; }

      result.signal_bar_time=entry_bar.time;
      result.rsi=rsi;
      result.atr=atr;
      result.adx=adx;
      result.ema_fast=h4_fast;
      result.ema_slow=h4_slow;
      result.ema_distance_ratio=(h4_slow!=0.0 ? (h4_fast-h4_slow)/h4_slow : 0.0);
      const double previous_close=iClose(m_config.symbol,m_config.entry_timeframe,2);
      if(previous_close<=0.0)
        { SetDataError(result,"RECENT_RETURN_UNAVAILABLE","Previous closed-bar price is unavailable."); return false; }
      result.recent_return=entry_bar.close/previous_close-1.0;
      result.volatility=atr/entry_bar.close;
      MqlDateTime signal_time;
      TimeToStruct(entry_bar.time,signal_time);
      result.hour=signal_time.hour;
      result.day_of_week=signal_time.day_of_week;

      // 市場レジーム判定（分析専用）。既存のADX/ATR/EMA(H1)ハンドルを再利用し、確定足データのみで判定する。
      // この結果はログ記録のみに使用し、以降のEntry判定・売買制御には一切使用しない。
      double atr_baseline_average;
      const bool atr_baseline_ok=ReadAtrBaseline(1,m_config.regime_atr_baseline_period,atr_baseline_average);
      double ma_slope_reference;
      const bool ma_slope_ok=ReadIndicator(m_h1_fast_handle,1+m_config.regime_ma_slope_lookback,ma_slope_reference);
      result.market_regime_trend=ma_slope_ok ?
         CMarketRegimeClassifier::ClassifyTrend(adx,h1_fast,ma_slope_reference,m_config.regime_trend_adx_min) :
         MARKET_REGIME_TREND_UNKNOWN;
      result.market_regime_volatility=atr_baseline_ok ?
         CMarketRegimeClassifier::ClassifyVolatility(atr,atr_baseline_average,m_config.regime_high_volatility_ratio,
                                                       m_config.regime_low_volatility_ratio) :
         MARKET_REGIME_VOLATILITY_UNKNOWN;

      // 段階的Entry判定パイプライン: Stage 1 Market Regime。判定結果自体は方式に関わらず常に記録する
      // （ログ・分析専用）。実際のEntry拒否ゲートとしては、InpEntryUseStagedPipeline=trueの場合のみ働く。
      // InpEntryUseStagedPipeline=falseの既存方式では、このステージはEntry判定に一切影響しない。
      result.staged_pipeline_used=m_config.entry_use_staged_pipeline;
      result.stage_market_regime=MarketRegimeTrendToString(result.market_regime_trend);
      result.stage_market_regime_passed=(result.market_regime_trend!=MARKET_REGIME_TREND_RANGE &&
                                          result.market_regime_trend!=MARKET_REGIME_TREND_UNKNOWN);
      if(m_config.entry_use_staged_pipeline && m_config.entry_require_market_regime_trend &&
         !result.stage_market_regime_passed)
        {
         result.reason_code="REGIME_NOT_TRENDING";
         result.reason="Staged entry pipeline rejected: market regime is not trending.";
         return true;
        }

      // Stage 2 Higher Timeframe Bias（D1/H4トレンド一致）。既存方式・段階的方式ともに共通のゲート。
      const ESignalDirection direction=CTrendFollowingRules::TrendDirection(d1_close,d1_slow,h4_fast,h4_slow);
      result.stage_htf_bias=SignalDirectionToString(direction);
      result.stage_htf_bias_passed=(direction!=SIGNAL_DIRECTION_NONE);
      if(direction==SIGNAL_DIRECTION_NONE)
        { result.reason_code="TREND_NOT_ALIGNED"; result.reason="D1 and H4 trends are not aligned."; return true; }
      if(atr/point<m_config.minimum_atr_points)
        { result.reason_code="ATR_TOO_LOW"; result.reason="ATR is below the configured floor."; return true; }
      if(adx<m_config.minimum_adx)
        { result.reason_code="ADX_TOO_LOW"; result.reason="H1 ADX is below the configured trend-strength floor."; return true; }
      if(h4_adx<m_config.minimum_confirmation_adx)
        { result.reason_code="CONFIRMATION_ADX_TOO_LOW"; result.reason="H4 ADX is below the configured trend-strength floor."; return true; }
      if(!CTrendFollowingRules::MomentumAllowed(direction,rsi,m_config.rsi_buy_min,m_config.rsi_buy_max,m_config.rsi_sell_min,m_config.rsi_sell_max))
        { result.reason_code="RSI_FILTERED"; result.reason="RSI is outside the configured range."; return true; }

      double previous_high,previous_low;
      if(!ReadBreakoutRange(previous_high,previous_low))
        { SetDataError(result,"BREAKOUT_DATA_UNAVAILABLE","Breakout range is unavailable."); return false; }

      const double touch_high=iHigh(m_config.symbol,m_config.entry_timeframe,2);
      const double touch_low=iLow(m_config.symbol,m_config.entry_timeframe,2);
      double h1_fast_touch;
      if(touch_high<=0.0 || touch_low<=0.0 || !ReadIndicator(m_h1_fast_handle,2,h1_fast_touch))
        { SetDataError(result,"PULLBACK_DATA_UNAVAILABLE","Pullback confirmation bar data is unavailable."); return false; }

      const bool breakout=m_config.enable_breakout &&
         CTrendFollowingRules::IsBreakout(direction,entry_bar.close,previous_high,previous_low,m_config.breakout_buffer_points*point);
      const bool pullback=m_config.enable_pullback &&
         CTrendFollowingRules::IsPullback(direction,entry_bar.open,entry_bar.high,entry_bar.low,entry_bar.close,h1_fast,
                                           touch_high,touch_low,h1_fast_touch,atr,m_config.pullback_atr_tolerance,
                                           m_config.pullback_trigger_atr_buffer);

      // Stage 3 Setup / Stage 4 Entry Trigger。IsPullbackをSetup（押し目/戻り成立）とTrigger（再加速）に
      // 分解した診断専用フィールド（既存のbreakout/pullback変数と数式上等価、判定への影響はない）。
      // ブレイクアウトにはSetup相当の別ロジックがないため、有効化かつレンジデータ取得成功をSetup成立とみなす。
      result.stage_breakout_setup_passed=m_config.enable_breakout;
      result.stage_breakout_trigger_passed=breakout;
      result.stage_pullback_setup_passed=m_config.enable_pullback &&
         CTrendFollowingRules::IsPullbackSetup(direction,touch_high,touch_low,h1_fast_touch,atr,m_config.pullback_atr_tolerance);
      result.stage_pullback_trigger_passed=m_config.enable_pullback &&
         CTrendFollowingRules::IsPullbackTrigger(direction,entry_bar.open,entry_bar.close,h1_fast,touch_high,touch_low,
                                                  atr,m_config.pullback_trigger_atr_buffer);

      if(!breakout && !pullback)
        { result.reason_code="ENTRY_PATTERN_NOT_FOUND"; result.reason="No enabled closed-bar entry pattern matched."; return true; }

      result.status=SIGNAL_STATUS_CANDIDATE;
      result.direction=direction;
      result.entry_pattern=(breakout ? ENTRY_PATTERN_BREAKOUT : ENTRY_PATTERN_PULLBACK);
      result.trade_candidate_id=StringFormat("%s-%s-%I64d",m_config.ea_id,m_config.symbol,(long)entry_bar.time);
      result.entry_price=NormalizeDouble(entry_bar.close,digits);
      result.risk_reward_ratio=m_config.risk_reward_ratio;
      const double stop_distance=atr*m_config.stop_atr_multiple;
      if(direction==SIGNAL_DIRECTION_BUY)
        {
         result.stop_loss=NormalizeDouble(result.entry_price-stop_distance,digits);
         result.take_profit=NormalizeDouble(result.entry_price+stop_distance*m_config.risk_reward_ratio,digits);
        }
      else
        {
         result.stop_loss=NormalizeDouble(result.entry_price+stop_distance,digits);
         result.take_profit=NormalizeDouble(result.entry_price-stop_distance*m_config.risk_reward_ratio,digits);
        }
      if(result.stop_loss<=0.0 || result.take_profit<=0.0 ||
         (direction==SIGNAL_DIRECTION_BUY && !(result.stop_loss<result.entry_price && result.take_profit>result.entry_price)) ||
         (direction==SIGNAL_DIRECTION_SELL && !(result.stop_loss>result.entry_price && result.take_profit<result.entry_price)))
        {
         SetDataError(result,"INVALID_TRADE_GEOMETRY","Calculated entry, stop, and target geometry is invalid.");
         return false;
        }
      result.reason_code=(breakout ? "TREND_BREAKOUT" : "TREND_PULLBACK");
      result.reason=StringFormat("D1/H4 aligned; H1 %s; RSI=%.2f; ATR=%.8f.",EntryPatternToString(result.entry_pattern),rsi,atr);
      return true;
     }

   // 保有中ポジションのエントリー根拠再検証専用（Evaluateとは別系統）。RSI・ATR下限・
   // エントリーパターン（ブレイクアウト/プルバック）は再チェックせず、トレンド方向とADX
   // （トレンド強度）という「保有継続の前提」が消えたかどうかのみを判定する。
   // signal_exit_check_*で個々の条件をon/offできる。データ取得不能時はfalse-safe
   // （false=保有継続）とし、既存の保護SL/TPに委ねる（不確かなデータで決済アクションを起こさない）。
   bool IsTrendStillValid(const ESignalDirection position_direction,string &reason_code)
     {
      reason_code="";
      if(!m_initialized)
        { reason_code="STRATEGY_NOT_INITIALIZED"; return true; }
      double d1_slow,h4_fast,h4_slow,adx,h4_adx;
      const double d1_close=iClose(m_config.symbol,m_config.trend_timeframe,1);
      if(d1_close<=0.0 ||
         !ReadIndicator(m_d1_slow_handle,1,d1_slow) ||
         !ReadIndicator(m_h4_fast_handle,1,h4_fast) ||
         !ReadIndicator(m_h4_slow_handle,1,h4_slow) ||
         !ReadIndicator(m_h1_adx_handle,1,adx) ||
         !ReadIndicator(m_h4_adx_handle,1,h4_adx))
        { reason_code="MARKET_DATA_UNAVAILABLE"; return true; }

      if(m_config.signal_exit_check_trend)
        {
         const ESignalDirection current_direction=CTrendFollowingRules::TrendDirection(d1_close,d1_slow,h4_fast,h4_slow);
         if(current_direction!=position_direction)
           { reason_code="TREND_REVERSED"; return false; }
        }
      if(m_config.signal_exit_check_h1_adx && adx<m_config.minimum_adx)
        { reason_code="ADX_TOO_LOW"; return false; }
      if(m_config.signal_exit_check_h4_adx && h4_adx<m_config.minimum_confirmation_adx)
        { reason_code="CONFIRMATION_ADX_TOO_LOW"; return false; }
      return true;
     }
  };

#endif
