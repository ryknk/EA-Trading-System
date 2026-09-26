# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 30
- MFEデータのある負けトレード数: 30
- うち一度含み益になった数: 26
- 割合: 86.67%
- 反転前の平均含み益: 1781.73

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 42
- 平均Giveback比率: 634.01%
- 中央値Giveback比率: 138.38%
- 損益ゼロ以下まで完全反転した割合: 73.81%

## Time Stop（時間切れ決済）

- Time Stopによる決済件数: 1
- 純損益: -694.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -694.00

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

- 決済件数: 22
- 純損益: -69876.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3176.18
- 平均逆行幅（R）: 0.7909
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 22,
    "net_profit": -69876.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3176.181818181818,
    "average_win": null,
    "average_loss": -3176.181818181818
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 5897
- 最終Entry候補まで到達: 68
- Stage別棄却数（market_regime）: 4581
- Stage別棄却数（htf_bias）: 176
- Stage別棄却数（trend_strength_or_momentum_filter）: 606
- Stage別棄却数（setup_or_trigger）: 466
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 4581,
  "RSI_FILTERED": 548,
  "ENTRY_PATTERN_NOT_FOUND": 466,
  "CONFIRMATION_ADX_TOO_LOW": 58,
  "TREND_NOT_ALIGNED": 176
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 46,
    "net_profit": -9625.0,
    "win_rate": 0.2391304347826087,
    "profit_factor": 0.8773776005503675,
    "expectancy": -209.2391304347826,
    "average_win": 6260.727272727273,
    "average_loss": -2616.4333333333334
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 8,
    "net_profit": -570.0,
    "win_rate": 0.25,
    "profit_factor": 0.9652354232739693,
    "expectancy": -71.25,
    "average_win": 7913.0,
    "average_loss": -2732.6666666666665
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 10,
    "net_profit": 54.0,
    "win_rate": 0.2,
    "profit_factor": 1.0038706902730987,
    "expectancy": 5.4,
    "average_win": 7002.5,
    "average_loss": -2790.2
  },
  {
    "session": "NewYork",
    "number_of_trades": 20,
    "net_profit": -19107.0,
    "win_rate": 0.15,
    "profit_factor": 0.5398343047059391,
    "expectancy": -955.35,
    "average_win": 7471.666666666667,
    "average_loss": -2595.125
  },
  {
    "session": "Tokyo",
    "number_of_trades": 8,
    "net_profit": 9998.0,
    "win_rate": 0.5,
    "profit_factor": 2.5093599033816427,
    "expectancy": 1249.75,
    "average_win": 4155.5,
    "average_loss": -2208.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 11,
    "net_profit": 2181.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 1.184455345060893,
    "expectancy": 198.27272727272728,
    "average_win": 7002.5,
    "average_loss": -1478.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 12,
    "net_profit": -21859.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.2673124622913454,
    "expectancy": -1821.5833333333333,
    "average_win": 3987.5,
    "average_loss": -2983.4
  },
  {
    "weekday": "Thu",
    "number_of_trades": 7,
    "net_profit": 14533.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.5822536744692433,
    "expectancy": 2076.1428571428573,
    "average_win": 7906.0,
    "average_loss": -3061.6666666666665
  },
  {
    "weekday": "Tue",
    "number_of_trades": 8,
    "net_profit": -7070.0,
    "win_rate": 0.25,
    "profit_factor": 0.4935892844352124,
    "expectancy": -883.75,
    "average_win": 3445.5,
    "average_loss": -2792.2
  },
  {
    "weekday": "Wed",
    "number_of_trades": 8,
    "net_profit": 2590.0,
    "win_rate": 0.25,
    "profit_factor": 1.1892030097158302,
    "expectancy": 323.75,
    "average_win": 8139.5,
    "average_loss": -3422.25
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_10.8-16.54",
    "number_of_trades": 16,
    "net_profit": -385.0,
    "win_rate": 0.25,
    "profit_factor": 0.9842882794645772,
    "expectancy": -24.0625,
    "average_win": 6029.75,
    "average_loss": -2722.6666666666665
  },
  {
    "atr_band": "ATR_3.042-6.679",
    "number_of_trades": 16,
    "net_profit": 10337.0,
    "win_rate": 0.3125,
    "profit_factor": 1.3756040841539188,
    "expectancy": 646.0625,
    "average_win": 7571.6,
    "average_loss": -3057.8888888888887
  },
  {
    "atr_band": "ATR_6.679-10.8",
    "number_of_trades": 14,
    "net_profit": -19577.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.2603521233187245,
    "expectancy": -1398.357142857143,
    "average_win": 3445.5,
    "average_loss": -2205.6666666666665
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.13-42.53",
    "number_of_trades": 16,
    "net_profit": 30347.0,
    "win_rate": 0.4375,
    "profit_factor": 2.919967101100848,
    "expectancy": 1896.6875,
    "average_win": 6593.285714285715,
    "average_loss": -1975.75
  },
  {
    "adx_band": "ADX_42.53-51.06",
    "number_of_trades": 14,
    "net_profit": -9614.0,
    "win_rate": 0.21428571428571427,
    "profit_factor": 0.6190966719492869,
    "expectancy": -686.7142857142857,
    "average_win": 5208.666666666667,
    "average_loss": -2524.0
  },
  {
    "adx_band": "ADX_51.06-66.38",
    "number_of_trades": 16,
    "net_profit": -30358.0,
    "win_rate": 0.0625,
    "profit_factor": 0.18930755467727722,
    "expectancy": -1897.375,
    "average_win": 7089.0,
    "average_loss": -3120.5833333333335
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.193-1.068",
    "number_of_trades": 16,
    "net_profit": -22640.0,
    "win_rate": 0.125,
    "profit_factor": 0.4041321226477168,
    "expectancy": -1415.0,
    "average_win": 7677.5,
    "average_loss": -2713.9285714285716
  },
  {
    "hold_time_band": "HOLD_H_1.068-6.318",
    "number_of_trades": 14,
    "net_profit": -12622.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5374015026571376,
    "expectancy": -901.5714285714286,
    "average_win": 7331.5,
    "average_loss": -2728.5
  },
  {
    "hold_time_band": "HOLD_H_6.318-68.64",
    "number_of_trades": 16,
    "net_profit": 25637.0,
    "win_rate": 0.4375,
    "profit_factor": 2.940286081889049,
    "expectancy": 1602.3125,
    "average_win": 5550.0,
    "average_loss": -2202.1666666666665
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-179-828",
    "number_of_trades": 15,
    "net_profit": -49120.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3274.6666666666665,
    "average_win": null,
    "average_loss": -3274.6666666666665
  },
  {
    "mfe_band": "MFE_4331-8293",
    "number_of_trades": 16,
    "net_profit": 67475.0,
    "win_rate": 0.5625,
    "profit_factor": 365.72972972972974,
    "expectancy": 4217.1875,
    "average_win": 7517.777777777777,
    "average_loss": -92.5
  },
  {
    "mfe_band": "MFE_828-4331",
    "number_of_trades": 15,
    "net_profit": -27980.0,
    "win_rate": 0.13333333333333333,
    "profit_factor": 0.04138687131697958,
    "expectancy": -1865.3333333333333,
    "average_win": 604.0,
    "average_loss": -2245.230769230769
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1707-59",
    "number_of_trades": 16,
    "net_profit": 58274.0,
    "win_rate": 0.5,
    "profit_factor": 18.6480920654149,
    "expectancy": 3642.125,
    "average_win": 7697.0,
    "average_loss": -660.4
  },
  {
    "mae_band": "MAE_-3052--1707",
    "number_of_trades": 15,
    "net_profit": -14385.0,
    "win_rate": 0.2,
    "profit_factor": 0.33639341237256076,
    "expectancy": -959.0,
    "average_win": 2430.6666666666665,
    "average_loss": -2167.7
  },
  {
    "mae_band": "MAE_-4009--3052",
    "number_of_trades": 15,
    "net_profit": -53514.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3567.6,
    "average_win": null,
    "average_loss": -3567.6
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 7,
    "net_profit": -3278.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.6838043792804089,
    "expectancy": -468.2857142857143,
    "average_win": 7089.0,
    "average_loss": -2073.4
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 39,
    "net_profit": -6347.0,
    "win_rate": 0.2564102564102564,
    "profit_factor": 0.9068343950914483,
    "expectancy": -162.74358974358975,
    "average_win": 6177.9,
    "average_loss": -2725.04
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 3,
    "net_profit": 8288.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 12.94236311239193,
    "expectancy": 2762.6666666666665,
    "average_win": 4491.0,
    "average_loss": -694.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 11,
    "net_profit": -2833.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.8317496139684047,
    "expectancy": -257.54545454545456,
    "average_win": 7002.5,
    "average_loss": -2104.75
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 32,
    "net_profit": -15080.0,
    "win_rate": 0.21875,
    "profit_factor": 0.7526287298436706,
    "expectancy": -471.25,
    "average_win": 6554.428571428572,
    "average_loss": -2902.904761904762
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 25,
    "net_profit": -69362.0,
    "win_rate": 0.08,
    "profit_factor": 0.017117755420150205,
    "expectancy": -2774.48,
    "average_win": 604.0,
    "average_loss": -3068.2608695652175
  },
  {
    "close_reason": "SL",
    "number_of_trades": 12,
    "net_profit": -7923.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -660.25,
    "average_win": null,
    "average_loss": -1131.857142857143
  },
  {
    "close_reason": "TP",
    "number_of_trades": 9,
    "net_profit": 67660.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7517.777777777777,
    "average_win": 7517.777777777777,
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
    "net_profit": -7292.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3646.0,
    "average_win": null,
    "average_loss": -3646.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": -10609.0,
    "win_rate": 0.25,
    "profit_factor": 0.40817806537989515,
    "expectancy": -1326.125,
    "average_win": 3658.5,
    "average_loss": -2987.6666666666665
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 30,
    "net_profit": 12234.0,
    "win_rate": 0.26666666666666666,
    "profit_factor": 1.2930790791270392,
    "expectancy": 407.8,
    "average_win": 6747.125,
    "average_loss": -2455.470588235294
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 6,
    "net_profit": -3958.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.6567811307665626,
    "expectancy": -659.6666666666666,
    "average_win": 7574.0,
    "average_loss": -2306.4
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 12,
    "net_profit": 17724.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.4989851150202975,
    "expectancy": 1477.0,
    "average_win": 7387.0,
    "average_loss": -1478.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 10,
    "net_profit": -25228.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2522.8,
    "average_win": null,
    "average_loss": -2803.1111111111113
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 6,
    "net_profit": -1010.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.8900381056069678,
    "expectancy": -168.33333333333334,
    "average_win": 8175.0,
    "average_loss": -3061.6666666666665
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 8,
    "net_profit": -4485.0,
    "win_rate": 0.375,
    "profit_factor": 0.6619431672571041,
    "expectancy": -560.625,
    "average_win": 2927.3333333333335,
    "average_loss": -3316.75
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 10,
    "net_profit": 3374.0,
    "win_rate": 0.3,
    "profit_factor": 1.177681815788088,
    "expectancy": 337.4,
    "average_win": 7454.333333333333,
    "average_loss": -3164.8333333333335
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0276-1",
    "number_of_trades": 16,
    "net_profit": 68868.0,
    "win_rate": 0.6875,
    "profit_factor": null,
    "expectancy": 4304.25,
    "average_win": 6260.727272727273,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1-2.698",
    "number_of_trades": 12,
    "net_profit": -21249.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1770.75,
    "average_win": null,
    "average_loss": -1770.75
  },
  {
    "giveback_band": "GIVEBACK_2.698-119.3",
    "number_of_trades": 14,
    "net_profit": -43219.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3087.0714285714284,
    "average_win": null,
    "average_loss": -3087.0714285714284
  }
]
```

## time_stop_reason_code別

```json
[
  {
    "time_stop_reason_code": "MAX_HOLDING_BARS_MIN_MFE_NOT_REACHED",
    "number_of_trades": 1,
    "net_profit": -694.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -694.0,
    "average_win": null,
    "average_loss": -694.0
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
