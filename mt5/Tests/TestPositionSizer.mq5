#property strict

#include <EaTradingSystem/Risk/PositionSizer.mqh>

int g_failures=0;

void AssertNear(const double actual,const double expected,const double tolerance,const string name)
  {
   if(MathAbs(actual-expected)<=tolerance)
      PrintFormat("PASS %s",name);
   else
     {
      PrintFormat("FAIL %s actual=%.10f expected=%.10f",name,actual,expected);
      g_failures++;
     }
  }

void OnStart(void)
  {
   AssertNear(CPositionSizerRules::RawVolume(1000000.0,0.005,100000.0),0.05,1.0e-12,
              "0.5 percent risk raw volume");
   AssertNear(CPositionSizerRules::RawVolume(0.0,0.005,100000.0),0.0,1.0e-12,
              "zero equity rejected");
   AssertNear(CPositionSizerRules::RawVolume(1000000.0,0.0,100000.0),0.0,1.0e-12,
              "zero risk rejected");
   AssertNear(CPositionSizerRules::RawVolume(1000000.0,-0.005,100000.0),0.0,1.0e-12,
              "negative risk rejected");
   AssertNear(CPositionSizerRules::RawVolume(1000000.0,0.005,0.0),0.0,1.0e-12,
              "zero stop loss rejected");
   AssertNear(CPositionSizerRules::RawVolume(1000000.0,0.005,0.000001),5000000000.0,0.1,
              "very small loss remains bounded by volume limits later");
   AssertNear(CPositionSizerRules::RawVolume(1000000.0,0.005,1000000000.0),0.000005,1.0e-12,
              "very large stop produces small volume");
   AssertNear(CPositionSizerRules::TickLossPerLot(150.0,149.0,0.001,100.0),100000.0,1.0e-8,
              "tick loss calculation");
   AssertNear(CPositionSizerRules::TickLossPerLot(150.0,149.0,0.0,100.0),0.0,1.0e-12,
              "invalid tick size rejected");
   AssertNear(CPositionSizerRules::TickLossPerLot(150.0,149.0,0.001,0.0),0.0,1.0e-12,
              "invalid tick value rejected");
   AssertNear(CPositionSizerRules::FloorVolume(0.057,0.01,100.0,0.01),0.05,1.0e-12,
              "volume is floored not rounded");
   AssertNear(CPositionSizerRules::FloorVolume(0.009,0.01,100.0,0.01),0.0,1.0e-12,
              "below minimum is rejected");
   AssertNear(CPositionSizerRules::FloorVolume(120.0,0.01,100.0,0.01),100.0,1.0e-12,
              "volume is capped at maximum");
   AssertNear(CPositionSizerRules::FloorVolume(5000000000.0,0.01,100.0,0.01),100.0,1.0e-12,
              "tiny stop cannot exceed symbol maximum");

   // 通常のBroker仕様では正規化前後でvolumeが変わらないこと（既存挙動の維持）
   AssertNear(CPositionSizerRules::NormalizeVolume(0.05,0.01),0.05,1.0e-12,"normalize keeps 0.01 step volume");
   AssertNear(CPositionSizerRules::NormalizeVolume(46.0,1.0),46.0,1.0e-12,"normalize keeps 1.0 step volume");
   AssertNear(CPositionSizerRules::NormalizeVolume(0.5,0.1),0.5,1.0e-12,"normalize keeps 0.1 step volume");
   AssertNear(CPositionSizerRules::NormalizeVolume(0.04,0.01),0.04,1.0e-12,"normalize keeps XAUUSD style volume");
   AssertNear(CPositionSizerRules::NormalizeVolume(0.001,0.001),0.001,1.0e-12,"normalize keeps 0.001 step volume");
   AssertNear(CPositionSizerRules::VolumeDigits(0.01),2.0,1.0e-12,"volume digits for 0.01 step");
   // 極小刻み（初期値のCustom Symbolで実際に発生した1e-8）でvolumeが0に潰れる場合は0を返す
   AssertNear(CPositionSizerRules::NormalizeVolume(1.0e-7,1.0e-8),0.0,1.0e-15,"tiny step cannot yield zero-volume success");
   AssertNear(CPositionSizerRules::NormalizeVolume(0.0,0.01),0.0,1.0e-15,"zero volume stays zero");
   AssertNear(CPositionSizerRules::NormalizeVolume(0.05,0.0),0.0,1.0e-15,"invalid step is rejected");

   if(g_failures==0) Print("TEST_SUITE_PASS TestPositionSizer");
   else PrintFormat("TEST_SUITE_FAIL TestPositionSizer failures=%d",g_failures);
  }
