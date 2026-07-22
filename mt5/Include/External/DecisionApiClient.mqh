#ifndef EA_TRADING_SYSTEM_DECISION_API_CLIENT_MQH
#define EA_TRADING_SYSTEM_DECISION_API_CLIENT_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/Signal/SignalResult.mqh>
#include <EaTradingSystem/External/CryptoUtils.mqh>
#include <EaTradingSystem/External/StrictJson.mqh>
#include <EaTradingSystem/External/IDecisionProvider.mqh>

class CDecisionApiClient : public IDecisionProvider
  {
private:
   SEaConfig              m_config;
   string                 m_secret;
   CDecisionResponseParser m_parser;
   bool                   m_initialized;

   string Iso8601Utc(const datetime value)
     {
      MqlDateTime parts;
      TimeToStruct(value,parts);
      return StringFormat("%04d-%02d-%02dT%02d:%02d:%02dZ",
                          parts.year,parts.mon,parts.day,parts.hour,parts.min,parts.sec);
     }

   datetime BrokerTimeToUtc(const datetime broker_time)
     {
      const datetime server_now=TimeTradeServer();
      const datetime utc_now=TimeGMT();
      if(server_now<=0 || utc_now<=0) return 0;
      return broker_time-(server_now-utc_now);
     }

   string TimeframeName(const ENUM_TIMEFRAMES timeframe)
     {
      string value=EnumToString(timeframe);
      if(StringFind(value,"PERIOD_")==0) value=StringSubstr(value,7);
      return value;
     }

   string JsonNumber(const double value)
     {
      return DoubleToString(value,10);
     }

   bool BuildRequest(const SSignalResult &signal,const string request_id,const datetime request_time,
                     string &body,string &error)
     {
      body="";
      error="";
      MqlTick tick;
      const double point=SymbolInfoDouble(signal.symbol,SYMBOL_POINT);
      if(point<=0.0 || !SymbolInfoTick(signal.symbol,tick))
        { error="REQUEST_MARKET_DATA_UNAVAILABLE"; return false; }
      const double current_price=(signal.direction==SIGNAL_DIRECTION_BUY ? tick.ask : tick.bid);
      const double spread_points=(tick.ask-tick.bid)/point;
      const datetime observed_utc=BrokerTimeToUtc(signal.signal_bar_time);
      if(observed_utc<=0 || current_price<=0.0 || spread_points<0.0 ||
         !MathIsValidNumber(signal.rsi) || !MathIsValidNumber(signal.atr) ||
         !MathIsValidNumber(signal.ema_fast) || !MathIsValidNumber(signal.ema_slow) ||
         !MathIsValidNumber(signal.ema_distance_ratio) || !MathIsValidNumber(signal.recent_return) ||
         !MathIsValidNumber(signal.volatility))
        { error="REQUEST_FEATURE_INVALID"; return false; }

      body="{";
      body+="\"schema_version\":\"1.0\",";
      body+="\"request_id\":\""+CCryptoUtils::JsonEscape(request_id)+"\",";
      body+="\"trade_candidate_id\":\""+CCryptoUtils::JsonEscape(signal.trade_candidate_id)+"\",";
      body+="\"ea_id\":\""+CCryptoUtils::JsonEscape(m_config.ea_id)+"\",";
      body+="\"timestamp\":\""+Iso8601Utc(request_time)+"\",";
      body+="\"symbol\":\""+CCryptoUtils::JsonEscape(signal.symbol)+"\",";
      body+="\"timeframe\":\""+TimeframeName(signal.timeframe)+"\",";
      body+="\"direction\":\""+SignalDirectionToString(signal.direction)+"\",";
      body+="\"strategy\":{";
      body+="\"pattern\":\""+EntryPatternToString(signal.entry_pattern)+"\",";
      body+="\"reason_code\":\""+CCryptoUtils::JsonEscape(signal.reason_code)+"\",";
      body+="\"reason\":\""+CCryptoUtils::JsonEscape(signal.reason)+"\"},";
      body+="\"market_features\":{";
      body+="\"feature_schema_version\":\"1.0\",";
      body+="\"observed_at\":\""+Iso8601Utc(observed_utc)+"\",";
      body+="\"current_price\":"+JsonNumber(current_price)+",";
      body+="\"spread_points\":"+JsonNumber(spread_points)+",";
      body+="\"rsi\":"+JsonNumber(signal.rsi)+",";
      body+="\"atr\":"+JsonNumber(signal.atr)+",";
      body+="\"ema50\":"+JsonNumber(signal.ema_fast)+",";
      body+="\"ema200\":"+JsonNumber(signal.ema_slow)+",";
      body+="\"ema_distance_ratio\":"+JsonNumber(signal.ema_distance_ratio)+",";
      body+="\"recent_return\":"+JsonNumber(signal.recent_return)+",";
      body+="\"volatility\":"+JsonNumber(signal.volatility)+",";
      body+="\"hour\":"+IntegerToString(signal.hour)+",";
      body+="\"day_of_week\":"+IntegerToString(signal.day_of_week);
      body+="},";
      body+="\"trade_proposal\":{";
      body+="\"entry_price\":"+JsonNumber(signal.entry_price)+",";
      body+="\"stop_loss\":"+JsonNumber(signal.stop_loss)+",";
      body+="\"take_profit\":"+JsonNumber(signal.take_profit)+",";
      body+="\"risk_reward_ratio\":"+JsonNumber(signal.risk_reward_ratio);
      body+="}}";
      if(StringLen(body)>16384)
        { error="REQUEST_BODY_TOO_LARGE"; return false; }
      return true;
     }

   bool LoadSecret(string &error)
     {
      error="";
      ResetLastError();
      const int handle=FileOpen(m_config.decision_api_secret_file,FILE_READ|FILE_TXT|FILE_ANSI,0,CP_UTF8);
      if(handle==INVALID_HANDLE)
        { error=StringFormat("DECISION_SECRET_FILE_OPEN_FAILED_%d",GetLastError()); return false; }
      m_secret=FileReadString(handle);
      FileClose(handle);
      StringTrimLeft(m_secret);
      StringTrimRight(m_secret);
      if(StringLen(m_secret)<32 || StringLen(m_secret)>256)
        { m_secret=""; error="DECISION_SECRET_LENGTH_INVALID"; return false; }
      return true;
     }

   void SetFailure(SExternalDecision &decision,const string code,const string reason,const bool veto)
     {
      decision.status=(veto ? EXTERNAL_DECISION_VETO : EXTERNAL_DECISION_ERROR);
      decision.reason_code=code;
      decision.reason=reason;
     }

public:
   CDecisionApiClient(void) { m_secret=""; m_initialized=false; }

   bool Initialize(const SEaConfig &config,string &error)
     {
      error="";
      m_config=config;
      m_secret="";
      m_initialized=false;
      MathSrand((int)(GetTickCount()^(uint)TimeLocal()));
      if(m_config.decision_api_enabled && !LoadSecret(error)) return false;
      m_initialized=true;
      return true;
     }

   void Shutdown(void)
     {
      m_secret="";
      m_initialized=false;
     }

   bool Decide(const SSignalResult &signal,SExternalDecision &decision)
     {
      ResetExternalDecision(decision);
      if(!m_initialized)
        { SetFailure(decision,"DECISION_CLIENT_NOT_INITIALIZED","Decision API client is not initialized.",false); return false; }
      if(!m_config.decision_api_enabled)
        { SetFailure(decision,"DECISION_API_DISABLED","Decision API is disabled; fail-safe veto.",true); return true; }
      if(MQLInfoInteger(MQL_TESTER))
        { SetFailure(decision,"WEBREQUEST_UNAVAILABLE_IN_TESTER","WebRequest is unavailable in Strategy Tester.",true); return true; }

      string request_id,nonce;
      if(!CCryptoUtils::GenerateUuid(request_id) || !CCryptoUtils::GenerateUuid(nonce))
        { SetFailure(decision,"REQUEST_ID_GENERATION_FAILED","Request identity could not be generated.",false); return false; }
      const datetime request_time=TimeGMT();
      decision.request_id=request_id;
      decision.request_time=request_time;
      if(request_time<=0)
        { SetFailure(decision,"UTC_TIME_UNAVAILABLE","UTC time is unavailable.",false); return false; }

      string body,error;
      if(!BuildRequest(signal,request_id,request_time,body,error))
        { SetFailure(decision,error,"Decision request could not be built.",false); return false; }
      string body_hash;
      if(!CCryptoUtils::Sha256Hex(body,body_hash))
        { SetFailure(decision,"BODY_HASH_FAILED","Request body hash failed.",false); return false; }
      const string timestamp=IntegerToString((long)request_time);
      const string canonical="POST\n/v1/trade-decisions\n"+timestamp+"\n"+nonce+"\n"+body_hash;
      string signature;
      if(!CCryptoUtils::HmacSha256Hex(m_secret,canonical,signature))
        { SetFailure(decision,"REQUEST_SIGNING_FAILED","HMAC-SHA256 signing failed.",false); return false; }

      string headers="Content-Type: application/json\r\n";
      headers+="X-EA-Key-Id: "+m_config.decision_api_key_id+"\r\n";
      headers+="X-EA-Timestamp: "+timestamp+"\r\n";
      headers+="X-EA-Nonce: "+nonce+"\r\n";
      headers+="X-EA-Signature: "+signature+"\r\n";
      headers+="Idempotency-Key: "+request_id+"\r\n";

      char request_data[],response_data[];
      StringToCharArray(body,request_data,0,WHOLE_ARRAY,CP_UTF8);
      if(ArraySize(request_data)>0 && request_data[ArraySize(request_data)-1]==0)
         ArrayResize(request_data,ArraySize(request_data)-1);
      string response_headers;
      ResetLastError();
      const int http_status=WebRequest("POST",m_config.decision_api_url,headers,
                                       m_config.decision_api_timeout_ms,request_data,
                                       response_data,response_headers);
      decision.http_status=http_status;
      decision.response_time=TimeGMT();
      if(http_status==-1)
        {
         const int web_error=GetLastError();
         SetFailure(decision,"WEBREQUEST_FAILED",StringFormat("WebRequest error=%d",web_error),true);
         return true;
        }
      if(http_status!=200)
        { SetFailure(decision,"HTTP_STATUS_REJECTED",StringFormat("HTTP status=%d",http_status),true); return true; }
      if(ArraySize(response_data)<=0 || ArraySize(response_data)>32768)
        { SetFailure(decision,"RESPONSE_SIZE_INVALID","Response is empty or too large.",true); return true; }
      const string response=CharArrayToString(response_data,0,WHOLE_ARRAY,CP_UTF8);
      SExternalDecision parsed;
      if(!m_parser.Parse(response,parsed,error))
        { SetFailure(decision,"RESPONSE_JSON_INVALID",error,true); return true; }
      parsed.http_status=http_status;
      parsed.request_time=decision.request_time;
      parsed.response_time=decision.response_time;
      if(!CDecisionResponseParser::Validate(request_id,decision.response_time,
                                            m_config.decision_max_clock_skew_seconds,
                                            m_config.decision_max_ttl_seconds,
                                            m_config.ml_min_win_probability,
                                            m_config.ml_min_expected_return,parsed,error))
        { decision=parsed; SetFailure(decision,error,"Decision response failed validation.",true); return true; }
      decision=parsed;
      return true;
     }
  };

#endif
