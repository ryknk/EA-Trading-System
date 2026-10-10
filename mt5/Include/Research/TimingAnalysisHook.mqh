#ifndef EA_TRADING_SYSTEM_TIMING_ANALYSIS_HOOK_MQH
#define EA_TRADING_SYSTEM_TIMING_ANALYSIS_HOOK_MQH

// 研究計測（Entry Timing・Breakout Timing比較）を製品中核から切り離すための研究ビルド専用モジュール。
// EAControllerはEA_TRADING_SYSTEM_RESEARCH_BUILD定義時だけ本ファイルをincludeする
// （docs/product-separation.md 2.3節、DECISIONS.md DEC-045）。
// Shadow Tradeの仮想計測だけを行い、実注文・Risk・既存ポジション管理には一切影響しない。

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/Logging/AuditPayloadBuilder.mqh>
#include <EaTradingSystem/Logging/AuditEventPublisher.mqh>
#include <EaTradingSystem/Logging/EntryTimingAnalyzer.mqh>
#include <EaTradingSystem/Logging/BreakoutTimingAnalyzer.mqh>

// 研究計測イベントのPayload。AuditPayloadBuilderから本文を変更せずに移設した（JSONフィールド名・値・型は不変）。
class CTimingAnalysisPayloadBuilder : public CAuditPayloadBuilder
  {
public:
   // ENTRY_TIMING_SETUPイベントのPayload。
   static string BuildEntryTimingSetupPayload(const SEntryTimingSetupEvent &setup)
     {
      string payload="{";
      payload+="\"setup_bar_time\":"+JString(Iso8601Utc(setup.setup_bar_time))+",";
      payload+="\"direction\":"+JString(SignalDirectionToString(setup.direction))+",";
      payload+="\"pre_entry_mfe_price\":"+JNumber(setup.pre_entry_mfe_price)+",";
      payload+="\"pre_entry_mfe_r\":"+JNumber(setup.pre_entry_mfe_r)+",";
      payload+="\"pre_entry_mfe_time\":"+JString(Iso8601Utc(setup.pre_entry_mfe_time))+",";
      payload+="\"pre_entry_mae_price\":"+JNumber(setup.pre_entry_mae_price)+",";
      payload+="\"pre_entry_mae_r\":"+JNumber(setup.pre_entry_mae_r)+",";
      payload+="\"pre_entry_mae_time\":"+JString(Iso8601Utc(setup.pre_entry_mae_time))+",";
      payload+="\"trigger_found\":"+JBool(setup.trigger_found)+",";
      payload+="\"trigger_wait_bars\":"+IntegerToString(setup.trigger_wait_bars)+"}";
      return payload;
     }

   // ENTRY_TIMING_TRADEイベントのPayload。
   static string BuildEntryTimingTradePayload(const SEntryTimingTradeEvent &trade)
     {
      string checkpoints="{";
      for(int checkpoint_index=0; checkpoint_index<CEntryTimingRules::CheckpointCount(); checkpoint_index++)
        {
         if(!trade.checkpoint_valid[checkpoint_index]) continue;
         if(StringLen(checkpoints)>1) checkpoints+=",";
         checkpoints+="\"bars_"+IntegerToString(CEntryTimingRules::CheckpointBars(checkpoint_index))+"\":"+
                      JNumber(trade.checkpoint_r[checkpoint_index]);
        }
      checkpoints+="}";
      string payload="{";
      payload+="\"variant\":"+JString(EntryTimingVariantToString(trade.variant))+",";
      payload+="\"entry_bar_time\":"+JString(Iso8601Utc(trade.entry_bar_time))+",";
      payload+="\"direction\":"+JString(SignalDirectionToString(trade.direction))+",";
      payload+="\"entry_price\":"+JNumber(trade.entry_price)+",";
      payload+="\"stop_loss\":"+JNumber(trade.stop_loss)+",";
      payload+="\"take_profit\":"+JNumber(trade.take_profit)+",";
      payload+="\"wait_bars\":"+IntegerToString(trade.wait_bars)+",";
      payload+="\"bars_held\":"+IntegerToString(trade.bars_held)+",";
      payload+="\"mfe_r\":"+JNumber(trade.mfe_r)+",";
      payload+="\"mae_r\":"+JNumber(trade.mae_r)+",";
      payload+="\"exit_reason\":"+JString(trade.exit_reason)+",";
      payload+="\"exit_price\":"+JNumber(trade.exit_price)+",";
      payload+="\"pnl_r\":"+JNumber(trade.pnl_r)+",";
      payload+="\"checkpoint_r\":"+checkpoints+"}";
      return payload;
     }

   // BREAKOUT_TIMING_SETUPイベントのPayload。
   static string BuildBreakoutTimingSetupPayload(const SBreakoutTimingSetupEvent &setup)
     {
      string payload="{";
      payload+="\"setup_bar_time\":"+JString(Iso8601Utc(setup.setup_bar_time))+",";
      payload+="\"direction\":"+JString(SignalDirectionToString(setup.direction))+",";
      payload+="\"breakout_level_high\":"+JNumber(setup.breakout_level_high)+",";
      payload+="\"breakout_level_low\":"+JNumber(setup.breakout_level_low)+",";
      payload+="\"pre_entry_mfe_price\":"+JNumber(setup.pre_entry_mfe_price)+",";
      payload+="\"pre_entry_mfe_r\":"+JNumber(setup.pre_entry_mfe_r)+",";
      payload+="\"pre_entry_mfe_time\":"+JString(Iso8601Utc(setup.pre_entry_mfe_time))+",";
      payload+="\"pre_entry_mae_price\":"+JNumber(setup.pre_entry_mae_price)+",";
      payload+="\"pre_entry_mae_r\":"+JNumber(setup.pre_entry_mae_r)+",";
      payload+="\"pre_entry_mae_time\":"+JString(Iso8601Utc(setup.pre_entry_mae_time))+",";
      payload+="\"confirm_1_bar_held\":"+JBool(setup.confirm_1_bar_held)+",";
      payload+="\"confirm_2_bars_held\":"+JBool(setup.confirm_2_bars_held)+",";
      payload+="\"confirm_3_bars_held\":"+JBool(setup.confirm_3_bars_held)+"}";
      return payload;
     }

   // BREAKOUT_TIMING_TRADEイベントのPayload。
   static string BuildBreakoutTimingTradePayload(const SBreakoutTimingTradeEvent &trade)
     {
      string checkpoints="{";
      for(int checkpoint_index=0; checkpoint_index<CEntryTimingRules::CheckpointCount(); checkpoint_index++)
        {
         if(!trade.checkpoint_valid[checkpoint_index]) continue;
         if(StringLen(checkpoints)>1) checkpoints+=",";
         checkpoints+="\"bars_"+IntegerToString(CEntryTimingRules::CheckpointBars(checkpoint_index))+"\":"+
                      JNumber(trade.checkpoint_r[checkpoint_index]);
        }
      checkpoints+="}";
      string payload="{";
      payload+="\"variant\":"+JString(BreakoutTimingVariantToString(trade.variant))+",";
      payload+="\"entry_bar_time\":"+JString(Iso8601Utc(trade.entry_bar_time))+",";
      payload+="\"direction\":"+JString(SignalDirectionToString(trade.direction))+",";
      payload+="\"entry_price\":"+JNumber(trade.entry_price)+",";
      payload+="\"stop_loss\":"+JNumber(trade.stop_loss)+",";
      payload+="\"take_profit\":"+JNumber(trade.take_profit)+",";
      payload+="\"wait_bars\":"+IntegerToString(trade.wait_bars)+",";
      payload+="\"bars_held\":"+IntegerToString(trade.bars_held)+",";
      payload+="\"mfe_r\":"+JNumber(trade.mfe_r)+",";
      payload+="\"mae_r\":"+JNumber(trade.mae_r)+",";
      payload+="\"exit_reason\":"+JString(trade.exit_reason)+",";
      payload+="\"exit_price\":"+JNumber(trade.exit_price)+",";
      payload+="\"pnl_r\":"+JNumber(trade.pnl_r)+",";
      payload+="\"checkpoint_r\":"+checkpoints+"}";
      return payload;
     }
  };

// Entry Timing・Breakout Timing分析器の初期化・Tick処理・監査記録をまとめたEAControllerからの唯一の入口。
// 完了イベントはローカル監査のみへ記録し、Telemetryへは送らない（バー単位で発生しうる高頻度データのため）。
class CTimingAnalysisHook
  {
private:
   CEntryTimingAnalyzer    m_entry_timing_analyzer;
   CBreakoutTimingAnalyzer m_breakout_timing_analyzer;

public:
   bool Initialize(const SEaConfig &config,string &error)
     {
      if(!m_entry_timing_analyzer.Initialize(config,error)) return false;
      return m_breakout_timing_analyzer.Initialize(config,error);
     }

   void Shutdown(void)
     {
      m_entry_timing_analyzer.Shutdown();
      m_breakout_timing_analyzer.Shutdown();
     }

   // 各分析器は無効時（InpEnableEntryTimingAnalysis/InpEnableBreakoutTimingAnalysis=false、既定）に即returnする。
   void OnTick(CAuditEventPublisher &publisher,const string symbol)
     {
      SEntryTimingSetupEvent entry_timing_setups[];
      SEntryTimingTradeEvent entry_timing_trades[];
      m_entry_timing_analyzer.OnTick(entry_timing_setups,entry_timing_trades);
      for(int index=0; index<ArraySize(entry_timing_setups); index++)
         publisher.Audit("ENTRY_TIMING_SETUP",entry_timing_setups[index].setup_id,"",symbol,
                         CTimingAnalysisPayloadBuilder::BuildEntryTimingSetupPayload(entry_timing_setups[index]),false);
      for(int index=0; index<ArraySize(entry_timing_trades); index++)
         publisher.Audit("ENTRY_TIMING_TRADE",entry_timing_trades[index].setup_id,"",symbol,
                         CTimingAnalysisPayloadBuilder::BuildEntryTimingTradePayload(entry_timing_trades[index]),false);

      SBreakoutTimingSetupEvent breakout_timing_setups[];
      SBreakoutTimingTradeEvent breakout_timing_trades[];
      m_breakout_timing_analyzer.OnTick(breakout_timing_setups,breakout_timing_trades);
      for(int index=0; index<ArraySize(breakout_timing_setups); index++)
         publisher.Audit("BREAKOUT_TIMING_SETUP",breakout_timing_setups[index].setup_id,"",symbol,
                         CTimingAnalysisPayloadBuilder::BuildBreakoutTimingSetupPayload(breakout_timing_setups[index]),false);
      for(int index=0; index<ArraySize(breakout_timing_trades); index++)
         publisher.Audit("BREAKOUT_TIMING_TRADE",breakout_timing_trades[index].setup_id,"",symbol,
                         CTimingAnalysisPayloadBuilder::BuildBreakoutTimingTradePayload(breakout_timing_trades[index]),false);
     }
  };

#endif
