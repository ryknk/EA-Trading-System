#property strict
#property script_show_inputs

#include <EaTradingSystem/Logging/TradeAnalyticsTracker.mqh>

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

void AssertNearDouble(const double actual,const double expected,const string test_name)
  {
   AssertTrue(MathAbs(actual-expected)<0.0000001,
              StringFormat("%s (actual=%.10f expected=%.10f)",test_name,actual,expected));
  }

void OnStart(void)
  {
   // 初期観測（最初の1件）はmfe=mae=post_peak_mae=profit、mfe_timeはその時刻になる想定
   // （CTradeAnalyticsTracker::Update側の初期化ロジックであり、UpdateExtreme自体は
   // 2件目以降の更新のみを担う。ここでは初期値を模して2件目以降の挙動を検証する）。
   double mfe=100.0,mae=100.0,post_peak_mae=100.0;
   datetime mfe_time=D'2026.01.01 00:00:00';

   // ケース1: 新高値を更新 → mfe/mfe_time/post_peak_maeがすべて新値へ更新される。
   CTradeAnalyticsRules::UpdateExtreme(200.0,D'2026.01.01 01:00:00',mfe,mfe_time,mae,post_peak_mae);
   AssertNearDouble(mfe,200.0,"new high updates mfe");
   AssertTrue(mfe_time==D'2026.01.01 01:00:00',"new high updates mfe_time");
   AssertNearDouble(post_peak_mae,200.0,"new high resets post_peak_mae to current profit");
   AssertNearDouble(mae,100.0,"new high does not worsen mae when profit is positive");

   // ケース2: Peak確定後に含み益が縮小（Peakは更新されない）→ post_peak_maeのみ更新、mfe/mfe_timeは不変。
   CTradeAnalyticsRules::UpdateExtreme(120.0,D'2026.01.01 02:00:00',mfe,mfe_time,mae,post_peak_mae);
   AssertNearDouble(mfe,200.0,"pullback after peak does not change mfe");
   AssertTrue(mfe_time==D'2026.01.01 01:00:00',"pullback after peak does not change mfe_time");
   AssertNearDouble(post_peak_mae,120.0,"pullback after peak lowers post_peak_mae");

   // ケース3: さらに逆行してSL方向へ（マイナス）→ post_peak_maeとmae両方が更新される。
   CTradeAnalyticsRules::UpdateExtreme(-300.0,D'2026.01.01 03:00:00',mfe,mfe_time,mae,post_peak_mae);
   AssertNearDouble(post_peak_mae,-300.0,"further reversal lowers post_peak_mae again");
   AssertNearDouble(mae,-300.0,"further reversal below prior mae updates overall mae");
   AssertTrue(mfe_time==D'2026.01.01 01:00:00',"mfe_time remains at the original peak after reversal");

   // ケース4: Peak後の一時的な戻り（post_peak_maeより高いがmfeより低い）→ どちらも更新されない。
   CTradeAnalyticsRules::UpdateExtreme(-100.0,D'2026.01.01 04:00:00',mfe,mfe_time,mae,post_peak_mae);
   AssertNearDouble(post_peak_mae,-300.0,"bounce between post_peak_mae and mfe does not change post_peak_mae");
   AssertNearDouble(mfe,200.0,"bounce between post_peak_mae and mfe does not change mfe");

   // ケース5: 再度新高値（2つ目のPeak）→ post_peak_maeは新Peak時点の値へリセットされる。
   CTradeAnalyticsRules::UpdateExtreme(250.0,D'2026.01.01 05:00:00',mfe,mfe_time,mae,post_peak_mae);
   AssertNearDouble(mfe,250.0,"second higher peak updates mfe");
   AssertTrue(mfe_time==D'2026.01.01 05:00:00',"second higher peak updates mfe_time");
   AssertNearDouble(post_peak_mae,250.0,"second higher peak resets post_peak_mae");

   if(g_failures==0)
      Print("TEST_SUITE_PASS TestTradeAnalyticsTracker");
   else
      PrintFormat("TEST_SUITE_FAIL TestTradeAnalyticsTracker failures=%d",g_failures);
  }
