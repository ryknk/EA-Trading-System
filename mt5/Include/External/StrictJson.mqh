#ifndef EA_TRADING_SYSTEM_STRICT_JSON_MQH
#define EA_TRADING_SYSTEM_STRICT_JSON_MQH

#include <EaTradingSystem/External/DecisionTypes.mqh>

enum EJsonTokenType
  {
   JSON_TOKEN_INVALID=0,
   JSON_TOKEN_OBJECT_BEGIN,
   JSON_TOKEN_OBJECT_END,
   JSON_TOKEN_ARRAY_BEGIN,
   JSON_TOKEN_ARRAY_END,
   JSON_TOKEN_COLON,
   JSON_TOKEN_COMMA,
   JSON_TOKEN_STRING,
   JSON_TOKEN_NUMBER,
   JSON_TOKEN_TRUE,
   JSON_TOKEN_FALSE,
   JSON_TOKEN_NULL,
   JSON_TOKEN_END
  };

struct SJsonToken
  {
   EJsonTokenType type;
   string text;
   double number;
  };

class CStrictJsonTokenizer
  {
private:
   string m_json;
   int    m_position;

   void SkipWhitespace(void)
     {
      while(m_position<StringLen(m_json))
        {
         const ushort c=StringGetCharacter(m_json,m_position);
         if(c==' ' || c==9 || c==10 || c==13) m_position++;
         else break;
        }
     }

   int HexDigit(const ushort c)
     {
      if(c>='0' && c<='9') return (int)(c-'0');
      if(c>='a' && c<='f') return 10+(int)(c-'a');
      if(c>='A' && c<='F') return 10+(int)(c-'A');
      return -1;
     }

   bool ReadString(SJsonToken &token,string &error)
     {
      m_position++;
      string value="";
      while(m_position<StringLen(m_json))
        {
         ushort c=StringGetCharacter(m_json,m_position++);
         if(c=='"')
           {
            token.type=JSON_TOKEN_STRING;
            token.text=value;
            return true;
           }
         if(c<32) { error="JSON_CONTROL_CHARACTER"; return false; }
         if(c!='\\')
           {
            value+=ShortToString(c);
            continue;
           }
         if(m_position>=StringLen(m_json)) { error="JSON_ESCAPE_TRUNCATED"; return false; }
         const ushort escaped=StringGetCharacter(m_json,m_position++);
         if(escaped=='"' || escaped=='\\' || escaped=='/') value+=ShortToString(escaped);
         else if(escaped=='b') value+=ShortToString(8);
         else if(escaped=='f') value+=ShortToString(12);
         else if(escaped=='n') value+=ShortToString(10);
         else if(escaped=='r') value+=ShortToString(13);
         else if(escaped=='t') value+=ShortToString(9);
         else if(escaped=='u')
           {
            if(m_position+4>StringLen(m_json)) { error="JSON_UNICODE_TRUNCATED"; return false; }
            int code=0;
            for(int index=0; index<4; index++)
              {
               const int digit=HexDigit(StringGetCharacter(m_json,m_position++));
               if(digit<0) { error="JSON_UNICODE_INVALID"; return false; }
               code=code*16+digit;
              }
            if(code>=0xD800 && code<=0xDFFF) { error="JSON_SURROGATE_NOT_ALLOWED"; return false; }
            value+=ShortToString((ushort)code);
           }
         else { error="JSON_ESCAPE_INVALID"; return false; }
        }
      error="JSON_STRING_UNTERMINATED";
      return false;
     }

   bool ReadNumber(SJsonToken &token,string &error)
     {
      const int start=m_position;
      if(StringGetCharacter(m_json,m_position)=='-') m_position++;
      if(m_position>=StringLen(m_json)) { error="JSON_NUMBER_INVALID"; return false; }
      ushort c=StringGetCharacter(m_json,m_position);
      if(c=='0')
        {
         m_position++;
         if(m_position<StringLen(m_json))
           {
            c=StringGetCharacter(m_json,m_position);
            if(c>='0' && c<='9') { error="JSON_NUMBER_LEADING_ZERO"; return false; }
           }
        }
      else if(c>='1' && c<='9')
        {
         while(m_position<StringLen(m_json))
           {
            c=StringGetCharacter(m_json,m_position);
            if(c>='0' && c<='9') m_position++; else break;
           }
        }
      else { error="JSON_NUMBER_INVALID"; return false; }

      if(m_position<StringLen(m_json) && StringGetCharacter(m_json,m_position)=='.')
        {
         m_position++;
         const int fraction_start=m_position;
         while(m_position<StringLen(m_json))
           {
            c=StringGetCharacter(m_json,m_position);
            if(c>='0' && c<='9') m_position++; else break;
           }
         if(m_position==fraction_start) { error="JSON_FRACTION_INVALID"; return false; }
        }
      if(m_position<StringLen(m_json))
        {
         c=StringGetCharacter(m_json,m_position);
         if(c=='e' || c=='E')
           {
            m_position++;
            if(m_position<StringLen(m_json))
              {
               c=StringGetCharacter(m_json,m_position);
               if(c=='+' || c=='-') m_position++;
              }
            const int exponent_start=m_position;
            while(m_position<StringLen(m_json))
              {
               c=StringGetCharacter(m_json,m_position);
               if(c>='0' && c<='9') m_position++; else break;
              }
            if(m_position==exponent_start) { error="JSON_EXPONENT_INVALID"; return false; }
           }
        }
      token.text=StringSubstr(m_json,start,m_position-start);
      token.number=StringToDouble(token.text);
      if(!MathIsValidNumber(token.number)) { error="JSON_NUMBER_NOT_FINITE"; return false; }
      token.type=JSON_TOKEN_NUMBER;
      return true;
     }

public:
   CStrictJsonTokenizer(void) { m_json=""; m_position=0; }

   void Reset(const string json) { m_json=json; m_position=0; }

   bool Next(SJsonToken &token,string &error)
     {
      ZeroMemory(token);
      error="";
      SkipWhitespace();
      if(m_position>=StringLen(m_json)) { token.type=JSON_TOKEN_END; return true; }
      const ushort c=StringGetCharacter(m_json,m_position);
      if(c=='{') { m_position++; token.type=JSON_TOKEN_OBJECT_BEGIN; return true; }
      if(c=='}') { m_position++; token.type=JSON_TOKEN_OBJECT_END; return true; }
      if(c=='[') { m_position++; token.type=JSON_TOKEN_ARRAY_BEGIN; return true; }
      if(c==']') { m_position++; token.type=JSON_TOKEN_ARRAY_END; return true; }
      if(c==':') { m_position++; token.type=JSON_TOKEN_COLON; return true; }
      if(c==',') { m_position++; token.type=JSON_TOKEN_COMMA; return true; }
      if(c=='"') return ReadString(token,error);
      if(c=='-' || (c>='0' && c<='9')) return ReadNumber(token,error);
      const string remaining=StringSubstr(m_json,m_position);
      if(StringFind(remaining,"true")==0) { m_position+=4; token.type=JSON_TOKEN_TRUE; return true; }
      if(StringFind(remaining,"false")==0) { m_position+=5; token.type=JSON_TOKEN_FALSE; return true; }
      if(StringFind(remaining,"null")==0) { m_position+=4; token.type=JSON_TOKEN_NULL; return true; }
      error="JSON_TOKEN_INVALID";
      return false;
     }
  };

class CDecisionResponseParser
  {
private:
   CStrictJsonTokenizer m_tokenizer;
   SJsonToken           m_current;
   string               m_error;

   bool SafeText(const string value,const int max_length,const bool allow_empty)
     {
      if((!allow_empty && StringLen(value)==0) || StringLen(value)>max_length) return false;
      for(int index=0; index<StringLen(value); index++)
         if(StringGetCharacter(value,index)<32) return false;
      return true;
     }

   bool ReasonCodeValid(const string value)
     {
      if(StringLen(value)<1 || StringLen(value)>64) return false;
      for(int index=0; index<StringLen(value); index++)
        {
         const ushort c=StringGetCharacter(value,index);
         if(!((c>='A' && c<='Z') || (c>='0' && c<='9') || c=='_')) return false;
        }
      return true;
     }

   bool Next(void) { return m_tokenizer.Next(m_current,m_error); }

   bool Expect(const EJsonTokenType type,const string error)
     {
      if(m_current.type!=type) { m_error=error; return false; }
      return true;
     }

   bool NextString(string &value,const string error)
     {
      if(!Next() || !Expect(JSON_TOKEN_STRING,error)) return false;
      value=m_current.text;
      return true;
     }

   bool NextNumber(double &value,const string error)
     {
      if(!Next() || !Expect(JSON_TOKEN_NUMBER,error)) return false;
      value=m_current.number;
      return true;
     }

   bool ParseMl(SExternalDecision &decision)
     {
      if(!Next() || !Expect(JSON_TOKEN_OBJECT_BEGIN,"ML_OBJECT_REQUIRED")) return false;
      bool has_status=false,has_model=false,has_win=false,has_return=false;
      if(!Next()) return false;
      if(m_current.type==JSON_TOKEN_OBJECT_END) { m_error="ML_OBJECT_EMPTY"; return false; }
      while(true)
        {
         if(!Expect(JSON_TOKEN_STRING,"ML_KEY_REQUIRED")) return false;
         const string key=m_current.text;
         if(!Next() || !Expect(JSON_TOKEN_COLON,"ML_COLON_REQUIRED")) return false;
         if(key=="status")
           { if(has_status || !NextString(decision.ml_status,"ML_STATUS_STRING_REQUIRED")) return false; has_status=true; }
         else if(key=="model_version")
           { if(has_model || !NextString(decision.ml_model_version,"ML_MODEL_STRING_REQUIRED")) return false; has_model=true; }
         else if(key=="win_probability")
           { if(has_win || !NextNumber(decision.ml_win_probability,"ML_WIN_NUMBER_REQUIRED")) return false; has_win=true; }
         else if(key=="expected_return")
           { if(has_return || !NextNumber(decision.ml_expected_return,"ML_RETURN_NUMBER_REQUIRED")) return false; has_return=true; }
         else { m_error="ML_UNKNOWN_FIELD"; return false; }
         if(!Next()) return false;
         if(m_current.type==JSON_TOKEN_OBJECT_END) break;
         if(!Expect(JSON_TOKEN_COMMA,"ML_COMMA_REQUIRED") || !Next()) return false;
        }
      if(!has_status || !has_model) { m_error="ML_REQUIRED_FIELD_MISSING"; return false; }
      if(decision.ml_status!="PASSED" && decision.ml_status!="REJECTED" && decision.ml_status!="ERROR")
        { m_error="ML_STATUS_INVALID"; return false; }
      if(decision.ml_status=="PASSED" && (!has_win || !has_return))
        { m_error="ML_PASSED_METRICS_MISSING"; return false; }
      if(!SafeText(decision.ml_model_version,64,false))
        { m_error="ML_MODEL_VERSION_INVALID"; return false; }
      if(has_win && (decision.ml_win_probability<0.0 || decision.ml_win_probability>1.0))
        { m_error="ML_WIN_RANGE_INVALID"; return false; }
      return true;
     }

   bool ParseLlm(SExternalDecision &decision)
     {
      if(!Next() || !Expect(JSON_TOKEN_OBJECT_BEGIN,"LLM_OBJECT_REQUIRED")) return false;
      bool has_status=false,has_provider=false,has_model=false,has_prompt=false,has_confidence=false,has_reason=false;
      if(!Next()) return false;
      if(m_current.type==JSON_TOKEN_OBJECT_END) { m_error="LLM_OBJECT_EMPTY"; return false; }
      while(true)
        {
         if(!Expect(JSON_TOKEN_STRING,"LLM_KEY_REQUIRED")) return false;
         const string key=m_current.text;
         if(!Next() || !Expect(JSON_TOKEN_COLON,"LLM_COLON_REQUIRED")) return false;
         if(key=="status")
           { if(has_status || !NextString(decision.llm_status,"LLM_STATUS_STRING_REQUIRED")) return false; has_status=true; }
         else if(key=="provider")
           { if(has_provider || !NextString(decision.llm_provider,"LLM_PROVIDER_STRING_REQUIRED")) return false; has_provider=true; }
         else if(key=="model")
           { if(has_model || !NextString(decision.llm_model,"LLM_MODEL_STRING_REQUIRED")) return false; has_model=true; }
         else if(key=="prompt_version")
           { if(has_prompt || !NextString(decision.llm_prompt_version,"LLM_PROMPT_STRING_REQUIRED")) return false; has_prompt=true; }
         else if(key=="confidence")
           { if(has_confidence || !NextNumber(decision.llm_confidence,"LLM_CONFIDENCE_NUMBER_REQUIRED")) return false; has_confidence=true; }
         else if(key=="reason")
           { if(has_reason || !NextString(decision.reason,"LLM_REASON_STRING_REQUIRED")) return false; has_reason=true; }
         else { m_error="LLM_UNKNOWN_FIELD"; return false; }
         if(!Next()) return false;
         if(m_current.type==JSON_TOKEN_OBJECT_END) break;
         if(!Expect(JSON_TOKEN_COMMA,"LLM_COMMA_REQUIRED") || !Next()) return false;
        }
      if(!has_status) { m_error="LLM_STATUS_MISSING"; return false; }
      if(decision.llm_status!="NOT_CALLED" && decision.llm_status!="ALLOW" &&
         decision.llm_status!="VETO" && decision.llm_status!="ERROR")
        { m_error="LLM_STATUS_INVALID"; return false; }
      if(decision.llm_status=="ALLOW" || decision.llm_status=="VETO")
        {
         if(!has_provider || !has_model || !has_prompt || !has_confidence || !has_reason)
           { m_error="LLM_DECISION_FIELD_MISSING"; return false; }
        }
      if(has_confidence && (decision.llm_confidence<0.0 || decision.llm_confidence>1.0))
        { m_error="LLM_CONFIDENCE_RANGE_INVALID"; return false; }
      if(has_provider && !SafeText(decision.llm_provider,32,false)) { m_error="LLM_PROVIDER_INVALID"; return false; }
      if(has_model && !SafeText(decision.llm_model,64,false)) { m_error="LLM_MODEL_INVALID"; return false; }
      if(has_prompt && !SafeText(decision.llm_prompt_version,32,false)) { m_error="LLM_PROMPT_INVALID"; return false; }
      if(has_reason && !SafeText(decision.reason,512,false)) { m_error="LLM_REASON_INVALID"; return false; }
      return true;
     }

public:
   CDecisionResponseParser(void) { m_error=""; }

   static bool ParseIso8601Utc(const string value,datetime &parsed)
     {
      parsed=0;
      if(StringLen(value)!=20 || StringSubstr(value,4,1)!="-" || StringSubstr(value,7,1)!="-" ||
         StringSubstr(value,10,1)!="T" || StringSubstr(value,13,1)!=":" ||
         StringSubstr(value,16,1)!=":" || StringSubstr(value,19,1)!="Z") return false;
      const string compact=StringSubstr(value,0,4)+StringSubstr(value,5,2)+StringSubstr(value,8,2)+
                           StringSubstr(value,11,2)+StringSubstr(value,14,2)+StringSubstr(value,17,2);
      for(int index=0; index<StringLen(compact); index++)
        {
         const ushort c=StringGetCharacter(compact,index);
         if(c<'0' || c>'9') return false;
        }
      MqlDateTime parts;
      ZeroMemory(parts);
      parts.year=(int)StringToInteger(StringSubstr(value,0,4));
      parts.mon=(int)StringToInteger(StringSubstr(value,5,2));
      parts.day=(int)StringToInteger(StringSubstr(value,8,2));
      parts.hour=(int)StringToInteger(StringSubstr(value,11,2));
      parts.min=(int)StringToInteger(StringSubstr(value,14,2));
      parts.sec=(int)StringToInteger(StringSubstr(value,17,2));
      if(parts.year<2020 || parts.mon<1 || parts.mon>12 || parts.day<1 || parts.day>31 ||
         parts.hour>23 || parts.min>59 || parts.sec>59) return false;
      int days_in_month=31;
      if(parts.mon==4 || parts.mon==6 || parts.mon==9 || parts.mon==11) days_in_month=30;
      else if(parts.mon==2)
        {
         const bool leap=(parts.year%400==0 || (parts.year%4==0 && parts.year%100!=0));
         days_in_month=(leap ? 29 : 28);
        }
      if(parts.day>days_in_month) return false;
      parsed=StructToTime(parts);
      MqlDateTime roundtrip;
      TimeToStruct(parsed,roundtrip);
      return roundtrip.year==parts.year && roundtrip.mon==parts.mon && roundtrip.day==parts.day &&
             roundtrip.hour==parts.hour && roundtrip.min==parts.min && roundtrip.sec==parts.sec;
     }

   bool Parse(const string json,SExternalDecision &decision,string &error)
     {
      ResetExternalDecision(decision);
      error="";
      m_error="";
      m_tokenizer.Reset(json);
      if(!Next() || !Expect(JSON_TOKEN_OBJECT_BEGIN,"RESPONSE_OBJECT_REQUIRED")) { error=m_error; return false; }
      bool has_schema=false,has_request=false,has_decision=false,has_reason_code=false;
      bool has_ml=false,has_llm=false,has_created=false,has_expires=false;
      string schema,created,expires;
      if(!Next()) { error=m_error; return false; }
      if(m_current.type==JSON_TOKEN_OBJECT_END) { error="RESPONSE_OBJECT_EMPTY"; return false; }
      while(true)
        {
         if(!Expect(JSON_TOKEN_STRING,"RESPONSE_KEY_REQUIRED")) { error=m_error; return false; }
         const string key=m_current.text;
         if(!Next() || !Expect(JSON_TOKEN_COLON,"RESPONSE_COLON_REQUIRED")) { error=m_error; return false; }
         if(key=="schema_version")
           { if(has_schema || !NextString(schema,"SCHEMA_STRING_REQUIRED")) { error=(has_schema ? "DUPLICATE_FIELD" : m_error); return false; } has_schema=true; }
         else if(key=="request_id")
           { if(has_request || !NextString(decision.request_id,"REQUEST_ID_STRING_REQUIRED")) { error=(has_request ? "DUPLICATE_FIELD" : m_error); return false; } has_request=true; }
         else if(key=="decision")
           { if(has_decision || !NextString(decision.decision,"DECISION_STRING_REQUIRED")) { error=(has_decision ? "DUPLICATE_FIELD" : m_error); return false; } has_decision=true; }
         else if(key=="reason_code")
           { if(has_reason_code || !NextString(decision.reason_code,"REASON_CODE_STRING_REQUIRED")) { error=(has_reason_code ? "DUPLICATE_FIELD" : m_error); return false; } has_reason_code=true; }
         else if(key=="ml")
           { if(has_ml || !ParseMl(decision)) { error=(has_ml ? "DUPLICATE_FIELD" : m_error); return false; } has_ml=true; }
         else if(key=="llm")
           { if(has_llm || !ParseLlm(decision)) { error=(has_llm ? "DUPLICATE_FIELD" : m_error); return false; } has_llm=true; }
         else if(key=="created_at")
           { if(has_created || !NextString(created,"CREATED_AT_STRING_REQUIRED")) { error=(has_created ? "DUPLICATE_FIELD" : m_error); return false; } has_created=true; }
         else if(key=="expires_at")
           { if(has_expires || !NextString(expires,"EXPIRES_AT_STRING_REQUIRED")) { error=(has_expires ? "DUPLICATE_FIELD" : m_error); return false; } has_expires=true; }
         else { error="RESPONSE_UNKNOWN_FIELD"; return false; }
         if(!Next()) { error=m_error; return false; }
         if(m_current.type==JSON_TOKEN_OBJECT_END) break;
         if(!Expect(JSON_TOKEN_COMMA,"RESPONSE_COMMA_REQUIRED") || !Next()) { error=m_error; return false; }
        }
      if(!Next() || m_current.type!=JSON_TOKEN_END) { error="RESPONSE_TRAILING_DATA"; return false; }
      if(!has_schema || !has_request || !has_decision || !has_reason_code ||
         !has_ml || !has_llm || !has_created || !has_expires)
        { error="RESPONSE_REQUIRED_FIELD_MISSING"; return false; }
      if(schema!="1.0") { error="SCHEMA_VERSION_INVALID"; return false; }
      if(decision.decision!="ALLOW" && decision.decision!="VETO") { error="DECISION_INVALID"; return false; }
      if(!ReasonCodeValid(decision.reason_code))
        { error="REASON_CODE_INVALID"; return false; }
      if(!ParseIso8601Utc(created,decision.created_at) || !ParseIso8601Utc(expires,decision.expires_at))
        { error="DECISION_TIME_INVALID"; return false; }
      return true;
     }

   static bool Validate(const string expected_request_id,const datetime now,
                        const int max_clock_skew_seconds,const int max_ttl_seconds,
                        const double min_win_probability,const double min_expected_return,
                        SExternalDecision &decision,string &error)
     {
      error="";
      if(decision.request_id!=expected_request_id) { error="REQUEST_ID_MISMATCH"; return false; }
      if(MathAbs((double)(now-decision.created_at))>max_clock_skew_seconds)
        { error="DECISION_CLOCK_SKEW"; return false; }
      if(decision.expires_at<=now || decision.expires_at<decision.created_at ||
         decision.expires_at-decision.created_at>max_ttl_seconds)
        { error="DECISION_EXPIRED_OR_TTL_INVALID"; return false; }
      if(decision.decision=="ALLOW")
        {
         if(decision.ml_status!="PASSED" || decision.ml_win_probability<min_win_probability ||
            decision.ml_expected_return<min_expected_return)
           { error="ML_THRESHOLD_NOT_MET"; return false; }
         const bool shadow_veto=(decision.llm_status=="VETO" &&
                                 decision.reason_code=="LLM_SHADOW_VETO_RECORDED");
         if(decision.llm_status!="ALLOW" && !shadow_veto)
           { error="LLM_NOT_ALLOWED"; return false; }
         decision.status=EXTERNAL_DECISION_ALLOW;
        }
      else decision.status=EXTERNAL_DECISION_VETO;
      return true;
     }
  };

#endif
