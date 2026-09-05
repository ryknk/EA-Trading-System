#ifndef EA_TRADING_SYSTEM_POSITION_MANAGER_MQH
#define EA_TRADING_SYSTEM_POSITION_MANAGER_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/Trading/OrderManager.mqh>

class CPositionProtectionRules
  {
public:
   // Bid/Askそのものの健全性チェック（週末クローズ中の陳腐化・欠落Tick等でbid<=0/ask<=0/
   // ask<bid（クロス）になりうる）。HasValidProtectiveStopと成行決済系メソッドの両方から
   // 共通で使う、成行注文の価格として使用可能かどうかの判定。
   static bool HasValidMarketData(const double bid,const double ask)
     {
      return bid>0.0 && ask>0.0 && ask>=bid;
     }

   static bool HasValidProtectiveStop(const ENUM_POSITION_TYPE type,const double bid,
                                      const double ask,const double stop_loss)
     {
      if(!HasValidMarketData(bid,ask) || stop_loss<=0.0)
         return false;
      if(type==POSITION_TYPE_BUY) return stop_loss<bid;
      if(type==POSITION_TYPE_SELL) return stop_loss>ask;
      return false;
     }

   static bool IsManagedPosition(const long position_magic,const ulong configured_magic)
     {
      return position_magic==(long)configured_magic;
     }

   // 複数戦略が異なるMagic Numberでポジションを識別する場合の判定（レンジ戦略追加、2026-08-24）。
   // secondary_magic=0は「セカンダリ戦略なし」を意味し、primaryのみで判定する。
   static bool IsManagedPosition(const long position_magic,const ulong configured_magic,const ulong secondary_magic)
     {
      if(position_magic==(long)configured_magic) return true;
      return secondary_magic!=0 && position_magic==(long)secondary_magic;
     }
  };

class CBreakevenStopRules
  {
public:
   // 含み益が「建値から当初SLまでの距離（初期リスク）」のtrigger_r_multiple倍に達したかを判定する。
   // current_slが既に建値以上（BUY: sl>=建値、SELL: sl<=建値）の場合はrisk_distance<=0となり、
   // 既に建値へ移動済み（または当初から建値以上）とみなして対象外とする（べき等性を状態フラグなしで担保）。
   static bool ShouldMoveToBreakeven(const ENUM_POSITION_TYPE type,const double open_price,
                                     const double current_sl,const double bid,const double ask,
                                     const double trigger_r_multiple)
     {
      if(trigger_r_multiple<=0.0 || current_sl<=0.0 || open_price<=0.0 || bid<=0.0 || ask<=0.0)
         return false;
      double risk_distance,profit_distance;
      if(type==POSITION_TYPE_BUY)
        {
         risk_distance=open_price-current_sl;
         profit_distance=bid-open_price;
        }
      else if(type==POSITION_TYPE_SELL)
        {
         risk_distance=current_sl-open_price;
         profit_distance=open_price-ask;
        }
      else
         return false;
      if(risk_distance<=0.0)
         return false;
      return profit_distance>=risk_distance*trigger_r_multiple;
     }
  };

// ATRトレーリングストップ判定の純粋関数群（単体テスト対象）。建値ストップと異なり、
// 開始判定には「当初SL（エントリー時点、以降のSL変更の影響を受けない固定値）」を使う。
// 現在SLを基準にすると、一度トレーリングでSLを動かした後は risk_distance が変動し、
// 判定が不安定になるため（建値ストップのべき等性トリックとは異なる設計が必要）。
class CAtrTrailingStopRules
  {
public:
   // 含み益が「建値〜当初SL距離（初期リスク）」のtrigger_r_multiple倍に達したかを判定する。
   static bool ShouldTrail(const ENUM_POSITION_TYPE type,const double open_price,
                           const double initial_stop_loss,const double bid,const double ask,
                           const double trigger_r_multiple)
     {
      if(trigger_r_multiple<=0.0 || initial_stop_loss<=0.0 || open_price<=0.0 || bid<=0.0 || ask<=0.0)
         return false;
      double risk_distance,profit_distance;
      if(type==POSITION_TYPE_BUY)
        {
         risk_distance=open_price-initial_stop_loss;
         profit_distance=bid-open_price;
        }
      else if(type==POSITION_TYPE_SELL)
        {
         risk_distance=initial_stop_loss-open_price;
         profit_distance=open_price-ask;
        }
      else
         return false;
      if(risk_distance<=0.0)
         return false;
      return profit_distance>=risk_distance*trigger_r_multiple;
     }

   // 現在Bid/AskからATR×atr_multipleだけ離れた位置を候補SLとして返す。atr<=0またはatr_multiple<=0なら0を返す。
   static double ComputeTrailingStopLoss(const ENUM_POSITION_TYPE type,const double bid,const double ask,
                                         const double atr,const double atr_multiple)
     {
      if(atr<=0.0 || atr_multiple<=0.0 || bid<=0.0 || ask<=0.0)
         return 0.0;
      const double distance=atr*atr_multiple;
      if(type==POSITION_TYPE_BUY)  return bid-distance;
      if(type==POSITION_TYPE_SELL) return ask+distance;
      return 0.0;
     }

   // 候補SLが現在のSLより保護方向（利益を確定する方向）へ動いているかを判定する。
   // トレーリングは保護方向にのみ追従し、緩める方向へは絶対に動かさない。
   static bool IsMoreProtective(const ENUM_POSITION_TYPE type,const double candidate_sl,const double current_sl)
     {
      if(candidate_sl<=0.0) return false;
      if(current_sl<=0.0) return true;
      if(type==POSITION_TYPE_BUY)  return candidate_sl>current_sl;
      if(type==POSITION_TYPE_SELL) return candidate_sl<current_sl;
      return false;
     }
  };

class CTimeStopRules
  {
public:
   // 経過本数（entry_timeframeの確定足換算）が上限に達したかを判定する。max_holding_barsが0以下なら常にfalse。
   static bool HasExceededMaxHoldingBars(const int elapsed_closed_bars,const int max_holding_bars)
     {
      return max_holding_bars>0 && elapsed_closed_bars>=max_holding_bars;
     }

   // 保有中に追跡した含み益ピーク（peak_favorable_price）が「建値〜当初SL距離（初期リスク）」の
   // min_r_multiple倍に到達しているかを判定する。CBreakevenStopRules::ShouldMoveToBreakevenと
   // 同じ距離計算だが、現在値ではなく保有中の最高値/最安値（ピーク）を用いる点が異なる。
   // initial_stop_lossは建値ストップ等によるSL変更の影響を受けない、エントリー時点のSLを渡すこと。
   static bool HasReachedMinMfeR(const ENUM_POSITION_TYPE type,const double open_price,
                                 const double initial_stop_loss,const double peak_favorable_price,
                                 const double min_r_multiple)
     {
      if(min_r_multiple<=0.0 || initial_stop_loss<=0.0 || open_price<=0.0)
         return false;
      double risk_distance,favorable_distance;
      if(type==POSITION_TYPE_BUY)
        {
         risk_distance=open_price-initial_stop_loss;
         favorable_distance=peak_favorable_price-open_price;
        }
      else if(type==POSITION_TYPE_SELL)
        {
         risk_distance=initial_stop_loss-open_price;
         favorable_distance=open_price-peak_favorable_price;
        }
      else
         return false;
      if(risk_distance<=0.0)
         return false;
      return favorable_distance>=risk_distance*min_r_multiple;
     }
  };

// Time Stop判定専用のピーク含み益（価格ベース）追跡。CTradeAnalyticsTracker（分析専用・売買判断に不使用）
// とは別系統で、こちらはTime Stop決済の可否という売買判断に直接使用する。当初SL（initial_stop_loss）は
// 初回検知時に固定し、以降のSL変更（建値ストップ等）で判定基準がぶれないようにする。
class CTimeStopTracker
  {
private:
   struct SState
     {
      ulong  ticket;
      double initial_stop_loss;
      double peak_favorable_price;
     };
   SState m_states[];

   int Find(const ulong ticket)
     {
      for(int index=0; index<ArraySize(m_states); index++)
         if(m_states[index].ticket==ticket) return index;
      return -1;
     }

public:
   // 現在値でピークを更新し（初回検知時は当初SL・現在値で初期化）、判定に必要な値を返す。
   void Update(const ulong ticket,const ENUM_POSITION_TYPE type,const double current_stop_loss,
               const double current_price,double &initial_stop_loss,double &peak_favorable_price)
     {
      int slot=Find(ticket);
      if(slot<0)
        {
         slot=ArraySize(m_states);
         ArrayResize(m_states,slot+1);
         m_states[slot].ticket=ticket;
         m_states[slot].initial_stop_loss=current_stop_loss;
         m_states[slot].peak_favorable_price=current_price;
        }
      else
        {
         if(type==POSITION_TYPE_BUY && current_price>m_states[slot].peak_favorable_price)
            m_states[slot].peak_favorable_price=current_price;
         if(type==POSITION_TYPE_SELL && current_price<m_states[slot].peak_favorable_price)
            m_states[slot].peak_favorable_price=current_price;
        }
      initial_stop_loss=m_states[slot].initial_stop_loss;
      peak_favorable_price=m_states[slot].peak_favorable_price;
     }

   void Remove(const ulong ticket)
     {
      const int slot=Find(ticket);
      if(slot<0) return;
      const int last=ArraySize(m_states)-1;
      m_states[slot]=m_states[last];
      ArrayResize(m_states,last);
     }
  };

class CPositionManager
  {
private:
   SEaConfig m_config;
   ulong     m_emergency_attempt_ticket;
   string    m_emergency_key_prefix;
   string    m_signal_exit_key_prefix;
   ulong     m_signal_exit_attempt_ticket;
   string    m_time_stop_key_prefix;
   ulong     m_time_stop_attempt_ticket;
   string    m_atr_trailing_initial_sl_key_prefix;
   int       m_atr_trailing_handle;
   bool      m_initialized;

   ENUM_ORDER_TYPE_FILLING FillingMode(const string symbol)
     {
      const long modes=SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE);
      if((modes & SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK) return ORDER_FILLING_FOK;
      if((modes & SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC) return ORDER_FILLING_IOC;
      return ORDER_FILLING_RETURN;
     }

   bool EmergencyClose(const ulong ticket,string &error)
     {
      error="";
      const string attempt_key=m_emergency_key_prefix+StringFormat("%I64u",ticket);
      if(ticket==m_emergency_attempt_ticket || GlobalVariableCheck(attempt_key))
        { error="EMERGENCY_CLOSE_ALREADY_ATTEMPTED"; return false; }
      if(!PositionSelectByTicket(ticket))
        { error="POSITION_SELECT_FAILED"; return false; }
      const string symbol=PositionGetString(POSITION_SYMBOL);
      const double volume=PositionGetDouble(POSITION_VOLUME);
      const ENUM_POSITION_TYPE position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      MqlTick tick;
      if(volume<=0.0 || !SymbolInfoTick(symbol,tick))
        { error="POSITION_CLOSE_DATA_UNAVAILABLE"; return false; }
      // 週末クローズ中等、Tick取得自体は成功するがbid/askが陳腐化・欠落している場合がある
      // （OANDA_HIST実績: 週跨ぎ保有ポジションでbid<=0/ask<=0/クロスにより成行決済のOrderCheckが
      // retcode=0で失敗し続け、詳細不明なまま次Tickへ持ち越されていた）。実際に発注を試みる前に
      // HasValidProtectiveStopと同じ健全性基準で弾き、原因を明示する。
      if(!CPositionProtectionRules::HasValidMarketData(tick.bid,tick.ask))
        { error="EMERGENCY_CLOSE_INVALID_MARKET_DATA"; return false; }

      MqlTradeRequest request;
      MqlTradeCheckResult check;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(check);
      ZeroMemory(result);
      request.action=TRADE_ACTION_DEAL;
      request.magic=m_config.magic_number;
      request.position=ticket;
      request.symbol=symbol;
      request.volume=volume;
      request.type=(position_type==POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY);
      request.price=(position_type==POSITION_TYPE_BUY ? tick.bid : tick.ask);
      request.deviation=m_config.max_deviation_points;
      request.type_filling=FillingMode(symbol);
      request.comment="EMERGENCY_NO_SL";
      // 根本原因（2026-08-23、OOS期間で162件のEmergencyClose失敗を調査して判明）: OrderCheckは
      // 成功時（bool戻り値true）でもretcode=0（"Done"相当、TRADE_RETCODE_DONEではない）を返す
      // ことがMQL5仕様上ある（COrderCheckRules::IsAcceptedのコメント・単体テスト参照）。本メソッドは
      // 他3箇所（ModifyStopLoss/CloseOnSignalInvalidation/CloseOnTimeStop）と異なりCOrderCheckRules::
      // IsAcceptedを使わず`retcode!=TRADE_RETCODE_DONE`のみで判定していたため、retcode=0の正当な
      // 成功ケースを常に失敗と誤判定し、EmergencyCloseが実質的に一度も成功できない状態だった
      // （保有ポジションはBroker側SLで保護され続けていたため実害はなかったが、EA自身の安全網が
      // 機能していなかった）。他3箇所と同じCOrderCheckRules::IsAcceptedへ統一する。
      ResetLastError();
      const bool check_ok=OrderCheck(request,check);
      if(!COrderCheckRules::IsAccepted(check_ok,check.retcode))
        {
         error=StringFormat("EMERGENCY_ORDER_CHECK_FAILED retcode=%u comment=%s last_error=%d price=%.5f bid=%.5f ask=%.5f",
                            check.retcode,check.comment,GetLastError(),request.price,tick.bid,tick.ask);
         return false;
        }
      ResetLastError();
      if(GlobalVariableSet(attempt_key,1.0)==0 && GetLastError()!=0)
        { error="EMERGENCY_IDEMPOTENCY_PERSIST_FAILED"; return false; }
      GlobalVariablesFlush();
      m_emergency_attempt_ticket=ticket;
      if(!OrderSend(request,result) || !COrderValidationRules::AcceptedRetcode(result.retcode))
        { error=StringFormat("EMERGENCY_CLOSE_FAILED retcode=%u comment=%s",result.retcode,result.comment); return false; }
      PrintFormat("EMERGENCY_CLOSE_SUBMITTED position=%I64u order=%I64u deal=%I64u retcode=%u reason=UNPROTECTED_POSITION",
                  ticket,result.order,result.deal,result.retcode);
      return true;
     }

   bool ModifyStopLoss(const ulong ticket,const double new_sl,string &error)
     {
      error="";
      if(!PositionSelectByTicket(ticket))
        { error="POSITION_SELECT_FAILED"; return false; }
      const string symbol=PositionGetString(POSITION_SYMBOL);
      const double take_profit=PositionGetDouble(POSITION_TP);

      MqlTradeRequest request;
      MqlTradeCheckResult check;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(check);
      ZeroMemory(result);
      request.action=TRADE_ACTION_SLTP;
      request.magic=m_config.magic_number;
      request.position=ticket;
      request.symbol=symbol;
      request.sl=new_sl;
      request.tp=take_profit;

      ResetLastError();
      const bool check_ok=OrderCheck(request,check);
      if(!COrderCheckRules::IsAccepted(check_ok,check.retcode))
        { error=StringFormat("SL_MODIFY_ORDER_CHECK_FAILED retcode=%u comment=%s",check.retcode,check.comment); return false; }
      if(!OrderSend(request,result) || !COrderValidationRules::AcceptedRetcode(result.retcode))
        { error=StringFormat("SL_MODIFY_FAILED retcode=%u comment=%s",result.retcode,result.comment); return false; }
      PrintFormat("SL_MODIFIED position=%I64u new_sl=%.8f retcode=%u",ticket,new_sl,result.retcode);
      return true;
     }

   // ポジションの当初SL（ATRトレーリング開始前の値）をGlobalVariableで一度だけ固定保存し、以降は
   // その値を返す。ATRトレーリングが現在のSLを動かした後もShouldTrailの判定基準がぶれないようにする
   // （EmergencyClose等と同じGlobalVariableべき等性パターン）。
   double InitialStopLoss(const ulong ticket,const double current_sl)
     {
      const string key=m_atr_trailing_initial_sl_key_prefix+StringFormat("%I64u",ticket);
      if(GlobalVariableCheck(key))
         return GlobalVariableGet(key);
      ResetLastError();
      GlobalVariableSet(key,current_sl);
      GlobalVariablesFlush();
      return current_sl;
     }

   // 確定足ベースのATR（shift=1）を取得する。無効時はハンドル未作成のため常にfalseを返す。
   bool ReadAtr(double &atr)
     {
      if(m_atr_trailing_handle==INVALID_HANDLE) return false;
      if(BarsCalculated(m_atr_trailing_handle)<=1) return false;
      double values[1];
      if(CopyBuffer(m_atr_trailing_handle,0,1,1,values)!=1) return false;
      atr=values[0];
      return MathIsValidNumber(atr) && atr>0.0;
     }

public:
   CPositionManager(void)
     {
      m_emergency_attempt_ticket=0;
      m_emergency_key_prefix="";
      m_signal_exit_attempt_ticket=0;
      m_time_stop_key_prefix="";
      m_time_stop_attempt_ticket=0;
      m_atr_trailing_initial_sl_key_prefix="";
      m_atr_trailing_handle=INVALID_HANDLE;
      m_initialized=false;
     }

   bool Initialize(const SEaConfig &config,string &error)
     {
      Shutdown();
      error="";
      m_config=config;
      const string identity=StringFormat("%I64d",AccountInfoInteger(ACCOUNT_LOGIN));
      m_emergency_key_prefix="ETS.POS.EMERGENCY."+identity+"."+StringFormat("%I64u",m_config.magic_number)+".";
      if(StringLen(m_emergency_key_prefix)+20>63)
        { error="POSITION_STATE_KEY_TOO_LONG"; return false; }
      m_signal_exit_key_prefix="ETS.POS.SIGNALEXIT."+identity+"."+StringFormat("%I64u",m_config.magic_number)+".";
      if(StringLen(m_signal_exit_key_prefix)+20>63)
        { error="POSITION_STATE_KEY_TOO_LONG"; return false; }
      m_time_stop_key_prefix="ETS.POS.TIMESTOP."+identity+"."+StringFormat("%I64u",m_config.magic_number)+".";
      if(StringLen(m_time_stop_key_prefix)+20>63)
        { error="POSITION_STATE_KEY_TOO_LONG"; return false; }
      m_atr_trailing_initial_sl_key_prefix="ETS.POS.ATRTRAIL."+identity+"."+StringFormat("%I64u",m_config.magic_number)+".";
      if(StringLen(m_atr_trailing_initial_sl_key_prefix)+20>63)
        { error="POSITION_STATE_KEY_TOO_LONG"; return false; }
      m_emergency_attempt_ticket=0;
      m_signal_exit_attempt_ticket=0;
      m_time_stop_attempt_ticket=0;
      if(m_config.enable_atr_trailing_stop)
        {
         if(!SymbolSelect(m_config.symbol,true))
           { error="SYMBOL_SELECT_FAILED"; return false; }
         m_atr_trailing_handle=iATR(m_config.symbol,m_config.entry_timeframe,m_config.atr_period);
         if(m_atr_trailing_handle==INVALID_HANDLE)
           { error="INDICATOR_HANDLE_FAILED"; return false; }
        }
      m_initialized=true;
      return true;
     }

   void Shutdown(void)
     {
      if(m_atr_trailing_handle!=INVALID_HANDLE) IndicatorRelease(m_atr_trailing_handle);
      m_atr_trailing_handle=INVALID_HANDLE;
     }

   bool Monitor(string &error)
     {
      error="";
      if(!m_initialized)
        { error="POSITION_MANAGER_NOT_INITIALIZED"; return false; }
      const int total=PositionsTotal();
      for(int index=0; index<total; index++)
        {
         const ulong ticket=PositionGetTicket(index);
         if(ticket==0)
           { error="POSITION_ENUMERATION_FAILED"; return false; }
         const long magic=PositionGetInteger(POSITION_MAGIC);
         if(!CPositionProtectionRules::IsManagedPosition(magic,m_config.magic_number,m_config.mean_reversion_magic_number))
            continue;
         const string symbol=PositionGetString(POSITION_SYMBOL);
         const ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         const double stop_loss=PositionGetDouble(POSITION_SL);
         MqlTick tick;
         if(!SymbolInfoTick(symbol,tick))
           { error="POSITION_TICK_UNAVAILABLE"; return false; }
         if(CPositionProtectionRules::HasValidProtectiveStop(type,tick.bid,tick.ask,stop_loss))
           {
            const double open_price=PositionGetDouble(POSITION_PRICE_OPEN);
            // 分析ではなくリスク管理: 含み益が初期リスクのtrigger_r_multiple倍に達したらSLを建値へ引き上げる。
            // 失敗しても既存の保護SLは維持されるため、Monitor()全体を失敗させず次Tickで再試行する。
            if(m_config.enable_breakeven_stop && m_config.enable_trade_mutations &&
               CBreakevenStopRules::ShouldMoveToBreakeven(type,open_price,stop_loss,
                                                          tick.bid,tick.ask,m_config.breakeven_trigger_r_multiple))
              {
               string breakeven_error;
               if(!ModifyStopLoss(ticket,open_price,breakeven_error))
                  PrintFormat("BREAKEVEN_SL_MOVE_FAILED position=%I64u code=%s",ticket,breakeven_error);
              }
            // 分析ではなくリスク管理: 含み益が初期リスクのtrigger_r_multiple倍に達したら、以降SLを
            // ATR×atr_multiple幅で保護方向にのみ追従させる。開始判定は当初SL（エントリー時点、
            // 建値ストップ等によるSL変更の影響を受けない固定値）を基準にする。失敗しても既存の
            // 保護SLは維持されるため、Monitor()全体を失敗させず次Tickで再試行する。
            double atr;
            if(m_config.enable_atr_trailing_stop && m_config.enable_trade_mutations && ReadAtr(atr))
              {
               const double initial_stop_loss=InitialStopLoss(ticket,stop_loss);
               if(CAtrTrailingStopRules::ShouldTrail(type,open_price,initial_stop_loss,
                                                     tick.bid,tick.ask,m_config.atr_trailing_trigger_r_multiple))
                 {
                  const double candidate_sl=CAtrTrailingStopRules::ComputeTrailingStopLoss(
                     type,tick.bid,tick.ask,atr,m_config.atr_trailing_atr_multiple);
                  if(CAtrTrailingStopRules::IsMoreProtective(type,candidate_sl,stop_loss))
                    {
                     string trailing_error;
                     if(!ModifyStopLoss(ticket,candidate_sl,trailing_error))
                        PrintFormat("ATR_TRAILING_SL_MOVE_FAILED position=%I64u code=%s",ticket,trailing_error);
                    }
                 }
              }
            continue;
           }

         if(!m_config.close_unprotected_positions)
           { error="UNPROTECTED_POSITION"; return false; }
         if(!m_config.enable_trade_mutations)
           { error="UNPROTECTED_POSITION_MUTATIONS_DISABLED"; return false; }
         string close_error;
         if(!EmergencyClose(ticket,close_error))
           { error=close_error; return false; }
         // Keep new entries disabled until a later tick confirms that the position is gone.
         error="EMERGENCY_CLOSE_PENDING";
         return false;
        }
      m_emergency_attempt_ticket=0;
      return true;
     }

   // エントリー根拠（トレンド/ADX）が消失した保有ポジションを、満期(SL/TP)を待たず市場成行で決済する。
   // reason_codeはCTrendFollowingStrategy::IsTrendStillValidが返す不合格理由（TREND_REVERSED等）。
   // EmergencyCloseと同じ考え方で、GlobalVariableベースのべき等性により二重約定を防止する。
   bool CloseOnSignalInvalidation(const ulong ticket,const string reason_code,string &error)
     {
      error="";
      const string attempt_key=m_signal_exit_key_prefix+StringFormat("%I64u",ticket);
      if(ticket==m_signal_exit_attempt_ticket || GlobalVariableCheck(attempt_key))
        { error="SIGNAL_EXIT_ALREADY_ATTEMPTED"; return false; }
      if(!PositionSelectByTicket(ticket))
        { error="POSITION_SELECT_FAILED"; return false; }
      const string symbol=PositionGetString(POSITION_SYMBOL);
      const double volume=PositionGetDouble(POSITION_VOLUME);
      const ENUM_POSITION_TYPE position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      MqlTick tick;
      if(volume<=0.0 || !SymbolInfoTick(symbol,tick))
        { error="POSITION_CLOSE_DATA_UNAVAILABLE"; return false; }
      if(!CPositionProtectionRules::HasValidMarketData(tick.bid,tick.ask))
        { error="SIGNAL_EXIT_INVALID_MARKET_DATA"; return false; }

      MqlTradeRequest request;
      MqlTradeCheckResult check;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(check);
      ZeroMemory(result);
      request.action=TRADE_ACTION_DEAL;
      request.magic=m_config.magic_number;
      request.position=ticket;
      request.symbol=symbol;
      request.volume=volume;
      request.type=(position_type==POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY);
      request.price=(position_type==POSITION_TYPE_BUY ? tick.bid : tick.ask);
      request.deviation=m_config.max_deviation_points;
      request.type_filling=FillingMode(symbol);
      request.comment=StringSubstr("SIGNAL_"+reason_code,0,31);

      ResetLastError();
      const bool check_ok=OrderCheck(request,check);
      if(!COrderCheckRules::IsAccepted(check_ok,check.retcode))
        { error=StringFormat("SIGNAL_EXIT_ORDER_CHECK_FAILED retcode=%u comment=%s",check.retcode,check.comment); return false; }
      // Persist before sending. An ambiguous failure is never retried automatically
      // (matches EmergencyClose's idempotency convention).
      ResetLastError();
      if(GlobalVariableSet(attempt_key,1.0)==0 && GetLastError()!=0)
        { error="SIGNAL_EXIT_IDEMPOTENCY_PERSIST_FAILED"; return false; }
      GlobalVariablesFlush();
      m_signal_exit_attempt_ticket=ticket;
      if(!OrderSend(request,result) || !COrderValidationRules::AcceptedRetcode(result.retcode))
        { error=StringFormat("SIGNAL_EXIT_FAILED retcode=%u comment=%s",result.retcode,result.comment); return false; }
      PrintFormat("SIGNAL_EXIT_SUBMITTED position=%I64u order=%I64u deal=%I64u retcode=%u reason=%s",
                  ticket,result.order,result.deal,result.retcode,reason_code);
      return true;
     }

   // Time Stop（保有時間超過）による決済専用のメカニズム。判断（経過バー数・MFE到達判定）はEAController側で
   // 行い、ここは決済実行のみを担う（CloseOnSignalInvalidationと同じ責務境界・冪等性の考え方）。
   bool CloseOnTimeStop(const ulong ticket,const string reason_code,string &error)
     {
      error="";
      const string attempt_key=m_time_stop_key_prefix+StringFormat("%I64u",ticket);
      if(ticket==m_time_stop_attempt_ticket || GlobalVariableCheck(attempt_key))
        { error="TIME_STOP_ALREADY_ATTEMPTED"; return false; }
      if(!PositionSelectByTicket(ticket))
        { error="POSITION_SELECT_FAILED"; return false; }
      const string symbol=PositionGetString(POSITION_SYMBOL);
      const double volume=PositionGetDouble(POSITION_VOLUME);
      const ENUM_POSITION_TYPE position_type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      MqlTick tick;
      if(volume<=0.0 || !SymbolInfoTick(symbol,tick))
        { error="POSITION_CLOSE_DATA_UNAVAILABLE"; return false; }
      if(!CPositionProtectionRules::HasValidMarketData(tick.bid,tick.ask))
        { error="TIME_STOP_INVALID_MARKET_DATA"; return false; }

      MqlTradeRequest request;
      MqlTradeCheckResult check;
      MqlTradeResult result;
      ZeroMemory(request);
      ZeroMemory(check);
      ZeroMemory(result);
      request.action=TRADE_ACTION_DEAL;
      request.magic=m_config.magic_number;
      request.position=ticket;
      request.symbol=symbol;
      request.volume=volume;
      request.type=(position_type==POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY);
      request.price=(position_type==POSITION_TYPE_BUY ? tick.bid : tick.ask);
      request.deviation=m_config.max_deviation_points;
      request.type_filling=FillingMode(symbol);
      request.comment=StringSubstr("TIMESTOP_"+reason_code,0,31);

      ResetLastError();
      const bool check_ok=OrderCheck(request,check);
      if(!COrderCheckRules::IsAccepted(check_ok,check.retcode))
        { error=StringFormat("TIME_STOP_ORDER_CHECK_FAILED retcode=%u comment=%s",check.retcode,check.comment); return false; }
      // Persist before sending. An ambiguous failure is never retried automatically
      // (matches EmergencyClose/CloseOnSignalInvalidation's idempotency convention).
      ResetLastError();
      if(GlobalVariableSet(attempt_key,1.0)==0 && GetLastError()!=0)
        { error="TIME_STOP_IDEMPOTENCY_PERSIST_FAILED"; return false; }
      GlobalVariablesFlush();
      m_time_stop_attempt_ticket=ticket;
      if(!OrderSend(request,result) || !COrderValidationRules::AcceptedRetcode(result.retcode))
        { error=StringFormat("TIME_STOP_CLOSE_FAILED retcode=%u comment=%s",result.retcode,result.comment); return false; }
      PrintFormat("TIME_STOP_EXIT_SUBMITTED position=%I64u order=%I64u deal=%I64u retcode=%u reason=%s",
                  ticket,result.order,result.deal,result.retcode,reason_code);
      return true;
     }

   void OnTradeTransaction(const MqlTradeTransaction &transaction)
     {
      if(transaction.type!=TRADE_TRANSACTION_DEAL_ADD || transaction.deal==0)
         return;
      if(!HistoryDealSelect(transaction.deal))
         return;
      const long magic=HistoryDealGetInteger(transaction.deal,DEAL_MAGIC);
      if(!CPositionProtectionRules::IsManagedPosition(magic,m_config.magic_number,m_config.mean_reversion_magic_number))
         return;
      const ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(transaction.deal,DEAL_ENTRY);
      const string symbol=HistoryDealGetString(transaction.deal,DEAL_SYMBOL);
      const double price=HistoryDealGetDouble(transaction.deal,DEAL_PRICE);
      const double volume=HistoryDealGetDouble(transaction.deal,DEAL_VOLUME);
      const double pnl=HistoryDealGetDouble(transaction.deal,DEAL_PROFIT)+
                       HistoryDealGetDouble(transaction.deal,DEAL_COMMISSION)+
                       HistoryDealGetDouble(transaction.deal,DEAL_SWAP)+
                       HistoryDealGetDouble(transaction.deal,DEAL_FEE);
      PrintFormat("TRADE_DEAL deal=%I64u order=%I64u position=%I64u symbol=%s entry=%s price=%.8f volume=%.8f pnl=%.2f",
                  transaction.deal,transaction.order,transaction.position,symbol,EnumToString(entry),price,volume,pnl);
     }
  };

#endif
