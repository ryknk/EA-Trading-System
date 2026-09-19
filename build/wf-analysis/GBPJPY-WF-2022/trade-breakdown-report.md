# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 7
- MFEデータのある負けトレード数: 7
- うち一度含み益になった数: 7
- 割合: 100.00%
- 反転前の平均含み益: 2049.43

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 13
- 平均Giveback比率: 262.86%
- 中央値Giveback比率: 179.88%
- 損益ゼロ以下まで完全反転した割合: 53.85%

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

- 決済件数: 7
- 純損益: -25293.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3613.29
- 平均逆行幅（R）: 0.7555
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 6,
    "net_profit": -21553.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3592.1666666666665,
    "average_win": null,
    "average_loss": -3592.1666666666665
  },
  "SELL": {
    "number_of_trades": 1,
    "net_profit": -3740.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3740.0,
    "average_win": null,
    "average_loss": -3740.0
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6343
- 最終Entry候補まで到達: 29
- Stage別棄却数（market_regime）: 5349
- Stage別棄却数（htf_bias）: 257
- Stage別棄却数（trend_strength_or_momentum_filter）: 463
- Stage別棄却数（setup_or_trigger）: 245
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5349,
  "RSI_FILTERED": 444,
  "ENTRY_PATTERN_NOT_FOUND": 245,
  "CONFIRMATION_ADX_TOO_LOW": 19,
  "TREND_NOT_ALIGNED": 257
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 11,
    "net_profit": 15686.0,
    "win_rate": 0.45454545454545453,
    "profit_factor": 1.7277873149909526,
    "expectancy": 1426.0,
    "average_win": 7447.8,
    "average_loss": -3592.1666666666665
  },
  {
    "direction": "SELL",
    "number_of_trades": 2,
    "net_profit": 5346.0,
    "win_rate": 0.5,
    "profit_factor": 2.429411764705882,
    "expectancy": 2673.0,
    "average_win": 9086.0,
    "average_loss": -3740.0
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 3,
    "net_profit": -10865.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3621.6666666666665,
    "average_win": null,
    "average_loss": -3621.6666666666665
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 1,
    "net_profit": -3668.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3668.0,
    "average_win": null,
    "average_loss": -3668.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 6,
    "net_profit": 21378.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 3.9679300291545188,
    "expectancy": 3563.0,
    "average_win": 7145.25,
    "average_loss": -3601.5
  },
  {
    "session": "Tokyo",
    "number_of_trades": 3,
    "net_profit": 14187.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 4.988473432667979,
    "expectancy": 4729.0,
    "average_win": 8872.0,
    "average_loss": -3557.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 2,
    "net_profit": 5346.0,
    "win_rate": 0.5,
    "profit_factor": 2.429411764705882,
    "expectancy": 2673.0,
    "average_win": 9086.0,
    "average_loss": -3740.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 3,
    "net_profit": 2332.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.3232155232155232,
    "expectancy": 777.3333333333334,
    "average_win": 9547.0,
    "average_loss": -3607.5
  },
  {
    "weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": 14865.0,
    "win_rate": 0.75,
    "profit_factor": 5.2925209356049665,
    "expectancy": 3716.25,
    "average_win": 6109.333333333333,
    "average_loss": -3463.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 4,
    "net_profit": -1511.0,
    "win_rate": 0.25,
    "profit_factor": 0.8610574712643678,
    "expectancy": -377.75,
    "average_win": 9364.0,
    "average_loss": -3625.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.164-0.234",
    "number_of_trades": 4,
    "net_profit": -2225.0,
    "win_rate": 0.25,
    "profit_factor": 0.7955526968666727,
    "expectancy": -556.25,
    "average_win": 8658.0,
    "average_loss": -3627.6666666666665
  },
  {
    "atr_band": "ATR_0.234-0.377",
    "number_of_trades": 4,
    "net_profit": 11426.0,
    "win_rate": 0.5,
    "profit_factor": 2.5854030803385597,
    "expectancy": 2856.5,
    "average_win": 9316.5,
    "average_loss": -3603.5
  },
  {
    "atr_band": "ATR_0.377-0.497",
    "number_of_trades": 5,
    "net_profit": 11831.0,
    "win_rate": 0.6,
    "profit_factor": 2.64251006525059,
    "expectancy": 2366.2,
    "average_win": 6344.666666666667,
    "average_loss": -3601.5
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.3-42.48",
    "number_of_trades": 5,
    "net_profit": 7118.0,
    "win_rate": 0.4,
    "profit_factor": 1.6527879677182686,
    "expectancy": 1423.6,
    "average_win": 9011.0,
    "average_loss": -3634.6666666666665
  },
  {
    "adx_band": "ADX_42.48-47.52",
    "number_of_trades": 4,
    "net_profit": 15567.0,
    "win_rate": 0.75,
    "profit_factor": 5.264931506849315,
    "expectancy": 3891.75,
    "average_win": 6405.666666666667,
    "average_loss": -3650.0
  },
  {
    "adx_band": "ADX_47.52-50.31",
    "number_of_trades": 4,
    "net_profit": -1653.0,
    "win_rate": 0.25,
    "profit_factor": 0.8460750535431605,
    "expectancy": -413.25,
    "average_win": 9086.0,
    "average_loss": -3579.6666666666665
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_1.978-5.028",
    "number_of_trades": 4,
    "net_profit": -2297.0,
    "win_rate": 0.25,
    "profit_factor": 0.7903240529438612,
    "expectancy": -574.25,
    "average_win": 8658.0,
    "average_loss": -3651.6666666666665
  },
  {
    "hold_time_band": "HOLD_H_5.028-8.251",
    "number_of_trades": 4,
    "net_profit": -14338.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3584.5,
    "average_win": null,
    "average_loss": -3584.5
  },
  {
    "hold_time_band": "HOLD_H_8.251-31.77",
    "number_of_trades": 5,
    "net_profit": 37667.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7533.4,
    "average_win": 7533.4,
    "average_loss": null
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_2653-8632",
    "number_of_trades": 4,
    "net_profit": -10863.0,
    "win_rate": 0.25,
    "profit_factor": 0.00376008804108584,
    "expectancy": -2715.75,
    "average_win": 41.0,
    "average_loss": -3634.6666666666665
  },
  {
    "mfe_band": "MFE_345-2653",
    "number_of_trades": 4,
    "net_profit": -14389.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3597.25,
    "average_win": null,
    "average_loss": -3597.25
  },
  {
    "mfe_band": "MFE_8632-9617",
    "number_of_trades": 5,
    "net_profit": 46284.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9256.8,
    "average_win": 9256.8,
    "average_loss": null
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1176--858",
    "number_of_trades": 5,
    "net_profit": 36961.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7392.2,
    "average_win": 7392.2,
    "average_loss": null
  },
  {
    "mae_band": "MAE_-3557--1176",
    "number_of_trades": 3,
    "net_profit": 2365.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.3379054150592942,
    "expectancy": 788.3333333333334,
    "average_win": 9364.0,
    "average_loss": -3499.5
  },
  {
    "mae_band": "MAE_-3750--3557",
    "number_of_trades": 5,
    "net_profit": -18294.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3658.8,
    "average_win": null,
    "average_loss": -3658.8
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 3,
    "net_profit": 1883.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.261418853255588,
    "expectancy": 627.6666666666666,
    "average_win": 9086.0,
    "average_loss": -3601.5
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 10,
    "net_profit": 19149.0,
    "win_rate": 0.5,
    "profit_factor": 2.058540630182421,
    "expectancy": 1914.9,
    "average_win": 7447.8,
    "average_loss": -3618.0
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 4,
    "net_profit": 15477.0,
    "win_rate": 0.75,
    "profit_factor": 5.1382352941176475,
    "expectancy": 3869.25,
    "average_win": 6405.666666666667,
    "average_loss": -3740.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 2,
    "net_profit": 4990.0,
    "win_rate": 0.5,
    "profit_factor": 2.36041439476554,
    "expectancy": 2495.0,
    "average_win": 8658.0,
    "average_loss": -3668.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 7,
    "net_profit": 565.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.0315907184791724,
    "expectancy": 80.71428571428571,
    "average_win": 9225.0,
    "average_loss": -3577.0
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 7,
    "net_profit": -25293.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3613.285714285714,
    "average_win": null,
    "average_loss": -3613.285714285714
  },
  {
    "close_reason": "SL",
    "number_of_trades": 1,
    "net_profit": 41.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 41.0,
    "average_win": 41.0,
    "average_loss": null
  },
  {
    "close_reason": "TP",
    "number_of_trades": 5,
    "net_profit": 46284.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9256.8,
    "average_win": 9256.8,
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
    "net_profit": 9086.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9086.0,
    "average_win": 9086.0,
    "average_loss": null
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 4,
    "net_profit": -1236.0,
    "win_rate": 0.25,
    "profit_factor": 0.886240220892775,
    "expectancy": -309.0,
    "average_win": 9629.0,
    "average_loss": -3621.6666666666665
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 1,
    "net_profit": 9547.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9547.0,
    "average_win": 9547.0,
    "average_loss": null
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 7,
    "net_profit": 3635.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.2519406709176601,
    "expectancy": 519.2857142857143,
    "average_win": 6021.0,
    "average_loss": -3607.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": 14710.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 4.933155080213904,
    "expectancy": 4903.333333333333,
    "average_win": 9225.0,
    "average_loss": -3740.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 2,
    "net_profit": -7215.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3607.5,
    "average_win": null,
    "average_loss": -3607.5
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 1,
    "net_profit": -3557.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3557.0,
    "average_win": null,
    "average_loss": -3557.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 2,
    "net_profit": 18205.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9102.5,
    "average_win": 9102.5,
    "average_loss": null
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": -1111.0,
    "win_rate": 0.4,
    "profit_factor": 0.8969483350338558,
    "expectancy": -222.2,
    "average_win": 4835.0,
    "average_loss": -3593.6666666666665
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00125-2.341",
    "number_of_trades": 4,
    "net_profit": -10863.0,
    "win_rate": 0.25,
    "profit_factor": 0.00376008804108584,
    "expectancy": -2715.75,
    "average_win": 41.0,
    "average_loss": -3634.6666666666665
  },
  {
    "giveback_band": "GIVEBACK_-0.00542--0.00125",
    "number_of_trades": 5,
    "net_profit": 46284.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9256.8,
    "average_win": 9256.8,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_2.341-11.84",
    "number_of_trades": 4,
    "net_profit": -14389.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3597.25,
    "average_win": null,
    "average_loss": -3597.25
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
