# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 48
- MFEデータのある負けトレード数: 48
- うち一度含み益になった数: 46
- 割合: 95.83%
- 反転前の平均含み益: 2428.28

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 65
- 平均Giveback比率: 858.13%
- 中央値Giveback比率: 179.75%
- 損益ゼロ以下まで完全反転した割合: 75.38%

## Time Stop（時間切れ決済）

- Time Stopによる決済件数: 1
- 純損益: 310.00
- プロフィットファクター: 算出不能
- 勝率: 100.00%
- 期待値: 310.00

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

- 決済件数: 35
- 純損益: -107091.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3059.74
- 平均逆行幅（R）: 0.7698
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 28,
    "net_profit": -87601.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3128.6071428571427,
    "average_win": null,
    "average_loss": -3128.6071428571427
  },
  "SELL": {
    "number_of_trades": 7,
    "net_profit": -19490.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2784.285714285714,
    "average_win": null,
    "average_loss": -2784.285714285714
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 9781
- 最終Entry候補まで到達: 131
- Stage別棄却数（market_regime）: 7653
- Stage別棄却数（htf_bias）: 313
- Stage別棄却数（trend_strength_or_momentum_filter）: 905
- Stage別棄却数（setup_or_trigger）: 779
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 7653,
  "ENTRY_PATTERN_NOT_FOUND": 779,
  "RSI_FILTERED": 808,
  "TREND_NOT_ALIGNED": 313,
  "CONFIRMATION_ADX_TOO_LOW": 97
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 57,
    "net_profit": -10573.0,
    "win_rate": 0.24561403508771928,
    "profit_factor": 0.8809588146546871,
    "expectancy": -185.49122807017545,
    "average_win": 5588.928571428572,
    "average_loss": -2220.45
  },
  {
    "direction": "SELL",
    "number_of_trades": 10,
    "net_profit": -10408.0,
    "win_rate": 0.2,
    "profit_factor": 0.4662016617088932,
    "expectancy": -1040.8,
    "average_win": 4545.0,
    "average_loss": -2437.25
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 18,
    "net_profit": -4878.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.8207144957365481,
    "expectancy": -271.0,
    "average_win": 5582.5,
    "average_loss": -2092.923076923077
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 14,
    "net_profit": -1036.0,
    "win_rate": 0.21428571428571427,
    "profit_factor": 0.9624610479020219,
    "expectancy": -74.0,
    "average_win": 8854.0,
    "average_loss": -2759.8
  },
  {
    "session": "NewYork",
    "number_of_trades": 19,
    "net_profit": -20133.0,
    "win_rate": 0.15789473684210525,
    "profit_factor": 0.4605739088497709,
    "expectancy": -1059.6315789473683,
    "average_win": 5730.0,
    "average_loss": -2488.2
  },
  {
    "session": "Tokyo",
    "number_of_trades": 16,
    "net_profit": 5066.0,
    "win_rate": 0.375,
    "profit_factor": 1.3129671958979428,
    "expectancy": 316.625,
    "average_win": 3542.1666666666665,
    "average_loss": -1618.7
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 9,
    "net_profit": -2086.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.8853846153846154,
    "expectancy": -231.77777777777777,
    "average_win": 5371.333333333333,
    "average_loss": -3033.3333333333335
  },
  {
    "weekday": "Mon",
    "number_of_trades": 23,
    "net_profit": 5776.0,
    "win_rate": 0.2608695652173913,
    "profit_factor": 1.1796466782781787,
    "expectancy": 251.1304347826087,
    "average_win": 6321.333333333333,
    "average_loss": -2143.4666666666667
  },
  {
    "weekday": "Thu",
    "number_of_trades": 7,
    "net_profit": -6795.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.36083153042987487,
    "expectancy": -970.7142857142857,
    "average_win": 1918.0,
    "average_loss": -2126.2
  },
  {
    "weekday": "Tue",
    "number_of_trades": 11,
    "net_profit": 5581.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 1.3452734471665428,
    "expectancy": 507.3636363636364,
    "average_win": 7248.333333333333,
    "average_loss": -2020.5
  },
  {
    "weekday": "Wed",
    "number_of_trades": 17,
    "net_profit": -23457.0,
    "win_rate": 0.11764705882352941,
    "profit_factor": 0.24742532644614842,
    "expectancy": -1379.8235294117646,
    "average_win": 3856.0,
    "average_loss": -2226.3571428571427
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_23.3-52.02",
    "number_of_trades": 23,
    "net_profit": -3152.0,
    "win_rate": 0.2608695652173913,
    "profit_factor": 0.9294428401943008,
    "expectancy": -137.04347826086956,
    "average_win": 6920.166666666667,
    "average_loss": -2792.0625
  },
  {
    "atr_band": "ATR_52.02-82.58",
    "number_of_trades": 21,
    "net_profit": -9101.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.7358123603007344,
    "expectancy": -433.3809523809524,
    "average_win": 8449.333333333334,
    "average_loss": -2026.4117647058824
  },
  {
    "atr_band": "ATR_82.58-150.9",
    "number_of_trades": 23,
    "net_profit": -8728.0,
    "win_rate": 0.30434782608695654,
    "profit_factor": 0.7010344591354388,
    "expectancy": -379.4782608695652,
    "average_win": 2923.714285714286,
    "average_loss": -1946.2666666666667
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.05-42.38",
    "number_of_trades": 23,
    "net_profit": -15832.0,
    "win_rate": 0.30434782608695654,
    "profit_factor": 0.5575799916165991,
    "expectancy": -688.3478260869565,
    "average_win": 2850.4285714285716,
    "average_loss": -2385.6666666666665
  },
  {
    "adx_band": "ADX_42.38-45.79",
    "number_of_trades": 22,
    "net_profit": -18960.0,
    "win_rate": 0.13636363636363635,
    "profit_factor": 0.4864154725465233,
    "expectancy": -861.8181818181819,
    "average_win": 5985.666666666667,
    "average_loss": -2050.9444444444443
  },
  {
    "adx_band": "ADX_45.79-73.25",
    "number_of_trades": 22,
    "net_profit": 13811.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 1.3877969337900826,
    "expectancy": 627.7727272727273,
    "average_win": 8237.5,
    "average_loss": -2374.266666666667
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.273-4.105",
    "number_of_trades": 22,
    "net_profit": -35840.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.3082683548212769,
    "expectancy": -1629.090909090909,
    "average_win": 7986.0,
    "average_loss": -2726.9473684210525
  },
  {
    "hold_time_band": "HOLD_H_12.4-75",
    "number_of_trades": 22,
    "net_profit": 13025.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 1.8668885191347753,
    "expectancy": 592.0454545454545,
    "average_win": 3506.25,
    "average_loss": -1155.7692307692307
  },
  {
    "hold_time_band": "HOLD_H_4.105-12.4",
    "number_of_trades": 23,
    "net_profit": 1834.0,
    "win_rate": 0.2608695652173913,
    "profit_factor": 1.0442151450131392,
    "expectancy": 79.73913043478261,
    "average_win": 7218.833333333333,
    "average_loss": -2592.4375
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-100-1515",
    "number_of_trades": 23,
    "net_profit": -67973.0,
    "win_rate": 0.043478260869565216,
    "profit_factor": 0.004539929411420119,
    "expectancy": -2955.3478260869565,
    "average_win": 310.0,
    "average_loss": -3103.7727272727275
  },
  {
    "mfe_band": "MFE_1515-4238",
    "number_of_trades": 22,
    "net_profit": -31722.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.12599531615925058,
    "expectancy": -1441.909090909091,
    "average_win": 1143.25,
    "average_loss": -2135.0
  },
  {
    "mfe_band": "MFE_4238-9025",
    "number_of_trades": 22,
    "net_profit": 78714.0,
    "win_rate": 0.5,
    "profit_factor": 22.057784911717494,
    "expectancy": 3577.909090909091,
    "average_win": 7495.636363636364,
    "average_loss": -415.3333333333333
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1685--151",
    "number_of_trades": 22,
    "net_profit": 59826.0,
    "win_rate": 0.5,
    "profit_factor": 788.1842105263158,
    "expectancy": 2719.3636363636365,
    "average_win": 5445.636363636364,
    "average_loss": -8.444444444444445
  },
  {
    "mae_band": "MAE_-2898--1685",
    "number_of_trades": 22,
    "net_profit": -3342.0,
    "win_rate": 0.22727272727272727,
    "profit_factor": 0.8914053614947197,
    "expectancy": -151.9090909090909,
    "average_win": 5486.6,
    "average_loss": -1923.4375
  },
  {
    "mae_band": "MAE_-3771--2898",
    "number_of_trades": 23,
    "net_profit": -77465.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3368.0434782608695,
    "average_win": null,
    "average_loss": -3368.0434782608695
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 16,
    "net_profit": -5235.0,
    "win_rate": 0.25,
    "profit_factor": 0.780300486822226,
    "expectancy": -327.1875,
    "average_win": 4648.25,
    "average_loss": -2166.181818181818
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 51,
    "net_profit": -15746.0,
    "win_rate": 0.23529411764705882,
    "profit_factor": 0.8136303380361708,
    "expectancy": -308.7450980392157,
    "average_win": 5728.5,
    "average_loss": -2283.4594594594596
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 5,
    "net_profit": -4061.0,
    "win_rate": 0.2,
    "profit_factor": 0.11331877729257642,
    "expectancy": -812.2,
    "average_win": 519.0,
    "average_loss": -1145.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 15,
    "net_profit": 6598.0,
    "win_rate": 0.26666666666666666,
    "profit_factor": 1.2530490143437907,
    "expectancy": 439.8666666666667,
    "average_win": 8168.0,
    "average_loss": -2607.4
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 47,
    "net_profit": -23518.0,
    "win_rate": 0.23404255319148937,
    "profit_factor": 0.6971749375498957,
    "expectancy": -500.3829787234043,
    "average_win": 4922.181818181818,
    "average_loss": -2284.176470588235
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 42,
    "net_profit": -99772.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.07743235995783478,
    "expectancy": -2375.5238095238096,
    "average_win": 1395.6666666666667,
    "average_loss": -3004.0555555555557
  },
  {
    "close_reason": "SL",
    "number_of_trades": 15,
    "net_profit": -170.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -11.333333333333334,
    "average_win": null,
    "average_loss": -14.166666666666666
  },
  {
    "close_reason": "TP",
    "number_of_trades": 10,
    "net_profit": 78961.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7896.1,
    "average_win": 7896.1,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 5,
    "net_profit": -11680.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2336.0,
    "average_win": null,
    "average_loss": -2336.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 23,
    "net_profit": -6511.0,
    "win_rate": 0.17391304347826086,
    "profit_factor": 0.8330983568737023,
    "expectancy": -283.0869565217391,
    "average_win": 8125.0,
    "average_loss": -2053.2105263157896
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 23,
    "net_profit": 12484.0,
    "win_rate": 0.34782608695652173,
    "profit_factor": 1.3849640753646428,
    "expectancy": 542.7826086956521,
    "average_win": 5614.125,
    "average_loss": -2494.5384615384614
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 16,
    "net_profit": -15274.0,
    "win_rate": 0.25,
    "profit_factor": 0.3937926655024607,
    "expectancy": -954.625,
    "average_win": 2480.5,
    "average_loss": -2290.5454545454545
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 6,
    "net_profit": 3604.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2931988285063456,
    "expectancy": 600.6666666666666,
    "average_win": 7948.0,
    "average_loss": -3073.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 15,
    "net_profit": 201.0,
    "win_rate": 0.26666666666666666,
    "profit_factor": 1.008048692587995,
    "expectancy": 13.4,
    "average_win": 6293.5,
    "average_loss": -2270.2727272727275
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 13,
    "net_profit": 4405.0,
    "win_rate": 0.3076923076923077,
    "profit_factor": 1.3820799722439068,
    "expectancy": 338.84615384615387,
    "average_win": 3983.5,
    "average_loss": -1281.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 19,
    "net_profit": -10274.0,
    "win_rate": 0.21052631578947367,
    "profit_factor": 0.681771720613288,
    "expectancy": -540.7368421052631,
    "average_win": 5502.75,
    "average_loss": -2483.4615384615386
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 14,
    "net_profit": -18917.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.3054668282116239,
    "expectancy": -1351.2142857142858,
    "average_win": 4160.0,
    "average_loss": -2476.090909090909
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.024-1.001",
    "number_of_trades": 22,
    "net_profit": 87325.0,
    "win_rate": 0.7272727272727273,
    "profit_factor": 8733.5,
    "expectancy": 3969.318181818182,
    "average_win": 5458.4375,
    "average_loss": -3.3333333333333335
  },
  {
    "giveback_band": "GIVEBACK_1.001-2.85",
    "number_of_trades": 21,
    "net_profit": -33155.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1578.8095238095239,
    "average_win": null,
    "average_loss": -1578.8095238095239
  },
  {
    "giveback_band": "GIVEBACK_2.85-335.8",
    "number_of_trades": 22,
    "net_profit": -67925.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3087.5,
    "average_win": null,
    "average_loss": -3087.5
  }
]
```

## time_stop_reason_code別

```json
[
  {
    "time_stop_reason_code": "MAX_HOLDING_BARS_MIN_MFE_NOT_REACHED",
    "number_of_trades": 1,
    "net_profit": 310.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 310.0,
    "average_win": 310.0,
    "average_loss": null
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
