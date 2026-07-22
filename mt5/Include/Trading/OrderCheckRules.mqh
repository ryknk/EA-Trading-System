#ifndef EA_TRADING_SYSTEM_ORDER_CHECK_RULES_MQH
#define EA_TRADING_SYSTEM_ORDER_CHECK_RULES_MQH

class COrderCheckRules
  {
public:
   static bool IsAccepted(const bool function_result,const uint retcode)
     {
      // OrderCheck success is indicated by its bool return. The documented
      // successful check result may retain retcode=0 (comment "Done").
      return function_result && (retcode==0 || retcode==TRADE_RETCODE_DONE);
     }
  };

#endif
