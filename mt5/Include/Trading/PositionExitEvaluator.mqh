#ifndef EA_TRADING_SYSTEM_POSITION_EXIT_EVALUATOR_MQH
#define EA_TRADING_SYSTEM_POSITION_EXIT_EVALUATOR_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/Strategy/TrendFollowingStrategy.mqh>
#include <EaTradingSystem/Strategy/MeanReversionStrategy.mqh>
#include <EaTradingSystem/Trading/PositionManager.mqh>
#include <EaTradingSystem/Logging/AuditPayloadBuilder.mqh>
#include <EaTradingSystem/Logging/AuditEventPublisher.mqh>
#include <EaTradingSystem/Core/ClosedPositionProcessor.mqh>

// 保有ポジションに対するExit判定（Signal Invalidation / Time Stop / Mean Reversion Forced Exit）。
// 判断（Strategy参照・経過バー数・MFE等）をここで行い、メカニズム（決済実行）はPositionManagerへ、
// Time Stop状態の保持・更新はCTimeStopTrackerへ委ねる。
class CPositionExitEvaluator
  {
private:
   SEaConfig                m_config;
   CTrendFollowingStrategy *m_strategy;
   CMeanReversionStrategy  *m_mean_reversion_strategy;
   CPositionManager        *m_position_manager;
   CAuditEventPublisher    *m_publisher;
   CTimeStopTracker         m_time_stop_tracker;

   string JString(const string value) { return CAuditPayloadBuilder::JString(value); }
   string JNumber(const double value) { return CAuditPayloadBuilder::JNumber(value); }

   void Audit(const string event_type,const string candidate_id,const string request_id,
              const string symbol,const string payload,const bool send_remote)
     {
      m_publisher.Audit(event_type,candidate_id,request_id,symbol,payload,send_remote);
     }

   // Entry後、entry_timeframe換算で何本の確定足が経過したかを返す（look-ahead biasを避けるため、
   // 当日の未確定足は本数へ含めない）。Bars(symbol,timeframe,open_time,TimeCurrent())は境界を含むため-1する。
   int ElapsedClosedBars(const string symbol,const ENUM_TIMEFRAMES timeframe,const datetime open_time)
     {
      const int bars=Bars(symbol,timeframe,open_time,TimeCurrent());
      return bars>0 ? bars-1 : 0;
     }

public:
   CPositionExitEvaluator(void)
     {
      m_strategy=NULL;
      m_mean_reversion_strategy=NULL;
      m_position_manager=NULL;
      m_publisher=NULL;
     }

   void Initialize(const SEaConfig &config,CTrendFollowingStrategy *strategy,
                   CMeanReversionStrategy *mean_reversion_strategy,
                   CPositionManager *position_manager,CAuditEventPublisher *publisher)
     {
      m_config=config;
      m_strategy=strategy;
      m_mean_reversion_strategy=mean_reversion_strategy;
      m_position_manager=position_manager;
      m_publisher=publisher;
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
         const string candidate_id=CClosedPositionProcessor::CandidateForPosition(m_config.ea_id,position_identifier,symbol);
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
   // 実勢価格（Bid/Ask）ベースのレンジブレイクが一定秒数継続したことを検知したら満期を待たず
   // 市場成行で決済する（Range Filter解除単独では即決済しない、2026-08-25/26仕様変更。詳細は
   // CMeanReversionStrategy::IsRangeStillValid参照）。本メソッドはOnTick毎に呼ばれるため、
   // Tickベースのブレイク監視も自然に実現される（EAController::OnTick参照）。
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
         string alert_transition;
         const bool still_valid=m_mean_reversion_strategy.IsRangeStillValid(
            ticket,direction,reason_code,alert_transition);

         // 警戒状態（Range Filter解除後、ブレイク確認待ち）の遷移を監査ログへ記録する（2026-08-25
         // 追加、ユーザー依頼）。決済に至らない状態遷移専用のため、決済確定時のRANGE_EXITとは
         // 別イベント（RANGE_ALERT）とする。ポジションが同時に決済される場合でもここで先に
         // 識別子を確保する（下のRANGE_EXIT側の識別子取得と同じ安全な順序）。
         if(StringLen(alert_transition)>0)
           {
            const string alert_symbol=PositionGetString(POSITION_SYMBOL);
            const ulong alert_position_identifier=(ulong)PositionGetInteger(POSITION_IDENTIFIER);
            const string alert_candidate_id=CClosedPositionProcessor::CandidateForPosition(
               m_config.ea_id,alert_position_identifier,alert_symbol);
            string alert_payload="{";
            alert_payload+="\"position_ticket\":"+JString(StringFormat("%I64u",ticket))+",";
            alert_payload+="\"transition\":"+JString(alert_transition)+"}";
            Audit("RANGE_ALERT",alert_candidate_id,"",alert_symbol,alert_payload,false);
           }

         if(!still_valid)
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
            // （TICK_BREAK_EXIT/BB_WIDTH_EXPANSION等）を専用イベントへ記録する。TICK_BREAK_EXITは
            // 警戒状態中にBid/Askベースのレンジブレイクが実時間でBreakConfirmSeconds以上継続した
            // 場合の理由コード（2026-08-26追加、ユーザー依頼: 従来のSL/TP等と区別できるようにする）。
            // TIME_STOP_EXITと同じくローカル監査のみ、既存TRADE_CLOSEDの契約は変更しない。
            const int elapsed_bars=ElapsedClosedBars(symbol,m_config.entry_timeframe,open_time);
            const string candidate_id=CClosedPositionProcessor::CandidateForPosition(m_config.ea_id,position_identifier,symbol);
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
         const string candidate_id=CClosedPositionProcessor::CandidateForPosition(m_config.ea_id,position_identifier,symbol);
         string payload="{";
         payload+="\"position_ticket\":"+JString(StringFormat("%I64u",ticket))+",";
         payload+="\"reason_code\":"+JString("MEAN_REVERSION_MAX_HOLDING_BARS")+",";
         payload+="\"elapsed_bars\":"+IntegerToString(elapsed_bars)+"}";
         Audit("RANGE_EXIT",candidate_id,"",symbol,payload,false);
        }
     }
  };

#endif
