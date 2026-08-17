#property copyright "EA Trading System"
#property version   "1.13"
#property strict
#property description "Phase 12 production-gated EA with local Risk authority and auditable external filters."

#include <EaTradingSystem/Core/EAController.mqh>

input string          InpEaId="trend-ea-v1";
input string          InpSymbol="";
input ENUM_TIMEFRAMES InpTrendTimeframe=PERIOD_D1;
input ENUM_TIMEFRAMES InpConfirmationTimeframe=PERIOD_H4;
input ENUM_TIMEFRAMES InpEntryTimeframe=PERIOD_H1;
input int             InpFastEmaPeriod=50;
input int             InpSlowEmaPeriod=200;
input int             InpRsiPeriod=14;
input int             InpAtrPeriod=14;
input int             InpBreakoutLookback=20;
input double          InpBreakoutBufferPoints=0.0;
input double          InpPullbackAtrTolerance=0.15;
input double          InpRsiBuyMin=50.0;
input double          InpRsiBuyMax=75.0;
input double          InpRsiSellMin=25.0;
input double          InpRsiSellMax=50.0;
input double          InpMinimumAtrPoints=10.0;
input int             InpAdxPeriod=14;
input double          InpMinimumAdx=20.0;
input double          InpMinimumConfirmationAdx=20.0;
input double          InpStopAtrMultiple=2.0;
input double          InpRiskRewardRatio=2.0;
input bool            InpEnableBreakout=true;
input bool            InpEnablePullback=true;
input double          InpRiskPerTradePercent=0.5;
input double          InpDailyLossLimitPercent=2.0;
input double          InpMaxDrawdownPercent=10.0;
input int             InpMaxOpenPositions=1;
input double          InpMaxSpreadPoints=30.0;
input double          InpMinimumFreeMarginPercent=20.0;
input ulong           InpMagicNumber=26072001;
input int             InpMaxDeviationPoints=10;
input bool            InpEmergencyStop=false;
input bool            InpStrategyEnabled=true;
input bool            InpEnableTradeMutations=false;
input bool            InpCloseUnprotectedPositions=true;
input bool            InpDecisionApiEnabled=false;
input string          InpDecisionApiUrl="";
input string          InpDecisionApiKeyId="";
input string          InpDecisionApiSecretFile="EaTradingSystem\\decision-api-secret.txt";
input int             InpDecisionApiTimeoutMs=4500;
input int             InpDecisionMaxClockSkewSeconds=60;
input int             InpDecisionMaxTtlSeconds=60;
input double          InpMlMinWinProbability=0.60;
input double          InpMlMinExpectedReturn=0.0;
input bool            InpAuditFileEnabled=true;
input string          InpAuditLogDirectory="EaTradingSystem\\Audit";
input bool            InpTelemetryEnabled=false;
input string          InpTelemetryApiUrl="";
input int             InpTelemetryTimeoutMs=1500;
input ETesterDecisionMode InpTesterDecisionMode=TESTER_DECISION_FAIL_SAFE;
input double          InpTesterFixedMlProbability=0.65;
input bool            InpTesterResetPersistentState=true;

CEAController g_controller;

int OnInit(void)
  {
   SEaConfig config;
   SetDefaultConfig(config);
   config.ea_id=InpEaId;
   config.symbol=(StringLen(InpSymbol)>0 ? InpSymbol : _Symbol);
   config.trend_timeframe=InpTrendTimeframe;
   config.confirmation_timeframe=InpConfirmationTimeframe;
   config.entry_timeframe=InpEntryTimeframe;
   config.fast_ema_period=InpFastEmaPeriod;
   config.slow_ema_period=InpSlowEmaPeriod;
   config.rsi_period=InpRsiPeriod;
   config.atr_period=InpAtrPeriod;
   config.breakout_lookback=InpBreakoutLookback;
   config.breakout_buffer_points=InpBreakoutBufferPoints;
   config.pullback_atr_tolerance=InpPullbackAtrTolerance;
   config.rsi_buy_min=InpRsiBuyMin;
   config.rsi_buy_max=InpRsiBuyMax;
   config.rsi_sell_min=InpRsiSellMin;
   config.rsi_sell_max=InpRsiSellMax;
   config.minimum_atr_points=InpMinimumAtrPoints;
   config.adx_period=InpAdxPeriod;
   config.minimum_adx=InpMinimumAdx;
   config.minimum_confirmation_adx=InpMinimumConfirmationAdx;
   config.stop_atr_multiple=InpStopAtrMultiple;
   config.risk_reward_ratio=InpRiskRewardRatio;
   config.enable_breakout=InpEnableBreakout;
   config.enable_pullback=InpEnablePullback;
   config.risk_per_trade_rate=InpRiskPerTradePercent/100.0;
   config.daily_loss_limit_rate=InpDailyLossLimitPercent/100.0;
   config.max_drawdown_rate=InpMaxDrawdownPercent/100.0;
   config.max_open_positions=InpMaxOpenPositions;
   config.max_spread_points=InpMaxSpreadPoints;
   config.minimum_free_margin_rate=InpMinimumFreeMarginPercent/100.0;
   config.magic_number=InpMagicNumber;
   config.max_deviation_points=InpMaxDeviationPoints;
   config.emergency_stop=InpEmergencyStop;
   config.strategy_enabled=InpStrategyEnabled;
   config.enable_trade_mutations=InpEnableTradeMutations;
   config.close_unprotected_positions=InpCloseUnprotectedPositions;
   config.decision_api_enabled=InpDecisionApiEnabled;
   config.decision_api_url=InpDecisionApiUrl;
   config.decision_api_key_id=InpDecisionApiKeyId;
   config.decision_api_secret_file=InpDecisionApiSecretFile;
   config.decision_api_timeout_ms=InpDecisionApiTimeoutMs;
   config.decision_max_clock_skew_seconds=InpDecisionMaxClockSkewSeconds;
   config.decision_max_ttl_seconds=InpDecisionMaxTtlSeconds;
   config.ml_min_win_probability=InpMlMinWinProbability;
   config.ml_min_expected_return=InpMlMinExpectedReturn;
   config.audit_file_enabled=InpAuditFileEnabled;
   config.audit_log_directory=InpAuditLogDirectory;
   config.telemetry_enabled=InpTelemetryEnabled;
   config.telemetry_api_url=InpTelemetryApiUrl;
   config.telemetry_timeout_ms=InpTelemetryTimeoutMs;
   config.tester_decision_mode=(int)InpTesterDecisionMode;
   config.tester_fixed_ml_probability=InpTesterFixedMlProbability;
   config.tester_reset_persistent_state=InpTesterResetPersistentState;

   string error;
   if(!g_controller.Initialize(config,error))
     {
      PrintFormat("EA_INIT_FAILED code=%s last_error=%d",error,GetLastError());
      return INIT_FAILED;
     }
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   g_controller.Shutdown();
   PrintFormat("EA_DEINIT reason=%d",reason);
  }

void OnTick(void)
  {
   g_controller.OnTick();
  }

void OnTradeTransaction(const MqlTradeTransaction &transaction,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   g_controller.OnTradeTransaction(transaction);
  }
