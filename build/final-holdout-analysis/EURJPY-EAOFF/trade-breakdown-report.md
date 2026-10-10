# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 25
- MFEデータのある負けトレード数: 25
- うち一度含み益になった数: 23
- 割合: 92.00%
- 反転前の平均含み益: 1985.00

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 43
- 平均Giveback比率: 467.76%
- 中央値Giveback比率: 101.46%
- 損益ゼロ以下まで完全反転した割合: 58.14%

## Time Stop（時間切れ決済）

- Time Stopによる決済件数: 3
- 純損益: -2718.00
- プロフィットファクター: 0.0480
- 勝率: 33.33%
- 期待値: -906.00

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

- 決済件数: 0
- 純損益: 0.00
- プロフィットファクター: 算出不能
- 勝率: 算出不能
- 期待値: 0.00
- 平均逆行幅（R）: 算出不能
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 10467
- 最終Entry候補まで到達: 87
- Stage別棄却数（market_regime）: 8772
- Stage別棄却数（htf_bias）: 277
- Stage別棄却数（trend_strength_or_momentum_filter）: 793
- Stage別棄却数（setup_or_trigger）: 538
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 8772,
  "TREND_NOT_ALIGNED": 277,
  "ENTRY_PATTERN_NOT_FOUND": 538,
  "RSI_FILTERED": 707,
  "CONFIRMATION_ADX_TOO_LOW": 86
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 41,
    "net_profit": 30327.0,
    "win_rate": 0.4146341463414634,
    "profit_factor": 1.3850852020214846,
    "expectancy": 739.6829268292682,
    "average_win": 6416.529411764706,
    "average_loss": -3579.7272727272725
  },
  {
    "direction": "SELL",
    "number_of_trades": 4,
    "net_profit": -1991.0,
    "win_rate": 0.25,
    "profit_factor": 0.8249054612611028,
    "expectancy": -497.75,
    "average_win": 9380.0,
    "average_loss": -3790.3333333333335
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 9,
    "net_profit": 2799.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 1.138194924459366,
    "expectancy": 311.0,
    "average_win": 5763.25,
    "average_loss": -4050.8
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 10,
    "net_profit": -17637.0,
    "win_rate": 0.2,
    "profit_factor": 0.34788878207498336,
    "expectancy": -1763.7,
    "average_win": 4704.5,
    "average_loss": -3863.714285714286
  },
  {
    "session": "NewYork",
    "number_of_trades": 17,
    "net_profit": 40762.0,
    "win_rate": 0.5294117647058824,
    "profit_factor": 2.8805130097804024,
    "expectancy": 2397.764705882353,
    "average_win": 6937.555555555556,
    "average_loss": -2709.5
  },
  {
    "session": "Tokyo",
    "number_of_trades": 9,
    "net_profit": 2412.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.1140479455293395,
    "expectancy": 268.0,
    "average_win": 7853.666666666667,
    "average_loss": -4229.8
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 9,
    "net_profit": 358.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 1.018229034064871,
    "expectancy": 39.77777777777778,
    "average_win": 4999.25,
    "average_loss": -3927.8
  },
  {
    "weekday": "Mon",
    "number_of_trades": 9,
    "net_profit": 17171.0,
    "win_rate": 0.5555555555555556,
    "profit_factor": 2.0365831572592814,
    "expectancy": 1907.888888888889,
    "average_win": 6747.2,
    "average_loss": -4141.25
  },
  {
    "weekday": "Thu",
    "number_of_trades": 12,
    "net_profit": 11565.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.4623595730220285,
    "expectancy": 963.75,
    "average_win": 9144.5,
    "average_loss": -3126.625
  },
  {
    "weekday": "Tue",
    "number_of_trades": 10,
    "net_profit": 3871.0,
    "win_rate": 0.3,
    "profit_factor": 1.160469261700452,
    "expectancy": 387.1,
    "average_win": 9331.333333333334,
    "average_loss": -4020.5
  },
  {
    "weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": -4629.0,
    "win_rate": 0.4,
    "profit_factor": 0.03260188087774295,
    "expectancy": -925.8,
    "average_win": 78.0,
    "average_loss": -2392.5
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.0939-0.177",
    "number_of_trades": 15,
    "net_profit": 2162.0,
    "win_rate": 0.4,
    "profit_factor": 1.053872221668494,
    "expectancy": 144.13333333333333,
    "average_win": 7049.0,
    "average_loss": -4459.111111111111
  },
  {
    "atr_band": "ATR_0.177-0.24",
    "number_of_trades": 15,
    "net_profit": 39967.0,
    "win_rate": 0.5333333333333333,
    "profit_factor": 3.5172891604207344,
    "expectancy": 2664.4666666666667,
    "average_win": 6980.5,
    "average_loss": -2646.1666666666665
  },
  {
    "atr_band": "ATR_0.24-0.401",
    "number_of_trades": 15,
    "net_profit": -13793.0,
    "win_rate": 0.26666666666666666,
    "profit_factor": 0.595702896001876,
    "expectancy": -919.5333333333333,
    "average_win": 5080.75,
    "average_loss": -3411.6
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.11-41.6",
    "number_of_trades": 15,
    "net_profit": 25251.0,
    "win_rate": 0.4,
    "profit_factor": 2.5668279970215933,
    "expectancy": 1683.4,
    "average_win": 6894.5,
    "average_loss": -2014.5
  },
  {
    "adx_band": "ADX_41.6-44.26",
    "number_of_trades": 15,
    "net_profit": -12318.0,
    "win_rate": 0.4,
    "profit_factor": 0.7064696771118789,
    "expectancy": -821.2,
    "average_win": 4941.166666666667,
    "average_loss": -4662.777777777777
  },
  {
    "adx_band": "ADX_44.26-61.41",
    "number_of_trades": 15,
    "net_profit": 15403.0,
    "win_rate": 0.4,
    "profit_factor": 1.4806828111346897,
    "expectancy": 1026.8666666666666,
    "average_win": 7907.833333333333,
    "average_loss": -4005.5
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_1.656-6.853",
    "number_of_trades": 15,
    "net_profit": -27665.0,
    "win_rate": 0.2,
    "profit_factor": 0.49619391025641024,
    "expectancy": -1844.3333333333333,
    "average_win": 9082.333333333334,
    "average_loss": -4576.0
  },
  {
    "hold_time_band": "HOLD_H_18.54-71.17",
    "number_of_trades": 15,
    "net_profit": 36893.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 5.926949786324786,
    "expectancy": 2459.5333333333333,
    "average_win": 4438.1,
    "average_loss": -1497.6
  },
  {
    "hold_time_band": "HOLD_H_6.853-18.54",
    "number_of_trades": 15,
    "net_profit": 19108.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.6891974752028855,
    "expectancy": 1273.8666666666666,
    "average_win": 9366.6,
    "average_loss": -3465.625
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-104-1624",
    "number_of_trades": 15,
    "net_profit": -62652.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4176.8,
    "average_win": null,
    "average_loss": -4176.8
  },
  {
    "mfe_band": "MFE_1624-7514",
    "number_of_trades": 15,
    "net_profit": -20724.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.24223920435847746,
    "expectancy": -1381.6,
    "average_win": 1325.0,
    "average_loss": -3038.777777777778
  },
  {
    "mfe_band": "MFE_7514-9584",
    "number_of_trades": 15,
    "net_profit": 111712.0,
    "win_rate": 0.8666666666666667,
    "profit_factor": 901.9032258064516,
    "expectancy": 7447.466666666666,
    "average_win": 8602.76923076923,
    "average_loss": -124.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2626--420",
    "number_of_trades": 15,
    "net_profit": 58780.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 28.95054683785069,
    "expectancy": 3918.6666666666665,
    "average_win": 6088.3,
    "average_loss": -701.0
  },
  {
    "mae_band": "MAE_-4659--2626",
    "number_of_trades": 15,
    "net_profit": 43459.0,
    "win_rate": 0.5333333333333333,
    "profit_factor": 4.078050853459877,
    "expectancy": 2897.266666666667,
    "average_win": 7197.25,
    "average_loss": -2017.0
  },
  {
    "mae_band": "MAE_-5096--4659",
    "number_of_trades": 15,
    "net_profit": -73903.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4926.866666666667,
    "average_win": null,
    "average_loss": -4926.866666666667
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 8,
    "net_profit": -2158.0,
    "win_rate": 0.25,
    "profit_factor": 0.8954356042252156,
    "expectancy": -269.75,
    "average_win": 9240.0,
    "average_loss": -3439.6666666666665
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 37,
    "net_profit": 30494.0,
    "win_rate": 0.43243243243243246,
    "profit_factor": 1.438844675982558,
    "expectancy": 824.1621621621622,
    "average_win": 6248.8125,
    "average_loss": -3657.2105263157896
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 5,
    "net_profit": -1321.0,
    "win_rate": 0.2,
    "profit_factor": 0.787175769292734,
    "expectancy": -264.2,
    "average_win": 4886.0,
    "average_loss": -1551.75
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 3,
    "net_profit": -770.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.9219858156028369,
    "expectancy": -256.6666666666667,
    "average_win": 9100.0,
    "average_loss": -4935.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 37,
    "net_profit": 30427.0,
    "win_rate": 0.43243243243243246,
    "profit_factor": 1.4109091400172862,
    "expectancy": 822.3513513513514,
    "average_win": 6529.6875,
    "average_loss": -3897.2631578947367
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 12,
    "net_profit": 4827.0,
    "win_rate": 0.5,
    "profit_factor": 1.422975814931651,
    "expectancy": 402.25,
    "average_win": 2706.5,
    "average_loss": -1902.0
  },
  {
    "close_reason": "SL",
    "number_of_trades": 22,
    "net_profit": -78694.0,
    "win_rate": 0.045454545454545456,
    "profit_factor": 0.00024138325308398868,
    "expectancy": -3577.0,
    "average_win": 19.0,
    "average_loss": -4142.789473684211
  },
  {
    "close_reason": "TP",
    "number_of_trades": 11,
    "net_profit": 102203.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9291.181818181818,
    "average_win": 9291.181818181818,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 13,
    "net_profit": 13858.0,
    "win_rate": 0.46153846153846156,
    "profit_factor": 1.5801724859750481,
    "expectancy": 1066.0,
    "average_win": 6290.666666666667,
    "average_loss": -3412.285714285714
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": 18016.0,
    "win_rate": 0.5,
    "profit_factor": 2.2870410058579798,
    "expectancy": 2252.0,
    "average_win": 8003.5,
    "average_loss": -3499.5
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 11,
    "net_profit": -9888.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.6511184814056876,
    "expectancy": -898.9090909090909,
    "average_win": 9227.0,
    "average_loss": -4048.8571428571427
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 13,
    "net_profit": 6350.0,
    "win_rate": 0.46153846153846156,
    "profit_factor": 1.2657014937863509,
    "expectancy": 488.46153846153845,
    "average_win": 5041.5,
    "average_loss": -3414.1428571428573
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 11,
    "net_profit": -2074.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.9304026845637584,
    "expectancy": -188.54545454545453,
    "average_win": 9242.0,
    "average_loss": -3725.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": -3795.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 0.7382217010415948,
    "expectancy": -542.1428571428571,
    "average_win": 3567.3333333333335,
    "average_loss": -3624.25
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 10,
    "net_profit": 12860.0,
    "win_rate": 0.5,
    "profit_factor": 1.8569334310655028,
    "expectancy": 1286.0,
    "average_win": 5573.4,
    "average_loss": -3001.4
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 14,
    "net_profit": 12908.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.4313017909649826,
    "expectancy": 922.0,
    "average_win": 7139.333333333333,
    "average_loss": -4275.428571428572
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 3,
    "net_profit": 8437.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 10.447928331466965,
    "expectancy": 2812.3333333333335,
    "average_win": 9330.0,
    "average_loss": -893.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.01067-0.673",
    "number_of_trades": 14,
    "net_profit": 117003.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8357.357142857143,
    "average_win": 8357.357142857143,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.673-2.994",
    "number_of_trades": 14,
    "net_profit": -10826.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.11869098013676327,
    "expectancy": -773.2857142857143,
    "average_win": 364.5,
    "average_loss": -1535.5
  },
  {
    "giveback_band": "GIVEBACK_2.994-57.38",
    "number_of_trades": 15,
    "net_profit": -68106.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4540.4,
    "average_win": null,
    "average_loss": -4540.4
  }
]
```

## time_stop_reason_code別

```json
[
  {
    "time_stop_reason_code": "MAX_HOLDING_BARS_MIN_MFE_NOT_REACHED",
    "number_of_trades": 3,
    "net_profit": -2718.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.04798598949211909,
    "expectancy": -906.0,
    "average_win": 137.0,
    "average_loss": -1427.5
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
