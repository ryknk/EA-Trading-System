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
   AssertTrue(CTrendFollowingRules::IsPullback(SIGNAL_DIRECTION_BUY,1.1002,1.1012,1.1000,1.1010,1.1006,
                                                1.1005,1.0995,1.1000,0.0100,0.15),
              "buy pullback accepted with 2-bar confirmation");
   AssertTrue(CTrendFollowingRules::IsPullback(SIGNAL_DIRECTION_SELL,1.0993,1.0995,1.0980,1.0985,1.0994,
                                                1.1005,1.0995,1.1000,0.0100,0.15),
              "sell pullback accepted with 2-bar confirmation");
   AssertTrue(!CTrendFollowingRules::IsPullback(SIGNAL_DIRECTION_BUY,1.1002,1.1012,1.1000,1.1010,1.1006,
                                                1.1015,1.0995,1.1000,0.0100,0.15),
              "buy pullback rejected when entry close fails to break touch bar high");
   AssertTrue(!CTrendFollowingRules::IsPullback(SIGNAL_DIRECTION_NONE,1.0,1.1,0.9,1.0,1.0,
                                                1.05,0.95,1.0,0.1,0.15),
              "no direction rejected");

   // 段階的Entry判定パイプライン専用: Setup(押し目/戻り成立)とTrigger(再加速)への分解が、
   // 既存のIsPullbackと数式上等価であることを検証する。
   AssertTrue(CTrendFollowingRules::IsPullbackSetup(SIGNAL_DIRECTION_BUY,1.1005,1.0995,1.1000,0.0100,0.15),
              "buy pullback setup accepted when touch bar is near EMA");
   AssertTrue(CTrendFollowingRules::IsPullbackTrigger(SIGNAL_DIRECTION_BUY,1.1002,1.1010,1.1006,1.1005,1.0995),
              "buy pullback trigger accepted when entry bar reaccelerates");
   AssertTrue(!CTrendFollowingRules::IsPullbackSetup(SIGNAL_DIRECTION_BUY,1.2005,1.1995,1.1000,0.0100,0.15),
              "buy pullback setup rejected when touch bar is far from EMA");
   AssertTrue(!CTrendFollowingRules::IsPullbackTrigger(SIGNAL_DIRECTION_BUY,1.1002,1.1010,1.1006,1.1015,1.0995),
              "buy pullback trigger rejected when entry close fails to break touch bar high");
   AssertTrue((CTrendFollowingRules::IsPullbackSetup(SIGNAL_DIRECTION_BUY,1.1005,1.0995,1.1000,0.0100,0.15)&&
               CTrendFollowingRules::IsPullbackTrigger(SIGNAL_DIRECTION_BUY,1.1002,1.1010,1.1006,1.1005,1.0995))==
              CTrendFollowingRules::IsPullback(SIGNAL_DIRECTION_BUY,1.1002,1.1012,1.1000,1.1010,1.1006,
                                                1.1005,1.0995,1.1000,0.0100,0.15),
              "setup AND trigger equals composed IsPullback for accepted buy case");
   AssertTrue((CTrendFollowingRules::IsPullbackSetup(SIGNAL_DIRECTION_BUY,1.1015,1.0995,1.1000,0.0100,0.15)&&
               CTrendFollowingRules::IsPullbackTrigger(SIGNAL_DIRECTION_BUY,1.1002,1.1010,1.1006,1.1015,1.0995))==
              CTrendFollowingRules::IsPullback(SIGNAL_DIRECTION_BUY,1.1002,1.1012,1.1000,1.1010,1.1006,
                                                1.1015,1.0995,1.1000,0.0100,0.15),
              "setup AND trigger equals composed IsPullback for rejected buy case");

   // Trigger ATR余裕幅（trigger_atr_buffer）: 弱いTrigger（タッチ足高安値を僅かに超えるのみ）を
   // 追加で棄却できることを検証する。既定0.0では従来どおり合格し続ける（後方互換）。
   AssertTrue(CTrendFollowingRules::IsPullbackTrigger(SIGNAL_DIRECTION_BUY,1.1002,1.1010,1.1006,1.1005,1.0995,0.0100,0.0),
              "buy pullback trigger unaffected by default zero buffer");
   AssertTrue(!CTrendFollowingRules::IsPullbackTrigger(SIGNAL_DIRECTION_BUY,1.1002,1.1010,1.1006,1.1005,1.0995,0.0100,0.15),
              "buy pullback trigger rejected when close fails to clear touch high by ATR buffer");
   AssertTrue(CTrendFollowingRules::IsPullbackTrigger(SIGNAL_DIRECTION_BUY,1.1002,1.1010,1.1006,1.1005,1.0995,0.0100,0.02),
              "buy pullback trigger accepted when close clears touch high by a small ATR buffer");
   AssertTrue(!CTrendFollowingRules::IsPullbackTrigger(SIGNAL_DIRECTION_SELL,1.0993,1.0985,1.0994,1.1005,1.0995,0.0100,0.15),
              "sell pullback trigger rejected when close fails to clear touch low by ATR buffer");

   if(g_failures==0)
      Print("TEST_SUITE_PASS TestTrendFollowingRules");
   else
      PrintFormat("TEST_SUITE_FAIL TestTrendFollowingRules failures=%d",g_failures);
  }
