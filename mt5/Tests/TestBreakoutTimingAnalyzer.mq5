#property strict
#property script_show_inputs

#include <EaTradingSystem/Logging/BreakoutTimingAnalyzer.mqh>

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
   AssertTrue(BreakoutTimingVariantToString(BREAKOUT_TIMING_IMMEDIATE)=="IMMEDIATE","immediate variant label");
   AssertTrue(BreakoutTimingVariantToString(BREAKOUT_TIMING_CONFIRM_1_BAR)=="CONFIRM_1_BAR","confirm 1 bar variant label");
   AssertTrue(BreakoutTimingVariantToString(BREAKOUT_TIMING_CONFIRM_2_BARS)=="CONFIRM_2_BARS","confirm 2 bars variant label");
   AssertTrue(BreakoutTimingVariantToString(BREAKOUT_TIMING_CONFIRM_3_BARS)=="CONFIRM_3_BARS","confirm 3 bars variant label");

   // HoldsBreakoutはCTrendFollowingRules::IsBreakoutと同一の数式（レンジ高安値を固定して再評価する）。
   AssertTrue(CBreakoutTimingRules::HoldsBreakout(SIGNAL_DIRECTION_BUY,151.00,150.00,140.00,0.0),
              "buy holds when close remains above frozen breakout high");
   AssertTrue(!CBreakoutTimingRules::HoldsBreakout(SIGNAL_DIRECTION_BUY,149.50,150.00,140.00,0.0),
              "buy fails to hold when close falls back below frozen breakout high");
   AssertTrue(CBreakoutTimingRules::HoldsBreakout(SIGNAL_DIRECTION_SELL,139.00,150.00,140.00,0.0),
              "sell holds when close remains below frozen breakout low");
   AssertTrue(!CBreakoutTimingRules::HoldsBreakout(SIGNAL_DIRECTION_SELL,140.50,150.00,140.00,0.0),
              "sell fails to hold when close rises back above frozen breakout low");
   AssertTrue(!CBreakoutTimingRules::HoldsBreakout(SIGNAL_DIRECTION_BUY,150.05,150.00,140.00,0.10),
              "buy fails to hold when close is within the required buffer");
   AssertTrue(CBreakoutTimingRules::HoldsBreakout(SIGNAL_DIRECTION_BUY,150.20,150.00,140.00,0.10),
              "buy holds when close clears the required buffer");
   AssertTrue(!CBreakoutTimingRules::HoldsBreakout(SIGNAL_DIRECTION_NONE,151.00,150.00,140.00,0.0),
              "no direction never holds");

   if(g_failures==0)
      Print("TEST_SUITE_PASS TestBreakoutTimingAnalyzer");
   else
      PrintFormat("TEST_SUITE_FAIL TestBreakoutTimingAnalyzer failures=%d",g_failures);
  }
