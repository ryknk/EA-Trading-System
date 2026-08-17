#ifndef EA_TRADING_SYSTEM_MARKET_REGIME_CLASSIFIER_MQH
#define EA_TRADING_SYSTEM_MARKET_REGIME_CLASSIFIER_MQH

// 市場レジーム（Trend/Range、Volatility水準）の判定専用ロジック。
// 分析・監査ログ・将来のMarketFilter向けの分類のみを行い、
// 発注判断・既存ポジション管理・売買制御には一切関与しない（判定と売買制御の分離）。
enum EMarketRegimeTrend
  {
   MARKET_REGIME_TREND_UNKNOWN=0,
   MARKET_REGIME_TREND_UP=1,
   MARKET_REGIME_TREND_DOWN=2,
   MARKET_REGIME_TREND_RANGE=3
  };

enum EMarketRegimeVolatility
  {
   MARKET_REGIME_VOLATILITY_UNKNOWN=0,
   MARKET_REGIME_VOLATILITY_HIGH=1,
   MARKET_REGIME_VOLATILITY_NORMAL=2,
   MARKET_REGIME_VOLATILITY_LOW=3
  };

string MarketRegimeTrendToString(const EMarketRegimeTrend value)
  {
   if(value==MARKET_REGIME_TREND_UP) return "TrendUp";
   if(value==MARKET_REGIME_TREND_DOWN) return "TrendDown";
   if(value==MARKET_REGIME_TREND_RANGE) return "Range";
   return "Unknown";
  }

string MarketRegimeVolatilityToString(const EMarketRegimeVolatility value)
  {
   if(value==MARKET_REGIME_VOLATILITY_HIGH) return "HighVolatility";
   if(value==MARKET_REGIME_VOLATILITY_NORMAL) return "NormalVolatility";
   if(value==MARKET_REGIME_VOLATILITY_LOW) return "LowVolatility";
   return "Unknown";
  }

class CMarketRegimeClassifier
  {
public:
   // ADXでトレンド強度、MAの現在値と参照値（過去N本前）の比較でトレンド方向を判定する。
   // ADXが閾値未満、または入力が不正な場合はRange扱いとする。データ不良時はUnknownとする。
   static EMarketRegimeTrend ClassifyTrend(const double adx,const double ma_current,const double ma_reference,
                                            const double trend_adx_min)
     {
      if(!MathIsValidNumber(adx) || !MathIsValidNumber(ma_current) || !MathIsValidNumber(ma_reference) ||
         adx<0.0 || trend_adx_min<0.0)
         return MARKET_REGIME_TREND_UNKNOWN;
      if(adx<trend_adx_min) return MARKET_REGIME_TREND_RANGE;
      if(ma_current>ma_reference) return MARKET_REGIME_TREND_UP;
      if(ma_current<ma_reference) return MARKET_REGIME_TREND_DOWN;
      return MARKET_REGIME_TREND_RANGE;
     }

   // 現在のATRを直近の平均ATR（同一Indicatorから算出したベースライン）と比較し、
   // 固定pips閾値ではなく相対比率でボラティリティ水準を判定する。
   static EMarketRegimeVolatility ClassifyVolatility(const double atr,const double atr_baseline_average,
                                                       const double high_volatility_ratio,
                                                       const double low_volatility_ratio)
     {
      if(!MathIsValidNumber(atr) || !MathIsValidNumber(atr_baseline_average) ||
         atr<0.0 || atr_baseline_average<=0.0 ||
         high_volatility_ratio<=1.0 || low_volatility_ratio<=0.0 || low_volatility_ratio>=1.0)
         return MARKET_REGIME_VOLATILITY_UNKNOWN;
      const double ratio=atr/atr_baseline_average;
      if(ratio>=high_volatility_ratio) return MARKET_REGIME_VOLATILITY_HIGH;
      if(ratio<=low_volatility_ratio) return MARKET_REGIME_VOLATILITY_LOW;
      return MARKET_REGIME_VOLATILITY_NORMAL;
     }
  };

#endif
