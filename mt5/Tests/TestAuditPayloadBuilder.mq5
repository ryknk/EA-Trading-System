#property strict

#include <EaTradingSystem/Logging/AuditPayloadBuilder.mqh>

int g_failures=0;

void AssertTrue(const bool condition,const string name)
  {
   if(condition) PrintFormat("PASS %s",name);
   else { PrintFormat("FAIL %s",name); g_failures++; }
  }

void OnStart(void)
  {
   AssertTrue(CAuditPayloadBuilder::JString("a\"b")=="\"a\\\"b\"","JString escapes double quotes");
   AssertTrue(CAuditPayloadBuilder::JNumber(1.5)=="1.5000000000","JNumber formats with 10 decimals");
   AssertTrue(CAuditPayloadBuilder::JBool(true)=="true","JBool true");
   AssertTrue(CAuditPayloadBuilder::JBool(false)=="false","JBool false");

   MqlDateTime parts;
   ZeroMemory(parts);
   parts.year=2026; parts.mon=1; parts.day=2; parts.hour=3; parts.min=4; parts.sec=5;
   const datetime sample=StructToTime(parts);
   AssertTrue(CAuditPayloadBuilder::Iso8601Utc(sample)=="2026-01-02T03:04:05Z","Iso8601Utc formats UTC timestamp");

   SEntryTimingSetupEvent setup;
   ZeroMemory(setup);
   setup.setup_id="setup-1";
   setup.setup_bar_time=sample;
   setup.direction=SIGNAL_DIRECTION_BUY;
   setup.pre_entry_mfe_price=1.1;
   setup.pre_entry_mfe_r=1.2;
   setup.pre_entry_mfe_time=sample;
   setup.pre_entry_mae_price=1.3;
   setup.pre_entry_mae_r=1.4;
   setup.pre_entry_mae_time=sample;
   setup.trigger_found=true;
   setup.trigger_wait_bars=3;
   const string setup_payload=CAuditPayloadBuilder::BuildEntryTimingSetupPayload(setup);
   AssertTrue(StringFind(setup_payload,"\"direction\":\"BUY\"")>=0,"entry timing setup payload has direction");
   AssertTrue(StringFind(setup_payload,"\"trigger_found\":true")>=0,"entry timing setup payload has trigger_found");
   AssertTrue(StringFind(setup_payload,"\"trigger_wait_bars\":3")>=0,"entry timing setup payload has trigger_wait_bars");

   SEntryTimingTradeEvent trade;
   ZeroMemory(trade);
   trade.setup_id="setup-1";
   trade.variant=ENTRY_TIMING_WAIT_1_BAR;
   trade.entry_bar_time=sample;
   trade.direction=SIGNAL_DIRECTION_SELL;
   trade.exit_reason="TP";
   trade.checkpoint_valid[0]=true;
   trade.checkpoint_r[0]=0.5;
   const string trade_payload=CAuditPayloadBuilder::BuildEntryTimingTradePayload(trade);
   AssertTrue(StringFind(trade_payload,"\"variant\":\"WAIT_1_BAR\"")>=0,"entry timing trade payload has variant");
   AssertTrue(StringFind(trade_payload,"\"exit_reason\":\"TP\"")>=0,"entry timing trade payload has exit_reason");
   AssertTrue(StringFind(trade_payload,"\"checkpoint_r\":{\"bars_1\":0.5000000000}")>=0,
              "entry timing trade payload aggregates only valid checkpoints");

   SClosedPositionEvent closed;
   ZeroMemory(closed);
   closed.position_ticket=12345;
   closed.direction="BUY";
   closed.open_time=sample;
   closed.close_time=sample;
   closed.volume=0.1;
   closed.open_price=150.0;
   closed.close_price=151.0;
   closed.close_reason="TP";
   closed.pnl=100.0;
   closed.commission=-1.0;
   closed.swap=-0.5;
   closed.exit_spread_points=2.0;
   closed.point_value=1000.0;
   const string closed_payload=CAuditPayloadBuilder::BuildClosedPositionPayload(closed);
   AssertTrue(StringFind(closed_payload,"\"position_ticket\":\"12345\"")>=0,"closed payload has position_ticket");
   AssertTrue(StringFind(closed_payload,"\"close_reason\":\"TP\"")>=0,"closed payload has close_reason");
   AssertTrue(StringFind(closed_payload,"\"point_value\":1000.0000000000")>=0,"closed payload has point_value");

   const string analytics_payload=CAuditPayloadBuilder::BuildClosedPositionAnalyticsPayload(12345,10.0,-5.0);
   AssertTrue(StringFind(analytics_payload,"\"mfe\":10.0000000000")>=0,"analytics payload has mfe");
   AssertTrue(StringFind(analytics_payload,"\"mae\":-5.0000000000")>=0,"analytics payload has mae");

   if(g_failures==0) Print("TEST_SUITE_PASS TestAuditPayloadBuilder");
   else PrintFormat("TEST_SUITE_FAIL TestAuditPayloadBuilder failures=%d",g_failures);
  }
