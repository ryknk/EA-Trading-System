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

   AssertTrue(CBreakevenStopRules::ShouldMoveToBreakeven(POSITION_TYPE_BUY,150.00,149.00,151.00,151.02,1.0),
              "buy triggers at exactly 1R profit");
   AssertTrue(!CBreakevenStopRules::ShouldMoveToBreakeven(POSITION_TYPE_BUY,150.00,149.00,150.99,151.01,1.0),
              "buy below 1R profit does not trigger");
   AssertTrue(CBreakevenStopRules::ShouldMoveToBreakeven(POSITION_TYPE_SELL,150.00,151.00,148.98,149.00,1.0),
              "sell triggers at exactly 1R profit");
   AssertTrue(!CBreakevenStopRules::ShouldMoveToBreakeven(POSITION_TYPE_SELL,150.00,151.00,148.99,149.01,1.0),
              "sell below 1R profit does not trigger");
   AssertTrue(CBreakevenStopRules::ShouldMoveToBreakeven(POSITION_TYPE_BUY,150.00,149.00,150.50,150.52,0.5),
              "lower trigger multiple (0.5R) fires earlier");
   AssertTrue(!CBreakevenStopRules::ShouldMoveToBreakeven(POSITION_TYPE_BUY,150.00,150.00,152.00,152.02,1.0),
              "sl already at breakeven is not re-triggered");
   AssertTrue(!CBreakevenStopRules::ShouldMoveToBreakeven(POSITION_TYPE_BUY,150.00,150.50,152.00,152.02,1.0),
              "sl already beyond breakeven is not re-triggered");
   AssertTrue(!CBreakevenStopRules::ShouldMoveToBreakeven(POSITION_TYPE_BUY,150.00,149.00,151.00,151.02,0.0),
              "zero trigger multiple never fires");
   AssertTrue(!CBreakevenStopRules::ShouldMoveToBreakeven(POSITION_TYPE_BUY,150.00,0.0,151.00,151.02,1.0),
              "missing stop loss never fires");

   AssertTrue(CTimeStopRules::HasExceededMaxHoldingBars(20,20),"time stop fires at exactly max holding bars");
   AssertTrue(CTimeStopRules::HasExceededMaxHoldingBars(21,20),"time stop fires beyond max holding bars");
   AssertTrue(!CTimeStopRules::HasExceededMaxHoldingBars(19,20),"time stop does not fire before max holding bars");
   AssertTrue(!CTimeStopRules::HasExceededMaxHoldingBars(20,0),"zero max holding bars never fires");
   AssertTrue(!CTimeStopRules::HasExceededMaxHoldingBars(20,-1),"negative max holding bars never fires");

   AssertTrue(CTimeStopRules::HasReachedMinMfeR(POSITION_TYPE_BUY,150.00,149.00,150.50,0.5),
              "buy reaches exactly 0.5R peak favorable excursion");
   AssertTrue(!CTimeStopRules::HasReachedMinMfeR(POSITION_TYPE_BUY,150.00,149.00,150.49,0.5),
              "buy below 0.5R peak favorable excursion does not reach threshold");
   AssertTrue(CTimeStopRules::HasReachedMinMfeR(POSITION_TYPE_SELL,150.00,151.00,149.50,0.5),
              "sell reaches exactly 0.5R peak favorable excursion");
   AssertTrue(!CTimeStopRules::HasReachedMinMfeR(POSITION_TYPE_SELL,150.00,151.00,149.51,0.5),
              "sell below 0.5R peak favorable excursion does not reach threshold");
   AssertTrue(!CTimeStopRules::HasReachedMinMfeR(POSITION_TYPE_BUY,150.00,149.00,150.50,0.0),
              "zero min r multiple never reaches threshold");
   AssertTrue(!CTimeStopRules::HasReachedMinMfeR(POSITION_TYPE_BUY,150.00,0.0,150.50,0.5),
              "missing initial stop loss never reaches threshold");
   AssertTrue(!CTimeStopRules::HasReachedMinMfeR(POSITION_TYPE_BUY,150.00,150.00,150.50,0.5),
              "zero risk distance never reaches threshold");

   if(g_failures==0) Print("TEST_SUITE_PASS TestTradingRules");
   else PrintFormat("TEST_SUITE_FAIL TestTradingRules failures=%d",g_failures);
  }
