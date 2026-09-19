# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 12
- MFEデータのある負けトレード数: 12
- うち一度含み益になった数: 11
- 割合: 91.67%
- 反転前の平均含み益: 3280.27

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 20
- 平均Giveback比率: 293.75%
- 中央値Giveback比率: 100.43%
- 損益ゼロ以下まで完全反転した割合: 55.00%

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
- 純損益: -34015.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3779.44
- 平均逆行幅（R）: 0.7637
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 2,
    "net_profit": -7563.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3781.5,
    "average_win": null,
    "average_loss": -3781.5
  },
  "SELL": {
    "number_of_trades": 7,
    "net_profit": -26452.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3778.8571428571427,
    "average_win": null,
    "average_loss": -3778.8571428571427
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6205
- 最終Entry候補まで到達: 38
- Stage別棄却数（market_regime）: 5192
- Stage別棄却数（htf_bias）: 171
- Stage別棄却数（trend_strength_or_momentum_filter）: 405
- Stage別棄却数（setup_or_trigger）: 399
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5192,
  "RSI_FILTERED": 370,
  "ENTRY_PATTERN_NOT_FOUND": 399,
  "CONFIRMATION_ADX_TOO_LOW": 35,
  "TREND_NOT_ALIGNED": 171
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 7,
    "net_profit": 20628.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 3.704956726986625,
    "expectancy": 2946.8571428571427,
    "average_win": 9418.0,
    "average_loss": -1906.5
  },
  {
    "direction": "SELL",
    "number_of_trades": 14,
    "net_profit": 31171.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.1765305352155204,
    "expectancy": 2226.5,
    "average_win": 9610.833333333334,
    "average_loss": -3311.75
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 4,
    "net_profit": 15571.0,
    "win_rate": 0.5,
    "profit_factor": 5.22895165670831,
    "expectancy": 3892.75,
    "average_win": 9626.5,
    "average_loss": -1841.0
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 5,
    "net_profit": 6910.0,
    "win_rate": 0.4,
    "profit_factor": 1.573158593231586,
    "expectancy": 1382.0,
    "average_win": 9483.0,
    "average_loss": -4018.6666666666665
  },
  {
    "session": "NewYork",
    "number_of_trades": 3,
    "net_profit": 1974.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.272125723738627,
    "expectancy": 658.0,
    "average_win": 9228.0,
    "average_loss": -3627.0
  },
  {
    "session": "Tokyo",
    "number_of_trades": 9,
    "net_profit": 27344.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 3.4572250179726813,
    "expectancy": 3038.222222222222,
    "average_win": 9618.0,
    "average_loss": -2225.6
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 7,
    "net_profit": 40793.0,
    "win_rate": 0.7142857142857143,
    "profit_factor": 6.484404409787578,
    "expectancy": 5827.571428571428,
    "average_win": 9646.2,
    "average_loss": -3719.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 3,
    "net_profit": 15538.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 5.5807783018867925,
    "expectancy": 5179.333333333333,
    "average_win": 9465.0,
    "average_loss": -3392.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": -8124.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2708.0,
    "average_win": null,
    "average_loss": -2708.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": -7811.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2603.6666666666665,
    "average_win": null,
    "average_loss": -2603.6666666666665
  },
  {
    "weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": 11403.0,
    "win_rate": 0.4,
    "profit_factor": 2.5503738953093134,
    "expectancy": 2280.6,
    "average_win": 9379.0,
    "average_loss": -2451.6666666666665
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.117-0.173",
    "number_of_trades": 7,
    "net_profit": 26218.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 3.2296113615103326,
    "expectancy": 3745.4285714285716,
    "average_win": 9494.25,
    "average_loss": -3919.6666666666665
  },
  {
    "atr_band": "ATR_0.173-0.236",
    "number_of_trades": 7,
    "net_profit": 17565.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.521833304453301,
    "expectancy": 2509.285714285714,
    "average_win": 9702.333333333334,
    "average_loss": -2885.5
  },
  {
    "atr_band": "ATR_0.236-0.393",
    "number_of_trades": 7,
    "net_profit": 8016.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.7409187540438118,
    "expectancy": 1145.142857142857,
    "average_win": 9417.5,
    "average_loss": -2163.8
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.14-43.55",
    "number_of_trades": 7,
    "net_profit": 17454.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.490648219318473,
    "expectancy": 2493.4285714285716,
    "average_win": 9721.0,
    "average_loss": -2927.25
  },
  {
    "adx_band": "ADX_43.55-46.14",
    "number_of_trades": 7,
    "net_profit": 34002.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 9.601568429041235,
    "expectancy": 4857.428571428572,
    "average_win": 9488.75,
    "average_loss": -1317.6666666666667
  },
  {
    "adx_band": "ADX_46.14-54.01",
    "number_of_trades": 7,
    "net_profit": 343.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.0185827283562683,
    "expectancy": 49.0,
    "average_win": 9400.5,
    "average_loss": -3691.6
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_1.675-7.367",
    "number_of_trades": 7,
    "net_profit": -13081.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.42249790296234163,
    "expectancy": -1868.7142857142858,
    "average_win": 9570.0,
    "average_loss": -3775.1666666666665
  },
  {
    "hold_time_band": "HOLD_H_10.43-67.62",
    "number_of_trades": 7,
    "net_profit": 16609.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.4543782837127845,
    "expectancy": 2372.714285714286,
    "average_win": 9343.0,
    "average_loss": -2855.0
  },
  {
    "hold_time_band": "HOLD_H_7.367-10.43",
    "number_of_trades": 7,
    "net_profit": 48271.0,
    "win_rate": 0.7142857142857143,
    "profit_factor": 986.1224489795918,
    "expectancy": 6895.857142857143,
    "average_win": 9664.0,
    "average_loss": -24.5
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-0.001-3815",
    "number_of_trades": 7,
    "net_profit": -26268.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3752.5714285714284,
    "average_win": null,
    "average_loss": -3752.5714285714284
  },
  {
    "mfe_band": "MFE_3815-9257",
    "number_of_trades": 7,
    "net_profit": 10532.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 2.3413143148242486,
    "expectancy": 1504.5714285714287,
    "average_win": 9192.0,
    "average_loss": -1570.4
  },
  {
    "mfe_band": "MFE_9257-9828",
    "number_of_trades": 7,
    "net_profit": 67535.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9647.857142857143,
    "average_win": 9647.857142857143,
    "average_loss": null
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2139--176",
    "number_of_trades": 7,
    "net_profit": 58166.0,
    "win_rate": 0.8571428571428571,
    "profit_factor": 8310.42857142857,
    "expectancy": 8309.42857142857,
    "average_win": 9695.5,
    "average_loss": -7.0
  },
  {
    "mae_band": "MAE_-3582--2139",
    "number_of_trades": 7,
    "net_profit": 20710.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 3.9434337691870383,
    "expectancy": 2958.5714285714284,
    "average_win": 9248.666666666666,
    "average_loss": -1759.0
  },
  {
    "mae_band": "MAE_-4264--3582",
    "number_of_trades": 7,
    "net_profit": -27077.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3868.1428571428573,
    "average_win": null,
    "average_loss": -3868.1428571428573
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 14,
    "net_profit": 30855.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.150876538604998,
    "expectancy": 2203.9285714285716,
    "average_win": 9610.833333333334,
    "average_loss": -3351.25
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 7,
    "net_profit": 20944.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 3.8651162790697673,
    "expectancy": 2992.0,
    "average_win": 9418.0,
    "average_loss": -1827.5
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": -3602.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1801.0,
    "average_win": null,
    "average_loss": -1801.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 1,
    "net_profit": 9396.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9396.0,
    "average_win": 9396.0,
    "average_loss": null
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 18,
    "net_profit": 46005.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 2.5074710007208862,
    "expectancy": 2555.8333333333335,
    "average_win": 9565.375,
    "average_loss": -3051.8
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 9,
    "net_profit": -34015.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3779.4444444444443,
    "average_win": null,
    "average_loss": -3779.4444444444443
  },
  {
    "close_reason": "SL",
    "number_of_trades": 3,
    "net_profit": -105.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -35.0,
    "average_win": null,
    "average_loss": -35.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 9,
    "net_profit": 85919.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9546.555555555555,
    "average_win": 9546.555555555555,
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
    "net_profit": 20986.0,
    "win_rate": 0.6,
    "profit_factor": 3.5848010838773248,
    "expectancy": 4197.2,
    "average_win": 9701.666666666666,
    "average_loss": -4059.5
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 4,
    "net_profit": 1609.0,
    "win_rate": 0.25,
    "profit_factor": 1.213197296939181,
    "expectancy": 402.25,
    "average_win": 9156.0,
    "average_loss": -2515.6666666666665
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 8,
    "net_profit": 17972.0,
    "win_rate": 0.375,
    "profit_factor": 2.644582723279649,
    "expectancy": 2246.5,
    "average_win": 9633.333333333334,
    "average_loss": -2185.6
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 4,
    "net_profit": 11232.0,
    "win_rate": 0.5,
    "profit_factor": 2.49242625564709,
    "expectancy": 2808.0,
    "average_win": 9379.0,
    "average_loss": -3763.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 8,
    "net_profit": 23272.0,
    "win_rate": 0.5,
    "profit_factor": 2.4994845360824742,
    "expectancy": 2909.0,
    "average_win": 9698.0,
    "average_loss": -3880.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 3,
    "net_profit": 15749.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 5.642983490566038,
    "expectancy": 5249.666666666667,
    "average_win": 9570.5,
    "average_loss": -3392.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": 5612.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.4965333333333333,
    "expectancy": 1870.6666666666667,
    "average_win": 9362.0,
    "average_loss": -1875.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": 1417.0,
    "win_rate": 0.25,
    "profit_factor": 1.1814108308795288,
    "expectancy": 354.25,
    "average_win": 9228.0,
    "average_loss": -2603.6666666666665
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 3,
    "net_profit": 5749.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.576364134905402,
    "expectancy": 1916.3333333333333,
    "average_win": 9396.0,
    "average_loss": -1823.5
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00185-1.938",
    "number_of_trades": 6,
    "net_profit": 14593.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 4.650988241180886,
    "expectancy": 2432.1666666666665,
    "average_win": 9295.0,
    "average_loss": -999.25
  },
  {
    "giveback_band": "GIVEBACK_-0.0778--0.00185",
    "number_of_trades": 7,
    "net_profit": 67329.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9618.42857142857,
    "average_win": 9618.42857142857,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1.938-36.35",
    "number_of_trades": 7,
    "net_profit": -26577.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3796.714285714286,
    "average_win": null,
    "average_loss": -3796.714285714286
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
