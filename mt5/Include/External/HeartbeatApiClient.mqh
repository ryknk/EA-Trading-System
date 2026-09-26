#ifndef EA_TRADING_SYSTEM_HEARTBEAT_API_CLIENT_MQH
#define EA_TRADING_SYSTEM_HEARTBEAT_API_CLIENT_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/External/CryptoUtils.mqh>
#include <EaTradingSystem/Logging/AuditPayloadBuilder.mqh>

// EA稼働監視専用のHeartbeat。取引判断API・Telemetryとは分離し、送信結果を売買可否・Risk判定・
// 既存ポジション管理の入力に一切使用しない（呼び出し側は失敗をログ出力するだけにする）。
class CHeartbeatRules
  {
public:
   static string BuildBody(const string heartbeat_id,const string ea_id,const datetime timestamp_utc,
                           const string symbol,const int interval_seconds,const bool terminal_connected,
                           const bool trade_mutations_enabled,const bool kill_switch_active)
     {
      string body="{";
      body+="\"schema_version\":\"1.0\",";
      body+="\"heartbeat_id\":"+CAuditPayloadBuilder::JString(heartbeat_id)+",";
      body+="\"ea_id\":"+CAuditPayloadBuilder::JString(ea_id)+",";
      body+="\"timestamp\":"+CAuditPayloadBuilder::JString(CAuditPayloadBuilder::Iso8601Utc(timestamp_utc))+",";
      body+="\"symbol\":"+CAuditPayloadBuilder::JString(symbol)+",";
      body+="\"interval_seconds\":"+IntegerToString(interval_seconds)+",";
      body+="\"terminal_connected\":"+CAuditPayloadBuilder::JBool(terminal_connected)+",";
      body+="\"trade_mutations_enabled\":"+CAuditPayloadBuilder::JBool(trade_mutations_enabled)+",";
      body+="\"kill_switch_active\":"+CAuditPayloadBuilder::JBool(kill_switch_active);
      body+="}";
      return body;
     }

   static string CanonicalRequest(const string timestamp,const string nonce,const string body_hash)
     {
      return "POST\n/v1/heartbeats\n"+timestamp+"\n"+nonce+"\n"+body_hash;
     }

   static bool IsAcceptedResponse(const string response,const string heartbeat_id)
     {
      if(StringLen(response)<=0 || StringLen(response)>1024) return false;
      if(StringFind(response,"\"heartbeat_id\":\""+heartbeat_id+"\"")<0) return false;
      return (StringFind(response,"\"status\":\"ACCEPTED\"")>=0 || StringFind(response,"\"status\":\"STALE\"")>=0);
     }
  };

class CHeartbeatApiClient
  {
private:
   SEaConfig m_config;
   string    m_secret;
   bool      m_initialized;

   bool LoadSecret(string &error)
     {
      error="";
      ResetLastError();
      const int handle=FileOpen(m_config.decision_api_secret_file,FILE_READ|FILE_TXT|FILE_ANSI,0,CP_UTF8);
      if(handle==INVALID_HANDLE)
        { error=StringFormat("HEARTBEAT_SECRET_FILE_OPEN_FAILED_%d",GetLastError()); return false; }
      m_secret=FileReadString(handle);
      FileClose(handle);
      StringTrimLeft(m_secret);
      StringTrimRight(m_secret);
      if(StringLen(m_secret)<32 || StringLen(m_secret)>256)
        { m_secret=""; error="HEARTBEAT_SECRET_LENGTH_INVALID"; return false; }
      return true;
     }

public:
   CHeartbeatApiClient(void) { m_secret=""; m_initialized=false; }

   bool Initialize(const SEaConfig &config,string &error)
     {
      error="";
      m_config=config;
      m_secret="";
      m_initialized=false;
      if(m_config.heartbeat_enabled && !LoadSecret(error)) return false;
      m_initialized=true;
      return true;
     }

   void Shutdown(void) { m_secret=""; m_initialized=false; }
   bool Enabled(void) const { return m_initialized && m_config.heartbeat_enabled; }

   bool Send(const bool terminal_connected,const bool kill_switch_active,string &error)
     {
      error="";
      if(!Enabled()) { error="HEARTBEAT_CLIENT_NOT_ENABLED"; return false; }
      if(MQLInfoInteger(MQL_TESTER)) { error="HEARTBEAT_UNAVAILABLE_IN_TESTER"; return false; }
      const datetime now_utc=TimeGMT();
      if(now_utc<=0) { error="HEARTBEAT_UTC_UNAVAILABLE"; return false; }
      string heartbeat_id,nonce;
      if(!CCryptoUtils::GenerateUuid(heartbeat_id) || !CCryptoUtils::GenerateUuid(nonce))
        { error="HEARTBEAT_UUID_FAILED"; return false; }
      const string body=CHeartbeatRules::BuildBody(heartbeat_id,m_config.ea_id,now_utc,m_config.symbol,
                                                   m_config.heartbeat_interval_seconds,terminal_connected,
                                                   m_config.enable_trade_mutations,kill_switch_active);
      string body_hash;
      if(!CCryptoUtils::Sha256Hex(body,body_hash)) { error="HEARTBEAT_BODY_HASH_FAILED"; return false; }
      const string timestamp=IntegerToString((long)now_utc);
      string signature;
      if(!CCryptoUtils::HmacSha256Hex(m_secret,CHeartbeatRules::CanonicalRequest(timestamp,nonce,body_hash),signature))
        { error="HEARTBEAT_SIGNING_FAILED"; return false; }

      string headers="Content-Type: application/json\r\n";
      headers+="X-EA-Key-Id: "+m_config.decision_api_key_id+"\r\n";
      headers+="X-EA-Timestamp: "+timestamp+"\r\n";
      headers+="X-EA-Nonce: "+nonce+"\r\n";
      headers+="X-EA-Signature: "+signature+"\r\n";
      headers+="Idempotency-Key: "+heartbeat_id+"\r\n";
      char request_data[],response_data[];
      StringToCharArray(body,request_data,0,WHOLE_ARRAY,CP_UTF8);
      if(ArraySize(request_data)>0 && request_data[ArraySize(request_data)-1]==0)
         ArrayResize(request_data,ArraySize(request_data)-1);
      string response_headers;
      ResetLastError();
      const int status=WebRequest("POST",m_config.heartbeat_api_url,headers,
                                  m_config.heartbeat_timeout_ms,request_data,response_data,response_headers);
      if(status!=200)
        { error=(status==-1 ? StringFormat("HEARTBEAT_WEBREQUEST_FAILED_%d",GetLastError()) : StringFormat("HEARTBEAT_HTTP_%d",status)); return false; }
      const string response=CharArrayToString(response_data,0,WHOLE_ARRAY,CP_UTF8);
      if(!CHeartbeatRules::IsAcceptedResponse(response,heartbeat_id))
        { error="HEARTBEAT_RESPONSE_INVALID"; return false; }
      return true;
     }
  };

#endif
