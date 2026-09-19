# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 13
- MFEデータのある負けトレード数: 13
- うち一度含み益になった数: 13
- 割合: 100.00%
- 反転前の平均含み益: 3336.23

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 22
- 平均Giveback比率: 248.54%
- 中央値Giveback比率: 107.87%
- 損益ゼロ以下まで完全反転した割合: 68.18%

## Time Stop（時間切れ決済）

- Time Stopによる決済件数: 1
- 純損益: 818.00
- プロフィットファクター: 算出不能
- 勝率: 100.00%
- 期待値: 818.00

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

- 決済件数: 9
- 純損益: -34152.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3794.67
- 平均逆行幅（R）: 0.7593
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 2,
    "net_profit": -7177.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3588.5,
    "average_win": null,
    "average_loss": -3588.5
  },
  "SELL": {
    "number_of_trades": 7,
    "net_profit": -26975.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3853.5714285714284,
    "average_win": null,
    "average_loss": -3853.5714285714284
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6254
- 最終Entry候補まで到達: 37
- Stage別棄却数（market_regime）: 5208
- Stage別棄却数（htf_bias）: 99
- Stage別棄却数（trend_strength_or_momentum_filter）: 513
- Stage別棄却数（setup_or_trigger）: 397
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5208,
  "RSI_FILTERED": 462,
  "TREND_NOT_ALIGNED": 99,
  "ENTRY_PATTERN_NOT_FOUND": 397,
  "CONFIRMATION_ADX_TOO_LOW": 51
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 3,
    "net_profit": 2327.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.324230179740839,
    "expectancy": 775.6666666666666,
    "average_win": 9504.0,
    "average_loss": -3588.5
  },
  {
    "direction": "SELL",
    "number_of_trades": 19,
    "net_profit": 19584.0,
    "win_rate": 0.3157894736842105,
    "profit_factor": 1.6896503151741382,
    "expectancy": 1030.7368421052631,
    "average_win": 7996.833333333333,
    "average_loss": -2581.5454545454545
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 4,
    "net_profit": 15638.0,
    "win_rate": 0.5,
    "profit_factor": 5.101232625229478,
    "expectancy": 3909.5,
    "average_win": 9725.5,
    "average_loss": -3813.0
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 5,
    "net_profit": 1503.0,
    "win_rate": 0.4,
    "profit_factor": 1.1773032912587,
    "expectancy": 300.6,
    "average_win": 4990.0,
    "average_loss": -2825.6666666666665
  },
  {
    "session": "NewYork",
    "number_of_trades": 7,
    "net_profit": 6573.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.5509177772190093,
    "expectancy": 939.0,
    "average_win": 9252.0,
    "average_loss": -2386.2
  },
  {
    "session": "Tokyo",
    "number_of_trades": 6,
    "net_profit": -1803.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.8411873513608737,
    "expectancy": -300.5,
    "average_win": 9550.0,
    "average_loss": -2838.25
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 7,
    "net_profit": 10493.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 2.2766759946465505,
    "expectancy": 1499.0,
    "average_win": 9356.0,
    "average_loss": -2054.75
  },
  {
    "weekday": "Mon",
    "number_of_trades": 2,
    "net_profit": -4975.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2487.5,
    "average_win": null,
    "average_loss": -2487.5
  },
  {
    "weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": -10817.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3605.6666666666665,
    "average_win": null,
    "average_loss": -3605.6666666666665
  },
  {
    "weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": 18002.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 36.8605577689243,
    "expectancy": 6000.666666666667,
    "average_win": 9252.0,
    "average_loss": -502.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 7,
    "net_profit": 9208.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.8324744598137601,
    "expectancy": 1315.4285714285713,
    "average_win": 6756.333333333333,
    "average_loss": -3687.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.0565-0.0854",
    "number_of_trades": 8,
    "net_profit": 13000.0,
    "win_rate": 0.375,
    "profit_factor": 1.832639467110741,
    "expectancy": 1625.0,
    "average_win": 9537.666666666666,
    "average_loss": -3903.25
  },
  {
    "atr_band": "ATR_0.0854-0.122",
    "number_of_trades": 7,
    "net_profit": 10928.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.301882296878723,
    "expectancy": 1561.142857142857,
    "average_win": 6440.666666666667,
    "average_loss": -2098.5
  },
  {
    "atr_band": "ATR_0.122-0.239",
    "number_of_trades": 7,
    "net_profit": -2017.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.8256246217688251,
    "expectancy": -288.14285714285717,
    "average_win": 9550.0,
    "average_loss": -2313.4
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.21-42.54",
    "number_of_trades": 8,
    "net_profit": 21356.0,
    "win_rate": 0.5,
    "profit_factor": 3.665834477593309,
    "expectancy": 2669.5,
    "average_win": 7341.75,
    "average_loss": -2670.3333333333335
  },
  {
    "adx_band": "ADX_42.54-45.64",
    "number_of_trades": 7,
    "net_profit": 18901.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 3.050667245307584,
    "expectancy": 2700.1428571428573,
    "average_win": 9372.666666666666,
    "average_loss": -2304.25
  },
  {
    "adx_band": "ADX_45.64-72.93",
    "number_of_trades": 7,
    "net_profit": -18346.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2620.8571428571427,
    "average_win": null,
    "average_loss": -3057.6666666666665
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.0532-4.636",
    "number_of_trades": 8,
    "net_profit": -3060.0,
    "win_rate": 0.25,
    "profit_factor": 0.8640664563990937,
    "expectancy": -382.5,
    "average_win": 9725.5,
    "average_loss": -3751.8333333333335
  },
  {
    "hold_time_band": "HOLD_H_16.12-71.54",
    "number_of_trades": 8,
    "net_profit": 9652.0,
    "win_rate": 0.375,
    "profit_factor": 2.023976235943136,
    "expectancy": 1206.5,
    "average_win": 6359.333333333333,
    "average_loss": -1885.2
  },
  {
    "hold_time_band": "HOLD_H_4.636-16.12",
    "number_of_trades": 6,
    "net_profit": 15319.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 5.211987902117129,
    "expectancy": 2553.1666666666665,
    "average_win": 9478.0,
    "average_loss": -1818.5
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_280-4224",
    "number_of_trades": 7,
    "net_profit": -21501.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.036650387562166764,
    "expectancy": -3071.5714285714284,
    "average_win": 818.0,
    "average_loss": -3719.8333333333335
  },
  {
    "mfe_band": "MFE_4224-7088",
    "number_of_trades": 7,
    "net_profit": -13239.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1891.2857142857142,
    "average_win": null,
    "average_loss": -2206.5
  },
  {
    "mfe_band": "MFE_7088-9918",
    "number_of_trades": 8,
    "net_profit": 56651.0,
    "win_rate": 0.75,
    "profit_factor": 3541.6875,
    "expectancy": 7081.375,
    "average_win": 9444.5,
    "average_loss": -16.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1886--544",
    "number_of_trades": 8,
    "net_profit": 27725.0,
    "win_rate": 0.375,
    "profit_factor": 32.867816091954026,
    "expectancy": 3465.625,
    "average_win": 9531.666666666666,
    "average_loss": -290.0
  },
  {
    "mae_band": "MAE_-3700--1886",
    "number_of_trades": 6,
    "net_profit": 9070.0,
    "win_rate": 0.5,
    "profit_factor": 1.8510039407018202,
    "expectancy": 1511.6666666666667,
    "average_win": 6576.0,
    "average_loss": -3552.6666666666665
  },
  {
    "mae_band": "MAE_-5541--3700",
    "number_of_trades": 8,
    "net_profit": -14884.0,
    "win_rate": 0.125,
    "profit_factor": 0.3810197122182484,
    "expectancy": -1860.5,
    "average_win": 9162.0,
    "average_loss": -3435.1428571428573
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 19,
    "net_profit": 19584.0,
    "win_rate": 0.3157894736842105,
    "profit_factor": 1.6896503151741382,
    "expectancy": 1030.7368421052631,
    "average_win": 7996.833333333333,
    "average_loss": -2581.5454545454545
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 3,
    "net_profit": 2327.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.324230179740839,
    "expectancy": 775.6666666666666,
    "average_win": 9504.0,
    "average_loss": -3588.5
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": -368.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -184.0,
    "average_win": null,
    "average_loss": -184.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 2,
    "net_profit": -3813.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1906.5,
    "average_win": null,
    "average_loss": -3813.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 18,
    "net_profit": 26092.0,
    "win_rate": 0.3888888888888889,
    "profit_factor": 1.8311407001560858,
    "expectancy": 1449.5555555555557,
    "average_win": 8212.142857142857,
    "average_loss": -3139.3
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 10,
    "net_profit": -33334.0,
    "win_rate": 0.1,
    "profit_factor": 0.023951745139376902,
    "expectancy": -3333.4,
    "average_win": 818.0,
    "average_loss": -3794.6666666666665
  },
  {
    "close_reason": "SL",
    "number_of_trades": 6,
    "net_profit": -1422.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -237.0,
    "average_win": null,
    "average_loss": -355.5
  },
  {
    "close_reason": "TP",
    "number_of_trades": 6,
    "net_profit": 56667.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9444.5,
    "average_win": 9444.5,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 8,
    "net_profit": 23195.0,
    "win_rate": 0.5,
    "profit_factor": 5.085784745464154,
    "expectancy": 2899.375,
    "average_win": 7218.0,
    "average_loss": -1892.3333333333333
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 7,
    "net_profit": 17341.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.5384137686302344,
    "expectancy": 2477.285714285714,
    "average_win": 9537.666666666666,
    "average_loss": -3757.3333333333335
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 3,
    "net_profit": -10877.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3625.6666666666665,
    "average_win": null,
    "average_loss": -3625.6666666666665
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 4,
    "net_profit": -7748.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1937.0,
    "average_win": null,
    "average_loss": -1937.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 6,
    "net_profit": -1514.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.8631597975415762,
    "expectancy": -252.33333333333334,
    "average_win": 9550.0,
    "average_loss": -2766.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 2,
    "net_profit": 8610.0,
    "win_rate": 0.5,
    "profit_factor": 16.597826086956523,
    "expectancy": 4305.0,
    "average_win": 9162.0,
    "average_loss": -552.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": -6602.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.11024258760107816,
    "expectancy": -2200.6666666666665,
    "average_win": 818.0,
    "average_loss": -3710.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 2,
    "net_profit": -4975.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2487.5,
    "average_win": null,
    "average_loss": -2487.5
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 9,
    "net_profit": 26392.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 3.282452650696186,
    "expectancy": 2932.4444444444443,
    "average_win": 9488.75,
    "average_loss": -2890.75
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00699-1",
    "number_of_trades": 7,
    "net_profit": 57485.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8212.142857142857,
    "average_win": 8212.142857142857,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1-1.778",
    "number_of_trades": 8,
    "net_profit": -8632.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1079.0,
    "average_win": null,
    "average_loss": -1438.6666666666667
  },
  {
    "giveback_band": "GIVEBACK_1.778-14.21",
    "number_of_trades": 7,
    "net_profit": -26942.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3848.8571428571427,
    "average_win": null,
    "average_loss": -3848.8571428571427
  }
]
```

## time_stop_reason_code別

```json
[
  {
    "time_stop_reason_code": "MAX_HOLDING_BARS_MIN_MFE_NOT_REACHED",
    "number_of_trades": 1,
    "net_profit": 818.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 818.0,
    "average_win": 818.0,
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
