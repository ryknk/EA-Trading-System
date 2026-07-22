#ifndef EA_TRADING_SYSTEM_DRAWDOWN_GUARD_MQH
#define EA_TRADING_SYSTEM_DRAWDOWN_GUARD_MQH

class CDrawdownGuard
  {
private:
   double m_limit_rate;
   double m_high_water_equity;
   double m_current_drawdown_rate;
   string m_high_water_key;
   string m_lock_key;
   bool   m_locked;
   bool   m_initialized;

public:
   CDrawdownGuard(void)
     {
      m_limit_rate=0.0;
      m_high_water_equity=0.0;
      m_current_drawdown_rate=0.0;
      m_high_water_key="";
      m_lock_key="";
      m_locked=false;
      m_initialized=false;
     }

   static double DrawdownRate(const double high_water,const double current_equity)
     {
      if(high_water<=0.0 || current_equity>=high_water)
         return 0.0;
      return (high_water-current_equity)/high_water;
     }

   static bool IsBreached(const double high_water,const double current_equity,const double limit_rate)
     {
      if(high_water<=0.0 || current_equity<0.0 || limit_rate<=0.0)
         return true;
      return DrawdownRate(high_water,current_equity)+1.0e-12>=limit_rate;
     }

   static bool NextLocked(const bool previously_locked,const bool currently_breached)
     { return previously_locked || currently_breached; }

   bool Initialize(const double limit_rate,string &error)
     {
      error="";
      m_initialized=false;
      const double equity=AccountInfoDouble(ACCOUNT_EQUITY);
      if(limit_rate<=0.0 || equity<=0.0)
        { error="DRAWDOWN_STATE_UNAVAILABLE"; return false; }
      m_limit_rate=limit_rate;
      const string identity=StringFormat("%I64d",AccountInfoInteger(ACCOUNT_LOGIN));
      // The key is account-wide so drawdown remains authoritative across strategies.
      m_high_water_key="ETS.DD.HWM."+identity;
      m_lock_key="ETS.DD.LOCK."+identity;
      if(GlobalVariableCheck(m_high_water_key))
         m_high_water_equity=GlobalVariableGet(m_high_water_key);
      else
        {
         m_high_water_equity=equity;
         ResetLastError();
         if(GlobalVariableSet(m_high_water_key,m_high_water_equity)==0 && GetLastError()!=0)
           { error="DRAWDOWN_STATE_PERSIST_FAILED"; return false; }
        }
      if(m_high_water_equity<=0.0 || !MathIsValidNumber(m_high_water_equity))
        { error="DRAWDOWN_HIGH_WATER_INVALID"; return false; }
      m_locked=GlobalVariableCheck(m_lock_key) && GlobalVariableGet(m_lock_key)>0.5;
      m_initialized=true;
      string reason;
      return Evaluate(reason,error);
     }

   bool Evaluate(string &reason_code,string &error)
     {
      reason_code="";
      error="";
      if(!m_initialized)
        { error="DRAWDOWN_GUARD_NOT_INITIALIZED"; return false; }
      const double equity=AccountInfoDouble(ACCOUNT_EQUITY);
      if(equity<=0.0 || !MathIsValidNumber(equity))
        { error="EQUITY_UNAVAILABLE"; return false; }
      if(equity>m_high_water_equity)
        {
         m_high_water_equity=equity;
         ResetLastError();
         if(GlobalVariableSet(m_high_water_key,m_high_water_equity)==0 && GetLastError()!=0)
           { error="DRAWDOWN_STATE_PERSIST_FAILED"; return false; }
        }
      m_current_drawdown_rate=DrawdownRate(m_high_water_equity,equity);
      if(NextLocked(m_locked,IsBreached(m_high_water_equity,equity,m_limit_rate)))
        {
         m_locked=true;
         ResetLastError();
         if(GlobalVariableSet(m_lock_key,1.0)==0 && GetLastError()!=0)
           { error="DRAWDOWN_LOCK_PERSIST_FAILED"; return false; }
         reason_code="DD_LIMIT";
        }
      return true;
     }

   bool IsLocked(void) const { return m_locked; }
   double CurrentDrawdownRate(void) const { return m_current_drawdown_rate; }
   double HighWaterEquity(void) const { return m_high_water_equity; }
  };

#endif
