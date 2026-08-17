#ifndef EA_TRADING_SYSTEM_CORE_CONFIG_MQH
#define EA_TRADING_SYSTEM_CORE_CONFIG_MQH

struct SEaConfig
  {
   string            ea_id;
   string            symbol;
   ENUM_TIMEFRAMES   trend_timeframe;
   ENUM_TIMEFRAMES   confirmation_timeframe;
   ENUM_TIMEFRAMES   entry_timeframe;
   int               slow_ema_period;
   int               fast_ema_period;
   int               rsi_period;
   int               atr_period;
   int               breakout_lookback;
   double            breakout_buffer_points;
   double            pullback_atr_tolerance;
   double            rsi_buy_min;
   double            rsi_buy_max;
   double            rsi_sell_min;
   double            rsi_sell_max;
   double            minimum_atr_points;
   int               adx_period;
   double            minimum_adx;
   double            minimum_confirmation_adx;
   double            stop_atr_multiple;
   double            risk_reward_ratio;
   bool              enable_breakout;
   bool              enable_pullback;
   double            regime_trend_adx_min;
   int               regime_atr_baseline_period;
   double            regime_high_volatility_ratio;
   double            regime_low_volatility_ratio;
   int               regime_ma_slope_lookback;
   double            risk_per_trade_rate;
   double            daily_loss_limit_rate;
   double            max_drawdown_rate;
   int               max_open_positions;
   double            max_spread_points;
   double            minimum_free_margin_rate;
   ulong             magic_number;
   int               max_deviation_points;
   bool              emergency_stop;
   bool              strategy_enabled;
   bool              enable_trade_mutations;
   bool              close_unprotected_positions;
   bool              decision_api_enabled;
   string            decision_api_url;
   string            decision_api_key_id;
   string            decision_api_secret_file;
   int               decision_api_timeout_ms;
   int               decision_max_clock_skew_seconds;
   int               decision_max_ttl_seconds;
   double            ml_min_win_probability;
   double            ml_min_expected_return;
   bool              audit_file_enabled;
   string            audit_log_directory;
   bool              telemetry_enabled;
   string            telemetry_api_url;
   int               telemetry_timeout_ms;
   int               tester_decision_mode;
   double            tester_fixed_ml_probability;
   bool              tester_reset_persistent_state;
  };

void SetDefaultConfig(SEaConfig &config)
  {
   config.ea_id                     = "trend-ea-v1";
   config.symbol                    = _Symbol;
   config.trend_timeframe           = PERIOD_D1;
   config.confirmation_timeframe    = PERIOD_H4;
   config.entry_timeframe           = PERIOD_H1;
   config.slow_ema_period           = 200;
   config.fast_ema_period           = 50;
   config.rsi_period                = 14;
   config.atr_period                = 14;
   config.breakout_lookback         = 20;
   config.breakout_buffer_points    = 0.0;
   config.pullback_atr_tolerance    = 0.15;
   config.rsi_buy_min               = 50.0;
   config.rsi_buy_max               = 75.0;
   config.rsi_sell_min              = 25.0;
   config.rsi_sell_max              = 50.0;
   config.minimum_atr_points        = 10.0;
   config.adx_period                = 14;
   config.minimum_adx               = 20.0;
   config.minimum_confirmation_adx  = 20.0;
   config.stop_atr_multiple         = 2.0;
   config.risk_reward_ratio         = 2.0;
   config.enable_breakout           = true;
   config.enable_pullback           = true;
   config.regime_trend_adx_min      = 20.0;
   config.regime_atr_baseline_period = 50;
   config.regime_high_volatility_ratio = 1.3;
   config.regime_low_volatility_ratio  = 0.7;
   config.regime_ma_slope_lookback  = 5;
   config.risk_per_trade_rate       = 0.005;
   config.daily_loss_limit_rate     = 0.02;
   config.max_drawdown_rate         = 0.10;
   config.max_open_positions        = 1;
   config.max_spread_points         = 30.0;
   config.minimum_free_margin_rate  = 0.20;
   config.magic_number              = 26072001;
   config.max_deviation_points      = 10;
   config.emergency_stop            = false;
   config.strategy_enabled          = true;
   config.enable_trade_mutations    = false;
   config.close_unprotected_positions = true;
   config.decision_api_enabled       = false;
   config.decision_api_url           = "";
   config.decision_api_key_id        = "";
   config.decision_api_secret_file   = "EaTradingSystem\\decision-api-secret.txt";
   config.decision_api_timeout_ms    = 4500;
   config.decision_max_clock_skew_seconds = 60;
   config.decision_max_ttl_seconds   = 60;
   config.ml_min_win_probability     = 0.60;
   config.ml_min_expected_return     = 0.0;
   config.audit_file_enabled         = true;
   config.audit_log_directory        = "EaTradingSystem\\Audit";
   config.telemetry_enabled          = false;
   config.telemetry_api_url          = "";
   config.telemetry_timeout_ms       = 1500;
   config.tester_decision_mode       = 0;
   config.tester_fixed_ml_probability = 0.65;
   config.tester_reset_persistent_state = true;
  }

bool IsSafeConfigIdentifier(const string value)
  {
   if(StringLen(value)<1 || StringLen(value)>64) return false;
   for(int index=0; index<StringLen(value); index++)
     {
      const ushort c=StringGetCharacter(value,index);
      if(!((c>='A' && c<='Z') || (c>='a' && c<='z') || (c>='0' && c<='9') ||
           c=='.' || c=='_' || c=='-')) return false;
     }
   return true;
  }

bool ValidateConfig(const SEaConfig &config,string &error)
  {
   error="";
   if(StringLen(config.ea_id)<1 || StringLen(config.ea_id)>64)
     { error="INVALID_EA_ID"; return false; }
   if(StringLen(config.symbol)<1)
     { error="INVALID_SYMBOL"; return false; }
   if(config.fast_ema_period<2 || config.slow_ema_period<=config.fast_ema_period)
     { error="INVALID_EMA_PERIODS"; return false; }
   if(config.rsi_period<2 || config.atr_period<2 || config.breakout_lookback<2)
     { error="INVALID_INDICATOR_PERIOD"; return false; }
   if(config.breakout_buffer_points<0.0 || config.pullback_atr_tolerance<0.0)
     { error="INVALID_ENTRY_TOLERANCE"; return false; }
   if(config.rsi_buy_min<0.0 || config.rsi_buy_max>100.0 || config.rsi_buy_min>config.rsi_buy_max)
     { error="INVALID_BUY_RSI_RANGE"; return false; }
   if(config.rsi_sell_min<0.0 || config.rsi_sell_max>100.0 || config.rsi_sell_min>config.rsi_sell_max)
     { error="INVALID_SELL_RSI_RANGE"; return false; }
   if(config.minimum_atr_points<0.0 || config.stop_atr_multiple<=0.0 || config.risk_reward_ratio<=0.0)
     { error="INVALID_RISK_GEOMETRY"; return false; }
   if(config.adx_period<2 || config.minimum_adx<0.0 || config.minimum_adx>100.0 ||
      config.minimum_confirmation_adx<0.0 || config.minimum_confirmation_adx>100.0)
     { error="INVALID_TREND_STRENGTH_FILTER"; return false; }
   if(!config.enable_breakout && !config.enable_pullback)
     { error="NO_ENTRY_PATTERN_ENABLED"; return false; }
   if(config.regime_trend_adx_min<0.0 || config.regime_trend_adx_min>100.0)
     { error="INVALID_REGIME_TREND_ADX_MIN"; return false; }
   if(config.regime_atr_baseline_period<2 || config.regime_ma_slope_lookback<1)
     { error="INVALID_REGIME_LOOKBACK_PERIOD"; return false; }
   if(config.regime_high_volatility_ratio<=1.0 ||
      config.regime_low_volatility_ratio<=0.0 || config.regime_low_volatility_ratio>=1.0)
     { error="INVALID_REGIME_VOLATILITY_RATIO"; return false; }
   if(config.risk_per_trade_rate<=0.0 || config.risk_per_trade_rate>0.05)
     { error="INVALID_TRADE_RISK_RATE"; return false; }
   if(config.daily_loss_limit_rate<=0.0 || config.daily_loss_limit_rate>0.20)
     { error="INVALID_DAILY_LOSS_RATE"; return false; }
   if(config.max_drawdown_rate<=0.0 || config.max_drawdown_rate>0.50)
     { error="INVALID_DRAWDOWN_RATE"; return false; }
   if(config.max_open_positions<1 || config.max_spread_points<=0.0)
     { error="INVALID_EXPOSURE_OR_SPREAD_LIMIT"; return false; }
   if(config.minimum_free_margin_rate<0.0 || config.minimum_free_margin_rate>=1.0 || config.max_deviation_points<0)
     { error="INVALID_MARGIN_OR_DEVIATION_LIMIT"; return false; }
   if(config.magic_number==0)
     { error="INVALID_MAGIC_NUMBER"; return false; }
   if(config.decision_api_timeout_ms<100 || config.decision_api_timeout_ms>10000 ||
      config.decision_max_clock_skew_seconds<0 || config.decision_max_clock_skew_seconds>300 ||
      config.decision_max_ttl_seconds<1 || config.decision_max_ttl_seconds>300)
     { error="INVALID_DECISION_API_TIMING"; return false; }
   if(config.ml_min_win_probability<0.0 || config.ml_min_win_probability>1.0)
     { error="INVALID_ML_THRESHOLD"; return false; }
   if(config.telemetry_timeout_ms<100 || config.telemetry_timeout_ms>5000)
     { error="INVALID_TELEMETRY_TIMEOUT"; return false; }
   if(config.tester_decision_mode<0 || config.tester_decision_mode>5 ||
      config.tester_fixed_ml_probability<0.0 || config.tester_fixed_ml_probability>1.0)
     { error="INVALID_TESTER_DECISION_CONFIG"; return false; }
   if(!MQLInfoInteger(MQL_TESTER) && config.tester_decision_mode!=0)
     { error="MOCK_DECISION_FORBIDDEN_OUTSIDE_TESTER"; return false; }
   if(StringLen(config.audit_log_directory)<1 || StringLen(config.audit_log_directory)>128 ||
      StringFind(config.audit_log_directory,"..")>=0 || StringFind(config.audit_log_directory,":")>=0 ||
      StringGetCharacter(config.audit_log_directory,0)=='\\' || StringGetCharacter(config.audit_log_directory,0)=='/')
     { error="INVALID_AUDIT_DIRECTORY"; return false; }
   if(config.decision_api_enabled)
     {
      if(StringFind(config.decision_api_url,"https://")!=0 ||
         StringFind(config.decision_api_url,"/v1/trade-decisions")!=StringLen(config.decision_api_url)-19)
        { error="INVALID_DECISION_API_URL"; return false; }
      if(!IsSafeConfigIdentifier(config.decision_api_key_id) || StringLen(config.decision_api_secret_file)<1 ||
         StringFind(config.decision_api_secret_file,"..")>=0 ||
         StringFind(config.decision_api_secret_file,":")>=0 ||
         StringGetCharacter(config.decision_api_secret_file,0)=='\\' ||
         StringGetCharacter(config.decision_api_secret_file,0)=='/')
        { error="DECISION_API_CREDENTIAL_CONFIG_MISSING"; return false; }
     }
   if(config.telemetry_enabled)
     {
      if(StringFind(config.telemetry_api_url,"https://")!=0 ||
         StringFind(config.telemetry_api_url,"/v1/trade-events")!=StringLen(config.telemetry_api_url)-16)
        { error="INVALID_TELEMETRY_API_URL"; return false; }
      if(!IsSafeConfigIdentifier(config.decision_api_key_id) || StringLen(config.decision_api_secret_file)<1)
        { error="TELEMETRY_CREDENTIAL_CONFIG_MISSING"; return false; }
     }
   return true;
  }

#endif
