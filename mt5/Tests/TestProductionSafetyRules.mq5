#property strict

#include <EaTradingSystem/External/MockDecisionProvider.mqh>

int g_failures=0;
void AssertTrue(const bool condition,const string name)
  {
   if(condition) PrintFormat("PASS %s",name);
   else { PrintFormat("FAIL %s",name); g_failures++; }
  }

void OnStart(void)
  {
   AssertTrue(!CDecisionPolicyRules::IsNewCandidateProcessingAllowed(true,true),"emergency stop blocks candidates");
   AssertTrue(!CDecisionPolicyRules::IsNewCandidateProcessingAllowed(false,false),"strategy stop blocks candidates");
   AssertTrue(CDecisionPolicyRules::IsNewCandidateProcessingAllowed(false,true),"enabled strategy accepts candidates");

   SEaConfig config;
   SetDefaultConfig(config);
   config.tester_decision_mode=TESTER_DECISION_ALWAYS_ALLOW;
   CMockDecisionProvider provider;
   string error;
   AssertTrue(provider.Initialize(config,error),"mock provider initialized");
   SSignalResult signal;
   SExternalDecision decision;
   AssertTrue(provider.Decide(signal,decision) && decision.status==EXTERNAL_DECISION_ALLOW,"mock always allow");
   provider.Shutdown();

   config.tester_decision_mode=TESTER_DECISION_ALWAYS_VETO;
   AssertTrue(provider.Initialize(config,error),"mock veto initialized");
   AssertTrue(provider.Decide(signal,decision) && decision.status==EXTERNAL_DECISION_VETO,"mock always veto");
   provider.Shutdown();

   config.tester_decision_mode=TESTER_DECISION_FIXED_ML;
   config.tester_fixed_ml_probability=0.55;
   AssertTrue(provider.Initialize(config,error),"mock fixed ml initialized");
   AssertTrue(provider.Decide(signal,decision) && decision.status==EXTERNAL_DECISION_VETO,"mock probability threshold veto");
   provider.Shutdown();

   config.tester_decision_mode=TESTER_DECISION_ERROR;
   AssertTrue(provider.Initialize(config,error),"mock error initialized");
   AssertTrue(!provider.Decide(signal,decision) && decision.status==EXTERNAL_DECISION_ERROR,"mock error fails closed");
   provider.Shutdown();

   config.tester_decision_mode=TESTER_DECISION_TIMEOUT;
   AssertTrue(provider.Initialize(config,error),"mock timeout initialized");
   AssertTrue(provider.Decide(signal,decision) && decision.status==EXTERNAL_DECISION_VETO,"mock timeout fails closed");

   if(g_failures==0) Print("TEST_SUITE_PASS TestProductionSafetyRules");
   else PrintFormat("TEST_SUITE_FAIL TestProductionSafetyRules failures=%d",g_failures);
  }
