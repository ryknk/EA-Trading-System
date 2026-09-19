# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 19
- MFEデータのある負けトレード数: 19
- うち一度含み益になった数: 18
- 割合: 94.74%
- 反転前の平均含み益: 2845.56

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 26
- 平均Giveback比率: 305.34%
- 中央値Giveback比率: 193.32%
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

- 決済件数: 16
- 純損益: -58484.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3655.25
- 平均逆行幅（R）: 0.7551
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 10,
    "net_profit": -36820.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3682.0,
    "average_win": null,
    "average_loss": -3682.0
  },
  "SELL": {
    "number_of_trades": 6,
    "net_profit": -21664.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3610.6666666666665,
    "average_win": null,
    "average_loss": -3610.6666666666665
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6240
- 最終Entry候補まで到達: 57
- Stage別棄却数（market_regime）: 5087
- Stage別棄却数（htf_bias）: 270
- Stage別棄却数（trend_strength_or_momentum_filter）: 421
- Stage別棄却数（setup_or_trigger）: 405
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5087,
  "RSI_FILTERED": 392,
  "ENTRY_PATTERN_NOT_FOUND": 405,
  "TREND_NOT_ALIGNED": 270,
  "CONFIRMATION_ADX_TOO_LOW": 29
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 16,
    "net_profit": -8520.0,
    "win_rate": 0.25,
    "profit_factor": 0.7687233638263796,
    "expectancy": -532.5,
    "average_win": 7079.75,
    "average_loss": -3349.0
  },
  {
    "direction": "SELL",
    "number_of_trades": 11,
    "net_profit": -3445.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.846061039367264,
    "expectancy": -313.1818181818182,
    "average_win": 9467.0,
    "average_loss": -2797.375
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 8,
    "net_profit": 9415.0,
    "win_rate": 0.375,
    "profit_factor": 1.5085890233362143,
    "expectancy": 1176.875,
    "average_win": 9309.0,
    "average_loss": -3702.4
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 6,
    "net_profit": 2208.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2957406911331368,
    "expectancy": 368.0,
    "average_win": 4837.0,
    "average_loss": -2488.6666666666665
  },
  {
    "session": "NewYork",
    "number_of_trades": 3,
    "net_profit": -7693.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2564.3333333333335,
    "average_win": null,
    "average_loss": -2564.3333333333335
  },
  {
    "session": "Tokyo",
    "number_of_trades": 10,
    "net_profit": -15895.0,
    "win_rate": 0.1,
    "profit_factor": 0.3778134418914158,
    "expectancy": -1589.5,
    "average_win": 9652.0,
    "average_loss": -3193.375
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 8,
    "net_profit": -22298.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2787.25,
    "average_win": null,
    "average_loss": -2787.25
  },
  {
    "weekday": "Mon",
    "number_of_trades": 6,
    "net_profit": 24096.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 6.730321046373365,
    "expectancy": 4016.0,
    "average_win": 7075.25,
    "average_loss": -2102.5
  },
  {
    "weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": 6072.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.69608938547486,
    "expectancy": 2024.0,
    "average_win": 9652.0,
    "average_loss": -3580.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 7,
    "net_profit": -8797.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5138973310493452,
    "expectancy": -1256.7142857142858,
    "average_win": 9300.0,
    "average_loss": -3619.4
  },
  {
    "weekday": "Wed",
    "number_of_trades": 3,
    "net_profit": -11038.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3679.3333333333335,
    "average_win": null,
    "average_loss": -3679.3333333333335
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.121-0.148",
    "number_of_trades": 9,
    "net_profit": 13781.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.9260180083322134,
    "expectancy": 1531.2222222222222,
    "average_win": 9554.333333333334,
    "average_loss": -2976.4
  },
  {
    "atr_band": "ATR_0.148-0.185",
    "number_of_trades": 9,
    "net_profit": -448.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.9764582238570678,
    "expectancy": -49.77777777777778,
    "average_win": 9291.0,
    "average_loss": -3171.6666666666665
  },
  {
    "atr_band": "ATR_0.185-0.475",
    "number_of_trades": 9,
    "net_profit": -25298.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.00031613056192207384,
    "expectancy": -2810.8888888888887,
    "average_win": 8.0,
    "average_loss": -3163.25
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.13-42.27",
    "number_of_trades": 9,
    "net_profit": 670.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 1.0366560892876682,
    "expectancy": 74.44444444444444,
    "average_win": 9474.0,
    "average_loss": -3046.3333333333335
  },
  {
    "adx_band": "ADX_42.27-44.91",
    "number_of_trades": 9,
    "net_profit": -9734.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.48881420018905575,
    "expectancy": -1081.5555555555557,
    "average_win": 4654.0,
    "average_loss": -2720.285714285714
  },
  {
    "adx_band": "ADX_44.91-53.65",
    "number_of_trades": 9,
    "net_profit": -2901.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.8675221481413827,
    "expectancy": -322.3333333333333,
    "average_win": 9498.5,
    "average_loss": -3649.6666666666665
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.761-4.386",
    "number_of_trades": 9,
    "net_profit": -6828.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.7352872761107234,
    "expectancy": -758.6666666666666,
    "average_win": 9483.0,
    "average_loss": -3684.8571428571427
  },
  {
    "hold_time_band": "HOLD_H_4.386-7.899",
    "number_of_trades": 9,
    "net_profit": -26224.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2913.777777777778,
    "average_win": null,
    "average_loss": -2913.777777777778
  },
  {
    "hold_time_band": "HOLD_H_7.899-62.55",
    "number_of_trades": 9,
    "net_profit": 21087.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 3.92875,
    "expectancy": 2343.0,
    "average_win": 7071.75,
    "average_loss": -2400.0
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-0.001-2086",
    "number_of_trades": 9,
    "net_profit": -33031.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3670.1111111111113,
    "average_win": null,
    "average_loss": -3670.1111111111113
  },
  {
    "mfe_band": "MFE_2086-5702",
    "number_of_trades": 9,
    "net_profit": -26058.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2895.3333333333335,
    "average_win": null,
    "average_loss": -3257.25
  },
  {
    "mfe_band": "MFE_5702-9999",
    "number_of_trades": 9,
    "net_profit": 47124.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 366.30232558139534,
    "expectancy": 5236.0,
    "average_win": 7875.5,
    "average_loss": -64.5
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2787--119",
    "number_of_trades": 9,
    "net_profit": 37237.0,
    "win_rate": 0.5555555555555556,
    "profit_factor": 51.73160762942779,
    "expectancy": 4137.444444444444,
    "average_win": 7594.2,
    "average_loss": -244.66666666666666
  },
  {
    "mae_band": "MAE_-3630--2787",
    "number_of_trades": 8,
    "net_profit": -11919.0,
    "win_rate": 0.125,
    "profit_factor": 0.4378095372859771,
    "expectancy": -1489.875,
    "average_win": 9282.0,
    "average_loss": -3533.5
  },
  {
    "mae_band": "MAE_-3800--3630",
    "number_of_trades": 10,
    "net_profit": -37283.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3728.3,
    "average_win": null,
    "average_loss": -3728.3
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 13,
    "net_profit": -10693.0,
    "win_rate": 0.15384615384615385,
    "profit_factor": 0.6390792182806224,
    "expectancy": -822.5384615384615,
    "average_win": 9467.0,
    "average_loss": -2962.7
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 14,
    "net_profit": -1272.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.9570139569463688,
    "expectancy": -90.85714285714286,
    "average_win": 7079.75,
    "average_loss": -3287.8888888888887
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 1,
    "net_profit": -110.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -110.0,
    "average_win": null,
    "average_loss": -110.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 1,
    "net_profit": 9282.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9282.0,
    "average_win": 9282.0,
    "average_loss": null
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 25,
    "net_profit": -21137.0,
    "win_rate": 0.2,
    "profit_factor": 0.6424003518982202,
    "expectancy": -845.48,
    "average_win": 7594.2,
    "average_loss": -3283.777777777778
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 16,
    "net_profit": -58484.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3655.25,
    "average_win": null,
    "average_loss": -3655.25
  },
  {
    "close_reason": "SL",
    "number_of_trades": 6,
    "net_profit": -726.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.010899182561307902,
    "expectancy": -121.0,
    "average_win": 8.0,
    "average_loss": -244.66666666666666
  },
  {
    "close_reason": "TP",
    "number_of_trades": 5,
    "net_profit": 47245.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9449.0,
    "average_win": 9449.0,
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
    "net_profit": -5519.0,
    "win_rate": 0.2,
    "profit_factor": 0.6271197892034323,
    "expectancy": -1103.8,
    "average_win": 9282.0,
    "average_loss": -3700.25
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 7,
    "net_profit": -9330.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.499194847020934,
    "expectancy": -1332.857142857143,
    "average_win": 9300.0,
    "average_loss": -3105.0
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 9,
    "net_profit": 1635.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.092419874512464,
    "expectancy": 181.66666666666666,
    "average_win": 6442.0,
    "average_loss": -3538.2
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 6,
    "net_profit": 1249.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 1.1542737154150198,
    "expectancy": 208.16666666666666,
    "average_win": 9345.0,
    "average_loss": -2024.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 7,
    "net_profit": -22188.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3169.714285714286,
    "average_win": null,
    "average_loss": -3169.714285714286
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 3,
    "net_profit": 5956.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.605390835579515,
    "expectancy": 1985.3333333333333,
    "average_win": 9666.0,
    "average_loss": -1855.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": 6072.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.69608938547486,
    "expectancy": 2024.0,
    "average_win": 9652.0,
    "average_loss": -3580.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 11,
    "net_profit": 9233.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 1.4936905143834884,
    "expectancy": 839.3636363636364,
    "average_win": 6983.75,
    "average_loss": -3117.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 3,
    "net_profit": -11038.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3679.3333333333335,
    "average_win": null,
    "average_loss": -3679.3333333333335
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00424-1.006",
    "number_of_trades": 9,
    "net_profit": 47234.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 2487.0,
    "expectancy": 5248.222222222223,
    "average_win": 7875.5,
    "average_loss": -19.0
  },
  {
    "giveback_band": "GIVEBACK_1.006-2.582",
    "number_of_trades": 8,
    "net_profit": -22424.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2803.0,
    "average_win": null,
    "average_loss": -2803.0
  },
  {
    "giveback_band": "GIVEBACK_2.582-16.82",
    "number_of_trades": 9,
    "net_profit": -32994.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3666.0,
    "average_win": null,
    "average_loss": -3666.0
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
