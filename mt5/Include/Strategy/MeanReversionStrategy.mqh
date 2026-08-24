#ifndef EA_TRADING_SYSTEM_MEAN_REVERSION_STRATEGY_MQH
#define EA_TRADING_SYSTEM_MEAN_REVERSION_STRATEGY_MQH

#include <EaTradingSystem/Strategy/IStrategy.mqh>
#include <EaTradingSystem/Filter/ChoppinessIndex.mqh>

// TPの決定方式。将来的に反対側Band TP等の比較を可能にするための外部パラメータ化（既定はBB Middle）。
enum EMeanReversionTakeProfitMode
  {
   MEAN_REVERSION_TP_BB_MIDDLE=0,
   MEAN_REVERSION_TP_OPPOSITE_BAND=1
  };

// レンジ相場逆張りロジック（2026-08-24仕様変更）: 既存のトレンドフォロー戦略とは独立した、
// レンジ端からの平均回帰を狙う第二の候補生成ロジック。Choppiness Index（レンジの往復効率性）と
// ADX（トレンド強度）の両方でレンジ相場と確認できた場合のみ活動する。Band外側へのブレイク後、
// 確定足で内側へ復帰したタイミングのみをEntryとする（タッチのみでは反応しない）。
//
// エントリー条件（本クラス）と保有中ポジションの強制決済条件（CMeanReversionExitRules）は、
// 目的も判定基準も異なるためコード上も明確に分離する（2026-08-24追記）。Range Filter（CI/ADX閾値）は
// 新規エントリーの成立条件としてのみ用い、保有中ポジションの決済判断には使わない。CI/ADXの
// 一時的な閾値跨ぎだけで決済すると過剰反応（ホイッスル）になるため、強制決済はレンジ崩壊を
// 示すより強い条件（CMeanReversionExitRules参照）でのみ発動する。
class CMeanReversionEntryRules
  {
public:
   // Range Filter: Choppiness IndexがCI閾値以上、かつADXがADX上限未満の場合のみレンジ相場と判定する。
   static bool IsRangeFilterActive(const double choppiness,const double adx,
                                   const double choppiness_min,const double adx_max)
     {
      if(!MathIsValidNumber(adx) || adx<0.0 || adx_max<=0.0)
         return false;
      return CChoppinessIndex::IsChoppy(choppiness,choppiness_min) && adx<adx_max;
     }

   // BUY: 確定足CloseがLower Bandを下抜けた後（Reentry待ち開始）、最大max_reentry_bars本以内に
   // 確定足CloseがLower Band内へ復帰した最初の確定足でのみ成立する。SELLはUpper Bandに対して同様。
   // closes[i]/lower_bands[i]/upper_bands[i]はshift=(i+1)（i=0が直近確定足=shift1）に対応する、
   // サイズmax_reentry_bars+2以上の配列（末尾の余分な1本は、Band外側に留まっていた期間が
   // max_reentry_bars本を超えていた＝期限切れかどうかを判定するための参照用）。
   // 各足は自身の時点のBand値と比較する（トレンド戦略のタッチ足/確認足パターンと同じ考え方）。
   // max_reentry_bars=1では、従来の「直近確定足がBandを下抜け/上抜け、次の確定足で復帰」判定と
   // 完全に等価になる（ブレイクが単発であれば、gap=1で必ず成立する）。
   static ESignalDirection EntryDirectionWithReentry(const double &closes[],const double &lower_bands[],
                                                      const double &upper_bands[],const int max_reentry_bars)
     {
      if(max_reentry_bars<1) return SIGNAL_DIRECTION_NONE;
      const int needed=max_reentry_bars+2;
      if(ArraySize(closes)<needed || ArraySize(lower_bands)<needed || ArraySize(upper_bands)<needed)
         return SIGNAL_DIRECTION_NONE;
      for(int i=0; i<needed; i++)
        {
         if(!MathIsValidNumber(closes[i]) || !MathIsValidNumber(lower_bands[i]) || !MathIsValidNumber(upper_bands[i]) ||
            upper_bands[i]<=lower_bands[i])
            return SIGNAL_DIRECTION_NONE;
        }

      // BUY: entry(shift1)がLower Band内へ復帰、かつtouch(shift2)がLower Bandを下抜けたままだった場合のみ
      // （touch自身がまだ内側なら、復帰は既により早いタイミングで成立済みのはずであり、今回は新規事象ではない）。
      if(closes[0]>=lower_bands[0] && closes[1]<lower_bands[1])
        {
         int streak_end=1;
         for(int i=2; i<=max_reentry_bars; i++)
           {
            if(closes[i]<lower_bands[i]) streak_end=i;
            else break;
           }
         const bool expired=(streak_end==max_reentry_bars && closes[max_reentry_bars+1]<lower_bands[max_reentry_bars+1]);
         if(!expired) return SIGNAL_DIRECTION_BUY;
        }

      // SELL: BUYの逆。
      if(closes[0]<=upper_bands[0] && closes[1]>upper_bands[1])
        {
         int streak_end=1;
         for(int i=2; i<=max_reentry_bars; i++)
           {
            if(closes[i]>upper_bands[i]) streak_end=i;
            else break;
           }
         const bool expired=(streak_end==max_reentry_bars && closes[max_reentry_bars+1]>upper_bands[max_reentry_bars+1]);
         if(!expired) return SIGNAL_DIRECTION_SELL;
        }

      return SIGNAL_DIRECTION_NONE;
     }

   // SL: Lower Bandまたは直近レンジ下限のうち、より保守的な（entryから遠い）方の外側にATRバッファを設ける。
   static double StopLossBuy(const double lower_band,const double recent_range_low,
                             const double atr,const double atr_buffer_multiple)
     {
      if(!MathIsValidNumber(lower_band) || !MathIsValidNumber(recent_range_low) ||
         !MathIsValidNumber(atr) || atr<=0.0 || atr_buffer_multiple<=0.0)
         return 0.0;
      return MathMin(lower_band,recent_range_low)-atr*atr_buffer_multiple;
     }

   static double StopLossSell(const double upper_band,const double recent_range_high,
                              const double atr,const double atr_buffer_multiple)
     {
      if(!MathIsValidNumber(upper_band) || !MathIsValidNumber(recent_range_high) ||
         !MathIsValidNumber(atr) || atr<=0.0 || atr_buffer_multiple<=0.0)
         return 0.0;
      return MathMax(upper_band,recent_range_high)+atr*atr_buffer_multiple;
     }

   // TP: 既定はBB Middle（basis）。将来比較用に反対側Bandも選択可能にする。
   static double TakeProfit(const ESignalDirection direction,const int mode,
                            const double basis,const double upper_band,const double lower_band)
     {
      if(mode==MEAN_REVERSION_TP_OPPOSITE_BAND)
         return (direction==SIGNAL_DIRECTION_BUY ? upper_band : lower_band);
      return basis;
     }

  };

// 保有中のレンジポジションに対する強制決済条件専用（エントリー条件のCMeanReversionEntryRulesとは
// 意図的に別クラスへ分離、2026-08-24追記）。CI/ADXの一時的な閾値跨ぎのような弱いシグナルでは
// 反応せず、レンジ崩壊を示す強い条件（実際の価格構造ブレイク、またはADX急伸）でのみ決済する。
class CMeanReversionExitRules
  {
public:
   // レンジ高値/安値（直近N本の実際のスイング高安値、Bollinger Bandのような統計的構成物ではない）を
   // 確定足Closeで明確にブレイクしたか（保有ポジション方向への逆行）。
   static bool IsRangeBreak(const ESignalDirection position_direction,const double confirmed_close,
                            const double recent_range_low,const double recent_range_high)
     {
      if(!MathIsValidNumber(confirmed_close) || !MathIsValidNumber(recent_range_low) || !MathIsValidNumber(recent_range_high))
         return false;
      if(position_direction==SIGNAL_DIRECTION_BUY) return confirmed_close<recent_range_low;
      if(position_direction==SIGNAL_DIRECTION_SELL) return confirmed_close>recent_range_high;
      return false;
     }

   // ADXがadx_thresholdを超え、かつ直近確定足間で上昇中（強いトレンドの急発生を示す）。
   // 単純な閾値跨ぎ（一時的な上下動）では反応しないよう、上昇方向であることも同時に要求する。
   static bool IsAdxSurging(const double current_adx,const double previous_adx,const double adx_threshold)
     {
      if(!MathIsValidNumber(current_adx) || !MathIsValidNumber(previous_adx) || adx_threshold<=0.0)
         return false;
      return current_adx>adx_threshold && current_adx>previous_adx;
     }

   // BB Widthが過去N本平均のexpansion_ratio倍以上に急拡大したか（レンジ状態からの逸脱）。
   static bool IsBbWidthExpanded(const double current_width,const double average_width,const double expansion_ratio)
     {
      if(!MathIsValidNumber(current_width) || !MathIsValidNumber(average_width) ||
         current_width<0.0 || average_width<=0.0 || expansion_ratio<=1.0)
         return false;
      return current_width>=average_width*expansion_ratio;
     }
  };

class CMeanReversionStrategy : public IStrategy
  {
private:
   SEaConfig m_config;
   int m_bb_handle;
   int m_atr_handle;
   int m_adx_handle;
   bool m_initialized;

   bool ReadIndicator(const int handle,const int shift,double &value)
     {
      if(handle==INVALID_HANDLE || BarsCalculated(handle)<=shift)
         return false;
      double values[1];
      if(CopyBuffer(handle,0,shift,1,values)!=1)
         return false;
      value=values[0];
      return MathIsValidNumber(value);
     }

   bool ReadBandBuffer(const int buffer_index,const int shift,double &value)
     {
      if(m_bb_handle==INVALID_HANDLE || BarsCalculated(m_bb_handle)<=shift)
         return false;
      double values[1];
      if(CopyBuffer(m_bb_handle,buffer_index,shift,1,values)!=1)
         return false;
      value=values[0];
      return MathIsValidNumber(value);
     }

   // Choppiness Index算出用の入力データを、直近confirmed bar（shift=1）からperiod本分読み取る。
   // ATRインジケーターの平滑化済み値をTrue Range代用として合算する簡略実装（既存ATRハンドルの
   // 再利用によりインジケーターを増やさない設計を優先した近似、詳細はTASKS.md参照）。
   bool ReadChoppinessInputs(double &atr_sum,double &highest_high,double &lowest_low)
     {
      const int period=m_config.mean_reversion_choppiness_period;
      double atr_values[];
      if(m_atr_handle==INVALID_HANDLE || BarsCalculated(m_atr_handle)<=period ||
         CopyBuffer(m_atr_handle,0,1,period,atr_values)!=period)
         return false;
      atr_sum=0.0;
      for(int i=0; i<period; i++)
        {
         if(!MathIsValidNumber(atr_values[i]))
            return false;
         atr_sum+=atr_values[i];
        }
      highest_high=-DBL_MAX;
      lowest_low=DBL_MAX;
      for(int shift=1; shift<period+1; shift++)
        {
         const double high=iHigh(m_config.symbol,m_config.entry_timeframe,shift);
         const double low=iLow(m_config.symbol,m_config.entry_timeframe,shift);
         if(high<=0.0 || low<=0.0)
            return false;
         if(high>highest_high) highest_high=high;
         if(low<lowest_low) lowest_low=low;
        }
      return highest_high>-DBL_MAX && lowest_low<DBL_MAX;
     }

   // 直近レンジ高安値（SL算出用）。BB期間と同じ窓（確定足のみ）を参照する。
   bool ReadRecentRange(const int period,double &highest_high,double &lowest_low)
     {
      if(period<1) return false;
      highest_high=-DBL_MAX;
      lowest_low=DBL_MAX;
      for(int shift=1; shift<period+1; shift++)
        {
         const double high=iHigh(m_config.symbol,m_config.entry_timeframe,shift);
         const double low=iLow(m_config.symbol,m_config.entry_timeframe,shift);
         if(high<=0.0 || low<=0.0)
            return false;
         if(high>highest_high) highest_high=high;
         if(low<lowest_low) lowest_low=low;
        }
      return highest_high>-DBL_MAX && lowest_low<DBL_MAX;
     }

   // Reentry判定用の窓データ（Close・Lower/Upper Band）を、shift=1からmax_reentry_bars+2本分
   // 読み取る。closes[0]/lower_bands[0]/upper_bands[0]がshift=1（直近確定足）に対応する。
   bool ReadReentryWindow(const int max_reentry_bars,double &closes[],double &lower_bands[],double &upper_bands[])
     {
      if(max_reentry_bars<1) return false;
      const int size=max_reentry_bars+2;
      ArrayResize(closes,size);
      ArrayResize(lower_bands,size);
      ArrayResize(upper_bands,size);
      for(int i=0; i<size; i++)
        {
         const int shift=i+1;
         const double close=iClose(m_config.symbol,m_config.entry_timeframe,shift);
         double lower,upper;
         if(close<=0.0 || !ReadBandBuffer(2,shift,lower) || !ReadBandBuffer(1,shift,upper))
            return false;
         closes[i]=close;
         lower_bands[i]=lower;
         upper_bands[i]=upper;
        }
      return true;
     }

   // BB Width（Upper-Lower）の過去N本平均（確定足のみ、shift=1..period）。
   bool ReadBbWidthBaseline(const int period,double &average_width)
     {
      if(period<2 || m_bb_handle==INVALID_HANDLE || BarsCalculated(m_bb_handle)<=period)
         return false;
      double upper_values[],lower_values[];
      if(CopyBuffer(m_bb_handle,1,1,period,upper_values)!=period ||
         CopyBuffer(m_bb_handle,2,1,period,lower_values)!=period)
         return false;
      double sum=0.0;
      for(int i=0; i<period; i++)
        {
         if(!MathIsValidNumber(upper_values[i]) || !MathIsValidNumber(lower_values[i]))
            return false;
         sum+=(upper_values[i]-lower_values[i]);
        }
      average_width=sum/period;
      return true;
     }

   void SetDataError(SSignalResult &result,const string code,const string message)
     {
      result.status=SIGNAL_STATUS_ERROR;
      result.reason_code=code;
      result.reason=message;
     }

public:
   CMeanReversionStrategy(void)
     {
      m_bb_handle=INVALID_HANDLE;
      m_atr_handle=INVALID_HANDLE;
      m_adx_handle=INVALID_HANDLE;
      m_initialized=false;
     }

   virtual string Name(void) const { return "MeanReversionStrategyV1"; }

   virtual bool Initialize(const SEaConfig &config,string &error)
     {
      Shutdown();
      m_config=config;
      error="";
      if(!SymbolSelect(m_config.symbol,true))
        { error="SYMBOL_SELECT_FAILED"; return false; }

      m_bb_handle=iBands(m_config.symbol,m_config.entry_timeframe,m_config.mean_reversion_bb_period,0,
                         m_config.mean_reversion_bb_deviation,PRICE_CLOSE);
      m_atr_handle=iATR(m_config.symbol,m_config.entry_timeframe,m_config.atr_period);
      m_adx_handle=iADX(m_config.symbol,m_config.entry_timeframe,m_config.adx_period);

      if(m_bb_handle==INVALID_HANDLE || m_atr_handle==INVALID_HANDLE || m_adx_handle==INVALID_HANDLE)
        {
         error="INDICATOR_HANDLE_FAILED";
         Shutdown();
         return false;
        }
      m_initialized=true;
      return true;
     }

   virtual void Shutdown(void)
     {
      if(m_bb_handle!=INVALID_HANDLE) IndicatorRelease(m_bb_handle);
      if(m_atr_handle!=INVALID_HANDLE) IndicatorRelease(m_atr_handle);
      if(m_adx_handle!=INVALID_HANDLE) IndicatorRelease(m_adx_handle);
      m_bb_handle=INVALID_HANDLE;
      m_atr_handle=INVALID_HANDLE;
      m_adx_handle=INVALID_HANDLE;
      m_initialized=false;
     }

   virtual bool Evaluate(SSignalResult &result)
     {
      ResetSignalResult(result);
      result.symbol=m_config.symbol;
      result.timeframe=m_config.entry_timeframe;
      if(!m_initialized)
        { SetDataError(result,"STRATEGY_NOT_INITIALIZED","Strategy is not initialized."); return false; }

      MqlRates entry_bar[1];
      if(CopyRates(m_config.symbol,m_config.entry_timeframe,1,1,entry_bar)!=1 ||
         entry_bar[0].time<=0 || entry_bar[0].close<=0.0)
        { SetDataError(result,"MARKET_DATA_UNAVAILABLE","Closed-bar price data is unavailable."); return false; }
      result.signal_bar_time=entry_bar[0].time;

      double adx;
      if(!ReadIndicator(m_adx_handle,1,adx))
        { SetDataError(result,"MARKET_DATA_UNAVAILABLE","ADX data is unavailable."); return false; }

      double atr_sum,choppiness_high,choppiness_low;
      if(!ReadChoppinessInputs(atr_sum,choppiness_high,choppiness_low))
        { SetDataError(result,"MARKET_DATA_UNAVAILABLE","Choppiness index inputs are unavailable."); return false; }
      const double choppiness=CChoppinessIndex::Calculate(atr_sum,choppiness_high,choppiness_low,
                                                            m_config.mean_reversion_choppiness_period);
      result.adx=adx;

      if(!CMeanReversionEntryRules::IsRangeFilterActive(choppiness,adx,m_config.mean_reversion_choppiness_min,
                                                    m_config.mean_reversion_adx_max))
        {
         result.reason_code="NOT_RANGE_MARKET";
         result.reason=StringFormat("Range filter not active: choppiness=%.2f adx=%.2f.",choppiness,adx);
         return true;
        }

      double basis,atr;
      if(!ReadBandBuffer(0,1,basis) || !ReadIndicator(m_atr_handle,1,atr) || atr<=0.0)
        { SetDataError(result,"MARKET_DATA_UNAVAILABLE","Bollinger Band or ATR data is unavailable."); return false; }

      result.atr=atr;

      const double point=SymbolInfoDouble(m_config.symbol,SYMBOL_POINT);
      const int digits=(int)SymbolInfoInteger(m_config.symbol,SYMBOL_DIGITS);
      if(point<=0.0)
        { SetDataError(result,"INVALID_SYMBOL_DATA","Point is invalid."); return false; }

      const int max_reentry_bars=m_config.mean_reversion_max_reentry_bars;
      double window_closes[],window_lower_bands[],window_upper_bands[];
      if(!ReadReentryWindow(max_reentry_bars,window_closes,window_lower_bands,window_upper_bands))
        { SetDataError(result,"MARKET_DATA_UNAVAILABLE","Reentry window Band data is unavailable."); return false; }

      const double close=entry_bar[0].close;
      const double entry_lower=window_lower_bands[0];
      const double entry_upper=window_upper_bands[0];
      const ESignalDirection direction=CMeanReversionEntryRules::EntryDirectionWithReentry(
         window_closes,window_lower_bands,window_upper_bands,max_reentry_bars);
      if(direction==SIGNAL_DIRECTION_NONE)
        { result.reason_code="RANGE_REVERSAL_PATTERN_NOT_FOUND"; result.reason="No band break-and-return pattern matched within the reentry window."; return true; }

      double recent_high,recent_low;
      if(!ReadRecentRange(m_config.mean_reversion_bb_period,recent_high,recent_low))
        { SetDataError(result,"MARKET_DATA_UNAVAILABLE","Recent range data is unavailable."); return false; }

      result.status=SIGNAL_STATUS_CANDIDATE;
      result.direction=direction;
      result.entry_pattern=ENTRY_PATTERN_MEAN_REVERSION;
      // EAController::CandidateForPosition()はTRADE_CLOSED時点でDeal Comment（entry_bar時刻のみ）から
      // "{ea_id}-{symbol}-{bar_time}"形式のIDを復元するため、トレンドフォロー戦略と同一形式を使う
      // 必要がある（戦略種別はresult.entry_patternで区別済みのため、ID自体への追加識別子は不要）。
      // 両戦略は同一確定足で排他的にしか候補を生成しないため、ID衝突は発生しない。
      result.trade_candidate_id=StringFormat("%s-%s-%I64d",m_config.ea_id,m_config.symbol,(long)entry_bar[0].time);
      result.entry_price=NormalizeDouble(close,digits);
      if(direction==SIGNAL_DIRECTION_BUY)
        {
         result.stop_loss=NormalizeDouble(
            CMeanReversionEntryRules::StopLossBuy(entry_lower,recent_low,atr,m_config.mean_reversion_stop_atr_multiple),digits);
         result.take_profit=NormalizeDouble(
            CMeanReversionEntryRules::TakeProfit(direction,m_config.mean_reversion_take_profit_mode,basis,entry_upper,entry_lower),digits);
        }
      else
        {
         result.stop_loss=NormalizeDouble(
            CMeanReversionEntryRules::StopLossSell(entry_upper,recent_high,atr,m_config.mean_reversion_stop_atr_multiple),digits);
         result.take_profit=NormalizeDouble(
            CMeanReversionEntryRules::TakeProfit(direction,m_config.mean_reversion_take_profit_mode,basis,entry_upper,entry_lower),digits);
        }
      if(result.stop_loss<=0.0 || result.take_profit<=0.0 ||
         (direction==SIGNAL_DIRECTION_BUY && !(result.stop_loss<result.entry_price && result.take_profit>result.entry_price)) ||
         (direction==SIGNAL_DIRECTION_SELL && !(result.stop_loss>result.entry_price && result.take_profit<result.entry_price)))
        {
         SetDataError(result,"INVALID_TRADE_GEOMETRY","Calculated entry, stop, and target geometry is invalid.");
         return false;
        }
      result.risk_reward_ratio=MathAbs(result.take_profit-result.entry_price)/MathAbs(result.entry_price-result.stop_loss);
      result.reason_code="RANGE_REVERSAL_ENTRY";
      result.reason=StringFormat("Choppiness=%.2f; ADX=%.2f; band break-and-return.",choppiness,adx);
      return true;
     }

   // 保有中のレンジポジションについて、レンジ崩壊を示す「強い」条件（レンジ高値/安値の確定足
   // ブレイク、またはADX急伸）、あるいはBB Width急拡大のいずれかを検知したら決済すべきと判断する
   // （保有継続の前提が崩れたかどうかの再検証専用）。エントリー条件のRange Filter（CI/ADX閾値）は
   // 新規エントリーの成立条件としてのみ用いており、保有中ポジションの決済判断には使わない
   // （CI/ADXの一時的な閾値跨ぎ1本だけを理由に決済すると過剰反応になるため、2026-08-24仕様変更）。
   // トレンドフォロー戦略のIsTrendStillValidと同じ考え方: データ取得不能時はfalse-safe（true=保有継続）。
   bool IsRangeStillValid(const ESignalDirection position_direction,string &reason_code)
     {
      reason_code="";
      if(!m_initialized)
        { reason_code="STRATEGY_NOT_INITIALIZED"; return true; }

      const double close=iClose(m_config.symbol,m_config.entry_timeframe,1);
      double recent_high,recent_low;
      if(close<=0.0 || !ReadRecentRange(m_config.mean_reversion_bb_period,recent_high,recent_low))
        { reason_code="MARKET_DATA_UNAVAILABLE"; return true; }
      if(CMeanReversionExitRules::IsRangeBreak(position_direction,close,recent_low,recent_high))
        { reason_code="RANGE_BREAK"; return false; }

      double adx_now,adx_previous;
      if(!ReadIndicator(m_adx_handle,1,adx_now) || !ReadIndicator(m_adx_handle,2,adx_previous))
        { reason_code="MARKET_DATA_UNAVAILABLE"; return true; }
      if(CMeanReversionExitRules::IsAdxSurging(adx_now,adx_previous,m_config.mean_reversion_forced_exit_adx_threshold))
        { reason_code="ADX_SURGE"; return false; }

      double upper,lower,average_width;
      if(!ReadBandBuffer(1,1,upper) || !ReadBandBuffer(2,1,lower) ||
         !ReadBbWidthBaseline(m_config.mean_reversion_bb_width_lookback,average_width))
        { reason_code="MARKET_DATA_UNAVAILABLE"; return true; }
      const double current_width=upper-lower;
      if(CMeanReversionExitRules::IsBbWidthExpanded(current_width,average_width,m_config.mean_reversion_bb_width_expansion_ratio))
        { reason_code="BB_WIDTH_EXPANSION"; return false; }

      return true;
     }
  };

#endif
