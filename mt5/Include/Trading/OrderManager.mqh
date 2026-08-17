#ifndef EA_TRADING_SYSTEM_ORDER_MANAGER_MQH
#define EA_TRADING_SYSTEM_ORDER_MANAGER_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/Signal/SignalResult.mqh>
#include <EaTradingSystem/Risk/RiskDecision.mqh>
#include <EaTradingSystem/Trading/OrderResult.mqh>
#include <EaTradingSystem/Trading/OrderCheckRules.mqh>

class COrderValidationRules
  {
public:
   static bool ApprovalChainValid(const bool mutations_enabled,const bool external_approved,
                                  const ESignalStatus signal_status,const ERiskDecisionStatus risk_status,
                                  const double volume)
     {
      return mutations_enabled && external_approved && signal_status==SIGNAL_STATUS_CANDIDATE &&
             risk_status==RISK_DECISION_APPROVED && volume>0.0;
     }

   static bool AcceptedRetcode(const uint retcode)
     {
      return retcode==TRADE_RETCODE_DONE || retcode==TRADE_RETCODE_PLACED ||
             retcode==TRADE_RETCODE_DONE_PARTIAL;
     }
  };

class COrderManager
  {
private:
   SEaConfig m_config;
   string    m_last_candidate_key;
   bool      m_initialized;

   ENUM_ORDER_TYPE_FILLING FillingMode(const string symbol)
     {
      const long modes=SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE);
      if((modes & SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK) return ORDER_FILLING_FOK;
      if((modes & SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC) return ORDER_FILLING_IOC;
      return ORDER_FILLING_RETURN;
     }

   void Block(SOrderResult &result,const string code,const string reason)
     {
      result.status=ORDER_SUBMISSION_BLOCKED;
      result.reason_code=code;
      result.reason=reason;
     }

public:
   COrderManager(void) { m_initialized=false; }

   bool Initialize(const SEaConfig &config,string &error)
     {
      error="";
      m_initialized=false;
      m_config=config;
      const string identity=StringFormat("%I64d",AccountInfoInteger(ACCOUNT_LOGIN));
      m_last_candidate_key="ETS.ORDER.LAST."+identity+"."+StringFormat("%I64u",m_config.magic_number)+"."+m_config.symbol;
      if(StringLen(m_last_candidate_key)>63)
        { error="ORDER_STATE_KEY_TOO_LONG"; return false; }
      m_initialized=true;
      return true;
     }

   bool Submit(const SSignalResult &signal,const SRiskDecision &risk_decision,
               const bool external_approved,SOrderResult &order_result)
     {
      ResetOrderResult(order_result);
      order_result.trade_candidate_id=signal.trade_candidate_id;
      order_result.requested_volume=risk_decision.volume;
      if(!m_initialized)
        {
         order_result.status=ORDER_SUBMISSION_ERROR;
         order_result.reason_code="ORDER_MANAGER_NOT_INITIALIZED";
         order_result.reason="Order Manager is not initialized.";
         return false;
        }
      if(!m_config.enable_trade_mutations)
        { Block(order_result,"TRADE_MUTATIONS_DISABLED","Trade mutations are disabled by configuration."); return true; }
      if(!external_approved)
        { Block(order_result,"EXTERNAL_APPROVAL_REQUIRED","No valid external ALLOW decision was supplied."); return true; }
      if(!COrderValidationRules::ApprovalChainValid(m_config.enable_trade_mutations,external_approved,
                                                    signal.status,risk_decision.status,risk_decision.volume))
        { Block(order_result,"APPROVAL_CHAIN_INVALID","Signal or Risk approval is invalid."); return true; }
      if(StringLen(signal.trade_candidate_id)<1 || signal.signal_bar_time<=0)
        { Block(order_result,"CANDIDATE_ID_INVALID","Candidate identity or bar time is invalid."); return true; }
      if(GlobalVariableCheck(m_last_candidate_key) &&
         (datetime)GlobalVariableGet(m_last_candidate_key)>=signal.signal_bar_time)
        { Block(order_result,"DUPLICATE_CANDIDATE","This bar or a newer candidate was already submitted."); return true; }

      MqlTick tick;
      const double point=SymbolInfoDouble(signal.symbol,SYMBOL_POINT);
      if(point<=0.0 || !SymbolInfoTick(signal.symbol,tick))
        {
         order_result.status=ORDER_SUBMISSION_ERROR;
         order_result.reason_code="MARKET_DATA_UNAVAILABLE";
         order_result.reason="Current tick is unavailable.";
         return false;
        }

      MqlTradeRequest request;
      MqlTradeCheckResult check;
      ZeroMemory(request);
      ZeroMemory(check);
      request.action=TRADE_ACTION_DEAL;
      request.magic=m_config.magic_number;
      request.symbol=signal.symbol;
      request.volume=risk_decision.volume;
      request.type=(signal.direction==SIGNAL_DIRECTION_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
      request.price=(signal.direction==SIGNAL_DIRECTION_BUY ? tick.ask : tick.bid);
      request.sl=signal.stop_loss;
      request.tp=signal.take_profit;
      request.deviation=m_config.max_deviation_points;
      request.type_filling=FillingMode(signal.symbol);
      // trade_candidate_idは"{ea_id}-{symbol}-{unix_time}"形式でMQL5のDeal Comment上限(31文字)を
      // 超えることが多く、そのまま格納すると末尾が切り捨てられCANDIDATE/RISK_DECISION監査ログとの
      // 相関IDが一致しなくなる（EAController::CandidateForPositionでの復元に失敗する）。
      // ea_id・symbolはPosition側から既知のため、一意性を持つentry_bar時刻のみを格納する。
      request.comment=IntegerToString((long)signal.signal_bar_time);
      order_result.requested_price=request.price;

      ResetLastError();
      const bool order_check_ok=OrderCheck(request,check);
      if(!COrderCheckRules::IsAccepted(order_check_ok,check.retcode))
        { Block(order_result,"ORDER_CHECK_FAILED",StringFormat("last_error=%d retcode=%u comment=%s",GetLastError(),check.retcode,check.comment)); return true; }

      // Persist before sending. An ambiguous failure is never retried automatically.
      ResetLastError();
      if(GlobalVariableSet(m_last_candidate_key,(double)signal.signal_bar_time)==0 && GetLastError()!=0)
        {
         order_result.status=ORDER_SUBMISSION_ERROR;
         order_result.reason_code="ORDER_IDEMPOTENCY_PERSIST_FAILED";
         order_result.reason="Candidate idempotency state could not be persisted.";
         return false;
        }
      GlobalVariablesFlush();

      MqlTradeResult broker_result;
      ZeroMemory(broker_result);
      ResetLastError();
      if(!OrderSend(request,broker_result))
        {
         order_result.status=ORDER_SUBMISSION_ERROR;
         order_result.reason_code="ORDER_SEND_FAILED";
         order_result.reason=StringFormat("last_error=%d retcode=%u comment=%s",GetLastError(),broker_result.retcode,broker_result.comment);
         order_result.broker_retcode=broker_result.retcode;
         return false;
        }
      order_result.broker_retcode=broker_result.retcode;
      order_result.order_ticket=broker_result.order;
      order_result.deal_ticket=broker_result.deal;
      order_result.confirmed_price=broker_result.price;
      order_result.confirmed_volume=broker_result.volume;
      if(broker_result.price>0.0)
         order_result.slippage_points=MathAbs(broker_result.price-request.price)/point;
      if(!COrderValidationRules::AcceptedRetcode(broker_result.retcode))
        {
         order_result.status=ORDER_SUBMISSION_ERROR;
         order_result.reason_code="ORDER_REJECTED_BY_BROKER";
         order_result.reason=StringFormat("retcode=%u comment=%s",broker_result.retcode,broker_result.comment);
         return false;
        }
      order_result.status=ORDER_SUBMISSION_ACCEPTED;
      order_result.reason_code=(broker_result.retcode==TRADE_RETCODE_DONE_PARTIAL ? "ORDER_PARTIALLY_FILLED" : "ORDER_ACCEPTED");
      order_result.reason=broker_result.comment;
      return true;
     }
  };

#endif
