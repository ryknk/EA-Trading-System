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

class CPositionManager
  {
private:
   SEaConfig m_config;
   ulong     m_emergency_attempt_ticket;
   string    m_emergency_key_prefix;
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

public:
   CPositionManager(void)
     {
      m_emergency_attempt_ticket=0;
      m_emergency_key_prefix="";
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
      m_emergency_attempt_ticket=0;
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
            continue;

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
