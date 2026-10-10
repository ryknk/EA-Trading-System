#property strict

// 製品ビルド（EA_TRADING_SYSTEM_RESEARCH_BUILD未定義）でEAの入口・中核がコンパイルでき、研究計測
// （Entry/Breakout Timing分析器と研究フック、DEC-045）と外部連携（Decision API、Tester判断Mock、Heartbeat、
// Telemetry、DEC-046）がinclude経路に含まれないことを検査する。本Scriptはマクロを定義しないままEAControllerを
// includeする。EAのイベント関数を持つEAEntryPoint.mqhは、ProductEA.mq5のコンパイルで確認する。

#include <EaTradingSystem/Core/EAController.mqh>

int g_failures=0;

void AssertTrue(const bool condition,const string name)
  {
   if(condition) PrintFormat("PASS %s",name);
   else { PrintFormat("FAIL %s",name); g_failures++; }
  }

void OnStart(void)
  {
   bool research_build_defined=false;
   bool hook_included=false;
   bool entry_timing_included=false;
   bool breakout_timing_included=false;
   bool decision_api_included=false;
   bool mock_decision_included=false;
   bool heartbeat_included=false;
   bool telemetry_included=false;
#ifdef EA_TRADING_SYSTEM_RESEARCH_BUILD
   research_build_defined=true;
#endif
#ifdef EA_TRADING_SYSTEM_TIMING_ANALYSIS_HOOK_MQH
   hook_included=true;
#endif
#ifdef EA_TRADING_SYSTEM_ENTRY_TIMING_ANALYZER_MQH
   entry_timing_included=true;
#endif
#ifdef EA_TRADING_SYSTEM_BREAKOUT_TIMING_ANALYZER_MQH
   breakout_timing_included=true;
#endif
#ifdef EA_TRADING_SYSTEM_DECISION_API_CLIENT_MQH
   decision_api_included=true;
#endif
#ifdef EA_TRADING_SYSTEM_MOCK_DECISION_PROVIDER_MQH
   mock_decision_included=true;
#endif
#ifdef EA_TRADING_SYSTEM_HEARTBEAT_API_CLIENT_MQH
   heartbeat_included=true;
#endif
#ifdef EA_TRADING_SYSTEM_TELEMETRY_API_CLIENT_MQH
   telemetry_included=true;
#endif
   AssertTrue(!research_build_defined,"product build does not define research build macro");
   AssertTrue(!hook_included,"product build does not include timing analysis hook");
   AssertTrue(!entry_timing_included,"product build does not include entry timing analyzer");
   AssertTrue(!breakout_timing_included,"product build does not include breakout timing analyzer");
   AssertTrue(!decision_api_included,"product build does not include decision api client");
   AssertTrue(!mock_decision_included,"product build does not include tester mock decision provider");
   AssertTrue(!heartbeat_included,"product build does not include heartbeat api client");
   AssertTrue(!telemetry_included,"product build does not include telemetry api client");

   if(g_failures==0) Print("TEST_SUITE_PASS TestProductBuildWithoutResearch");
   else PrintFormat("TEST_SUITE_FAIL TestProductBuildWithoutResearch failures=%d",g_failures);
  }
