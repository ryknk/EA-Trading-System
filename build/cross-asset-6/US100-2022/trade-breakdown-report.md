# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 18
- MFEデータのある負けトレード数: 18
- うち一度含み益になった数: 17
- 割合: 94.44%
- 反転前の平均含み益: 3423.94

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 25
- 平均Giveback比率: 312.93%
- 中央値Giveback比率: 100.17%
- 損益ゼロ以下まで完全反転した割合: 80.00%

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

- 決済件数: 10
- 純損益: -30426.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3042.60
- 平均逆行幅（R）: 0.7676
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 2,
    "net_profit": -5911.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2955.5,
    "average_win": null,
    "average_loss": -2955.5
  },
  "SELL": {
    "number_of_trades": 8,
    "net_profit": -24515.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3064.375,
    "average_win": null,
    "average_loss": -3064.375
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 5908
- 最終Entry候補まで到達: 49
- Stage別棄却数（market_regime）: 4723
- Stage別棄却数（htf_bias）: 260
- Stage別棄却数（trend_strength_or_momentum_filter）: 580
- Stage別棄却数（setup_or_trigger）: 296
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 4723,
  "CONFIRMATION_ADX_TOO_LOW": 36,
  "RSI_FILTERED": 544,
  "TREND_NOT_ALIGNED": 260,
  "ENTRY_PATTERN_NOT_FOUND": 296
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 3,
    "net_profit": -5954.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1984.6666666666667,
    "average_win": null,
    "average_loss": -1984.6666666666667
  },
  {
    "direction": "SELL",
    "number_of_trades": 23,
    "net_profit": 9541.0,
    "win_rate": 0.21739130434782608,
    "profit_factor": 1.386980328533766,
    "expectancy": 414.82608695652175,
    "average_win": 6839.2,
    "average_loss": -1643.6666666666667
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 4,
    "net_profit": 5200.0,
    "win_rate": 0.25,
    "profit_factor": 45.44444444444444,
    "expectancy": 1300.0,
    "average_win": 5317.0,
    "average_loss": -39.0
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 4,
    "net_profit": -2655.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -663.75,
    "average_win": null,
    "average_loss": -885.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 10,
    "net_profit": 21992.0,
    "win_rate": 0.4,
    "profit_factor": 4.193262668796283,
    "expectancy": 2199.2,
    "average_win": 7219.75,
    "average_loss": -1721.75
  },
  {
    "session": "Tokyo",
    "number_of_trades": 8,
    "net_profit": -20950.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2618.75,
    "average_win": null,
    "average_loss": -2618.75
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 5,
    "net_profit": 1200.0,
    "win_rate": 0.2,
    "profit_factor": 1.1657000828500415,
    "expectancy": 240.0,
    "average_win": 8442.0,
    "average_loss": -2414.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 8,
    "net_profit": -9148.0,
    "win_rate": 0.125,
    "profit_factor": 0.19761424436452943,
    "expectancy": -1143.5,
    "average_win": 2253.0,
    "average_loss": -1900.1666666666667
  },
  {
    "weekday": "Thu",
    "number_of_trades": 6,
    "net_profit": 11834.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 6.708634828750603,
    "expectancy": 1972.3333333333333,
    "average_win": 6953.5,
    "average_loss": -518.25
  },
  {
    "weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": 3317.0,
    "win_rate": 0.25,
    "profit_factor": 1.5284371515054962,
    "expectancy": 829.25,
    "average_win": 9594.0,
    "average_loss": -2092.3333333333335
  },
  {
    "weekday": "Wed",
    "number_of_trades": 3,
    "net_profit": -3616.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1205.3333333333333,
    "average_win": null,
    "average_loss": -1808.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_36.15-55.13",
    "number_of_trades": 9,
    "net_profit": 4879.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 2.369351669941061,
    "expectancy": 542.1111111111111,
    "average_win": 8442.0,
    "average_loss": -712.6
  },
  {
    "atr_band": "ATR_55.13-68.79",
    "number_of_trades": 8,
    "net_profit": 7717.0,
    "win_rate": 0.375,
    "profit_factor": 1.606682389937107,
    "expectancy": 964.625,
    "average_win": 6812.333333333333,
    "average_loss": -2544.0
  },
  {
    "atr_band": "ATR_68.79-103.1",
    "number_of_trades": 9,
    "net_profit": -9009.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.37114337568058076,
    "expectancy": -1001.0,
    "average_win": 5317.0,
    "average_loss": -1790.75
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.18-40.97",
    "number_of_trades": 9,
    "net_profit": 14506.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 3.5083866505274077,
    "expectancy": 1611.7777777777778,
    "average_win": 6763.0,
    "average_loss": -1156.6
  },
  {
    "adx_band": "ADX_40.97-44.45",
    "number_of_trades": 8,
    "net_profit": -2738.0,
    "win_rate": 0.125,
    "profit_factor": 0.75829802259887,
    "expectancy": -342.25,
    "average_win": 8590.0,
    "average_loss": -1888.0
  },
  {
    "adx_band": "ADX_44.45-56.36",
    "number_of_trades": 9,
    "net_profit": -8181.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.39391020891983997,
    "expectancy": -909.0,
    "average_win": 5317.0,
    "average_loss": -1928.2857142857142
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_1.011-4.1",
    "number_of_trades": 9,
    "net_profit": -1261.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.8700401937545089,
    "expectancy": -140.11111111111111,
    "average_win": 8442.0,
    "average_loss": -1940.6
  },
  {
    "hold_time_band": "HOLD_H_12.53-93.03",
    "number_of_trades": 9,
    "net_profit": -5872.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.6486987735566856,
    "expectancy": -652.4444444444445,
    "average_win": 5421.5,
    "average_loss": -2387.8571428571427
  },
  {
    "hold_time_band": "HOLD_H_4.1-12.53",
    "number_of_trades": 8,
    "net_profit": 10720.0,
    "win_rate": 0.25,
    "profit_factor": 3.5578620854211405,
    "expectancy": 1340.0,
    "average_win": 7455.5,
    "average_loss": -698.5
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-3.001-2581",
    "number_of_trades": 9,
    "net_profit": -26620.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2957.777777777778,
    "average_win": null,
    "average_loss": -2957.777777777778
  },
  {
    "mfe_band": "MFE_2581-5313",
    "number_of_trades": 8,
    "net_profit": 1448.0,
    "win_rate": 0.125,
    "profit_factor": 1.3742569139312484,
    "expectancy": 181.0,
    "average_win": 5317.0,
    "average_loss": -773.8
  },
  {
    "mfe_band": "MFE_5313-9587",
    "number_of_trades": 9,
    "net_profit": 28759.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 240.65833333333333,
    "expectancy": 3195.4444444444443,
    "average_win": 7219.75,
    "average_loss": -30.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1062--118",
    "number_of_trades": 9,
    "net_profit": 13599.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 85.99375,
    "expectancy": 1511.0,
    "average_win": 6879.5,
    "average_loss": -32.0
  },
  {
    "mae_band": "MAE_-2681--1062",
    "number_of_trades": 8,
    "net_profit": 4152.0,
    "win_rate": 0.25,
    "profit_factor": 1.6205350470781648,
    "expectancy": 519.0,
    "average_win": 5421.5,
    "average_loss": -1338.2
  },
  {
    "mae_band": "MAE_-3806--2681",
    "number_of_trades": 9,
    "net_profit": -14164.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.4038218705278222,
    "expectancy": -1573.7777777777778,
    "average_win": 9594.0,
    "average_loss": -2969.75
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 17,
    "net_profit": 1978.0,
    "win_rate": 0.17647058823529413,
    "profit_factor": 1.0802499188575139,
    "expectancy": 116.3529411764706,
    "average_win": 8875.333333333334,
    "average_loss": -1760.5714285714287
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 9,
    "net_profit": 1609.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 1.2699211541687636,
    "expectancy": 178.77777777777777,
    "average_win": 3785.0,
    "average_loss": -1490.25
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": -7412.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3706.0,
    "average_win": null,
    "average_loss": -3706.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 5,
    "net_profit": 5787.0,
    "win_rate": 0.2,
    "profit_factor": 3.1796610169491526,
    "expectancy": 1157.4,
    "average_win": 8442.0,
    "average_loss": -885.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 19,
    "net_profit": 5212.0,
    "win_rate": 0.21052631578947367,
    "profit_factor": 1.2537240774997567,
    "expectancy": 274.3157894736842,
    "average_win": 6438.5,
    "average_loss": -1580.1538461538462
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 11,
    "net_profit": -28173.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.07404851114178664,
    "expectancy": -2561.181818181818,
    "average_win": 2253.0,
    "average_loss": -3042.6
  },
  {
    "close_reason": "SL",
    "number_of_trades": 11,
    "net_profit": -183.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -16.636363636363637,
    "average_win": null,
    "average_loss": -22.875
  },
  {
    "close_reason": "TP",
    "number_of_trades": 4,
    "net_profit": 31943.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7985.75,
    "average_win": 7985.75,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 5,
    "net_profit": -3247.0,
    "win_rate": 0.2,
    "profit_factor": 0.40963636363636363,
    "expectancy": -649.4,
    "average_win": 2253.0,
    "average_loss": -1375.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 4,
    "net_profit": -9342.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2335.5,
    "average_win": null,
    "average_loss": -2335.5
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 11,
    "net_profit": 7418.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 2.169847027282763,
    "expectancy": 674.3636363636364,
    "average_win": 6879.5,
    "average_loss": -1056.8333333333333
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 6,
    "net_profit": 8758.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.929132187566306,
    "expectancy": 1459.6666666666667,
    "average_win": 9092.0,
    "average_loss": -2356.5
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 4,
    "net_profit": 6428.0,
    "win_rate": 0.25,
    "profit_factor": 4.191658391261172,
    "expectancy": 1607.0,
    "average_win": 8442.0,
    "average_loss": -1007.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": -6916.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5539791048626338,
    "expectancy": -988.0,
    "average_win": 8590.0,
    "average_loss": -3101.2
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": 5253.0,
    "win_rate": 0.25,
    "profit_factor": 83.078125,
    "expectancy": 1313.25,
    "average_win": 5317.0,
    "average_loss": -21.333333333333332
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 7,
    "net_profit": 5228.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.7898474089741654,
    "expectancy": 746.8571428571429,
    "average_win": 5923.5,
    "average_loss": -1323.8
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 4,
    "net_profit": -6406.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1601.5,
    "average_win": null,
    "average_loss": -2135.3333333333335
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0029-1.001",
    "number_of_trades": 9,
    "net_profit": 34191.0,
    "win_rate": 0.5555555555555556,
    "profit_factor": 6839.2,
    "expectancy": 3799.0,
    "average_win": 6839.2,
    "average_loss": -5.0
  },
  {
    "giveback_band": "GIVEBACK_1.001-1.88",
    "number_of_trades": 7,
    "net_profit": -178.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -25.428571428571427,
    "average_win": null,
    "average_loss": -25.428571428571427
  },
  {
    "giveback_band": "GIVEBACK_1.88-40.39",
    "number_of_trades": 9,
    "net_profit": -28368.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3152.0,
    "average_win": null,
    "average_loss": -3152.0
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
