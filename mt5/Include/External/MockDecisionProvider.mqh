#ifndef EA_TRADING_SYSTEM_MOCK_DECISION_PROVIDER_MQH
#define EA_TRADING_SYSTEM_MOCK_DECISION_PROVIDER_MQH

#include <EaTradingSystem/External/IDecisionProvider.mqh>

class CMockDecisionProvider : public IDecisionProvider
  {
private:
   SEaConfig m_config;
   bool      m_initialized;

   void Populate(SExternalDecision &decision)
     {
      decision.request_id="00000000-0000-4000-8000-000000000001";
      decision.request_time=TimeGMT();
      decision.response_time=decision.request_time;
      decision.created_at=decision.request_time;
      decision.expires_at=decision.request_time+60;
      decision.ml_model_version="mock-v1";
      decision.llm_provider="mock";
      decision.llm_model="mock";
      decision.llm_prompt_version="mock-v1";
      decision.llm_confidence=1.0;
     }

public:
   CMockDecisionProvider(void) { m_initialized=false; }

   virtual bool Initialize(const SEaConfig &config,string &error)
     {
      error="";
      m_initialized=false;
      if(!CDecisionPolicyRules::IsTesterModeValid(config.tester_decision_mode))
        { error="INVALID_TESTER_DECISION_MODE"; return false; }
      if(config.tester_fixed_ml_probability<0.0 || config.tester_fixed_ml_probability>1.0)
        { error="INVALID_TESTER_ML_PROBABILITY"; return false; }
      m_config=config;
      m_initialized=true;
      return true;
     }

   virtual void Shutdown(void) { m_initialized=false; }

   virtual bool Decide(const SSignalResult &signal,SExternalDecision &decision)
     {
      ResetExternalDecision(decision);
      Populate(decision);
      if(!m_initialized)
        { decision.reason_code="MOCK_NOT_INITIALIZED"; return false; }
      if(m_config.tester_decision_mode==TESTER_DECISION_ERROR)
        { decision.reason_code="MOCK_ERROR"; decision.reason="Injected provider error."; return false; }
      if(m_config.tester_decision_mode==TESTER_DECISION_TIMEOUT)
        { decision.status=EXTERNAL_DECISION_VETO; decision.reason_code="MOCK_TIMEOUT"; decision.reason="Injected timeout; fail-safe veto."; return true; }
      if(m_config.tester_decision_mode==TESTER_DECISION_ALWAYS_VETO ||
         m_config.tester_decision_mode==TESTER_DECISION_FAIL_SAFE)
        { decision.status=EXTERNAL_DECISION_VETO; decision.reason_code="MOCK_VETO"; decision.reason="Injected veto."; return true; }

      decision.ml_win_probability=(m_config.tester_decision_mode==TESTER_DECISION_FIXED_ML ?
                                   m_config.tester_fixed_ml_probability : 1.0);
      decision.ml_expected_return=0.01;
      if(decision.ml_win_probability+1.0e-12<m_config.ml_min_win_probability)
        {
         decision.status=EXTERNAL_DECISION_VETO;
         decision.decision="VETO";
         decision.ml_status="REJECTED";
         decision.llm_status="SKIPPED";
         decision.reason_code="MOCK_ML_THRESHOLD";
         decision.reason="Fixed ML probability is below threshold.";
         return true;
        }
      decision.status=EXTERNAL_DECISION_ALLOW;
      decision.decision="ALLOW";
      decision.ml_status="PASSED";
      decision.llm_status="ALLOW";
      decision.reason_code="MOCK_ALLOW";
      decision.reason="Injected allow.";
      return true;
     }
  };

#endif
