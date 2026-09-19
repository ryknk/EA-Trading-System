# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 21
- MFEデータのある負けトレード数: 21
- うち一度含み益になった数: 19
- 割合: 90.48%
- 反転前の平均含み益: 2244.21

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 26
- 平均Giveback比率: 288.29%
- 中央値Giveback比率: 201.93%
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
- 純損益: -57554.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3597.12
- 平均逆行幅（R）: 0.7629
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 14,
    "net_profit": -49915.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3565.3571428571427,
    "average_win": null,
    "average_loss": -3565.3571428571427
  },
  "SELL": {
    "number_of_trades": 2,
    "net_profit": -7639.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3819.5,
    "average_win": null,
    "average_loss": -3819.5
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6324
- 最終Entry候補まで到達: 50
- Stage別棄却数（market_regime）: 5302
- Stage別棄却数（htf_bias）: 207
- Stage別棄却数（trend_strength_or_momentum_filter）: 473
- Stage別棄却数（setup_or_trigger）: 292
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5302,
  "ENTRY_PATTERN_NOT_FOUND": 292,
  "RSI_FILTERED": 443,
  "TREND_NOT_ALIGNED": 207,
  "CONFIRMATION_ADX_TOO_LOW": 30
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 26,
    "net_profit": -19976.0,
    "win_rate": 0.23076923076923078,
    "profit_factor": 0.6498141785288549,
    "expectancy": -768.3076923076923,
    "average_win": 6178.0,
    "average_loss": -3002.315789473684
  },
  {
    "direction": "SELL",
    "number_of_trades": 2,
    "net_profit": -7639.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3819.5,
    "average_win": null,
    "average_loss": -3819.5
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 8,
    "net_profit": 7564.0,
    "win_rate": 0.25,
    "profit_factor": 1.7055312004477194,
    "expectancy": 945.5,
    "average_win": 9142.5,
    "average_loss": -2144.2
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 4,
    "net_profit": -12058.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3014.5,
    "average_win": null,
    "average_loss": -3014.5
  },
  {
    "session": "NewYork",
    "number_of_trades": 9,
    "net_profit": -14468.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.390024874573127,
    "expectancy": -1607.5555555555557,
    "average_win": 4625.5,
    "average_loss": -3388.4285714285716
  },
  {
    "session": "Tokyo",
    "number_of_trades": 7,
    "net_profit": -8653.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.5241682705526532,
    "expectancy": -1236.142857142857,
    "average_win": 4766.0,
    "average_loss": -3637.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 2,
    "net_profit": 7868.0,
    "win_rate": 0.5,
    "profit_factor": 6.341479972844535,
    "expectancy": 3934.0,
    "average_win": 9341.0,
    "average_loss": -1473.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 9,
    "net_profit": -21535.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.009702933872896165,
    "expectancy": -2392.777777777778,
    "average_win": 105.5,
    "average_loss": -3106.5714285714284
  },
  {
    "weekday": "Thu",
    "number_of_trades": 2,
    "net_profit": -8719.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4359.5,
    "average_win": null,
    "average_loss": -4359.5
  },
  {
    "weekday": "Tue",
    "number_of_trades": 6,
    "net_profit": 3663.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2505129257283545,
    "expectancy": 610.5,
    "average_win": 9142.5,
    "average_loss": -3655.5
  },
  {
    "weekday": "Wed",
    "number_of_trades": 9,
    "net_profit": -8892.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.5093527561661977,
    "expectancy": -988.0,
    "average_win": 9231.0,
    "average_loss": -2589.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.11-0.194",
    "number_of_trades": 10,
    "net_profit": -6319.0,
    "win_rate": 0.2,
    "profit_factor": 0.5987936507936508,
    "expectancy": -631.9,
    "average_win": 4715.5,
    "average_loss": -2250.0
  },
  {
    "atr_band": "ATR_0.194-0.23",
    "number_of_trades": 9,
    "net_profit": -27059.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.0007385797112153329,
    "expectancy": -3006.5555555555557,
    "average_win": 20.0,
    "average_loss": -3384.875
  },
  {
    "atr_band": "ATR_0.23-0.469",
    "number_of_trades": 9,
    "net_profit": 5763.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2637045849730026,
    "expectancy": 640.3333333333334,
    "average_win": 9205.666666666666,
    "average_loss": -3642.3333333333335
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.28-41.95",
    "number_of_trades": 10,
    "net_profit": -1479.0,
    "win_rate": 0.2,
    "profit_factor": 0.9255474452554745,
    "expectancy": -147.9,
    "average_win": 9193.0,
    "average_loss": -2837.8571428571427
  },
  {
    "adx_band": "ADX_41.95-43.92",
    "number_of_trades": 9,
    "net_profit": -4216.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.814166703398422,
    "expectancy": -468.44444444444446,
    "average_win": 9235.5,
    "average_loss": -3241.0
  },
  {
    "adx_band": "ADX_43.92-52.06",
    "number_of_trades": 9,
    "net_profit": -21920.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.00953413763499164,
    "expectancy": -2435.5555555555557,
    "average_win": 105.5,
    "average_loss": -3161.5714285714284
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.377-3.025",
    "number_of_trades": 10,
    "net_profit": -15961.0,
    "win_rate": 0.1,
    "profit_factor": 0.3617131888346797,
    "expectancy": -1596.1,
    "average_win": 9045.0,
    "average_loss": -3125.75
  },
  {
    "hold_time_band": "HOLD_H_3.025-9.704",
    "number_of_trades": 9,
    "net_profit": -21193.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.30361778332730915,
    "expectancy": -2354.777777777778,
    "average_win": 9240.0,
    "average_loss": -3804.125
  },
  {
    "hold_time_band": "HOLD_H_9.704-90.1",
    "number_of_trades": 9,
    "net_profit": 9539.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 2.031912591951536,
    "expectancy": 1059.888888888889,
    "average_win": 4695.75,
    "average_loss": -1848.8
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-60-1370",
    "number_of_trades": 9,
    "net_profit": -29431.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3270.1111111111113,
    "average_win": null,
    "average_loss": -3270.1111111111113
  },
  {
    "mfe_band": "MFE_1370-3844",
    "number_of_trades": 9,
    "net_profit": -31638.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3515.3333333333335,
    "average_win": null,
    "average_loss": -3515.3333333333335
  },
  {
    "mfe_band": "MFE_3844-9311",
    "number_of_trades": 10,
    "net_profit": 33454.0,
    "win_rate": 0.6,
    "profit_factor": 10.25677919203099,
    "expectancy": 3345.4,
    "average_win": 6178.0,
    "average_loss": -1204.6666666666667
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-3083--72",
    "number_of_trades": 10,
    "net_profit": 36324.0,
    "win_rate": 0.6,
    "profit_factor": 49.82258064516129,
    "expectancy": 3632.4,
    "average_win": 6178.0,
    "average_loss": -248.0
  },
  {
    "mae_band": "MAE_-3588--3083",
    "number_of_trades": 8,
    "net_profit": -27927.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3490.875,
    "average_win": null,
    "average_loss": -3490.875
  },
  {
    "mae_band": "MAE_-6940--3588",
    "number_of_trades": 10,
    "net_profit": -36012.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3601.2,
    "average_win": null,
    "average_loss": -3601.2
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 2,
    "net_profit": -7639.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3819.5,
    "average_win": null,
    "average_loss": -3819.5
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 26,
    "net_profit": -19976.0,
    "win_rate": 0.23076923076923078,
    "profit_factor": 0.6498141785288549,
    "expectancy": -768.3076923076923,
    "average_win": 6178.0,
    "average_loss": -3002.315789473684
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 4,
    "net_profit": 1887.0,
    "win_rate": 0.25,
    "profit_factor": 1.2566299469604243,
    "expectancy": 471.75,
    "average_win": 9240.0,
    "average_loss": -2451.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 24,
    "net_profit": -29502.0,
    "win_rate": 0.20833333333333334,
    "profit_factor": 0.48540031397174255,
    "expectancy": -1229.25,
    "average_win": 5565.6,
    "average_loss": -3185.0
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 19,
    "net_profit": -59539.0,
    "win_rate": 0.05263157894736842,
    "profit_factor": 0.0031977230872258498,
    "expectancy": -3133.6315789473683,
    "average_win": 191.0,
    "average_loss": -3318.3333333333335
  },
  {
    "close_reason": "SL",
    "number_of_trades": 5,
    "net_profit": -4933.0,
    "win_rate": 0.2,
    "profit_factor": 0.004037956793862305,
    "expectancy": -986.6,
    "average_win": 20.0,
    "average_loss": -1651.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 4,
    "net_profit": 36857.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9214.25,
    "average_win": 9214.25,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 12,
    "net_profit": -10860.0,
    "win_rate": 0.25,
    "profit_factor": 0.4601312388148737,
    "expectancy": -905.0,
    "average_win": 3085.3333333333335,
    "average_loss": -2235.1111111111113
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 5,
    "net_profit": -1536.0,
    "win_rate": 0.2,
    "profit_factor": 0.8573418779604347,
    "expectancy": -307.2,
    "average_win": 9231.0,
    "average_loss": -3589.0
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 5,
    "net_profit": 7984.0,
    "win_rate": 0.4,
    "profit_factor": 1.7534207794658865,
    "expectancy": 1596.8,
    "average_win": 9290.5,
    "average_loss": -3532.3333333333335
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 6,
    "net_profit": -23203.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3867.1666666666665,
    "average_win": null,
    "average_loss": -3867.1666666666665
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 1,
    "net_profit": -4912.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4912.0,
    "average_win": null,
    "average_loss": -4912.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 3,
    "net_profit": -8643.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2881.0,
    "average_win": null,
    "average_loss": -2881.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": 1288.0,
    "win_rate": 0.25,
    "profit_factor": 1.162155356918041,
    "expectancy": 322.0,
    "average_win": 9231.0,
    "average_loss": -2647.6666666666665
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 12,
    "net_profit": 5989.0,
    "win_rate": 0.4166666666666667,
    "profit_factor": 1.2741212010252654,
    "expectancy": 499.0833333333333,
    "average_win": 5567.4,
    "average_loss": -3121.1428571428573
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 8,
    "net_profit": -21337.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2667.125,
    "average_win": null,
    "average_loss": -3048.1428571428573
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0199-1.166",
    "number_of_trades": 9,
    "net_profit": 37027.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 904.0975609756098,
    "expectancy": 4114.111111111111,
    "average_win": 6178.0,
    "average_loss": -20.5
  },
  {
    "giveback_band": "GIVEBACK_1.166-3.189",
    "number_of_trades": 8,
    "net_profit": -23952.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2994.0,
    "average_win": null,
    "average_loss": -2994.0
  },
  {
    "giveback_band": "GIVEBACK_3.189-14.83",
    "number_of_trades": 9,
    "net_profit": -33565.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3729.4444444444443,
    "average_win": null,
    "average_loss": -3729.4444444444443
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
