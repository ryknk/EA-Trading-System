# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 17
- MFEデータのある負けトレード数: 17
- うち一度含み益になった数: 14
- 割合: 82.35%
- 反転前の平均含み益: 2442.64

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 26
- 平均Giveback比率: 477.19%
- 中央値Giveback比率: 101.05%
- 損益ゼロ以下まで完全反転した割合: 57.69%

## Time Stop（時間切れ決済）

- Time Stopによる決済件数: 1
- 純損益: 175.00
- プロフィットファクター: 算出不能
- 勝率: 100.00%
- 期待値: 175.00

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

- 決済件数: 13
- 純損益: -49537.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3810.54
- 平均逆行幅（R）: 0.7685
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 12,
    "net_profit": -45815.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3817.9166666666665,
    "average_win": null,
    "average_loss": -3817.9166666666665
  },
  "SELL": {
    "number_of_trades": 1,
    "net_profit": -3722.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3722.0,
    "average_win": null,
    "average_loss": -3722.0
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6335
- 最終Entry候補まで到達: 57
- Stage別棄却数（market_regime）: 5265
- Stage別棄却数（htf_bias）: 308
- Stage別棄却数（trend_strength_or_momentum_filter）: 363
- Stage別棄却数（setup_or_trigger）: 342
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5265,
  "RSI_FILTERED": 330,
  "ENTRY_PATTERN_NOT_FOUND": 342,
  "CONFIRMATION_ADX_TOO_LOW": 33,
  "TREND_NOT_ALIGNED": 308
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 23,
    "net_profit": -8080.0,
    "win_rate": 0.30434782608695654,
    "profit_factor": 0.8451098416593184,
    "expectancy": -351.30434782608694,
    "average_win": 6298.0,
    "average_loss": -3260.375
  },
  {
    "direction": "SELL",
    "number_of_trades": 6,
    "net_profit": 18939.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 6.088393336915637,
    "expectancy": 3156.5,
    "average_win": 5665.25,
    "average_loss": -3722.0
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 8,
    "net_profit": -6880.0,
    "win_rate": 0.25,
    "profit_factor": 0.7327636434259079,
    "expectancy": -860.0,
    "average_win": 9432.5,
    "average_loss": -4290.833333333333
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": 4924.0,
    "win_rate": 0.375,
    "profit_factor": 1.3298720439472098,
    "expectancy": 615.5,
    "average_win": 6617.0,
    "average_loss": -2985.4
  },
  {
    "session": "NewYork",
    "number_of_trades": 4,
    "net_profit": 12703.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 3175.75,
    "average_win": 3175.75,
    "average_loss": null
  },
  {
    "session": "Tokyo",
    "number_of_trades": 9,
    "net_profit": 112.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 1.0073606729758149,
    "expectancy": 12.444444444444445,
    "average_win": 7664.0,
    "average_loss": -2536.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": -5820.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.029190992493744787,
    "expectancy": -1940.0,
    "average_win": 175.0,
    "average_loss": -5995.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": 14080.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 4.393588816582309,
    "expectancy": 2011.4285714285713,
    "average_win": 4557.25,
    "average_loss": -1383.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": -15151.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3787.75,
    "average_win": null,
    "average_loss": -3787.75
  },
  {
    "weekday": "Tue",
    "number_of_trades": 9,
    "net_profit": -4200.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.8178032274856846,
    "expectancy": -466.6666666666667,
    "average_win": 9426.0,
    "average_loss": -3293.1428571428573
  },
  {
    "weekday": "Wed",
    "number_of_trades": 6,
    "net_profit": 21950.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 3.9107545418379526,
    "expectancy": 3658.3333333333335,
    "average_win": 7372.75,
    "average_loss": -3770.5
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_-0.000251-0.00109",
    "number_of_trades": 10,
    "net_profit": -8678.0,
    "win_rate": 0.2,
    "profit_factor": 0.6849290200776967,
    "expectancy": -867.8,
    "average_win": 9432.5,
    "average_loss": -3442.875
  },
  {
    "atr_band": "ATR_0.00109-0.00142",
    "number_of_trades": 9,
    "net_profit": -10956.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.4761654315084867,
    "expectancy": -1217.3333333333333,
    "average_win": 3319.6666666666665,
    "average_loss": -4183.0
  },
  {
    "atr_band": "ATR_0.00142-0.00191",
    "number_of_trades": 10,
    "net_profit": 30493.0,
    "win_rate": 0.6,
    "profit_factor": 5.1040376850605655,
    "expectancy": 3049.3,
    "average_win": 6320.5,
    "average_loss": -1857.5
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.57-42.21",
    "number_of_trades": 10,
    "net_profit": -7955.0,
    "win_rate": 0.4,
    "profit_factor": 0.653331590186081,
    "expectancy": -795.5,
    "average_win": 3748.0,
    "average_loss": -3824.5
  },
  {
    "adx_band": "ADX_42.21-45.8",
    "number_of_trades": 9,
    "net_profit": 5289.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.3052990071577002,
    "expectancy": 587.6666666666666,
    "average_win": 7537.666666666667,
    "average_loss": -3464.8
  },
  {
    "adx_band": "ADX_45.8-58.02",
    "number_of_trades": 10,
    "net_profit": 13525.0,
    "win_rate": 0.4,
    "profit_factor": 1.8660434142280848,
    "expectancy": 1352.5,
    "average_win": 7285.5,
    "average_loss": -2602.8333333333335
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.605-5.152",
    "number_of_trades": 10,
    "net_profit": -40518.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4051.8,
    "average_win": null,
    "average_loss": -4051.8
  },
  {
    "hold_time_band": "HOLD_H_12.33-66",
    "number_of_trades": 10,
    "net_profit": 37008.0,
    "win_rate": 0.8,
    "profit_factor": 120.76699029126213,
    "expectancy": 3700.8,
    "average_win": 4664.625,
    "average_loss": -154.5
  },
  {
    "hold_time_band": "HOLD_H_5.152-12.33",
    "number_of_trades": 9,
    "net_profit": 14369.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.9540535157028085,
    "expectancy": 1596.5555555555557,
    "average_win": 9810.0,
    "average_loss": -3012.2
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-123-1995",
    "number_of_trades": 10,
    "net_profit": -36286.0,
    "win_rate": 0.1,
    "profit_factor": 0.004799648939963248,
    "expectancy": -3628.6,
    "average_win": 175.0,
    "average_loss": -4051.222222222222
  },
  {
    "mfe_band": "MFE_1995-5970",
    "number_of_trades": 9,
    "net_profit": -18151.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.06341589267285862,
    "expectancy": -2016.7777777777778,
    "average_win": 614.5,
    "average_loss": -2768.5714285714284
  },
  {
    "mfe_band": "MFE_5970-1e+04",
    "number_of_trades": 10,
    "net_profit": 65296.0,
    "win_rate": 0.8,
    "profit_factor": 1390.276595744681,
    "expectancy": 6529.6,
    "average_win": 8167.875,
    "average_loss": -47.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2050--488",
    "number_of_trades": 10,
    "net_profit": 28957.0,
    "win_rate": 0.6,
    "profit_factor": 5.730762947230844,
    "expectancy": 2895.7,
    "average_win": 5846.333333333333,
    "average_loss": -2040.3333333333333
  },
  {
    "mae_band": "MAE_-3804--2050",
    "number_of_trades": 9,
    "net_profit": 13087.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 1.7109795186613788,
    "expectancy": 1454.111111111111,
    "average_win": 7873.5,
    "average_loss": -3681.4
  },
  {
    "mae_band": "MAE_-5244--3804",
    "number_of_trades": 10,
    "net_profit": -31185.0,
    "win_rate": 0.1,
    "profit_factor": 0.005580357142857143,
    "expectancy": -3118.5,
    "average_win": 175.0,
    "average_loss": -3484.4444444444443
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 11,
    "net_profit": 25.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 1.0011647952289988,
    "expectancy": 2.272727272727273,
    "average_win": 5372.0,
    "average_loss": -3577.1666666666665
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 18,
    "net_profit": 10834.0,
    "win_rate": 0.3888888888888889,
    "profit_factor": 1.3147131445170661,
    "expectancy": 601.8888888888889,
    "average_win": 6465.571428571428,
    "average_loss": -3129.5454545454545
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": 6411.0,
    "win_rate": 0.5,
    "profit_factor": 2.7224610424502957,
    "expectancy": 3205.5,
    "average_win": 10133.0,
    "average_loss": -3722.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 5,
    "net_profit": -4524.0,
    "win_rate": 0.2,
    "profit_factor": 0.6791034189246702,
    "expectancy": -904.8,
    "average_win": 9574.0,
    "average_loss": -3524.5
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 22,
    "net_profit": 8972.0,
    "win_rate": 0.4090909090909091,
    "profit_factor": 1.2356835137123043,
    "expectancy": 407.8181818181818,
    "average_win": 5226.666666666667,
    "average_loss": -3172.3333333333335
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 18,
    "net_profit": -40323.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.18976430164566882,
    "expectancy": -2240.1666666666665,
    "average_win": 2361.0,
    "average_loss": -3554.785714285714
  },
  {
    "close_reason": "SL",
    "number_of_trades": 5,
    "net_profit": -6060.0,
    "win_rate": 0.2,
    "profit_factor": 0.009965691880411697,
    "expectancy": -1212.0,
    "average_win": 61.0,
    "average_loss": -2040.3333333333333
  },
  {
    "close_reason": "TP",
    "number_of_trades": 6,
    "net_profit": 57242.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9540.333333333334,
    "average_win": 9540.333333333334,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 10,
    "net_profit": -18564.0,
    "win_rate": 0.3,
    "profit_factor": 0.30539549502357255,
    "expectancy": -1856.4,
    "average_win": 2720.6666666666665,
    "average_loss": -3818.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 10,
    "net_profit": -12238.0,
    "win_rate": 0.2,
    "profit_factor": 0.43614080353851825,
    "expectancy": -1223.8,
    "average_win": 4733.0,
    "average_loss": -3100.5714285714284
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 6,
    "net_profit": 22197.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 4.0709739900387385,
    "expectancy": 3699.5,
    "average_win": 7356.25,
    "average_loss": -3614.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 3,
    "net_profit": 19464.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 85.62608695652175,
    "expectancy": 6488.0,
    "average_win": 9847.0,
    "average_loss": -230.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 2,
    "net_profit": -5995.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2997.5,
    "average_win": null,
    "average_loss": -5995.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 3,
    "net_profit": -3744.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.04465424853278898,
    "expectancy": -1248.0,
    "average_win": 175.0,
    "average_loss": -1959.5
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 7,
    "net_profit": 4604.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.3038743317272787,
    "expectancy": 657.7142857142857,
    "average_win": 6585.0,
    "average_loss": -3787.75
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 10,
    "net_profit": -13154.0,
    "win_rate": 0.2,
    "profit_factor": 0.4350141740400309,
    "expectancy": -1315.4,
    "average_win": 5064.0,
    "average_loss": -2910.25
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 7,
    "net_profit": 29148.0,
    "win_rate": 0.7142857142857143,
    "profit_factor": 4.865269858109004,
    "expectancy": 4164.0,
    "average_win": 7337.8,
    "average_loss": -3770.5
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0301-0.782",
    "number_of_trades": 9,
    "net_profit": 66511.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7390.111111111111,
    "average_win": 7390.111111111111,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.782-2.296",
    "number_of_trades": 8,
    "net_profit": -7767.0,
    "win_rate": 0.25,
    "profit_factor": 0.02948894164688242,
    "expectancy": -970.875,
    "average_win": 118.0,
    "average_loss": -1600.6
  },
  {
    "giveback_band": "GIVEBACK_2.296-77.21",
    "number_of_trades": 9,
    "net_profit": -36534.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4059.3333333333335,
    "average_win": null,
    "average_loss": -4059.3333333333335
  }
]
```

## time_stop_reason_code別

```json
[
  {
    "time_stop_reason_code": "MAX_HOLDING_BARS_MIN_MFE_NOT_REACHED",
    "number_of_trades": 1,
    "net_profit": 175.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 175.0,
    "average_win": 175.0,
    "average_loss": null
  }
]
```

## range_exit_reason_code別

```json
[]
```

## trend_reversal_trend_direction別

```json
[]
```
