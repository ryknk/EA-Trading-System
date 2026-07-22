#ifndef EA_TRADING_SYSTEM_ORDER_RESULT_MQH
#define EA_TRADING_SYSTEM_ORDER_RESULT_MQH

enum EOrderSubmissionStatus
  {
   ORDER_SUBMISSION_BLOCKED=0,
   ORDER_SUBMISSION_ACCEPTED=1,
   ORDER_SUBMISSION_ERROR=2
  };

struct SOrderResult
  {
   EOrderSubmissionStatus status;
   string                 reason_code;
   string                 reason;
   string                 trade_candidate_id;
   ulong                  order_ticket;
   ulong                  deal_ticket;
   uint                   broker_retcode;
   double                 requested_price;
   double                 confirmed_price;
   double                 requested_volume;
   double                 confirmed_volume;
   double                 slippage_points;
  };

void ResetOrderResult(SOrderResult &result)
  {
   ZeroMemory(result);
   result.status=ORDER_SUBMISSION_BLOCKED;
   result.reason_code="ORDER_NOT_SUBMITTED";
  }

#endif
