#ifndef EA_TRADING_SYSTEM_RISK_MANAGER_MQH
#define EA_TRADING_SYSTEM_RISK_MANAGER_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/Signal/SignalResult.mqh>
#include <EaTradingSystem/Risk/RiskDecision.mqh>
#include <EaTradingSystem/Risk/PositionSizer.mqh>
#include <EaTradingSystem/Risk/DailyLossGuard.mqh>
#include <EaTradingSystem/Risk/DrawdownGuard.mqh>
#include <EaTradingSystem/Risk/ExposureGuard.mqh>
#include <EaTradingSystem/Filter/SpreadFilter.mqh>
#include <EaTradingSystem/Trading/OrderCheckRules.mqh>

class CRiskManager
  {
private:
   SEaConfig          m_config;
   CPositionSizer     m_position_sizer;
   CDailyLossGuard    m_daily_guard;
   CDrawdownGuard     m_drawdown_guard;
   CExposureGuard     m_exposure_guard;
   CSpreadFilter      m_spread_filter;
   bool               m_initialized;
   bool               m_operational_healthy;
   string             m_operational_error;

   void Reject(SRiskDecision &decision,const string code,const string reason)
     {
      decision.status=RISK_DECISION_REJECTED;
      decision.reason_code=code;
      decision.reason=reason;
     }

   ENUM_ORDER_TYPE_FILLING FillingMode(const string symbol)
     {
      const long modes=SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE);
      if((modes & SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK) return ORDER_FILLING_FOK;
      if((modes & SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC) return ORDER_FILLING_IOC;
      return ORDER_FILLING_RETURN;
     }

public:
   CRiskManager(void)
     {
      m_initialized=false;
      m_operational_healthy=false;
      m_operational_error="RISK_MANAGER_NOT_INITIALIZED";
     }

   bool Initialize(const SEaConfig &config,string &error)
     {
      error="";
      m_initialized=false;
      m_operational_healthy=false;
      m_operational_error="RISK_INITIALIZING";
      m_config=config;
      if(MQLInfoInteger(MQL_TESTER) && m_config.tester_reset_persistent_state)
        {
         const string identity=StringFormat("%I64d",AccountInfoInteger(ACCOUNT_LOGIN));
         GlobalVariablesDeleteAll("ETS.DD.HWM."+identity);
         GlobalVariablesDeleteAll("ETS.DD.LOCK."+identity);
         GlobalVariablesDeleteAll("ETS.DAILY.EQ."+identity+".");
         GlobalVariablesDeleteAll("ETS.DAILY.LOCK."+identity+".");
         GlobalVariablesDeleteAll("ETS.ORDER.LAST."+identity+".");
        }
      if(!m_drawdown_guard.Initialize(m_config.max_drawdown_rate,error))
         return false;
      if(!m_daily_guard.Initialize(m_config.daily_loss_limit_rate,error))
         return false;
      m_initialized=true;
      m_operational_healthy=true;
      m_operational_error="";
      GlobalVariablesFlush();
      return true;
     }

   void SetOperationalHealth(const bool healthy,const string error)
     {
      m_operational_healthy=healthy;
      m_operational_error=(healthy ? "" : error);
     }

   bool Monitor(string &reason_code,string &error)
     {
      reason_code="";
      error="";
      if(!m_initialized)
        { error="RISK_MANAGER_NOT_INITIALIZED"; return false; }
      string guard_reason;
      if(!m_drawdown_guard.Evaluate(guard_reason,error)) return false;
      if(StringLen(guard_reason)>0) reason_code=guard_reason;
      if(!m_daily_guard.Evaluate(guard_reason,error)) return false;
      if(StringLen(reason_code)==0 && StringLen(guard_reason)>0) reason_code=guard_reason;
      return true;
     }

   bool Evaluate(const SSignalResult &signal,SRiskDecision &decision)
     {
      ResetRiskDecision(decision);
      if(!m_initialized)
        { Reject(decision,"RISK_STATE_UNAVAILABLE","Risk Manager is not initialized."); return false; }
      if(!m_operational_healthy)
        { Reject(decision,"RISK_STATE_UNAVAILABLE",m_operational_error); return false; }
      if(m_config.emergency_stop)
        { Reject(decision,"EMERGENCY_STOP","Emergency stop is enabled."); return true; }
      if(signal.status!=SIGNAL_STATUS_CANDIDATE)
        { Reject(decision,"INVALID_SIGNAL","Risk evaluation requires a signal candidate."); return true; }

      string guard_reason,error;
      if(!Monitor(guard_reason,error))
        { Reject(decision,"RISK_STATE_UNAVAILABLE",error); return false; }
      decision.drawdown_rate=m_drawdown_guard.CurrentDrawdownRate();
      decision.daily_loss_rate=m_daily_guard.CurrentLossRate();
      if(m_drawdown_guard.IsLocked())
        { Reject(decision,"DD_LIMIT","Account drawdown lock is active."); return true; }
      if(m_daily_guard.IsLocked())
        { Reject(decision,"DAILY_LOSS_LIMIT","Daily loss lock is active."); return true; }

      double spread_points=0.0;
      if(!m_spread_filter.Evaluate(signal.symbol,m_config.max_spread_points,spread_points,error))
        { Reject(decision,error,"Spread is invalid or exceeds the configured limit."); return true; }

      MqlTick tick;
      const double point=SymbolInfoDouble(signal.symbol,SYMBOL_POINT);
      const long stops_level=SymbolInfoInteger(signal.symbol,SYMBOL_TRADE_STOPS_LEVEL);
      if(point<=0.0 || !SymbolInfoTick(signal.symbol,tick))
        { Reject(decision,"MARKET_DATA_UNAVAILABLE","Current tick or point is unavailable."); return false; }
      const double entry=(signal.direction==SIGNAL_DIRECTION_BUY ? tick.ask : tick.bid);
      const double stop_distance=MathAbs(entry-signal.stop_loss);
      if(entry<=0.0 || signal.stop_loss<=0.0 ||
         (signal.direction==SIGNAL_DIRECTION_BUY && signal.stop_loss>=entry) ||
         (signal.direction==SIGNAL_DIRECTION_SELL && signal.stop_loss<=entry) ||
         stop_distance+1.0e-12<stops_level*point)
        { Reject(decision,"INVALID_STOP","Stop loss is invalid at the current market price."); return true; }

      const double equity=AccountInfoDouble(ACCOUNT_EQUITY);
      double loss_per_lot=0.0;
      if(!m_position_sizer.Calculate(signal.symbol,signal.direction,entry,signal.stop_loss,equity,
                                     m_config.risk_per_trade_rate,decision.volume,decision.risk_budget,
                                     loss_per_lot,error))
        { Reject(decision,error,"Position size calculation rejected the candidate."); return true; }
      decision.estimated_stop_loss=decision.volume*loss_per_lot;

      if(!m_exposure_guard.Evaluate(signal.symbol,decision.volume,m_config.max_open_positions,guard_reason,error))
        { Reject(decision,"RISK_STATE_UNAVAILABLE",error); return false; }
      if(StringLen(guard_reason)>0)
        { Reject(decision,guard_reason,"Position or symbol exposure limit is active."); return true; }

      const ENUM_ORDER_TYPE order_type=(signal.direction==SIGNAL_DIRECTION_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
      if(!OrderCalcMargin(order_type,signal.symbol,decision.volume,entry,decision.required_margin) ||
         decision.required_margin<0.0 || !MathIsValidNumber(decision.required_margin))
        { Reject(decision,"MARGIN_CALCULATION_FAILED","Required margin could not be calculated."); return false; }
      const double free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(free_margin<=0.0 || decision.required_margin>free_margin*(1.0-m_config.minimum_free_margin_rate))
        { Reject(decision,"MARGIN_INSUFFICIENT","Configured free-margin reserve would be violated."); return true; }

      MqlTradeRequest request;
      MqlTradeCheckResult check;
      ZeroMemory(request);
      ZeroMemory(check);
      request.action=TRADE_ACTION_DEAL;
      request.magic=m_config.magic_number;
      request.symbol=signal.symbol;
      request.volume=decision.volume;
      request.type=order_type;
      request.price=entry;
      request.sl=signal.stop_loss;
      request.tp=signal.take_profit;
      request.deviation=m_config.max_deviation_points;
      request.type_filling=FillingMode(signal.symbol);
      request.comment=StringSubstr(signal.trade_candidate_id,0,31);
      ResetLastError();
      const bool order_check_ok=OrderCheck(request,check);
      if(!COrderCheckRules::IsAccepted(order_check_ok,check.retcode))
        {
         Reject(decision,"ORDER_CHECK_FAILED",
                StringFormat("OrderCheck last_error=%d retcode=%u comment=%s execution=%d filling=%d volume=%.8f price=%.8f sl=%.8f tp=%.8f",
                             GetLastError(),check.retcode,check.comment,
                             (int)SymbolInfoInteger(signal.symbol,SYMBOL_TRADE_EXEMODE),(int)request.type_filling,
                             request.volume,request.price,request.sl,request.tp));
         return true;
        }

      decision.status=RISK_DECISION_APPROVED;
      decision.reason_code="RISK_APPROVED";
      decision.reason=StringFormat("Risk approved volume=%.2f risk=%.2f margin=%.2f spread=%.1f",
                                   decision.volume,decision.estimated_stop_loss,decision.required_margin,spread_points);
      return true;
     }
  };

#endif
