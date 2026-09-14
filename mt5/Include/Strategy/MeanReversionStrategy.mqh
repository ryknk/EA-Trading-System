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

   // Tokyoセッション判定（2026-08-26追加、ユーザー依頼）。python.analysis.trade_breakdown.
   // SESSION_BOUNDARIESのTokyo区分（hour∈[0,8)∪[22,24)）と同一の境界を用いる（DST未考慮の
   // 簡略化、既存のSession別分析との整合性を優先。hour_utcはbar_timeをTimeToStructした値を渡す）。
   static bool IsTokyoSession(const int hour_utc)
     {
      return hour_utc<8 || hour_utc>=22;
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
// 意図的に別クラスへ分離、2026-08-24追記）。
//
// 2026-08-25仕様変更（ユーザー指示）: Range Filter解除だけを理由とした即時決済（旧IsRangeQualityLost、
// 強制決済専用の別閾値によるCI/ADX判定）は、レンジが一時的に崩れただけでもTP到達前に決済される
// 頻度が高すぎたため廃止した。Range Filterの判定条件自体（CMeanReversionEntryRules::
// IsRangeFilterActive、エントリーと完全に同一の閾値）は変更せず、保有ポジションの状態機械
// （CMeanReversionStrategy::IsRangeStillValid）が、Range Filter解除を「即決済」ではなく
// 「警戒状態への移行」として扱う。
//
// 2026-08-26仕様変更（ユーザー指示）: 当初は確定足ベースの猶予期間（最大N本以内のブレイク確認）
// だったが、猶予期間が短くブレイクを十分に検知できていなかったため、警戒状態中はBid/Ask（実勢
// 価格）を毎Tick監視し、本クラスのIsTickRangeBreak（ATRバッファ付きのレンジ高値/安値ブレイク）が
// 実時間で`mean_reversion_break_confirm_seconds`秒以上継続した場合のみ強制決済する方式へ変更した。
class CMeanReversionExitRules
  {
public:
   // レンジ高値/安値（直近N本の実際のスイング高安値、Bollinger Bandのような統計的構成物ではない）を
   // 実勢価格（Bid/Ask）がATRバッファを含めて明確にブレイクしたか（保有ポジション方向への逆行）。
   // 2026-08-26仕様変更（ユーザー指示）: 確定足Close基準から、警戒状態中はTick（Bid/Ask）基準へ
   // 変更した。BUY: Bid<RangeLow-ATR×break_atr_multiplier、SELL: Ask>RangeHigh+ATR×break_atr_multiplier。
   // 継続確認（実時間で何秒続いたか）はCMeanReversionStrategy::IsRangeStillValid側の
   // m_grace_trackerが担当し、本メソッドは「今この瞬間ブレイクしているか」のみを判定する。
   static bool IsTickRangeBreak(const ESignalDirection position_direction,const double bid,const double ask,
                                const double recent_range_low,const double recent_range_high,
                                const double atr,const double break_atr_multiplier)
     {
      if(!MathIsValidNumber(bid) || !MathIsValidNumber(ask) || bid<=0.0 || ask<=0.0 || ask<bid ||
         !MathIsValidNumber(recent_range_low) || !MathIsValidNumber(recent_range_high) ||
         !MathIsValidNumber(atr) || atr<=0.0 || break_atr_multiplier<0.0)
         return false;
      const double buffer=atr*break_atr_multiplier;
      if(position_direction==SIGNAL_DIRECTION_BUY) return bid<recent_range_low-buffer;
      if(position_direction==SIGNAL_DIRECTION_SELL) return ask>recent_range_high+buffer;
      return false;
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

// 保有中レンジポジションの「警戒状態」（Range Filter解除を検知してから、Range Filterが再成立する
// かポジションが決済されるまで）をticket単位で追跡する（2026-08-25追加、2026-08-26仕様変更で
// 猶予バー数の概念を廃止しTickベースのブレイク確認タイマーへ置き換え。ユーザー指示: 猶予期間が
// 短くブレイクを十分に検知できていなかったため、確定足の本数ではなくBid/Askを毎Tick監視し、
// ブレイク条件が実時間で一定秒数継続した場合のみ強制決済する方式へ変更した）。
// レコードが存在する＝警戒状態、存在しない＝通常状態という単純な設計とし、状態フラグを別途持たない。
// break_timer_start（0=ブレイク確認タイマー停止中）は、警戒状態中にBreakLevelを実勢価格で
// 継続的に超過している実時間を計測するための開始時刻（TimeCurrent()、Tick数ではなく実時間で
// 判定するため）。CTimeStopTracker（PositionManager.mqh）と同じ考え方だが、Strategy層が
// Trading層へ依存する構成を避けるため、レンジ戦略専用としてこのファイル内に定義する。
// EA再起動・再初期化時はこの配列が空の状態から始まるため、既存の保有ポジションは自動的に
// 「通常状態」（未警戒）から再開する（CTimeStopTrackerと同じ、安全側のfalse-safeな再初期化）。
class CRangeExitGraceTracker
  {
private:
   struct SState
     {
      ulong    ticket;
      datetime break_timer_start; // 0 = ブレイク確認タイマー停止中
     };
   SState m_states[];

   int Find(const ulong ticket)
     {
      for(int index=0; index<ArraySize(m_states); index++)
         if(m_states[index].ticket==ticket) return index;
      return -1;
     }

public:
   bool IsInAlert(const ulong ticket,datetime &break_timer_start)
     {
      const int slot=Find(ticket);
      if(slot<0) return false;
      break_timer_start=m_states[slot].break_timer_start;
      return true;
     }

   // 戻り値: 新規に警戒状態へ遷移した場合はtrue（監査ログ記録用）。既に警戒状態だった場合はfalse。
   bool EnterAlert(const ulong ticket)
     {
      if(Find(ticket)>=0) return false;
      const int last=ArraySize(m_states);
      ArrayResize(m_states,last+1);
      m_states[last].ticket=ticket;
      m_states[last].break_timer_start=0;
      return true;
     }

   // 戻り値: 実際に警戒状態を解除した場合はtrue（監査ログ記録用）。元々警戒状態でなかった場合はfalse。
   // ポジション決済時（理由を問わず）にも外部から呼び出され、状態を確実にクリアする
   // （CMeanReversionStrategy::ClearPositionState経由、2026-08-26追加、ユーザー指示）。
   bool ClearAlert(const ulong ticket)
     {
      const int slot=Find(ticket);
      if(slot<0) return false;
      const int last=ArraySize(m_states)-1;
      m_states[slot]=m_states[last];
      ArrayResize(m_states,last);
      return true;
     }

   // ブレイク確認タイマーを開始する（警戒状態でない場合、または既に開始済みの場合は何もしない）。
   void StartBreakTimer(const ulong ticket,const datetime now)
     {
      const int slot=Find(ticket);
      if(slot<0 || m_states[slot].break_timer_start>0) return;
      m_states[slot].break_timer_start=now;
     }

   // 価格がBreakLevelの内側へ戻った場合にタイマーをリセットする（警戒状態自体は解除しない）。
   void ResetBreakTimer(const ulong ticket)
     {
      const int slot=Find(ticket);
      if(slot<0) return;
      m_states[slot].break_timer_start=0;
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
   CRangeExitGraceTracker m_grace_tracker;

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

   // 直近レンジ高安値（確定足のみ）を、呼び出し元が指定したperiod本で参照する。
   // エントリー側のSL算出ではmean_reversion_bb_period（Band期間と共用）、決済側の
   // IsRangeBreak判定ではmean_reversion_range_break_lookback（エントリーとは独立、
   // 2026-08-25追加）を使う。
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

      // Tokyoセッション限定（2026-08-26追加、ユーザー依頼）。既定は無効（従来どおり全セッションで
      // エントリー判定を行う）。python.analysis.trade_breakdown由来の分析で、Tokyoセッションのみが
      // 唯一プラスだった一方London/Overlapが特に悪かったことを踏まえた検証用オプション。
      if(m_config.mean_reversion_restrict_to_tokyo_session)
        {
         MqlDateTime entry_bar_parts;
         TimeToStruct(entry_bar[0].time,entry_bar_parts);
         if(!CMeanReversionEntryRules::IsTokyoSession(entry_bar_parts.hour))
           {
            result.reason_code="OUTSIDE_TOKYO_SESSION";
            result.reason=StringFormat("Entry bar hour=%d is outside the Tokyo session window.",entry_bar_parts.hour);
            return true;
           }
        }

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

   // 保有中のレンジポジションについて、決済すべきかを判断する（保有継続の前提が崩れたかどうかの
   // 再検証専用）。トレンドフォロー戦略のIsTrendStillValidと同じ考え方: データ取得不能時は
   // false-safe（true=保有継続）。EAController::EvaluateMeanReversionForcedExits経由でOnTick毎に
   // 呼び出されるため、本メソッド自体が既にTickベースで評価されている。
   //
   // 2026-08-25/26仕様変更（ユーザー指示）: Range Filter（CI>60かつADX<25、エントリーと完全に
   // 同一の判定・閾値、変更しない）が解除されただけでは即決済しない。解除を検知したら「警戒状態」へ
   // 移行する。当初は「確定足ベースで最大N本の猶予期間」だったが、猶予期間が短くブレイクを
   // 十分に検知できなかったため、確定足ではなく実勢価格（Bid/Ask）を毎Tick監視し、ブレイク条件
   // （BUY: Bid<RangeLow-ATR×BreakAtrMultiplier、SELL: Ask>RangeHigh+ATR×BreakAtrMultiplier）が
   // 実時間で`mean_reversion_break_confirm_seconds`秒以上継続した場合のみ強制決済する方式へ
   // 変更した（Tick数ではなく実時間、TimeCurrent()はStrategy Tester上でもシミュレート時刻を
   // 正しく返すため使用する）。継続中に価格がBreakLevelの内側へ戻ればタイマーをリセットし、
   // 再度ブレイクすれば新たにタイマーが開始する。Range Filterが再成立すれば警戒状態・タイマーとも
   // 解除して通常状態へ復帰する。BB Width急拡大は警戒状態と独立した、常時有効なボラティリティ
   // ベースの強制決済条件として維持する（変更なし）。複数ポジションが存在する場合、警戒状態と
   // タイマーはm_grace_tracker内でticket単位に独立管理される。
   //
   // alert_transition（2026-08-25追加、ユーザー依頼）: 警戒状態の遷移が今回発生した場合のみ
   // "ALERT_ENTERED"/"ALERT_CLEARED_FILTER_REACTIVATED"を設定する（それ以外は空文字列）。
   // 呼び出し元（EAController）が監査ログ（RANGE_ALERT）へ記録するための観測性向上専用の出力であり、
   // 決済判断（戻り値・reason_code）そのものには影響しない。決済に至る遷移
   // （BB_WIDTH_EXPANSION・TICK_BREAK_EXIT）は既存のRANGE_EXIT監査で捕捉済みのため、
   // ここでは設定しない（二重記録を避ける）。
   bool IsRangeStillValid(const ulong ticket,const ESignalDirection position_direction,string &reason_code,
                          string &alert_transition)
     {
      reason_code="";
      alert_transition="";
      if(!m_initialized)
        { reason_code="STRATEGY_NOT_INITIALIZED"; return true; }

      double upper,lower,average_width;
      if(!ReadBandBuffer(1,1,upper) || !ReadBandBuffer(2,1,lower) ||
         !ReadBbWidthBaseline(m_config.mean_reversion_bb_width_lookback,average_width))
        { reason_code="MARKET_DATA_UNAVAILABLE"; return true; }
      const double current_width=upper-lower;
      if(CMeanReversionExitRules::IsBbWidthExpanded(current_width,average_width,m_config.mean_reversion_bb_width_expansion_ratio))
        { m_grace_tracker.ClearAlert(ticket); reason_code="BB_WIDTH_EXPANSION"; return false; }

      double adx;
      double atr_sum,choppiness_high,choppiness_low;
      if(!ReadIndicator(m_adx_handle,1,adx) || !ReadChoppinessInputs(atr_sum,choppiness_high,choppiness_low))
        { reason_code="MARKET_DATA_UNAVAILABLE"; return true; }
      const double choppiness=CChoppinessIndex::Calculate(atr_sum,choppiness_high,choppiness_low,
                                                            m_config.mean_reversion_choppiness_period);
      const bool range_filter_active=CMeanReversionEntryRules::IsRangeFilterActive(
         choppiness,adx,m_config.mean_reversion_choppiness_min,m_config.mean_reversion_adx_max);

      if(range_filter_active)
        {
         // Range Filterが再成立。警戒状態であれば解除し（ブレイク確認タイマーも一体で消える）、
         // 通常状態へ復帰する。
         if(m_grace_tracker.ClearAlert(ticket))
            alert_transition="ALERT_CLEARED_FILTER_REACTIVATED";
         return true;
        }

      datetime break_timer_start;
      if(!m_grace_tracker.IsInAlert(ticket,break_timer_start))
        {
         // Range Filter解除を検知した最初のTick。ここでは決済せず警戒状態を開始する
         // （ブレイク確認タイマーはまだ開始しない、停止中=0のまま）。
         m_grace_tracker.EnterAlert(ticket);
         break_timer_start=0;
         alert_transition="ALERT_ENTERED";
        }

      // Tick監視: 確定足ではなくBid/Ask（実勢価格）でレンジブレイクを判定する。RangeLow/RangeHigh
      // はmean_reversion_range_break_lookback本の確定足高安値（既存パラメータを再利用）。
      double atr;
      double recent_high,recent_low;
      MqlTick tick;
      if(!ReadIndicator(m_atr_handle,1,atr) || atr<=0.0 ||
         !ReadRecentRange(m_config.mean_reversion_range_break_lookback,recent_high,recent_low) ||
         !SymbolInfoTick(m_config.symbol,tick) || tick.bid<=0.0 || tick.ask<=0.0 || tick.ask<tick.bid)
        { reason_code="MARKET_DATA_UNAVAILABLE"; return true; } // データ不能時はタイマーへ触れずfalse-safe

      const bool broken=CMeanReversionExitRules::IsTickRangeBreak(position_direction,tick.bid,tick.ask,
         recent_low,recent_high,atr,m_config.mean_reversion_break_atr_multiplier);

      if(!broken)
        {
         // 価格がBreakLevelの内側へ戻った（または一度もブレイクしていない）。タイマーをリセットする。
         m_grace_tracker.ResetBreakTimer(ticket);
         return true;
        }

      const datetime now=TimeCurrent();
      if(break_timer_start<=0)
        {
         // ブレイク条件を初めて（またはリセット後に再び）満たした。確認タイマーを開始する。
         m_grace_tracker.StartBreakTimer(ticket,now);
         return true;
        }
      if(now-break_timer_start>=m_config.mean_reversion_break_confirm_seconds)
        {
         // ブレイクがBreakConfirmSeconds以上、実時間で継続して確認された。強制決済する。
         m_grace_tracker.ClearAlert(ticket);
         reason_code="TICK_BREAK_EXIT";
         return false;
        }
      return true; // タイマー継続中（BreakConfirmSecondsに未到達）。
     }

   // ポジション決済時に外部（EAController::OnTradeTransaction）から呼び出し、警戒状態・
   // ブレイク確認タイマーを確実にクリアする（2026-08-26追加、ユーザー指示: 決済理由を問わず、
   // 決済後は必ず状態をクリアする）。追跡されていないticketに対しては安全なno-op。
   void ClearPositionState(const ulong ticket)
     {
      m_grace_tracker.ClearAlert(ticket);
     }
  };

#endif
