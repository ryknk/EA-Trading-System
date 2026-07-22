#property strict

#include <EaTradingSystem/Risk/DailyLossGuard.mqh>
#include <EaTradingSystem/Risk/DrawdownGuard.mqh>
#include <EaTradingSystem/Filter/SpreadFilter.mqh>
#include <EaTradingSystem/Risk/ExposureGuard.mqh>

int g_failures=0;

void AssertTrue(const bool condition,const string name)
  {
   if(condition) PrintFormat("PASS %s",name);
   else { PrintFormat("FAIL %s",name); g_failures++; }
  }

void AssertNear(const double actual,const double expected,const double tolerance,const string name)
  {
   AssertTrue(MathAbs(actual-expected)<=tolerance,name);
  }

void OnStart(void)
  {
   AssertNear(CDailyLossGuard::LossRate(1000000.0,985000.0),0.015,1.0e-12,"daily loss rate");
   AssertNear(CDailyLossGuard::LossRate(1000000.0,1000000.0),0.0,1.0e-12,"daily loss zero");
   AssertTrue(!CDailyLossGuard::IsBreached(1000000.0,980001.0,0.02),"daily loss below boundary");
   AssertTrue(CDailyLossGuard::IsBreached(1000000.0,980000.0,0.02),"daily loss boundary breached");
   AssertTrue(CDailyLossGuard::IsBreached(1000000.0,979999.0,0.02),"daily loss above boundary breached");
   AssertTrue(CDailyLossGuard::IsBreached(0.0,980000.0,0.02),"invalid daily state fails closed");
   AssertTrue(CDailyLossGuard::NextLocked(true,false),"daily lock remains sticky until broker day reset");
   AssertTrue(!CDailyLossGuard::NextLocked(false,false),"daily unlocked state remains open below limit");
   AssertTrue(CDailyLossGuard::ServerDayStart(D'2026.07.21 23:59:59')!=
              CDailyLossGuard::ServerDayStart(D'2026.07.22 00:00:00'),"broker server date change detected");

   AssertNear(CDrawdownGuard::DrawdownRate(1100000.0,990000.0),0.10,1.0e-12,"drawdown rate");
   AssertNear(CDrawdownGuard::DrawdownRate(1100000.0,1100000.0),0.0,1.0e-12,"drawdown zero");
   AssertTrue(!CDrawdownGuard::IsBreached(1100000.0,990001.0,0.10),"drawdown below boundary");
   AssertTrue(CDrawdownGuard::IsBreached(1100000.0,990000.0,0.10),"drawdown boundary breached");
   AssertTrue(CDrawdownGuard::IsBreached(1100000.0,989999.0,0.10),"drawdown above boundary breached");
   AssertTrue(CDrawdownGuard::IsBreached(0.0,990000.0,0.10),"invalid drawdown state fails closed");
   AssertTrue(CDrawdownGuard::NextLocked(true,false),"drawdown lock has no automatic recovery");

   AssertTrue(CSpreadFilter::IsAllowed(150.000,150.010,0.001,20.0),"normal spread allowed");
   AssertTrue(CSpreadFilter::IsAllowed(150.000,150.019,0.001,20.0),"spread immediately below boundary allowed");
   AssertTrue(CSpreadFilter::IsAllowed(150.000,150.020,0.001,20.0),"spread boundary allowed");
   AssertTrue(!CSpreadFilter::IsAllowed(150.000,150.021,0.001,20.0),"wide spread rejected");
   AssertTrue(!CSpreadFilter::IsAllowed(150.020,150.000,0.001,20.0),"crossed quote rejected");
   AssertTrue(!CSpreadFilter::IsAllowed(150.000,150.020,0.0,20.0),"invalid point rejected");
   AssertTrue(!CSpreadFilter::IsAllowed(0.0,150.020,0.001,20.0),"missing bid rejected");
   AssertTrue(!CSpreadFilter::IsAllowed(150.000,0.0,0.001,20.0),"missing ask rejected");

   AssertTrue(CExposureGuard::IsPositionCountAllowed(0,2),"no position allowed");
   AssertTrue(CExposureGuard::IsPositionCountAllowed(1,2),"below maximum allowed");
   AssertTrue(!CExposureGuard::IsPositionCountAllowed(2,2),"at maximum rejected");
   AssertTrue(!CExposureGuard::IsPositionCountAllowed(3,2),"above maximum rejected");
   AssertTrue(CExposureGuard::IsSymbolAdditionAllowed(false),"different symbol allowed");
   AssertTrue(!CExposureGuard::IsSymbolAdditionAllowed(true),"same symbol duplicate rejected for buy or sell");

   if(g_failures==0) Print("TEST_SUITE_PASS TestRiskGuards");
   else PrintFormat("TEST_SUITE_FAIL TestRiskGuards failures=%d",g_failures);
  }
