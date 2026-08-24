#ifndef EA_TRADING_SYSTEM_CHOPPINESS_INDEX_MQH
#define EA_TRADING_SYSTEM_CHOPPINESS_INDEX_MQH

// Choppiness Index（CI、E.W.Dreissが考案）: トレンド相場とレンジ（往復）相場を区別するための
// 価格経路効率性の指標。100に近いほど往復（レンジ）、0に近いほど一方向トレンドが強いことを示す。
// CI = 100 * log10( sum(ATR, period) / (highest_high(period) - lowest_low(period)) ) / log10(period)
//
// 既存のCMarketRegimeClassifier（ADX＋MAスロープに基づく方向性判定）とは異なる軸（価格の
// 進み方の効率性）で判定するため、独立した確認シグナルとして扱う。B案・D案でADX閾値ベースの
// レジーム判定を複数の形で試したがいずれもTrain区間で反証されており（詳細はTASKS.md参照）、
// 本指標は既存ADX判定を置き換えるものではなく、平均回帰戦略（II案）専用の活動条件として
// 独立に用いる。
class CChoppinessIndex
  {
public:
   static double Calculate(const double atr_sum,const double highest_high,const double lowest_low,
                           const int period)
     {
      if(period<2 || atr_sum<=0.0 || !MathIsValidNumber(atr_sum) ||
         !MathIsValidNumber(highest_high) || !MathIsValidNumber(lowest_low))
         return 0.0;
      const double range=highest_high-lowest_low;
      if(range<=0.0)
         return 0.0;
      const double ratio=atr_sum/range;
      if(ratio<=0.0)
         return 0.0;
      const double result=100.0*MathLog10(ratio)/MathLog10((double)period);
      return (MathIsValidNumber(result) ? MathMax(0.0,MathMin(100.0,result)) : 0.0);
     }

   static bool IsChoppy(const double choppiness,const double threshold)
     {
      if(!MathIsValidNumber(choppiness) || !MathIsValidNumber(threshold))
         return false;
      return choppiness>=threshold;
     }
  };

#endif
