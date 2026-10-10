# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 5
- MFEデータのある負けトレード数: 5
- うち一度含み益になった数: 5
- 割合: 100.00%
- 反転前の平均含み益: 2052.80

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 10
- 平均Giveback比率: 257.20%
- 中央値Giveback比率: 100.18%
- 損益ゼロ以下まで完全反転した割合: 60.00%

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

- 決済件数: 3
- 純損益: -11683.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3894.33
- 平均逆行幅（R）: 0.7781
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 3,
    "net_profit": -11683.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3894.3333333333335,
    "average_win": null,
    "average_loss": -3894.3333333333335
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 4464
- 最終Entry候補まで到達: 25
- Stage別棄却数（market_regime）: 3455
- Stage別棄却数（htf_bias）: 560
- Stage別棄却数（trend_strength_or_momentum_filter）: 286
- Stage別棄却数（setup_or_trigger）: 138
- Stage別棄却数（other）: 0

```json
{
  "ENTRY_PATTERN_NOT_FOUND": 138,
  "REGIME_NOT_TRENDING": 3455,
  "RSI_FILTERED": 245,
  "CONFIRMATION_ADX_TOO_LOW": 41,
  "TREND_NOT_ALIGNED": 560
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 10,
    "net_profit": 24487.0,
    "win_rate": 0.4,
    "profit_factor": 2.983877501417808,
    "expectancy": 2448.7,
    "average_win": 9207.5,
    "average_loss": -2468.6
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 1,
    "net_profit": 9321.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9321.0,
    "average_win": 9321.0,
    "average_loss": null
  },
  {
    "session": "NewYork",
    "number_of_trades": 1,
    "net_profit": 0.0,
    "win_rate": 0.0,
    "profit_factor": null,
    "expectancy": 0.0,
    "average_win": null,
    "average_loss": null
  },
  {
    "session": "Tokyo",
    "number_of_trades": 8,
    "net_profit": 15166.0,
    "win_rate": 0.375,
    "profit_factor": 2.228712630640849,
    "expectancy": 1895.75,
    "average_win": 9169.666666666666,
    "average_loss": -2468.6
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 2,
    "net_profit": 4953.0,
    "win_rate": 0.5,
    "profit_factor": 2.2969363707776904,
    "expectancy": 2476.5,
    "average_win": 8772.0,
    "average_loss": -3819.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 4,
    "net_profit": 4740.0,
    "win_rate": 0.25,
    "profit_factor": 2.0685302073940486,
    "expectancy": 1185.0,
    "average_win": 9176.0,
    "average_loss": -2218.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 2,
    "net_profit": 9298.0,
    "win_rate": 0.5,
    "profit_factor": 405.2608695652174,
    "expectancy": 4649.0,
    "average_win": 9321.0,
    "average_loss": -23.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 1,
    "net_profit": -4065.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4065.0,
    "average_win": null,
    "average_loss": -4065.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 1,
    "net_profit": 9561.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9561.0,
    "average_win": 9561.0,
    "average_loss": null
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_40.54-53.27",
    "number_of_trades": 4,
    "net_profit": 13860.0,
    "win_rate": 0.5,
    "profit_factor": 4.390410958904109,
    "expectancy": 3465.0,
    "average_win": 8974.0,
    "average_loss": -2044.0
  },
  {
    "atr_band": "ATR_53.27-78.67",
    "number_of_trades": 2,
    "net_profit": -4436.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2218.0,
    "average_win": null,
    "average_loss": -2218.0
  },
  {
    "atr_band": "ATR_78.67-127.7",
    "number_of_trades": 4,
    "net_profit": 15063.0,
    "win_rate": 0.5,
    "profit_factor": 4.944226237234878,
    "expectancy": 3765.75,
    "average_win": 9441.0,
    "average_loss": -3819.0
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.23-41.59",
    "number_of_trades": 4,
    "net_profit": 18245.0,
    "win_rate": 0.5,
    "profit_factor": 29.642072213500786,
    "expectancy": 4561.25,
    "average_win": 9441.0,
    "average_loss": -637.0
  },
  {
    "adx_band": "ADX_41.59-48.65",
    "number_of_trades": 2,
    "net_profit": -4088.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2044.0,
    "average_win": null,
    "average_loss": -2044.0
  },
  {
    "adx_band": "ADX_48.65-60.11",
    "number_of_trades": 4,
    "net_profit": 10330.0,
    "win_rate": 0.5,
    "profit_factor": 2.3559989498556053,
    "expectancy": 2582.5,
    "average_win": 8974.0,
    "average_loss": -3809.0
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_1.017-2.818",
    "number_of_trades": 3,
    "net_profit": -11683.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3894.3333333333335,
    "average_win": null,
    "average_loss": -3894.3333333333335
  },
  {
    "hold_time_band": "HOLD_H_12.01-27.46",
    "number_of_trades": 4,
    "net_profit": 18245.0,
    "win_rate": 0.5,
    "profit_factor": 29.642072213500786,
    "expectancy": 4561.25,
    "average_win": 9441.0,
    "average_loss": -637.0
  },
  {
    "hold_time_band": "HOLD_H_2.818-12.01",
    "number_of_trades": 3,
    "net_profit": 17925.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 780.3478260869565,
    "expectancy": 5975.0,
    "average_win": 8974.0,
    "average_loss": -23.0
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_1884-8630",
    "number_of_trades": 3,
    "net_profit": -3822.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1274.0,
    "average_win": null,
    "average_loss": -1911.0
  },
  {
    "mfe_band": "MFE_328-1884",
    "number_of_trades": 3,
    "net_profit": -8521.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2840.3333333333335,
    "average_win": null,
    "average_loss": -2840.3333333333335
  },
  {
    "mfe_band": "MFE_8630-9372",
    "number_of_trades": 4,
    "net_profit": 36830.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9207.5,
    "average_win": 9207.5,
    "average_loss": null
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1886--1266",
    "number_of_trades": 4,
    "net_profit": 18859.0,
    "win_rate": 0.5,
    "profit_factor": 820.9565217391304,
    "expectancy": 4714.75,
    "average_win": 9441.0,
    "average_loss": -23.0
  },
  {
    "mae_band": "MAE_-3769--1886",
    "number_of_trades": 2,
    "net_profit": 17948.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8974.0,
    "average_win": 8974.0,
    "average_loss": null
  },
  {
    "mae_band": "MAE_-4065--3769",
    "number_of_trades": 4,
    "net_profit": -12320.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3080.0,
    "average_win": null,
    "average_loss": -3080.0
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 1,
    "net_profit": 0.0,
    "win_rate": 0.0,
    "profit_factor": null,
    "expectancy": 0.0,
    "average_win": null,
    "average_loss": null
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 9,
    "net_profit": 24487.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 2.983877501417808,
    "expectancy": 2720.777777777778,
    "average_win": 9207.5,
    "average_loss": -2468.6
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 2,
    "net_profit": 9153.0,
    "win_rate": 0.5,
    "profit_factor": 398.95652173913044,
    "expectancy": 4576.5,
    "average_win": 9176.0,
    "average_loss": -23.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 8,
    "net_profit": 15334.0,
    "win_rate": 0.375,
    "profit_factor": 2.244642857142857,
    "expectancy": 1916.75,
    "average_win": 9218.0,
    "average_loss": -3080.0
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 4,
    "net_profit": -12320.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3080.0,
    "average_win": null,
    "average_loss": -3080.0
  },
  {
    "close_reason": "SL",
    "number_of_trades": 2,
    "net_profit": -23.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -11.5,
    "average_win": null,
    "average_loss": -23.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 4,
    "net_profit": 36830.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9207.5,
    "average_win": 9207.5,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 2,
    "net_profit": 8772.0,
    "win_rate": 0.5,
    "profit_factor": null,
    "expectancy": 4386.0,
    "average_win": 8772.0,
    "average_loss": null
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 1,
    "net_profit": -637.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -637.0,
    "average_win": null,
    "average_loss": -637.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 7,
    "net_profit": 16352.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.3968904835127285,
    "expectancy": 2336.0,
    "average_win": 9352.666666666666,
    "average_loss": -2926.5
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 4,
    "net_profit": 23835.0,
    "win_rate": 0.75,
    "profit_factor": 7.241162608012568,
    "expectancy": 5958.75,
    "average_win": 9218.0,
    "average_loss": -3819.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 2,
    "net_profit": -4436.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2218.0,
    "average_win": null,
    "average_loss": -2218.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 1,
    "net_profit": -23.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -23.0,
    "average_win": null,
    "average_loss": -23.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": 5111.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.257318573185732,
    "expectancy": 1703.6666666666667,
    "average_win": 9176.0,
    "average_loss": -4065.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00975-1.671",
    "number_of_trades": 3,
    "net_profit": 9298.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 405.2608695652174,
    "expectancy": 3099.3333333333335,
    "average_win": 9321.0,
    "average_loss": -23.0
  },
  {
    "giveback_band": "GIVEBACK_-0.025--0.00975",
    "number_of_trades": 3,
    "net_profit": 27509.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9169.666666666666,
    "average_win": 9169.666666666666,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1.671-12.64",
    "number_of_trades": 4,
    "net_profit": -12320.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3080.0,
    "average_win": null,
    "average_loss": -3080.0
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
