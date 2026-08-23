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
input double          InpPullbackTriggerAtrBuffer=0.0;
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
input bool            InpEntryUseStagedPipeline=false;
input bool            InpEntryRequireMarketRegimeTrend=true;
input double          InpRegimeTrendAdxMin=20.0;
input int             InpRegimeAtrBaselinePeriod=50;
input double          InpRegimeHighVolatilityRatio=1.3;
input double          InpRegimeLowVolatilityRatio=0.7;
input int             InpRegimeMaSlopeLookback=5;
input int             InpRegimeTrendPersistenceBars=1;
input double          InpRiskPerTradePercent=0.5;
input double          InpDailyLossLimitPercent=2.0;
input double          InpMaxDrawdownPercent=10.0;
input int             InpMaxOpenPositions=1;
input int             InpMaxSameDirectionPositions=1;
input double          InpMaxOpenRiskPercent=2.0;
input double          InpMinSameDirectionEntryDistancePoints=0.0;
input double          InpMinMarginLevelPercent=150.0;
input double          InpMaxSpreadPoints=30.0;
input double          InpMinimumFreeMarginPercent=20.0;
input ulong           InpMagicNumber=26072001;
input int             InpMaxDeviationPoints=10;
input bool            InpEmergencyStop=false;
input bool            InpStrategyEnabled=true;
input bool            InpEnableTradeMutations=false;
input bool            InpCloseUnprotectedPositions=true;
input bool            InpEnableBreakevenStop=true;
input double          InpBreakevenTriggerR=1.0;
input bool            InpEnableSignalInvalidationExit=true;
input bool            InpSignalExitCheckTrend=true;
input bool            InpSignalExitCheckH1Adx=true;
input bool            InpSignalExitCheckH4Adx=true;
input bool            InpEnableTimeStop=true;
input int             InpMaxHoldingBars=20;
input bool            InpTimeStopRequireMinMfe=true;
input double          InpTimeStopMinMfeR=0.5;
input bool            InpEnableEntryTimingAnalysis=false;
input int             InpEntryTimingMaxWaitBars=6;
input int             InpEntryTimingMaxHoldingBars=20;
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
   config.pullback_trigger_atr_buffer=InpPullbackTriggerAtrBuffer;
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
   config.entry_use_staged_pipeline=InpEntryUseStagedPipeline;
   config.entry_require_market_regime_trend=InpEntryRequireMarketRegimeTrend;
   config.regime_trend_adx_min=InpRegimeTrendAdxMin;
   config.regime_atr_baseline_period=InpRegimeAtrBaselinePeriod;
   config.regime_high_volatility_ratio=InpRegimeHighVolatilityRatio;
   config.regime_low_volatility_ratio=InpRegimeLowVolatilityRatio;
   config.regime_ma_slope_lookback=InpRegimeMaSlopeLookback;
   config.regime_trend_persistence_bars=InpRegimeTrendPersistenceBars;
   config.risk_per_trade_rate=InpRiskPerTradePercent/100.0;
   config.daily_loss_limit_rate=InpDailyLossLimitPercent/100.0;
   config.max_drawdown_rate=InpMaxDrawdownPercent/100.0;
   config.max_open_positions=InpMaxOpenPositions;
   config.max_same_direction_positions=InpMaxSameDirectionPositions;
   config.max_open_risk_rate=InpMaxOpenRiskPercent/100.0;
   config.min_same_direction_entry_distance_points=InpMinSameDirectionEntryDistancePoints;
   config.min_margin_level_percent=InpMinMarginLevelPercent;
   config.max_spread_points=InpMaxSpreadPoints;
   config.minimum_free_margin_rate=InpMinimumFreeMarginPercent/100.0;
   config.magic_number=InpMagicNumber;
   config.max_deviation_points=InpMaxDeviationPoints;
   config.emergency_stop=InpEmergencyStop;
   config.strategy_enabled=InpStrategyEnabled;
   config.enable_trade_mutations=InpEnableTradeMutations;
   config.close_unprotected_positions=InpCloseUnprotectedPositions;
   config.enable_breakeven_stop=InpEnableBreakevenStop;
   config.breakeven_trigger_r_multiple=InpBreakevenTriggerR;
   config.enable_signal_invalidation_exit=InpEnableSignalInvalidationExit;
   config.signal_exit_check_trend=InpSignalExitCheckTrend;
   config.signal_exit_check_h1_adx=InpSignalExitCheckH1Adx;
   config.signal_exit_check_h4_adx=InpSignalExitCheckH4Adx;
   config.enable_time_stop=InpEnableTimeStop;
   config.max_holding_bars=InpMaxHoldingBars;
   config.time_stop_require_min_mfe=InpTimeStopRequireMinMfe;
   config.time_stop_min_mfe_r_multiple=InpTimeStopMinMfeR;
   config.enable_entry_timing_analysis=InpEnableEntryTimingAnalysis;
   config.entry_timing_max_wait_bars=InpEntryTimingMaxWaitBars;
   config.entry_timing_max_holding_bars=InpEntryTimingMaxHoldingBars;
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
