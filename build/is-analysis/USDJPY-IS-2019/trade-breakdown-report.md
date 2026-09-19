# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 14
- MFEデータのある負けトレード数: 14
- うち一度含み益になった数: 14
- 割合: 100.00%
- 反転前の平均含み益: 2710.79

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 17
- 平均Giveback比率: 392.61%
- 中央値Giveback比率: 234.38%
- 損益ゼロ以下まで完全反転した割合: 82.35%

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

- 決済件数: 11
- 純損益: -41550.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3777.27
- 平均逆行幅（R）: 0.7670
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 6,
    "net_profit": -21981.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3663.5,
    "average_win": null,
    "average_loss": -3663.5
  },
  "SELL": {
    "number_of_trades": 5,
    "net_profit": -19569.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3913.8,
    "average_win": null,
    "average_loss": -3913.8
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6215
- 最終Entry候補まで到達: 32
- Stage別棄却数（market_regime）: 5383
- Stage別棄却数（htf_bias）: 165
- Stage別棄却数（trend_strength_or_momentum_filter）: 367
- Stage別棄却数（setup_or_trigger）: 268
- Stage別棄却数（other）: 0

```json
{
  "ENTRY_PATTERN_NOT_FOUND": 268,
  "RSI_FILTERED": 326,
  "REGIME_NOT_TRENDING": 5383,
  "CONFIRMATION_ADX_TOO_LOW": 41,
  "TREND_NOT_ALIGNED": 165
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 8,
    "net_profit": -16338.0,
    "win_rate": 0.125,
    "profit_factor": 0.28773214752811926,
    "expectancy": -2042.25,
    "average_win": 6600.0,
    "average_loss": -3276.8571428571427
  },
  {
    "direction": "SELL",
    "number_of_trades": 9,
    "net_profit": -744.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.9633750123067835,
    "expectancy": -82.66666666666667,
    "average_win": 9785.0,
    "average_loss": -2902.0
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 1,
    "net_profit": -3808.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3808.0,
    "average_win": null,
    "average_loss": -3808.0
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 4,
    "net_profit": -1537.0,
    "win_rate": 0.25,
    "profit_factor": 0.8616935121029425,
    "expectancy": -384.25,
    "average_win": 9576.0,
    "average_loss": -3704.3333333333335
  },
  {
    "session": "NewYork",
    "number_of_trades": 4,
    "net_profit": -9580.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2395.0,
    "average_win": null,
    "average_loss": -2395.0
  },
  {
    "session": "Tokyo",
    "number_of_trades": 8,
    "net_profit": -2157.0,
    "win_rate": 0.25,
    "profit_factor": 0.8849661351394592,
    "expectancy": -269.625,
    "average_win": 8297.0,
    "average_loss": -3125.1666666666665
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 5,
    "net_profit": -2068.0,
    "win_rate": 0.2,
    "profit_factor": 0.8285524788592273,
    "expectancy": -413.6,
    "average_win": 9994.0,
    "average_loss": -3015.5
  },
  {
    "weekday": "Mon",
    "number_of_trades": 2,
    "net_profit": -7506.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3753.0,
    "average_win": null,
    "average_loss": -3753.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": 9064.0,
    "win_rate": 0.5,
    "profit_factor": 2.2744656917885266,
    "expectancy": 2266.0,
    "average_win": 8088.0,
    "average_loss": -3556.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": -8899.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2966.3333333333335,
    "average_win": null,
    "average_loss": -2966.3333333333335
  },
  {
    "weekday": "Wed",
    "number_of_trades": 3,
    "net_profit": -7673.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2557.6666666666665,
    "average_win": null,
    "average_loss": -2557.6666666666665
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.0511-0.0763",
    "number_of_trades": 6,
    "net_profit": -9124.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.41974052403968454,
    "expectancy": -1520.6666666666667,
    "average_win": 6600.0,
    "average_loss": -3144.8
  },
  {
    "atr_band": "ATR_0.0763-0.114",
    "number_of_trades": 5,
    "net_profit": -3043.0,
    "win_rate": 0.2,
    "profit_factor": 0.7588556937950709,
    "expectancy": -608.6,
    "average_win": 9576.0,
    "average_loss": -3154.75
  },
  {
    "atr_band": "ATR_0.114-0.198",
    "number_of_trades": 6,
    "net_profit": -4915.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.6703333556911932,
    "expectancy": -819.1666666666666,
    "average_win": 9994.0,
    "average_loss": -2981.8
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.1-41.18",
    "number_of_trades": 6,
    "net_profit": -6055.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.6227179263505515,
    "expectancy": -1009.1666666666666,
    "average_win": 9994.0,
    "average_loss": -3209.8
  },
  {
    "adx_band": "ADX_41.18-45.71",
    "number_of_trades": 5,
    "net_profit": 5113.0,
    "win_rate": 0.4,
    "profit_factor": 1.4621712013016361,
    "expectancy": 1022.6,
    "average_win": 8088.0,
    "average_loss": -3687.6666666666665
  },
  {
    "adx_band": "ADX_45.71-60.35",
    "number_of_trades": 6,
    "net_profit": -16140.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2690.0,
    "average_win": null,
    "average_loss": -2690.0
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.857-5.281",
    "number_of_trades": 6,
    "net_profit": -8881.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.5188275451048383,
    "expectancy": -1480.1666666666667,
    "average_win": 9576.0,
    "average_loss": -3691.4
  },
  {
    "hold_time_band": "HOLD_H_14.33-65",
    "number_of_trades": 6,
    "net_profit": -2485.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.7264722069345074,
    "expectancy": -414.1666666666667,
    "average_win": 6600.0,
    "average_loss": -1817.0
  },
  {
    "hold_time_band": "HOLD_H_5.281-14.33",
    "number_of_trades": 5,
    "net_profit": -5716.0,
    "win_rate": 0.2,
    "profit_factor": 0.6361553150859325,
    "expectancy": -1143.2,
    "average_win": 9994.0,
    "average_loss": -3927.5
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_135-2404",
    "number_of_trades": 6,
    "net_profit": -22147.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3691.1666666666665,
    "average_win": null,
    "average_loss": -3691.1666666666665
  },
  {
    "mfe_band": "MFE_2404-4161",
    "number_of_trades": 5,
    "net_profit": -15808.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3161.6,
    "average_win": null,
    "average_loss": -3161.6
  },
  {
    "mfe_band": "MFE_4161-9766",
    "number_of_trades": 6,
    "net_profit": 20873.0,
    "win_rate": 0.5,
    "profit_factor": 4.940532376817067,
    "expectancy": 3478.8333333333335,
    "average_win": 8723.333333333334,
    "average_loss": -1765.6666666666667
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-3388--1025",
    "number_of_trades": 6,
    "net_profit": 24468.0,
    "win_rate": 0.5,
    "profit_factor": 15.376028202115158,
    "expectancy": 4078.0,
    "average_win": 8723.333333333334,
    "average_loss": -567.3333333333334
  },
  {
    "mae_band": "MAE_-3733--3388",
    "number_of_trades": 5,
    "net_profit": -18093.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3618.6,
    "average_win": null,
    "average_loss": -3618.6
  },
  {
    "mae_band": "MAE_-4552--3733",
    "number_of_trades": 6,
    "net_profit": -23457.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3909.5,
    "average_win": null,
    "average_loss": -3909.5
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 10,
    "net_profit": 5858.0,
    "win_rate": 0.3,
    "profit_factor": 1.288400945254037,
    "expectancy": 585.8,
    "average_win": 8723.333333333334,
    "average_loss": -2901.714285714286
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 7,
    "net_profit": -22940.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3277.1428571428573,
    "average_win": null,
    "average_loss": -3277.1428571428573
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": 3106.0,
    "win_rate": 0.5,
    "profit_factor": 1.8889524899828276,
    "expectancy": 1553.0,
    "average_win": 6600.0,
    "average_loss": -3494.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 1,
    "net_profit": -3698.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3698.0,
    "average_win": null,
    "average_loss": -3698.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 14,
    "net_profit": -16490.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5427066001109262,
    "expectancy": -1177.857142857143,
    "average_win": 9785.0,
    "average_loss": -3005.0
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 13,
    "net_profit": -42675.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3282.6923076923076,
    "average_win": null,
    "average_loss": -3282.6923076923076
  },
  {
    "close_reason": "SL",
    "number_of_trades": 1,
    "net_profit": -577.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -577.0,
    "average_win": null,
    "average_loss": -577.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 3,
    "net_profit": 26170.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8723.333333333334,
    "average_win": 8723.333333333334,
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
    "net_profit": -2039.0,
    "win_rate": 0.2,
    "profit_factor": 0.8305493226959195,
    "expectancy": -407.8,
    "average_win": 9994.0,
    "average_loss": -3008.25
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 4,
    "net_profit": -14717.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3679.25,
    "average_win": null,
    "average_loss": -3679.25
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 5,
    "net_profit": 8012.0,
    "win_rate": 0.4,
    "profit_factor": 1.9813816756491915,
    "expectancy": 1602.4,
    "average_win": 8088.0,
    "average_loss": -2721.3333333333335
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 3,
    "net_profit": -8338.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2779.3333333333335,
    "average_win": null,
    "average_loss": -2779.3333333333335
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 5,
    "net_profit": -4605.0,
    "win_rate": 0.2,
    "profit_factor": 0.684567436125762,
    "expectancy": -921.0,
    "average_win": 9994.0,
    "average_loss": -3649.75
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 3,
    "net_profit": -8463.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2821.0,
    "average_win": null,
    "average_loss": -2821.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": 8669.0,
    "win_rate": 0.5,
    "profit_factor": 2.154788863727188,
    "expectancy": 2167.25,
    "average_win": 8088.0,
    "average_loss": -3753.5
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 1,
    "net_profit": -3770.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3770.0,
    "average_win": null,
    "average_loss": -3770.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 4,
    "net_profit": -8913.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2228.25,
    "average_win": null,
    "average_loss": -2228.25
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0243-1.523",
    "number_of_trades": 6,
    "net_profit": 24468.0,
    "win_rate": 0.5,
    "profit_factor": 15.376028202115158,
    "expectancy": 4078.0,
    "average_win": 8723.333333333334,
    "average_loss": -567.3333333333334
  },
  {
    "giveback_band": "GIVEBACK_1.523-2.597",
    "number_of_trades": 5,
    "net_profit": -19403.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3880.6,
    "average_win": null,
    "average_loss": -3880.6
  },
  {
    "giveback_band": "GIVEBACK_2.597-28",
    "number_of_trades": 6,
    "net_profit": -22147.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3691.1666666666665,
    "average_win": null,
    "average_loss": -3691.1666666666665
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
