#ifndef EA_TRADING_SYSTEM_BREAKOUT_TIMING_ANALYZER_MQH
#define EA_TRADING_SYSTEM_BREAKOUT_TIMING_ANALYZER_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/Strategy/TrendFollowingRules.mqh>
#include <EaTradingSystem/Logging/EntryTimingAnalyzer.mqh>

// 分析専用のBreakout Timing比較機能。ブレイクアウトはSetupとTriggerが同一の価格事象
// （レンジ突破）であり、CEntryTimingAnalyzer（プルバック専用）が検証する「Trigger成立を待つ」
// という概念を適用できない（docs/backtesting.md参照）。代わりに、
//   IMMEDIATE      : ブレイクアウト成立bar自身の終値で即Entry（現行ライブロジックと同一）
//   CONFIRM_1_BAR  : 1本後の終値時点でもブレイクアウトレベル（Setup成立時点で固定）を
//                    維持できていた場合のみEntry。維持できていなければ当Variantは生成しない
//   CONFIRM_2_BARS : 2本後について同様
//   CONFIRM_3_BARS : 3本後について同様
// の4方式を実発注を一切伴わないShadow Tradeとして並行シミュレートし、監査ログへ記録する。
// 過去データへ最も適合する確認本数を自動採用する処理は実装しない（判断はユーザー・分析側に委ねる）。
// 既存Strategy/PositionManagerには一切影響しない（自己完結、読み取り専用、実注文を出さない、
// CEntryTimingAnalyzerと同じ設計方針）。既存CTrendFollowingStrategy::Evaluateと同じ上流ゲート
// （HTF Bias/ATR/ADX/RSI/ブレイクアウトレンジ）を独立に再評価する意図的な重複であり、
// Strategy本体とは完全に分離した自己完結モジュールとする（DECISIONS.md参照、
// CEntryTimingAnalyzerと同じ設計判断）。
enum EBreakoutTimingVariant
  {
   BREAKOUT_TIMING_IMMEDIATE=0,
   BREAKOUT_TIMING_CONFIRM_1_BAR=1,
   BREAKOUT_TIMING_CONFIRM_2_BARS=2,
   BREAKOUT_TIMING_CONFIRM_3_BARS=3
  };

string BreakoutTimingVariantToString(const EBreakoutTimingVariant variant)
  {
   if(variant==BREAKOUT_TIMING_IMMEDIATE)      return "IMMEDIATE";
   if(variant==BREAKOUT_TIMING_CONFIRM_1_BAR)  return "CONFIRM_1_BAR";
   if(variant==BREAKOUT_TIMING_CONFIRM_2_BARS) return "CONFIRM_2_BARS";
   if(variant==BREAKOUT_TIMING_CONFIRM_3_BARS) return "CONFIRM_3_BARS";
   return "UNKNOWN";
  }

// Shadow Trade判定の純粋関数群（単体テスト対象）。実注文・実ポジションには一切関与しない。
// SL/TP判定・R換算・含み損益追跡等の汎用関数はCEntryTimingRules（プルバック分析と共通）を再利用する。
class CBreakoutTimingRules
  {
public:
   // ブレイクアウトが依然として維持されているか（Setup成立時点で固定したレンジ高安値に対して）を判定する。
   // 数式はCTrendFollowingRules::IsBreakoutと同一だが、レンジ高安値を毎回再計算せずSetup成立時点の
   // 値へ固定して比較する点が異なる（「同一のブレイクアウト事象がどれだけ維持されたか」を見るため）。
   static bool HoldsBreakout(const ESignalDirection direction,const double close_price,
                             const double breakout_level_high,const double breakout_level_low,
                             const double buffer_price)
     {
      return CTrendFollowingRules::IsBreakout(direction,close_price,breakout_level_high,breakout_level_low,buffer_price);
     }
  };

// EAControllerが監査ログへ書き出すための完了イベント（Setup単位）。
struct SBreakoutTimingSetupEvent
  {
   string           setup_id;
   datetime         setup_bar_time;
   ESignalDirection direction;
   double           breakout_level_high;
   double           breakout_level_low;
   double           pre_entry_mfe_price;
   double           pre_entry_mfe_r;
   datetime         pre_entry_mfe_time;
   double           pre_entry_mae_price;
   double           pre_entry_mae_r;
   datetime         pre_entry_mae_time;
   bool             confirm_1_bar_held;
   bool             confirm_2_bars_held;
   bool             confirm_3_bars_held;
  };

// EAControllerが監査ログへ書き出すための完了イベント（Variant単位のShadow Trade）。
struct SBreakoutTimingTradeEvent
  {
   string                 setup_id;
   EBreakoutTimingVariant variant;
   datetime               entry_bar_time;
   ESignalDirection       direction;
   double                 entry_price;
   double                 stop_loss;
   double                 take_profit;
   int                    wait_bars;
   int                    bars_held;
   double                 mfe_r;
   double                 mae_r;
   string                 exit_reason; // "SL" / "TP" / "EXPIRED"
   double                 exit_price;
   double                 pnl_r;
   double                 checkpoint_r[6];
   bool                   checkpoint_valid[6];
  };

class CBreakoutTimingAnalyzer
  {
private:
   struct SPendingSetup
     {
      string           setup_id;
      datetime         setup_bar_time;
      ESignalDirection direction;
      double           breakout_level_high;
      double           breakout_level_low;
      double           buffer_price;
      double           setup_close;
      double           setup_atr;
      int              bars_elapsed;
      bool             confirm_1_done;
      bool             confirm_2_done;
      bool             confirm_3_done;
      bool             confirm_1_held;
      bool             confirm_2_held;
      bool             confirm_3_held;
      double           favorable_extreme;
      double           adverse_extreme;
      datetime         favorable_time;
      datetime         adverse_time;
     };

   struct SActiveTrade
     {
      string                 setup_id;
      EBreakoutTimingVariant variant;
      ESignalDirection       direction;
      datetime               entry_bar_time;
      double                 entry_price;
      double                 stop_loss;
      double                 take_profit;
      double                 stop_distance;
      int                    wait_bars;
      int                    bars_held;
      double                 favorable_extreme;
      double                 adverse_extreme;
      double                 checkpoint_r[6];
      bool                   checkpoint_valid[6];
      bool                   closed;
     };

   SEaConfig      m_config;
   bool           m_enabled;
   int            m_d1_slow_handle;
   int            m_h4_fast_handle;
   int            m_h4_slow_handle;
   int            m_h1_atr_handle;
   int            m_h1_rsi_handle;
   int            m_h1_adx_handle;
   int            m_h4_adx_handle;
   datetime       m_last_bar_time;
   bool           m_initialized;
   SPendingSetup  m_pending[];
   SActiveTrade   m_active[];

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

   // CTrendFollowingStrategy::ReadBreakoutRangeと同じレンジ・shift規約（意図的な重複、
   // CEntryTimingAnalyzer::DetectNewSetupと同じ設計方針、Strategy本体からの独立性を優先）。
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

   void RegisterActiveTrade(const string setup_id,const EBreakoutTimingVariant variant,
                            const ESignalDirection direction,const datetime entry_bar_time,
                            const double entry_price,const double atr,const int wait_bars)
     {
      const double stop_distance=CEntryTimingRules::StopDistance(atr,m_config.stop_atr_multiple);
      if(stop_distance<=0.0 || entry_price<=0.0) return; // データ不良時は記録しない(fail-safe)
      const int slot=ArraySize(m_active);
      ArrayResize(m_active,slot+1);
      m_active[slot].setup_id=setup_id;
      m_active[slot].variant=variant;
      m_active[slot].direction=direction;
      m_active[slot].entry_bar_time=entry_bar_time;
      m_active[slot].entry_price=entry_price;
      m_active[slot].stop_loss=CEntryTimingRules::ComputeStopLoss(direction,entry_price,stop_distance);
      m_active[slot].take_profit=CEntryTimingRules::ComputeTakeProfit(direction,entry_price,stop_distance,
                                                                       m_config.risk_reward_ratio);
      m_active[slot].stop_distance=stop_distance;
      m_active[slot].wait_bars=wait_bars;
      m_active[slot].bars_held=0;
      m_active[slot].favorable_extreme=entry_price;
      m_active[slot].adverse_extreme=entry_price;
      for(int index=0; index<CEntryTimingRules::CheckpointCount(); index++)
        {
         m_active[slot].checkpoint_r[index]=0.0;
         m_active[slot].checkpoint_valid[index]=false;
        }
      m_active[slot].closed=false;
     }

   void FinalizeActiveTrade(const int index,const string exit_reason,const double exit_price,
                            SBreakoutTimingTradeEvent &completed_trades[])
     {
      const int slot=ArraySize(completed_trades);
      ArrayResize(completed_trades,slot+1);
      completed_trades[slot].setup_id=m_active[index].setup_id;
      completed_trades[slot].variant=m_active[index].variant;
      completed_trades[slot].entry_bar_time=m_active[index].entry_bar_time;
      completed_trades[slot].direction=m_active[index].direction;
      completed_trades[slot].entry_price=m_active[index].entry_price;
      completed_trades[slot].stop_loss=m_active[index].stop_loss;
      completed_trades[slot].take_profit=m_active[index].take_profit;
      completed_trades[slot].wait_bars=m_active[index].wait_bars;
      completed_trades[slot].bars_held=m_active[index].bars_held;
      completed_trades[slot].mfe_r=CEntryTimingRules::PriceToR(m_active[index].direction,m_active[index].entry_price,
                                                                m_active[index].favorable_extreme,m_active[index].stop_distance);
      completed_trades[slot].mae_r=CEntryTimingRules::PriceToR(m_active[index].direction,m_active[index].entry_price,
                                                                m_active[index].adverse_extreme,m_active[index].stop_distance);
      completed_trades[slot].exit_reason=exit_reason;
      completed_trades[slot].exit_price=exit_price;
      completed_trades[slot].pnl_r=CEntryTimingRules::PriceToR(m_active[index].direction,m_active[index].entry_price,
                                                                exit_price,m_active[index].stop_distance);
      for(int index2=0; index2<CEntryTimingRules::CheckpointCount(); index2++)
        {
         completed_trades[slot].checkpoint_r[index2]=m_active[index].checkpoint_r[index2];
         completed_trades[slot].checkpoint_valid[index2]=m_active[index].checkpoint_valid[index2];
        }
      m_active[index].closed=true;
     }

   void PruneClosedActiveTrades(void)
     {
      for(int index=ArraySize(m_active)-1; index>=0; index--)
        {
         if(!m_active[index].closed) continue;
         const int last=ArraySize(m_active)-1;
         m_active[index]=m_active[last];
         ArrayResize(m_active,last);
        }
     }

   // 毎Tick: アクティブなShadow TradeのSL/TP判定・含み損益追跡（tick粒度）。
   void MonitorActiveTrades(const MqlTick &tick,SBreakoutTimingTradeEvent &completed_trades[])
     {
      for(int index=ArraySize(m_active)-1; index>=0; index--)
        {
         if(m_active[index].closed) continue;
         const ESignalDirection direction=m_active[index].direction;
         const double exit_reference_price=(direction==SIGNAL_DIRECTION_BUY ? tick.bid : tick.ask);
         CEntryTimingRules::UpdateExcursion(direction,exit_reference_price,
                                            m_active[index].favorable_extreme,m_active[index].adverse_extreme);
         if(CEntryTimingRules::IsStopLossHit(direction,m_active[index].stop_loss,tick.bid,tick.ask))
           { FinalizeActiveTrade(index,"SL",m_active[index].stop_loss,completed_trades); continue; }
         if(CEntryTimingRules::IsTakeProfitHit(direction,m_active[index].take_profit,tick.bid,tick.ask))
           { FinalizeActiveTrade(index,"TP",m_active[index].take_profit,completed_trades); continue; }
        }
     }

   // 新確定足ごとに1回: 既存アクティブトレードのバー経過処理（本数計測・価格推移チェックポイント・期限切れ）。
   void AdvanceActiveTradesOnNewBar(const MqlRates &bar,SBreakoutTimingTradeEvent &completed_trades[])
     {
      for(int index=ArraySize(m_active)-1; index>=0; index--)
        {
         if(m_active[index].closed) continue;
         m_active[index].bars_held++;
         const int bars_held=m_active[index].bars_held;
         for(int checkpoint_index=0; checkpoint_index<CEntryTimingRules::CheckpointCount(); checkpoint_index++)
           {
            if(m_active[index].checkpoint_valid[checkpoint_index]) continue;
            if(bars_held!=CEntryTimingRules::CheckpointBars(checkpoint_index)) continue;
            m_active[index].checkpoint_r[checkpoint_index]=
               CEntryTimingRules::PriceToR(m_active[index].direction,m_active[index].entry_price,
                                           bar.close,m_active[index].stop_distance);
            m_active[index].checkpoint_valid[checkpoint_index]=true;
           }
         if(bars_held>=m_config.breakout_timing_max_holding_bars)
            FinalizeActiveTrade(index,"EXPIRED",bar.close,completed_trades);
        }
     }

   // 新確定足ごとに1回: 既存Pending Setupの進行（本数計測・Confirm 1/2/3本後の維持判定・完了イベント出力）。
   void AdvancePendingSetups(const MqlRates &bar,const double atr,
                             SBreakoutTimingSetupEvent &completed_setups[],SBreakoutTimingTradeEvent &completed_trades[])
     {
      for(int index=ArraySize(m_pending)-1; index>=0; index--)
        {
         const ESignalDirection direction=m_pending[index].direction;
         m_pending[index].bars_elapsed++;
         const int elapsed=m_pending[index].bars_elapsed;

         const double prev_favorable=m_pending[index].favorable_extreme;
         const double prev_adverse=m_pending[index].adverse_extreme;
         CEntryTimingRules::UpdateExcursion(direction,bar.high,m_pending[index].favorable_extreme,m_pending[index].adverse_extreme);
         CEntryTimingRules::UpdateExcursion(direction,bar.low,m_pending[index].favorable_extreme,m_pending[index].adverse_extreme);
         if(m_pending[index].favorable_extreme!=prev_favorable) m_pending[index].favorable_time=bar.time;
         if(m_pending[index].adverse_extreme!=prev_adverse) m_pending[index].adverse_time=bar.time;

         if(elapsed==1 && !m_pending[index].confirm_1_done)
           {
            m_pending[index].confirm_1_done=true;
            m_pending[index].confirm_1_held=CBreakoutTimingRules::HoldsBreakout(direction,bar.close,
               m_pending[index].breakout_level_high,m_pending[index].breakout_level_low,m_pending[index].buffer_price);
            if(m_pending[index].confirm_1_held)
               RegisterActiveTrade(m_pending[index].setup_id,BREAKOUT_TIMING_CONFIRM_1_BAR,direction,bar.time,bar.close,atr,elapsed);
           }
         if(elapsed==2 && !m_pending[index].confirm_2_done)
           {
            m_pending[index].confirm_2_done=true;
            m_pending[index].confirm_2_held=CBreakoutTimingRules::HoldsBreakout(direction,bar.close,
               m_pending[index].breakout_level_high,m_pending[index].breakout_level_low,m_pending[index].buffer_price);
            if(m_pending[index].confirm_2_held)
               RegisterActiveTrade(m_pending[index].setup_id,BREAKOUT_TIMING_CONFIRM_2_BARS,direction,bar.time,bar.close,atr,elapsed);
           }
         if(elapsed==3 && !m_pending[index].confirm_3_done)
           {
            m_pending[index].confirm_3_done=true;
            m_pending[index].confirm_3_held=CBreakoutTimingRules::HoldsBreakout(direction,bar.close,
               m_pending[index].breakout_level_high,m_pending[index].breakout_level_low,m_pending[index].buffer_price);
            if(m_pending[index].confirm_3_held)
               RegisterActiveTrade(m_pending[index].setup_id,BREAKOUT_TIMING_CONFIRM_3_BARS,direction,bar.time,bar.close,atr,elapsed);
           }

         if(m_pending[index].confirm_1_done && m_pending[index].confirm_2_done && m_pending[index].confirm_3_done)
           {
            const int slot=ArraySize(completed_setups);
            ArrayResize(completed_setups,slot+1);
            const double setup_stop_distance=CEntryTimingRules::StopDistance(m_pending[index].setup_atr,m_config.stop_atr_multiple);
            completed_setups[slot].setup_id=m_pending[index].setup_id;
            completed_setups[slot].setup_bar_time=m_pending[index].setup_bar_time;
            completed_setups[slot].direction=direction;
            completed_setups[slot].breakout_level_high=m_pending[index].breakout_level_high;
            completed_setups[slot].breakout_level_low=m_pending[index].breakout_level_low;
            completed_setups[slot].pre_entry_mfe_price=m_pending[index].favorable_extreme;
            completed_setups[slot].pre_entry_mfe_r=CEntryTimingRules::PriceToR(direction,m_pending[index].setup_close,
                                                                                m_pending[index].favorable_extreme,setup_stop_distance);
            completed_setups[slot].pre_entry_mfe_time=m_pending[index].favorable_time;
            completed_setups[slot].pre_entry_mae_price=m_pending[index].adverse_extreme;
            completed_setups[slot].pre_entry_mae_r=CEntryTimingRules::PriceToR(direction,m_pending[index].setup_close,
                                                                                m_pending[index].adverse_extreme,setup_stop_distance);
            completed_setups[slot].pre_entry_mae_time=m_pending[index].adverse_time;
            completed_setups[slot].confirm_1_bar_held=m_pending[index].confirm_1_held;
            completed_setups[slot].confirm_2_bars_held=m_pending[index].confirm_2_held;
            completed_setups[slot].confirm_3_bars_held=m_pending[index].confirm_3_held;

            const int last=ArraySize(m_pending)-1;
            m_pending[index]=m_pending[last];
            ArrayResize(m_pending,last);
           }
        }
     }

   // 新確定足ごとに1回: このbar自身がブレイクアウトSetup（Setup=Trigger同時成立）として成立するかを
   // 判定し、成立していればPendingへ登録した上でVariant IMMEDIATE（即時Entry）を確定する。
   // 既存CTrendFollowingStrategy::Evaluateと同じ上流ゲート（HTF Bias/ATR/ADX/RSI）を独立に再評価する
   // （Strategy本体とは完全に分離した自己完結モジュールとするための意図的な重複、DECISIONS.md参照）。
   void DetectNewSetup(const MqlRates &bar,const double atr,const double rsi,
                       const double adx,const double h4_adx,const double d1_close,const double d1_slow,
                       const double h4_fast,const double h4_slow)
     {
      const double point=SymbolInfoDouble(m_config.symbol,SYMBOL_POINT);
      if(point<=0.0 || atr<=0.0) return;
      const ESignalDirection direction=CTrendFollowingRules::TrendDirection(d1_close,d1_slow,h4_fast,h4_slow);
      if(direction==SIGNAL_DIRECTION_NONE) return;
      if(atr/point<m_config.minimum_atr_points) return;
      if(adx<m_config.minimum_adx) return;
      if(h4_adx<m_config.minimum_confirmation_adx) return;
      if(!CTrendFollowingRules::MomentumAllowed(direction,rsi,m_config.rsi_buy_min,m_config.rsi_buy_max,
                                                m_config.rsi_sell_min,m_config.rsi_sell_max))
         return;

      double previous_high,previous_low;
      if(!ReadBreakoutRange(previous_high,previous_low)) return;
      const double buffer_price=m_config.breakout_buffer_points*point;
      if(!CTrendFollowingRules::IsBreakout(direction,bar.close,previous_high,previous_low,buffer_price))
         return;

      const string setup_id=StringFormat("BT-%s-%s-%I64d",m_config.ea_id,m_config.symbol,(long)bar.time);
      const int slot=ArraySize(m_pending);
      ArrayResize(m_pending,slot+1);
      m_pending[slot].setup_id=setup_id;
      m_pending[slot].setup_bar_time=bar.time;
      m_pending[slot].direction=direction;
      m_pending[slot].breakout_level_high=previous_high;
      m_pending[slot].breakout_level_low=previous_low;
      m_pending[slot].buffer_price=buffer_price;
      m_pending[slot].setup_close=bar.close;
      m_pending[slot].setup_atr=atr;
      m_pending[slot].bars_elapsed=0;
      m_pending[slot].confirm_1_done=false;
      m_pending[slot].confirm_2_done=false;
      m_pending[slot].confirm_3_done=false;
      m_pending[slot].confirm_1_held=false;
      m_pending[slot].confirm_2_held=false;
      m_pending[slot].confirm_3_held=false;
      m_pending[slot].favorable_extreme=bar.close;
      m_pending[slot].adverse_extreme=bar.close;
      m_pending[slot].favorable_time=bar.time;
      m_pending[slot].adverse_time=bar.time;

      RegisterActiveTrade(setup_id,BREAKOUT_TIMING_IMMEDIATE,direction,bar.time,bar.close,atr,0);
     }

   void ProcessNewBar(SBreakoutTimingSetupEvent &completed_setups[],SBreakoutTimingTradeEvent &completed_trades[])
     {
      MqlRates rates[1];
      if(CopyRates(m_config.symbol,m_config.entry_timeframe,1,1,rates)!=1) return;
      const MqlRates bar=rates[0];
      if(bar.time<=0 || bar.close<=0.0) return;

      double rsi,atr,adx,h4_adx,d1_slow,h4_fast,h4_slow;
      const double d1_close=iClose(m_config.symbol,m_config.trend_timeframe,1);
      if(d1_close<=0.0 ||
         !ReadIndicator(m_d1_slow_handle,1,d1_slow) || !ReadIndicator(m_h4_fast_handle,1,h4_fast) ||
         !ReadIndicator(m_h4_slow_handle,1,h4_slow) ||
         !ReadIndicator(m_h1_atr_handle,1,atr) || !ReadIndicator(m_h1_rsi_handle,1,rsi) ||
         !ReadIndicator(m_h1_adx_handle,1,adx) || !ReadIndicator(m_h4_adx_handle,1,h4_adx))
         return; // データ不良時は何もしない（既存Pending/Activeの状態は次Tickへ持ち越す）

      AdvanceActiveTradesOnNewBar(bar,completed_trades);
      AdvancePendingSetups(bar,atr,completed_setups,completed_trades);
      DetectNewSetup(bar,atr,rsi,adx,h4_adx,d1_close,d1_slow,h4_fast,h4_slow);
     }

public:
   CBreakoutTimingAnalyzer(void)
     {
      m_enabled=false;
      m_d1_slow_handle=INVALID_HANDLE;
      m_h4_fast_handle=INVALID_HANDLE;
      m_h4_slow_handle=INVALID_HANDLE;
      m_h1_atr_handle=INVALID_HANDLE;
      m_h1_rsi_handle=INVALID_HANDLE;
      m_h1_adx_handle=INVALID_HANDLE;
      m_h4_adx_handle=INVALID_HANDLE;
      m_last_bar_time=0;
      m_initialized=false;
     }

   bool Initialize(const SEaConfig &config,string &error)
     {
      Shutdown();
      m_config=config;
      m_enabled=config.enable_breakout_timing_analysis;
      error="";
      if(!m_enabled)
        { m_initialized=true; return true; } // 無効時はIndicatorハンドルすら作成しない（コスト0）
      if(!SymbolSelect(m_config.symbol,true))
        { error="SYMBOL_SELECT_FAILED"; return false; }
      m_d1_slow_handle=iMA(m_config.symbol,m_config.trend_timeframe,m_config.slow_ema_period,0,MODE_EMA,PRICE_CLOSE);
      m_h4_fast_handle=iMA(m_config.symbol,m_config.confirmation_timeframe,m_config.fast_ema_period,0,MODE_EMA,PRICE_CLOSE);
      m_h4_slow_handle=iMA(m_config.symbol,m_config.confirmation_timeframe,m_config.slow_ema_period,0,MODE_EMA,PRICE_CLOSE);
      m_h1_atr_handle=iATR(m_config.symbol,m_config.entry_timeframe,m_config.atr_period);
      m_h1_rsi_handle=iRSI(m_config.symbol,m_config.entry_timeframe,m_config.rsi_period,PRICE_CLOSE);
      m_h1_adx_handle=iADX(m_config.symbol,m_config.entry_timeframe,m_config.adx_period);
      m_h4_adx_handle=iADX(m_config.symbol,m_config.confirmation_timeframe,m_config.adx_period);
      if(m_d1_slow_handle==INVALID_HANDLE || m_h4_fast_handle==INVALID_HANDLE ||
         m_h4_slow_handle==INVALID_HANDLE ||
         m_h1_atr_handle==INVALID_HANDLE || m_h1_rsi_handle==INVALID_HANDLE ||
         m_h1_adx_handle==INVALID_HANDLE || m_h4_adx_handle==INVALID_HANDLE)
        {
         error="INDICATOR_HANDLE_FAILED";
         Shutdown();
         return false;
        }
      m_last_bar_time=0;
      ArrayResize(m_pending,0);
      ArrayResize(m_active,0);
      m_initialized=true;
      return true;
     }

   void Shutdown(void)
     {
      if(m_d1_slow_handle!=INVALID_HANDLE) IndicatorRelease(m_d1_slow_handle);
      if(m_h4_fast_handle!=INVALID_HANDLE) IndicatorRelease(m_h4_fast_handle);
      if(m_h4_slow_handle!=INVALID_HANDLE) IndicatorRelease(m_h4_slow_handle);
      if(m_h1_atr_handle!=INVALID_HANDLE) IndicatorRelease(m_h1_atr_handle);
      if(m_h1_rsi_handle!=INVALID_HANDLE) IndicatorRelease(m_h1_rsi_handle);
      if(m_h1_adx_handle!=INVALID_HANDLE) IndicatorRelease(m_h1_adx_handle);
      if(m_h4_adx_handle!=INVALID_HANDLE) IndicatorRelease(m_h4_adx_handle);
      m_d1_slow_handle=INVALID_HANDLE;
      m_h4_fast_handle=INVALID_HANDLE;
      m_h4_slow_handle=INVALID_HANDLE;
      m_h1_atr_handle=INVALID_HANDLE;
      m_h1_rsi_handle=INVALID_HANDLE;
      m_h1_adx_handle=INVALID_HANDLE;
      m_h4_adx_handle=INVALID_HANDLE;
      m_initialized=false;
     }

   // 毎Tickで呼び出す。完了したSetup/Shadow Trade分析イベントをout配列で返す（呼び出し側が監査ログへ記録する）。
   void OnTick(SBreakoutTimingSetupEvent &completed_setups[],SBreakoutTimingTradeEvent &completed_trades[])
     {
      ArrayResize(completed_setups,0);
      ArrayResize(completed_trades,0);
      if(!m_enabled || !m_initialized) return;

      MqlTick tick;
      if(!SymbolInfoTick(m_config.symbol,tick)) return;

      MonitorActiveTrades(tick,completed_trades);

      const datetime current_bar=iTime(m_config.symbol,m_config.entry_timeframe,0);
      if(current_bar>0 && current_bar!=m_last_bar_time)
        {
         m_last_bar_time=current_bar;
         ProcessNewBar(completed_setups,completed_trades);
        }

      PruneClosedActiveTrades();
     }
  };

#endif
