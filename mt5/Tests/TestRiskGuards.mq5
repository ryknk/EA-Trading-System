#property strict

#include <EaTradingSystem/Risk/DailyLossGuard.mqh>
#include <EaTradingSystem/Risk/DrawdownGuard.mqh>
#include <EaTradingSystem/Filter/SpreadFilter.mqh>
#include <EaTradingSystem/Risk/ExposureGuard.mqh>
#include <EaTradingSystem/Risk/OpenRiskGuard.mqh>
#include <EaTradingSystem/Risk/AdaptiveSizingGuard.mqh>

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

   AssertTrue(CExposureGuard::IsSameDirectionAdditionAllowed(0,1),"no same-direction position allowed under default limit");
   AssertTrue(!CExposureGuard::IsSameDirectionAdditionAllowed(1,1),"same-direction addition rejected at default limit of one");
   AssertTrue(CExposureGuard::IsSameDirectionAdditionAllowed(1,3),"same-direction addition allowed below configured limit");
   AssertTrue(!CExposureGuard::IsSameDirectionAdditionAllowed(3,3),"same-direction addition rejected at configured limit");
   AssertTrue(!CExposureGuard::IsSameDirectionAdditionAllowed(4,3),"same-direction addition rejected above configured limit");

   AssertTrue(!CExposureGuard::IsOppositeDirectionBlocking(false),"opposite direction absent does not block");
   AssertTrue(CExposureGuard::IsOppositeDirectionBlocking(true),"opposite direction position always blocks addition");

   AssertTrue(CExposureGuard::IsEntryDistanceSufficient(150.500,150.000,0.0,0.001),"min entry distance disabled by default allows any distance");
   AssertTrue(CExposureGuard::IsEntryDistanceSufficient(150.500,150.000,500.0,0.001),"entry distance at boundary allowed");
   AssertTrue(!CExposureGuard::IsEntryDistanceSufficient(150.300,150.000,500.0,0.001),"entry distance below configured minimum rejected");
   AssertTrue(!CExposureGuard::IsEntryDistanceSufficient(150.500,150.000,500.0,0.0),"entry distance check fails closed without a valid point size");

   AssertTrue(CExposureGuard::EffectiveMaxSameDirection(5,ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)==5,
              "configured same-direction limit honored on hedging accounts");
   AssertTrue(CExposureGuard::EffectiveMaxSameDirection(5,ACCOUNT_MARGIN_MODE_RETAIL_NETTING)==1,
              "same-direction limit forced to one on netting accounts");

   // equity 1,000,000 * rate 0.02 = 20,000 が上限。
   AssertTrue(COpenRiskGuardRules::IsWithinLimit(0.0,20000.0,1000000.0,0.02),"open risk at boundary allowed");
   AssertTrue(!COpenRiskGuardRules::IsWithinLimit(0.0,20000.02,1000000.0,0.02),"open risk above boundary rejected");
   AssertTrue(COpenRiskGuardRules::IsWithinLimit(15000.0,5000.0,1000000.0,0.02),"existing plus candidate risk at boundary allowed");
   AssertTrue(!COpenRiskGuardRules::IsWithinLimit(15000.02,5000.0,1000000.0,0.02),"existing plus candidate risk above boundary rejected");
   AssertTrue(!COpenRiskGuardRules::IsWithinLimit(-1.0,5000.0,1000000.0,0.02),"negative existing risk fails closed");
   AssertTrue(!COpenRiskGuardRules::IsWithinLimit(0.0,5000.0,0.0,0.02),"zero equity fails closed");

   {
      // OrderCalcProfitへ到達する前にfalse-safeで弾かれる入力検証のみを対象とする
      // （実際の損益計算はTestPositionSizerと同様、Terminal/Strategy Tester文脈依存のため単体テスト対象外）。
      double risk_amount=0.0;
      AssertTrue(!COpenRiskGuardRules::PositionRiskAmount("USDJPY",POSITION_TYPE_BUY,1.0,150.000,0.0,risk_amount),
                 "position without a stop loss is treated as risk-uncalculable");
      AssertTrue(!COpenRiskGuardRules::PositionRiskAmount("USDJPY",POSITION_TYPE_BUY,1.0,150.000,150.500,risk_amount),
                 "buy stop loss above entry is invalid and treated as risk-uncalculable");
      AssertTrue(!COpenRiskGuardRules::PositionRiskAmount("USDJPY",POSITION_TYPE_SELL,1.0,150.000,149.500,risk_amount),
                 "sell stop loss below entry is invalid and treated as risk-uncalculable");
      AssertTrue(!COpenRiskGuardRules::PositionRiskAmount("USDJPY",POSITION_TYPE_BUY,0.0,150.000,149.500,risk_amount),
                 "zero volume is treated as risk-uncalculable");
   }

   {
      // 連続値方式（2026-08-23再設計）: avg_r（直近平均R倍数相当）が負の大きさに比例して
      // 滑らかに縮小し、floor_multiplierを下限にクランプする。境界での急激な切替を避ける狙い。
      AssertNear(CAdaptiveSizingRules::RiskMultiplier(10,10,-0.2,1.0,0.5),0.8,1.0e-12,
                 "adaptive sizing reduces proportionally for a mild negative average R");
      AssertNear(CAdaptiveSizingRules::RiskMultiplier(10,10,-0.5,1.0,0.5),0.5,1.0e-12,
                 "adaptive sizing reduces to exactly the floor at avg_r=-0.5 with sensitivity 1.0");
      AssertNear(CAdaptiveSizingRules::RiskMultiplier(10,10,-1.0,1.0,0.5),0.5,1.0e-12,
                 "adaptive sizing clamps at the floor for a large negative average R");
      AssertNear(CAdaptiveSizingRules::RiskMultiplier(10,10,0.0,1.0,0.5),1.0,1.0e-12,
                 "adaptive sizing does not reduce at zero average R boundary");
      AssertNear(CAdaptiveSizingRules::RiskMultiplier(10,10,0.5,1.0,0.5),1.0,1.0e-12,
                 "adaptive sizing does not expand above one for a positive average R");
      AssertNear(CAdaptiveSizingRules::RiskMultiplier(5,10,-0.5,1.0,0.5),1.0,1.0e-12,
                 "adaptive sizing does not reduce with insufficient trade history");
      AssertNear(CAdaptiveSizingRules::RiskMultiplier(0,10,0.0,1.0,0.5),1.0,1.0e-12,
                 "adaptive sizing does not reduce with zero trade history");
      AssertNear(CAdaptiveSizingRules::RiskMultiplier(10,0,-0.5,1.0,0.5),1.0,1.0e-12,
                 "adaptive sizing disabled with invalid lookback trades");
      AssertNear(CAdaptiveSizingRules::RiskMultiplier(10,10,-0.5,1.0,0.0),1.0,1.0e-12,
                 "adaptive sizing disabled with zero floor multiplier");
      AssertNear(CAdaptiveSizingRules::RiskMultiplier(10,10,-0.5,1.0,1.5),1.0,1.0e-12,
                 "adaptive sizing disabled with floor multiplier above one");
      AssertNear(CAdaptiveSizingRules::RiskMultiplier(10,10,-0.5,-0.1,0.5),1.0,1.0e-12,
                 "adaptive sizing disabled with negative sensitivity");
      AssertNear(CAdaptiveSizingRules::RiskMultiplier(15,10,-0.5,1.0,0.5),0.5,1.0e-12,
                 "adaptive sizing reduces when trade history exceeds lookback");
   }

   if(g_failures==0) Print("TEST_SUITE_PASS TestRiskGuards");
   else PrintFormat("TEST_SUITE_FAIL TestRiskGuards failures=%d",g_failures);
  }
