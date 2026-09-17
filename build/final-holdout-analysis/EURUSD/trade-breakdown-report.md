# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 24
- MFEデータのある負けトレード数: 24
- うち一度含み益になった数: 23
- 割合: 95.83%
- 反転前の平均含み益: 2064.26

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 42
- 平均Giveback比率: 332.27%
- 中央値Giveback比率: 149.31%
- 損益ゼロ以下まで完全反転した割合: 69.05%

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

- 決済件数: 20
- 純損益: -76063.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3803.15
- 平均逆行幅（R）: 0.7604
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 14,
    "net_profit": -52926.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3780.4285714285716,
    "average_win": null,
    "average_loss": -3780.4285714285716
  },
  "SELL": {
    "number_of_trades": 6,
    "net_profit": -23137.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3856.1666666666665,
    "average_win": null,
    "average_loss": -3856.1666666666665
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 10497
- 最終Entry候補まで到達: 77
- Stage別棄却数（market_regime）: 8986
- Stage別棄却数（htf_bias）: 256
- Stage別棄却数（trend_strength_or_momentum_filter）: 699
- Stage別棄却数（setup_or_trigger）: 479
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 8986,
  "RSI_FILTERED": 629,
  "ENTRY_PATTERN_NOT_FOUND": 479,
  "CONFIRMATION_ADX_TOO_LOW": 70,
  "TREND_NOT_ALIGNED": 256
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 35,
    "net_profit": 46301.0,
    "win_rate": 0.34285714285714286,
    "profit_factor": 1.7473327415059317,
    "expectancy": 1322.8857142857144,
    "average_win": 9021.333333333334,
    "average_loss": -3441.9444444444443
  },
  {
    "direction": "SELL",
    "number_of_trades": 8,
    "net_profit": -13313.0,
    "win_rate": 0.125,
    "profit_factor": 0.4246012879802913,
    "expectancy": -1664.125,
    "average_win": 9824.0,
    "average_loss": -3856.1666666666665
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 11,
    "net_profit": 21734.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 2.1424516400336415,
    "expectancy": 1975.8181818181818,
    "average_win": 10189.5,
    "average_loss": -3170.6666666666665
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": -7173.0,
    "win_rate": 0.25,
    "profit_factor": 0.7282954545454545,
    "expectancy": -896.625,
    "average_win": 9613.5,
    "average_loss": -4400.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 8,
    "net_profit": 16007.0,
    "win_rate": 0.375,
    "profit_factor": 2.254958839670717,
    "expectancy": 2000.875,
    "average_win": 9587.333333333334,
    "average_loss": -2551.0
  },
  {
    "session": "Tokyo",
    "number_of_trades": 16,
    "net_profit": 2420.0,
    "win_rate": 0.25,
    "profit_factor": 1.089919369821276,
    "expectancy": 151.25,
    "average_win": 7333.25,
    "average_loss": -3844.714285714286
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 12,
    "net_profit": -12811.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.6224841608958303,
    "expectancy": -1067.5833333333333,
    "average_win": 10562.0,
    "average_loss": -3770.5555555555557
  },
  {
    "weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": 12047.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.527256592292089,
    "expectancy": 1721.0,
    "average_win": 6645.0,
    "average_loss": -3944.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 8,
    "net_profit": 31349.0,
    "win_rate": 0.5,
    "profit_factor": 5.126497301566408,
    "expectancy": 3918.625,
    "average_win": 9736.5,
    "average_loss": -3798.5
  },
  {
    "weekday": "Tue",
    "number_of_trades": 10,
    "net_profit": -1586.0,
    "win_rate": 0.2,
    "profit_factor": 0.9223728647643287,
    "expectancy": -158.6,
    "average_win": 9422.5,
    "average_loss": -2918.714285714286
  },
  {
    "weekday": "Wed",
    "number_of_trades": 6,
    "net_profit": 3989.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2617282330555737,
    "expectancy": 664.8333333333334,
    "average_win": 9615.0,
    "average_loss": -3810.25
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_-0.000286-0.00105",
    "number_of_trades": 15,
    "net_profit": -25258.0,
    "win_rate": 0.13333333333333333,
    "profit_factor": 0.4520803505575079,
    "expectancy": -1683.8666666666666,
    "average_win": 10420.0,
    "average_loss": -4190.727272727273
  },
  {
    "atr_band": "ATR_0.00105-0.00145",
    "number_of_trades": 14,
    "net_profit": 34988.0,
    "win_rate": 0.35714285714285715,
    "profit_factor": 3.603080127966669,
    "expectancy": 2499.1428571428573,
    "average_win": 9685.8,
    "average_loss": -2688.2
  },
  {
    "atr_band": "ATR_0.00145-0.00334",
    "number_of_trades": 14,
    "net_profit": 23258.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.9101866708409971,
    "expectancy": 1661.2857142857142,
    "average_win": 8135.166666666667,
    "average_loss": -3194.125
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.01-42.12",
    "number_of_trades": 15,
    "net_profit": 39417.0,
    "win_rate": 0.4666666666666667,
    "profit_factor": 2.3770612073784236,
    "expectancy": 2627.8,
    "average_win": 9720.142857142857,
    "average_loss": -3578.0
  },
  {
    "adx_band": "ADX_42.12-45.38",
    "number_of_trades": 13,
    "net_profit": -767.0,
    "win_rate": 0.23076923076923078,
    "profit_factor": 0.9653740237461063,
    "expectancy": -59.0,
    "average_win": 7128.0,
    "average_loss": -3164.4285714285716
  },
  {
    "adx_band": "ADX_45.38-68.72",
    "number_of_trades": 15,
    "net_profit": -5662.0,
    "win_rate": 0.2,
    "profit_factor": 0.8350088877232859,
    "expectancy": -377.46666666666664,
    "average_win": 9551.666666666666,
    "average_loss": -3813.0
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.463-3.5",
    "number_of_trades": 14,
    "net_profit": -12166.0,
    "win_rate": 0.21428571428571427,
    "profit_factor": 0.7048305310915399,
    "expectancy": -869.0,
    "average_win": 9683.666666666666,
    "average_loss": -3747.0
  },
  {
    "hold_time_band": "HOLD_H_11-87.46",
    "number_of_trades": 14,
    "net_profit": 23224.0,
    "win_rate": 0.35714285714285715,
    "profit_factor": 2.487954894925679,
    "expectancy": 1658.857142857143,
    "average_win": 7766.4,
    "average_loss": -3121.6
  },
  {
    "hold_time_band": "HOLD_H_3.5-11",
    "number_of_trades": 15,
    "net_profit": 21930.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.7758163229207202,
    "expectancy": 1462.0,
    "average_win": 10039.4,
    "average_loss": -3533.375
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-50-1890",
    "number_of_trades": 14,
    "net_profit": -49991.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3570.785714285714,
    "average_win": null,
    "average_loss": -3570.785714285714
  },
  {
    "mfe_band": "MFE_1890-6821",
    "number_of_trades": 15,
    "net_profit": -33943.0,
    "win_rate": 0.06666666666666667,
    "profit_factor": 0.032990513090795134,
    "expectancy": -2262.866666666667,
    "average_win": 1158.0,
    "average_loss": -3510.1
  },
  {
    "mfe_band": "MFE_6821-1.001e+04",
    "number_of_trades": 14,
    "net_profit": 116922.0,
    "win_rate": 0.8571428571428571,
    "profit_factor": null,
    "expectancy": 8351.57142857143,
    "average_win": 9743.5,
    "average_loss": null
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1774--123",
    "number_of_trades": 15,
    "net_profit": 95611.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 59.441931540342296,
    "expectancy": 6374.066666666667,
    "average_win": 9724.7,
    "average_loss": -545.3333333333334
  },
  {
    "mae_band": "MAE_-3793--1774",
    "number_of_trades": 13,
    "net_profit": -662.0,
    "win_rate": 0.23076923076923078,
    "profit_factor": 0.9692021400325657,
    "expectancy": -50.92307692307692,
    "average_win": 6944.333333333333,
    "average_loss": -3582.5
  },
  {
    "mae_band": "MAE_-8418--3793",
    "number_of_trades": 15,
    "net_profit": -61961.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4130.733333333334,
    "average_win": null,
    "average_loss": -4130.733333333334
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 9,
    "net_profit": -18851.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.3378644186863365,
    "expectancy": -2094.5555555555557,
    "average_win": 9619.0,
    "average_loss": -3558.75
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 34,
    "net_profit": 51839.0,
    "win_rate": 0.35294117647058826,
    "profit_factor": 1.9155275334675568,
    "expectancy": 1524.6764705882354,
    "average_win": 9038.416666666666,
    "average_loss": -3538.875
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 4,
    "net_profit": 16323.0,
    "win_rate": 0.5,
    "profit_factor": 5.77280701754386,
    "expectancy": 4080.75,
    "average_win": 9871.5,
    "average_loss": -1710.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 6,
    "net_profit": -1232.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.891358024691358,
    "expectancy": -205.33333333333334,
    "average_win": 10108.0,
    "average_loss": -3780.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 33,
    "net_profit": 17897.0,
    "win_rate": 0.30303030303030304,
    "profit_factor": 1.2544645396121255,
    "expectancy": 542.3333333333334,
    "average_win": 8822.9,
    "average_loss": -3701.684210526316
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 22,
    "net_profit": -76282.0,
    "win_rate": 0.045454545454545456,
    "profit_factor": 0.014953512396694214,
    "expectancy": -3467.3636363636365,
    "average_win": 1158.0,
    "average_loss": -3687.6190476190477
  },
  {
    "close_reason": "SL",
    "number_of_trades": 9,
    "net_profit": -7652.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -850.2222222222222,
    "average_win": null,
    "average_loss": -2550.6666666666665
  },
  {
    "close_reason": "TP",
    "number_of_trades": 12,
    "net_profit": 116922.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9743.5,
    "average_win": 9743.5,
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
    "net_profit": 2259.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.0643113363320618,
    "expectancy": 161.35714285714286,
    "average_win": 9346.25,
    "average_loss": -3512.6
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 12,
    "net_profit": 22952.0,
    "win_rate": 0.4166666666666667,
    "profit_factor": 2.210293187091331,
    "expectancy": 1912.6666666666667,
    "average_win": 8383.2,
    "average_loss": -3792.8
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 12,
    "net_profit": 20121.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.0784114052953155,
    "expectancy": 1676.75,
    "average_win": 9694.75,
    "average_loss": -3731.6
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 5,
    "net_profit": -12344.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2468.8,
    "average_win": null,
    "average_loss": -3086.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 10,
    "net_profit": 8331.0,
    "win_rate": 0.3,
    "profit_factor": 1.371720506871319,
    "expectancy": 833.1,
    "average_win": 10247.666666666666,
    "average_loss": -3735.3333333333335
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": -4604.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.6996542501141627,
    "expectancy": -657.7142857142857,
    "average_win": 5362.5,
    "average_loss": -5109.666666666667
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 8,
    "net_profit": 31349.0,
    "win_rate": 0.5,
    "profit_factor": 5.126497301566408,
    "expectancy": 3918.625,
    "average_win": 9736.5,
    "average_loss": -3798.5
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 8,
    "net_profit": -10352.0,
    "win_rate": 0.125,
    "profit_factor": 0.4708107555464676,
    "expectancy": -1294.0,
    "average_win": 9210.0,
    "average_loss": -3260.3333333333335
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 10,
    "net_profit": 8264.0,
    "win_rate": 0.3,
    "profit_factor": 1.4092709984152139,
    "expectancy": 826.4,
    "average_win": 9485.333333333334,
    "average_loss": -2884.5714285714284
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.185-1",
    "number_of_trades": 19,
    "net_profit": 118080.0,
    "win_rate": 0.6842105263157895,
    "profit_factor": null,
    "expectancy": 6214.736842105263,
    "average_win": 9083.076923076924,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1-2.762",
    "number_of_trades": 9,
    "net_profit": -28584.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3176.0,
    "average_win": null,
    "average_loss": -3176.0
  },
  {
    "giveback_band": "GIVEBACK_2.762-25.64",
    "number_of_trades": 14,
    "net_profit": -52515.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3751.0714285714284,
    "average_win": null,
    "average_loss": -3751.0714285714284
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
