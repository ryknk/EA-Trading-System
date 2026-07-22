#property strict

#include <EaTradingSystem/External/CryptoUtils.mqh>
#include <EaTradingSystem/External/StrictJson.mqh>

int g_failures=0;

void AssertTrue(const bool condition,const string name)
  {
   if(condition) PrintFormat("PASS %s",name);
   else { PrintFormat("FAIL %s",name); g_failures++; }
  }

string AllowResponse(const string request_id,const string decision="ALLOW",
                     const double probability=0.68,const string llm_status="ALLOW",
                     const string reason_code="ALL_CHECKS_PASSED")
  {
   return "{\"schema_version\":\"1.0\",\"request_id\":\""+request_id+
          "\",\"decision\":\""+decision+"\",\"reason_code\":\""+reason_code+"\","+
          "\"ml\":{\"status\":\"PASSED\",\"win_probability\":"+DoubleToString(probability,2)+
          ",\"expected_return\":0.0035,\"model_version\":\"v1\"},"+
          "\"llm\":{\"status\":\""+llm_status+"\",\"provider\":\"test\",\"model\":\"model-1\","+
          "\"prompt_version\":\"p1\",\"confidence\":0.72,\"reason\":\"Trend aligned.\"},"+
          "\"created_at\":\"2026-07-20T12:00:00Z\",\"expires_at\":\"2026-07-20T12:00:30Z\"}";
  }

void OnStart(void)
  {
   string output;
   AssertTrue(CCryptoUtils::Sha256Hex("abc",output) &&
              output=="ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
              "SHA-256 known vector");
   AssertTrue(CCryptoUtils::HmacSha256Hex("key","The quick brown fox jumps over the lazy dog",output) &&
              output=="f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8",
              "HMAC-SHA256 known vector");
   AssertTrue(CCryptoUtils::JsonEscape("a\"b\\c\n")=="a\\\"b\\\\c\\n","JSON escaping");
   string uuid;
   AssertTrue(CCryptoUtils::GenerateUuid(uuid) && StringLen(uuid)==36 &&
              StringSubstr(uuid,8,1)=="-" && StringSubstr(uuid,13,1)=="-",
              "UUID shape");

   const string request_id="123e4567-e89b-42d3-a456-426614174000";
   CDecisionResponseParser parser;
   SExternalDecision decision;
   string error;
   const datetime now=D'2026.07.20 12:00:10';
   AssertTrue(parser.Parse(AllowResponse(request_id),decision,error),"valid ALLOW JSON parsed");
   AssertTrue(CDecisionResponseParser::Validate(request_id,now,60,60,0.60,0.0,decision,error) &&
              decision.status==EXTERNAL_DECISION_ALLOW,"valid ALLOW response accepted");

   AssertTrue(!parser.Parse("{\"schema_version\":\"1.0\" \"request_id\":\"x\"}",decision,error),
              "missing comma rejected");
   AssertTrue(!parser.Parse(AllowResponse(request_id)+" trailing",decision,error),"trailing data rejected");
   string unknown=AllowResponse(request_id);
   StringReplace(unknown,"\"created_at\"","\"unknown\":1,\"created_at\"");
   AssertTrue(!parser.Parse(unknown,decision,error),"unknown field rejected");
   AssertTrue(!parser.Parse(AllowResponse(request_id,"BUY"),decision,error),"invalid decision rejected");
   string bad_reason_code=AllowResponse(request_id);
   StringReplace(bad_reason_code,"ALL_CHECKS_PASSED","invalid-code");
   AssertTrue(!parser.Parse(bad_reason_code,decision,error),"invalid reason code rejected");
   string log_injection=AllowResponse(request_id);
   StringReplace(log_injection,"Trend aligned.","Trend\\naligned.");
   AssertTrue(!parser.Parse(log_injection,decision,error),"log control character rejected");

   AssertTrue(parser.Parse(AllowResponse(request_id),decision,error) &&
              !CDecisionResponseParser::Validate("different-id",now,60,60,0.60,0.0,decision,error),
              "request id mismatch rejected");
   AssertTrue(parser.Parse(AllowResponse(request_id),decision,error) &&
              !CDecisionResponseParser::Validate(request_id,D'2026.07.20 12:00:31',60,60,0.60,0.0,decision,error),
              "expired response rejected");
   AssertTrue(parser.Parse(AllowResponse(request_id,"ALLOW",0.59),decision,error) &&
              !CDecisionResponseParser::Validate(request_id,now,60,60,0.60,0.0,decision,error),
              "ML threshold failure rejected");
   AssertTrue(parser.Parse(AllowResponse(request_id,"ALLOW",0.68,"VETO"),decision,error) &&
              !CDecisionResponseParser::Validate(request_id,now,60,60,0.60,0.0,decision,error),
              "LLM veto blocks overall ALLOW");
   AssertTrue(parser.Parse(AllowResponse(request_id,"ALLOW",0.68,"VETO","LLM_SHADOW_VETO_RECORDED"),decision,error) &&
              CDecisionResponseParser::Validate(request_id,now,60,60,0.60,0.0,decision,error) &&
              decision.status==EXTERNAL_DECISION_ALLOW,
              "explicit shadow veto is recorded but not applied");

   const string veto="{\"schema_version\":\"1.0\",\"request_id\":\""+request_id+
                     "\",\"decision\":\"VETO\",\"reason_code\":\"ML_REJECTED\","+
                     "\"ml\":{\"status\":\"REJECTED\",\"model_version\":\"v1\"},"+
                     "\"llm\":{\"status\":\"NOT_CALLED\"},"+
                     "\"created_at\":\"2026-07-20T12:00:00Z\",\"expires_at\":\"2026-07-20T12:00:30Z\"}";
   AssertTrue(parser.Parse(veto,decision,error) &&
              CDecisionResponseParser::Validate(request_id,now,60,60,0.60,0.0,decision,error) &&
              decision.status==EXTERNAL_DECISION_VETO,"valid VETO accepted without LLM call");

   datetime parsed_time;
   AssertTrue(!CDecisionResponseParser::ParseIso8601Utc("2026-02-30T12:00:00Z",parsed_time),
              "invalid calendar date rejected");

   // Expected malformed-input cases can set the terminal last-error value.
   ResetLastError();
   if(g_failures==0) Print("TEST_SUITE_PASS TestDecisionApiRules");
   else PrintFormat("TEST_SUITE_FAIL TestDecisionApiRules failures=%d",g_failures);
  }
