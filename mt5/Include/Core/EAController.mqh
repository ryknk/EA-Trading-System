#ifndef EA_TRADING_SYSTEM_EA_CONTROLLER_MQH
#define EA_TRADING_SYSTEM_EA_CONTROLLER_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/Strategy/TrendFollowingStrategy.mqh>
#include <EaTradingSystem/Signal/SignalEngine.mqh>
#include <EaTradingSystem/Risk/RiskManager.mqh>
#include <EaTradingSystem/Trading/OrderManager.mqh>
#include <EaTradingSystem/Trading/PositionManager.mqh>
#include <EaTradingSystem/External/DecisionApiClient.mqh>
#include <EaTradingSystem/External/MockDecisionProvider.mqh>
#include <EaTradingSystem/External/TelemetryApiClient.mqh>
#include <EaTradingSystem/Logging/TradeLogger.mqh>
#include <EaTradingSystem/Logging/TradeAnalyticsTracker.mqh>

class CEAController
  {
private:
   // 決済直後はHistoryDealGetXxx(直近デタッチticket,...)の一部プロパティ(価格・volume・pnl等)が
   // Strategy Tester上でまだ確定していないことがあるため、即時集計せずキューへ積み、
   // 次Tick（履歴が確定した後）でTRADE_CLOSED・TRADE_ANALYTICSを確定させる。
   struct SPendingClosedPosition
     {
      ulong  position_identifier;
      ulong  position_ticket;
      string symbol;
     };
   SPendingClosedPosition      m_pending_closed_positions[];
   SEaConfig                   m_config;
   CTrendFollowingStrategy     m_strategy;
   CSignalEngine               m_signal_engine;
   CRiskManager                m_risk_manager;
   COrderManager               m_order_manager;
   CPositionManager            m_position_manager;
   CDecisionApiClient          m_decision_client;
   CMockDecisionProvider       m_mock_decision_provider;
   CTelemetryApiClient         m_telemetry_client;
   CTradeLogger                m_trade_logger;
   CTradeAnalyticsTracker      m_analytics_tracker;
   bool                        m_initialized;
   datetime                    m_last_risk_error_log;
   string                      m_last_risk_lock_code;
   datetime                    m_last_position_error_log;
   int                         m_last_snapshot_day;

   string JString(const string value) { return "\""+CCryptoUtils::JsonEscape(value)+"\""; }
   string JNumber(const double value) { return DoubleToString(value,10); }

   string SafeIdentifier(const string value,const string fallback)
     {
      return CTradeLogRules::SafeCorrelationId(value) ? value : fallback;
     }

   string Iso8601Utc(const datetime value)
     {
      MqlDateTime parts;
      TimeToStruct(value,parts);
      return StringFormat("%04d-%02d-%02dT%02d:%02d:%02dZ",
                          parts.year,parts.mon,parts.day,parts.hour,parts.min,parts.sec);
     }

   void Audit(const string event_type,const string candidate_id,const string request_id,
              const string symbol,const string payload,const bool send_remote)
     {
      string event_id,body,error;
      datetime event_time=0;
      if(!m_trade_logger.Record(event_type,SafeIdentifier(candidate_id,"unlinked"),
                                (StringLen(request_id)>0 ? SafeIdentifier(request_id,"") : ""),
                                SafeIdentifier(symbol,m_config.symbol),payload,
                                event_id,event_time,body,error))
        {
         PrintFormat("AUDIT_LOCAL_WRITE_FAILED type=%s candidate_id=%s code=%s",event_type,candidate_id,error);
         return;
        }
      if(send_remote && m_telemetry_client.Enabled())
        {
         string telemetry_error;
         if(!m_telemetry_client.Send(body,event_id,event_time,telemetry_error))
            PrintFormat("TELEMETRY_UPLOAD_FAILED event_id=%s candidate_id=%s type=%s code=%s trading_impact=none",
                        event_id,candidate_id,event_type,telemetry_error);
        }
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

   string CandidateForPosition(const ulong position_identifier,const string symbol)
     {
      if(position_identifier==0 || !HistorySelectByPosition(position_identifier)) return "unlinked";
      const int total=HistoryDealsTotal();
      for(int index=0; index<total; index++)
        {
         const ulong deal=HistoryDealGetTicket(index);
         if(deal==0) continue;
         const ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal,DEAL_ENTRY);
         if(entry!=DEAL_ENTRY_IN && entry!=DEAL_ENTRY_INOUT) continue;
         const string comment=HistoryDealGetString(deal,DEAL_COMMENT);
         if(CTradeLogRules::SafeCorrelationId(comment)) return comment;
        }
      return "unlinked";
     }

   string DealEntryName(const ENUM_DEAL_ENTRY entry)
     {
      if(entry==DEAL_ENTRY_IN) return "IN";
      if(entry==DEAL_ENTRY_OUT) return "OUT";
      if(entry==DEAL_ENTRY_INOUT) return "INOUT";
      if(entry==DEAL_ENTRY_OUT_BY) return "OUT_BY";
      return "UNKNOWN";
     }

   // 決済トリガー種別。SL/TPは注文設定どおりの自動決済、EXPERTはEA発注（Emergency Close等）による決済。
   string DealReasonName(const ENUM_DEAL_REASON reason)
     {
      if(reason==DEAL_REASON_SL) return "SL";
      if(reason==DEAL_REASON_TP) return "TP";
      if(reason==DEAL_REASON_SO) return "SO";
      if(reason==DEAL_REASON_EXPERT) return "EXPERT";
      if(reason==DEAL_REASON_CLIENT) return "CLIENT";
      if(reason==DEAL_REASON_MOBILE) return "MOBILE";
      if(reason==DEAL_REASON_WEB) return "WEB";
      if(reason==DEAL_REASON_ROLLOVER) return "ROLLOVER";
      if(reason==DEAL_REASON_VMARGIN) return "VMARGIN";
      if(reason==DEAL_REASON_SPLIT) return "SPLIT";
      return "UNKNOWN";
     }

   // キュー済みの決済済みポジションを確定させ、TRADE_CLOSED・TRADE_ANALYTICSを記録する。
   // 履歴がまだ確定していない場合はキューに残し、次回のTickで再試行する。
   void ProcessPendingClosedPositions(void)
     {
      for(int index=ArraySize(m_pending_closed_positions)-1; index>=0; index--)
        {
         const ulong position_identifier=m_pending_closed_positions[index].position_identifier;
         const ulong position_ticket=m_pending_closed_positions[index].position_ticket;
         const string symbol=m_pending_closed_positions[index].symbol;
         if(!HistorySelectByPosition(position_identifier))
            continue;
         const string candidate_id=CandidateForPosition(position_identifier,symbol);
         datetime open_time=0,close_time=0;
         double open_price=0.0,close_price=0.0,closed_volume=0.0,total_pnl=0.0,total_commission=0.0,total_swap=0.0;
         string direction="BUY";
         string close_reason="UNKNOWN";
         const int total=HistoryDealsTotal();
         for(int deal_index=0; deal_index<total; deal_index++)
           {
            const ulong deal=HistoryDealGetTicket(deal_index);
            if(deal==0) continue;
            const ENUM_DEAL_ENTRY deal_entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal,DEAL_ENTRY);
            if((deal_entry==DEAL_ENTRY_IN || deal_entry==DEAL_ENTRY_INOUT) && open_time==0)
              {
               open_time=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
               open_price=HistoryDealGetDouble(deal,DEAL_PRICE);
               direction=(HistoryDealGetInteger(deal,DEAL_TYPE)==DEAL_TYPE_BUY ? "BUY" : "SELL");
              }
            if(deal_entry==DEAL_ENTRY_OUT || deal_entry==DEAL_ENTRY_OUT_BY)
              {
               close_time=(datetime)HistoryDealGetInteger(deal,DEAL_TIME);
               close_price=HistoryDealGetDouble(deal,DEAL_PRICE);
               closed_volume+=HistoryDealGetDouble(deal,DEAL_VOLUME);
               close_reason=DealReasonName((ENUM_DEAL_REASON)HistoryDealGetInteger(deal,DEAL_REASON));
              }
            total_pnl+=HistoryDealGetDouble(deal,DEAL_PROFIT)+HistoryDealGetDouble(deal,DEAL_COMMISSION)+
                       HistoryDealGetDouble(deal,DEAL_SWAP)+HistoryDealGetDouble(deal,DEAL_FEE);
            total_commission+=HistoryDealGetDouble(deal,DEAL_COMMISSION)+HistoryDealGetDouble(deal,DEAL_FEE);
            total_swap+=HistoryDealGetDouble(deal,DEAL_SWAP);
           }
         if(open_time<=0 || close_time<=0)
            continue; // 履歴がまだ確定していない可能性。キューに残し次回再試行する。

         string closed_payload="{";
         closed_payload+="\"position_ticket\":"+JString(StringFormat("%I64u",position_ticket))+",";
         closed_payload+="\"direction\":"+JString(direction)+",";
         closed_payload+="\"open_time\":"+JString(Iso8601Utc(open_time))+",";
         closed_payload+="\"close_time\":"+JString(Iso8601Utc(close_time))+",";
         closed_payload+="\"volume\":"+JNumber(closed_volume)+",";
         closed_payload+="\"open_price\":"+JNumber(open_price)+",";
         closed_payload+="\"close_price\":"+JNumber(close_price)+",";
         closed_payload+="\"close_reason\":"+JString(close_reason)+",";
         closed_payload+="\"pnl\":"+JNumber(total_pnl)+",";
         closed_payload+="\"commission\":"+JNumber(total_commission)+",";
         closed_payload+="\"swap\":"+JNumber(total_swap)+"}";
         Audit("TRADE_CLOSED",candidate_id,"",symbol,closed_payload,true);

         double analytics_mfe=0.0,analytics_mae=0.0;
         if(m_analytics_tracker.Finalize(position_ticket,analytics_mfe,analytics_mae))
           {
            string analytics_payload="{";
            analytics_payload+="\"position_ticket\":"+JString(StringFormat("%I64u",position_ticket))+",";
            analytics_payload+="\"mfe\":"+JNumber(analytics_mfe)+",";
            analytics_payload+="\"mae\":"+JNumber(analytics_mae)+"}";
            Audit("TRADE_ANALYTICS",candidate_id,"",symbol,analytics_payload,true);
           }

         const int last=ArraySize(m_pending_closed_positions)-1;
         m_pending_closed_positions[index]=m_pending_closed_positions[last];
         ArrayResize(m_pending_closed_positions,last);
        }
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
         if(ticket==0 || PositionGetInteger(POSITION_MAGIC)!=(long)m_config.magic_number) continue;
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
         Audit("POSITION_SNAPSHOT",CandidateForPosition(identifier,symbol),"",symbol,payload,true);
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
      string audit_error;
      if(!m_trade_logger.Initialize(m_config,audit_error))
         PrintFormat("AUDIT_LOGGER_INIT_FAILED code=%s terminal_logging=true",audit_error);
      else if(StringLen(audit_error)>0)
         PrintFormat("AUDIT_LOGGER_INIT_WARNING code=%s terminal_logging=true",audit_error);
      string telemetry_error;
      if(!m_telemetry_client.Initialize(m_config,telemetry_error))
         PrintFormat("TELEMETRY_INIT_FAILED code=%s trading_impact=none",telemetry_error);
      m_analytics_tracker.Initialize(m_config.magic_number);
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
      const bool use_mock=(MQLInfoInteger(MQL_TESTER) && m_config.tester_decision_mode!=TESTER_DECISION_FAIL_SAFE);
      if(!(use_mock ? m_mock_decision_provider.Initialize(m_config,error) : m_decision_client.Initialize(m_config,error)))
        {
         m_strategy.Shutdown();
         return false;
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
      m_telemetry_client.Shutdown();
      m_trade_logger.Shutdown();
      m_decision_client.Shutdown();
      m_mock_decision_provider.Shutdown();
      m_strategy.Shutdown();
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
            AuditSystemError("POSITION_MANAGER",position_error,"Managed position monitoring failed.");
            m_last_position_error_log=position_now;
           }
        }
      // 分析専用のMFE/MAE追跡。既存ポジション管理の判断・発注には一切影響しない。
      m_analytics_tracker.Update();
      // 分析専用。前Tickで決済検知しキューへ積んだポジションの履歴を確定させる。
      ProcessPendingClosedPositions();

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
      risk_payload+="\"drawdown_rate\":"+JNumber(risk_decision.drawdown_rate)+"}";
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
      if(HistoryDealGetInteger(transaction.deal,DEAL_MAGIC)!=(long)m_config.magic_number) return;
      const string symbol=HistoryDealGetString(transaction.deal,DEAL_SYMBOL);
      const ulong position_identifier=(ulong)HistoryDealGetInteger(transaction.deal,DEAL_POSITION_ID);
      const string candidate_id=CandidateForPosition(position_identifier,symbol);
      // このデタッチ自身の価格・volume・entry種別は、SL/TP等の自動決済デタッチではDEAL_ADD通知の時点で
      // HistoryDealGetXxx(transaction.deal,...)がまだ確定していないことがある（Strategy Testerで確認済み）。
      // MqlTradeTransaction構造体が直接持つ価格・volumeと、ライブのポジション残存有無で代替する。
      // 本EAはInpMaxOpenPositions=1・部分決済ロジックなしのため、IN/OUTの二値判定で十分（反転・分割決済は想定しない）。
      const bool position_still_open=PositionSelectByTicket(transaction.position);
      const ENUM_DEAL_ENTRY entry=(position_still_open ? DEAL_ENTRY_IN : DEAL_ENTRY_OUT);
      // pnl（損益）はHistory側の値に依存するため、自動決済デタッチでは0で記録される場合がある既知の制約。
      // 決済済みトレードの正本はTRADE_CLOSED（ProcessPendingClosedPositionsで次Tick確定）を参照する。
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
         const int slot=ArraySize(m_pending_closed_positions);
         ArrayResize(m_pending_closed_positions,slot+1);
         m_pending_closed_positions[slot].position_identifier=position_identifier;
         m_pending_closed_positions[slot].position_ticket=transaction.position;
         m_pending_closed_positions[slot].symbol=symbol;
         // 履歴が既に確定している場合に備え、今Tick内でも即時確定を試みる（次Tickを待たせない）。
         ProcessPendingClosedPositions();
        }
     }
  };

#endif
