#ifndef EA_TRADING_SYSTEM_TRADE_LOGGER_MQH
#define EA_TRADING_SYSTEM_TRADE_LOGGER_MQH

#include <EaTradingSystem/Core/Config.mqh>
#include <EaTradingSystem/External/CryptoUtils.mqh>

class CTradeLogRules
  {
public:
   static bool SafeCorrelationId(const string value,const bool allow_empty=false)
     {
      if(StringLen(value)==0) return allow_empty;
      if(StringLen(value)>128) return false;
      for(int index=0; index<StringLen(value); index++)
        {
         const ushort c=StringGetCharacter(value,index);
         if(!((c>='A' && c<='Z') || (c>='a' && c<='z') || (c>='0' && c<='9') ||
              c=='.' || c=='_' || c=='-' || c==':')) return false;
        }
      return true;
     }

   // 相関ID等のログ・監査フィールドが安全でない場合にフォールバック値へ差し替える。
   static string SafeIdentifier(const string value,const string fallback)
     {
      return SafeCorrelationId(value) ? value : fallback;
     }

   static bool SafeEventType(const string value)
     {
      return value=="CANDIDATE" || value=="EXTERNAL_DECISION" || value=="RISK_DECISION" ||
             value=="ORDER_SUBMISSION" || value=="DEAL" || value=="POSITION_SNAPSHOT" ||
             value=="TRADE_CLOSED" || value=="ACCOUNT_SNAPSHOT" || value=="SYSTEM_ERROR" ||
             value=="TRADE_ANALYTICS" || value=="TIME_STOP_EXIT" || value=="ENTRY_PIPELINE" ||
             value=="ENTRY_TIMING_SETUP" || value=="ENTRY_TIMING_TRADE" || value=="RANGE_EXIT" ||
             value=="RANGE_ALERT";
     }
  };

class CTradeLogger
  {
private:
   SEaConfig m_config;
   bool      m_initialized;

   string Iso8601Utc(const datetime value)
     {
      MqlDateTime parts;
      TimeToStruct(value,parts);
      return StringFormat("%04d-%02d-%02dT%02d:%02d:%02dZ",
                          parts.year,parts.mon,parts.day,parts.hour,parts.min,parts.sec);
     }

   string FileName(const datetime value)
     {
      MqlDateTime parts;
      TimeToStruct(value,parts);
      return StringFormat("%s\\audit-%04d%02d%02d.jsonl",
                          m_config.audit_log_directory,parts.year,parts.mon,parts.day);
     }

public:
   CTradeLogger(void) { m_initialized=false; }

   bool Initialize(const SEaConfig &config,string &error)
     {
      error="";
      m_config=config;
      m_initialized=true;
      if(!m_config.audit_file_enabled) return true;
      ResetLastError();
      // FolderCreate returns false when the directory already exists. Actual
      // writability is checked by Record without disabling terminal logging.
      FolderCreate(m_config.audit_log_directory);
      return true;
     }

   void Shutdown(void) { m_initialized=false; }

   bool Record(const string event_type,const string candidate_id,const string request_id,
               const string symbol,const string payload_json,string &event_id,
               datetime &event_time,string &body,string &error)
     {
      event_id="";
      event_time=0;
      body="";
      error="";
      if(!m_initialized)
        { error="AUDIT_LOGGER_NOT_INITIALIZED"; return false; }
      if(!CTradeLogRules::SafeEventType(event_type) ||
         !CTradeLogRules::SafeCorrelationId(candidate_id) ||
         !CTradeLogRules::SafeCorrelationId(request_id,true) ||
         !CTradeLogRules::SafeCorrelationId(symbol) ||
         StringLen(payload_json)<2 || StringLen(payload_json)>12000 ||
         StringSubstr(payload_json,0,1)!="{" || StringSubstr(payload_json,StringLen(payload_json)-1,1)!="}")
        { error="AUDIT_EVENT_INVALID"; return false; }
      if(!CCryptoUtils::GenerateUuid(event_id))
        { error="AUDIT_EVENT_ID_FAILED"; return false; }
      event_time=TimeGMT();
      if(event_time<=0)
        { error="AUDIT_UTC_TIME_UNAVAILABLE"; return false; }
      body="{";
      body+="\"schema_version\":\"1.0\",";
      body+="\"event_id\":\""+CCryptoUtils::JsonEscape(event_id)+"\",";
      body+="\"trade_candidate_id\":\""+CCryptoUtils::JsonEscape(candidate_id)+"\",";
      body+="\"request_id\":\""+CCryptoUtils::JsonEscape(request_id)+"\",";
      body+="\"ea_id\":\""+CCryptoUtils::JsonEscape(m_config.ea_id)+"\",";
      body+="\"timestamp\":\""+Iso8601Utc(event_time)+"\",";
      body+="\"event_type\":\""+event_type+"\",";
      body+="\"symbol\":\""+CCryptoUtils::JsonEscape(symbol)+"\",";
      body+="\"payload\":"+payload_json+"}";
      if(StringLen(body)>16384)
        { body=""; error="AUDIT_EVENT_TOO_LARGE"; return false; }

      PrintFormat("AUDIT_EVENT event_id=%s candidate_id=%s request_id=%s type=%s",
                  event_id,candidate_id,request_id,event_type);
      if(!m_config.audit_file_enabled) return true;

      ResetLastError();
      const int handle=FileOpen(FileName(event_time),FILE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_SHARE_READ,0,CP_UTF8);
      if(handle==INVALID_HANDLE)
        { error=StringFormat("AUDIT_FILE_OPEN_FAILED_%d",GetLastError()); return false; }
      FileSeek(handle,0,SEEK_END);
      const uint written=FileWriteString(handle,body+"\r\n");
      FileFlush(handle);
      FileClose(handle);
      if(written<=0)
        { error="AUDIT_FILE_WRITE_FAILED"; return false; }
      return true;
     }
  };

#endif
