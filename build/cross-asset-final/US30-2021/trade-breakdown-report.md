# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 12
- MFEデータのある負けトレード数: 12
- うち一度含み益になった数: 11
- 割合: 91.67%
- 反転前の平均含み益: 3030.55

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 18
- 平均Giveback比率: 305.16%
- 中央値Giveback比率: 100.97%
- 損益ゼロ以下まで完全反転した割合: 72.22%

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
- 純損益: -31605.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3511.67
- 平均逆行幅（R）: 0.7876
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 9,
    "net_profit": -31605.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3511.6666666666665,
    "average_win": null,
    "average_loss": -3511.6666666666665
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 4462
- 最終Entry候補まで到達: 33
- Stage別棄却数（market_regime）: 3603
- Stage別棄却数（htf_bias）: 272
- Stage別棄却数（trend_strength_or_momentum_filter）: 308
- Stage別棄却数（setup_or_trigger）: 246
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 3603,
  "ENTRY_PATTERN_NOT_FOUND": 246,
  "RSI_FILTERED": 226,
  "CONFIRMATION_ADX_TOO_LOW": 82,
  "TREND_NOT_ALIGNED": 272
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 19,
    "net_profit": -10740.0,
    "win_rate": 0.2631578947368421,
    "profit_factor": 0.6619133062612145,
    "expectancy": -565.2631578947369,
    "average_win": 4205.4,
    "average_loss": -2647.25
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 6,
    "net_profit": -14072.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2345.3333333333335,
    "average_win": null,
    "average_loss": -2814.4
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 4,
    "net_profit": 7519.0,
    "win_rate": 0.25,
    "profit_factor": 71.27102803738318,
    "expectancy": 1879.75,
    "average_win": 7626.0,
    "average_loss": -53.5
  },
  {
    "session": "NewYork",
    "number_of_trades": 4,
    "net_profit": 1862.0,
    "win_rate": 0.5,
    "profit_factor": 1.2535748331744518,
    "expectancy": 465.5,
    "average_win": 4602.5,
    "average_loss": -3671.5
  },
  {
    "session": "Tokyo",
    "number_of_trades": 5,
    "net_profit": -6049.0,
    "win_rate": 0.4,
    "profit_factor": 0.4095656417764763,
    "expectancy": -1209.8,
    "average_win": 2098.0,
    "average_loss": -3415.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 5,
    "net_profit": -7753.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1550.6,
    "average_win": null,
    "average_loss": -2584.3333333333335
  },
  {
    "weekday": "Mon",
    "number_of_trades": 4,
    "net_profit": -2335.0,
    "win_rate": 0.5,
    "profit_factor": 0.6598689002184996,
    "expectancy": -583.75,
    "average_win": 2265.0,
    "average_loss": -3432.5
  },
  {
    "weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": 12378.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 4.650250663521085,
    "expectancy": 4126.0,
    "average_win": 7884.5,
    "average_loss": -3391.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 6,
    "net_profit": -9166.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.07357994744289469,
    "expectancy": -1527.6666666666667,
    "average_win": 728.0,
    "average_loss": -1978.8
  },
  {
    "weekday": "Wed",
    "number_of_trades": 1,
    "net_profit": -3864.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3864.0,
    "average_win": null,
    "average_loss": -3864.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_31.18-45.79",
    "number_of_trades": 6,
    "net_profit": 8312.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.1146573689151134,
    "expectancy": 1385.3333333333333,
    "average_win": 7884.5,
    "average_loss": -1864.25
  },
  {
    "atr_band": "ATR_45.79-68.82",
    "number_of_trades": 6,
    "net_profit": -13038.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.07531914893617021,
    "expectancy": -2173.0,
    "average_win": 1062.0,
    "average_loss": -2820.0
  },
  {
    "atr_band": "ATR_68.82-123.3",
    "number_of_trades": 7,
    "net_profit": -6014.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.41096963761018607,
    "expectancy": -859.1428571428571,
    "average_win": 2098.0,
    "average_loss": -3403.3333333333335
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.01-41.76",
    "number_of_trades": 7,
    "net_profit": -12582.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.12454773170052881,
    "expectancy": -1797.4285714285713,
    "average_win": 895.0,
    "average_loss": -3593.0
  },
  {
    "adx_band": "ADX_41.76-45.63",
    "number_of_trades": 6,
    "net_profit": -7492.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.3164233576642336,
    "expectancy": -1248.6666666666667,
    "average_win": 3468.0,
    "average_loss": -2740.0
  },
  {
    "adx_band": "ADX_45.63-60.16",
    "number_of_trades": 6,
    "net_profit": 9334.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.4505050505050505,
    "expectancy": 1555.6666666666667,
    "average_win": 7884.5,
    "average_loss": -1608.75
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.719-4.439",
    "number_of_trades": 6,
    "net_profit": 1010.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.1375272331154684,
    "expectancy": 168.33333333333334,
    "average_win": 4177.0,
    "average_loss": -1836.0
  },
  {
    "hold_time_band": "HOLD_H_11.6-80.56",
    "number_of_trades": 7,
    "net_profit": 5312.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.7216410813748133,
    "expectancy": 758.8571428571429,
    "average_win": 4224.333333333333,
    "average_loss": -3680.5
  },
  {
    "hold_time_band": "HOLD_H_4.439-11.6",
    "number_of_trades": 6,
    "net_profit": -17062.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2843.6666666666665,
    "average_win": null,
    "average_loss": -2843.6666666666665
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-45-1640",
    "number_of_trades": 6,
    "net_profit": -16406.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.042488619119878605,
    "expectancy": -2734.3333333333335,
    "average_win": 728.0,
    "average_loss": -3426.8
  },
  {
    "mfe_band": "MFE_1640-5118",
    "number_of_trades": 7,
    "net_profit": -13455.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.0731556106633602,
    "expectancy": -1922.142857142857,
    "average_win": 1062.0,
    "average_loss": -2903.4
  },
  {
    "mfe_band": "MFE_5118-8115",
    "number_of_trades": 6,
    "net_profit": 19121.0,
    "win_rate": 0.5,
    "profit_factor": 165.83620689655172,
    "expectancy": 3186.8333333333335,
    "average_win": 6412.333333333333,
    "average_loss": -58.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2273--295",
    "number_of_trades": 7,
    "net_profit": 5151.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 49.14018691588785,
    "expectancy": 735.8571428571429,
    "average_win": 1752.6666666666667,
    "average_loss": -53.5
  },
  {
    "mae_band": "MAE_-3373--2273",
    "number_of_trades": 5,
    "net_profit": 9734.0,
    "win_rate": 0.4,
    "profit_factor": 2.612924606462303,
    "expectancy": 1946.8,
    "average_win": 7884.5,
    "average_loss": -2011.6666666666667
  },
  {
    "mae_band": "MAE_-3970--3373",
    "number_of_trades": 7,
    "net_profit": -25625.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3660.714285714286,
    "average_win": null,
    "average_loss": -3660.714285714286
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 1,
    "net_profit": 728.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 728.0,
    "average_win": 728.0,
    "average_loss": null
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 18,
    "net_profit": -11468.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.6389964428494979,
    "expectancy": -637.1111111111111,
    "average_win": 5074.75,
    "average_loss": -2647.25
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 3,
    "net_profit": 3843.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.015860428231562,
    "expectancy": 1281.0,
    "average_win": 7626.0,
    "average_loss": -1891.5
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 16,
    "net_profit": -14583.0,
    "win_rate": 0.25,
    "profit_factor": 0.47888078902229847,
    "expectancy": -911.4375,
    "average_win": 3350.25,
    "average_loss": -2798.4
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 12,
    "net_profit": -26347.0,
    "win_rate": 0.25,
    "profit_factor": 0.16636608131624742,
    "expectancy": -2195.5833333333335,
    "average_win": 1752.6666666666667,
    "average_loss": -3511.6666666666665
  },
  {
    "close_reason": "SL",
    "number_of_trades": 5,
    "net_profit": -162.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -32.4,
    "average_win": null,
    "average_loss": -54.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 2,
    "net_profit": 15769.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7884.5,
    "average_win": 7884.5,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 4,
    "net_profit": -5500.0,
    "win_rate": 0.5,
    "profit_factor": 0.24554183813443073,
    "expectancy": -1375.0,
    "average_win": 895.0,
    "average_loss": -3645.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 9,
    "net_profit": 2081.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 1.152030976037405,
    "expectancy": 231.22222222222223,
    "average_win": 7884.5,
    "average_loss": -2281.3333333333335
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 4,
    "net_profit": -6819.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1704.75,
    "average_win": null,
    "average_loss": -2273.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 2,
    "net_profit": -502.0,
    "win_rate": 0.5,
    "profit_factor": 0.873551637279597,
    "expectancy": -251.0,
    "average_win": 3468.0,
    "average_loss": -3970.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": 4360.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.1525244514935236,
    "expectancy": 1453.3333333333333,
    "average_win": 8143.0,
    "average_loss": -1891.5
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 5,
    "net_profit": -10835.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2167.0,
    "average_win": null,
    "average_loss": -3611.6666666666665
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 2,
    "net_profit": 4235.0,
    "win_rate": 0.5,
    "profit_factor": 2.248894131524624,
    "expectancy": 2117.5,
    "average_win": 7626.0,
    "average_loss": -3391.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 7,
    "net_profit": -8104.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.18091772791590863,
    "expectancy": -1157.7142857142858,
    "average_win": 895.0,
    "average_loss": -1978.8
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 2,
    "net_profit": -396.0,
    "win_rate": 0.5,
    "profit_factor": 0.8975155279503105,
    "expectancy": -198.0,
    "average_win": 3468.0,
    "average_loss": -3864.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00853-1",
    "number_of_trades": 7,
    "net_profit": 21027.0,
    "win_rate": 0.7142857142857143,
    "profit_factor": null,
    "expectancy": 3003.8571428571427,
    "average_win": 4205.4,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1-2.079",
    "number_of_trades": 5,
    "net_profit": -7523.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1504.6,
    "average_win": null,
    "average_loss": -1504.6
  },
  {
    "giveback_band": "GIVEBACK_2.079-16.23",
    "number_of_trades": 6,
    "net_profit": -21289.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3548.1666666666665,
    "average_win": null,
    "average_loss": -3548.1666666666665
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
