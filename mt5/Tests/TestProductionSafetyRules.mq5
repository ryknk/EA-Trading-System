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

   AssertTrue(!CStrategyModeRules::IsMeanReversionModeActive(STRATEGY_MODE_TREND_ONLY),
              "TrendOnly does not activate mean reversion");
   AssertTrue(CStrategyModeRules::IsMeanReversionModeActive(STRATEGY_MODE_MEAN_REVERSION_ONLY),
              "MeanReversionOnly activates mean reversion");
   AssertTrue(CStrategyModeRules::IsMeanReversionModeActive(STRATEGY_MODE_COMBINED),
              "Combined activates mean reversion");
   AssertTrue(!CStrategyModeRules::ShouldDiscardTrendCandidate(STRATEGY_MODE_TREND_ONLY),
              "TrendOnly keeps trend candidates");
   AssertTrue(!CStrategyModeRules::ShouldDiscardTrendCandidate(STRATEGY_MODE_COMBINED),
              "Combined keeps trend candidates");
   AssertTrue(CStrategyModeRules::ShouldDiscardTrendCandidate(STRATEGY_MODE_MEAN_REVERSION_ONLY),
              "MeanReversionOnly discards trend candidates");

   SEaConfig mode_config;
   SetDefaultConfig(mode_config);
   string mode_error;
   AssertTrue(ValidateConfig(mode_config,mode_error),"default config (TrendOnly) validates");
   mode_config.strategy_mode=STRATEGY_MODE_MEAN_REVERSION_ONLY;
   AssertTrue(!ValidateConfig(mode_config,mode_error) && mode_error=="STRATEGY_MODE_REQUIRES_MEAN_REVERSION_ENABLED",
              "MeanReversionOnly without enable_mean_reversion_strategy is rejected");
   mode_config.enable_mean_reversion_strategy=true;
   AssertTrue(ValidateConfig(mode_config,mode_error),"MeanReversionOnly with mean reversion enabled validates");
   mode_config.strategy_mode=STRATEGY_MODE_COMBINED;
   AssertTrue(ValidateConfig(mode_config,mode_error),"Combined with mean reversion enabled validates");
   mode_config.strategy_mode=99;
   AssertTrue(!ValidateConfig(mode_config,mode_error) && mode_error=="INVALID_STRATEGY_MODE",
              "out-of-range strategy_mode is rejected");

   if(g_failures==0) Print("TEST_SUITE_PASS TestProductionSafetyRules");
   else PrintFormat("TEST_SUITE_FAIL TestProductionSafetyRules failures=%d",g_failures);
  }
