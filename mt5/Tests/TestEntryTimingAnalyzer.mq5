#property strict
#property script_show_inputs

#include <EaTradingSystem/Logging/EntryTimingAnalyzer.mqh>

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

void AssertNear(const double actual,const double expected,const double tolerance,const string test_name)
  {
   AssertTrue(MathAbs(actual-expected)<=tolerance,
             StringFormat("%s (actual=%.6f expected=%.6f)",test_name,actual,expected));
  }

void OnStart(void)
  {
   AssertTrue(CEntryTimingRules::CheckpointCount()==6,"checkpoint count is 6");
   AssertTrue(CEntryTimingRules::CheckpointBars(0)==1,"checkpoint 0 is 1 bar");
   AssertTrue(CEntryTimingRules::CheckpointBars(1)==2,"checkpoint 1 is 2 bars");
   AssertTrue(CEntryTimingRules::CheckpointBars(2)==3,"checkpoint 2 is 3 bars");
   AssertTrue(CEntryTimingRules::CheckpointBars(3)==5,"checkpoint 3 is 5 bars");
   AssertTrue(CEntryTimingRules::CheckpointBars(4)==10,"checkpoint 4 is 10 bars");
   AssertTrue(CEntryTimingRules::CheckpointBars(5)==20,"checkpoint 5 is 20 bars");
   AssertTrue(CEntryTimingRules::CheckpointBars(6)==0,"out-of-range checkpoint index returns 0");
   AssertTrue(CEntryTimingRules::CheckpointBars(-1)==0,"negative checkpoint index returns 0");

   AssertNear(CEntryTimingRules::StopDistance(0.0100,2.0),0.0200,1e-9,"stop distance is atr times multiple");
   AssertTrue(CEntryTimingRules::StopDistance(0.0,2.0)==0.0,"zero atr yields zero stop distance");
   AssertTrue(CEntryTimingRules::StopDistance(0.0100,0.0)==0.0,"zero multiple yields zero stop distance");

   AssertNear(CEntryTimingRules::ComputeStopLoss(SIGNAL_DIRECTION_BUY,150.00,0.50),149.50,1e-9,"buy stop loss below entry");
   AssertNear(CEntryTimingRules::ComputeStopLoss(SIGNAL_DIRECTION_SELL,150.00,0.50),150.50,1e-9,"sell stop loss above entry");
   AssertNear(CEntryTimingRules::ComputeTakeProfit(SIGNAL_DIRECTION_BUY,150.00,0.50,2.0),151.00,1e-9,"buy take profit at 2R");
   AssertNear(CEntryTimingRules::ComputeTakeProfit(SIGNAL_DIRECTION_SELL,150.00,0.50,2.0),149.00,1e-9,"sell take profit at 2R");

   AssertNear(CEntryTimingRules::PriceToR(SIGNAL_DIRECTION_BUY,150.00,150.50,0.50),1.0,1e-9,"buy 1R favorable move");
   AssertNear(CEntryTimingRules::PriceToR(SIGNAL_DIRECTION_BUY,150.00,149.50,0.50),-1.0,1e-9,"buy 1R adverse move");
   AssertNear(CEntryTimingRules::PriceToR(SIGNAL_DIRECTION_SELL,150.00,149.50,0.50),1.0,1e-9,"sell 1R favorable move");
   AssertNear(CEntryTimingRules::PriceToR(SIGNAL_DIRECTION_SELL,150.00,150.50,0.50),-1.0,1e-9,"sell 1R adverse move");
   AssertTrue(CEntryTimingRules::PriceToR(SIGNAL_DIRECTION_BUY,150.00,150.50,0.0)==0.0,"zero stop distance yields zero R");

   AssertTrue(CEntryTimingRules::IsStopLossHit(SIGNAL_DIRECTION_BUY,149.50,149.50,149.52),"buy sl hit at bid==sl");
   AssertTrue(CEntryTimingRules::IsStopLossHit(SIGNAL_DIRECTION_BUY,149.50,149.40,149.42),"buy sl hit below sl");
   AssertTrue(!CEntryTimingRules::IsStopLossHit(SIGNAL_DIRECTION_BUY,149.50,149.60,149.62),"buy sl not hit above sl");
   AssertTrue(CEntryTimingRules::IsStopLossHit(SIGNAL_DIRECTION_SELL,150.50,150.48,150.50),"sell sl hit at ask==sl");
   AssertTrue(!CEntryTimingRules::IsStopLossHit(SIGNAL_DIRECTION_SELL,150.50,150.38,150.40),"sell sl not hit below sl");
   AssertTrue(!CEntryTimingRules::IsStopLossHit(SIGNAL_DIRECTION_BUY,0.0,149.40,149.42),"missing sl never hits");

   AssertTrue(CEntryTimingRules::IsTakeProfitHit(SIGNAL_DIRECTION_BUY,151.00,151.00,151.02),"buy tp hit at bid==tp");
   AssertTrue(!CEntryTimingRules::IsTakeProfitHit(SIGNAL_DIRECTION_BUY,151.00,150.90,150.92),"buy tp not hit below tp");
   AssertTrue(CEntryTimingRules::IsTakeProfitHit(SIGNAL_DIRECTION_SELL,149.00,148.98,149.00),"sell tp hit at ask==tp");
   AssertTrue(!CEntryTimingRules::IsTakeProfitHit(SIGNAL_DIRECTION_SELL,149.00,149.08,149.10),"sell tp not hit above tp");

     {
      double favorable=150.00,adverse=150.00;
      CEntryTimingRules::UpdateExcursion(SIGNAL_DIRECTION_BUY,150.50,favorable,adverse);
      CEntryTimingRules::UpdateExcursion(SIGNAL_DIRECTION_BUY,149.80,favorable,adverse);
      CEntryTimingRules::UpdateExcursion(SIGNAL_DIRECTION_BUY,150.20,favorable,adverse);
      AssertNear(favorable,150.50,1e-9,"buy favorable extreme tracks highest price");
      AssertNear(adverse,149.80,1e-9,"buy adverse extreme tracks lowest price");
     }
     {
      double favorable=150.00,adverse=150.00;
      CEntryTimingRules::UpdateExcursion(SIGNAL_DIRECTION_SELL,149.50,favorable,adverse);
      CEntryTimingRules::UpdateExcursion(SIGNAL_DIRECTION_SELL,150.30,favorable,adverse);
      CEntryTimingRules::UpdateExcursion(SIGNAL_DIRECTION_SELL,149.90,favorable,adverse);
      AssertNear(favorable,149.50,1e-9,"sell favorable extreme tracks lowest price");
      AssertNear(adverse,150.30,1e-9,"sell adverse extreme tracks highest price");
     }

   AssertTrue(EntryTimingVariantToString(ENTRY_TIMING_IMMEDIATE)=="IMMEDIATE","immediate variant label");
   AssertTrue(EntryTimingVariantToString(ENTRY_TIMING_WAIT_1_BAR)=="WAIT_1_BAR","wait 1 bar variant label");
   AssertTrue(EntryTimingVariantToString(ENTRY_TIMING_WAIT_2_BARS)=="WAIT_2_BARS","wait 2 bars variant label");
   AssertTrue(EntryTimingVariantToString(ENTRY_TIMING_WAIT_TRIGGER)=="WAIT_TRIGGER","wait trigger variant label");

   if(g_failures==0)
      Print("TEST_SUITE_PASS TestEntryTimingAnalyzer");
   else
      PrintFormat("TEST_SUITE_FAIL TestEntryTimingAnalyzer failures=%d",g_failures);
  }
