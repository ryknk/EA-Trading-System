#property strict

#include <EaTradingSystem/Logging/TradeLogger.mqh>

int g_failures=0;

void AssertTrue(const bool condition,const string name)
  {
   if(condition) PrintFormat("PASS %s",name);
   else { PrintFormat("FAIL %s",name); g_failures++; }
  }

void OnStart(void)
  {
   AssertTrue(CTradeLogRules::SafeCorrelationId("trend-ea-v1-EURUSD-1780000000"),
              "candidate correlation id accepted");
   AssertTrue(CTradeLogRules::SafeCorrelationId("",true),"empty optional request id accepted");
   AssertTrue(!CTradeLogRules::SafeCorrelationId("",false),"empty candidate id rejected");
   AssertTrue(!CTradeLogRules::SafeCorrelationId("candidate/id"),"unsafe correlation id rejected");
   AssertTrue(!CTradeLogRules::SafeCorrelationId("candidate\nforged"),"log injection rejected");
   AssertTrue(CTradeLogRules::SafeEventType("TRADE_CLOSED"),"known event type accepted");
   AssertTrue(!CTradeLogRules::SafeEventType("BUY"),"unknown event type rejected");
   AssertTrue(CTradeLogRules::SafeEventType("BREAKOUT_TIMING_SETUP"),"breakout timing setup event type accepted");
   AssertTrue(CTradeLogRules::SafeEventType("BREAKOUT_TIMING_TRADE"),"breakout timing trade event type accepted");

   ResetLastError();
   if(g_failures==0) Print("TEST_SUITE_PASS TestAuditRules");
   else PrintFormat("TEST_SUITE_FAIL TestAuditRules failures=%d",g_failures);
  }
