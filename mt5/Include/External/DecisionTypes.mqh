#ifndef EA_TRADING_SYSTEM_DECISION_TYPES_MQH
#define EA_TRADING_SYSTEM_DECISION_TYPES_MQH

enum EExternalDecisionStatus
  {
   EXTERNAL_DECISION_ERROR=0,
   EXTERNAL_DECISION_VETO=1,
   EXTERNAL_DECISION_ALLOW=2
  };

struct SExternalDecision
  {
   EExternalDecisionStatus status;
   string request_id;
   string decision;
   string reason_code;
   string reason;
   string ml_status;
   double ml_win_probability;
   double ml_expected_return;
   string ml_model_version;
   string llm_status;
   string llm_provider;
   string llm_model;
   string llm_prompt_version;
   double llm_confidence;
   datetime created_at;
   datetime expires_at;
   datetime request_time;
   datetime response_time;
   int http_status;
  };

void ResetExternalDecision(SExternalDecision &decision)
  {
   ZeroMemory(decision);
   decision.status=EXTERNAL_DECISION_ERROR;
   decision.reason_code="EXTERNAL_NOT_EVALUATED";
  }

#endif
