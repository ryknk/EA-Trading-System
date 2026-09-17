# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 38
- MFEデータのある負けトレード数: 38
- うち一度含み益になった数: 34
- 割合: 89.47%
- 反転前の平均含み益: 2275.47

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 49
- 平均Giveback比率: 1362.78%
- 中央値Giveback比率: 203.15%
- 損益ゼロ以下まで完全反転した割合: 71.43%

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

- 決済件数: 26
- 純損益: -91048.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3501.85
- 平均逆行幅（R）: 0.7622
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 21,
    "net_profit": -73000.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3476.190476190476,
    "average_win": null,
    "average_loss": -3476.190476190476
  },
  "SELL": {
    "number_of_trades": 5,
    "net_profit": -18048.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3609.6,
    "average_win": null,
    "average_loss": -3609.6
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 10488
- 最終Entry候補まで到達: 107
- Stage別棄却数（market_regime）: 8825
- Stage別棄却数（htf_bias）: 240
- Stage別棄却数（trend_strength_or_momentum_filter）: 755
- Stage別棄却数（setup_or_trigger）: 561
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 8825,
  "CONFIRMATION_ADX_TOO_LOW": 119,
  "RSI_FILTERED": 636,
  "ENTRY_PATTERN_NOT_FOUND": 561,
  "TREND_NOT_ALIGNED": 240
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 47,
    "net_profit": -13446.0,
    "win_rate": 0.2765957446808511,
    "profit_factor": 0.8658927021932318,
    "expectancy": -286.0851063829787,
    "average_win": 6678.2307692307695,
    "average_loss": -3038.2727272727275
  },
  {
    "direction": "SELL",
    "number_of_trades": 6,
    "net_profit": -8456.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.5314716312056738,
    "expectancy": -1409.3333333333333,
    "average_win": 9592.0,
    "average_loss": -3609.6
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 7,
    "net_profit": 18415.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 3.4754671326791233,
    "expectancy": 2630.714285714286,
    "average_win": 8618.0,
    "average_loss": -2479.6666666666665
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 18,
    "net_profit": -16527.0,
    "win_rate": 0.2777777777777778,
    "profit_factor": 0.607397377423033,
    "expectancy": -918.1666666666666,
    "average_win": 5113.8,
    "average_loss": -3238.153846153846
  },
  {
    "session": "NewYork",
    "number_of_trades": 15,
    "net_profit": -33449.0,
    "win_rate": 0.13333333333333333,
    "profit_factor": 0.21248293073409616,
    "expectancy": -2229.9333333333334,
    "average_win": 4512.5,
    "average_loss": -3267.230769230769
  },
  {
    "session": "Tokyo",
    "number_of_trades": 13,
    "net_profit": 9659.0,
    "win_rate": 0.3076923076923077,
    "profit_factor": 1.367234430841761,
    "expectancy": 743.0,
    "average_win": 8990.25,
    "average_loss": -2922.4444444444443
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 8,
    "net_profit": -12568.0,
    "win_rate": 0.125,
    "profit_factor": 0.18065062911532695,
    "expectancy": -1571.0,
    "average_win": 2771.0,
    "average_loss": -2191.285714285714
  },
  {
    "weekday": "Mon",
    "number_of_trades": 12,
    "net_profit": 16952.0,
    "win_rate": 0.4166666666666667,
    "profit_factor": 1.8359798796725515,
    "expectancy": 1412.6666666666667,
    "average_win": 7446.0,
    "average_loss": -2896.8571428571427
  },
  {
    "weekday": "Thu",
    "number_of_trades": 10,
    "net_profit": 4661.0,
    "win_rate": 0.3,
    "profit_factor": 1.20678793256433,
    "expectancy": 466.1,
    "average_win": 9067.0,
    "average_loss": -3220.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 16,
    "net_profit": -24981.0,
    "win_rate": 0.1875,
    "profit_factor": 0.41089494163424123,
    "expectancy": -1561.3125,
    "average_win": 5808.0,
    "average_loss": -3533.75
  },
  {
    "weekday": "Wed",
    "number_of_trades": 7,
    "net_profit": -5966.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.6638683869513775,
    "expectancy": -852.2857142857143,
    "average_win": 5891.5,
    "average_loss": -3549.8
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.148-0.253",
    "number_of_trades": 18,
    "net_profit": 11798.0,
    "win_rate": 0.3888888888888889,
    "profit_factor": 1.2942658319407379,
    "expectancy": 655.4444444444445,
    "average_win": 7413.0,
    "average_loss": -4009.3
  },
  {
    "atr_band": "ATR_0.253-0.308",
    "number_of_trades": 17,
    "net_profit": -4092.0,
    "win_rate": 0.23529411764705882,
    "profit_factor": 0.8814806232983838,
    "expectancy": -240.7058823529412,
    "average_win": 7608.5,
    "average_loss": -2655.846153846154
  },
  {
    "atr_band": "ATR_0.308-0.464",
    "number_of_trades": 18,
    "net_profit": -29608.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.3223473404742287,
    "expectancy": -1644.888888888889,
    "average_win": 4694.666666666667,
    "average_loss": -2912.8
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.18-42.44",
    "number_of_trades": 18,
    "net_profit": 7365.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2186822649128537,
    "expectancy": 409.1666666666667,
    "average_win": 6840.666666666667,
    "average_loss": -2806.5833333333335
  },
  {
    "adx_band": "ADX_42.44-45.96",
    "number_of_trades": 17,
    "net_profit": -25100.0,
    "win_rate": 0.17647058823529413,
    "profit_factor": 0.41287923089518375,
    "expectancy": -1476.4705882352941,
    "average_win": 5883.666666666667,
    "average_loss": -3288.5384615384614
  },
  {
    "adx_band": "ADX_45.96-67.96",
    "number_of_trades": 18,
    "net_profit": -4167.0,
    "win_rate": 0.2777777777777778,
    "profit_factor": 0.9005038084095414,
    "expectancy": -231.5,
    "average_win": 7542.8,
    "average_loss": -3221.6153846153848
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.155-5.924",
    "number_of_trades": 18,
    "net_profit": -46092.0,
    "win_rate": 0.05555555555555555,
    "profit_factor": 0.1579524279294092,
    "expectancy": -2560.6666666666665,
    "average_win": 8646.0,
    "average_loss": -3421.125
  },
  {
    "hold_time_band": "HOLD_H_15.18-76.35",
    "number_of_trades": 18,
    "net_profit": 37601.0,
    "win_rate": 0.5,
    "profit_factor": 2.8533615930599368,
    "expectancy": 2088.9444444444443,
    "average_win": 6432.111111111111,
    "average_loss": -2254.222222222222
  },
  {
    "hold_time_band": "HOLD_H_5.924-15.18",
    "number_of_trades": 17,
    "net_profit": -13411.0,
    "win_rate": 0.23529411764705882,
    "profit_factor": 0.6901698047822571,
    "expectancy": -788.8823529411765,
    "average_win": 7468.5,
    "average_loss": -3329.6153846153848
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-120-1544",
    "number_of_trades": 18,
    "net_profit": -67911.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3772.8333333333335,
    "average_win": null,
    "average_loss": -3772.8333333333335
  },
  {
    "mfe_band": "MFE_1544-4611",
    "number_of_trades": 17,
    "net_profit": -43530.0,
    "win_rate": 0.11764705882352941,
    "profit_factor": 0.11864749949382467,
    "expectancy": -2560.5882352941176,
    "average_win": 2930.0,
    "average_loss": -3292.6666666666665
  },
  {
    "mfe_band": "MFE_4611-9536",
    "number_of_trades": 18,
    "net_profit": 89539.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 89.65247524752475,
    "expectancy": 4974.388888888889,
    "average_win": 7545.75,
    "average_loss": -202.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2671--444",
    "number_of_trades": 18,
    "net_profit": 74112.0,
    "win_rate": 0.6111111111111112,
    "profit_factor": 30.479713603818617,
    "expectancy": 4117.333333333333,
    "average_win": 6966.0,
    "average_loss": -419.0
  },
  {
    "mae_band": "MAE_-3539--2671",
    "number_of_trades": 17,
    "net_profit": -33745.0,
    "win_rate": 0.11764705882352941,
    "profit_factor": 0.33516559292314363,
    "expectancy": -1985.0,
    "average_win": 8506.0,
    "average_loss": -3383.8
  },
  {
    "mae_band": "MAE_-7669--3539",
    "number_of_trades": 18,
    "net_profit": -62269.0,
    "win_rate": 0.05555555555555555,
    "profit_factor": 0.042604551045510454,
    "expectancy": -3459.3888888888887,
    "average_win": 2771.0,
    "average_loss": -3825.8823529411766
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 12,
    "net_profit": 4037.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.1541722360129845,
    "expectancy": 336.4166666666667,
    "average_win": 7555.5,
    "average_loss": -3740.714285714286
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 41,
    "net_profit": -25939.0,
    "win_rate": 0.24390243902439024,
    "profit_factor": 0.7184399626598355,
    "expectancy": -632.6585365853658,
    "average_win": 6618.7,
    "average_loss": -2971.8064516129034
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 5,
    "net_profit": -2658.0,
    "win_rate": 0.2,
    "profit_factor": 0.7753929356092615,
    "expectancy": -531.6,
    "average_win": 9176.0,
    "average_loss": -2958.5
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 4,
    "net_profit": 26008.0,
    "win_rate": 0.75,
    "profit_factor": null,
    "expectancy": 6502.0,
    "average_win": 8669.333333333334,
    "average_loss": null
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 44,
    "net_profit": -45252.0,
    "win_rate": 0.22727272727272727,
    "profit_factor": 0.5750068089822216,
    "expectancy": -1028.4545454545455,
    "average_win": 6122.5,
    "average_loss": -3131.676470588235
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 31,
    "net_profit": -84399.0,
    "win_rate": 0.0967741935483871,
    "profit_factor": 0.08816983578219534,
    "expectancy": -2722.548387096774,
    "average_win": 2720.3333333333335,
    "average_loss": -3305.714285714286
  },
  {
    "close_reason": "SL",
    "number_of_trades": 12,
    "net_profit": -25689.0,
    "win_rate": 0.08333333333333333,
    "profit_factor": 0.002407673488408217,
    "expectancy": -2140.75,
    "average_win": 62.0,
    "average_loss": -2575.1
  },
  {
    "close_reason": "TP",
    "number_of_trades": 10,
    "net_profit": 88186.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8818.6,
    "average_win": 8818.6,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 14,
    "net_profit": -870.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.9688373092628412,
    "expectancy": -62.142857142857146,
    "average_win": 6762.0,
    "average_loss": -3102.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 10,
    "net_profit": 19923.0,
    "win_rate": 0.4,
    "profit_factor": 2.337742563620493,
    "expectancy": 1992.3,
    "average_win": 8704.0,
    "average_loss": -2482.1666666666665
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 11,
    "net_profit": -22327.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.2912738469352125,
    "expectancy": -2029.7272727272727,
    "average_win": 9176.0,
    "average_loss": -3150.3
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 18,
    "net_profit": -18628.0,
    "win_rate": 0.2777777777777778,
    "profit_factor": 0.576607495965634,
    "expectancy": -1034.888888888889,
    "average_win": 5073.8,
    "average_loss": -3384.3846153846152
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 9,
    "net_profit": -14327.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.38484328037784454,
    "expectancy": -1591.888888888889,
    "average_win": 8963.0,
    "average_loss": -2911.25
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 8,
    "net_profit": -3365.0,
    "win_rate": 0.25,
    "profit_factor": 0.7802377220480669,
    "expectancy": -420.625,
    "average_win": 5973.5,
    "average_loss": -2552.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 10,
    "net_profit": -2843.0,
    "win_rate": 0.3,
    "profit_factor": 0.8823748448489863,
    "expectancy": -284.3,
    "average_win": 7109.0,
    "average_loss": -3452.8571428571427
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 14,
    "net_profit": -1031.0,
    "win_rate": 0.21428571428571427,
    "profit_factor": 0.9615068697729988,
    "expectancy": -73.64285714285714,
    "average_win": 8584.333333333334,
    "average_loss": -2678.4
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 12,
    "net_profit": -336.0,
    "win_rate": 0.4166666666666667,
    "profit_factor": 0.9883150756390193,
    "expectancy": -28.0,
    "average_win": 5683.8,
    "average_loss": -4107.857142857143
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0165-1.002",
    "number_of_trades": 17,
    "net_profit": 96395.0,
    "win_rate": 0.8235294117647058,
    "profit_factor": 6886.357142857143,
    "expectancy": 5670.294117647059,
    "average_win": 6886.357142857143,
    "average_loss": -7.0
  },
  {
    "giveback_band": "GIVEBACK_1.002-3.007",
    "number_of_trades": 15,
    "net_profit": -38186.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2545.733333333333,
    "average_win": null,
    "average_loss": -2545.733333333333
  },
  {
    "giveback_band": "GIVEBACK_3.007-350",
    "number_of_trades": 17,
    "net_profit": -65122.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3830.705882352941,
    "average_win": null,
    "average_loss": -3830.705882352941
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
