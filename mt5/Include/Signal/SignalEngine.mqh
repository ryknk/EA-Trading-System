#ifndef EA_TRADING_SYSTEM_SIGNAL_ENGINE_MQH
#define EA_TRADING_SYSTEM_SIGNAL_ENGINE_MQH

#include <EaTradingSystem/Strategy/IStrategy.mqh>

class CSignalEngine
  {
private:
   IStrategy         *m_strategy;
   string             m_symbol;
   ENUM_TIMEFRAMES    m_timeframe;
   datetime           m_current_bar_time;
   bool               m_initialized;

public:
   CSignalEngine(void)
     {
      m_strategy=NULL;
      m_symbol="";
      m_timeframe=PERIOD_CURRENT;
      m_current_bar_time=0;
      m_initialized=false;
     }

   bool Initialize(IStrategy *strategy,const string symbol,const ENUM_TIMEFRAMES timeframe,string &error)
     {
      error="";
      if(strategy==NULL)
        { error="NULL_STRATEGY"; return false; }
      const datetime current_bar=iTime(symbol,timeframe,0);
      if(current_bar<=0)
        { error="ENTRY_TIMEFRAME_DATA_UNAVAILABLE"; return false; }
      m_strategy=strategy;
      m_symbol=symbol;
      m_timeframe=timeframe;
      m_current_bar_time=current_bar;
      m_initialized=true;
      return true;
     }

   bool Poll(SSignalResult &result,bool &evaluated)
     {
      ResetSignalResult(result);
      evaluated=false;
      if(!m_initialized || m_strategy==NULL)
        {
         result.status=SIGNAL_STATUS_ERROR;
         result.reason_code="SIGNAL_ENGINE_NOT_INITIALIZED";
         result.reason="Signal engine is not initialized.";
         return false;
        }
      const datetime current_bar=iTime(m_symbol,m_timeframe,0);
      if(current_bar<=0)
        {
         result.status=SIGNAL_STATUS_ERROR;
         result.reason_code="BAR_TIME_UNAVAILABLE";
         result.reason="Current entry bar time is unavailable.";
         return false;
        }
      if(current_bar==m_current_bar_time)
         return true;

      // Advance before evaluation so repeated ticks cannot duplicate a candidate after an error.
      m_current_bar_time=current_bar;
      evaluated=true;
      return m_strategy.Evaluate(result);
     }
  };

#endif
