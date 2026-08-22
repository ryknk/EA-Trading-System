#ifndef EA_TRADING_SYSTEM_ENTRY_TIMING_ANALYZER_MQH
#define EA_TRADING_SYSTEM_ENTRY_TIMING_ANALYZER_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/Strategy/TrendFollowingRules.mqh>

// 分析専用のEntry Timing比較機能。同一のプルバックSetupについて、
//   IMMEDIATE   : Setup成立bar自身の終値で即Entry
//   WAIT_1_BAR  : 1本待ってEntry
//   WAIT_2_BARS : 2本待ってEntry
//   WAIT_TRIGGER: Setup後のTrigger（再加速）成立を待ってEntry
// の4方式を、実発注を一切伴わないShadow Tradeとして並行シミュレートし、監査ログへ記録する。
// 過去データへ最も適合する待機時間を自動採用する処理は実装しない（判断はユーザー・分析側に委ねる）。
// ブレイクアウトパターンはSetupとTriggerが同一の価格事象（レンジ突破）であり、両者の間に
// 待機できる中間状態が存在しないため、本分析の対象外とする（プルバックのみを対象とする）。
// 既存Strategy/PositionManagerには一切影響しない（自己完結、読み取り専用、実注文を出さない）。
enum EEntryTimingVariant
  {
   ENTRY_TIMING_IMMEDIATE=0,
   ENTRY_TIMING_WAIT_1_BAR=1,
   ENTRY_TIMING_WAIT_2_BARS=2,
   ENTRY_TIMING_WAIT_TRIGGER=3
  };

string EntryTimingVariantToString(const EEntryTimingVariant variant)
  {
   if(variant==ENTRY_TIMING_IMMEDIATE)    return "IMMEDIATE";
   if(variant==ENTRY_TIMING_WAIT_1_BAR)   return "WAIT_1_BAR";
   if(variant==ENTRY_TIMING_WAIT_2_BARS)  return "WAIT_2_BARS";
   if(variant==ENTRY_TIMING_WAIT_TRIGGER) return "WAIT_TRIGGER";
   return "UNKNOWN";
  }

// Shadow Trade判定の純粋関数群（単体テスト対象）。実注文・実ポジションには一切関与しない。
class CEntryTimingRules
  {
public:
   static int CheckpointCount(void) { return 6; }

   // Entry後の価格推移を観測する固定バーオフセット（本数）。閾値の自動最適化対象ではなく、
   // 「どの本数で何が起きているか」を一覧できるようにするための観測点。
   static int CheckpointBars(const int index)
     {
      static const int bars[6]={1,2,3,5,10,20};
      if(index<0 || index>=6) return 0;
      return bars[index];
     }

   static double StopDistance(const double atr,const double stop_atr_multiple)
     {
      if(atr<=0.0 || stop_atr_multiple<=0.0) return 0.0;
      return atr*stop_atr_multiple;
     }

   static double ComputeStopLoss(const ESignalDirection direction,const double entry_price,const double stop_distance)
     {
      if(direction==SIGNAL_DIRECTION_BUY)  return entry_price-stop_distance;
      if(direction==SIGNAL_DIRECTION_SELL) return entry_price+stop_distance;
      return 0.0;
     }

   static double ComputeTakeProfit(const ESignalDirection direction,const double entry_price,
                                   const double stop_distance,const double risk_reward_ratio)
     {
      if(direction==SIGNAL_DIRECTION_BUY)  return entry_price+stop_distance*risk_reward_ratio;
      if(direction==SIGNAL_DIRECTION_SELL) return entry_price-stop_distance*risk_reward_ratio;
      return 0.0;
     }

   // stop_distanceを1Rとした価格差のR換算。stop_distance<=0の場合は換算不能として0を返す。
   static double PriceToR(const ESignalDirection direction,const double reference_price,
                          const double current_price,const double stop_distance)
     {
      if(stop_distance<=0.0) return 0.0;
      if(direction==SIGNAL_DIRECTION_BUY)  return (current_price-reference_price)/stop_distance;
      if(direction==SIGNAL_DIRECTION_SELL) return (reference_price-current_price)/stop_distance;
      return 0.0;
     }

   static bool IsStopLossHit(const ESignalDirection direction,const double stop_loss,
                             const double bid,const double ask)
     {
      if(stop_loss<=0.0) return false;
      if(direction==SIGNAL_DIRECTION_BUY)  return bid<=stop_loss;
      if(direction==SIGNAL_DIRECTION_SELL) return ask>=stop_loss;
      return false;
     }

   static bool IsTakeProfitHit(const ESignalDirection direction,const double take_profit,
                               const double bid,const double ask)
     {
      if(take_profit<=0.0) return false;
      if(direction==SIGNAL_DIRECTION_BUY)  return bid>=take_profit;
      if(direction==SIGNAL_DIRECTION_SELL) return ask<=take_profit;
      return false;
     }

   // 方向に対する順行側(favorable)・逆行側(adverse)の極値を更新する。
   static void UpdateExcursion(const ESignalDirection direction,const double price,
                               double &favorable_extreme,double &adverse_extreme)
     {
      if(direction==SIGNAL_DIRECTION_BUY)
        {
         if(price>favorable_extreme) favorable_extreme=price;
         if(price<adverse_extreme) adverse_extreme=price;
        }
      else if(direction==SIGNAL_DIRECTION_SELL)
        {
         if(price<favorable_extreme) favorable_extreme=price;
         if(price>adverse_extreme) adverse_extreme=price;
        }
     }
  };

// EAControllerが監査ログへ書き出すための完了イベント（Setup単位）。
struct SEntryTimingSetupEvent
  {
   string           setup_id;
   datetime         setup_bar_time;
   ESignalDirection direction;
   double           pre_entry_mfe_price;
   double           pre_entry_mfe_r;
   datetime         pre_entry_mfe_time;
   double           pre_entry_mae_price;
   double           pre_entry_mae_r;
   datetime         pre_entry_mae_time;
   bool             trigger_found;
   int              trigger_wait_bars; // trigger_found=falseの場合は-1
  };

// EAControllerが監査ログへ書き出すための完了イベント（Variant単位のShadow Trade）。
struct SEntryTimingTradeEvent
  {
   string              setup_id;
   EEntryTimingVariant variant;
   datetime            entry_bar_time;
   ESignalDirection    direction;
   double              entry_price;
   double              stop_loss;
   double              take_profit;
   int                 wait_bars;
   int                 bars_held;
   double              mfe_r;
   double              mae_r;
   string              exit_reason; // "SL" / "TP" / "EXPIRED"
   double              exit_price;
   double              pnl_r;
   double              checkpoint_r[6];
   bool                checkpoint_valid[6];
  };

class CEntryTimingAnalyzer
  {
private:
   struct SPendingSetup
     {
      string           setup_id;
      datetime         setup_bar_time;
      ESignalDirection direction;
      double           setup_high;
      double           setup_low;
      double           setup_close;
      double           setup_atr;
      int              bars_elapsed;
      bool             variant_b_done;
      bool             variant_c_done;
      bool             trigger_done;
      bool             trigger_expired;
      int              trigger_wait_bars; // trigger成立時点のbars_elapsed（完了イベント出力が後続barへずれても正しい値を保持する）
      double           favorable_extreme;
      double           adverse_extreme;
      datetime         favorable_time;
      datetime         adverse_time;
     };

   struct SActiveTrade
     {
      string              setup_id;
      EEntryTimingVariant variant;
      ESignalDirection    direction;
      datetime            entry_bar_time;
      double              entry_price;
      double              stop_loss;
      double              take_profit;
      double              stop_distance;
      int                 wait_bars;
      int                 bars_held;
      double              favorable_extreme;
      double              adverse_extreme;
      double              checkpoint_r[6];
      bool                checkpoint_valid[6];
      bool                closed;
     };

   SEaConfig      m_config;
   bool           m_enabled;
   int            m_d1_slow_handle;
   int            m_h4_fast_handle;
   int            m_h4_slow_handle;
   int            m_h1_fast_handle;
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

   void RegisterActiveTrade(const string setup_id,const EEntryTimingVariant variant,
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
                            SEntryTimingTradeEvent &completed_trades[])
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
   void MonitorActiveTrades(const MqlTick &tick,SEntryTimingTradeEvent &completed_trades[])
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
   void AdvanceActiveTradesOnNewBar(const MqlRates &bar,SEntryTimingTradeEvent &completed_trades[])
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
         if(bars_held>=m_config.entry_timing_max_holding_bars)
            FinalizeActiveTrade(index,"EXPIRED",bar.close,completed_trades);
        }
     }

   // 新確定足ごとに1回: 既存Pending Setupの進行（本数計測・Variant B/C/D解決・完了イベント出力）。
   void AdvancePendingSetups(const MqlRates &bar,const double ema,const double atr,
                             SEntryTimingSetupEvent &completed_setups[],SEntryTimingTradeEvent &completed_trades[])
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

         if(elapsed==1 && !m_pending[index].variant_b_done)
           {
            m_pending[index].variant_b_done=true;
            RegisterActiveTrade(m_pending[index].setup_id,ENTRY_TIMING_WAIT_1_BAR,direction,bar.time,bar.close,atr,elapsed);
           }
         if(elapsed==2 && !m_pending[index].variant_c_done)
           {
            m_pending[index].variant_c_done=true;
            RegisterActiveTrade(m_pending[index].setup_id,ENTRY_TIMING_WAIT_2_BARS,direction,bar.time,bar.close,atr,elapsed);
           }
         if(!m_pending[index].trigger_done && !m_pending[index].trigger_expired)
           {
            if(CTrendFollowingRules::IsPullbackTrigger(direction,bar.open,bar.close,ema,
                                                        m_pending[index].setup_high,m_pending[index].setup_low))
              {
               m_pending[index].trigger_done=true;
               m_pending[index].trigger_wait_bars=elapsed;
               RegisterActiveTrade(m_pending[index].setup_id,ENTRY_TIMING_WAIT_TRIGGER,direction,bar.time,bar.close,atr,elapsed);
              }
            else if(elapsed>=m_config.entry_timing_max_wait_bars)
               m_pending[index].trigger_expired=true;
           }

         if(m_pending[index].variant_b_done && m_pending[index].variant_c_done &&
            (m_pending[index].trigger_done || m_pending[index].trigger_expired))
           {
            const int slot=ArraySize(completed_setups);
            ArrayResize(completed_setups,slot+1);
            const double setup_stop_distance=CEntryTimingRules::StopDistance(m_pending[index].setup_atr,m_config.stop_atr_multiple);
            completed_setups[slot].setup_id=m_pending[index].setup_id;
            completed_setups[slot].setup_bar_time=m_pending[index].setup_bar_time;
            completed_setups[slot].direction=direction;
            completed_setups[slot].pre_entry_mfe_price=m_pending[index].favorable_extreme;
            completed_setups[slot].pre_entry_mfe_r=CEntryTimingRules::PriceToR(direction,m_pending[index].setup_close,
                                                                                m_pending[index].favorable_extreme,setup_stop_distance);
            completed_setups[slot].pre_entry_mfe_time=m_pending[index].favorable_time;
            completed_setups[slot].pre_entry_mae_price=m_pending[index].adverse_extreme;
            completed_setups[slot].pre_entry_mae_r=CEntryTimingRules::PriceToR(direction,m_pending[index].setup_close,
                                                                                m_pending[index].adverse_extreme,setup_stop_distance);
            completed_setups[slot].pre_entry_mae_time=m_pending[index].adverse_time;
            completed_setups[slot].trigger_found=m_pending[index].trigger_done;
            completed_setups[slot].trigger_wait_bars=(m_pending[index].trigger_done ? m_pending[index].trigger_wait_bars : -1);

            const int last=ArraySize(m_pending)-1;
            m_pending[index]=m_pending[last];
            ArrayResize(m_pending,last);
           }
        }
     }

   // 新確定足ごとに1回: このbar自身がプルバックSetup（タッチ足）として成立するかを判定し、
   // 成立していればPendingへ登録した上でVariant A（即時Entry）を確定する。
   // 既存CTrendFollowingStrategy::Evaluateと同じ上流ゲート（HTF Bias/ATR/ADX/RSI）を独立に再評価する
   // （Strategy本体とは完全に分離した自己完結モジュールとするための意図的な重複、DECISIONS.md参照）。
   void DetectNewSetup(const MqlRates &bar,const double ema,const double atr,const double rsi,
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
      if(!CTrendFollowingRules::IsPullbackSetup(direction,bar.high,bar.low,ema,atr,m_config.pullback_atr_tolerance))
         return;

      const string setup_id=StringFormat("ET-%s-%s-%I64d",m_config.ea_id,m_config.symbol,(long)bar.time);
      const int slot=ArraySize(m_pending);
      ArrayResize(m_pending,slot+1);
      m_pending[slot].setup_id=setup_id;
      m_pending[slot].setup_bar_time=bar.time;
      m_pending[slot].direction=direction;
      m_pending[slot].setup_high=bar.high;
      m_pending[slot].setup_low=bar.low;
      m_pending[slot].setup_close=bar.close;
      m_pending[slot].setup_atr=atr;
      m_pending[slot].bars_elapsed=0;
      m_pending[slot].variant_b_done=false;
      m_pending[slot].variant_c_done=false;
      m_pending[slot].trigger_done=false;
      m_pending[slot].trigger_expired=false;
      m_pending[slot].trigger_wait_bars=-1;
      m_pending[slot].favorable_extreme=bar.close;
      m_pending[slot].adverse_extreme=bar.close;
      m_pending[slot].favorable_time=bar.time;
      m_pending[slot].adverse_time=bar.time;

      RegisterActiveTrade(setup_id,ENTRY_TIMING_IMMEDIATE,direction,bar.time,bar.close,atr,0);
     }

   void ProcessNewBar(SEntryTimingSetupEvent &completed_setups[],SEntryTimingTradeEvent &completed_trades[])
     {
      MqlRates rates[1];
      if(CopyRates(m_config.symbol,m_config.entry_timeframe,1,1,rates)!=1) return;
      const MqlRates bar=rates[0];
      if(bar.time<=0 || bar.close<=0.0) return;

      double ema,atr,rsi,adx,h4_adx,d1_slow,h4_fast,h4_slow;
      const double d1_close=iClose(m_config.symbol,m_config.trend_timeframe,1);
      if(d1_close<=0.0 ||
         !ReadIndicator(m_d1_slow_handle,1,d1_slow) || !ReadIndicator(m_h4_fast_handle,1,h4_fast) ||
         !ReadIndicator(m_h4_slow_handle,1,h4_slow) || !ReadIndicator(m_h1_fast_handle,1,ema) ||
         !ReadIndicator(m_h1_atr_handle,1,atr) || !ReadIndicator(m_h1_rsi_handle,1,rsi) ||
         !ReadIndicator(m_h1_adx_handle,1,adx) || !ReadIndicator(m_h4_adx_handle,1,h4_adx))
         return; // データ不良時は何もしない（既存Pending/Activeの状態は次Tickへ持ち越す）

      AdvanceActiveTradesOnNewBar(bar,completed_trades);
      AdvancePendingSetups(bar,ema,atr,completed_setups,completed_trades);
      DetectNewSetup(bar,ema,atr,rsi,adx,h4_adx,d1_close,d1_slow,h4_fast,h4_slow);
     }

public:
   CEntryTimingAnalyzer(void)
     {
      m_enabled=false;
      m_d1_slow_handle=INVALID_HANDLE;
      m_h4_fast_handle=INVALID_HANDLE;
      m_h4_slow_handle=INVALID_HANDLE;
      m_h1_fast_handle=INVALID_HANDLE;
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
      m_enabled=config.enable_entry_timing_analysis;
      error="";
      if(!m_enabled)
        { m_initialized=true; return true; } // 無効時はIndicatorハンドルすら作成しない（コスト0）
      if(!SymbolSelect(m_config.symbol,true))
        { error="SYMBOL_SELECT_FAILED"; return false; }
      m_d1_slow_handle=iMA(m_config.symbol,m_config.trend_timeframe,m_config.slow_ema_period,0,MODE_EMA,PRICE_CLOSE);
      m_h4_fast_handle=iMA(m_config.symbol,m_config.confirmation_timeframe,m_config.fast_ema_period,0,MODE_EMA,PRICE_CLOSE);
      m_h4_slow_handle=iMA(m_config.symbol,m_config.confirmation_timeframe,m_config.slow_ema_period,0,MODE_EMA,PRICE_CLOSE);
      m_h1_fast_handle=iMA(m_config.symbol,m_config.entry_timeframe,m_config.fast_ema_period,0,MODE_EMA,PRICE_CLOSE);
      m_h1_atr_handle=iATR(m_config.symbol,m_config.entry_timeframe,m_config.atr_period);
      m_h1_rsi_handle=iRSI(m_config.symbol,m_config.entry_timeframe,m_config.rsi_period,PRICE_CLOSE);
      m_h1_adx_handle=iADX(m_config.symbol,m_config.entry_timeframe,m_config.adx_period);
      m_h4_adx_handle=iADX(m_config.symbol,m_config.confirmation_timeframe,m_config.adx_period);
      if(m_d1_slow_handle==INVALID_HANDLE || m_h4_fast_handle==INVALID_HANDLE ||
         m_h4_slow_handle==INVALID_HANDLE || m_h1_fast_handle==INVALID_HANDLE ||
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
      if(m_h1_fast_handle!=INVALID_HANDLE) IndicatorRelease(m_h1_fast_handle);
      if(m_h1_atr_handle!=INVALID_HANDLE) IndicatorRelease(m_h1_atr_handle);
      if(m_h1_rsi_handle!=INVALID_HANDLE) IndicatorRelease(m_h1_rsi_handle);
      if(m_h1_adx_handle!=INVALID_HANDLE) IndicatorRelease(m_h1_adx_handle);
      if(m_h4_adx_handle!=INVALID_HANDLE) IndicatorRelease(m_h4_adx_handle);
      m_d1_slow_handle=INVALID_HANDLE;
      m_h4_fast_handle=INVALID_HANDLE;
      m_h4_slow_handle=INVALID_HANDLE;
      m_h1_fast_handle=INVALID_HANDLE;
      m_h1_atr_handle=INVALID_HANDLE;
      m_h1_rsi_handle=INVALID_HANDLE;
      m_h1_adx_handle=INVALID_HANDLE;
      m_h4_adx_handle=INVALID_HANDLE;
      m_initialized=false;
     }

   // 毎Tickで呼び出す。完了したSetup/Shadow Trade分析イベントをout配列で返す（呼び出し側が監査ログへ記録する）。
   void OnTick(SEntryTimingSetupEvent &completed_setups[],SEntryTimingTradeEvent &completed_trades[])
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
