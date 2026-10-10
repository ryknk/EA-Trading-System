# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 13
- MFEデータのある負けトレード数: 13
- うち一度含み益になった数: 10
- 割合: 76.92%
- 反転前の平均含み益: 2083.30

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 14
- 平均Giveback比率: 435.13%
- 中央値Giveback比率: 244.72%
- 損益ゼロ以下まで完全反転した割合: 78.57%

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

- 決済件数: 10
- 純損益: -36343.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3634.30
- 平均逆行幅（R）: 0.7575
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 4,
    "net_profit": -14939.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3734.75,
    "average_win": null,
    "average_loss": -3734.75
  },
  "SELL": {
    "number_of_trades": 6,
    "net_profit": -21404.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3567.3333333333335,
    "average_win": null,
    "average_loss": -3567.3333333333335
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6337
- 最終Entry候補まで到達: 32
- Stage別棄却数（market_regime）: 5399
- Stage別棄却数（htf_bias）: 172
- Stage別棄却数（trend_strength_or_momentum_filter）: 451
- Stage別棄却数（setup_or_trigger）: 283
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5399,
  "RSI_FILTERED": 407,
  "ENTRY_PATTERN_NOT_FOUND": 283,
  "CONFIRMATION_ADX_TOO_LOW": 44,
  "TREND_NOT_ALIGNED": 172
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 7,
    "net_profit": 2292.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.1448615851346227,
    "expectancy": 327.42857142857144,
    "average_win": 9057.0,
    "average_loss": -3164.4
  },
  {
    "direction": "SELL",
    "number_of_trades": 10,
    "net_profit": -23154.0,
    "win_rate": 0.1,
    "profit_factor": 0.28640552285265203,
    "expectancy": -2315.4,
    "average_win": 9293.0,
    "average_loss": -4055.875
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 3,
    "net_profit": 1927.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2616073852837362,
    "expectancy": 642.3333333333334,
    "average_win": 9293.0,
    "average_loss": -3683.0
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 3,
    "net_profit": -10707.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3569.0,
    "average_win": null,
    "average_loss": -3569.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 6,
    "net_profit": -7900.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.5247834456207893,
    "expectancy": -1316.6666666666667,
    "average_win": 8724.0,
    "average_loss": -3324.8
  },
  {
    "session": "Tokyo",
    "number_of_trades": 5,
    "net_profit": -4182.0,
    "win_rate": 0.2,
    "profit_factor": 0.6918656056587091,
    "expectancy": -836.4,
    "average_win": 9390.0,
    "average_loss": -4524.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": 5665.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.561466372657111,
    "expectancy": 1888.3333333333333,
    "average_win": 9293.0,
    "average_loss": -3628.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 3,
    "net_profit": -436.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.9556279259108488,
    "expectancy": -145.33333333333334,
    "average_win": 9390.0,
    "average_loss": -4913.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": 1458.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2006606110652354,
    "expectancy": 486.0,
    "average_win": 8724.0,
    "average_loss": -3633.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": -11942.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2985.5,
    "average_win": null,
    "average_loss": -2985.5
  },
  {
    "weekday": "Wed",
    "number_of_trades": 4,
    "net_profit": -15607.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3901.75,
    "average_win": null,
    "average_loss": -3901.75
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_-0.000463-0.000923",
    "number_of_trades": 6,
    "net_profit": 4050.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2767716804483018,
    "expectancy": 675.0,
    "average_win": 9341.5,
    "average_loss": -3658.25
  },
  {
    "atr_band": "ATR_0.000923-0.00121",
    "number_of_trades": 5,
    "net_profit": -17210.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3442.0,
    "average_win": null,
    "average_loss": -4302.5
  },
  {
    "atr_band": "ATR_0.00121-0.0016",
    "number_of_trades": 6,
    "net_profit": -7702.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.5311092170948496,
    "expectancy": -1283.6666666666667,
    "average_win": 8724.0,
    "average_loss": -3285.2
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.06-42.3",
    "number_of_trades": 6,
    "net_profit": -21681.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3613.5,
    "average_win": null,
    "average_loss": -3613.5
  },
  {
    "adx_band": "ADX_42.3-46.23",
    "number_of_trades": 5,
    "net_profit": -6916.0,
    "win_rate": 0.2,
    "profit_factor": 0.5578005115089514,
    "expectancy": -1383.2,
    "average_win": 8724.0,
    "average_loss": -3910.0
  },
  {
    "adx_band": "ADX_46.23-72.3",
    "number_of_trades": 6,
    "net_profit": 7735.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.7065217391304348,
    "expectancy": 1289.1666666666667,
    "average_win": 9341.5,
    "average_loss": -3649.3333333333335
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.624-1.865",
    "number_of_trades": 6,
    "net_profit": -8780.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.5141924417639573,
    "expectancy": -1463.3333333333333,
    "average_win": 9293.0,
    "average_loss": -3614.6
  },
  {
    "hold_time_band": "HOLD_H_1.865-12.64",
    "number_of_trades": 5,
    "net_profit": -14455.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2891.0,
    "average_win": null,
    "average_loss": -3613.75
  },
  {
    "hold_time_band": "HOLD_H_12.64-84.57",
    "number_of_trades": 6,
    "net_profit": 2373.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.1507528111301697,
    "expectancy": 395.5,
    "average_win": 9057.0,
    "average_loss": -3935.25
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-213-1423",
    "number_of_trades": 6,
    "net_profit": -21577.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3596.1666666666665,
    "average_win": null,
    "average_loss": -3596.1666666666665
  },
  {
    "mfe_band": "MFE_1423-2973",
    "number_of_trades": 5,
    "net_profit": -18516.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3703.2,
    "average_win": null,
    "average_loss": -3703.2
  },
  {
    "mfe_band": "MFE_2973-9364",
    "number_of_trades": 6,
    "net_profit": 19231.0,
    "win_rate": 0.5,
    "profit_factor": 3.352128180039139,
    "expectancy": 3205.1666666666665,
    "average_win": 9135.666666666666,
    "average_loss": -4088.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-3428--470",
    "number_of_trades": 6,
    "net_profit": 23147.0,
    "win_rate": 0.5,
    "profit_factor": 6.433568075117371,
    "expectancy": 3857.8333333333335,
    "average_win": 9135.666666666666,
    "average_loss": -2130.0
  },
  {
    "mae_band": "MAE_-3667--3428",
    "number_of_trades": 5,
    "net_profit": -17853.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3570.6,
    "average_win": null,
    "average_loss": -3570.6
  },
  {
    "mae_band": "MAE_-6269--3667",
    "number_of_trades": 6,
    "net_profit": -26156.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4359.333333333333,
    "average_win": null,
    "average_loss": -4359.333333333333
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 12,
    "net_profit": -28207.0,
    "win_rate": 0.08333333333333333,
    "profit_factor": 0.24781333333333333,
    "expectancy": -2350.5833333333335,
    "average_win": 9293.0,
    "average_loss": -3750.0
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 5,
    "net_profit": 7345.0,
    "win_rate": 0.4,
    "profit_factor": 1.682050329649921,
    "expectancy": 1469.0,
    "average_win": 9057.0,
    "average_loss": -3589.6666666666665
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": -6998.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3499.0,
    "average_win": null,
    "average_loss": -3499.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 2,
    "net_profit": 5665.0,
    "win_rate": 0.5,
    "profit_factor": 2.561466372657111,
    "expectancy": 2832.5,
    "average_win": 9293.0,
    "average_loss": -3628.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 13,
    "net_profit": -19529.0,
    "win_rate": 0.15384615384615385,
    "profit_factor": 0.48120500491459234,
    "expectancy": -1502.2307692307693,
    "average_win": 9057.0,
    "average_loss": -3764.3
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 11,
    "net_profit": -37226.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3384.181818181818,
    "average_win": null,
    "average_loss": -3384.181818181818
  },
  {
    "close_reason": "SL",
    "number_of_trades": 3,
    "net_profit": -11043.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3681.0,
    "average_win": null,
    "average_loss": -5521.5
  },
  {
    "close_reason": "TP",
    "number_of_trades": 3,
    "net_profit": 27407.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9135.666666666666,
    "average_win": 9135.666666666666,
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
    "net_profit": 7069.0,
    "win_rate": 0.4,
    "profit_factor": 1.6456887102667155,
    "expectancy": 1413.8,
    "average_win": 9008.5,
    "average_loss": -3649.3333333333335
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 4,
    "net_profit": -14813.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3703.25,
    "average_win": null,
    "average_loss": -3703.25
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 4,
    "net_profit": -1192.0,
    "win_rate": 0.25,
    "profit_factor": 0.8873558873558873,
    "expectancy": -298.0,
    "average_win": 9390.0,
    "average_loss": -3527.3333333333335
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 4,
    "net_profit": -11926.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2981.5,
    "average_win": null,
    "average_loss": -3975.3333333333335
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": 5665.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.561466372657111,
    "expectancy": 1888.3333333333333,
    "average_win": 9293.0,
    "average_loss": -3628.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 3,
    "net_profit": 14532.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 5.056951423785595,
    "expectancy": 4844.0,
    "average_win": 9057.0,
    "average_loss": -3582.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": -15686.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3921.5,
    "average_win": null,
    "average_loss": -3921.5
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 2,
    "net_profit": -9982.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4991.0,
    "average_win": null,
    "average_loss": -4991.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": -15391.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3078.2,
    "average_win": null,
    "average_loss": -3078.2
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00815-1.967",
    "number_of_trades": 5,
    "net_profit": 24030.0,
    "win_rate": 0.6,
    "profit_factor": 8.115783239561742,
    "expectancy": 4806.0,
    "average_win": 9135.666666666666,
    "average_loss": -3377.0
  },
  {
    "giveback_band": "GIVEBACK_1.967-2.715",
    "number_of_trades": 4,
    "net_profit": -15625.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3906.25,
    "average_win": null,
    "average_loss": -3906.25
  },
  {
    "giveback_band": "GIVEBACK_2.715-31.61",
    "number_of_trades": 5,
    "net_profit": -18512.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3702.4,
    "average_win": null,
    "average_loss": -3702.4
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
