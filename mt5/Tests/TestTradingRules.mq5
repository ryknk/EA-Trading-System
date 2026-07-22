#property strict

#include <EaTradingSystem/Trading/OrderManager.mqh>
#include <EaTradingSystem/Trading/OrderCheckRules.mqh>
#include <EaTradingSystem/Trading/PositionManager.mqh>

int g_failures=0;

void AssertTrue(const bool condition,const string name)
  {
   if(condition) PrintFormat("PASS %s",name);
   else { PrintFormat("FAIL %s",name); g_failures++; }
  }

void OnStart(void)
  {
   AssertTrue(COrderCheckRules::IsAccepted(true,0),"OrderCheck bool success accepts documented retcode zero");
   AssertTrue(COrderCheckRules::IsAccepted(true,TRADE_RETCODE_DONE),"OrderCheck completed retcode accepted");
   AssertTrue(!COrderCheckRules::IsAccepted(false,0),"OrderCheck function failure rejected");
   AssertTrue(COrderValidationRules::ApprovalChainValid(true,true,SIGNAL_STATUS_CANDIDATE,
                                                        RISK_DECISION_APPROVED,0.10),
              "complete approval chain accepted");
   AssertTrue(!COrderValidationRules::ApprovalChainValid(false,true,SIGNAL_STATUS_CANDIDATE,
                                                         RISK_DECISION_APPROVED,0.10),
              "disabled mutations block order");
   AssertTrue(!COrderValidationRules::ApprovalChainValid(true,false,SIGNAL_STATUS_CANDIDATE,
                                                         RISK_DECISION_APPROVED,0.10),
              "missing external approval blocks order");
   AssertTrue(!COrderValidationRules::ApprovalChainValid(true,true,SIGNAL_STATUS_CANDIDATE,
                                                         RISK_DECISION_REJECTED,0.10),
              "risk rejection blocks order");
   AssertTrue(!COrderValidationRules::ApprovalChainValid(true,true,SIGNAL_STATUS_NONE,
                                                         RISK_DECISION_APPROVED,0.10),
              "missing signal blocks order");
   AssertTrue(!COrderValidationRules::ApprovalChainValid(true,true,SIGNAL_STATUS_CANDIDATE,
                                                         RISK_DECISION_APPROVED,0.0),
              "zero volume blocks order");

   AssertTrue(COrderValidationRules::AcceptedRetcode(TRADE_RETCODE_DONE),"done retcode accepted");
   AssertTrue(COrderValidationRules::AcceptedRetcode(TRADE_RETCODE_PLACED),"placed retcode accepted");
   AssertTrue(COrderValidationRules::AcceptedRetcode(TRADE_RETCODE_DONE_PARTIAL),"partial retcode accepted");
   AssertTrue(!COrderValidationRules::AcceptedRetcode(TRADE_RETCODE_REJECT),"broker rejection not accepted");

   AssertTrue(CPositionProtectionRules::HasValidProtectiveStop(POSITION_TYPE_BUY,150.00,150.02,149.00),
              "buy protective stop valid");
   AssertTrue(!CPositionProtectionRules::HasValidProtectiveStop(POSITION_TYPE_BUY,150.00,150.02,0.0),
              "missing buy stop rejected");
   AssertTrue(!CPositionProtectionRules::HasValidProtectiveStop(POSITION_TYPE_BUY,150.00,150.02,150.01),
              "buy stop beyond market rejected");
   AssertTrue(CPositionProtectionRules::HasValidProtectiveStop(POSITION_TYPE_SELL,150.00,150.02,151.00),
              "sell protective stop valid");
   AssertTrue(!CPositionProtectionRules::HasValidProtectiveStop(POSITION_TYPE_SELL,150.00,150.02,149.00),
              "sell stop below market rejected");
   AssertTrue(!CPositionProtectionRules::HasValidProtectiveStop(POSITION_TYPE_BUY,150.02,150.00,149.00),
              "crossed quote rejected");
   AssertTrue(CPositionProtectionRules::IsManagedPosition(26072001,26072001),"matching magic managed");
   AssertTrue(!CPositionProtectionRules::IsManagedPosition(0,26072001),"manual position not managed");

   if(g_failures==0) Print("TEST_SUITE_PASS TestTradingRules");
   else PrintFormat("TEST_SUITE_FAIL TestTradingRules failures=%d",g_failures);
  }
