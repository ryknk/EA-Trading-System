#ifndef EA_TRADING_SYSTEM_POSITION_MANAGER_MQH
#define EA_TRADING_SYSTEM_POSITION_MANAGER_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/Trading/OrderManager.mqh>

class CPositionProtectionRules
  {
public:
   static bool HasValidProtectiveStop(const ENUM_POSITION_TYPE type,const double bid,
                                      const double ask,const double stop_loss)
     {
      if(bid<=0.0 || ask<=0.0 || ask<bid || stop_loss<=0.0)
         return false;
      if(type==POSITION_TYPE_BUY) return stop_loss<bid;
      if(type==POSITION_TYPE_SELL) return stop_loss>ask;
      return false;
     }

   static bool IsManagedPosition(const long position_magic,const ulong configured_magic)
     {
      return position_magic==(long)configured_magic;
     }
  };

class CBreakevenStopRules
  {
public:
   // 含み益が「建値から当初SLまでの距離（初期リスク）」のtrigger_r_multiple倍に達したかを判定する。
   // current_slが既に建値以上（BUY: sl>=建値、SELL: sl<=建値）の場合はrisk_distance<=0となり、
   // 既に建値へ移動済み（または当初から建値以上）とみなして対象外とする（べき等性を状態フラグなしで担保）。
   static bool ShouldMoveToBreakeven(const ENUM_POSITION_TYPE type,const double open_price,
                                     const double current_sl,const double bid,const double ask,
                                     const double trigger_r_multiple)
     {
      if(trigger_r_multiple<=0.0 || current_sl<=0.0 || open_price<=0.0 || bid<=0.0 || ask<=0.0)
         return false;
      double risk_distance,profit_distance;
      if(type==POSITION_TYPE_BUY)
        {
         risk_distance=open_price-current_sl;
         profit_distance=bid-open_price;
        }
      else if(type==POSITION_TYPE_SELL)
        {
         risk_distance=current_sl-open_price;
         profit_distance=open_price-ask;
        }
      else
         return false;
      if(risk_distance<=0.0)
         return false;
      return profit_distance>=risk_distance*trigger_r_multiple;
     }
  };

class CSignalExitVolumeRules
  {
public:
   // 一部利確の決済量算出。Volume Stepの倍数へ切り下げ、決済量・残存量のいずれかがVolume Min未満に
   // なる場合は分割不可（0を返す＝一部利確を見送り、そのまま保有を継続する）とする。
   // 最小Lot未満を無条件で引き上げることはしない。
   static double ClosableVolume(const double current_volume,const double close_fraction,
                                const double volume_step,const double volume_min)
     {
      if(current_volume<=0.0 || close_fraction<=0.0 || close_fraction>=1.0 || volume_step<=0.0)
         return 0.0;
      const double raw=current_volume*close_fraction;
      const double steps=MathFloor(raw/volume_step);
      const double close_volume=NormalizeDouble(steps*volume_step,8);
      const double remaining=NormalizeDouble(current_volume-close_volume,8);
      if(close_volume<volume_min || remaining<volume_min)
         return 0.0;
      return close_volume;
     }
  };

class CPositionManager
  {
private:
   SEaConfig m_config;
   ulong     m_emergency_attempt_ticket;
   string    m_emergency_key_prefix;
   string    m_signal_exit_key_prefix;
   ulong     m_signal_exit_attempt_ticket;
   string    m_signal_partial_key_prefix;
   bool      m_initialized;

   ENUM_ORDER_TYPE_FILLING FillingMode(const string symbol)
     {
      const long modes=SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE);
      if((modes & SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK) return ORDER_FILLING_FOK;
      if((modes & SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC) return ORDER_FILLING_IOC;
      return ORDER_FILLING_RETURN;
     }

   bool EmergencyClose(const ulong ticket,string &error)
     {
      error="";
      const string attempt_key=m_emergency_key_prefix+StringFormat("%I64u",ticket);
      if(ticket==m_emergency_attempt_ticket || GlobalVariableCheck(attempt_key))
        { error="EMERGENCY_CLOSE_ALREADY_ATTEMPTED"; return false; }
      if(!PositionSelectByTicket(ticket))
        { error="POSITION_SELECT_FAILED"; return false; }
      const string symbol=PositionGetString(POSITION_SYMBOL);
      const double volume=PositionGetDouble(POSITION_VOLUME);
      const ENUM_POSITION_TYPE position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      MqlTick tick;
      if(volume<=0.0 || !SymbolInfoTick(symbol,tick))
        { error="POSITION_CLOSE_DATA_UNAVAILABLE"; return false; }

      MqlTradeRequest request;
      MqlTradeCheckResult check;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(check);
      ZeroMemory(result);
      request.action=TRADE_ACTION_DEAL;
      request.magic=m_config.magic_number;
      request.position=ticket;
      request.symbol=symbol;
      request.volume=volume;
      request.type=(position_type==POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY);
      request.price=(position_type==POSITION_TYPE_BUY ? tick.bid : tick.ask);
      request.deviation=m_config.max_deviation_points;
      request.type_filling=FillingMode(symbol);
      request.comment="EMERGENCY_NO_SL";
      if(!OrderCheck(request,check) || check.retcode!=TRADE_RETCODE_DONE)
        { error=StringFormat("EMERGENCY_ORDER_CHECK_FAILED retcode=%u comment=%s",check.retcode,check.comment); return false; }
      ResetLastError();
      if(GlobalVariableSet(attempt_key,1.0)==0 && GetLastError()!=0)
        { error="EMERGENCY_IDEMPOTENCY_PERSIST_FAILED"; return false; }
      GlobalVariablesFlush();
      m_emergency_attempt_ticket=ticket;
      if(!OrderSend(request,result) || !COrderValidationRules::AcceptedRetcode(result.retcode))
        { error=StringFormat("EMERGENCY_CLOSE_FAILED retcode=%u comment=%s",result.retcode,result.comment); return false; }
      PrintFormat("EMERGENCY_CLOSE_SUBMITTED position=%I64u order=%I64u deal=%I64u retcode=%u reason=UNPROTECTED_POSITION",
                  ticket,result.order,result.deal,result.retcode);
      return true;
     }

   bool ModifyStopLoss(const ulong ticket,const double new_sl,string &error)
     {
      error="";
      if(!PositionSelectByTicket(ticket))
        { error="POSITION_SELECT_FAILED"; return false; }
      const string symbol=PositionGetString(POSITION_SYMBOL);
      const double take_profit=PositionGetDouble(POSITION_TP);

      MqlTradeRequest request;
      MqlTradeCheckResult check;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(check);
      ZeroMemory(result);
      request.action=TRADE_ACTION_SLTP;
      request.magic=m_config.magic_number;
      request.position=ticket;
      request.symbol=symbol;
      request.sl=new_sl;
      request.tp=take_profit;

      ResetLastError();
      const bool check_ok=OrderCheck(request,check);
      if(!COrderCheckRules::IsAccepted(check_ok,check.retcode))
        { error=StringFormat("SL_MODIFY_ORDER_CHECK_FAILED retcode=%u comment=%s",check.retcode,check.comment); return false; }
      if(!OrderSend(request,result) || !COrderValidationRules::AcceptedRetcode(result.retcode))
        { error=StringFormat("SL_MODIFY_FAILED retcode=%u comment=%s",result.retcode,result.comment); return false; }
      PrintFormat("SL_MODIFIED position=%I64u new_sl=%.8f retcode=%u",ticket,new_sl,result.retcode);
      return true;
     }

public:
   CPositionManager(void)
     {
      m_emergency_attempt_ticket=0;
      m_emergency_key_prefix="";
      m_signal_exit_attempt_ticket=0;
      m_initialized=false;
     }

   bool Initialize(const SEaConfig &config,string &error)
     {
      error="";
      m_config=config;
      const string identity=StringFormat("%I64d",AccountInfoInteger(ACCOUNT_LOGIN));
      m_emergency_key_prefix="ETS.POS.EMERGENCY."+identity+"."+StringFormat("%I64u",m_config.magic_number)+".";
      if(StringLen(m_emergency_key_prefix)+20>63)
        { error="POSITION_STATE_KEY_TOO_LONG"; return false; }
      m_signal_exit_key_prefix="ETS.POS.SIGNALEXIT."+identity+"."+StringFormat("%I64u",m_config.magic_number)+".";
      if(StringLen(m_signal_exit_key_prefix)+20>63)
        { error="POSITION_STATE_KEY_TOO_LONG"; return false; }
      m_signal_partial_key_prefix="ETS.POS.SIGNALPARTIAL."+identity+"."+StringFormat("%I64u",m_config.magic_number)+".";
      if(StringLen(m_signal_partial_key_prefix)+20>63)
        { error="POSITION_STATE_KEY_TOO_LONG"; return false; }
      m_emergency_attempt_ticket=0;
      m_signal_exit_attempt_ticket=0;
      m_initialized=true;
      return true;
     }

   bool Monitor(string &error)
     {
      error="";
      if(!m_initialized)
        { error="POSITION_MANAGER_NOT_INITIALIZED"; return false; }
      const int total=PositionsTotal();
      for(int index=0; index<total; index++)
        {
         const ulong ticket=PositionGetTicket(index);
         if(ticket==0)
           { error="POSITION_ENUMERATION_FAILED"; return false; }
         const long magic=PositionGetInteger(POSITION_MAGIC);
         if(!CPositionProtectionRules::IsManagedPosition(magic,m_config.magic_number))
            continue;
         const string symbol=PositionGetString(POSITION_SYMBOL);
         const ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         const double stop_loss=PositionGetDouble(POSITION_SL);
         MqlTick tick;
         if(!SymbolInfoTick(symbol,tick))
           { error="POSITION_TICK_UNAVAILABLE"; return false; }
         if(CPositionProtectionRules::HasValidProtectiveStop(type,tick.bid,tick.ask,stop_loss))
           {
            const double open_price=PositionGetDouble(POSITION_PRICE_OPEN);
            // 分析ではなくリスク管理: 含み益が初期リスクのtrigger_r_multiple倍に達したらSLを建値へ引き上げる。
            // 失敗しても既存の保護SLは維持されるため、Monitor()全体を失敗させず次Tickで再試行する。
            if(m_config.enable_breakeven_stop && m_config.enable_trade_mutations &&
               CBreakevenStopRules::ShouldMoveToBreakeven(type,open_price,stop_loss,
                                                          tick.bid,tick.ask,m_config.breakeven_trigger_r_multiple))
              {
               string breakeven_error;
               if(!ModifyStopLoss(ticket,open_price,breakeven_error))
                  PrintFormat("BREAKEVEN_SL_MOVE_FAILED position=%I64u code=%s",ticket,breakeven_error);
              }
            continue;
           }

         if(!m_config.close_unprotected_positions)
           { error="UNPROTECTED_POSITION"; return false; }
         if(!m_config.enable_trade_mutations)
           { error="UNPROTECTED_POSITION_MUTATIONS_DISABLED"; return false; }
         string close_error;
         if(!EmergencyClose(ticket,close_error))
           { error=close_error; return false; }
         // Keep new entries disabled until a later tick confirms that the position is gone.
         error="EMERGENCY_CLOSE_PENDING";
         return false;
        }
      m_emergency_attempt_ticket=0;
      return true;
     }

   // エントリー根拠（トレンド/ADX）が消失した保有ポジションを、満期(SL/TP)を待たず市場成行で決済する。
   // reason_codeはCTrendFollowingStrategy::IsTrendStillValidが返す不合格理由（TREND_REVERSED等）。
   // EmergencyCloseと同じ考え方で、GlobalVariableベースのべき等性により二重約定を防止する。
   bool CloseOnSignalInvalidation(const ulong ticket,const string reason_code,string &error)
     {
      error="";
      const string attempt_key=m_signal_exit_key_prefix+StringFormat("%I64u",ticket);
      if(ticket==m_signal_exit_attempt_ticket || GlobalVariableCheck(attempt_key))
        { error="SIGNAL_EXIT_ALREADY_ATTEMPTED"; return false; }
      if(!PositionSelectByTicket(ticket))
        { error="POSITION_SELECT_FAILED"; return false; }
      const string symbol=PositionGetString(POSITION_SYMBOL);
      const double volume=PositionGetDouble(POSITION_VOLUME);
      const ENUM_POSITION_TYPE position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      MqlTick tick;
      if(volume<=0.0 || !SymbolInfoTick(symbol,tick))
        { error="POSITION_CLOSE_DATA_UNAVAILABLE"; return false; }

      MqlTradeRequest request;
      MqlTradeCheckResult check;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(check);
      ZeroMemory(result);
      request.action=TRADE_ACTION_DEAL;
      request.magic=m_config.magic_number;
      request.position=ticket;
      request.symbol=symbol;
      request.volume=volume;
      request.type=(position_type==POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY);
      request.price=(position_type==POSITION_TYPE_BUY ? tick.bid : tick.ask);
      request.deviation=m_config.max_deviation_points;
      request.type_filling=FillingMode(symbol);
      request.comment=StringSubstr("SIGNAL_"+reason_code,0,31);

      ResetLastError();
      const bool check_ok=OrderCheck(request,check);
      if(!COrderCheckRules::IsAccepted(check_ok,check.retcode))
        { error=StringFormat("SIGNAL_EXIT_ORDER_CHECK_FAILED retcode=%u comment=%s",check.retcode,check.comment); return false; }
      // Persist before sending. An ambiguous failure is never retried automatically
      // (matches EmergencyClose's idempotency convention).
      ResetLastError();
      if(GlobalVariableSet(attempt_key,1.0)==0 && GetLastError()!=0)
        { error="SIGNAL_EXIT_IDEMPOTENCY_PERSIST_FAILED"; return false; }
      GlobalVariablesFlush();
      m_signal_exit_attempt_ticket=ticket;
      if(!OrderSend(request,result) || !COrderValidationRules::AcceptedRetcode(result.retcode))
        { error=StringFormat("SIGNAL_EXIT_FAILED retcode=%u comment=%s",result.retcode,result.comment); return false; }
      PrintFormat("SIGNAL_EXIT_SUBMITTED position=%I64u order=%I64u deal=%I64u retcode=%u reason=%s",
                  ticket,result.order,result.deal,result.retcode,reason_code);
      return true;
     }

   // エントリー根拠の一部（H1 ADX）が弱体化した保有ポジションを、現在volumeのclose_fraction割合だけ
   // 一部利確する（残りは保有継続、満期(SL/TP)を待たず一部だけ確定）。
   // CloseOnSignalInvalidation（完全決済）とは別の独立したGlobalVariable名前空間でべき等性を担保する
   // （一度弱体化を検知して一部利確したら、同一ポジションに対して再度は行わない）。
   bool ClosePartialOnSignalWeakening(const ulong ticket,const double close_fraction,
                                      const string reason_code,string &error)
     {
      error="";
      const string attempt_key=m_signal_partial_key_prefix+StringFormat("%I64u",ticket);
      if(GlobalVariableCheck(attempt_key))
        { error="SIGNAL_PARTIAL_EXIT_ALREADY_ATTEMPTED"; return false; }
      if(!PositionSelectByTicket(ticket))
        { error="POSITION_SELECT_FAILED"; return false; }
      const string symbol=PositionGetString(POSITION_SYMBOL);
      const ENUM_POSITION_TYPE position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      const double volume_step=SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
      const double volume_min=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
      const double close_volume=CSignalExitVolumeRules::ClosableVolume(
         PositionGetDouble(POSITION_VOLUME),close_fraction,volume_step,volume_min);
      MqlTick tick;
      if(close_volume<=0.0 || !SymbolInfoTick(symbol,tick))
        { error="POSITION_CLOSE_DATA_UNAVAILABLE"; return false; }

      MqlTradeRequest request;
      MqlTradeCheckResult check;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(check);
      ZeroMemory(result);
      request.action=TRADE_ACTION_DEAL;
      request.magic=m_config.magic_number;
      request.position=ticket;
      request.symbol=symbol;
      request.volume=close_volume;
      request.type=(position_type==POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY);
      request.price=(position_type==POSITION_TYPE_BUY ? tick.bid : tick.ask);
      request.deviation=m_config.max_deviation_points;
      request.type_filling=FillingMode(symbol);
      request.comment=StringSubstr("SIGPART_"+reason_code,0,31);

      ResetLastError();
      const bool check_ok=OrderCheck(request,check);
      if(!COrderCheckRules::IsAccepted(check_ok,check.retcode))
        { error=StringFormat("SIGNAL_PARTIAL_EXIT_ORDER_CHECK_FAILED retcode=%u comment=%s",check.retcode,check.comment); return false; }
      // Persist before sending. An ambiguous failure is never retried automatically
      // (matches EmergencyClose's idempotency convention).
      ResetLastError();
      if(GlobalVariableSet(attempt_key,1.0)==0 && GetLastError()!=0)
        { error="SIGNAL_PARTIAL_EXIT_IDEMPOTENCY_PERSIST_FAILED"; return false; }
      GlobalVariablesFlush();
      if(!OrderSend(request,result) || !COrderValidationRules::AcceptedRetcode(result.retcode))
        { error=StringFormat("SIGNAL_PARTIAL_EXIT_FAILED retcode=%u comment=%s",result.retcode,result.comment); return false; }
      PrintFormat("SIGNAL_PARTIAL_EXIT_SUBMITTED position=%I64u order=%I64u deal=%I64u retcode=%u volume=%.8f reason=%s",
                  ticket,result.order,result.deal,result.retcode,close_volume,reason_code);
      return true;
     }

   void OnTradeTransaction(const MqlTradeTransaction &transaction)
     {
      if(transaction.type!=TRADE_TRANSACTION_DEAL_ADD || transaction.deal==0)
         return;
      if(!HistoryDealSelect(transaction.deal))
         return;
      const long magic=HistoryDealGetInteger(transaction.deal,DEAL_MAGIC);
      if(!CPositionProtectionRules::IsManagedPosition(magic,m_config.magic_number))
         return;
      const ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(transaction.deal,DEAL_ENTRY);
      const string symbol=HistoryDealGetString(transaction.deal,DEAL_SYMBOL);
      const double price=HistoryDealGetDouble(transaction.deal,DEAL_PRICE);
      const double volume=HistoryDealGetDouble(transaction.deal,DEAL_VOLUME);
      const double pnl=HistoryDealGetDouble(transaction.deal,DEAL_PROFIT)+
                       HistoryDealGetDouble(transaction.deal,DEAL_COMMISSION)+
                       HistoryDealGetDouble(transaction.deal,DEAL_SWAP)+
                       HistoryDealGetDouble(transaction.deal,DEAL_FEE);
      PrintFormat("TRADE_DEAL deal=%I64u order=%I64u position=%I64u symbol=%s entry=%s price=%.8f volume=%.8f pnl=%.2f",
                  transaction.deal,transaction.order,transaction.position,symbol,EnumToString(entry),price,volume,pnl);
     }
  };

#endif
