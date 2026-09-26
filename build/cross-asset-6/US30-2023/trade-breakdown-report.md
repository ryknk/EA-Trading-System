# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 18
- MFEデータのある負けトレード数: 18
- うち一度含み益になった数: 17
- 割合: 94.44%
- 反転前の平均含み益: 2255.88

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 20
- 平均Giveback比率: 448.01%
- 中央値Giveback比率: 234.54%
- 損益ゼロ以下まで完全反転した割合: 85.00%

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
- 純損益: -51125.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3408.33
- 平均逆行幅（R）: 0.7872
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 10,
    "net_profit": -35829.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3582.9,
    "average_win": null,
    "average_loss": -3582.9
  },
  "SELL": {
    "number_of_trades": 5,
    "net_profit": -15296.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3059.2,
    "average_win": null,
    "average_loss": -3059.2
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 5891
- 最終Entry候補まで到達: 35
- Stage別棄却数（market_regime）: 4852
- Stage別棄却数（htf_bias）: 286
- Stage別棄却数（trend_strength_or_momentum_filter）: 459
- Stage別棄却数（setup_or_trigger）: 259
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 4852,
  "TREND_NOT_ALIGNED": 286,
  "ENTRY_PATTERN_NOT_FOUND": 259,
  "RSI_FILTERED": 375,
  "CONFIRMATION_ADX_TOO_LOW": 84
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 16,
    "net_profit": -20727.0,
    "win_rate": 0.1875,
    "profit_factor": 0.4344919786096257,
    "expectancy": -1295.4375,
    "average_win": 5308.333333333333,
    "average_loss": -2819.3846153846152
  },
  {
    "direction": "SELL",
    "number_of_trades": 5,
    "net_profit": -15296.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3059.2,
    "average_win": null,
    "average_loss": -3059.2
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 4,
    "net_profit": -13330.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3332.5,
    "average_win": null,
    "average_loss": -3332.5
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 2,
    "net_profit": 3661.0,
    "win_rate": 0.5,
    "profit_factor": 1.9910665944775312,
    "expectancy": 1830.5,
    "average_win": 7355.0,
    "average_loss": -3694.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 10,
    "net_profit": -19296.0,
    "win_rate": 0.1,
    "profit_factor": 0.27981189116560296,
    "expectancy": -1929.6,
    "average_win": 7497.0,
    "average_loss": -2977.0
  },
  {
    "session": "Tokyo",
    "number_of_trades": 5,
    "net_profit": -7058.0,
    "win_rate": 0.2,
    "profit_factor": 0.13196408805804943,
    "expectancy": -1411.6,
    "average_win": 1073.0,
    "average_loss": -2032.75
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 2,
    "net_profit": -6304.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3152.0,
    "average_win": null,
    "average_loss": -3152.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 6,
    "net_profit": -1280.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.8681499793984343,
    "expectancy": -213.33333333333334,
    "average_win": 4214.0,
    "average_loss": -2427.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": 435.0,
    "win_rate": 0.25,
    "profit_factor": 1.0615972812234495,
    "expectancy": 108.75,
    "average_win": 7497.0,
    "average_loss": -2354.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": -11009.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3669.6666666666665,
    "average_win": null,
    "average_loss": -3669.6666666666665
  },
  {
    "weekday": "Wed",
    "number_of_trades": 6,
    "net_profit": -17865.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2977.5,
    "average_win": null,
    "average_loss": -2977.5
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_41.25-52.68",
    "number_of_trades": 7,
    "net_profit": -14291.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.33978564168899567,
    "expectancy": -2041.5714285714287,
    "average_win": 7355.0,
    "average_loss": -3607.6666666666665
  },
  {
    "atr_band": "ATR_52.68-69.73",
    "number_of_trades": 7,
    "net_profit": -6201.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5473061760840998,
    "expectancy": -885.8571428571429,
    "average_win": 7497.0,
    "average_loss": -2283.0
  },
  {
    "atr_band": "ATR_69.73-88.29",
    "number_of_trades": 7,
    "net_profit": -15531.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.06462298241387618,
    "expectancy": -2218.714285714286,
    "average_win": 1073.0,
    "average_loss": -2767.3333333333335
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.16-42.48",
    "number_of_trades": 7,
    "net_profit": -8068.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.5109117361784675,
    "expectancy": -1152.5714285714287,
    "average_win": 4214.0,
    "average_loss": -3299.2
  },
  {
    "adx_band": "ADX_42.48-45.03",
    "number_of_trades": 7,
    "net_profit": -7999.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.4838022715539494,
    "expectancy": -1142.7142857142858,
    "average_win": 7497.0,
    "average_loss": -2582.6666666666665
  },
  {
    "adx_band": "ADX_45.03-58.59",
    "number_of_trades": 7,
    "net_profit": -19956.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2850.8571428571427,
    "average_win": null,
    "average_loss": -2850.8571428571427
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.134-2.169",
    "number_of_trades": 7,
    "net_profit": -24035.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3433.5714285714284,
    "average_win": null,
    "average_loss": -3433.5714285714284
  },
  {
    "hold_time_band": "HOLD_H_10.47-54.09",
    "number_of_trades": 7,
    "net_profit": 426.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.0523084479371316,
    "expectancy": 60.857142857142854,
    "average_win": 4285.0,
    "average_loss": -1628.8
  },
  {
    "hold_time_band": "HOLD_H_2.169-10.47",
    "number_of_trades": 7,
    "net_profit": -12414.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.37204714451919674,
    "expectancy": -1773.4285714285713,
    "average_win": 7355.0,
    "average_loss": -3294.8333333333335
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-22-1305",
    "number_of_trades": 7,
    "net_profit": -23834.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3404.8571428571427,
    "average_win": null,
    "average_loss": -3404.8571428571427
  },
  {
    "mfe_band": "MFE_1305-2647",
    "number_of_trades": 7,
    "net_profit": -16199.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.062123668364983786,
    "expectancy": -2314.1428571428573,
    "average_win": 1073.0,
    "average_loss": -2878.6666666666665
  },
  {
    "mfe_band": "MFE_2647-7456",
    "number_of_trades": 7,
    "net_profit": 4010.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.3698579597860174,
    "expectancy": 572.8571428571429,
    "average_win": 7426.0,
    "average_loss": -2168.4
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2890--255",
    "number_of_trades": 7,
    "net_profit": 10394.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.8792261797143373,
    "expectancy": 1484.857142857143,
    "average_win": 5308.333333333333,
    "average_loss": -1382.75
  },
  {
    "mae_band": "MAE_-3652--2890",
    "number_of_trades": 7,
    "net_profit": -20691.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2955.8571428571427,
    "average_win": null,
    "average_loss": -2955.8571428571427
  },
  {
    "mae_band": "MAE_-3950--3652",
    "number_of_trades": 7,
    "net_profit": -25726.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3675.1428571428573,
    "average_win": null,
    "average_loss": -3675.1428571428573
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 10,
    "net_profit": -22571.0,
    "win_rate": 0.1,
    "profit_factor": 0.24933484102700545,
    "expectancy": -2257.1,
    "average_win": 7497.0,
    "average_loss": -3340.8888888888887
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 11,
    "net_profit": -13452.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.38519195612431445,
    "expectancy": -1222.909090909091,
    "average_win": 4214.0,
    "average_loss": -2431.1111111111113
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": -4363.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2181.5,
    "average_win": null,
    "average_loss": -2181.5
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 2,
    "net_profit": 3661.0,
    "win_rate": 0.5,
    "profit_factor": 1.9910665944775312,
    "expectancy": 1830.5,
    "average_win": 7355.0,
    "average_loss": -3694.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 17,
    "net_profit": -35321.0,
    "win_rate": 0.11764705882352941,
    "profit_factor": 0.19525643070333326,
    "expectancy": -2077.705882352941,
    "average_win": 4285.0,
    "average_loss": -2926.0666666666666
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 17,
    "net_profit": -50799.0,
    "win_rate": 0.058823529411764705,
    "profit_factor": 0.02068553362122147,
    "expectancy": -2988.176470588235,
    "average_win": 1073.0,
    "average_loss": -3242.0
  },
  {
    "close_reason": "SL",
    "number_of_trades": 2,
    "net_profit": -76.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -38.0,
    "average_win": null,
    "average_loss": -38.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 2,
    "net_profit": 14852.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7426.0,
    "average_win": 7426.0,
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
    "net_profit": -3587.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3587.0,
    "average_win": null,
    "average_loss": -3587.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 6,
    "net_profit": -12427.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.07948148148148149,
    "expectancy": -2071.1666666666665,
    "average_win": 1073.0,
    "average_loss": -2700.0
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 12,
    "net_profit": -13510.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.5236584161906777,
    "expectancy": -1125.8333333333333,
    "average_win": 7426.0,
    "average_loss": -2836.2
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 2,
    "net_profit": -6499.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3249.5,
    "average_win": null,
    "average_loss": -3249.5
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": 4796.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.775638652350981,
    "expectancy": 1598.6666666666667,
    "average_win": 7497.0,
    "average_loss": -1350.5
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 5,
    "net_profit": -5906.0,
    "win_rate": 0.2,
    "profit_factor": 0.5546338888469949,
    "expectancy": -1181.2,
    "average_win": 7355.0,
    "average_loss": -3315.25
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 2,
    "net_profit": -7049.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3524.5,
    "average_win": null,
    "average_loss": -3524.5
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": -6294.0,
    "win_rate": 0.25,
    "profit_factor": 0.14564951812135196,
    "expectancy": -1573.5,
    "average_win": 1073.0,
    "average_loss": -2455.6666666666665
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 7,
    "net_profit": -21570.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3081.4285714285716,
    "average_win": null,
    "average_loss": -3081.4285714285716
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0114-1.883",
    "number_of_trades": 7,
    "net_profit": 11909.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 3.9653884462151394,
    "expectancy": 1701.2857142857142,
    "average_win": 5308.333333333333,
    "average_loss": -1004.0
  },
  {
    "giveback_band": "GIVEBACK_1.883-3.74",
    "number_of_trades": 6,
    "net_profit": -20148.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3358.0,
    "average_win": null,
    "average_loss": -3358.0
  },
  {
    "giveback_band": "GIVEBACK_3.74-27.77",
    "number_of_trades": 7,
    "net_profit": -25701.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3671.5714285714284,
    "average_win": null,
    "average_loss": -3671.5714285714284
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
