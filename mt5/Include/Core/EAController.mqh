#ifndef EA_TRADING_SYSTEM_EA_CONTROLLER_MQH
#define EA_TRADING_SYSTEM_EA_CONTROLLER_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/Strategy/TrendFollowingStrategy.mqh>
#include <EaTradingSystem/Strategy/MeanReversionStrategy.mqh>
#include <EaTradingSystem/Signal/SignalEngine.mqh>
#include <EaTradingSystem/Risk/RiskManager.mqh>
#include <EaTradingSystem/Trading/OrderManager.mqh>
#include <EaTradingSystem/Trading/PositionManager.mqh>
#include <EaTradingSystem/External/DecisionApiClient.mqh>
#include <EaTradingSystem/External/MockDecisionProvider.mqh>
#include <EaTradingSystem/External/TelemetryApiClient.mqh>
#include <EaTradingSystem/Logging/TradeLogger.mqh>
#include <EaTradingSystem/Logging/TradeAnalyticsTracker.mqh>
#include <EaTradingSystem/Logging/EntryTimingAnalyzer.mqh>

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
      // OnTradeTransaction検知時点（決済Tick直後）のSpreadをベストエフォートで記録する。
      // 決済自体はブローカー側SL/TP等で発生するため、約定Tickそのものの値ではない近似値。
      double exit_spread_points;
     };
   SPendingClosedPosition      m_pending_closed_positions[];
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
   CTimeStopTracker            m_time_stop_tracker;
   CDecisionApiClient          m_decision_client;
   CMockDecisionProvider       m_mock_decision_provider;
   CTelemetryApiClient         m_telemetry_client;
   CTradeLogger                m_trade_logger;
   CTradeAnalyticsTracker      m_analytics_tracker;
   CEntryTimingAnalyzer        m_entry_timing_analyzer;
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

   // Entry Timing分析（分析専用、実注文なし）の完了イベントを監査ログへ記録する。
   // Telemetryへは送らない（バー単位で発生しうる高頻度データのためローカル監査のみ）。
   void AuditEntryTimingEvents(const SEntryTimingSetupEvent &setups[],const SEntryTimingTradeEvent &trades[])
     {
      for(int index=0; index<ArraySize(setups); index++)
        {
         string payload="{";
         payload+="\"setup_bar_time\":"+JString(Iso8601Utc(setups[index].setup_bar_time))+",";
         payload+="\"direction\":"+JString(SignalDirectionToString(setups[index].direction))+",";
         payload+="\"pre_entry_mfe_price\":"+JNumber(setups[index].pre_entry_mfe_price)+",";
         payload+="\"pre_entry_mfe_r\":"+JNumber(setups[index].pre_entry_mfe_r)+",";
         payload+="\"pre_entry_mfe_time\":"+JString(Iso8601Utc(setups[index].pre_entry_mfe_time))+",";
         payload+="\"pre_entry_mae_price\":"+JNumber(setups[index].pre_entry_mae_price)+",";
         payload+="\"pre_entry_mae_r\":"+JNumber(setups[index].pre_entry_mae_r)+",";
         payload+="\"pre_entry_mae_time\":"+JString(Iso8601Utc(setups[index].pre_entry_mae_time))+",";
         payload+="\"trigger_found\":"+(setups[index].trigger_found ? "true" : "false")+",";
         payload+="\"trigger_wait_bars\":"+IntegerToString(setups[index].trigger_wait_bars)+"}";
         Audit("ENTRY_TIMING_SETUP",setups[index].setup_id,"",m_config.symbol,payload,false);
        }
      for(int index=0; index<ArraySize(trades); index++)
        {
         string checkpoints="{";
         for(int checkpoint_index=0; checkpoint_index<CEntryTimingRules::CheckpointCount(); checkpoint_index++)
           {
            if(!trades[index].checkpoint_valid[checkpoint_index]) continue;
            if(StringLen(checkpoints)>1) checkpoints+=",";
            checkpoints+="\"bars_"+IntegerToString(CEntryTimingRules::CheckpointBars(checkpoint_index))+"\":"+
                         JNumber(trades[index].checkpoint_r[checkpoint_index]);
           }
         checkpoints+="}";
         string payload="{";
         payload+="\"variant\":"+JString(EntryTimingVariantToString(trades[index].variant))+",";
         payload+="\"entry_bar_time\":"+JString(Iso8601Utc(trades[index].entry_bar_time))+",";
         payload+="\"direction\":"+JString(SignalDirectionToString(trades[index].direction))+",";
         payload+="\"entry_price\":"+JNumber(trades[index].entry_price)+",";
         payload+="\"stop_loss\":"+JNumber(trades[index].stop_loss)+",";
         payload+="\"take_profit\":"+JNumber(trades[index].take_profit)+",";
         payload+="\"wait_bars\":"+IntegerToString(trades[index].wait_bars)+",";
         payload+="\"bars_held\":"+IntegerToString(trades[index].bars_held)+",";
         payload+="\"mfe_r\":"+JNumber(trades[index].mfe_r)+",";
         payload+="\"mae_r\":"+JNumber(trades[index].mae_r)+",";
         payload+="\"exit_reason\":"+JString(trades[index].exit_reason)+",";
         payload+="\"exit_price\":"+JNumber(trades[index].exit_price)+",";
         payload+="\"pnl_r\":"+JNumber(trades[index].pnl_r)+",";
         payload+="\"checkpoint_r\":"+checkpoints+"}";
         Audit("ENTRY_TIMING_TRADE",trades[index].setup_id,"",m_config.symbol,payload,false);
        }
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
         // Deal CommentはOrderManager::Submitがentry_bar時刻のみを格納する（trade_candidate_id
         // 全体はMQL5のComment上限31文字を超えるため）。CANDIDATE/RISK_DECISION監査ログと同じ
         // "{ea_id}-{symbol}-{unix_time}"形式へ復元する。
         const string comment=HistoryDealGetString(deal,DEAL_COMMENT);
         if(!CTradeLogRules::SafeCorrelationId(comment) || StringLen(comment)<1) continue;
         const string candidate_id=StringFormat("%s-%s-%s",m_config.ea_id,symbol,comment);
         if(CTradeLogRules::SafeCorrelationId(candidate_id)) return candidate_id;
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

         // コスト感応度分析用: このトレードのVolumeにおける「1 Point変動あたりの口座通貨換算値」を
         // OrderCalcProfit（PositionSizerと同じAPI）で算出する。CANDIDATE.spread_pointsや
         // ORDER_SUBMISSION.slippage_pointsをPython側で金額換算する際に使用する。算出できない場合は0。
         double point_value=0.0;
         const double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
         if(point>0.0 && closed_volume>0.0 && open_price>0.0)
           {
            const ENUM_ORDER_TYPE calc_type=(direction=="BUY" ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
            double profit_for_one_point=0.0;
            ResetLastError();
            if(OrderCalcProfit(calc_type,symbol,closed_volume,open_price,open_price+point,profit_for_one_point) &&
               MathIsValidNumber(profit_for_one_point))
               point_value=MathAbs(profit_for_one_point);
           }

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
         closed_payload+="\"swap\":"+JNumber(total_swap)+",";
         closed_payload+="\"exit_spread_points\":"+JNumber(m_pending_closed_positions[index].exit_spread_points)+",";
         closed_payload+="\"point_value\":"+JNumber(point_value)+"}";
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

   // 保有ポジションのエントリー根拠（トレンド/ADX）を再検証し、消失していれば早期決済する。
   // PositionManagerはメカニズム（決済実行）のみを持ち、判断（Strategy参照）はここで行う
   // （Strategyから直接発注処理を呼び出さない、という責務境界を維持するため）。
   void EvaluateSignalInvalidationExits(void)
     {
      if(!m_config.enable_signal_invalidation_exit || !m_config.enable_trade_mutations)
         return;
      const int total=PositionsTotal();
      for(int index=0; index<total; index++)
        {
         const ulong ticket=PositionGetTicket(index);
         if(ticket==0) continue;
         if(!CPositionProtectionRules::IsManagedPosition(PositionGetInteger(POSITION_MAGIC),m_config.magic_number))
            continue;
         const ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         const ESignalDirection direction=(type==POSITION_TYPE_BUY ? SIGNAL_DIRECTION_BUY : SIGNAL_DIRECTION_SELL);
         string reason_code;
         if(!m_strategy.IsTrendStillValid(direction,reason_code))
           {
            string close_error;
            if(!m_position_manager.CloseOnSignalInvalidation(ticket,reason_code,close_error))
               PrintFormat("SIGNAL_EXIT_FAILED position=%I64u code=%s",ticket,close_error);
           }
        }
     }

   // Entry後、entry_timeframe換算で何本の確定足が経過したかを返す（look-ahead biasを避けるため、
   // 当日の未確定足は本数へ含めない）。Bars(symbol,timeframe,open_time,TimeCurrent())は境界を含むため-1する。
   int ElapsedClosedBars(const string symbol,const ENUM_TIMEFRAMES timeframe,const datetime open_time)
     {
      const int bars=Bars(symbol,timeframe,open_time,TimeCurrent());
      return bars>0 ? bars-1 : 0;
     }

   // 保有ポジションの経過バー数（entry_timeframe換算）が上限へ達したら、必要に応じて最低MFE到達判定を経て
   // 決済する。判断（経過バー数・MFE）はここで行い、メカニズム（決済実行）はPositionManagerへ委ねる
   // （EvaluateSignalInvalidationExitsと同じ責務境界）。
   void EvaluateTimeStopExits(void)
     {
      if(!m_config.enable_time_stop || !m_config.enable_trade_mutations)
         return;
      const int total=PositionsTotal();
      for(int index=0; index<total; index++)
        {
         const ulong ticket=PositionGetTicket(index);
         if(ticket==0) continue;
         if(!CPositionProtectionRules::IsManagedPosition(PositionGetInteger(POSITION_MAGIC),m_config.magic_number))
            continue;
         const double stop_loss=PositionGetDouble(POSITION_SL);
         if(stop_loss<=0.0) continue; // 保護SL未確定のpositionはPositionManager::Monitorの緊急決済側の責務
         const string symbol=PositionGetString(POSITION_SYMBOL);
         const ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         const double open_price=PositionGetDouble(POSITION_PRICE_OPEN);
         const datetime open_time=(datetime)PositionGetInteger(POSITION_TIME);
         const ulong position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
         MqlTick tick;
         if(!SymbolInfoTick(symbol,tick)) continue;
         const double current_price=(type==POSITION_TYPE_BUY ? tick.bid : tick.ask);

         double initial_stop_loss,peak_favorable_price;
         m_time_stop_tracker.Update(ticket,type,stop_loss,current_price,initial_stop_loss,peak_favorable_price);

         const int elapsed_bars=ElapsedClosedBars(symbol,m_config.entry_timeframe,open_time);
         if(!CTimeStopRules::HasExceededMaxHoldingBars(elapsed_bars,m_config.max_holding_bars))
            continue;
         if(m_config.time_stop_require_min_mfe &&
            CTimeStopRules::HasReachedMinMfeR(type,open_price,initial_stop_loss,peak_favorable_price,
                                              m_config.time_stop_min_mfe_r_multiple))
            continue; // 十分なMFEに到達済み。通常のSL/TP/建値ストップへ委ねる

         const string reason_code=(m_config.time_stop_require_min_mfe ?
            "MAX_HOLDING_BARS_MIN_MFE_NOT_REACHED" : "MAX_HOLDING_BARS");
         string close_error;
         if(!m_position_manager.CloseOnTimeStop(ticket,reason_code,close_error))
           { PrintFormat("TIME_STOP_EXIT_FAILED position=%I64u code=%s",ticket,close_error); continue; }
         m_time_stop_tracker.Remove(ticket);

         const double risk_distance=(type==POSITION_TYPE_BUY ? open_price-initial_stop_loss : initial_stop_loss-open_price);
         const double favorable_distance=(type==POSITION_TYPE_BUY ? peak_favorable_price-open_price : open_price-peak_favorable_price);
         const double mfe_r_multiple=(risk_distance>0.0 ? favorable_distance/risk_distance : 0.0);
         const string candidate_id=CandidateForPosition(position_identifier,symbol);
         string payload="{";
         payload+="\"position_ticket\":"+JString(StringFormat("%I64u",ticket))+",";
         payload+="\"reason_code\":"+JString(reason_code)+",";
         payload+="\"elapsed_bars\":"+IntegerToString(elapsed_bars)+",";
         payload+="\"mfe_r_multiple\":"+JNumber(mfe_r_multiple)+"}";
         // ローカル監査のみ。Time Stop識別は分析専用の新規イベントであり、既存TRADE_CLOSEDの契約は変更しない。
         Audit("TIME_STOP_EXIT",candidate_id,"",symbol,payload,false);
        }
     }

   // レンジ戦略のポジションについて、BB Width急拡大、またはRange Filter解除後の警戒状態中に
   // レンジ高値/安値の確定足ブレイクを検知したら満期を待たず市場成行で決済する（Range Filter解除
   // 単独では即決済しない、2026-08-25仕様変更。詳細はCMeanReversionStrategy::IsRangeStillValid参照）。
   // 判断（Strategy参照）はここで行い、メカニズム（決済実行）はPositionManagerへ委ねる
   // （EvaluateSignalInvalidationExitsと同じ責務境界）。トレンド戦略のポジション監視
   // （EvaluateSignalInvalidationExits/EvaluateTimeStopExits）とは完全に独立しており、
   // レンジポジションがそのままトレンドポジションへ引き継がれることはない。
   void EvaluateMeanReversionForcedExits(void)
     {
      if(!m_config.enable_mean_reversion_strategy || !m_config.enable_trade_mutations)
         return;
      const int total=PositionsTotal();
      for(int index=0; index<total; index++)
        {
         const ulong ticket=PositionGetTicket(index);
         if(ticket==0) continue;
         if(!CPositionProtectionRules::IsManagedPosition(PositionGetInteger(POSITION_MAGIC),m_config.mean_reversion_magic_number))
            continue;
         const ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         const ESignalDirection direction=(type==POSITION_TYPE_BUY ? SIGNAL_DIRECTION_BUY : SIGNAL_DIRECTION_SELL);
         string reason_code;
         if(!m_mean_reversion_strategy.IsRangeStillValid(ticket,direction,reason_code))
           {
            // 決済実行（CloseOnSignalInvalidation）で本ポジションが消滅する前に、監査ログ用の
            // 識別子を確保しておく（EvaluateTimeStopExitsと同じ安全な取得順序）。
            const string symbol=PositionGetString(POSITION_SYMBOL);
            const datetime open_time=(datetime)PositionGetInteger(POSITION_TIME);
            const ulong position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
            string close_error;
            if(!m_position_manager.CloseOnSignalInvalidation(ticket,reason_code,close_error))
              {
               PrintFormat("RANGE_EXIT_FAILED position=%I64u code=%s",ticket,close_error);
               continue;
              }
            // 監査ログの粒度不足対応（2026-08-24追加、ユーザー依頼）: 強制決済の発火理由
            // （RANGE_FILTER_RELEASED/RANGE_BREAK/BB_WIDTH_EXPANSION）を専用イベントへ記録する。
            // TIME_STOP_EXITと同じくローカル監査のみ、既存TRADE_CLOSEDの契約は変更しない。
            const int elapsed_bars=ElapsedClosedBars(symbol,m_config.entry_timeframe,open_time);
            const string candidate_id=CandidateForPosition(position_identifier,symbol);
            string payload="{";
            payload+="\"position_ticket\":"+JString(StringFormat("%I64u",ticket))+",";
            payload+="\"reason_code\":"+JString(reason_code)+",";
            payload+="\"elapsed_bars\":"+IntegerToString(elapsed_bars)+"}";
            Audit("RANGE_EXIT",candidate_id,"",symbol,payload,false);
           }
        }
     }

   // レンジ戦略のポジションについて、経過バー数（entry_timeframe換算）が独立した上限
   // （max_holding_bars、既定20本）へ達したら無条件で成行決済する。トレンド戦略のTime Stop
   // （最低MFE要求等）とはパラメータ・判断ロジックとも独立している。
   void EvaluateMeanReversionTimeStopExits(void)
     {
      if(!m_config.enable_mean_reversion_strategy || !m_config.enable_trade_mutations)
         return;
      const int total=PositionsTotal();
      for(int index=0; index<total; index++)
        {
         const ulong ticket=PositionGetTicket(index);
         if(ticket==0) continue;
         if(!CPositionProtectionRules::IsManagedPosition(PositionGetInteger(POSITION_MAGIC),m_config.mean_reversion_magic_number))
            continue;
         const double stop_loss=PositionGetDouble(POSITION_SL);
         if(stop_loss<=0.0) continue; // 保護SL未確定のpositionはPositionManager::Monitorの緊急決済側の責務
         const string symbol=PositionGetString(POSITION_SYMBOL);
         const datetime open_time=(datetime)PositionGetInteger(POSITION_TIME);
         const int elapsed_bars=ElapsedClosedBars(symbol,m_config.entry_timeframe,open_time);
         if(!CTimeStopRules::HasExceededMaxHoldingBars(elapsed_bars,m_config.mean_reversion_max_holding_bars))
            continue;
         // 決済実行（CloseOnTimeStop）で本ポジションが消滅する前に、監査ログ用の識別子を確保しておく
         // （EvaluateTimeStopExitsと同じ安全な取得順序、決済後のPositionGetInteger呼び出しを避ける）。
         const ulong position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
         string close_error;
         if(!m_position_manager.CloseOnTimeStop(ticket,"MEAN_REVERSION_MAX_HOLDING_BARS",close_error))
           { PrintFormat("RANGE_TIME_STOP_EXIT_FAILED position=%I64u code=%s",ticket,close_error); continue; }
         PrintFormat("RANGE_TIME_STOP_EXIT_SUBMITTED position=%I64u elapsed_bars=%d",ticket,elapsed_bars);
         // 監査ログの粒度不足対応（2026-08-24追加、ユーザー依頼）。EvaluateMeanReversionForcedExits
         // と同一のRANGE_EXITイベントへ統一し、reason_codeで発火理由を区別できるようにする。
         const string candidate_id=CandidateForPosition(position_identifier,symbol);
         string payload="{";
         payload+="\"position_ticket\":"+JString(StringFormat("%I64u",ticket))+",";
         payload+="\"reason_code\":"+JString("MEAN_REVERSION_MAX_HOLDING_BARS")+",";
         payload+="\"elapsed_bars\":"+IntegerToString(elapsed_bars)+"}";
         Audit("RANGE_EXIT",candidate_id,"",symbol,payload,false);
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
      m_analytics_tracker.Initialize(m_config.magic_number,m_config.mean_reversion_magic_number);
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
      if(!m_entry_timing_analyzer.Initialize(m_config,error))
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
      m_telemetry_client.Shutdown();
      m_trade_logger.Shutdown();
      m_decision_client.Shutdown();
      m_mock_decision_provider.Shutdown();
      m_entry_timing_analyzer.Shutdown();
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
      // 分析専用。前Tickで決済検知しキューへ積んだポジションの履歴を確定させる。
      ProcessPendingClosedPositions();
      // 既存ポジション管理の一部。エントリー根拠（トレンド/ADX）が消失した保有ポジションを
      // 満期(SL/TP)を待たず早期決済する。新規候補評価より先に行う。
      EvaluateSignalInvalidationExits();
      // 既存ポジション管理の一部。Entry後の経過バー数が上限を超えたポジションを、シグナルの
      // 有効期限切れとみなし早期決済する（必要に応じ最低MFE到達判定を伴う）。
      EvaluateTimeStopExits();
      // レンジ戦略のポジション管理（トレンド戦略とは独立）。Range Filter解除・レンジブレイク・
      // BB Width急拡大での早期決済、および独立した時間切れ決済。
      EvaluateMeanReversionForcedExits();
      EvaluateMeanReversionTimeStopExits();

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
      if(!CPositionProtectionRules::IsManagedPosition(HistoryDealGetInteger(transaction.deal,DEAL_MAGIC),
         m_config.magic_number,m_config.mean_reversion_magic_number)) return;
      const string symbol=HistoryDealGetString(transaction.deal,DEAL_SYMBOL);
      const ulong position_identifier=(ulong)HistoryDealGetInteger(transaction.deal,DEAL_POSITION_ID);
      const string candidate_id=CandidateForPosition(position_identifier,symbol);
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
         // コスト感応度分析用: 約定Tickそのものではないが、決済検知直後のSpreadをベストエフォートで記録する。
         MqlTick exit_tick;
         double exit_spread_points=0.0;
         if(SymbolInfoTick(symbol,exit_tick))
           {
            const double exit_point=SymbolInfoDouble(symbol,SYMBOL_POINT);
            if(exit_point>0.0) exit_spread_points=(exit_tick.ask-exit_tick.bid)/exit_point;
           }
         m_pending_closed_positions[slot].exit_spread_points=exit_spread_points;
         // 履歴が既に確定している場合に備え、今Tick内でも即時確定を試みる（次Tickを待たせない）。
         ProcessPendingClosedPositions();
        }
     }
  };

#endif
