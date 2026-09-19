# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 13
- MFEデータのある負けトレード数: 13
- うち一度含み益になった数: 13
- 割合: 100.00%
- 反転前の平均含み益: 2612.38

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 24
- 平均Giveback比率: 282.58%
- 中央値Giveback比率: 102.79%
- 損益ゼロ以下まで完全反転した割合: 66.67%

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

- 決済件数: 9
- 純損益: -33113.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3679.22
- 平均逆行幅（R）: 0.7625
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 9,
    "net_profit": -33113.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3679.222222222222,
    "average_win": null,
    "average_loss": -3679.222222222222
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6323
- 最終Entry候補まで到達: 52
- Stage別棄却数（market_regime）: 5289
- Stage別棄却数（htf_bias）: 102
- Stage別棄却数（trend_strength_or_momentum_filter）: 459
- Stage別棄却数（setup_or_trigger）: 421
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5289,
  "ENTRY_PATTERN_NOT_FOUND": 421,
  "RSI_FILTERED": 417,
  "TREND_NOT_ALIGNED": 102,
  "CONFIRMATION_ADX_TOO_LOW": 42
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 20,
    "net_profit": -7684.0,
    "win_rate": 0.2,
    "profit_factor": 0.784749845929744,
    "expectancy": -384.2,
    "average_win": 7003.5,
    "average_loss": -2746.0
  },
  {
    "direction": "SELL",
    "number_of_trades": 4,
    "net_profit": 22105.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 5526.25,
    "average_win": 5526.25,
    "average_loss": null
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 10,
    "net_profit": 5812.0,
    "win_rate": 0.3,
    "profit_factor": 1.4784326638129732,
    "expectancy": 581.2,
    "average_win": 5986.666666666667,
    "average_loss": -2429.6
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 4,
    "net_profit": -1498.0,
    "win_rate": 0.25,
    "profit_factor": 0.8634706525701786,
    "expectancy": -374.5,
    "average_win": 9474.0,
    "average_loss": -3657.3333333333335
  },
  {
    "session": "NewYork",
    "number_of_trades": 6,
    "net_profit": 3127.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.3479083222073875,
    "expectancy": 521.1666666666666,
    "average_win": 6057.5,
    "average_loss": -2247.0
  },
  {
    "session": "Tokyo",
    "number_of_trades": 4,
    "net_profit": 6980.0,
    "win_rate": 0.5,
    "profit_factor": 2.9442896935933147,
    "expectancy": 1745.0,
    "average_win": 5285.0,
    "average_loss": -3590.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 4,
    "net_profit": -9191.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2297.75,
    "average_win": null,
    "average_loss": -2297.75
  },
  {
    "weekday": "Mon",
    "number_of_trades": 5,
    "net_profit": -11132.0,
    "win_rate": 0.2,
    "profit_factor": 0.002419571646204857,
    "expectancy": -2226.4,
    "average_win": 27.0,
    "average_loss": -2789.75
  },
  {
    "weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": 4798.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.0904545454545453,
    "expectancy": 1599.3333333333333,
    "average_win": 9198.0,
    "average_loss": -2200.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": 18050.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": null,
    "expectancy": 6016.666666666667,
    "average_win": 9025.0,
    "average_loss": null
  },
  {
    "weekday": "Wed",
    "number_of_trades": 9,
    "net_profit": 11896.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 2.0865911582024115,
    "expectancy": 1321.7777777777778,
    "average_win": 5711.0,
    "average_loss": -3649.3333333333335
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.0951-0.168",
    "number_of_trades": 8,
    "net_profit": 10641.0,
    "win_rate": 0.375,
    "profit_factor": 2.3205510052122116,
    "expectancy": 1330.125,
    "average_win": 6233.0,
    "average_loss": -2686.0
  },
  {
    "atr_band": "ATR_0.168-0.237",
    "number_of_trades": 8,
    "net_profit": -20215.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2526.875,
    "average_win": null,
    "average_loss": -2887.8571428571427
  },
  {
    "atr_band": "ATR_0.237-0.737",
    "number_of_trades": 8,
    "net_profit": 23995.0,
    "win_rate": 0.625,
    "profit_factor": 4.231649831649832,
    "expectancy": 2999.375,
    "average_win": 6284.0,
    "average_loss": -2475.0
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.45-41.31",
    "number_of_trades": 8,
    "net_profit": -11912.0,
    "win_rate": 0.125,
    "profit_factor": 0.4230638833728871,
    "expectancy": -1489.0,
    "average_win": 8735.0,
    "average_loss": -2949.5714285714284
  },
  {
    "adx_band": "ADX_41.31-44.03",
    "number_of_trades": 8,
    "net_profit": 16590.0,
    "win_rate": 0.375,
    "profit_factor": 2.4550078933520436,
    "expectancy": 2073.75,
    "average_win": 9330.666666666666,
    "average_loss": -2850.5
  },
  {
    "adx_band": "ADX_44.03-56.71",
    "number_of_trades": 8,
    "net_profit": 9743.0,
    "win_rate": 0.5,
    "profit_factor": 3.6700465881063304,
    "expectancy": 1217.875,
    "average_win": 3348.0,
    "average_loss": -1824.5
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.5-4.417",
    "number_of_trades": 8,
    "net_profit": -19246.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2405.75,
    "average_win": null,
    "average_loss": -3207.6666666666665
  },
  {
    "hold_time_band": "HOLD_H_15.04-64.11",
    "number_of_trades": 8,
    "net_profit": 30012.0,
    "win_rate": 0.75,
    "profit_factor": 19.887350534927627,
    "expectancy": 3751.5,
    "average_win": 5266.833333333333,
    "average_loss": -794.5
  },
  {
    "hold_time_band": "HOLD_H_4.417-15.04",
    "number_of_trades": 8,
    "net_profit": 3655.0,
    "win_rate": 0.25,
    "profit_factor": 1.2459126690439346,
    "expectancy": 456.875,
    "average_win": 9259.0,
    "average_loss": -2972.6
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_2631-7396",
    "number_of_trades": 8,
    "net_profit": -6502.0,
    "win_rate": 0.125,
    "profit_factor": 0.16124871001031993,
    "expectancy": -812.75,
    "average_win": 1250.0,
    "average_loss": -1938.0
  },
  {
    "mfe_band": "MFE_322-2631",
    "number_of_trades": 8,
    "net_profit": -27322.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3415.25,
    "average_win": null,
    "average_loss": -3415.25
  },
  {
    "mfe_band": "MFE_7396-9454",
    "number_of_trades": 8,
    "net_profit": 48245.0,
    "win_rate": 0.875,
    "profit_factor": 78.31570512820512,
    "expectancy": 6030.625,
    "average_win": 6981.285714285715,
    "average_loss": -624.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1282--98",
    "number_of_trades": 8,
    "net_profit": 20318.0,
    "win_rate": 0.5,
    "profit_factor": 20.880626223091976,
    "expectancy": 2539.75,
    "average_win": 5335.0,
    "average_loss": -340.6666666666667
  },
  {
    "mae_band": "MAE_-3589--1282",
    "number_of_trades": 8,
    "net_profit": 21655.0,
    "win_rate": 0.5,
    "profit_factor": 4.039724873666479,
    "expectancy": 2706.875,
    "average_win": 7194.75,
    "average_loss": -3562.0
  },
  {
    "mae_band": "MAE_-4993--3589",
    "number_of_trades": 8,
    "net_profit": -27552.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3444.0,
    "average_win": null,
    "average_loss": -3444.0
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 6,
    "net_profit": 18515.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 6.157381615598886,
    "expectancy": 3085.8333333333335,
    "average_win": 5526.25,
    "average_loss": -3590.0
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 18,
    "net_profit": -4094.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.8724928366762178,
    "expectancy": -227.44444444444446,
    "average_win": 7003.5,
    "average_loss": -2675.6666666666665
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 3,
    "net_profit": 10539.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 406.34615384615387,
    "expectancy": 3513.0,
    "average_win": 5282.5,
    "average_loss": -26.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 7,
    "net_profit": -1651.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.851954806312769,
    "expectancy": -235.85714285714286,
    "average_win": 4750.5,
    "average_loss": -3717.3333333333335
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 14,
    "net_profit": 5533.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.225652528548124,
    "expectancy": 395.2142857142857,
    "average_win": 7513.25,
    "average_loss": -2724.4444444444443
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 12,
    "net_profit": -30626.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.11679547814050063,
    "expectancy": -2552.1666666666665,
    "average_win": 2025.0,
    "average_loss": -3467.6
  },
  {
    "close_reason": "SL",
    "number_of_trades": 7,
    "net_profit": -995.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.026418786692759294,
    "expectancy": -142.14285714285714,
    "average_win": 27.0,
    "average_loss": -340.6666666666667
  },
  {
    "close_reason": "TP",
    "number_of_trades": 5,
    "net_profit": 46042.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9208.4,
    "average_win": 9208.4,
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
    "net_profit": 9237.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.9665166893376582,
    "expectancy": 1319.5714285714287,
    "average_win": 9397.0,
    "average_loss": -2389.25
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 5,
    "net_profit": -11052.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2210.4,
    "average_win": null,
    "average_loss": -2763.0
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 8,
    "net_profit": 20606.0,
    "win_rate": 0.5,
    "profit_factor": 3.610998479472884,
    "expectancy": 2575.75,
    "average_win": 7124.5,
    "average_loss": -2630.6666666666665
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 4,
    "net_profit": -4370.0,
    "win_rate": 0.5,
    "profit_factor": 0.3928025566208142,
    "expectancy": -1092.5,
    "average_win": 1413.5,
    "average_loss": -3598.5
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": -4802.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.3683241252302026,
    "expectancy": -1600.6666666666667,
    "average_win": 2800.0,
    "average_loss": -3801.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 4,
    "net_profit": -5551.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1387.75,
    "average_win": null,
    "average_loss": -1387.75
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 5,
    "net_profit": 15522.0,
    "win_rate": 0.6,
    "profit_factor": 4.527727272727272,
    "expectancy": 3104.4,
    "average_win": 6640.666666666667,
    "average_loss": -2200.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": -7170.0,
    "win_rate": 0.25,
    "profit_factor": 0.003751563151313047,
    "expectancy": -1792.5,
    "average_win": 27.0,
    "average_loss": -3598.5
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 8,
    "net_profit": 16422.0,
    "win_rate": 0.375,
    "profit_factor": 2.5,
    "expectancy": 2052.75,
    "average_win": 9123.333333333334,
    "average_loss": -3649.3333333333335
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0173-0.999",
    "number_of_trades": 8,
    "net_profit": 50119.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 6264.875,
    "average_win": 6264.875,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.999-2.353",
    "number_of_trades": 8,
    "net_profit": -8352.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1044.0,
    "average_win": null,
    "average_loss": -1670.4
  },
  {
    "giveback_band": "GIVEBACK_2.353-12.87",
    "number_of_trades": 8,
    "net_profit": -27346.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3418.25,
    "average_win": null,
    "average_loss": -3418.25
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
