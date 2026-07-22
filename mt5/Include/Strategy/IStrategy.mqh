#ifndef EA_TRADING_SYSTEM_I_STRATEGY_MQH
#define EA_TRADING_SYSTEM_I_STRATEGY_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/Signal/SignalResult.mqh>

class IStrategy
  {
public:
   virtual bool Initialize(const SEaConfig &config,string &error)=0;
   virtual void Shutdown(void)=0;
   virtual bool Evaluate(SSignalResult &result)=0;
   virtual string Name(void) const=0;
  };

#endif
