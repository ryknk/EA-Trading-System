# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 2
- MFEデータのある負けトレード数: 2
- うち一度含み益になった数: 2
- 割合: 100.00%
- 反転前の平均含み益: 1852.50

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 9
- 平均Giveback比率: 93.78%
- 中央値Giveback比率: 41.63%
- 損益ゼロ以下まで完全反転した割合: 33.33%

## Time Stop（時間切れ決済）

- Time Stopによる決済件数: 0
- 純損益: 0.00
- プロフィットファクター: 算出不能
- 勝率: 算出不能
- 期待値: 0.00

## レンジ相場逆張り強制決済（RANGE_EXIT）

- 強制決済件数: 0
- 純損益: 0.00
- プロフィットファクター: 算出不能
- 勝率: 算出不能
- 期待値: 0.00

## トレンド継続反転Exit（TREND_REVERSAL_EXIT）

- 決済件数: 0
- 純損益: 0.00
- プロフィットファクター: 算出不能
- 勝率: 算出不能
- 期待値: 0.00
- 平均Peak MFE（R）: 算出不能
- 平均反転幅（R）: 算出不能
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

## 初期逆行Exit（EARLY_ADVERSE_EXIT）

- 決済件数: 2
- 純損益: -7479.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3739.50
- 平均逆行幅（R）: 0.7612
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 2,
    "net_profit": -7479.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3739.5,
    "average_win": null,
    "average_loss": -3739.5
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 2051
- 最終Entry候補まで到達: 23
- Stage別棄却数（market_regime）: 1579
- Stage別棄却数（htf_bias）: 78
- Stage別棄却数（trend_strength_or_momentum_filter）: 222
- Stage別棄却数（setup_or_trigger）: 149
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 1579,
  "RSI_FILTERED": 217,
  "ENTRY_PATTERN_NOT_FOUND": 149,
  "TREND_NOT_ALIGNED": 78,
  "CONFIRMATION_ADX_TOO_LOW": 5
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 9,
    "net_profit": 36044.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 5.81936087712261,
    "expectancy": 4004.8888888888887,
    "average_win": 7253.833333333333,
    "average_loss": -3739.5
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 2,
    "net_profit": 14983.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7491.5,
    "average_win": 7491.5,
    "average_loss": null
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 2,
    "net_profit": 5849.0,
    "win_rate": 0.5,
    "profit_factor": 2.5676762262128117,
    "expectancy": 2924.5,
    "average_win": 9580.0,
    "average_loss": -3731.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 3,
    "net_profit": 18960.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 6320.0,
    "average_win": 6320.0,
    "average_loss": null
  },
  {
    "session": "Tokyo",
    "number_of_trades": 2,
    "net_profit": -3748.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1874.0,
    "average_win": null,
    "average_loss": -3748.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Mon",
    "number_of_trades": 1,
    "net_profit": -3731.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3731.0,
    "average_win": null,
    "average_loss": -3731.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 2,
    "net_profit": 19250.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9625.0,
    "average_win": 9625.0,
    "average_loss": null
  },
  {
    "weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": 14693.0,
    "win_rate": 0.75,
    "profit_factor": null,
    "expectancy": 3673.25,
    "average_win": 4897.666666666667,
    "average_loss": null
  },
  {
    "weekday": "Wed",
    "number_of_trades": 2,
    "net_profit": 5832.0,
    "win_rate": 0.5,
    "profit_factor": 2.5560298826040553,
    "expectancy": 2916.0,
    "average_win": 9580.0,
    "average_loss": -3748.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.105-0.16",
    "number_of_trades": 3,
    "net_profit": 24573.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8191.0,
    "average_win": 8191.0,
    "average_loss": null
  },
  {
    "atr_band": "ATR_0.16-0.182",
    "number_of_trades": 3,
    "net_profit": 18950.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 6316.666666666667,
    "average_win": 6316.666666666667,
    "average_loss": null
  },
  {
    "atr_band": "ATR_0.182-0.187",
    "number_of_trades": 3,
    "net_profit": -7479.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2493.0,
    "average_win": null,
    "average_loss": -3739.5
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.21-40.78",
    "number_of_trades": 3,
    "net_profit": 5345.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": null,
    "expectancy": 1781.6666666666667,
    "average_win": 2672.5,
    "average_loss": null
  },
  {
    "adx_band": "ADX_40.78-51.39",
    "number_of_trades": 3,
    "net_profit": 2181.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.291616526273566,
    "expectancy": 727.0,
    "average_win": 9660.0,
    "average_loss": -3739.5
  },
  {
    "adx_band": "ADX_51.39-55.85",
    "number_of_trades": 3,
    "net_profit": 28518.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9506.0,
    "average_win": 9506.0,
    "average_loss": null
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_14.14-20.35",
    "number_of_trades": 3,
    "net_profit": 15180.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 5.050160085378868,
    "expectancy": 5060.0,
    "average_win": 9464.0,
    "average_loss": -3748.0
  },
  {
    "hold_time_band": "HOLD_H_20.35-77.95",
    "number_of_trades": 3,
    "net_profit": 14935.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 4978.333333333333,
    "average_win": 4978.333333333333,
    "average_loss": null
  },
  {
    "hold_time_band": "HOLD_H_3.139-14.14",
    "number_of_trades": 3,
    "net_profit": 5929.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.5891181988742966,
    "expectancy": 1976.3333333333333,
    "average_win": 9660.0,
    "average_loss": -3731.0
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_1807-8215",
    "number_of_trades": 3,
    "net_profit": -7457.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.0029415697285733386,
    "expectancy": -2485.6666666666665,
    "average_win": 22.0,
    "average_loss": -3739.5
  },
  {
    "mfe_band": "MFE_8215-9406",
    "number_of_trades": 3,
    "net_profit": 14671.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": null,
    "expectancy": 4890.333333333333,
    "average_win": 7335.5,
    "average_loss": null
  },
  {
    "mfe_band": "MFE_9406-9591",
    "number_of_trades": 3,
    "net_profit": 28830.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9610.0,
    "average_win": 9610.0,
    "average_loss": null
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1021--160",
    "number_of_trades": 3,
    "net_profit": 24261.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8087.0,
    "average_win": 8087.0,
    "average_loss": null
  },
  {
    "mae_band": "MAE_-1534--1021",
    "number_of_trades": 3,
    "net_profit": 19240.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": null,
    "expectancy": 6413.333333333333,
    "average_win": 9620.0,
    "average_loss": null
  },
  {
    "mae_band": "MAE_-3748--1534",
    "number_of_trades": 3,
    "net_profit": -7457.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.0029415697285733386,
    "expectancy": -2485.6666666666665,
    "average_win": 22.0,
    "average_loss": -3739.5
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 2,
    "net_profit": 14983.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7491.5,
    "average_win": 7491.5,
    "average_loss": null
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 7,
    "net_profit": 21061.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 3.816018184249231,
    "expectancy": 3008.714285714286,
    "average_win": 7135.0,
    "average_loss": -3739.5
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 1,
    "net_profit": 9660.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9660.0,
    "average_win": 9660.0,
    "average_loss": null
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 8,
    "net_profit": 26384.0,
    "win_rate": 0.625,
    "profit_factor": 4.527744350849044,
    "expectancy": 3298.0,
    "average_win": 6772.6,
    "average_loss": -3739.5
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 3,
    "net_profit": -2156.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.7117261665998128,
    "expectancy": -718.6666666666666,
    "average_win": 5323.0,
    "average_loss": -3739.5
  },
  {
    "close_reason": "SL",
    "number_of_trades": 2,
    "net_profit": 22.0,
    "win_rate": 0.5,
    "profit_factor": null,
    "expectancy": 11.0,
    "average_win": 22.0,
    "average_loss": null
  },
  {
    "close_reason": "TP",
    "number_of_trades": 4,
    "net_profit": 38178.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9544.5,
    "average_win": 9544.5,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 3,
    "net_profit": 24251.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8083.666666666667,
    "average_win": 8083.666666666667,
    "average_loss": null
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 2,
    "net_profit": -3748.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1874.0,
    "average_win": null,
    "average_loss": -3748.0
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 3,
    "net_profit": 5951.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 2.595014741356205,
    "expectancy": 1983.6666666666667,
    "average_win": 4841.0,
    "average_loss": -3731.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 1,
    "net_profit": 9590.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9590.0,
    "average_win": 9590.0,
    "average_loss": null
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Mon",
    "number_of_trades": 2,
    "net_profit": 5859.0,
    "win_rate": 0.5,
    "profit_factor": 2.5703564727954973,
    "expectancy": 2929.5,
    "average_win": 9590.0,
    "average_loss": -3731.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": 15492.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 5.133404482390608,
    "expectancy": 5164.0,
    "average_win": 9620.0,
    "average_loss": -3748.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 1,
    "net_profit": 0.0,
    "win_rate": 0.0,
    "profit_factor": null,
    "expectancy": 0.0,
    "average_win": null,
    "average_loss": null
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 3,
    "net_profit": 14693.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 4897.666666666667,
    "average_win": 4897.666666666667,
    "average_loss": null
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00152-0.998",
    "number_of_trades": 3,
    "net_profit": 14693.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 4897.666666666667,
    "average_win": 4897.666666666667,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_-0.00819--0.00152",
    "number_of_trades": 3,
    "net_profit": 28830.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9610.0,
    "average_win": 9610.0,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.998-3.074",
    "number_of_trades": 3,
    "net_profit": -7479.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2493.0,
    "average_win": null,
    "average_loss": -3739.5
  }
]
```

## time_stop_reason_code別

```json
[]
```

## range_exit_reason_code別

```json
[]
```

## trend_reversal_trend_direction別

```json
[]
```
