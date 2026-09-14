#property strict
#property script_show_inputs

#include <EaTradingSystem/Filter/MarketRegimeClassifier.mqh>
#include <EaTradingSystem/Filter/ChoppinessIndex.mqh>

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
   AssertTrue(CMarketRegimeClassifier::ClassifyTrend(25.0,1.20,1.10,20.0)==MARKET_REGIME_TREND_UP,
              "strong ADX with rising MA classified as TrendUp");
   AssertTrue(CMarketRegimeClassifier::ClassifyTrend(25.0,1.10,1.20,20.0)==MARKET_REGIME_TREND_DOWN,
              "strong ADX with falling MA classified as TrendDown");
   AssertTrue(CMarketRegimeClassifier::ClassifyTrend(15.0,1.20,1.10,20.0)==MARKET_REGIME_TREND_RANGE,
              "ADX below threshold classified as Range regardless of MA slope");
   AssertTrue(CMarketRegimeClassifier::ClassifyTrend(25.0,1.15,1.15,20.0)==MARKET_REGIME_TREND_RANGE,
              "flat MA with strong ADX classified as Range");
   AssertTrue(CMarketRegimeClassifier::ClassifyTrend(20.0,1.20,1.10,20.0)==MARKET_REGIME_TREND_UP,
              "ADX exactly at threshold is treated as trending");
   AssertTrue(CMarketRegimeClassifier::ClassifyTrend(MathSqrt(-1.0),1.20,1.10,20.0)==MARKET_REGIME_TREND_UNKNOWN,
              "NaN ADX value classified as Unknown");
   AssertTrue(CMarketRegimeClassifier::ClassifyTrend(-1.0,1.20,1.10,20.0)==MARKET_REGIME_TREND_UNKNOWN,
              "negative ADX classified as Unknown");

   AssertTrue(CMarketRegimeClassifier::ClassifyVolatility(0.0020,0.0010,1.3,0.7)==MARKET_REGIME_VOLATILITY_HIGH,
              "ATR well above baseline classified as HighVolatility");
   AssertTrue(CMarketRegimeClassifier::ClassifyVolatility(0.0005,0.0010,1.3,0.7)==MARKET_REGIME_VOLATILITY_LOW,
              "ATR well below baseline classified as LowVolatility");
   AssertTrue(CMarketRegimeClassifier::ClassifyVolatility(0.0010,0.0010,1.3,0.7)==MARKET_REGIME_VOLATILITY_NORMAL,
              "ATR equal to baseline classified as NormalVolatility");
   AssertTrue(CMarketRegimeClassifier::ClassifyVolatility(0.00135,0.0010,1.3,0.7)==MARKET_REGIME_VOLATILITY_HIGH,
              "ATR ratio clearly above high threshold is treated as high volatility");
   AssertTrue(CMarketRegimeClassifier::ClassifyVolatility(0.0010,0.0,1.3,0.7)==MARKET_REGIME_VOLATILITY_UNKNOWN,
              "zero baseline classified as Unknown instead of dividing by zero");
   AssertTrue(CMarketRegimeClassifier::ClassifyVolatility(-0.0010,0.0010,1.3,0.7)==MARKET_REGIME_VOLATILITY_UNKNOWN,
              "negative ATR classified as Unknown");

   AssertTrue(MarketRegimeTrendToString(MARKET_REGIME_TREND_UP)=="TrendUp","TrendUp string mapping");
   AssertTrue(MarketRegimeTrendToString(MARKET_REGIME_TREND_DOWN)=="TrendDown","TrendDown string mapping");
   AssertTrue(MarketRegimeTrendToString(MARKET_REGIME_TREND_RANGE)=="Range","Range string mapping");
   AssertTrue(MarketRegimeTrendToString(MARKET_REGIME_TREND_UNKNOWN)=="Unknown","Trend Unknown string mapping");
   AssertTrue(MarketRegimeVolatilityToString(MARKET_REGIME_VOLATILITY_HIGH)=="HighVolatility","HighVolatility string mapping");
   AssertTrue(MarketRegimeVolatilityToString(MARKET_REGIME_VOLATILITY_NORMAL)=="NormalVolatility","NormalVolatility string mapping");
   AssertTrue(MarketRegimeVolatilityToString(MARKET_REGIME_VOLATILITY_LOW)=="LowVolatility","LowVolatility string mapping");
   AssertTrue(MarketRegimeVolatilityToString(MARKET_REGIME_VOLATILITY_UNKNOWN)=="Unknown","Volatility Unknown string mapping");

   // Choppiness Index（III案、レジーム分類器の高度化。既存ADXベース判定とは独立の軸）
   AssertTrue(MathAbs(CChoppinessIndex::Calculate(100.0,150.0,50.0,10)-0.0)<1.0e-9,
              "choppiness index is zero when atr sum equals the period range (efficient trend)");
   AssertTrue(MathAbs(CChoppinessIndex::Calculate(1000.0,150.0,50.0,10)-100.0)<1.0e-9,
              "choppiness index reaches 100 when atr sum is period times the range");
   AssertTrue(MathAbs(CChoppinessIndex::Calculate(316.2278,200.0,100.0,10)-50.0)<1.0e-3,
              "choppiness index at the geometric midpoint is 50");
   AssertTrue(CChoppinessIndex::Calculate(0.0,150.0,50.0,10)==0.0,
              "choppiness index with zero atr sum treated as zero (data unavailable)");
   AssertTrue(CChoppinessIndex::Calculate(100.0,100.0,100.0,10)==0.0,
              "choppiness index with zero range treated as zero to avoid division by zero");
   AssertTrue(CChoppinessIndex::Calculate(100.0,150.0,50.0,1)==0.0,
              "choppiness index rejects a period below two");
   AssertTrue(CChoppinessIndex::Calculate(MathSqrt(-1.0),150.0,50.0,10)==0.0,
              "choppiness index rejects NaN input");

   AssertTrue(CChoppinessIndex::IsChoppy(70.0,61.8),"choppiness above threshold is classified as choppy");
   AssertTrue(CChoppinessIndex::IsChoppy(61.8,61.8),"choppiness exactly at threshold is classified as choppy");
   AssertTrue(!CChoppinessIndex::IsChoppy(50.0,61.8),"choppiness below threshold is not classified as choppy");

   if(g_failures==0)
      Print("TEST_SUITE_PASS TestMarketRegimeClassifier");
   else
      PrintFormat("TEST_SUITE_FAIL TestMarketRegimeClassifier failures=%d",g_failures);
  }
