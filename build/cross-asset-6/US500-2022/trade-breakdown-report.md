# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 19
- MFEデータのある負けトレード数: 19
- うち一度含み益になった数: 16
- 割合: 84.21%
- 反転前の平均含み益: 2146.69

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 20
- 平均Giveback比率: 415.33%
- 中央値Giveback比率: 241.50%
- 損益ゼロ以下まで完全反転した割合: 80.00%

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
- 純損益: -43753.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -2916.87
- 平均逆行幅（R）: 0.7670
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 6,
    "net_profit": -17153.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2858.8333333333335,
    "average_win": null,
    "average_loss": -2858.8333333333335
  },
  "SELL": {
    "number_of_trades": 9,
    "net_profit": -26600.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2955.5555555555557,
    "average_win": null,
    "average_loss": -2955.5555555555557
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 5908
- 最終Entry候補まで到達: 45
- Stage別棄却数（market_regime）: 4729
- Stage別棄却数（htf_bias）: 314
- Stage別棄却数（trend_strength_or_momentum_filter）: 563
- Stage別棄却数（setup_or_trigger）: 257
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 4729,
  "CONFIRMATION_ADX_TOO_LOW": 44,
  "RSI_FILTERED": 519,
  "TREND_NOT_ALIGNED": 314,
  "ENTRY_PATTERN_NOT_FOUND": 257
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 8,
    "net_profit": -164.0,
    "win_rate": 0.25,
    "profit_factor": 0.9904389902640938,
    "expectancy": -20.5,
    "average_win": 8494.5,
    "average_loss": -2858.8333333333335
  },
  {
    "direction": "SELL",
    "number_of_trades": 15,
    "net_profit": -10701.0,
    "win_rate": 0.13333333333333333,
    "profit_factor": 0.6016750418760469,
    "expectancy": -713.4,
    "average_win": 8082.0,
    "average_loss": -2066.5384615384614
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 7,
    "net_profit": -5833.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5536424854606673,
    "expectancy": -833.2857142857143,
    "average_win": 7235.0,
    "average_loss": -2178.0
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 2,
    "net_profit": 4969.0,
    "win_rate": 0.5,
    "profit_factor": 2.9524557956777997,
    "expectancy": 2484.5,
    "average_win": 7514.0,
    "average_loss": -2545.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 10,
    "net_profit": 1694.0,
    "win_rate": 0.2,
    "profit_factor": 1.101376421304608,
    "expectancy": 169.4,
    "average_win": 9202.0,
    "average_loss": -2088.75
  },
  {
    "session": "Tokyo",
    "number_of_trades": 4,
    "net_profit": -11695.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2923.75,
    "average_win": null,
    "average_loss": -2923.75
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 6,
    "net_profit": -1000.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.9045346062052506,
    "expectancy": -166.66666666666666,
    "average_win": 9475.0,
    "average_loss": -2095.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 3,
    "net_profit": -2366.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -788.6666666666666,
    "average_win": null,
    "average_loss": -788.6666666666666
  },
  {
    "weekday": "Thu",
    "number_of_trades": 7,
    "net_profit": 1243.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.083305408484686,
    "expectancy": 177.57142857142858,
    "average_win": 8082.0,
    "average_loss": -2984.2
  },
  {
    "weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": -2283.0,
    "win_rate": 0.25,
    "profit_factor": 0.7669694804532,
    "expectancy": -570.75,
    "average_win": 7514.0,
    "average_loss": -3265.6666666666665
  },
  {
    "weekday": "Wed",
    "number_of_trades": 3,
    "net_profit": -6459.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2153.0,
    "average_win": null,
    "average_loss": -2153.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_12.06-14.03",
    "number_of_trades": 7,
    "net_profit": 1697.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 1.306428313470567,
    "expectancy": 242.42857142857142,
    "average_win": 7235.0,
    "average_loss": -923.0
  },
  {
    "atr_band": "ATR_14.03-24.99",
    "number_of_trades": 8,
    "net_profit": -24642.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3080.25,
    "average_win": null,
    "average_loss": -3080.25
  },
  {
    "atr_band": "ATR_7.706-12.06",
    "number_of_trades": 8,
    "net_profit": 12080.0,
    "win_rate": 0.375,
    "profit_factor": 1.8729585200173435,
    "expectancy": 1510.0,
    "average_win": 8639.333333333334,
    "average_loss": -2767.6
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.09-41.75",
    "number_of_trades": 8,
    "net_profit": 3660.0,
    "win_rate": 0.25,
    "profit_factor": 1.2482365708084644,
    "expectancy": 457.5,
    "average_win": 9202.0,
    "average_loss": -2457.3333333333335
  },
  {
    "adx_band": "ADX_41.75-45.05",
    "number_of_trades": 7,
    "net_profit": -15210.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2172.8571428571427,
    "average_win": null,
    "average_loss": -2172.8571428571427
  },
  {
    "adx_band": "ADX_45.05-54.87",
    "number_of_trades": 8,
    "net_profit": 685.0,
    "win_rate": 0.25,
    "profit_factor": 1.0487059158134244,
    "expectancy": 85.625,
    "average_win": 7374.5,
    "average_loss": -2344.0
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.449-2.158",
    "number_of_trades": 8,
    "net_profit": -23728.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2966.0,
    "average_win": null,
    "average_loss": -2966.0
  },
  {
    "hold_time_band": "HOLD_H_2.158-5.165",
    "number_of_trades": 7,
    "net_profit": 13865.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.150336015929644,
    "expectancy": 1980.7142857142858,
    "average_win": 8639.333333333334,
    "average_loss": -3013.25
  },
  {
    "hold_time_band": "HOLD_H_5.165-21.61",
    "number_of_trades": 8,
    "net_profit": -1002.0,
    "win_rate": 0.125,
    "profit_factor": 0.8783537695763021,
    "expectancy": -125.25,
    "average_win": 7235.0,
    "average_loss": -1176.7142857142858
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-37-821.3",
    "number_of_trades": 8,
    "net_profit": -22916.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2864.5,
    "average_win": null,
    "average_loss": -2864.5
  },
  {
    "mfe_band": "MFE_3527-9395",
    "number_of_trades": 8,
    "net_profit": 32888.0,
    "win_rate": 0.5,
    "profit_factor": 125.10566037735849,
    "expectancy": 4111.0,
    "average_win": 8288.25,
    "average_loss": -66.25
  },
  {
    "mfe_band": "MFE_821.3-3527",
    "number_of_trades": 7,
    "net_profit": -20837.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2976.714285714286,
    "average_win": null,
    "average_loss": -2976.714285714286
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1987--26",
    "number_of_trades": 8,
    "net_profit": 32888.0,
    "win_rate": 0.5,
    "profit_factor": 125.10566037735849,
    "expectancy": 4111.0,
    "average_win": 8288.25,
    "average_loss": -66.25
  },
  {
    "mae_band": "MAE_-2716--1987",
    "number_of_trades": 7,
    "net_profit": -17154.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2450.5714285714284,
    "average_win": null,
    "average_loss": -2450.5714285714284
  },
  {
    "mae_band": "MAE_-3730--2716",
    "number_of_trades": 8,
    "net_profit": -26599.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3324.875,
    "average_win": null,
    "average_loss": -3324.875
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 13,
    "net_profit": -11493.0,
    "win_rate": 0.15384615384615385,
    "profit_factor": 0.5844451675886756,
    "expectancy": -884.0769230769231,
    "average_win": 8082.0,
    "average_loss": -2514.2727272727275
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 10,
    "net_profit": 628.0,
    "win_rate": 0.2,
    "profit_factor": 1.038383961860522,
    "expectancy": 62.8,
    "average_win": 8494.5,
    "average_loss": -2045.125
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 2,
    "net_profit": 4969.0,
    "win_rate": 0.5,
    "profit_factor": 2.9524557956777997,
    "expectancy": 2484.5,
    "average_win": 7514.0,
    "average_loss": -2545.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 21,
    "net_profit": -15834.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.6182094374653389,
    "expectancy": -754.0,
    "average_win": 8546.333333333334,
    "average_loss": -2304.0555555555557
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 15,
    "net_profit": -43753.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2916.866666666667,
    "average_win": null,
    "average_loss": -2916.866666666667
  },
  {
    "close_reason": "SL",
    "number_of_trades": 4,
    "net_profit": -265.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -66.25,
    "average_win": null,
    "average_loss": -66.25
  },
  {
    "close_reason": "TP",
    "number_of_trades": 4,
    "net_profit": 33153.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8288.25,
    "average_win": 8288.25,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 4,
    "net_profit": -9317.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2329.25,
    "average_win": null,
    "average_loss": -2329.25
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 6,
    "net_profit": -3946.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.6556719022687609,
    "expectancy": -657.6666666666666,
    "average_win": 7514.0,
    "average_loss": -2292.0
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 10,
    "net_profit": -969.0,
    "win_rate": 0.2,
    "profit_factor": 0.9434424794256697,
    "expectancy": -96.9,
    "average_win": 8082.0,
    "average_loss": -2141.625
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 3,
    "net_profit": 3367.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.5512442698100852,
    "expectancy": 1122.3333333333333,
    "average_win": 9475.0,
    "average_loss": -3054.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 6,
    "net_profit": -1000.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.9045346062052506,
    "expectancy": -166.66666666666666,
    "average_win": 9475.0,
    "average_loss": -2095.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 7,
    "net_profit": 1243.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.083305408484686,
    "expectancy": 177.57142857142858,
    "average_win": 8082.0,
    "average_loss": -2984.2
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 6,
    "net_profit": -1628.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.8219208050754758,
    "expectancy": -271.3333333333333,
    "average_win": 7514.0,
    "average_loss": -1828.4
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 4,
    "net_profit": -9480.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2370.0,
    "average_win": null,
    "average_loss": -2370.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.01049-1.018",
    "number_of_trades": 7,
    "net_profit": 33045.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 306.97222222222223,
    "expectancy": 4720.714285714285,
    "average_win": 8288.25,
    "average_loss": -36.0
  },
  {
    "giveback_band": "GIVEBACK_1.018-3.555",
    "number_of_trades": 6,
    "net_profit": -15001.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2500.1666666666665,
    "average_win": null,
    "average_loss": -2500.1666666666665
  },
  {
    "giveback_band": "GIVEBACK_3.555-27.95",
    "number_of_trades": 7,
    "net_profit": -19274.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2753.4285714285716,
    "average_win": null,
    "average_loss": -2753.4285714285716
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
