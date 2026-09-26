#property strict

#include <EaTradingSystem/External/HeartbeatApiClient.mqh>

int g_failures=0;
void AssertTrue(const bool condition,const string name)
  {
   if(condition) PrintFormat("PASS %s",name);
   else { PrintFormat("FAIL %s",name); g_failures++; }
  }

void OnStart(void)
  {
   const string heartbeat_id="0f8fad5b-d9cb-469f-a165-70867728950e";
   const datetime timestamp=D'2025.06.15 15:06:40';
   const string body=CHeartbeatRules::BuildBody(heartbeat_id,"trend-ea-v1",timestamp,"USDJPY",60,true,false,true);
   AssertTrue(body=="{\"schema_version\":\"1.0\",\"heartbeat_id\":\"0f8fad5b-d9cb-469f-a165-70867728950e\","
              "\"ea_id\":\"trend-ea-v1\",\"timestamp\":\"2025-06-15T15:06:40Z\",\"symbol\":\"USDJPY\","
              "\"interval_seconds\":60,\"terminal_connected\":true,\"trade_mutations_enabled\":false,"
              "\"kill_switch_active\":true}","heartbeat body matches contract");
   AssertTrue(CHeartbeatRules::CanonicalRequest("1750000000","nonce","hash")=="POST\n/v1/heartbeats\n1750000000\nnonce\nhash",
              "heartbeat canonical path is separate from trading APIs");

   AssertTrue(CHeartbeatRules::IsAcceptedResponse("{\"schema_version\":\"1.0\",\"heartbeat_id\":\""+heartbeat_id+"\",\"status\":\"ACCEPTED\"}",heartbeat_id),
              "accepted response is recognized");
   AssertTrue(CHeartbeatRules::IsAcceptedResponse("{\"schema_version\":\"1.0\",\"heartbeat_id\":\""+heartbeat_id+"\",\"status\":\"STALE\"}",heartbeat_id),
              "stale response is recognized");
   AssertTrue(!CHeartbeatRules::IsAcceptedResponse("{\"schema_version\":\"1.0\",\"heartbeat_id\":\"other\",\"status\":\"ACCEPTED\"}",heartbeat_id),
              "mismatched heartbeat id is rejected");
   AssertTrue(!CHeartbeatRules::IsAcceptedResponse("{\"error\":{\"code\":\"INTERNAL_ERROR\"}}",heartbeat_id),
              "error response is rejected");
   AssertTrue(!CHeartbeatRules::IsAcceptedResponse("",heartbeat_id),"empty response is rejected");

   SEaConfig config;
   SetDefaultConfig(config);
   string error;
   AssertTrue(!config.heartbeat_enabled && config.heartbeat_interval_seconds==60 && config.heartbeat_timeout_ms==1500,
              "heartbeat is disabled by default with bounded timing");
   AssertTrue(ValidateConfig(config,error),"default config validates");

   config.heartbeat_enabled=true;
   AssertTrue(!ValidateConfig(config,error) && error=="INVALID_HEARTBEAT_API_URL","heartbeat requires URL");
   config.heartbeat_api_url="https://example.invalid/v1/trade-events";
   AssertTrue(!ValidateConfig(config,error) && error=="INVALID_HEARTBEAT_API_URL","heartbeat rejects telemetry route");
   config.heartbeat_api_url="http://example.invalid/v1/heartbeats";
   AssertTrue(!ValidateConfig(config,error) && error=="INVALID_HEARTBEAT_API_URL","heartbeat requires HTTPS");
   config.heartbeat_api_url="https://example.invalid/v1/heartbeats";
   AssertTrue(!ValidateConfig(config,error) && error=="HEARTBEAT_CREDENTIAL_CONFIG_MISSING","heartbeat requires key id");
   config.decision_api_key_id="trend-ea-dev";
   AssertTrue(ValidateConfig(config,error),"valid heartbeat config validates");
   config.heartbeat_interval_seconds=29;
   AssertTrue(!ValidateConfig(config,error) && error=="INVALID_HEARTBEAT_TIMING","too frequent heartbeat is rejected");
   config.heartbeat_interval_seconds=901;
   AssertTrue(!ValidateConfig(config,error) && error=="INVALID_HEARTBEAT_TIMING","too sparse heartbeat is rejected");
   config.heartbeat_interval_seconds=30;
   config.heartbeat_timeout_ms=3001;
   AssertTrue(!ValidateConfig(config,error) && error=="INVALID_HEARTBEAT_TIMING",
              "heartbeat timeout must stay far below interval");

   SEaConfig disabled_config;
   SetDefaultConfig(disabled_config);
   CHeartbeatApiClient disabled_client;
   AssertTrue(disabled_client.Initialize(disabled_config,error) && !disabled_client.Enabled(),
              "disabled heartbeat initializes without secret");
   AssertTrue(!disabled_client.Send(true,false,error) && error=="HEARTBEAT_CLIENT_NOT_ENABLED",
              "disabled heartbeat never sends");

   SEaConfig missing_secret_config;
   SetDefaultConfig(missing_secret_config);
   missing_secret_config.heartbeat_enabled=true;
   missing_secret_config.decision_api_secret_file="EaTradingSystem\\heartbeat-test-missing-secret.txt";
   CHeartbeatApiClient missing_secret_client;
   AssertTrue(!missing_secret_client.Initialize(missing_secret_config,error) &&
              StringFind(error,"HEARTBEAT_SECRET_FILE_OPEN_FAILED")==0 && !missing_secret_client.Enabled(),
              "missing secret disables heartbeat only");

   if(g_failures==0) Print("TEST_SUITE_PASS TestHeartbeatRules");
   else PrintFormat("TEST_SUITE_FAIL TestHeartbeatRules failures=%d",g_failures);
  }
