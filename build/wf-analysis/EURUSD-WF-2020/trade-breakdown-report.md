# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 20
- MFEデータのある負けトレード数: 20
- うち一度含み益になった数: 18
- 割合: 90.00%
- 反転前の平均含み益: 3340.83

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 30
- 平均Giveback比率: 320.30%
- 中央値Giveback比率: 102.19%
- 損益ゼロ以下まで完全反転した割合: 73.33%

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

- 決済件数: 15
- 純損益: -57439.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3829.27
- 平均逆行幅（R）: 0.7701
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 13,
    "net_profit": -49904.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3838.769230769231,
    "average_win": null,
    "average_loss": -3838.769230769231
  },
  "SELL": {
    "number_of_trades": 2,
    "net_profit": -7535.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3767.5,
    "average_win": null,
    "average_loss": -3767.5
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6257
- 最終Entry候補まで到達: 61
- Stage別棄却数（market_regime）: 5237
- Stage別棄却数（htf_bias）: 175
- Stage別棄却数（trend_strength_or_momentum_filter）: 388
- Stage別棄却数（setup_or_trigger）: 396
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5237,
  "RSI_FILTERED": 343,
  "TREND_NOT_ALIGNED": 175,
  "ENTRY_PATTERN_NOT_FOUND": 396,
  "CONFIRMATION_ADX_TOO_LOW": 45
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 24,
    "net_profit": -12132.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.7585431386207583,
    "expectancy": -505.5,
    "average_win": 9528.25,
    "average_loss": -2955.5882352941176
  },
  {
    "direction": "SELL",
    "number_of_trades": 8,
    "net_profit": 23392.0,
    "win_rate": 0.5,
    "profit_factor": 3.55734120476659,
    "expectancy": 2924.0,
    "average_win": 8134.75,
    "average_loss": -3049.0
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 7,
    "net_profit": 11695.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 2.5066993043030146,
    "expectancy": 1670.7142857142858,
    "average_win": 9728.5,
    "average_loss": -2587.3333333333335
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 7,
    "net_profit": -3027.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.8082721053965036,
    "expectancy": -432.42857142857144,
    "average_win": 6380.5,
    "average_loss": -3157.6
  },
  {
    "session": "NewYork",
    "number_of_trades": 7,
    "net_profit": -6868.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5906544284181666,
    "expectancy": -981.1428571428571,
    "average_win": 9910.0,
    "average_loss": -2796.3333333333335
  },
  {
    "session": "Tokyo",
    "number_of_trades": 11,
    "net_profit": 9460.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 1.4962232480067141,
    "expectancy": 860.0,
    "average_win": 9508.0,
    "average_loss": -3177.3333333333335
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 4,
    "net_profit": -2425.0,
    "win_rate": 0.25,
    "profit_factor": 0.549424005945745,
    "expectancy": -606.25,
    "average_win": 2957.0,
    "average_loss": -1794.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 8,
    "net_profit": -5618.0,
    "win_rate": 0.125,
    "profit_factor": 0.6310016420361247,
    "expectancy": -702.25,
    "average_win": 9607.0,
    "average_loss": -3045.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 6,
    "net_profit": 10882.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.28144135657089,
    "expectancy": 1813.6666666666667,
    "average_win": 9687.0,
    "average_loss": -2123.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 5,
    "net_profit": -1839.0,
    "win_rate": 0.2,
    "profit_factor": 0.8362567892440567,
    "expectancy": -367.8,
    "average_win": 9392.0,
    "average_loss": -3743.6666666666665
  },
  {
    "weekday": "Wed",
    "number_of_trades": 9,
    "net_profit": 10260.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.538243626062323,
    "expectancy": 1140.0,
    "average_win": 9774.0,
    "average_loss": -3812.4
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_-0.000153-0.00122",
    "number_of_trades": 12,
    "net_profit": -4976.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.8005691154663139,
    "expectancy": -414.6666666666667,
    "average_win": 9987.5,
    "average_loss": -3118.875
  },
  {
    "atr_band": "ATR_0.00122-0.00159",
    "number_of_trades": 9,
    "net_profit": 18835.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 1.9871075939416174,
    "expectancy": 2092.777777777778,
    "average_win": 9479.0,
    "average_loss": -3816.2
  },
  {
    "atr_band": "ATR_0.00159-0.00414",
    "number_of_trades": 11,
    "net_profit": -2599.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.8307942708333333,
    "expectancy": -236.27272727272728,
    "average_win": 6380.5,
    "average_loss": -2194.285714285714
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.19-42.49",
    "number_of_trades": 11,
    "net_profit": -7564.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.6192872961546205,
    "expectancy": -687.6363636363636,
    "average_win": 6152.0,
    "average_loss": -2483.5
  },
  {
    "adx_band": "ADX_42.49-46.19",
    "number_of_trades": 10,
    "net_profit": 37317.0,
    "win_rate": 0.5,
    "profit_factor": 4.266544117647059,
    "expectancy": 3731.7,
    "average_win": 9748.2,
    "average_loss": -2856.0
  },
  {
    "adx_band": "ADX_46.19-54.09",
    "number_of_trades": 11,
    "net_profit": -18493.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.3418861209964413,
    "expectancy": -1681.1818181818182,
    "average_win": 9607.0,
    "average_loss": -3512.5
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.215-4.782",
    "number_of_trades": 11,
    "net_profit": -10677.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.6456826176412026,
    "expectancy": -970.6363636363636,
    "average_win": 9728.5,
    "average_loss": -3766.75
  },
  {
    "hold_time_band": "HOLD_H_4.782-9.775",
    "number_of_trades": 10,
    "net_profit": -6315.0,
    "win_rate": 0.2,
    "profit_factor": 0.6689557559236737,
    "expectancy": -631.5,
    "average_win": 6380.5,
    "average_loss": -3815.2
  },
  {
    "hold_time_band": "HOLD_H_9.775-85.62",
    "number_of_trades": 11,
    "net_profit": 28252.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 3.774700451777647,
    "expectancy": 2568.3636363636365,
    "average_win": 9608.5,
    "average_loss": -1454.5714285714287
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-98-3206",
    "number_of_trades": 11,
    "net_profit": -39357.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3577.909090909091,
    "average_win": null,
    "average_loss": -3577.909090909091
  },
  {
    "mfe_band": "MFE_3206-6085",
    "number_of_trades": 10,
    "net_profit": -16897.0,
    "win_rate": 0.1,
    "profit_factor": 0.14893724186561902,
    "expectancy": -1689.7,
    "average_win": 2957.0,
    "average_loss": -3309.0
  },
  {
    "mfe_band": "MFE_6085-9953",
    "number_of_trades": 11,
    "net_profit": 67514.0,
    "win_rate": 0.6363636363636364,
    "profit_factor": 374.0055248618784,
    "expectancy": 6137.636363636364,
    "average_win": 9670.714285714286,
    "average_loss": -60.333333333333336
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2273--537",
    "number_of_trades": 11,
    "net_profit": 31937.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 94.65689149560117,
    "expectancy": 2903.3636363636365,
    "average_win": 8069.5,
    "average_loss": -85.25
  },
  {
    "mae_band": "MAE_-3748--2273",
    "number_of_trades": 10,
    "net_profit": 21879.0,
    "win_rate": 0.4,
    "profit_factor": 2.3264019399818125,
    "expectancy": 2187.9,
    "average_win": 9593.5,
    "average_loss": -3299.0
  },
  {
    "mae_band": "MAE_-4444--3748",
    "number_of_trades": 11,
    "net_profit": -42556.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3868.7272727272725,
    "average_win": null,
    "average_loss": -3868.7272727272725
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 6,
    "net_profit": 7345.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.330134009416878,
    "expectancy": 1224.1666666666667,
    "average_win": 6433.5,
    "average_loss": -1840.6666666666667
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 26,
    "net_profit": 3915.0,
    "win_rate": 0.23076923076923078,
    "profit_factor": 1.0726749582327826,
    "expectancy": 150.57692307692307,
    "average_win": 9630.833333333334,
    "average_loss": -3168.823529411765
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 1,
    "net_profit": -20.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -20.0,
    "average_win": null,
    "average_loss": -20.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 31,
    "net_profit": 11280.0,
    "win_rate": 0.25806451612903225,
    "profit_factor": 1.1899885467897324,
    "expectancy": 363.8709677419355,
    "average_win": 8831.5,
    "average_loss": -3124.842105263158
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 17,
    "net_profit": -56094.0,
    "win_rate": 0.058823529411764705,
    "profit_factor": 0.05007535858833889,
    "expectancy": -3299.6470588235293,
    "average_win": 2957.0,
    "average_loss": -3690.6875
  },
  {
    "close_reason": "SL",
    "number_of_trades": 8,
    "net_profit": -341.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -42.625,
    "average_win": null,
    "average_loss": -85.25
  },
  {
    "close_reason": "TP",
    "number_of_trades": 7,
    "net_profit": 67695.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9670.714285714286,
    "average_win": 9670.714285714286,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 9,
    "net_profit": 9593.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 2.0009390651085144,
    "expectancy": 1065.888888888889,
    "average_win": 9588.5,
    "average_loss": -1916.8
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 9,
    "net_profit": 22828.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 2.436988543371522,
    "expectancy": 2536.4444444444443,
    "average_win": 9678.5,
    "average_loss": -3971.5
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 10,
    "net_profit": -23327.0,
    "win_rate": 0.1,
    "profit_factor": 0.11250190229797595,
    "expectancy": -2332.7,
    "average_win": 2957.0,
    "average_loss": -3285.5
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 4,
    "net_profit": 2166.0,
    "win_rate": 0.25,
    "profit_factor": 1.2835820895522387,
    "expectancy": 541.5,
    "average_win": 9804.0,
    "average_loss": -2546.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 6,
    "net_profit": 4233.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.5103689414034243,
    "expectancy": 705.5,
    "average_win": 6263.5,
    "average_loss": -2073.5
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 8,
    "net_profit": -16916.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2114.5,
    "average_win": null,
    "average_loss": -2819.3333333333335
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": 12093.0,
    "win_rate": 0.5,
    "profit_factor": 2.586799632594148,
    "expectancy": 3023.25,
    "average_win": 9857.0,
    "average_loss": -3810.5
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 7,
    "net_profit": 7687.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.6795438472418671,
    "expectancy": 1098.142857142857,
    "average_win": 9499.5,
    "average_loss": -2828.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 7,
    "net_profit": 4163.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.2730015082956259,
    "expectancy": 594.7142857142857,
    "average_win": 9706.0,
    "average_loss": -3812.25
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0123-1",
    "number_of_trades": 12,
    "net_profit": 70652.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": null,
    "expectancy": 5887.666666666667,
    "average_win": 8831.5,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1-2.009",
    "number_of_trades": 8,
    "net_profit": -16250.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2031.25,
    "average_win": null,
    "average_loss": -2031.25
  },
  {
    "giveback_band": "GIVEBACK_2.009-35.84",
    "number_of_trades": 10,
    "net_profit": -35709.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3570.9,
    "average_win": null,
    "average_loss": -3570.9
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
