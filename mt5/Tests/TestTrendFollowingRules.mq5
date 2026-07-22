#property strict
#property script_show_inputs

#include <EaTradingSystem/Strategy/TrendFollowingRules.mqh>

int g_failures=0;

void AssertTrue(const bool condition,const string test_name)
  {
   if(condition)
      PrintFormat("PASS %s",test_name);
   else
     {
      PrintFormat("FAIL %s",test_name);
      g_failures++;
     }
  }

void OnStart(void)
  {
   AssertTrue(CTrendFollowingRules::TrendDirection(1.20,1.10,1.15,1.05)==SIGNAL_DIRECTION_BUY,
              "aligned bullish trend");
   AssertTrue(CTrendFollowingRules::TrendDirection(1.00,1.10,1.05,1.15)==SIGNAL_DIRECTION_SELL,
              "aligned bearish trend");
   AssertTrue(CTrendFollowingRules::TrendDirection(1.20,1.10,1.05,1.15)==SIGNAL_DIRECTION_NONE,
              "mixed trend rejected");
   AssertTrue(CTrendFollowingRules::MomentumAllowed(SIGNAL_DIRECTION_BUY,60.0,50.0,75.0,25.0,50.0),
              "buy RSI accepted");
   AssertTrue(!CTrendFollowingRules::MomentumAllowed(SIGNAL_DIRECTION_BUY,80.0,50.0,75.0,25.0,50.0),
              "overextended buy RSI rejected");
   AssertTrue(CTrendFollowingRules::IsBreakout(SIGNAL_DIRECTION_BUY,1.2010,1.2000,1.1800,0.0001),
              "buy breakout accepted");
   AssertTrue(!CTrendFollowingRules::IsBreakout(SIGNAL_DIRECTION_BUY,1.2000,1.2000,1.1800,0.0),
              "buy breakout boundary is strict");
   AssertTrue(CTrendFollowingRules::IsBreakout(SIGNAL_DIRECTION_SELL,1.1790,1.2000,1.1800,0.0001),
              "sell breakout accepted");
   AssertTrue(CTrendFollowingRules::IsPullback(SIGNAL_DIRECTION_BUY,1.1010,1.1060,1.0990,1.1050,1.1000,0.0100,0.25),
              "buy pullback accepted");
   AssertTrue(CTrendFollowingRules::IsPullback(SIGNAL_DIRECTION_SELL,1.0990,1.1010,1.0940,1.0950,1.1000,0.0100,0.25),
              "sell pullback accepted");
   AssertTrue(!CTrendFollowingRules::IsPullback(SIGNAL_DIRECTION_NONE,1.0,1.1,0.9,1.0,1.0,0.1,0.25),
              "no direction rejected");

   if(g_failures==0)
      Print("TEST_SUITE_PASS TestTrendFollowingRules");
   else
      PrintFormat("TEST_SUITE_FAIL TestTrendFollowingRules failures=%d",g_failures);
  }
