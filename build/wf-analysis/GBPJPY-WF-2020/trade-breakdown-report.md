# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 16
- MFEデータのある負けトレード数: 16
- うち一度含み益になった数: 15
- 割合: 93.75%
- 反転前の平均含み益: 1991.07

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 27
- 平均Giveback比率: 1355.41%
- 中央値Giveback比率: 104.97%
- 損益ゼロ以下まで完全反転した割合: 62.96%

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

- 決済件数: 14
- 純損益: -52770.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3769.29
- 平均逆行幅（R）: 0.7621
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 8,
    "net_profit": -30074.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3759.25,
    "average_win": null,
    "average_loss": -3759.25
  },
  "SELL": {
    "number_of_trades": 6,
    "net_profit": -22696.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3782.6666666666665,
    "average_win": null,
    "average_loss": -3782.6666666666665
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6236
- 最終Entry候補まで到達: 44
- Stage別棄却数（market_regime）: 5197
- Stage別棄却数（htf_bias）: 180
- Stage別棄却数（trend_strength_or_momentum_filter）: 472
- Stage別棄却数（setup_or_trigger）: 343
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5197,
  "RSI_FILTERED": 450,
  "ENTRY_PATTERN_NOT_FOUND": 343,
  "CONFIRMATION_ADX_TOO_LOW": 22,
  "TREND_NOT_ALIGNED": 180
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 16,
    "net_profit": 7502.0,
    "win_rate": 0.375,
    "profit_factor": 1.2494513533284566,
    "expectancy": 468.875,
    "average_win": 6262.666666666667,
    "average_loss": -3759.25
  },
  {
    "direction": "SELL",
    "number_of_trades": 12,
    "net_profit": 14960.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.6527620211187712,
    "expectancy": 1246.6666666666667,
    "average_win": 9469.5,
    "average_loss": -2864.75
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 7,
    "net_profit": -974.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.9496562774590376,
    "expectancy": -139.14285714285714,
    "average_win": 9186.5,
    "average_loss": -3869.4
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 9,
    "net_profit": 9407.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.5056167696855685,
    "expectancy": 1045.2222222222222,
    "average_win": 9337.333333333334,
    "average_loss": -3721.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 5,
    "net_profit": 1679.0,
    "win_rate": 0.6,
    "profit_factor": 1.2220018511172814,
    "expectancy": 335.8,
    "average_win": 3080.6666666666665,
    "average_loss": -3781.5
  },
  {
    "session": "Tokyo",
    "number_of_trades": 7,
    "net_profit": 12350.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 2.6517319780660693,
    "expectancy": 1764.2857142857142,
    "average_win": 9913.5,
    "average_loss": -1869.25
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 9,
    "net_profit": -17261.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.3437630688514618,
    "expectancy": -1917.888888888889,
    "average_win": 9042.0,
    "average_loss": -3287.875
  },
  {
    "weekday": "Mon",
    "number_of_trades": 4,
    "net_profit": -1396.0,
    "win_rate": 0.25,
    "profit_factor": 0.8757454383622608,
    "expectancy": -349.0,
    "average_win": 9839.0,
    "average_loss": -3745.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": -3659.0,
    "win_rate": 0.25,
    "profit_factor": 0.02034805890227577,
    "expectancy": -914.75,
    "average_win": 76.0,
    "average_loss": -1867.5
  },
  {
    "weekday": "Tue",
    "number_of_trades": 7,
    "net_profit": 28631.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 4.617308907138345,
    "expectancy": 4090.1428571428573,
    "average_win": 9136.5,
    "average_loss": -3957.5
  },
  {
    "weekday": "Wed",
    "number_of_trades": 4,
    "net_profit": 16147.0,
    "win_rate": 0.75,
    "profit_factor": 5.2447423764458465,
    "expectancy": 4036.75,
    "average_win": 6650.333333333333,
    "average_loss": -3804.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.115-0.19",
    "number_of_trades": 10,
    "net_profit": 28113.0,
    "win_rate": 0.5,
    "profit_factor": 2.461326541220501,
    "expectancy": 2811.3,
    "average_win": 9470.2,
    "average_loss": -3847.6
  },
  {
    "atr_band": "ATR_0.19-0.25",
    "number_of_trades": 8,
    "net_profit": -8854.0,
    "win_rate": 0.25,
    "profit_factor": 0.5285912043445853,
    "expectancy": -1106.75,
    "average_win": 4964.0,
    "average_loss": -3756.4
  },
  {
    "atr_band": "ATR_0.25-0.838",
    "number_of_trades": 10,
    "net_profit": 3203.0,
    "win_rate": 0.3,
    "profit_factor": 1.2139326743254075,
    "expectancy": 320.3,
    "average_win": 6058.333333333333,
    "average_loss": -2495.3333333333335
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.26-43.81",
    "number_of_trades": 10,
    "net_profit": 19225.0,
    "win_rate": 0.5,
    "profit_factor": 2.009822460342473,
    "expectancy": 1922.5,
    "average_win": 7652.6,
    "average_loss": -3807.6
  },
  {
    "adx_band": "ADX_43.81-46.05",
    "number_of_trades": 9,
    "net_profit": 16577.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.4547608600263273,
    "expectancy": 1841.888888888889,
    "average_win": 9324.0,
    "average_loss": -2279.0
  },
  {
    "adx_band": "ADX_46.05-56",
    "number_of_trades": 9,
    "net_profit": -13340.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.40866173145972784,
    "expectancy": -1482.2222222222222,
    "average_win": 4609.5,
    "average_loss": -3759.8333333333335
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.291-2.22",
    "number_of_trades": 9,
    "net_profit": -34244.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3804.8888888888887,
    "average_win": null,
    "average_loss": -3804.8888888888887
  },
  {
    "hold_time_band": "HOLD_H_12.68-104.2",
    "number_of_trades": 10,
    "net_profit": 29759.0,
    "win_rate": 0.6,
    "profit_factor": 4.8245726770338,
    "expectancy": 2975.9,
    "average_win": 6256.666666666667,
    "average_loss": -2593.6666666666665
  },
  {
    "hold_time_band": "HOLD_H_2.22-12.68",
    "number_of_trades": 9,
    "net_profit": 26947.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 3.4570985684325706,
    "expectancy": 2994.1111111111113,
    "average_win": 9478.5,
    "average_loss": -2741.75
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-72-1859",
    "number_of_trades": 9,
    "net_profit": -33564.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3729.3333333333335,
    "average_win": null,
    "average_loss": -3729.3333333333335
  },
  {
    "mfe_band": "MFE_1859-6216",
    "number_of_trades": 9,
    "net_profit": -19352.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.003911879761169446,
    "expectancy": -2150.222222222222,
    "average_win": 76.0,
    "average_loss": -2775.4285714285716
  },
  {
    "mfe_band": "MFE_6216-9915",
    "number_of_trades": 10,
    "net_profit": 75378.0,
    "win_rate": 0.9,
    "profit_factor": null,
    "expectancy": 7537.8,
    "average_win": 8375.333333333334,
    "average_loss": null
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2160--202",
    "number_of_trades": 10,
    "net_profit": 46327.0,
    "win_rate": 0.7,
    "profit_factor": 213.5091743119266,
    "expectancy": 4632.7,
    "average_win": 6649.285714285715,
    "average_loss": -218.0
  },
  {
    "mae_band": "MAE_-3708--2160",
    "number_of_trades": 8,
    "net_profit": 14395.0,
    "win_rate": 0.375,
    "profit_factor": 1.9918010197051124,
    "expectancy": 1799.375,
    "average_win": 9636.333333333334,
    "average_loss": -2902.8
  },
  {
    "mae_band": "MAE_-4095--3708",
    "number_of_trades": 10,
    "net_profit": -38260.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3826.0,
    "average_win": null,
    "average_loss": -3826.0
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 13,
    "net_profit": 24163.0,
    "win_rate": 0.38461538461538464,
    "profit_factor": 2.0593160894344584,
    "expectancy": 1858.6923076923076,
    "average_win": 9394.6,
    "average_loss": -2851.25
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 15,
    "net_profit": -1701.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.943641905771652,
    "expectancy": -113.4,
    "average_win": 5696.2,
    "average_loss": -3772.75
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 1,
    "net_profit": 124.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 124.0,
    "average_win": 124.0,
    "average_loss": null
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 2,
    "net_profit": -7564.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3782.0,
    "average_win": null,
    "average_loss": -3782.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 25,
    "net_profit": 29902.0,
    "win_rate": 0.36,
    "profit_factor": 1.658228405388747,
    "expectancy": 1196.08,
    "average_win": 8370.0,
    "average_loss": -3244.8571428571427
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 14,
    "net_profit": -52770.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3769.285714285714,
    "average_win": null,
    "average_loss": -3769.285714285714
  },
  {
    "close_reason": "SL",
    "number_of_trades": 6,
    "net_profit": -22.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.9009009009009009,
    "expectancy": -3.6666666666666665,
    "average_win": 100.0,
    "average_loss": -111.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 8,
    "net_profit": 75254.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9406.75,
    "average_win": 9406.75,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 11,
    "net_profit": -16645.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.3793810589112602,
    "expectancy": -1513.1818181818182,
    "average_win": 3391.6666666666665,
    "average_loss": -3352.5
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": 22244.0,
    "win_rate": 0.5,
    "profit_factor": 2.5039891818796485,
    "expectancy": 2780.5,
    "average_win": 9258.5,
    "average_loss": -3697.5
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 6,
    "net_profit": 2365.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 1.3164302916778163,
    "expectancy": 394.1666666666667,
    "average_win": 9839.0,
    "average_loss": -2491.3333333333335
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 3,
    "net_profit": 14498.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 4.709825997952917,
    "expectancy": 4832.666666666667,
    "average_win": 9203.0,
    "average_loss": -3908.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 7,
    "net_profit": -18322.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.010797969981643452,
    "expectancy": -2617.4285714285716,
    "average_win": 100.0,
    "average_loss": -3704.4
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 5,
    "net_profit": -15391.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3078.2,
    "average_win": null,
    "average_loss": -3078.2
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": -3735.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1245.0,
    "average_win": null,
    "average_loss": -1867.5
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 7,
    "net_profit": 16386.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.4199306759098786,
    "expectancy": 2340.8571428571427,
    "average_win": 9308.666666666666,
    "average_loss": -3846.6666666666665
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 6,
    "net_profit": 43524.0,
    "win_rate": 0.8333333333333334,
    "profit_factor": 12.441640378548897,
    "expectancy": 7254.0,
    "average_win": 9465.6,
    "average_loss": -3804.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00723-0.985",
    "number_of_trades": 9,
    "net_profit": 75378.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8375.333333333334,
    "average_win": 8375.333333333334,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.985-2.841",
    "number_of_trades": 9,
    "net_profit": -15444.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.004896907216494845,
    "expectancy": -1716.0,
    "average_win": 76.0,
    "average_loss": -2586.6666666666665
  },
  {
    "giveback_band": "GIVEBACK_2.841-288",
    "number_of_trades": 9,
    "net_profit": -33668.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3740.8888888888887,
    "average_win": null,
    "average_loss": -3740.8888888888887
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
