# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 4
- MFEデータのある負けトレード数: 4
- うち一度含み益になった数: 3
- 割合: 75.00%
- 反転前の平均含み益: 3201.33

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 6
- 平均Giveback比率: 145.56%
- 中央値Giveback比率: 100.29%
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

- 決済件数: 3
- 純損益: -10915.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3638.33
- 平均逆行幅（R）: 0.7643
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 3,
    "net_profit": -10915.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3638.3333333333335,
    "average_win": null,
    "average_loss": -3638.3333333333335
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 2052
- 最終Entry候補まで到達: 17
- Stage別棄却数（market_regime）: 1662
- Stage別棄却数（htf_bias）: 186
- Stage別棄却数（trend_strength_or_momentum_filter）: 87
- Stage別棄却数（setup_or_trigger）: 100
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 1662,
  "ENTRY_PATTERN_NOT_FOUND": 100,
  "RSI_FILTERED": 61,
  "CONFIRMATION_ADX_TOO_LOW": 26,
  "TREND_NOT_ALIGNED": 186
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 7,
    "net_profit": 2038.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.1861017258697837,
    "expectancy": 291.14285714285717,
    "average_win": 6494.5,
    "average_loss": -2737.75
  }
]
```

## session別

```json
[
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 2,
    "net_profit": -7427.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3713.5,
    "average_win": null,
    "average_loss": -3713.5
  },
  {
    "session": "NewYork",
    "number_of_trades": 2,
    "net_profit": 12989.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 6494.5,
    "average_win": 6494.5,
    "average_loss": null
  },
  {
    "session": "Tokyo",
    "number_of_trades": 3,
    "net_profit": -3524.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1174.6666666666667,
    "average_win": null,
    "average_loss": -1762.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": -7065.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2355.0,
    "average_win": null,
    "average_loss": -3532.5
  },
  {
    "weekday": "Mon",
    "number_of_trades": 2,
    "net_profit": -3886.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1943.0,
    "average_win": null,
    "average_loss": -1943.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 1,
    "net_profit": 9241.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9241.0,
    "average_win": 9241.0,
    "average_loss": null
  },
  {
    "weekday": "Tue",
    "number_of_trades": 1,
    "net_profit": 3748.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 3748.0,
    "average_win": 3748.0,
    "average_loss": null
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.0001-0.0014",
    "number_of_trades": 3,
    "net_profit": 9205.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 256.69444444444446,
    "expectancy": 3068.3333333333335,
    "average_win": 9241.0,
    "average_loss": -36.0
  },
  {
    "atr_band": "ATR_0.0014-0.0016",
    "number_of_trades": 1,
    "net_profit": -3850.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3850.0,
    "average_win": null,
    "average_loss": -3850.0
  },
  {
    "atr_band": "ATR_0.0016-0.00264",
    "number_of_trades": 3,
    "net_profit": -3317.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.5305024769992923,
    "expectancy": -1105.6666666666667,
    "average_win": 3748.0,
    "average_loss": -3532.5
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_41.17-43.76",
    "number_of_trades": 3,
    "net_profit": -3613.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1204.3333333333333,
    "average_win": null,
    "average_loss": -1806.5
  },
  {
    "adx_band": "ADX_43.76-45.12",
    "number_of_trades": 2,
    "net_profit": 12989.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 6494.5,
    "average_win": 6494.5,
    "average_loss": null
  },
  {
    "adx_band": "ADX_45.12-50.53",
    "number_of_trades": 2,
    "net_profit": -7338.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3669.0,
    "average_win": null,
    "average_loss": -3669.0
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.726-10.81",
    "number_of_trades": 2,
    "net_profit": -7427.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3713.5,
    "average_win": null,
    "average_loss": -3713.5
  },
  {
    "hold_time_band": "HOLD_H_10.81-18.82",
    "number_of_trades": 2,
    "net_profit": -3488.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1744.0,
    "average_win": null,
    "average_loss": -3488.0
  },
  {
    "hold_time_band": "HOLD_H_18.82-46",
    "number_of_trades": 3,
    "net_profit": 12953.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 360.80555555555554,
    "expectancy": 4317.666666666667,
    "average_win": 6494.5,
    "average_loss": -36.0
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-67-1766",
    "number_of_trades": 3,
    "net_profit": -10915.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3638.3333333333335,
    "average_win": null,
    "average_loss": -3638.3333333333335
  },
  {
    "mfe_band": "MFE_1766-8300",
    "number_of_trades": 1,
    "net_profit": -36.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -36.0,
    "average_win": null,
    "average_loss": -36.0
  },
  {
    "mfe_band": "MFE_8300-9220",
    "number_of_trades": 3,
    "net_profit": 12989.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": null,
    "expectancy": 4329.666666666667,
    "average_win": 6494.5,
    "average_loss": null
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2409--382",
    "number_of_trades": 3,
    "net_profit": 3712.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 104.11111111111111,
    "expectancy": 1237.3333333333333,
    "average_win": 3748.0,
    "average_loss": -36.0
  },
  {
    "mae_band": "MAE_-3506--2409",
    "number_of_trades": 1,
    "net_profit": 9241.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9241.0,
    "average_win": 9241.0,
    "average_loss": null
  },
  {
    "mae_band": "MAE_-3950--3506",
    "number_of_trades": 3,
    "net_profit": -10915.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3638.3333333333335,
    "average_win": null,
    "average_loss": -3638.3333333333335
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 1,
    "net_profit": -36.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -36.0,
    "average_win": null,
    "average_loss": -36.0
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 6,
    "net_profit": 2074.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.1900137425561155,
    "expectancy": 345.6666666666667,
    "average_win": 6494.5,
    "average_loss": -3638.3333333333335
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": 260.0,
    "win_rate": 0.5,
    "profit_factor": 1.0745412844036697,
    "expectancy": 130.0,
    "average_win": 3748.0,
    "average_loss": -3488.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 5,
    "net_profit": 1778.0,
    "win_rate": 0.2,
    "profit_factor": 1.2382419938362588,
    "expectancy": 355.6,
    "average_win": 9241.0,
    "average_loss": -2487.6666666666665
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 4,
    "net_profit": -7167.0,
    "win_rate": 0.25,
    "profit_factor": 0.3433806688043976,
    "expectancy": -1791.75,
    "average_win": 3748.0,
    "average_loss": -3638.3333333333335
  },
  {
    "close_reason": "SL",
    "number_of_trades": 2,
    "net_profit": -36.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -18.0,
    "average_win": null,
    "average_loss": -36.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 1,
    "net_profit": 9241.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9241.0,
    "average_win": 9241.0,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 3,
    "net_profit": 1903.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2593349686563096,
    "expectancy": 634.3333333333334,
    "average_win": 9241.0,
    "average_loss": -3669.0
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 3,
    "net_profit": 171.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.0478054235392786,
    "expectancy": 57.0,
    "average_win": 3748.0,
    "average_loss": -3577.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 1,
    "net_profit": -36.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -36.0,
    "average_win": null,
    "average_loss": -36.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 4,
    "net_profit": 2176.0,
    "win_rate": 0.25,
    "profit_factor": 1.307997169143666,
    "expectancy": 544.0,
    "average_win": 9241.0,
    "average_loss": -3532.5
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 2,
    "net_profit": -3886.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1943.0,
    "average_win": null,
    "average_loss": -1943.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 1,
    "net_profit": 3748.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 3748.0,
    "average_win": 3748.0,
    "average_loss": null
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00328-0.849",
    "number_of_trades": 2,
    "net_profit": 12989.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 6494.5,
    "average_win": 6494.5,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.849-1.662",
    "number_of_trades": 2,
    "net_profit": -36.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -18.0,
    "average_win": null,
    "average_loss": -36.0
  },
  {
    "giveback_band": "GIVEBACK_1.662-3.207",
    "number_of_trades": 2,
    "net_profit": -7065.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3532.5,
    "average_win": null,
    "average_loss": -3532.5
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
