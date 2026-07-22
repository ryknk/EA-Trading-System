#ifndef EA_TRADING_SYSTEM_DAILY_LOSS_GUARD_MQH
#define EA_TRADING_SYSTEM_DAILY_LOSS_GUARD_MQH

class CDailyLossGuard
  {
private:
   double   m_limit_rate;
   double   m_start_equity;
   double   m_current_loss_rate;
   datetime m_day_start;
   string   m_equity_key;
   string   m_lock_key;
   bool     m_locked;
   bool     m_initialized;

   datetime BrokerDayStart(const datetime now)
     {
      MqlDateTime parts;
      TimeToStruct(now,parts);
      parts.hour=0;
      parts.min=0;
      parts.sec=0;
      return StructToTime(parts);
     }

   string DateToken(const datetime value)
     {
      MqlDateTime parts;
      TimeToStruct(value,parts);
      return StringFormat("%04d%02d%02d",parts.year,parts.mon,parts.day);
     }

   double RealizedTradingResult(const datetime from,const datetime to,bool &ok)
     {
      ok=false;
      if(!HistorySelect(from,to))
         return 0.0;
      double result=0.0;
      const int total=HistoryDealsTotal();
      for(int index=0; index<total; index++)
        {
         const ulong ticket=HistoryDealGetTicket(index);
         if(ticket==0) return 0.0;
         const ENUM_DEAL_TYPE type=(ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket,DEAL_TYPE);
         if(type!=DEAL_TYPE_BUY && type!=DEAL_TYPE_SELL)
            continue;
         result+=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         result+=HistoryDealGetDouble(ticket,DEAL_COMMISSION);
         result+=HistoryDealGetDouble(ticket,DEAL_SWAP);
         result+=HistoryDealGetDouble(ticket,DEAL_FEE);
        }
      ok=true;
      return result;
     }

public:
   CDailyLossGuard(void)
     {
      m_limit_rate=0.0;
      m_start_equity=0.0;
      m_current_loss_rate=0.0;
      m_day_start=0;
      m_equity_key="";
      m_lock_key="";
      m_locked=false;
      m_initialized=false;
     }

   static double LossRate(const double start_equity,const double current_equity)
     {
      if(start_equity<=0.0 || current_equity>=start_equity)
         return 0.0;
      return (start_equity-current_equity)/start_equity;
     }

   static bool IsBreached(const double start_equity,const double current_equity,const double limit_rate)
     {
      if(start_equity<=0.0 || current_equity<0.0 || limit_rate<=0.0)
         return true;
      return LossRate(start_equity,current_equity)+1.0e-12>=limit_rate;
     }

   static bool NextLocked(const bool previously_locked,const bool currently_breached)
     { return previously_locked || currently_breached; }

   static datetime ServerDayStart(const datetime now)
     {
      MqlDateTime parts;
      TimeToStruct(now,parts);
      parts.hour=0; parts.min=0; parts.sec=0;
      return StructToTime(parts);
     }

   bool Initialize(const double limit_rate,string &error)
     {
      error="";
      m_initialized=false;
      if(limit_rate<=0.0)
        { error="INVALID_DAILY_LOSS_LIMIT"; return false; }
      const datetime now=TimeTradeServer();
      const double equity=AccountInfoDouble(ACCOUNT_EQUITY);
      const double balance=AccountInfoDouble(ACCOUNT_BALANCE);
      if(now<=0 || equity<=0.0 || balance<0.0)
        { error="DAILY_RISK_STATE_UNAVAILABLE"; return false; }
      m_limit_rate=limit_rate;
      m_day_start=BrokerDayStart(now);
      const string identity=StringFormat("%I64d",AccountInfoInteger(ACCOUNT_LOGIN));
      const string token=DateToken(m_day_start);
      m_equity_key="ETS.DAILY.EQ."+identity+"."+token;
      m_lock_key="ETS.DAILY.LOCK."+identity+"."+token;

      if(GlobalVariableCheck(m_equity_key))
         m_start_equity=GlobalVariableGet(m_equity_key);
      else
        {
         bool history_ok=false;
         const double realized=RealizedTradingResult(m_day_start,now,history_ok);
         if(!history_ok)
           { error="DAILY_HISTORY_UNAVAILABLE"; return false; }
         // First start mid-day cannot recover carried floating P/L. The larger baseline is fail-safe.
         m_start_equity=MathMax(equity,balance-realized);
         ResetLastError();
         if(GlobalVariableSet(m_equity_key,m_start_equity)==0 && GetLastError()!=0)
           { error="DAILY_STATE_PERSIST_FAILED"; return false; }
        }
      if(m_start_equity<=0.0 || !MathIsValidNumber(m_start_equity))
        { error="DAILY_BASELINE_INVALID"; return false; }
      m_locked=GlobalVariableCheck(m_lock_key) && GlobalVariableGet(m_lock_key)>0.5;
      m_current_loss_rate=LossRate(m_start_equity,equity);
      m_initialized=true;
      return true;
     }

   bool Evaluate(string &reason_code,string &error)
     {
      reason_code="";
      error="";
      if(!m_initialized)
        { error="DAILY_GUARD_NOT_INITIALIZED"; return false; }
      const datetime now=TimeTradeServer();
      if(BrokerDayStart(now)!=m_day_start)
        {
         if(!Initialize(m_limit_rate,error)) return false;
        }
      const double equity=AccountInfoDouble(ACCOUNT_EQUITY);
      if(equity<=0.0 || !MathIsValidNumber(equity))
        { error="EQUITY_UNAVAILABLE"; return false; }
      m_current_loss_rate=LossRate(m_start_equity,equity);
      if(NextLocked(m_locked,IsBreached(m_start_equity,equity,m_limit_rate)))
        {
         m_locked=true;
         ResetLastError();
         if(GlobalVariableSet(m_lock_key,1.0)==0 && GetLastError()!=0)
           { error="DAILY_LOCK_PERSIST_FAILED"; return false; }
         reason_code="DAILY_LOSS_LIMIT";
        }
      return true;
     }

   bool IsLocked(void) const { return m_locked; }
   double CurrentLossRate(void) const { return m_current_loss_rate; }
   double StartEquity(void) const { return m_start_equity; }
  };

#endif
