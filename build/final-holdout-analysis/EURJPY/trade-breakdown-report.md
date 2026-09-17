# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 29
- MFEデータのある負けトレード数: 29
- うち一度含み益になった数: 27
- 割合: 93.10%
- 反転前の平均含み益: 1884.48

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 44
- 平均Giveback比率: 512.59%
- 中央値Giveback比率: 235.26%
- 損益ゼロ以下まで完全反転した割合: 65.91%

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

- 決済件数: 24
- 純損益: -88225.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3676.04
- 平均逆行幅（R）: 0.7608
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 21,
    "net_profit": -77494.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3690.190476190476,
    "average_win": null,
    "average_loss": -3690.190476190476
  },
  "SELL": {
    "number_of_trades": 3,
    "net_profit": -10731.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3577.0,
    "average_win": null,
    "average_loss": -3577.0
  }
}
```

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
    "number_of_trades": 42,
    "net_profit": 9030.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.113184843509106,
    "expectancy": 215.0,
    "average_win": 6343.642857142857,
    "average_loss": -3068.5
  },
  {
    "direction": "SELL",
    "number_of_trades": 4,
    "net_profit": -1351.0,
    "win_rate": 0.25,
    "profit_factor": 0.8741030658838878,
    "expectancy": -337.75,
    "average_win": 9380.0,
    "average_loss": -3577.0
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 9,
    "net_profit": -5757.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.7000468920960767,
    "expectancy": -639.6666666666666,
    "average_win": 4478.666666666667,
    "average_loss": -3198.8333333333335
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 10,
    "net_profit": -16825.0,
    "win_rate": 0.1,
    "profit_factor": 0.35528988006284246,
    "expectancy": -1682.5,
    "average_win": 9272.0,
    "average_loss": -3262.125
  },
  {
    "session": "NewYork",
    "number_of_trades": 17,
    "net_profit": 15967.0,
    "win_rate": 0.4117647058823529,
    "profit_factor": 1.5918965005931198,
    "expectancy": 939.2352941176471,
    "average_win": 6134.714285714285,
    "average_loss": -2697.6
  },
  {
    "session": "Tokyo",
    "number_of_trades": 10,
    "net_profit": 14294.0,
    "win_rate": 0.4,
    "profit_factor": 1.7834045818261537,
    "expectancy": 1429.4,
    "average_win": 8135.0,
    "average_loss": -3649.2
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 9,
    "net_profit": -8088.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.5671394166443672,
    "expectancy": -898.6666666666666,
    "average_win": 3532.3333333333335,
    "average_loss": -3114.1666666666665
  },
  {
    "weekday": "Mon",
    "number_of_trades": 10,
    "net_profit": 13870.0,
    "win_rate": 0.5,
    "profit_factor": 1.7607086052761476,
    "expectancy": 1387.0,
    "average_win": 6420.6,
    "average_loss": -3646.6
  },
  {
    "weekday": "Thu",
    "number_of_trades": 12,
    "net_profit": 16022.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.7794317960692743,
    "expectancy": 1335.1666666666667,
    "average_win": 9144.5,
    "average_loss": -2569.5
  },
  {
    "weekday": "Tue",
    "number_of_trades": 10,
    "net_profit": -6859.0,
    "win_rate": 0.2,
    "profit_factor": 0.7336620976196948,
    "expectancy": -685.9,
    "average_win": 9447.0,
    "average_loss": -3679.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": -7266.0,
    "win_rate": 0.2,
    "profit_factor": 0.002608098833218943,
    "expectancy": -1453.2,
    "average_win": 19.0,
    "average_loss": -2428.3333333333335
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.0939-0.177",
    "number_of_trades": 16,
    "net_profit": -17840.0,
    "win_rate": 0.25,
    "profit_factor": 0.5682582706130055,
    "expectancy": -1115.0,
    "average_win": 5870.25,
    "average_loss": -3443.4166666666665
  },
  {
    "atr_band": "ATR_0.177-0.239",
    "number_of_trades": 14,
    "net_profit": 40035.0,
    "win_rate": 0.5,
    "profit_factor": 3.692514627749008,
    "expectancy": 2859.6428571428573,
    "average_win": 7843.428571428572,
    "average_loss": -2478.1666666666665
  },
  {
    "atr_band": "ATR_0.239-0.401",
    "number_of_trades": 16,
    "net_profit": -14516.0,
    "win_rate": 0.25,
    "profit_factor": 0.577064273643727,
    "expectancy": -907.25,
    "average_win": 4951.5,
    "average_loss": -3120.181818181818
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.11-41.63",
    "number_of_trades": 16,
    "net_profit": 23333.0,
    "win_rate": 0.375,
    "profit_factor": 2.2938338693578797,
    "expectancy": 1458.3125,
    "average_win": 6894.5,
    "average_loss": -2003.7777777777778
  },
  {
    "adx_band": "ADX_41.63-44.48",
    "number_of_trades": 15,
    "net_profit": -19732.0,
    "win_rate": 0.26666666666666666,
    "profit_factor": 0.49595115845403226,
    "expectancy": -1315.4666666666667,
    "average_win": 4853.75,
    "average_loss": -3558.818181818182
  },
  {
    "adx_band": "ADX_44.48-61.41",
    "number_of_trades": 15,
    "net_profit": 4078.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.122348564399508,
    "expectancy": 271.8666666666667,
    "average_win": 7481.8,
    "average_loss": -3703.4444444444443
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.675-5.104",
    "number_of_trades": 15,
    "net_profit": -39773.0,
    "win_rate": 0.06666666666666667,
    "profit_factor": 0.18061392665842604,
    "expectancy": -2651.5333333333333,
    "average_win": 8767.0,
    "average_loss": -3467.1428571428573
  },
  {
    "hold_time_band": "HOLD_H_15.32-61",
    "number_of_trades": 16,
    "net_profit": 43225.0,
    "win_rate": 0.625,
    "profit_factor": 5.621511814391105,
    "expectancy": 2701.5625,
    "average_win": 5257.8,
    "average_loss": -1870.6
  },
  {
    "hold_time_band": "HOLD_H_5.104-15.32",
    "number_of_trades": 15,
    "net_profit": 4227.0,
    "win_rate": 0.26666666666666666,
    "profit_factor": 1.1295870504920444,
    "expectancy": 281.8,
    "average_win": 9211.5,
    "average_loss": -3261.9
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-104-1530",
    "number_of_trades": 15,
    "net_profit": -49965.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3331.0,
    "average_win": null,
    "average_loss": -3331.0
  },
  {
    "mfe_band": "MFE_1530-5850",
    "number_of_trades": 15,
    "net_profit": -38998.0,
    "win_rate": 0.2,
    "profit_factor": 0.032763709417396265,
    "expectancy": -2599.866666666667,
    "average_win": 440.3333333333333,
    "average_loss": -3359.9166666666665
  },
  {
    "mfe_band": "MFE_5850-9545",
    "number_of_trades": 16,
    "net_profit": 96642.0,
    "win_rate": 0.75,
    "profit_factor": 424.86842105263156,
    "expectancy": 6040.125,
    "average_win": 8072.5,
    "average_loss": -114.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2470--378",
    "number_of_trades": 16,
    "net_profit": 67104.0,
    "win_rate": 0.6875,
    "profit_factor": 32.90870185449358,
    "expectancy": 4194.0,
    "average_win": 6291.545454545455,
    "average_loss": -701.0
  },
  {
    "mae_band": "MAE_-3670--2470",
    "number_of_trades": 13,
    "net_profit": -26397.0,
    "win_rate": 0.07692307692307693,
    "profit_factor": 0.2611470316567302,
    "expectancy": -2030.5384615384614,
    "average_win": 9330.0,
    "average_loss": -2977.25
  },
  {
    "mae_band": "MAE_-4405--3670",
    "number_of_trades": 17,
    "net_profit": -33028.0,
    "win_rate": 0.17647058823529413,
    "profit_factor": 0.37306860028093086,
    "expectancy": -1942.8235294117646,
    "average_win": 6551.333333333333,
    "average_loss": -3763.0
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 8,
    "net_profit": -12023.0,
    "win_rate": 0.125,
    "profit_factor": 0.43825631920758773,
    "expectancy": -1502.875,
    "average_win": 9380.0,
    "average_loss": -3057.5714285714284
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 38,
    "net_profit": 19702.0,
    "win_rate": 0.3684210526315789,
    "profit_factor": 1.285085878829096,
    "expectancy": 518.4736842105264,
    "average_win": 6343.642857142857,
    "average_loss": -3141.318181818182
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 5,
    "net_profit": -4273.0,
    "win_rate": 0.2,
    "profit_factor": 0.5334643520034938,
    "expectancy": -854.6,
    "average_win": 4886.0,
    "average_loss": -2289.75
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 3,
    "net_profit": -11200.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3733.3333333333335,
    "average_win": null,
    "average_loss": -3733.3333333333335
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 38,
    "net_profit": 23152.0,
    "win_rate": 0.3684210526315789,
    "profit_factor": 1.3300215243824214,
    "expectancy": 609.2631578947369,
    "average_win": 6664.642857142857,
    "average_loss": -3188.7727272727275
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 31,
    "net_profit": -74696.0,
    "win_rate": 0.16129032258064516,
    "profit_factor": 0.17262768467340858,
    "expectancy": -2409.548387096774,
    "average_win": 3117.0,
    "average_loss": -3472.346153846154
  },
  {
    "close_reason": "SL",
    "number_of_trades": 6,
    "net_profit": -212.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.08225108225108226,
    "expectancy": -35.333333333333336,
    "average_win": 19.0,
    "average_loss": -77.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 9,
    "net_profit": 82587.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9176.333333333334,
    "average_win": 9176.333333333334,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 12,
    "net_profit": 2992.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.1220228384991844,
    "expectancy": 249.33333333333334,
    "average_win": 6878.0,
    "average_loss": -3065.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 3,
    "net_profit": 9658.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 3.504668049792531,
    "expectancy": 3219.3333333333335,
    "average_win": 6757.0,
    "average_loss": -3856.0
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 15,
    "net_profit": -5546.0,
    "win_rate": 0.2,
    "profit_factor": 0.831832378180054,
    "expectancy": -369.73333333333335,
    "average_win": 9144.333333333334,
    "average_loss": -3297.9
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 16,
    "net_profit": 575.0,
    "win_rate": 0.375,
    "profit_factor": 1.0197208217580684,
    "expectancy": 35.9375,
    "average_win": 4955.333333333333,
    "average_loss": -2915.7
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 12,
    "net_profit": 31.0,
    "win_rate": 0.25,
    "profit_factor": 1.001119335620148,
    "expectancy": 2.5833333333333335,
    "average_win": 9242.0,
    "average_loss": -3077.222222222222
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": -13521.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.08783647035013155,
    "expectancy": -1931.5714285714287,
    "average_win": 651.0,
    "average_loss": -2964.6
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 9,
    "net_profit": 16373.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 2.4416659329048165,
    "expectancy": 1819.2222222222222,
    "average_win": 6932.5,
    "average_loss": -2271.4
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 14,
    "net_profit": 2669.0,
    "win_rate": 0.35714285714285715,
    "profit_factor": 1.0906774478494259,
    "expectancy": 190.64285714285714,
    "average_win": 6420.6,
    "average_loss": -3679.25
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 4,
    "net_profit": 2127.0,
    "win_rate": 0.25,
    "profit_factor": 1.2952936276551437,
    "expectancy": 531.75,
    "average_win": 9330.0,
    "average_loss": -3601.5
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00976-0.998",
    "number_of_trades": 15,
    "net_profit": 98191.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 6546.066666666667,
    "average_win": 6546.066666666667,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.998-2.91",
    "number_of_trades": 14,
    "net_profit": -29587.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2113.3571428571427,
    "average_win": null,
    "average_loss": -2465.5833333333335
  },
  {
    "giveback_band": "GIVEBACK_2.91-52",
    "number_of_trades": 15,
    "net_profit": -53562.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3570.8,
    "average_win": null,
    "average_loss": -3570.8
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
