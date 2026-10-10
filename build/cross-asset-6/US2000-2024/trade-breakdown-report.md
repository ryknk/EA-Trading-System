# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 21
- MFEデータのある負けトレード数: 21
- うち一度含み益になった数: 18
- 割合: 85.71%
- 反転前の平均含み益: 2237.56

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 23
- 平均Giveback比率: 932.09%
- 中央値Giveback比率: 219.44%
- 損益ゼロ以下まで完全反転した割合: 86.96%

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

- 決済件数: 17
- 純損益: -56375.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3316.18
- 平均逆行幅（R）: 0.7697
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 17,
    "net_profit": -56375.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3316.176470588235,
    "average_win": null,
    "average_loss": -3316.176470588235
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 5897
- 最終Entry候補まで到達: 46
- Stage別棄却数（market_regime）: 4665
- Stage別棄却数（htf_bias）: 262
- Stage別棄却数（trend_strength_or_momentum_filter）: 598
- Stage別棄却数（setup_or_trigger）: 326
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 4665,
  "RSI_FILTERED": 565,
  "ENTRY_PATTERN_NOT_FOUND": 326,
  "CONFIRMATION_ADX_TOO_LOW": 33,
  "TREND_NOT_ALIGNED": 262
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 26,
    "net_profit": -38268.0,
    "win_rate": 0.11538461538461539,
    "profit_factor": 0.3245075195933065,
    "expectancy": -1471.8461538461538,
    "average_win": 6128.0,
    "average_loss": -2697.714285714286
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 6,
    "net_profit": -5764.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.6087959820822587,
    "expectancy": -960.6666666666666,
    "average_win": 8970.0,
    "average_loss": -3683.5
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": -13667.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1708.375,
    "average_win": null,
    "average_loss": -1952.4285714285713
  },
  {
    "session": "NewYork",
    "number_of_trades": 9,
    "net_profit": -17273.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.2204621355718025,
    "expectancy": -1919.2222222222222,
    "average_win": 4885.0,
    "average_loss": -2769.75
  },
  {
    "session": "Tokyo",
    "number_of_trades": 3,
    "net_profit": -1564.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.7433119973740357,
    "expectancy": -521.3333333333334,
    "average_win": 4529.0,
    "average_loss": -3046.5
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": -6658.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2219.3333333333335,
    "average_win": null,
    "average_loss": -2219.3333333333335
  },
  {
    "weekday": "Mon",
    "number_of_trades": 8,
    "net_profit": -4268.0,
    "win_rate": 0.25,
    "profit_factor": 0.7597793662407835,
    "expectancy": -533.5,
    "average_win": 6749.5,
    "average_loss": -2961.1666666666665
  },
  {
    "weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": -9948.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2487.0,
    "average_win": null,
    "average_loss": -2487.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": -2814.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -938.0,
    "average_win": null,
    "average_loss": -1407.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 8,
    "net_profit": -14580.0,
    "win_rate": 0.125,
    "profit_factor": 0.2509632674030311,
    "expectancy": -1822.5,
    "average_win": 4885.0,
    "average_loss": -3244.1666666666665
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_2.256-4.861",
    "number_of_trades": 9,
    "net_profit": -8869.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.502830876170189,
    "expectancy": -985.4444444444445,
    "average_win": 8970.0,
    "average_loss": -2229.875
  },
  {
    "atr_band": "ATR_4.861-6.486",
    "number_of_trades": 8,
    "net_profit": -17505.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2188.125,
    "average_win": null,
    "average_loss": -2917.5
  },
  {
    "atr_band": "ATR_6.486-11.94",
    "number_of_trades": 9,
    "net_profit": -11894.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.4418058944997184,
    "expectancy": -1321.5555555555557,
    "average_win": 4707.0,
    "average_loss": -3044.0
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.1-44.4",
    "number_of_trades": 9,
    "net_profit": -1838.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.88015909239095,
    "expectancy": -204.22222222222223,
    "average_win": 6749.5,
    "average_loss": -2556.1666666666665
  },
  {
    "adx_band": "ADX_44.4-50.08",
    "number_of_trades": 8,
    "net_profit": -8660.0,
    "win_rate": 0.125,
    "profit_factor": 0.36064968623108157,
    "expectancy": -1082.5,
    "average_win": 4885.0,
    "average_loss": -2257.5
  },
  {
    "adx_band": "ADX_50.08-68.95",
    "number_of_trades": 9,
    "net_profit": -27770.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3085.5555555555557,
    "average_win": null,
    "average_loss": -3085.5555555555557
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.0971-1.45",
    "number_of_trades": 9,
    "net_profit": -26780.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2975.5555555555557,
    "average_win": null,
    "average_loss": -2975.5555555555557
  },
  {
    "hold_time_band": "HOLD_H_1.45-6.72",
    "number_of_trades": 8,
    "net_profit": -4681.0,
    "win_rate": 0.125,
    "profit_factor": 0.657094718335653,
    "expectancy": -585.125,
    "average_win": 8970.0,
    "average_loss": -2730.2
  },
  {
    "hold_time_band": "HOLD_H_6.72-68.65",
    "number_of_trades": 9,
    "net_profit": -6807.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.5803587941557241,
    "expectancy": -756.3333333333334,
    "average_win": 4707.0,
    "average_loss": -2317.285714285714
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-289-824.7",
    "number_of_trades": 9,
    "net_profit": -30431.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3381.222222222222,
    "average_win": null,
    "average_loss": -3381.222222222222
  },
  {
    "mfe_band": "MFE_4100-8786",
    "number_of_trades": 9,
    "net_profit": 14585.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 4.839168202158462,
    "expectancy": 1620.5555555555557,
    "average_win": 6128.0,
    "average_loss": -949.75
  },
  {
    "mfe_band": "MFE_824.7-4100",
    "number_of_trades": 8,
    "net_profit": -22422.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2802.75,
    "average_win": null,
    "average_loss": -2802.75
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2672--467",
    "number_of_trades": 9,
    "net_profit": 15455.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 6.276544895868898,
    "expectancy": 1717.2222222222222,
    "average_win": 6128.0,
    "average_loss": -585.8
  },
  {
    "mae_band": "MAE_-3382--2672",
    "number_of_trades": 8,
    "net_profit": -20917.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2614.625,
    "average_win": null,
    "average_loss": -2988.1428571428573
  },
  {
    "mae_band": "MAE_-3832--3382",
    "number_of_trades": 9,
    "net_profit": -32806.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3645.1111111111113,
    "average_win": null,
    "average_loss": -3645.1111111111113
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 6,
    "net_profit": 8375.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.528284671532847,
    "expectancy": 1395.8333333333333,
    "average_win": 6927.5,
    "average_loss": -1826.6666666666667
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 20,
    "net_profit": -46643.0,
    "win_rate": 0.05,
    "profit_factor": 0.08850543265848511,
    "expectancy": -2332.15,
    "average_win": 4529.0,
    "average_loss": -2842.8888888888887
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": -6378.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3189.0,
    "average_win": null,
    "average_loss": -3189.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 9,
    "net_profit": -11460.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.4390602055800294,
    "expectancy": -1273.3333333333333,
    "average_win": 8970.0,
    "average_loss": -2553.75
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 15,
    "net_profit": -20430.0,
    "win_rate": 0.13333333333333333,
    "profit_factor": 0.31544028950542824,
    "expectancy": -1362.0,
    "average_win": 4707.0,
    "average_loss": -2713.090909090909
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 18,
    "net_profit": -51846.0,
    "win_rate": 0.05555555555555555,
    "profit_factor": 0.0803370288248337,
    "expectancy": -2880.3333333333335,
    "average_win": 4529.0,
    "average_loss": -3316.176470588235
  },
  {
    "close_reason": "SL",
    "number_of_trades": 6,
    "net_profit": -277.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -46.166666666666664,
    "average_win": null,
    "average_loss": -69.25
  },
  {
    "close_reason": "TP",
    "number_of_trades": 2,
    "net_profit": 13855.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 6927.5,
    "average_win": 6927.5,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 2,
    "net_profit": 2127.0,
    "win_rate": 0.5,
    "profit_factor": 1.771211022480058,
    "expectancy": 1063.5,
    "average_win": 4885.0,
    "average_loss": -2758.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 15,
    "net_profit": -22703.0,
    "win_rate": 0.06666666666666667,
    "profit_factor": 0.28320651659141854,
    "expectancy": -1513.5333333333333,
    "average_win": 8970.0,
    "average_loss": -2639.4166666666665
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 8,
    "net_profit": -17681.0,
    "win_rate": 0.125,
    "profit_factor": 0.2039171544349392,
    "expectancy": -2210.125,
    "average_win": 4529.0,
    "average_loss": -3172.8571428571427
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 1,
    "net_profit": -11.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -11.0,
    "average_win": null,
    "average_loss": -11.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 2,
    "net_profit": -6635.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3317.5,
    "average_win": null,
    "average_loss": -3317.5
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 8,
    "net_profit": -8820.0,
    "win_rate": 0.125,
    "profit_factor": 0.5042158516020236,
    "expectancy": -1102.5,
    "average_win": 8970.0,
    "average_loss": -2541.4285714285716
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 7,
    "net_profit": -11868.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.291589566047872,
    "expectancy": -1695.4285714285713,
    "average_win": 4885.0,
    "average_loss": -2792.1666666666665
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": 4473.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 80.875,
    "expectancy": 1491.0,
    "average_win": 4529.0,
    "average_loss": -56.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 6,
    "net_profit": -15418.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2569.6666666666665,
    "average_win": null,
    "average_loss": -3083.6
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0219-1.018",
    "number_of_trades": 8,
    "net_profit": 18294.0,
    "win_rate": 0.375,
    "profit_factor": 204.26666666666668,
    "expectancy": 2286.75,
    "average_win": 6128.0,
    "average_loss": -30.0
  },
  {
    "giveback_band": "GIVEBACK_1.018-3.636",
    "number_of_trades": 7,
    "net_profit": -19601.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2800.1428571428573,
    "average_win": null,
    "average_loss": -2800.1428571428573
  },
  {
    "giveback_band": "GIVEBACK_3.636-128.4",
    "number_of_trades": 8,
    "net_profit": -26677.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3334.625,
    "average_win": null,
    "average_loss": -3334.625
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
