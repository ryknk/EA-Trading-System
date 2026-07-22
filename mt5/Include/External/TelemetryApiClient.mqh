#ifndef EA_TRADING_SYSTEM_TELEMETRY_API_CLIENT_MQH
#define EA_TRADING_SYSTEM_TELEMETRY_API_CLIENT_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/External/CryptoUtils.mqh>

class CTelemetryApiClient
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
        { error=StringFormat("TELEMETRY_SECRET_FILE_OPEN_FAILED_%d",GetLastError()); return false; }
      m_secret=FileReadString(handle);
      FileClose(handle);
      StringTrimLeft(m_secret);
      StringTrimRight(m_secret);
      if(StringLen(m_secret)<32 || StringLen(m_secret)>256)
        { m_secret=""; error="TELEMETRY_SECRET_LENGTH_INVALID"; return false; }
      return true;
     }

public:
   CTelemetryApiClient(void) { m_secret=""; m_initialized=false; }

   bool Initialize(const SEaConfig &config,string &error)
     {
      error="";
      m_config=config;
      m_secret="";
      m_initialized=false;
      if(m_config.telemetry_enabled && !LoadSecret(error)) return false;
      m_initialized=true;
      return true;
     }

   void Shutdown(void) { m_secret=""; m_initialized=false; }
   bool Enabled(void) const { return m_initialized && m_config.telemetry_enabled; }

   bool Send(const string body,const string event_id,const datetime event_time,string &error)
     {
      error="";
      if(!m_initialized) { error="TELEMETRY_CLIENT_NOT_INITIALIZED"; return false; }
      if(!m_config.telemetry_enabled) return true;
      if(MQLInfoInteger(MQL_TESTER)) { error="TELEMETRY_UNAVAILABLE_IN_TESTER"; return false; }
      string nonce;
      if(!CCryptoUtils::GenerateUuid(nonce)) { error="TELEMETRY_NONCE_FAILED"; return false; }
      string body_hash;
      if(!CCryptoUtils::Sha256Hex(body,body_hash)) { error="TELEMETRY_BODY_HASH_FAILED"; return false; }
      const string timestamp=IntegerToString((long)event_time);
      const string canonical="POST\n/v1/trade-events\n"+timestamp+"\n"+nonce+"\n"+body_hash;
      string signature;
      if(!CCryptoUtils::HmacSha256Hex(m_secret,canonical,signature))
        { error="TELEMETRY_SIGNING_FAILED"; return false; }

      string headers="Content-Type: application/json\r\n";
      headers+="X-EA-Key-Id: "+m_config.decision_api_key_id+"\r\n";
      headers+="X-EA-Timestamp: "+timestamp+"\r\n";
      headers+="X-EA-Nonce: "+nonce+"\r\n";
      headers+="X-EA-Signature: "+signature+"\r\n";
      headers+="Idempotency-Key: "+event_id+"\r\n";
      char request_data[],response_data[];
      StringToCharArray(body,request_data,0,WHOLE_ARRAY,CP_UTF8);
      if(ArraySize(request_data)>0 && request_data[ArraySize(request_data)-1]==0)
         ArrayResize(request_data,ArraySize(request_data)-1);
      string response_headers;
      ResetLastError();
      const int status=WebRequest("POST",m_config.telemetry_api_url,headers,
                                  m_config.telemetry_timeout_ms,request_data,response_data,response_headers);
      if(status!=200)
        { error=(status==-1 ? StringFormat("TELEMETRY_WEBREQUEST_FAILED_%d",GetLastError()) : StringFormat("TELEMETRY_HTTP_%d",status)); return false; }
      if(ArraySize(response_data)<=0 || ArraySize(response_data)>4096)
        { error="TELEMETRY_RESPONSE_SIZE_INVALID"; return false; }
      const string response=CharArrayToString(response_data,0,WHOLE_ARRAY,CP_UTF8);
      if(StringFind(response,"\"event_id\":\""+event_id+"\"")<0 ||
         (StringFind(response,"\"status\":\"ACCEPTED\"")<0 && StringFind(response,"\"status\":\"DUPLICATE\"")<0))
        { error="TELEMETRY_RESPONSE_INVALID"; return false; }
      return true;
     }
  };

#endif

