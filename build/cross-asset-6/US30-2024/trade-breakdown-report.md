# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 34
- MFEデータのある負けトレード数: 34
- うち一度含み益になった数: 30
- 割合: 88.24%
- 反転前の平均含み益: 1758.87

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 39
- 平均Giveback比率: 2098.05%
- 中央値Giveback比率: 270.60%
- 損益ゼロ以下まで完全反転した割合: 76.92%

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

- 決済件数: 30
- 純損益: -85749.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -2858.30
- 平均逆行幅（R）: 0.7675
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 30,
    "net_profit": -85749.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2858.3,
    "average_win": null,
    "average_loss": -2858.3
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 5897
- 最終Entry候補まで到達: 62
- Stage別棄却数（market_regime）: 4597
- Stage別棄却数（htf_bias）: 211
- Stage別棄却数（trend_strength_or_momentum_filter）: 683
- Stage別棄却数（setup_or_trigger）: 344
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 4597,
  "RSI_FILTERED": 632,
  "ENTRY_PATTERN_NOT_FOUND": 344,
  "CONFIRMATION_ADX_TOO_LOW": 51,
  "TREND_NOT_ALIGNED": 211
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 43,
    "net_profit": -29430.0,
    "win_rate": 0.20930232558139536,
    "profit_factor": 0.6573883281528307,
    "expectancy": -684.4186046511628,
    "average_win": 6274.333333333333,
    "average_loss": -2526.4411764705883
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 6,
    "net_profit": -12120.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2020.0,
    "average_win": null,
    "average_loss": -2020.0
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 5,
    "net_profit": -1500.0,
    "win_rate": 0.2,
    "profit_factor": 0.8534870091814808,
    "expectancy": -300.0,
    "average_win": 8738.0,
    "average_loss": -2559.5
  },
  {
    "session": "NewYork",
    "number_of_trades": 25,
    "net_profit": -5145.0,
    "win_rate": 0.28,
    "profit_factor": 0.894967847300194,
    "expectancy": -205.8,
    "average_win": 6262.857142857143,
    "average_loss": -2721.3888888888887
  },
  {
    "session": "Tokyo",
    "number_of_trades": 7,
    "net_profit": -10665.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.26731244847485575,
    "expectancy": -1523.5714285714287,
    "average_win": 3891.0,
    "average_loss": -2426.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 10,
    "net_profit": 17793.0,
    "win_rate": 0.4,
    "profit_factor": 2.2859930615784907,
    "expectancy": 1779.3,
    "average_win": 7907.25,
    "average_loss": -2306.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 8,
    "net_profit": -14702.0,
    "win_rate": 0.125,
    "profit_factor": 0.314847609283251,
    "expectancy": -1837.75,
    "average_win": 6756.0,
    "average_loss": -3065.4285714285716
  },
  {
    "weekday": "Thu",
    "number_of_trades": 13,
    "net_profit": -19132.0,
    "win_rate": 0.15384615384615385,
    "profit_factor": 0.2581908417665077,
    "expectancy": -1471.6923076923076,
    "average_win": 3329.5,
    "average_loss": -2344.6363636363635
  },
  {
    "weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": -10767.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3589.0,
    "average_win": null,
    "average_loss": -3589.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 9,
    "net_profit": -2622.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.8133409268883035,
    "expectancy": -291.3333333333333,
    "average_win": 5712.5,
    "average_loss": -2006.7142857142858
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_27.64-59.5",
    "number_of_trades": 14,
    "net_profit": -13120.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5536200326619488,
    "expectancy": -937.1428571428571,
    "average_win": 8136.0,
    "average_loss": -2449.3333333333335
  },
  {
    "atr_band": "ATR_59.5-84.64",
    "number_of_trades": 15,
    "net_profit": 5570.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.1991561784897025,
    "expectancy": 371.3333333333333,
    "average_win": 6707.6,
    "average_loss": -2796.8
  },
  {
    "atr_band": "ATR_84.64-134",
    "number_of_trades": 14,
    "net_profit": -21880.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.23332982935631943,
    "expectancy": -1562.857142857143,
    "average_win": 3329.5,
    "average_loss": -2378.25
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.02-43.75",
    "number_of_trades": 15,
    "net_profit": -17958.0,
    "win_rate": 0.13333333333333333,
    "profit_factor": 0.4463046896679308,
    "expectancy": -1197.2,
    "average_win": 7237.5,
    "average_loss": -2494.846153846154
  },
  {
    "adx_band": "ADX_43.75-51.58",
    "number_of_trades": 14,
    "net_profit": 9687.0,
    "win_rate": 0.35714285714285715,
    "profit_factor": 1.39236097047268,
    "expectancy": 691.9285714285714,
    "average_win": 6875.2,
    "average_loss": -2743.222222222222
  },
  {
    "adx_band": "ADX_51.58-79.57",
    "number_of_trades": 14,
    "net_profit": -21159.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.2647253014560239,
    "expectancy": -1511.357142857143,
    "average_win": 3809.0,
    "average_loss": -2398.0833333333335
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.285-1.728",
    "number_of_trades": 15,
    "net_profit": -26006.0,
    "win_rate": 0.06666666666666667,
    "profit_factor": 0.20621451681826505,
    "expectancy": -1733.7333333333333,
    "average_win": 6756.0,
    "average_loss": -2340.1428571428573
  },
  {
    "hold_time_band": "HOLD_H_1.728-7.164",
    "number_of_trades": 13,
    "net_profit": -17556.0,
    "win_rate": 0.15384615384615385,
    "profit_factor": 0.4810216388790351,
    "expectancy": -1350.4615384615386,
    "average_win": 8136.0,
    "average_loss": -3075.2727272727275
  },
  {
    "hold_time_band": "HOLD_H_7.164-112",
    "number_of_trades": 15,
    "net_profit": 14132.0,
    "win_rate": 0.4,
    "profit_factor": 1.73188668496556,
    "expectancy": 942.1333333333333,
    "average_win": 5573.5,
    "average_loss": -2145.4444444444443
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-142-708",
    "number_of_trades": 14,
    "net_profit": -37080.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2648.5714285714284,
    "average_win": null,
    "average_loss": -2648.5714285714284
  },
  {
    "mfe_band": "MFE_3182-9323",
    "number_of_trades": 15,
    "net_profit": 48890.0,
    "win_rate": 0.6,
    "profit_factor": 7.4507190922285265,
    "expectancy": 3259.3333333333335,
    "average_win": 6274.333333333333,
    "average_loss": -1263.1666666666667
  },
  {
    "mfe_band": "MFE_708-3182",
    "number_of_trades": 14,
    "net_profit": -41240.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2945.714285714286,
    "average_win": null,
    "average_loss": -2945.714285714286
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2114--193",
    "number_of_trades": 14,
    "net_profit": 30266.0,
    "win_rate": 0.5,
    "profit_factor": 4.756485044061065,
    "expectancy": 2161.8571428571427,
    "average_win": 5474.714285714285,
    "average_loss": -1151.0
  },
  {
    "mae_band": "MAE_-2945--2114",
    "number_of_trades": 15,
    "net_profit": -12125.0,
    "win_rate": 0.13333333333333333,
    "profit_factor": 0.5994516203627234,
    "expectancy": -808.3333333333334,
    "average_win": 9073.0,
    "average_loss": -2328.5384615384614
  },
  {
    "mae_band": "MAE_-3880--2945",
    "number_of_trades": 14,
    "net_profit": -47571.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3397.9285714285716,
    "average_win": null,
    "average_loss": -3397.9285714285716
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 13,
    "net_profit": -10572.0,
    "win_rate": 0.15384615384615385,
    "profit_factor": 0.5747727455554662,
    "expectancy": -813.2307692307693,
    "average_win": 7145.0,
    "average_loss": -2260.181818181818
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 30,
    "net_profit": -18858.0,
    "win_rate": 0.23333333333333334,
    "profit_factor": 0.6910398610678768,
    "expectancy": -628.6,
    "average_win": 6025.571428571428,
    "average_loss": -2653.782608695652
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 9,
    "net_profit": -5825.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.621335240200221,
    "expectancy": -647.2222222222222,
    "average_win": 3186.0,
    "average_loss": -2563.8333333333335
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 8,
    "net_profit": 9778.0,
    "win_rate": 0.375,
    "profit_factor": 1.7379622641509433,
    "expectancy": 1222.25,
    "average_win": 7676.0,
    "average_loss": -2650.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 26,
    "net_profit": -33383.0,
    "win_rate": 0.11538461538461539,
    "profit_factor": 0.4170537491705375,
    "expectancy": -1283.9615384615386,
    "average_win": 7961.0,
    "average_loss": -2489.8260869565215
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 32,
    "net_profit": -80996.0,
    "win_rate": 0.0625,
    "profit_factor": 0.05542921783344412,
    "expectancy": -2531.125,
    "average_win": 2376.5,
    "average_loss": -2858.3
  },
  {
    "close_reason": "SL",
    "number_of_trades": 4,
    "net_profit": -150.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -37.5,
    "average_win": null,
    "average_loss": -37.5
  },
  {
    "close_reason": "TP",
    "number_of_trades": 7,
    "net_profit": 51716.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7388.0,
    "average_win": 7388.0,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 3,
    "net_profit": -8216.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2738.6666666666665,
    "average_win": null,
    "average_loss": -2738.6666666666665
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 18,
    "net_profit": -4075.0,
    "win_rate": 0.2777777777777778,
    "profit_factor": 0.868755837547103,
    "expectancy": -226.38888888888889,
    "average_win": 5394.8,
    "average_loss": -2388.3846153846152
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 18,
    "net_profit": -16142.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.5544453338485743,
    "expectancy": -896.7777777777778,
    "average_win": 6695.666666666667,
    "average_loss": -2415.266666666667
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 4,
    "net_profit": -997.0,
    "win_rate": 0.25,
    "profit_factor": 0.904180682364248,
    "expectancy": -249.25,
    "average_win": 9408.0,
    "average_loss": -3468.3333333333335
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 11,
    "net_profit": -5195.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.7366953877344146,
    "expectancy": -472.27272727272725,
    "average_win": 7267.5,
    "average_loss": -2192.222222222222
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 11,
    "net_profit": 18298.0,
    "win_rate": 0.5454545454545454,
    "profit_factor": 2.136380573841759,
    "expectancy": 1663.4545454545455,
    "average_win": 5733.333333333333,
    "average_loss": -3220.4
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 9,
    "net_profit": -19909.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2212.1111111111113,
    "average_win": null,
    "average_loss": -2212.1111111111113
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 5,
    "net_profit": -16123.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3224.6,
    "average_win": null,
    "average_loss": -3224.6
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 7,
    "net_profit": -6501.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5368008550053438,
    "expectancy": -928.7142857142857,
    "average_win": 7534.0,
    "average_loss": -2339.1666666666665
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0112-1.552",
    "number_of_trades": 13,
    "net_profit": 56319.0,
    "win_rate": 0.6923076923076923,
    "profit_factor": 376.46,
    "expectancy": 4332.2307692307695,
    "average_win": 6274.333333333333,
    "average_loss": -37.5
  },
  {
    "giveback_band": "GIVEBACK_1.552-4.926",
    "number_of_trades": 13,
    "net_profit": -38685.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2975.769230769231,
    "average_win": null,
    "average_loss": -2975.769230769231
  },
  {
    "giveback_band": "GIVEBACK_4.926-487",
    "number_of_trades": 13,
    "net_profit": -36323.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2794.076923076923,
    "average_win": null,
    "average_loss": -2794.076923076923
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
