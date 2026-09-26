# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 22
- MFEデータのある負けトレード数: 22
- うち一度含み益になった数: 20
- 割合: 90.91%
- 反転前の平均含み益: 2317.55

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 28
- 平均Giveback比率: 412.43%
- 中央値Giveback比率: 203.27%
- 損益ゼロ以下まで完全反転した割合: 78.57%

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

- 決済件数: 18
- 純損益: -60120.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3340.00
- 平均逆行幅（R）: 0.7983
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 9,
    "net_profit": -30183.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3353.6666666666665,
    "average_win": null,
    "average_loss": -3353.6666666666665
  },
  "SELL": {
    "number_of_trades": 9,
    "net_profit": -29937.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3326.3333333333335,
    "average_win": null,
    "average_loss": -3326.3333333333335
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 5889
- 最終Entry候補まで到達: 48
- Stage別棄却数（market_regime）: 4736
- Stage別棄却数（htf_bias）: 140
- Stage別棄却数（trend_strength_or_momentum_filter）: 583
- Stage別棄却数（setup_or_trigger）: 382
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 4736,
  "CONFIRMATION_ADX_TOO_LOW": 78,
  "RSI_FILTERED": 505,
  "ENTRY_PATTERN_NOT_FOUND": 382,
  "TREND_NOT_ALIGNED": 140
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 13,
    "net_profit": -16507.0,
    "win_rate": 0.15384615384615385,
    "profit_factor": 0.454512408710882,
    "expectancy": -1269.7692307692307,
    "average_win": 6877.0,
    "average_loss": -3026.1
  },
  {
    "direction": "SELL",
    "number_of_trades": 17,
    "net_profit": -12263.0,
    "win_rate": 0.23529411764705882,
    "profit_factor": 0.6204228185842078,
    "expectancy": -721.3529411764706,
    "average_win": 5011.0,
    "average_loss": -2692.25
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 7,
    "net_profit": 2632.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.2027578768970033,
    "expectancy": 376.0,
    "average_win": 7806.5,
    "average_loss": -2596.2
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 7,
    "net_profit": -7023.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5422668317799648,
    "expectancy": -1003.2857142857143,
    "average_win": 8320.0,
    "average_loss": -3835.75
  },
  {
    "session": "NewYork",
    "number_of_trades": 8,
    "net_profit": -9143.0,
    "win_rate": 0.125,
    "profit_factor": 0.4320765264923287,
    "expectancy": -1142.875,
    "average_win": 6956.0,
    "average_loss": -2299.8571428571427
  },
  {
    "session": "Tokyo",
    "number_of_trades": 8,
    "net_profit": -15236.0,
    "win_rate": 0.25,
    "profit_factor": 0.16031964728575365,
    "expectancy": -1904.5,
    "average_win": 1454.5,
    "average_loss": -3024.1666666666665
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": -8111.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2703.6666666666665,
    "average_win": null,
    "average_loss": -2703.6666666666665
  },
  {
    "weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": -9515.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.4223180134782345,
    "expectancy": -1359.2857142857142,
    "average_win": 6956.0,
    "average_loss": -2745.1666666666665
  },
  {
    "weekday": "Thu",
    "number_of_trades": 5,
    "net_profit": -9485.0,
    "win_rate": 0.2,
    "profit_factor": 0.00472193074501574,
    "expectancy": -1897.0,
    "average_win": 45.0,
    "average_loss": -3176.6666666666665
  },
  {
    "weekday": "Tue",
    "number_of_trades": 7,
    "net_profit": -6629.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5565589671549936,
    "expectancy": -947.0,
    "average_win": 8320.0,
    "average_loss": -2491.5
  },
  {
    "weekday": "Wed",
    "number_of_trades": 8,
    "net_profit": 4970.0,
    "win_rate": 0.375,
    "profit_factor": 1.3679573554453246,
    "expectancy": 621.25,
    "average_win": 6159.0,
    "average_loss": -3376.75
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_2.757-3.763",
    "number_of_trades": 10,
    "net_profit": -1672.0,
    "win_rate": 0.2,
    "profit_factor": 0.9110969319934067,
    "expectancy": -167.2,
    "average_win": 8567.5,
    "average_loss": -2686.714285714286
  },
  {
    "atr_band": "ATR_3.763-5.489",
    "number_of_trades": 10,
    "net_profit": -5581.0,
    "win_rate": 0.2,
    "profit_factor": 0.7113524696146883,
    "expectancy": -558.1,
    "average_win": 6877.0,
    "average_loss": -2762.1428571428573
  },
  {
    "atr_band": "ATR_5.489-10.91",
    "number_of_trades": 10,
    "net_profit": -21517.0,
    "win_rate": 0.2,
    "profit_factor": 0.11909440759846066,
    "expectancy": -2151.7,
    "average_win": 1454.5,
    "average_loss": -3053.25
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.39-43.79",
    "number_of_trades": 10,
    "net_profit": -8349.0,
    "win_rate": 0.2,
    "profit_factor": 0.5148468824452321,
    "expectancy": -834.9,
    "average_win": 4430.0,
    "average_loss": -2458.4285714285716
  },
  {
    "adx_band": "ADX_43.79-48.87",
    "number_of_trades": 10,
    "net_profit": -15561.0,
    "win_rate": 0.2,
    "profit_factor": 0.386903589299082,
    "expectancy": -1556.1,
    "average_win": 4910.0,
    "average_loss": -3172.625
  },
  {
    "adx_band": "ADX_48.87-64.23",
    "number_of_trades": 10,
    "net_profit": -4860.0,
    "win_rate": 0.2,
    "profit_factor": 0.7567324056462108,
    "expectancy": -486.0,
    "average_win": 7559.0,
    "average_loss": -2854.0
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.261-1.49",
    "number_of_trades": 10,
    "net_profit": -10795.0,
    "win_rate": 0.1,
    "profit_factor": 0.43526026680617314,
    "expectancy": -1079.5,
    "average_win": 8320.0,
    "average_loss": -2389.375
  },
  {
    "hold_time_band": "HOLD_H_1.49-7.631",
    "number_of_trades": 10,
    "net_profit": 1121.0,
    "win_rate": 0.3,
    "profit_factor": 1.052265945542708,
    "expectancy": 112.1,
    "average_win": 7523.0,
    "average_loss": -3574.6666666666665
  },
  {
    "hold_time_band": "HOLD_H_7.631-70.58",
    "number_of_trades": 10,
    "net_profit": -19096.0,
    "win_rate": 0.2,
    "profit_factor": 0.13219722790274938,
    "expectancy": -1909.6,
    "average_win": 1454.5,
    "average_loss": -2750.625
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-179-1042",
    "number_of_trades": 10,
    "net_profit": -32224.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3222.4,
    "average_win": null,
    "average_loss": -3222.4
  },
  {
    "mfe_band": "MFE_1042-4362",
    "number_of_trades": 10,
    "net_profit": -30120.0,
    "win_rate": 0.1,
    "profit_factor": 0.0014917951268025858,
    "expectancy": -3012.0,
    "average_win": 45.0,
    "average_loss": -3351.6666666666665
  },
  {
    "mfe_band": "MFE_4362-8606",
    "number_of_trades": 10,
    "net_profit": 33574.0,
    "win_rate": 0.5,
    "profit_factor": 188.56424581005587,
    "expectancy": 3357.4,
    "average_win": 6750.6,
    "average_loss": -59.666666666666664
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2191--261",
    "number_of_trades": 10,
    "net_profit": 22759.0,
    "win_rate": 0.5,
    "profit_factor": 11.233363309352518,
    "expectancy": 2275.9,
    "average_win": 4996.6,
    "average_loss": -741.3333333333334
  },
  {
    "mae_band": "MAE_-3414--2191",
    "number_of_trades": 10,
    "net_profit": -14486.0,
    "win_rate": 0.1,
    "profit_factor": 0.37830994377923693,
    "expectancy": -1448.6,
    "average_win": 8815.0,
    "average_loss": -2589.0
  },
  {
    "mae_band": "MAE_-4583--3414",
    "number_of_trades": 10,
    "net_profit": -37043.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3704.3,
    "average_win": null,
    "average_loss": -3704.3
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 18,
    "net_profit": -21974.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.4185234188938873,
    "expectancy": -1220.7777777777778,
    "average_win": 5272.0,
    "average_loss": -2519.3333333333335
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 12,
    "net_profit": -6796.0,
    "win_rate": 0.25,
    "profit_factor": 0.7257244329647268,
    "expectancy": -566.3333333333334,
    "average_win": 5994.0,
    "average_loss": -3539.714285714286
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 4,
    "net_profit": -4458.0,
    "win_rate": 0.25,
    "profit_factor": 0.3911499590275881,
    "expectancy": -1114.5,
    "average_win": 2864.0,
    "average_loss": -2440.6666666666665
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 11,
    "net_profit": -4711.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.7843541151698251,
    "expectancy": -428.27272727272725,
    "average_win": 8567.5,
    "average_loss": -2730.75
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 15,
    "net_profit": -19601.0,
    "win_rate": 0.2,
    "profit_factor": 0.4131437125748503,
    "expectancy": -1306.7333333333333,
    "average_win": 4599.666666666667,
    "average_loss": -3036.3636363636365
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 21,
    "net_profit": -59480.0,
    "win_rate": 0.09523809523809523,
    "profit_factor": 0.046626809213162576,
    "expectancy": -2832.3809523809523,
    "average_win": 1454.5,
    "average_loss": -3283.6315789473683
  },
  {
    "close_reason": "SL",
    "number_of_trades": 5,
    "net_profit": -179.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -35.8,
    "average_win": null,
    "average_loss": -59.666666666666664
  },
  {
    "close_reason": "TP",
    "number_of_trades": 4,
    "net_profit": 30889.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7722.25,
    "average_win": 7722.25,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 1,
    "net_profit": -3039.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3039.0,
    "average_win": null,
    "average_loss": -3039.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 14,
    "net_profit": -30674.0,
    "win_rate": 0.07142857142857142,
    "profit_factor": 0.18141545687446628,
    "expectancy": -2191.0,
    "average_win": 6798.0,
    "average_loss": -3406.5454545454545
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 14,
    "net_profit": 2079.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.0942557918121232,
    "expectancy": 148.5,
    "average_win": 6034.0,
    "average_loss": -2205.7
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 1,
    "net_profit": 2864.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 2864.0,
    "average_win": 2864.0,
    "average_loss": null
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": -7322.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2440.6666666666665,
    "average_win": null,
    "average_loss": -2440.6666666666665
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 6,
    "net_profit": -7591.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.4781741939918884,
    "expectancy": -1265.1666666666667,
    "average_win": 6956.0,
    "average_loss": -2909.4
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 5,
    "net_profit": -3610.0,
    "win_rate": 0.4,
    "profit_factor": 0.4462340849823593,
    "expectancy": -722.0,
    "average_win": 1454.5,
    "average_loss": -3259.5
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 7,
    "net_profit": -5048.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.6223818073010173,
    "expectancy": -721.1428571428571,
    "average_win": 8320.0,
    "average_loss": -2228.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 9,
    "net_profit": -5199.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.750192196809533,
    "expectancy": -577.6666666666666,
    "average_win": 7806.5,
    "average_loss": -3468.6666666666665
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0392-1.007",
    "number_of_trades": 10,
    "net_profit": 33697.0,
    "win_rate": 0.6,
    "profit_factor": 334.63366336633663,
    "expectancy": 3369.7,
    "average_win": 5633.0,
    "average_loss": -50.5
  },
  {
    "giveback_band": "GIVEBACK_1.007-3.649",
    "number_of_trades": 8,
    "net_profit": -22161.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2770.125,
    "average_win": null,
    "average_loss": -2770.125
  },
  {
    "giveback_band": "GIVEBACK_3.649-32.64",
    "number_of_trades": 10,
    "net_profit": -33350.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3335.0,
    "average_win": null,
    "average_loss": -3335.0
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
