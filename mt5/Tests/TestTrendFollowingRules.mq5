#property strict
#property script_show_inputs

#include <EaTradingSystem/Strategy/TrendFollowingRules.mqh>
#include <EaTradingSystem/Strategy/MeanReversionStrategy.mqh>

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

// レンジ相場逆張りEntry（Reentry Window対応）のテスト用ヘルパー。closes[i]/lower[i]/upper[i]は
// shift=(i+1)（i=0が直近確定足=shift1）に対応する配列を組み立てる。
void SetReentryWindow3(double &closes[],double &lower[],double &upper[],
                       const double c0,const double l0,const double u0,
                       const double c1,const double l1,const double u1,
                       const double c2,const double l2,const double u2)
  {
   ArrayResize(closes,3); ArrayResize(lower,3); ArrayResize(upper,3);
   closes[0]=c0; lower[0]=l0; upper[0]=u0;
   closes[1]=c1; lower[1]=l1; upper[1]=u1;
   closes[2]=c2; lower[2]=l2; upper[2]=u2;
  }

void SetReentryWindow5(double &closes[],double &lower[],double &upper[],
                       const double c0,const double l0,const double u0,
                       const double c1,const double l1,const double u1,
                       const double c2,const double l2,const double u2,
                       const double c3,const double l3,const double u3,
                       const double c4,const double l4,const double u4)
  {
   ArrayResize(closes,5); ArrayResize(lower,5); ArrayResize(upper,5);
   closes[0]=c0; lower[0]=l0; upper[0]=u0;
   closes[1]=c1; lower[1]=l1; upper[1]=u1;
   closes[2]=c2; lower[2]=l2; upper[2]=u2;
   closes[3]=c3; lower[3]=l3; upper[3]=u3;
   closes[4]=c4; lower[4]=l4; upper[4]=u4;
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

   // レンジ相場逆張りロジック（2026-08-24仕様変更）: Range Filter（Choppiness Index+ADX）の単体テスト。
   AssertTrue(CMeanReversionEntryRules::IsRangeFilterActive(70.0,20.0,60.0,25.0),
              "range filter active when choppiness high and ADX low");
   AssertTrue(!CMeanReversionEntryRules::IsRangeFilterActive(50.0,20.0,60.0,25.0),
              "range filter inactive when choppiness below threshold");
   AssertTrue(!CMeanReversionEntryRules::IsRangeFilterActive(70.0,30.0,60.0,25.0),
              "range filter inactive when ADX at or above ceiling");
   AssertTrue(!CMeanReversionEntryRules::IsRangeFilterActive(70.0,MathSqrt(-1.0),60.0,25.0),
              "range filter inactive on NaN ADX");

   // Entry（Reentry Window対応、2026-08-24追加）: Band外側へのブレイク後、最大max_reentry_bars本
   // 以内にBand内へ復帰した最初の確定足でのみEntryする。
   double w_closes[],w_lower[],w_upper[];
   double w5_closes[],w5_lower[],w5_upper[];

   // MaxReentryBars=1: shift3がBand内側（単発ブレイク）なら、従来の「次の1本で復帰」と同等に成立する。
   SetReentryWindow3(w_closes,w_lower,w_upper,
                     149.600,149.500,151.000,   // shift1: entryがLower Band内へ復帰
                     149.400,149.500,151.000,   // shift2: touchがLower Bandを下抜け
                     149.600,149.450,150.950);  // shift3: ブレイク以前はBand内側
   AssertTrue(CMeanReversionEntryRules::EntryDirectionWithReentry(w_closes,w_lower,w_upper,1)==SIGNAL_DIRECTION_BUY,
              "reentry bars=1: buy equivalent to the legacy single-bar break-and-return");

   // MaxReentryBars=1: shift3もBand外側（ブレイクが1本より前から継続）なら期限切れで不成立。
   SetReentryWindow3(w_closes,w_lower,w_upper,
                     149.600,149.500,151.000,
                     149.400,149.500,151.000,
                     149.350,149.480,150.980);  // shift3もLower Band外側のまま
   AssertTrue(CMeanReversionEntryRules::EntryDirectionWithReentry(w_closes,w_lower,w_upper,1)==SIGNAL_DIRECTION_NONE,
              "reentry bars=1: rejected when the break already lasted more than 1 bar (expired)");

   // touchがBandを一度も割っていない場合は不成立（復帰は既に成立済みで新規事象ではない）。
   SetReentryWindow3(w_closes,w_lower,w_upper,
                     149.600,149.500,151.000,
                     149.600,149.500,151.000,   // shift2もBand内側＝ブレイクなし
                     149.600,149.500,151.000);
   AssertTrue(CMeanReversionEntryRules::EntryDirectionWithReentry(w_closes,w_lower,w_upper,1)==SIGNAL_DIRECTION_NONE,
              "reentry: rejected when the touch bar never broke the band");

   // MaxReentryBars=3: ブレイク開始からちょうど3本目での復帰（窓の境界）は成立する。
   SetReentryWindow5(w5_closes,w5_lower,w5_upper,
                     149.600,149.500,151.000,   // shift1: 復帰
                     149.300,149.480,150.980,   // shift2: ブレイク継続
                     149.250,149.460,150.960,   // shift3: ブレイク継続
                     149.200,149.440,150.940,   // shift4: ブレイク開始（gap=3）
                     149.600,149.400,150.900);  // shift5: ブレイク以前はBand内側
   AssertTrue(CMeanReversionEntryRules::EntryDirectionWithReentry(w5_closes,w5_lower,w5_upper,3)==SIGNAL_DIRECTION_BUY,
              "reentry bars=3: buy accepted when return happens exactly at the window boundary (gap=3)");

   // MaxReentryBars=3: ブレイクが4本以上前から継続していた場合は期限切れで不成立。
   SetReentryWindow5(w5_closes,w5_lower,w5_upper,
                     149.600,149.500,151.000,
                     149.300,149.480,150.980,
                     149.250,149.460,150.960,
                     149.200,149.440,150.940,
                     149.150,149.400,150.900);  // shift5もLower Band外側のまま（ブレイクは4本以上前から）
   AssertTrue(CMeanReversionEntryRules::EntryDirectionWithReentry(w5_closes,w5_lower,w5_upper,3)==SIGNAL_DIRECTION_NONE,
              "reentry bars=3: rejected when the break started more than 3 bars before the return");

   // MaxReentryBars=3: SELL方向（Upper Band）も同様に窓内の復帰で成立する。
   SetReentryWindow5(w5_closes,w5_lower,w5_upper,
                     150.900,149.500,151.000,   // shift1: Upper Band内へ復帰
                     151.200,149.520,151.020,   // shift2: ブレイク継続
                     151.250,149.540,151.040,   // shift3: ブレイク継続
                     151.300,149.560,151.060,   // shift4: ブレイク開始
                     150.900,149.600,151.100);  // shift5: ブレイク以前はBand内側
   AssertTrue(CMeanReversionEntryRules::EntryDirectionWithReentry(w5_closes,w5_lower,w5_upper,3)==SIGNAL_DIRECTION_SELL,
              "reentry bars=3: sell accepted when return happens within the window (upper band)");

   // 不正なmax_reentry_bars・配列サイズ不足は不成立。
   AssertTrue(CMeanReversionEntryRules::EntryDirectionWithReentry(w_closes,w_lower,w_upper,0)==SIGNAL_DIRECTION_NONE,
              "reentry: rejected when max_reentry_bars is non-positive");
   double w_short_closes[]={149.600,149.400};
   double w_short_lower[]={149.500,149.500};
   double w_short_upper[]={151.000,151.000};
   AssertTrue(CMeanReversionEntryRules::EntryDirectionWithReentry(w_short_closes,w_short_lower,w_short_upper,1)==SIGNAL_DIRECTION_NONE,
              "reentry: rejected when the supplied window array is smaller than max_reentry_bars+2");

   // SL: BandまたはRecent Rangeのうち保守的な方の外側にATR×バッファを設ける。
   AssertTrue(MathAbs(CMeanReversionEntryRules::StopLossBuy(149.500,149.300,0.100,1.0)-149.200)<1.0e-9,
              "buy stop loss uses the more conservative of band and recent range low, minus ATR buffer");
   AssertTrue(MathAbs(CMeanReversionEntryRules::StopLossBuy(149.500,149.700,0.100,1.0)-149.400)<1.0e-9,
              "buy stop loss uses the band when it is lower than the recent range low");
   AssertTrue(MathAbs(CMeanReversionEntryRules::StopLossSell(151.000,151.300,0.100,1.0)-151.400)<1.0e-9,
              "sell stop loss uses the more conservative of band and recent range high, plus ATR buffer");
   AssertTrue(CMeanReversionEntryRules::StopLossBuy(149.500,149.300,0.0,1.0)==0.0,
              "buy stop loss rejected on non-positive ATR");

   // TP: 既定はBB Middle、反対側Bandも選択可能。
   AssertTrue(CMeanReversionEntryRules::TakeProfit(SIGNAL_DIRECTION_BUY,MEAN_REVERSION_TP_BB_MIDDLE,150.000,151.000,149.500)==150.000,
              "buy take profit defaults to BB middle");
   AssertTrue(CMeanReversionEntryRules::TakeProfit(SIGNAL_DIRECTION_BUY,MEAN_REVERSION_TP_OPPOSITE_BAND,150.000,151.000,149.500)==151.000,
              "buy take profit can target the opposite (upper) band");
   AssertTrue(CMeanReversionEntryRules::TakeProfit(SIGNAL_DIRECTION_SELL,MEAN_REVERSION_TP_OPPOSITE_BAND,150.000,151.000,149.500)==149.500,
              "sell take profit can target the opposite (lower) band");

   // 強制決済（2026-08-24仕様変更）: レンジ高値/安値（実際のスイング高安値）の確定足Closeブレイク。
   // Range Filter（CI/ADX閾値）の一時的な跨ぎでは反応しない、独立した価格構造ベースの条件。
   AssertTrue(CMeanReversionExitRules::IsRangeBreak(SIGNAL_DIRECTION_BUY,149.400,149.500,151.000),
              "buy position force-exits when confirmed close breaks below the recent range low");
   AssertTrue(!CMeanReversionExitRules::IsRangeBreak(SIGNAL_DIRECTION_BUY,149.600,149.500,151.000),
              "buy position does not force-exit while close stays inside the recent range");
   AssertTrue(CMeanReversionExitRules::IsRangeBreak(SIGNAL_DIRECTION_SELL,151.200,149.500,151.000),
              "sell position force-exits when confirmed close breaks above the recent range high");
   AssertTrue(!CMeanReversionExitRules::IsRangeBreak(SIGNAL_DIRECTION_NONE,149.400,149.500,151.000),
              "range break check rejects an undirected position");

   // 強制決済（2026-08-25仕様変更、ユーザー指示）: Range Filter解除だけを理由とした即時決済
   // （旧IsRangeQualityLost）は廃止し、「警戒状態＋猶予期間」の状態機械
   // （CMeanReversionStrategy::IsRangeStillValid、ticket単位の状態を要するため本ファイルでの
   // 静的関数テストの対象外。IsTrendStillValidと同じ理由）へ置き換えた。Range Filter自体の
   // 判定（IsRangeFilterActive）とレンジブレイク判定（IsRangeBreak）は変更しておらず、
   // 上記のテストがそのまま引き続き有効。

   // 強制決済: BB Widthの急拡大（過去N本平均比）。
   AssertTrue(CMeanReversionExitRules::IsBbWidthExpanded(3.0,2.0,1.5),
              "bb width force-exits when current width is at least the expansion ratio times the average");
   AssertTrue(!CMeanReversionExitRules::IsBbWidthExpanded(2.5,2.0,1.5),
              "bb width does not force-exit below the expansion ratio");
   AssertTrue(!CMeanReversionExitRules::IsBbWidthExpanded(3.0,2.0,1.0),
              "bb width expansion check rejects a non-expansive ratio configuration");

   if(g_failures==0)
      Print("TEST_SUITE_PASS TestTrendFollowingRules");
   else
      PrintFormat("TEST_SUITE_FAIL TestTrendFollowingRules failures=%d",g_failures);
  }
