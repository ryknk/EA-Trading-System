# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 14
- MFEデータのある負けトレード数: 14
- うち一度含み益になった数: 14
- 割合: 100.00%
- 反転前の平均含み益: 3179.64

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 24
- 平均Giveback比率: 273.17%
- 中央値Giveback比率: 103.37%
- 損益ゼロ以下まで完全反転した割合: 58.33%

## Time Stop（時間切れ決済）

- Time Stopによる決済件数: 1
- 純損益: 905.00
- プロフィットファクター: 算出不能
- 勝率: 100.00%
- 期待値: 905.00

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

- 決済件数: 11
- 純損益: -40226.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3656.91
- 平均逆行幅（R）: 0.7713
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 9,
    "net_profit": -32726.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3636.222222222222,
    "average_win": null,
    "average_loss": -3636.222222222222
  },
  "SELL": {
    "number_of_trades": 2,
    "net_profit": -7500.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3750.0,
    "average_win": null,
    "average_loss": -3750.0
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6313
- 最終Entry候補まで到達: 39
- Stage別棄却数（market_regime）: 5301
- Stage別棄却数（htf_bias）: 234
- Stage別棄却数（trend_strength_or_momentum_filter）: 455
- Stage別棄却数（setup_or_trigger）: 284
- Stage別棄却数（other）: 0

```json
{
  "ENTRY_PATTERN_NOT_FOUND": 284,
  "REGIME_NOT_TRENDING": 5301,
  "RSI_FILTERED": 399,
  "CONFIRMATION_ADX_TOO_LOW": 56,
  "TREND_NOT_ALIGNED": 234
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 20,
    "net_profit": 16533.0,
    "win_rate": 0.45,
    "profit_factor": 1.5018668609416264,
    "expectancy": 826.65,
    "average_win": 5497.333333333333,
    "average_loss": -2994.818181818182
  },
  {
    "direction": "SELL",
    "number_of_trades": 4,
    "net_profit": 2023.0,
    "win_rate": 0.25,
    "profit_factor": 1.260595130748422,
    "expectancy": 505.75,
    "average_win": 9786.0,
    "average_loss": -2587.6666666666665
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 5,
    "net_profit": 7562.0,
    "win_rate": 0.4,
    "profit_factor": 2.756562137049942,
    "expectancy": 1512.4,
    "average_win": 5933.5,
    "average_loss": -1435.0
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 5,
    "net_profit": -2981.0,
    "win_rate": 0.4,
    "profit_factor": 0.7182952182952183,
    "expectancy": -596.2,
    "average_win": 3800.5,
    "average_loss": -3527.3333333333335
  },
  {
    "session": "NewYork",
    "number_of_trades": 8,
    "net_profit": 23668.0,
    "win_rate": 0.625,
    "profit_factor": 4.335870331219168,
    "expectancy": 2958.5,
    "average_win": 6152.6,
    "average_loss": -2365.0
  },
  {
    "session": "Tokyo",
    "number_of_trades": 6,
    "net_profit": -9693.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.48232215338602863,
    "expectancy": -1615.5,
    "average_win": 9031.0,
    "average_loss": -3744.8
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 4,
    "net_profit": 10564.0,
    "win_rate": 0.75,
    "profit_factor": 3.533333333333333,
    "expectancy": 2641.0,
    "average_win": 4911.333333333333,
    "average_loss": -4170.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 8,
    "net_profit": 9841.0,
    "win_rate": 0.375,
    "profit_factor": 1.908092645566116,
    "expectancy": 1230.125,
    "average_win": 6892.666666666667,
    "average_loss": -2167.4
  },
  {
    "weekday": "Thu",
    "number_of_trades": 5,
    "net_profit": 8766.0,
    "win_rate": 0.4,
    "profit_factor": 1.8334284084426697,
    "expectancy": 1753.2,
    "average_win": 9642.0,
    "average_loss": -3506.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": 914.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2543835235179517,
    "expectancy": 304.6666666666667,
    "average_win": 4507.0,
    "average_loss": -1796.5
  },
  {
    "weekday": "Wed",
    "number_of_trades": 4,
    "net_profit": -11529.0,
    "win_rate": 0.25,
    "profit_factor": 0.005091473938557128,
    "expectancy": -2882.25,
    "average_win": 59.0,
    "average_loss": -3862.6666666666665
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.194-0.251",
    "number_of_trades": 8,
    "net_profit": -6445.0,
    "win_rate": 0.25,
    "profit_factor": 0.5851303508207274,
    "expectancy": -805.625,
    "average_win": 4545.0,
    "average_loss": -2589.1666666666665
  },
  {
    "atr_band": "ATR_0.251-0.339",
    "number_of_trades": 8,
    "net_profit": 5955.0,
    "win_rate": 0.375,
    "profit_factor": 1.4133981256508157,
    "expectancy": 744.375,
    "average_win": 6786.666666666667,
    "average_loss": -2881.0
  },
  {
    "atr_band": "ATR_0.339-0.628",
    "number_of_trades": 8,
    "net_profit": 19046.0,
    "win_rate": 0.625,
    "profit_factor": 2.769087869217908,
    "expectancy": 2380.75,
    "average_win": 5962.4,
    "average_loss": -3588.6666666666665
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.13-42.57",
    "number_of_trades": 8,
    "net_profit": 19751.0,
    "win_rate": 0.5,
    "profit_factor": 3.7424326575951126,
    "expectancy": 2468.875,
    "average_win": 6738.25,
    "average_loss": -1800.5
  },
  {
    "adx_band": "ADX_42.57-44.26",
    "number_of_trades": 8,
    "net_profit": 902.0,
    "win_rate": 0.375,
    "profit_factor": 1.0588734416813523,
    "expectancy": 112.75,
    "average_win": 5407.666666666667,
    "average_loss": -3064.2
  },
  {
    "adx_band": "ADX_44.26-55.22",
    "number_of_trades": 8,
    "net_profit": -2097.0,
    "win_rate": 0.375,
    "profit_factor": 0.8846724962877413,
    "expectancy": -262.125,
    "average_win": 5362.0,
    "average_loss": -3636.6
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_1.351-5.551",
    "number_of_trades": 8,
    "net_profit": -16114.0,
    "win_rate": 0.125,
    "profit_factor": 0.37783783783783786,
    "expectancy": -2014.25,
    "average_win": 9786.0,
    "average_loss": -3700.0
  },
  {
    "hold_time_band": "HOLD_H_15.2-88.06",
    "number_of_trades": 8,
    "net_profit": 17397.0,
    "win_rate": 0.625,
    "profit_factor": 5.432356687898089,
    "expectancy": 2174.625,
    "average_win": 4264.4,
    "average_loss": -1308.3333333333333
  },
  {
    "hold_time_band": "HOLD_H_5.551-15.2",
    "number_of_trades": 8,
    "net_profit": 17273.0,
    "win_rate": 0.5,
    "profit_factor": 2.5874460068008456,
    "expectancy": 2159.125,
    "average_win": 7038.5,
    "average_loss": -2720.25
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_214-2359",
    "number_of_trades": 8,
    "net_profit": -24582.0,
    "win_rate": 0.125,
    "profit_factor": 0.0355082983481775,
    "expectancy": -3072.75,
    "average_win": 905.0,
    "average_loss": -3641.0
  },
  {
    "mfe_band": "MFE_2359-6851",
    "number_of_trades": 8,
    "net_profit": -8297.0,
    "win_rate": 0.375,
    "profit_factor": 0.4447938972162741,
    "expectancy": -1037.125,
    "average_win": 2215.6666666666665,
    "average_loss": -2988.8
  },
  {
    "mfe_band": "MFE_6851-9709",
    "number_of_trades": 8,
    "net_profit": 51435.0,
    "win_rate": 0.75,
    "profit_factor": 188.03636363636363,
    "expectancy": 6429.375,
    "average_win": 8618.333333333334,
    "average_loss": -137.5
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2117--123",
    "number_of_trades": 8,
    "net_profit": 42238.0,
    "win_rate": 0.75,
    "profit_factor": 154.59272727272727,
    "expectancy": 5279.75,
    "average_win": 7085.5,
    "average_loss": -137.5
  },
  {
    "mae_band": "MAE_-3518--2117",
    "number_of_trades": 8,
    "net_profit": -3229.0,
    "win_rate": 0.375,
    "profit_factor": 0.7641516324592799,
    "expectancy": -403.625,
    "average_win": 3487.3333333333335,
    "average_loss": -2738.2
  },
  {
    "mae_band": "MAE_-4488--3518",
    "number_of_trades": 8,
    "net_profit": -20453.0,
    "win_rate": 0.125,
    "profit_factor": 0.23511593118922963,
    "expectancy": -2556.625,
    "average_win": 6287.0,
    "average_loss": -3820.0
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 7,
    "net_profit": 919.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.0606440543750826,
    "expectancy": 131.28571428571428,
    "average_win": 8036.5,
    "average_loss": -3030.8
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 17,
    "net_profit": 17637.0,
    "win_rate": 0.47058823529411764,
    "profit_factor": 1.6902395115842204,
    "expectancy": 1037.4705882352941,
    "average_win": 5398.625,
    "average_loss": -2839.1111111111113
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 5,
    "net_profit": 952.0,
    "win_rate": 0.4,
    "profit_factor": 1.0857889519690007,
    "expectancy": 190.4,
    "average_win": 6024.5,
    "average_loss": -3699.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 3,
    "net_profit": 7140.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 2.797583081570997,
    "expectancy": 2380.0,
    "average_win": 5556.0,
    "average_loss": -3972.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 16,
    "net_profit": 10464.0,
    "win_rate": 0.375,
    "profit_factor": 1.408160081132738,
    "expectancy": 654.0,
    "average_win": 6016.833333333333,
    "average_loss": -2563.7
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 15,
    "net_profit": -26446.0,
    "win_rate": 0.26666666666666666,
    "profit_factor": 0.34256451051558695,
    "expectancy": -1763.0666666666666,
    "average_win": 3445.0,
    "average_loss": -3656.909090909091
  },
  {
    "close_reason": "SL",
    "number_of_trades": 4,
    "net_profit": -421.0,
    "win_rate": 0.25,
    "profit_factor": 0.12291666666666666,
    "expectancy": -105.25,
    "average_win": 59.0,
    "average_loss": -160.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 5,
    "net_profit": 45423.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9084.6,
    "average_win": 9084.6,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 7,
    "net_profit": 2387.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.1629017948542961,
    "expectancy": 341.0,
    "average_win": 8520.0,
    "average_loss": -2930.6
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 6,
    "net_profit": 8192.0,
    "win_rate": 0.5,
    "profit_factor": 1.710494362532524,
    "expectancy": 1365.3333333333333,
    "average_win": 6574.0,
    "average_loss": -3843.3333333333335
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 6,
    "net_profit": 5611.0,
    "win_rate": 0.5,
    "profit_factor": 1.7724394273127753,
    "expectancy": 935.1666666666666,
    "average_win": 4291.666666666667,
    "average_loss": -2421.3333333333335
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 5,
    "net_profit": 2366.0,
    "win_rate": 0.4,
    "profit_factor": 1.325940212150434,
    "expectancy": 473.2,
    "average_win": 4812.5,
    "average_loss": -2419.6666666666665
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": 2062.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2772996234534697,
    "expectancy": 687.3333333333334,
    "average_win": 9498.0,
    "average_loss": -3718.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 5,
    "net_profit": 12481.0,
    "win_rate": 0.6,
    "profit_factor": 4.335382148583645,
    "expectancy": 2496.2,
    "average_win": 5407.666666666667,
    "average_loss": -1871.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": 2593.0,
    "win_rate": 0.5,
    "profit_factor": 1.3575565361279647,
    "expectancy": 648.25,
    "average_win": 4922.5,
    "average_loss": -3626.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 7,
    "net_profit": 8764.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.8406714628297363,
    "expectancy": 1252.0,
    "average_win": 6396.333333333333,
    "average_loss": -2606.25
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": -7344.0,
    "win_rate": 0.2,
    "profit_factor": 0.3803054594548983,
    "expectancy": -1468.8,
    "average_win": 4507.0,
    "average_loss": -2962.75
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00893-0.506",
    "number_of_trades": 8,
    "net_profit": 58298.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7287.25,
    "average_win": 7287.25,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.506-2.124",
    "number_of_trades": 8,
    "net_profit": -10798.0,
    "win_rate": 0.25,
    "profit_factor": 0.0819588505356232,
    "expectancy": -1349.75,
    "average_win": 482.0,
    "average_loss": -1960.3333333333333
  },
  {
    "giveback_band": "GIVEBACK_2.124-16.26",
    "number_of_trades": 8,
    "net_profit": -28944.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3618.0,
    "average_win": null,
    "average_loss": -3618.0
  }
]
```

## time_stop_reason_code別

```json
[
  {
    "time_stop_reason_code": "MAX_HOLDING_BARS_MIN_MFE_NOT_REACHED",
    "number_of_trades": 1,
    "net_profit": 905.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 905.0,
    "average_win": 905.0,
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
