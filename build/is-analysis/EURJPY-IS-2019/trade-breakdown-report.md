# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 16
- MFEデータのある負けトレード数: 16
- うち一度含み益になった数: 16
- 割合: 100.00%
- 反転前の平均含み益: 2470.62

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 22
- 平均Giveback比率: 454.99%
- 中央値Giveback比率: 206.42%
- 損益ゼロ以下まで完全反転した割合: 81.82%

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

- 決済件数: 13
- 純損益: -48109.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3700.69
- 平均逆行幅（R）: 0.7593
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "SELL": {
    "number_of_trades": 13,
    "net_profit": -48109.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3700.6923076923076,
    "average_win": null,
    "average_loss": -3700.6923076923076
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6215
- 最終Entry候補まで到達: 33
- Stage別棄却数（market_regime）: 5062
- Stage別棄却数（htf_bias）: 325
- Stage別棄却数（trend_strength_or_momentum_filter）: 448
- Stage別棄却数（setup_or_trigger）: 347
- Stage別棄却数（other）: 0

```json
{
  "ENTRY_PATTERN_NOT_FOUND": 347,
  "REGIME_NOT_TRENDING": 5062,
  "RSI_FILTERED": 378,
  "CONFIRMATION_ADX_TOO_LOW": 70,
  "TREND_NOT_ALIGNED": 325
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 1,
    "net_profit": 9117.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9117.0,
    "average_win": 9117.0,
    "average_loss": null
  },
  {
    "direction": "SELL",
    "number_of_trades": 21,
    "net_profit": -20179.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5836892162323863,
    "expectancy": -960.9047619047619,
    "average_win": 9430.666666666666,
    "average_loss": -3029.4375
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 5,
    "net_profit": -11123.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2224.6,
    "average_win": null,
    "average_loss": -2780.75
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": 13073.0,
    "win_rate": 0.375,
    "profit_factor": 1.8871471226927252,
    "expectancy": 1634.125,
    "average_win": 9269.666666666666,
    "average_loss": -3684.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 3,
    "net_profit": -7405.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2468.3333333333335,
    "average_win": null,
    "average_loss": -2468.3333333333335
  },
  {
    "session": "Tokyo",
    "number_of_trades": 6,
    "net_profit": -5607.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.6312882225290984,
    "expectancy": -934.5,
    "average_win": 9600.0,
    "average_loss": -3041.4
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 4,
    "net_profit": 9138.0,
    "win_rate": 0.25,
    "profit_factor": 26.243093922651934,
    "expectancy": 2284.5,
    "average_win": 9500.0,
    "average_loss": -120.66666666666667
  },
  {
    "weekday": "Mon",
    "number_of_trades": 5,
    "net_profit": -2249.0,
    "win_rate": 0.2,
    "profit_factor": 0.8021291571353159,
    "expectancy": -449.8,
    "average_win": 9117.0,
    "average_loss": -3788.6666666666665
  },
  {
    "weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": 1638.0,
    "win_rate": 0.25,
    "profit_factor": 1.2168387609213662,
    "expectancy": 409.5,
    "average_win": 9192.0,
    "average_loss": -3777.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": 2138.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2865183596890915,
    "expectancy": 712.6666666666666,
    "average_win": 9600.0,
    "average_loss": -3731.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 6,
    "net_profit": -21727.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3621.1666666666665,
    "average_win": null,
    "average_loss": -3621.1666666666665
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.0909-0.128",
    "number_of_trades": 8,
    "net_profit": 26014.0,
    "win_rate": 0.5,
    "profit_factor": 3.282931110136025,
    "expectancy": 3251.75,
    "average_win": 9352.25,
    "average_loss": -2848.75
  },
  {
    "atr_band": "ATR_0.128-0.149",
    "number_of_trades": 6,
    "net_profit": -14565.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2427.5,
    "average_win": null,
    "average_loss": -3641.25
  },
  {
    "atr_band": "ATR_0.149-0.255",
    "number_of_trades": 8,
    "net_profit": -22511.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2813.875,
    "average_win": null,
    "average_loss": -2813.875
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.16-43.22",
    "number_of_trades": 8,
    "net_profit": -25853.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3231.625,
    "average_win": null,
    "average_loss": -3693.285714285714
  },
  {
    "adx_band": "ADX_43.22-47.97",
    "number_of_trades": 6,
    "net_profit": -1825.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.8388520971302428,
    "expectancy": -304.1666666666667,
    "average_win": 9500.0,
    "average_loss": -2265.0
  },
  {
    "adx_band": "ADX_47.97-66.57",
    "number_of_trades": 8,
    "net_profit": 16616.0,
    "win_rate": 0.375,
    "profit_factor": 2.4713539360665897,
    "expectancy": 2077.0,
    "average_win": 9303.0,
    "average_loss": -2823.25
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.743-3.883",
    "number_of_trades": 7,
    "net_profit": -8759.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5202913631633714,
    "expectancy": -1251.2857142857142,
    "average_win": 9500.0,
    "average_loss": -3651.8
  },
  {
    "hold_time_band": "HOLD_H_3.883-8.854",
    "number_of_trades": 7,
    "net_profit": -8865.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5199025182778229,
    "expectancy": -1266.4285714285713,
    "average_win": 9600.0,
    "average_loss": -3693.0
  },
  {
    "hold_time_band": "HOLD_H_8.854-80.45",
    "number_of_trades": 8,
    "net_profit": 6562.0,
    "win_rate": 0.25,
    "profit_factor": 1.5586107091172214,
    "expectancy": 820.25,
    "average_win": 9154.5,
    "average_loss": -1957.8333333333333
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_112-1560",
    "number_of_trades": 7,
    "net_profit": -25548.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3649.714285714286,
    "average_win": null,
    "average_loss": -3649.714285714286
  },
  {
    "mfe_band": "MFE_1560-5371",
    "number_of_trades": 7,
    "net_profit": -22561.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3223.0,
    "average_win": null,
    "average_loss": -3760.1666666666665
  },
  {
    "mfe_band": "MFE_5371-9525",
    "number_of_trades": 8,
    "net_profit": 37047.0,
    "win_rate": 0.5,
    "profit_factor": 103.33977900552486,
    "expectancy": 4630.875,
    "average_win": 9352.25,
    "average_loss": -120.66666666666667
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-3408--170",
    "number_of_trades": 8,
    "net_profit": 27855.0,
    "win_rate": 0.375,
    "profit_factor": 77.9475138121547,
    "expectancy": 3481.875,
    "average_win": 9405.666666666666,
    "average_loss": -120.66666666666667
  },
  {
    "mae_band": "MAE_-3667--3408",
    "number_of_trades": 4,
    "net_profit": -1498.0,
    "win_rate": 0.25,
    "profit_factor": 0.8598690364826941,
    "expectancy": -374.5,
    "average_win": 9192.0,
    "average_loss": -3563.3333333333335
  },
  {
    "mae_band": "MAE_-3923--3667",
    "number_of_trades": 10,
    "net_profit": -37419.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3741.9,
    "average_win": null,
    "average_loss": -3741.9
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 19,
    "net_profit": -25704.0,
    "win_rate": 0.10526315789473684,
    "profit_factor": 0.4263012231050799,
    "expectancy": -1352.842105263158,
    "average_win": 9550.0,
    "average_loss": -2986.9333333333334
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 3,
    "net_profit": 14642.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 4.992909735478593,
    "expectancy": 4880.666666666667,
    "average_win": 9154.5,
    "average_loss": -3667.0
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": -3610.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1805.0,
    "average_win": null,
    "average_loss": -1805.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 1,
    "net_profit": 9117.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9117.0,
    "average_win": 9117.0,
    "average_loss": null
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 19,
    "net_profit": -16569.0,
    "win_rate": 0.15789473684210525,
    "profit_factor": 0.6306591471433985,
    "expectancy": -872.0526315789474,
    "average_win": 9430.666666666666,
    "average_loss": -3204.3571428571427
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 13,
    "net_profit": -48109.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3700.6923076923076,
    "average_win": null,
    "average_loss": -3700.6923076923076
  },
  {
    "close_reason": "SL",
    "number_of_trades": 5,
    "net_profit": -362.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -72.4,
    "average_win": null,
    "average_loss": -120.66666666666667
  },
  {
    "close_reason": "TP",
    "number_of_trades": 4,
    "net_profit": 37409.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9352.25,
    "average_win": 9352.25,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 6,
    "net_profit": -5543.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.6339562834312884,
    "expectancy": -923.8333333333334,
    "average_win": 9600.0,
    "average_loss": -3028.6
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": -5806.0,
    "win_rate": 0.125,
    "profit_factor": 0.6109361388460766,
    "expectancy": -725.75,
    "average_win": 9117.0,
    "average_loss": -2487.1666666666665
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 4,
    "net_profit": 2352.0,
    "win_rate": 0.25,
    "profit_factor": 1.3290430889759373,
    "expectancy": 588.0,
    "average_win": 9500.0,
    "average_loss": -3574.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 4,
    "net_profit": -2065.0,
    "win_rate": 0.25,
    "profit_factor": 0.816558585768855,
    "expectancy": -516.25,
    "average_win": 9192.0,
    "average_loss": -3752.3333333333335
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": 18623.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 270.8985507246377,
    "expectancy": 6207.666666666667,
    "average_win": 9346.0,
    "average_loss": -69.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 4,
    "net_profit": -3941.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -985.25,
    "average_win": null,
    "average_loss": -1313.6666666666667
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": -7554.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2518.0,
    "average_win": null,
    "average_loss": -3777.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 5,
    "net_profit": 7204.0,
    "win_rate": 0.4,
    "profit_factor": 1.6257274385477287,
    "expectancy": 1440.8,
    "average_win": 9358.5,
    "average_loss": -3837.6666666666665
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 7,
    "net_profit": -25394.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3627.714285714286,
    "average_win": null,
    "average_loss": -3627.714285714286
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00887-1.02",
    "number_of_trades": 8,
    "net_profit": 37230.0,
    "win_rate": 0.5,
    "profit_factor": 208.98882681564245,
    "expectancy": 4653.75,
    "average_win": 9352.25,
    "average_loss": -89.5
  },
  {
    "giveback_band": "GIVEBACK_1.02-3.477",
    "number_of_trades": 6,
    "net_profit": -18880.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3146.6666666666665,
    "average_win": null,
    "average_loss": -3146.6666666666665
  },
  {
    "giveback_band": "GIVEBACK_3.477-32.25",
    "number_of_trades": 8,
    "net_profit": -29412.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3676.5,
    "average_win": null,
    "average_loss": -3676.5
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
