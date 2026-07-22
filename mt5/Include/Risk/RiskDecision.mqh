#ifndef EA_TRADING_SYSTEM_RISK_DECISION_MQH
#define EA_TRADING_SYSTEM_RISK_DECISION_MQH

enum ERiskDecisionStatus
  {
   RISK_DECISION_REJECTED=0,
   RISK_DECISION_APPROVED=1
  };

struct SRiskDecision
  {
   ERiskDecisionStatus status;
   string reason_code;
   string reason;
   double volume;
   double risk_budget;
   double estimated_stop_loss;
   double required_margin;
   double daily_loss_rate;
   double drawdown_rate;
  };

void ResetRiskDecision(SRiskDecision &decision)
  {
   ZeroMemory(decision);
   decision.status=RISK_DECISION_REJECTED;
   decision.reason_code="RISK_NOT_EVALUATED";
  }

#endif
