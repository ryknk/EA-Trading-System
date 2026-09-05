#ifndef EA_TRADING_SYSTEM_CLOSED_POSITION_PROCESSOR_MQH
#define EA_TRADING_SYSTEM_CLOSED_POSITION_PROCESSOR_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/Logging/TradeLogger.mqh>
#include <EaTradingSystem/Logging/AuditPayloadBuilder.mqh>
#include <EaTradingSystem/Logging/AuditEventPublisher.mqh>
#include <EaTradingSystem/Logging/TradeAnalyticsTracker.mqh>

// 決済済みポジションの遅延確定処理。
// 決済直後はHistoryDealGetXxx(直近デタッチticket,...)の一部プロパティ(価格・volume・pnl等)が
// Strategy Tester上でまだ確定していないことがあるため、即時集計せずキューへ積み、
// 次Tick（履歴が確定した後）でTRADE_CLOSED・TRADE_ANALYTICSを確定させる。
class CClosedPositionProcessor
  {
private:
   struct SPendingClosedPosition
     {
      ulong  position_identifier;
      ulong  position_ticket;
      string symbol;
      // OnTradeTransaction検知時点（決済Tick直後）のSpreadをベストエフォートで記録する。
      // 決済自体はブローカー側SL/TP等で発生するため、約定Tickそのものの値ではない近似値。
      double exit_spread_points;
     };
   SPendingClosedPosition  m_pending_closed_positions[];
   SEaConfig               m_config;
   CAuditEventPublisher   *m_publisher;
   CTradeAnalyticsTracker *m_analytics_tracker;

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

public:
   CClosedPositionProcessor(void) { m_publisher=NULL; m_analytics_tracker=NULL; }

   void Initialize(const SEaConfig &config,CAuditEventPublisher *publisher,CTradeAnalyticsTracker *analytics_tracker)
     {
      m_config=config;
      m_publisher=publisher;
      m_analytics_tracker=analytics_tracker;
      ArrayResize(m_pending_closed_positions,0);
     }

   // Deal Commentから相関ID（trade_candidate_id）を復元する。決済済み・保有中いずれのpositionにも使用できる。
   // Deal CommentはOrderManager::Submitがentry_bar時刻のみを格納する（trade_candidate_id
   // 全体はMQL5のComment上限31文字を超えるため）。CANDIDATE/RISK_DECISION監査ログと同じ
   // "{ea_id}-{symbol}-{unix_time}"形式へ復元する。
   static string CandidateForPosition(const string ea_id,const ulong position_identifier,const string symbol)
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
         if(!CTradeLogRules::SafeCorrelationId(comment) || StringLen(comment)<1) continue;
         const string candidate_id=StringFormat("%s-%s-%s",ea_id,symbol,comment);
         if(CTradeLogRules::SafeCorrelationId(candidate_id)) return candidate_id;
        }
      return "unlinked";
     }

   // 決済検知時にキューへ積む。履歴がまだ確定していない可能性があるため、この時点では集計しない。
   void Enqueue(const ulong position_identifier,const ulong position_ticket,const string symbol,
                const double exit_spread_points)
     {
      const int slot=ArraySize(m_pending_closed_positions);
      ArrayResize(m_pending_closed_positions,slot+1);
      m_pending_closed_positions[slot].position_identifier=position_identifier;
      m_pending_closed_positions[slot].position_ticket=position_ticket;
      m_pending_closed_positions[slot].symbol=symbol;
      m_pending_closed_positions[slot].exit_spread_points=exit_spread_points;
     }

   // キュー済みの決済済みポジションを確定させ、TRADE_CLOSED・TRADE_ANALYTICSを記録する。
   // 履歴がまだ確定していない場合はキューに残し、次回の呼び出しで再試行する。
   void ProcessPending(void)
     {
      for(int index=ArraySize(m_pending_closed_positions)-1; index>=0; index--)
        {
         const ulong position_identifier=m_pending_closed_positions[index].position_identifier;
         const ulong position_ticket=m_pending_closed_positions[index].position_ticket;
         const string symbol=m_pending_closed_positions[index].symbol;
         if(!HistorySelectByPosition(position_identifier))
            continue;
         const string candidate_id=CandidateForPosition(m_config.ea_id,position_identifier,symbol);
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

         SClosedPositionEvent closed;
         closed.position_ticket=position_ticket;
         closed.direction=direction;
         closed.open_time=open_time;
         closed.close_time=close_time;
         closed.volume=closed_volume;
         closed.open_price=open_price;
         closed.close_price=close_price;
         closed.close_reason=close_reason;
         closed.pnl=total_pnl;
         closed.commission=total_commission;
         closed.swap=total_swap;
         closed.exit_spread_points=m_pending_closed_positions[index].exit_spread_points;
         closed.point_value=point_value;
         m_publisher.Audit("TRADE_CLOSED",candidate_id,"",symbol,
                           CAuditPayloadBuilder::BuildClosedPositionPayload(closed),true);

         double analytics_mfe=0.0,analytics_mae=0.0;
         if(m_analytics_tracker.Finalize(position_ticket,analytics_mfe,analytics_mae))
           {
            m_publisher.Audit("TRADE_ANALYTICS",candidate_id,"",symbol,
                              CAuditPayloadBuilder::BuildClosedPositionAnalyticsPayload(
                                 position_ticket,analytics_mfe,analytics_mae),true);
           }

         const int last=ArraySize(m_pending_closed_positions)-1;
         m_pending_closed_positions[index]=m_pending_closed_positions[last];
         ArrayResize(m_pending_closed_positions,last);
        }
     }
  };

#endif
