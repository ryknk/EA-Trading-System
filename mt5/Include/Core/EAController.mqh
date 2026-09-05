#ifndef EA_TRADING_SYSTEM_EA_CONTROLLER_MQH
#define EA_TRADING_SYSTEM_EA_CONTROLLER_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/Strategy/TrendFollowingStrategy.mqh>
#include <EaTradingSystem/Strategy/MeanReversionStrategy.mqh>
#include <EaTradingSystem/Signal/SignalEngine.mqh>
#include <EaTradingSystem/Risk/RiskManager.mqh>
#include <EaTradingSystem/Trading/OrderManager.mqh>
#include <EaTradingSystem/Trading/PositionManager.mqh>
#include <EaTradingSystem/Trading/PositionExitEvaluator.mqh>
#include <EaTradingSystem/External/DecisionApiClient.mqh>
#include <EaTradingSystem/External/MockDecisionProvider.mqh>
#include <EaTradingSystem/Logging/TradeLogger.mqh>
#include <EaTradingSystem/Logging/TradeAnalyticsTracker.mqh>
#include <EaTradingSystem/Logging/EntryTimingAnalyzer.mqh>
#include <EaTradingSystem/Logging/BreakoutTimingAnalyzer.mqh>
#include <EaTradingSystem/Logging/AuditPayloadBuilder.mqh>
#include <EaTradingSystem/Logging/AuditEventPublisher.mqh>
#include <EaTradingSystem/Core/ClosedPositionProcessor.mqh>

class CEAController
  {
private:
   SEaConfig                   m_config;
   CTrendFollowingStrategy     m_strategy;
   CSignalEngine               m_signal_engine;
   // II案（平均回帰、2026-08-24追加）: トレンドフォロー戦略とは独立した第二の候補生成源。
   // InpEnableMeanReversionStrategy=false（既定）では初期化も評価も行われず、既存挙動を一切変えない。
   CMeanReversionStrategy      m_mean_reversion_strategy;
   CSignalEngine               m_mean_reversion_signal_engine;
   CRiskManager                m_risk_manager;
   COrderManager               m_order_manager;
   CPositionManager            m_position_manager;
   CPositionExitEvaluator      m_position_exit_evaluator;
   CDecisionApiClient          m_decision_client;
   CMockDecisionProvider       m_mock_decision_provider;
   CAuditEventPublisher        m_audit_publisher;
   CTradeAnalyticsTracker      m_analytics_tracker;
   CClosedPositionProcessor    m_closed_position_processor;
   CEntryTimingAnalyzer        m_entry_timing_analyzer;
   CBreakoutTimingAnalyzer     m_breakout_timing_analyzer;
   bool                        m_initialized;
   datetime                    m_last_risk_error_log;
   string                      m_last_risk_lock_code;
   datetime                    m_last_position_error_log;
   int                         m_last_snapshot_day;

   string JString(const string value) { return CAuditPayloadBuilder::JString(value); }
   string JNumber(const double value) { return CAuditPayloadBuilder::JNumber(value); }

   string SafeIdentifier(const string value,const string fallback)
     {
      return CTradeLogRules::SafeIdentifier(value,fallback);
     }

   // ローカルAudit記録・Telemetry送信の詳細はCAuditEventPublisherへ委譲する
   // （Telemetry障害が売買処理へ影響しない設計を維持する）。
   void Audit(const string event_type,const string candidate_id,const string request_id,
              const string symbol,const string payload,const bool send_remote)
     {
      m_audit_publisher.Audit(event_type,candidate_id,request_id,symbol,payload,send_remote);
     }

   void AuditSystemError(const string component,const string code,const string reason)
     {
      const string payload="{\"component\":"+JString(SafeIdentifier(component,"EA"))+","+
                           "\"reason_code\":"+JString(SafeIdentifier(code,"UNKNOWN_ERROR"))+","+
                           "\"reason\":"+JString(reason)+"}";
      // Telemetry transport failures never call this helper, avoiding recursive
      // reporting while still persisting operational component failures.
      Audit("SYSTEM_ERROR","system","",m_config.symbol,payload,true);
     }

   // Entry Timing分析（分析専用、実注文なし）の完了イベントを監査ログへ記録する。
   // Telemetryへは送らない（バー単位で発生しうる高頻度データのためローカル監査のみ）。
   void AuditEntryTimingEvents(const SEntryTimingSetupEvent &setups[],const SEntryTimingTradeEvent &trades[])
     {
      for(int index=0; index<ArraySize(setups); index++)
         Audit("ENTRY_TIMING_SETUP",setups[index].setup_id,"",m_config.symbol,
               CAuditPayloadBuilder::BuildEntryTimingSetupPayload(setups[index]),false);
      for(int index=0; index<ArraySize(trades); index++)
         Audit("ENTRY_TIMING_TRADE",trades[index].setup_id,"",m_config.symbol,
               CAuditPayloadBuilder::BuildEntryTimingTradePayload(trades[index]),false);
     }

   // Breakout Timing分析（分析専用、実注文なし）の完了イベントを監査ログへ記録する。
   // Telemetryへは送らない（バー単位で発生しうる高頻度データのためローカル監査のみ、
   // AuditEntryTimingEventsと同じ方針）。
   void AuditBreakoutTimingEvents(const SBreakoutTimingSetupEvent &setups[],const SBreakoutTimingTradeEvent &trades[])
     {
      for(int index=0; index<ArraySize(setups); index++)
         Audit("BREAKOUT_TIMING_SETUP",setups[index].setup_id,"",m_config.symbol,
               CAuditPayloadBuilder::BuildBreakoutTimingSetupPayload(setups[index]),false);
      for(int index=0; index<ArraySize(trades); index++)
         Audit("BREAKOUT_TIMING_TRADE",trades[index].setup_id,"",m_config.symbol,
               CAuditPayloadBuilder::BuildBreakoutTimingTradePayload(trades[index]),false);
     }

   string DealEntryName(const ENUM_DEAL_ENTRY entry)
     {
      if(entry==DEAL_ENTRY_IN) return "IN";
      if(entry==DEAL_ENTRY_OUT) return "OUT";
      if(entry==DEAL_ENTRY_INOUT) return "INOUT";
      if(entry==DEAL_ENTRY_OUT_BY) return "OUT_BY";
      return "UNKNOWN";
     }

   void AuditDailySnapshots(void)
     {
      const datetime now=TimeGMT();
      if(now<=0) return;
      const int day=(int)(now/86400);
      if(day==m_last_snapshot_day) return;
      m_last_snapshot_day=day;
      string account_payload="{";
      account_payload+="\"balance\":"+JNumber(AccountInfoDouble(ACCOUNT_BALANCE))+",";
      account_payload+="\"equity\":"+JNumber(AccountInfoDouble(ACCOUNT_EQUITY))+",";
      account_payload+="\"margin\":"+JNumber(AccountInfoDouble(ACCOUNT_MARGIN))+",";
      account_payload+="\"free_margin\":"+JNumber(AccountInfoDouble(ACCOUNT_MARGIN_FREE))+",";
      account_payload+="\"margin_level\":"+JNumber(AccountInfoDouble(ACCOUNT_MARGIN_LEVEL))+",";
      account_payload+="\"open_positions\":"+IntegerToString(PositionsTotal())+"}";
      Audit("ACCOUNT_SNAPSHOT","system","",m_config.symbol,account_payload,true);

      const int total=PositionsTotal();
      for(int index=0; index<total; index++)
        {
         const ulong ticket=PositionGetTicket(index);
         if(ticket==0 || !CPositionProtectionRules::IsManagedPosition(
               PositionGetInteger(POSITION_MAGIC),m_config.magic_number,m_config.mean_reversion_magic_number))
            continue;
         const string symbol=PositionGetString(POSITION_SYMBOL);
         const ulong identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
         const ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         string payload="{";
         payload+="\"position_ticket\":"+JString(StringFormat("%I64u",ticket))+",";
         payload+="\"direction\":"+JString(type==POSITION_TYPE_BUY ? "BUY" : "SELL")+",";
         payload+="\"volume\":"+JNumber(PositionGetDouble(POSITION_VOLUME))+",";
         payload+="\"open_price\":"+JNumber(PositionGetDouble(POSITION_PRICE_OPEN))+",";
         payload+="\"current_price\":"+JNumber(PositionGetDouble(POSITION_PRICE_CURRENT))+",";
         payload+="\"stop_loss\":"+JNumber(PositionGetDouble(POSITION_SL))+",";
         payload+="\"take_profit\":"+JNumber(PositionGetDouble(POSITION_TP))+",";
         payload+="\"unrealized_pnl\":"+JNumber(PositionGetDouble(POSITION_PROFIT))+"}";
         Audit("POSITION_SNAPSHOT",
               CClosedPositionProcessor::CandidateForPosition(m_config.ea_id,identifier,symbol),"",symbol,payload,true);
        }
     }

public:
   CEAController(void)
     {
      m_initialized=false;
      m_last_risk_error_log=0;
      m_last_risk_lock_code="";
      m_last_position_error_log=0;
      m_last_snapshot_day=-1;
     }

   bool Initialize(const SEaConfig &config,string &error)
     {
      error="";
      if(!ValidateConfig(config,error))
         return false;
      m_config=config;
      m_audit_publisher.Initialize(m_config);
      m_analytics_tracker.Initialize(m_config.magic_number,m_config.mean_reversion_magic_number);
      m_closed_position_processor.Initialize(m_config,GetPointer(m_audit_publisher),GetPointer(m_analytics_tracker));
      if(!m_strategy.Initialize(m_config,error))
         return false;
      if(!m_signal_engine.Initialize(GetPointer(m_strategy),m_config.symbol,m_config.entry_timeframe,error))
        {
         m_strategy.Shutdown();
         return false;
        }
      if(!m_risk_manager.Initialize(m_config,error))
        {
         m_strategy.Shutdown();
         return false;
        }
      if(!m_order_manager.Initialize(m_config,error) || !m_position_manager.Initialize(m_config,error))
        {
         m_strategy.Shutdown();
         return false;
        }
      m_position_exit_evaluator.Initialize(m_config,GetPointer(m_strategy),GetPointer(m_mean_reversion_strategy),
                                            GetPointer(m_position_manager),GetPointer(m_audit_publisher));
      if(!m_entry_timing_analyzer.Initialize(m_config,error))
        {
         m_strategy.Shutdown();
         return false;
        }
      if(!m_breakout_timing_analyzer.Initialize(m_config,error))
        {
         m_strategy.Shutdown();
         return false;
        }
      const bool use_mock=(MQLInfoInteger(MQL_TESTER) && m_config.tester_decision_mode!=TESTER_DECISION_FAIL_SAFE);
      if(!(use_mock ? m_mock_decision_provider.Initialize(m_config,error) : m_decision_client.Initialize(m_config,error)))
        {
         m_strategy.Shutdown();
         return false;
        }
      if(m_config.enable_mean_reversion_strategy)
        {
         if(!m_mean_reversion_strategy.Initialize(m_config,error))
           {
            m_strategy.Shutdown();
            return false;
           }
         if(!m_mean_reversion_signal_engine.Initialize(GetPointer(m_mean_reversion_strategy),m_config.symbol,
                                                        m_config.entry_timeframe,error))
           {
            m_strategy.Shutdown();
            m_mean_reversion_strategy.Shutdown();
            return false;
           }
        }
      m_initialized=true;
      PrintFormat("KILL_SWITCH_STATE emergency_stop=%s strategy_enabled=%s new_orders=%s existing_position_management=true",
                  (m_config.emergency_stop ? "enabled" : "disabled"),
                  (m_config.strategy_enabled ? "enabled" : "disabled"),
                  (!m_config.emergency_stop && m_config.strategy_enabled ? "enabled" : "disabled"));
      PrintFormat("EA_INIT_OK ea_id=%s strategy=%s symbol=%s entry_tf=%s phase=9 decision_api=%s telemetry=%s trade_mutations=%s",
                  m_config.ea_id,m_strategy.Name(),m_config.symbol,EnumToString(m_config.entry_timeframe),
                  (m_config.decision_api_enabled ? "enabled" : "disabled"),
                  (m_config.telemetry_enabled ? "enabled" : "disabled"),
                  (m_config.enable_trade_mutations ? "enabled" : "disabled"));
      return true;
     }

   void Shutdown(void)
     {
      m_initialized=false;
      m_audit_publisher.Shutdown();
      m_decision_client.Shutdown();
      m_mock_decision_provider.Shutdown();
      m_entry_timing_analyzer.Shutdown();
      m_breakout_timing_analyzer.Shutdown();
      m_strategy.Shutdown();
      m_mean_reversion_strategy.Shutdown();
     }

   void OnTick(void)
     {
      if(!m_initialized)
         return;

      // Existing positions are always inspected before any new candidate processing.
      string position_error;
      const bool positions_healthy=m_position_manager.Monitor(position_error);
      m_risk_manager.SetOperationalHealth(positions_healthy,position_error);
      if(!positions_healthy)
        {
         const datetime position_now=TimeLocal();
         if(position_now-m_last_position_error_log>=60)
           {
            PrintFormat("POSITION_MONITOR_ERROR code=%s new_orders=false",position_error);
            // position_errorはPositionManager::Monitor()が返す詳細理由。AuditSystemError()の
            // 第2引数(reason_code)はSafeCorrelationId検証を通らない値だと"UNKNOWN_ERROR"へ
            // フォールバックし詳細が失われるため、常に安全な固定識別子を渡し、詳細はreason（自由文字列、
            // 検証なし）側で運ぶ（RISK_MANAGER/SIGNAL_ENGINE呼び出しと同じパターン）。
            AuditSystemError("POSITION_MANAGER","POSITION_MONITOR_ERROR",
                             StringFormat("Managed position monitoring failed: %s",position_error));
            m_last_position_error_log=position_now;
           }
        }
      // 分析専用のMFE/MAE追跡。既存ポジション管理の判断・発注には一切影響しない。
      m_analytics_tracker.Update();
      // 分析専用。Entry Timing比較（Setup成立時即時/1本待ち/2本待ち/Trigger待ち）をShadow Tradeとして
      // 並行シミュレートする。実注文は一切発生しない。InpEnableEntryTimingAnalysis=false（既定）では即return。
      SEntryTimingSetupEvent entry_timing_setups[];
      SEntryTimingTradeEvent entry_timing_trades[];
      m_entry_timing_analyzer.OnTick(entry_timing_setups,entry_timing_trades);
      AuditEntryTimingEvents(entry_timing_setups,entry_timing_trades);
      // 分析専用。ブレイクアウトTiming比較（即時Entry/1〜3本後のブレイクアウトレベル維持確認）を
      // Shadow Tradeとして並行シミュレートする。実注文は一切発生しない。
      // InpEnableBreakoutTimingAnalysis=false（既定）では即return。
      SBreakoutTimingSetupEvent breakout_timing_setups[];
      SBreakoutTimingTradeEvent breakout_timing_trades[];
      m_breakout_timing_analyzer.OnTick(breakout_timing_setups,breakout_timing_trades);
      AuditBreakoutTimingEvents(breakout_timing_setups,breakout_timing_trades);
      // 分析専用。前Tickで決済検知しキューへ積んだポジションの履歴を確定させる。
      m_closed_position_processor.ProcessPending();
      // 既存ポジション管理の一部。エントリー根拠（トレンド/ADX）が消失した保有ポジションを
      // 満期(SL/TP)を待たず早期決済する。新規候補評価より先に行う。
      m_position_exit_evaluator.EvaluateSignalInvalidationExits();
      // 既存ポジション管理の一部。Entry後の経過バー数が上限を超えたポジションを、シグナルの
      // 有効期限切れとみなし早期決済する（必要に応じ最低MFE到達判定を伴う）。
      m_position_exit_evaluator.EvaluateTimeStopExits();
      // レンジ戦略のポジション管理（トレンド戦略とは独立）。Range Filter解除・レンジブレイク・
      // BB Width急拡大での早期決済、および独立した時間切れ決済。
      m_position_exit_evaluator.EvaluateMeanReversionForcedExits();
      m_position_exit_evaluator.EvaluateMeanReversionTimeStopExits();

      string risk_lock_code,risk_monitor_error;
      if(!m_risk_manager.Monitor(risk_lock_code,risk_monitor_error))
        {
         const datetime now=TimeLocal();
         if(now-m_last_risk_error_log>=60)
           {
            PrintFormat("RISK_MONITOR_ERROR code=RISK_STATE_UNAVAILABLE reason=%s",risk_monitor_error);
            AuditSystemError("RISK_MANAGER","RISK_STATE_UNAVAILABLE",risk_monitor_error);
            m_last_risk_error_log=now;
           }
        }

      else if(StringLen(risk_lock_code)>0 && risk_lock_code!=m_last_risk_lock_code)
        {
         PrintFormat("RISK_LOCK_ACTIVE code=%s new_orders=false",risk_lock_code);
         m_last_risk_lock_code=risk_lock_code;
        }

      AuditDailySnapshots();

      // Kill switches stop only new candidate processing. Existing-position and
      // account-risk monitoring above must continue even during an emergency.
      if(!CDecisionPolicyRules::IsNewCandidateProcessingAllowed(m_config.emergency_stop,m_config.strategy_enabled))
         return;

      SSignalResult result;
      bool evaluated=false;
      const bool ok=m_signal_engine.Poll(result,evaluated);
      if(!evaluated)
        {
         if(!ok && result.status==SIGNAL_STATUS_ERROR)
           {
            PrintFormat("SIGNAL_ERROR code=%s reason=%s",result.reason_code,result.reason);
            AuditSystemError("SIGNAL_ENGINE",result.reason_code,result.reason);
           }
         return;
        }
      if(!ok || result.status==SIGNAL_STATUS_ERROR)
        {
         PrintFormat("SIGNAL_ERROR code=%s bar=%s reason=%s",result.reason_code,
                     TimeToString(result.signal_bar_time,TIME_DATE|TIME_MINUTES),result.reason);
         AuditSystemError("SIGNAL_ENGINE",result.reason_code,result.reason);
         return;
        }
      // 段階的Entry判定パイプラインの全評価結果（成立・否決を問わず毎確定足）を記録する診断専用イベント。
      // InpEntryUseStagedPipeline=trueの場合のみ記録し、既存方式（既定値）では監査ログ量を増やさない。
      if(m_config.entry_use_staged_pipeline)
        {
         const string pipeline_id=SafeIdentifier(
            StringFormat("%s-%s-%I64d",m_config.ea_id,result.symbol,(long)result.signal_bar_time),"unlinked");
         string pipeline_payload="{";
         pipeline_payload+="\"stage_market_regime\":"+JString(result.stage_market_regime)+",";
         pipeline_payload+="\"stage_market_regime_passed\":"+(result.stage_market_regime_passed ? "true" : "false")+",";
         pipeline_payload+="\"stage_htf_bias\":"+JString(result.stage_htf_bias)+",";
         pipeline_payload+="\"stage_htf_bias_passed\":"+(result.stage_htf_bias_passed ? "true" : "false")+",";
         pipeline_payload+="\"stage_breakout_setup_passed\":"+(result.stage_breakout_setup_passed ? "true" : "false")+",";
         pipeline_payload+="\"stage_breakout_trigger_passed\":"+(result.stage_breakout_trigger_passed ? "true" : "false")+",";
         pipeline_payload+="\"stage_pullback_setup_passed\":"+(result.stage_pullback_setup_passed ? "true" : "false")+",";
         pipeline_payload+="\"stage_pullback_trigger_passed\":"+(result.stage_pullback_trigger_passed ? "true" : "false")+",";
         pipeline_payload+="\"final_status\":"+JString(result.status==SIGNAL_STATUS_CANDIDATE ? "CANDIDATE" : "REJECTED")+",";
         pipeline_payload+="\"reason_code\":"+JString(result.reason_code)+",";
         pipeline_payload+="\"reason\":"+JString(result.reason)+"}";
         Audit("ENTRY_PIPELINE",pipeline_id,"",result.symbol,pipeline_payload,false);
        }

      // II案（平均回帰、2026-08-24追加）: トレンドフォロー戦略が本確定足で候補を生成しなかった
      // 場合のみ、独立した第二の候補生成源として平均回帰戦略を評価する。トレンドフォロー戦略が
      // 候補を出した場合は評価しない（両戦略が同一口座へ同時に発注することを避ける単純な排他制御）。
      // InpEnableMeanReversionStrategy=false（既定）では従来どおり本ブロックは一切実行されない。
      if(result.status!=SIGNAL_STATUS_CANDIDATE && m_config.enable_mean_reversion_strategy)
        {
         SSignalResult mr_result;
         bool mr_evaluated=false;
         const bool mr_ok=m_mean_reversion_signal_engine.Poll(mr_result,mr_evaluated);
         if(mr_evaluated)
           {
            if(!mr_ok || mr_result.status==SIGNAL_STATUS_ERROR)
              {
               PrintFormat("SIGNAL_ERROR code=%s bar=%s reason=%s",mr_result.reason_code,
                           TimeToString(mr_result.signal_bar_time,TIME_DATE|TIME_MINUTES),mr_result.reason);
               AuditSystemError("MEAN_REVERSION_SIGNAL_ENGINE",mr_result.reason_code,mr_result.reason);
              }
            else if(mr_result.status==SIGNAL_STATUS_CANDIDATE)
               result=mr_result;
           }
        }

      if(result.status!=SIGNAL_STATUS_CANDIDATE)
        {
         PrintFormat("SIGNAL_NONE symbol=%s bar=%s code=%s reason=%s",m_config.symbol,
                     TimeToString(result.signal_bar_time,TIME_DATE|TIME_MINUTES),result.reason_code,result.reason);
         return;
        }

      const int digits=(int)SymbolInfoInteger(result.symbol,SYMBOL_DIGITS);
      PrintFormat("SIGNAL_CANDIDATE id=%s symbol=%s direction=%s pattern=%s bar=%s entry=%s sl=%s tp=%s code=%s reason=%s",
                  result.trade_candidate_id,result.symbol,SignalDirectionToString(result.direction),
                  EntryPatternToString(result.entry_pattern),TimeToString(result.signal_bar_time,TIME_DATE|TIME_MINUTES),
                  DoubleToString(result.entry_price,digits),DoubleToString(result.stop_loss,digits),
                  DoubleToString(result.take_profit,digits),
                  result.reason_code,result.reason);
      // 分析用の市場コンテキスト（ATR・ADX・スプレッド・曜日）。売買判断には使用しない。
      MqlTick candidate_tick;
      double candidate_spread_points=0.0;
      if(SymbolInfoTick(result.symbol,candidate_tick))
        {
         const double candidate_point=SymbolInfoDouble(result.symbol,SYMBOL_POINT);
         if(candidate_point>0.0) candidate_spread_points=(candidate_tick.ask-candidate_tick.bid)/candidate_point;
        }
      string candidate_payload="{";
      candidate_payload+="\"direction\":"+JString(SignalDirectionToString(result.direction))+",";
      candidate_payload+="\"pattern\":"+JString(EntryPatternToString(result.entry_pattern))+",";
      candidate_payload+="\"entry_price\":"+JNumber(result.entry_price)+",";
      candidate_payload+="\"stop_loss\":"+JNumber(result.stop_loss)+",";
      candidate_payload+="\"take_profit\":"+JNumber(result.take_profit)+",";
      candidate_payload+="\"risk_reward_ratio\":"+JNumber(result.risk_reward_ratio)+",";
      candidate_payload+="\"atr\":"+JNumber(result.atr)+",";
      candidate_payload+="\"adx\":"+JNumber(result.adx)+",";
      candidate_payload+="\"spread_points\":"+JNumber(candidate_spread_points)+",";
      candidate_payload+="\"market_regime_trend\":"+JString(MarketRegimeTrendToString(result.market_regime_trend))+",";
      candidate_payload+="\"market_regime_volatility\":"+JString(MarketRegimeVolatilityToString(result.market_regime_volatility))+",";
      candidate_payload+="\"hour\":"+IntegerToString(result.hour)+",";
      candidate_payload+="\"day_of_week\":"+IntegerToString(result.day_of_week)+",";
      // 段階的Entry判定パイプラインの各ステージ結果（InpEntryUseStagedPipelineの有効・無効に関わらず記録、分析専用）。
      candidate_payload+="\"staged_pipeline_used\":"+(result.staged_pipeline_used ? "true" : "false")+",";
      candidate_payload+="\"stage_market_regime\":"+JString(result.stage_market_regime)+",";
      candidate_payload+="\"stage_htf_bias\":"+JString(result.stage_htf_bias)+",";
      candidate_payload+="\"stage_breakout_setup_passed\":"+(result.stage_breakout_setup_passed ? "true" : "false")+",";
      candidate_payload+="\"stage_breakout_trigger_passed\":"+(result.stage_breakout_trigger_passed ? "true" : "false")+",";
      candidate_payload+="\"stage_pullback_setup_passed\":"+(result.stage_pullback_setup_passed ? "true" : "false")+",";
      candidate_payload+="\"stage_pullback_trigger_passed\":"+(result.stage_pullback_trigger_passed ? "true" : "false")+",";
      candidate_payload+="\"reason_code\":"+JString(result.reason_code)+",";
      candidate_payload+="\"reason\":"+JString(result.reason)+"}";
      Audit("CANDIDATE",result.trade_candidate_id,"",result.symbol,candidate_payload,false);

      SExternalDecision external_decision;
      const bool use_mock=(MQLInfoInteger(MQL_TESTER) && m_config.tester_decision_mode!=TESTER_DECISION_FAIL_SAFE);
      const bool external_ok=(use_mock ? m_mock_decision_provider.Decide(result,external_decision) :
                                         m_decision_client.Decide(result,external_decision));
      const string external_status=(external_decision.status==EXTERNAL_DECISION_ALLOW ? "ALLOW" : "VETO");
      string external_payload="{";
      external_payload+="\"decision\":"+JString(external_status)+",";
      external_payload+="\"reason_code\":"+JString(SafeIdentifier(external_decision.reason_code,"EXTERNAL_ERROR"))+",";
      external_payload+="\"ml_status\":"+JString(SafeIdentifier(external_decision.ml_status,"ERROR"))+",";
      external_payload+="\"ml_win_probability\":"+JNumber(external_decision.ml_win_probability)+",";
      external_payload+="\"ml_expected_return\":"+JNumber(external_decision.ml_expected_return)+",";
      external_payload+="\"ml_model_version\":"+JString(SafeIdentifier(external_decision.ml_model_version,"unavailable"))+",";
      external_payload+="\"llm_status\":"+JString(SafeIdentifier(external_decision.llm_status,"ERROR"))+",";
      external_payload+="\"llm_provider\":"+JString(SafeIdentifier(external_decision.llm_provider,"unavailable"))+",";
      external_payload+="\"llm_model\":"+JString(SafeIdentifier(external_decision.llm_model,"unavailable"))+",";
      external_payload+="\"llm_prompt_version\":"+JString(SafeIdentifier(external_decision.llm_prompt_version,"unavailable"))+",";
      external_payload+="\"llm_confidence\":"+JNumber(external_decision.llm_confidence)+",";
      external_payload+="\"llm_reason\":"+JString(StringLen(external_decision.reason)>0 ? external_decision.reason : "No external reason supplied.")+"}";
      Audit("EXTERNAL_DECISION",result.trade_candidate_id,external_decision.request_id,result.symbol,external_payload,false);
      if(!external_ok || external_decision.status!=EXTERNAL_DECISION_ALLOW)
        {
         PrintFormat("EXTERNAL_VETO candidate_id=%s request_id=%s code=%s http_status=%d ml_status=%s ml_probability=%.6f llm_status=%s reason=%s",
                     result.trade_candidate_id,external_decision.request_id,external_decision.reason_code,
                     external_decision.http_status,external_decision.ml_status,
                     external_decision.ml_win_probability,external_decision.llm_status,external_decision.reason);
         return;
        }
      PrintFormat("EXTERNAL_ALLOW candidate_id=%s request_id=%s model_version=%s ml_probability=%.6f expected_return=%.8f llm_provider=%s llm_model=%s prompt_version=%s confidence=%.6f request_time=%s response_time=%s expires_at=%s reason=%s",
                  result.trade_candidate_id,external_decision.request_id,external_decision.ml_model_version,
                  external_decision.ml_win_probability,external_decision.ml_expected_return,
                  external_decision.llm_provider,external_decision.llm_model,
                  external_decision.llm_prompt_version,external_decision.llm_confidence,
                  TimeToString(external_decision.request_time,TIME_DATE|TIME_SECONDS),
                  TimeToString(external_decision.response_time,TIME_DATE|TIME_SECONDS),
                  TimeToString(external_decision.expires_at,TIME_DATE|TIME_SECONDS),external_decision.reason);

      // Risk is deliberately recalculated after external latency using the latest account and market state.
      SRiskDecision risk_decision;
      const bool risk_ok=m_risk_manager.Evaluate(result,risk_decision);
      string risk_payload="{";
      risk_payload+="\"status\":"+JString(risk_decision.status==RISK_DECISION_APPROVED ? "APPROVED" : "REJECTED")+",";
      risk_payload+="\"reason_code\":"+JString(SafeIdentifier(risk_decision.reason_code,"RISK_ERROR"))+",";
      risk_payload+="\"reason\":"+JString(StringLen(risk_decision.reason)>0 ? risk_decision.reason : "Risk evaluation failed.")+",";
      risk_payload+="\"volume\":"+JNumber(risk_decision.volume)+",";
      risk_payload+="\"risk_budget\":"+JNumber(risk_decision.risk_budget)+",";
      risk_payload+="\"estimated_stop_loss\":"+JNumber(risk_decision.estimated_stop_loss)+",";
      risk_payload+="\"required_margin\":"+JNumber(risk_decision.required_margin)+",";
      risk_payload+="\"daily_loss_rate\":"+JNumber(risk_decision.daily_loss_rate)+",";
      risk_payload+="\"drawdown_rate\":"+JNumber(risk_decision.drawdown_rate)+",";
      risk_payload+="\"open_risk_rate\":"+JNumber(risk_decision.open_risk_rate)+",";
      risk_payload+="\"margin_level\":"+JNumber(risk_decision.margin_level)+",";
      risk_payload+="\"adaptive_risk_multiplier\":"+JNumber(risk_decision.adaptive_risk_multiplier)+"}";
      Audit("RISK_DECISION",result.trade_candidate_id,external_decision.request_id,result.symbol,risk_payload,true);
      if(!risk_ok || risk_decision.status!=RISK_DECISION_APPROVED)
        {
         PrintFormat("RISK_REJECTED id=%s code=%s daily_loss=%.6f drawdown=%.6f reason=%s",
                     result.trade_candidate_id,risk_decision.reason_code,risk_decision.daily_loss_rate,
                     risk_decision.drawdown_rate,risk_decision.reason);
         return;
        }
      PrintFormat("RISK_ALLOW id=%s volume=%.8f risk_budget=%.2f estimated_sl_loss=%.2f margin=%.2f reason=%s",
                  result.trade_candidate_id,risk_decision.volume,risk_decision.risk_budget,
                  risk_decision.estimated_stop_loss,risk_decision.required_margin,risk_decision.reason);

      const bool external_approved=(external_decision.status==EXTERNAL_DECISION_ALLOW);
      SOrderResult order_result;
      const bool order_ok=m_order_manager.Submit(result,risk_decision,external_approved,order_result);
      string order_payload="{";
      order_payload+="\"status\":"+JString(order_result.status==ORDER_SUBMISSION_ACCEPTED ? "ACCEPTED" : (order_result.status==ORDER_SUBMISSION_ERROR ? "ERROR" : "BLOCKED"))+",";
      order_payload+="\"reason_code\":"+JString(SafeIdentifier(order_result.reason_code,"ORDER_ERROR"))+",";
      order_payload+="\"reason\":"+JString(StringLen(order_result.reason)>0 ? order_result.reason : "Order was not accepted.")+",";
      order_payload+="\"order_ticket\":"+JString(StringFormat("%I64u",order_result.order_ticket))+",";
      order_payload+="\"deal_ticket\":"+JString(StringFormat("%I64u",order_result.deal_ticket))+",";
      order_payload+="\"broker_retcode\":"+IntegerToString((int)order_result.broker_retcode)+",";
      order_payload+="\"requested_price\":"+JNumber(order_result.requested_price)+",";
      order_payload+="\"confirmed_price\":"+JNumber(order_result.confirmed_price)+",";
      order_payload+="\"requested_volume\":"+JNumber(order_result.requested_volume)+",";
      order_payload+="\"confirmed_volume\":"+JNumber(order_result.confirmed_volume)+",";
      order_payload+="\"slippage_points\":"+JNumber(order_result.slippage_points)+"}";
      Audit("ORDER_SUBMISSION",result.trade_candidate_id,external_decision.request_id,result.symbol,order_payload,true);
      if(!order_ok || order_result.status!=ORDER_SUBMISSION_ACCEPTED)
        {
         PrintFormat("ORDER_BLOCKED id=%s code=%s reason=%s",result.trade_candidate_id,
                     order_result.reason_code,order_result.reason);
         return;
        }
      PrintFormat("ORDER_ACCEPTED id=%s order=%I64u deal=%I64u retcode=%u requested_price=%.8f confirmed_price=%.8f slippage_points=%.2f",
                  result.trade_candidate_id,order_result.order_ticket,order_result.deal_ticket,
                  order_result.broker_retcode,order_result.requested_price,order_result.confirmed_price,
                  order_result.slippage_points);
     }

   void OnTradeTransaction(const MqlTradeTransaction &transaction)
     {
      if(!m_initialized)
         return;
      m_position_manager.OnTradeTransaction(transaction);
      if(transaction.type!=TRADE_TRANSACTION_DEAL_ADD || transaction.deal==0 || !HistoryDealSelect(transaction.deal)) return;
      // レンジ戦略（mean_reversion_magic_number）のポジションがSL/TP等のブローカー側自動決済で
      // 決済された場合にDEAL/TRADE_CLOSED/TRADE_ANALYTICSが監査ログへ一切記録されない不具合を修正
      // （初回コミットから存在、レンジ戦略追加時に未更新。2026-08-24修正）。他のMagic Number判定
      // （IsManagedPosition 3引数版）と同じ設計に統一する。
      const long deal_magic=HistoryDealGetInteger(transaction.deal,DEAL_MAGIC);
      if(!CPositionProtectionRules::IsManagedPosition(deal_magic,
         m_config.magic_number,m_config.mean_reversion_magic_number)) return;
      const string symbol=HistoryDealGetString(transaction.deal,DEAL_SYMBOL);
      const ulong position_identifier=(ulong)HistoryDealGetInteger(transaction.deal,DEAL_POSITION_ID);
      const string candidate_id=CClosedPositionProcessor::CandidateForPosition(m_config.ea_id,position_identifier,symbol);
      // このデタッチ自身の価格・volume・entry種別は、SL/TP等の自動決済デタッチではDEAL_ADD通知の時点で
      // HistoryDealGetXxx(transaction.deal,...)がまだ確定していないことがある（Strategy Testerで確認済み）。
      // MqlTradeTransaction構造体が直接持つ価格・volumeと、ライブのポジション残存有無で代替する。
      // 反転（ドテン）は想定しないため、ライブのポジション残存有無によるIN/OUTの二値判定で十分。
      // 部分決済（PositionManager::ClosePartial）のデタッチもここではINと分類されるが（決済後も
      // ポジションが残存するため）、TRADE_CLOSED側のclosed_volume/pnlはポジションの全デタッチを
      // 合算するため、最終的な決済集計への影響はない（このDEALイベント自体の表示上の簡略化に留まる）。
      const bool position_still_open=PositionSelectByTicket(transaction.position);
      const ENUM_DEAL_ENTRY entry=(position_still_open ? DEAL_ENTRY_IN : DEAL_ENTRY_OUT);
      // pnl（損益）はHistory側の値に依存するため、自動決済デタッチでは0で記録される場合がある既知の制約。
      // 決済済みトレードの正本はTRADE_CLOSED（ClosedPositionProcessorが次Tick以降に確定）を参照する。
      const double pnl=HistoryDealGetDouble(transaction.deal,DEAL_PROFIT)+
                       HistoryDealGetDouble(transaction.deal,DEAL_COMMISSION)+
                       HistoryDealGetDouble(transaction.deal,DEAL_SWAP)+
                       HistoryDealGetDouble(transaction.deal,DEAL_FEE);
      string deal_payload="{";
      deal_payload+="\"deal_ticket\":"+JString(StringFormat("%I64u",transaction.deal))+",";
      deal_payload+="\"order_ticket\":"+JString(StringFormat("%I64u",transaction.order))+",";
      deal_payload+="\"position_ticket\":"+JString(StringFormat("%I64u",transaction.position))+",";
      deal_payload+="\"entry\":"+JString(DealEntryName(entry))+",";
      deal_payload+="\"price\":"+JNumber(transaction.price)+",";
      deal_payload+="\"volume\":"+JNumber(transaction.volume)+",";
      deal_payload+="\"pnl\":"+JNumber(pnl)+"}";
      Audit("DEAL",candidate_id,"",symbol,deal_payload,true);

      if(entry==DEAL_ENTRY_OUT)
        {
         // レンジ戦略ポジションの決済を検知したら、決済理由（SL/TP/TICK_BREAK_EXIT/BB_WIDTH_EXPANSION
         // 等いずれでも）を問わず警戒状態・ブレイク確認タイマーを必ずクリアする（2026-08-26追加、
         // ユーザー指示）。RANGE_BREAK/BB_WIDTH_EXPANSION経由の決済は既に呼び出し元
         // （EvaluateMeanReversionForcedExits内のIsRangeStillValid）でクリア済みだが、SL/TP等の
         // ブローカー側自動決済経路はここでしかクリアの機会がないため、常に呼んでも安全な
         // no-op設計（未追跡ticketは何もしない）を活かして無条件に呼び出す。
         if(deal_magic==(long)m_config.mean_reversion_magic_number)
            m_mean_reversion_strategy.ClearPositionState(transaction.position);
         // コスト感応度分析用: 約定Tickそのものではないが、決済検知直後のSpreadをベストエフォートで記録する。
         MqlTick exit_tick;
         double exit_spread_points=0.0;
         if(SymbolInfoTick(symbol,exit_tick))
           {
            const double exit_point=SymbolInfoDouble(symbol,SYMBOL_POINT);
            if(exit_point>0.0) exit_spread_points=(exit_tick.ask-exit_tick.bid)/exit_point;
           }
         m_closed_position_processor.Enqueue(position_identifier,transaction.position,symbol,exit_spread_points);
         // 履歴が既に確定している場合に備え、今Tick内でも即時確定を試みる（次Tickを待たせない）。
         m_closed_position_processor.ProcessPending();
        }
     }
  };

#endif
