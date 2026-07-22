#ifndef EA_TRADING_SYSTEM_I_DECISION_PROVIDER_MQH
#define EA_TRADING_SYSTEM_I_DECISION_PROVIDER_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/Signal/SignalResult.mqh>
#include <EaTradingSystem/External/DecisionTypes.mqh>

enum ETesterDecisionMode
  {
   TESTER_DECISION_FAIL_SAFE=0,
   TESTER_DECISION_ALWAYS_ALLOW=1,
   TESTER_DECISION_ALWAYS_VETO=2,
   TESTER_DECISION_FIXED_ML=3,
   TESTER_DECISION_ERROR=4,
   TESTER_DECISION_TIMEOUT=5
  };

class IDecisionProvider
  {
public:
   virtual bool Initialize(const SEaConfig &config,string &error)=0;
   virtual void Shutdown(void)=0;
   virtual bool Decide(const SSignalResult &signal,SExternalDecision &decision)=0;
  };

class CDecisionPolicyRules
  {
public:
   static bool IsTesterModeValid(const int mode)
     { return mode>=TESTER_DECISION_FAIL_SAFE && mode<=TESTER_DECISION_TIMEOUT; }

   static bool IsNewCandidateProcessingAllowed(const bool emergency_stop,const bool strategy_enabled)
     { return !emergency_stop && strategy_enabled; }
  };

#endif
