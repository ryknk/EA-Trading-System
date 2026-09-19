# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 24
- MFEデータのある負けトレード数: 24
- うち一度含み益になった数: 23
- 割合: 95.83%
- 反転前の平均含み益: 2128.35

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 27
- 平均Giveback比率: 515.85%
- 中央値Giveback比率: 307.50%
- 損益ゼロ以下まで完全反転した割合: 88.89%

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

- 決済件数: 22
- 純損益: -80533.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3660.59
- 平均逆行幅（R）: 0.7662
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 6,
    "net_profit": -22372.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3728.6666666666665,
    "average_win": null,
    "average_loss": -3728.6666666666665
  },
  "SELL": {
    "number_of_trades": 16,
    "net_profit": -58161.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3635.0625,
    "average_win": null,
    "average_loss": -3635.0625
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6193
- 最終Entry候補まで到達: 42
- Stage別棄却数（market_regime）: 5080
- Stage別棄却数（htf_bias）: 124
- Stage別棄却数（trend_strength_or_momentum_filter）: 529
- Stage別棄却数（setup_or_trigger）: 418
- Stage別棄却数（other）: 0

```json
{
  "ENTRY_PATTERN_NOT_FOUND": 418,
  "REGIME_NOT_TRENDING": 5080,
  "RSI_FILTERED": 463,
  "CONFIRMATION_ADX_TOO_LOW": 66,
  "TREND_NOT_ALIGNED": 124
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 10,
    "net_profit": 5790.0,
    "win_rate": 0.3,
    "profit_factor": 1.257780152263924,
    "expectancy": 579.0,
    "average_win": 9417.0,
    "average_loss": -3208.714285714286
  },
  {
    "direction": "SELL",
    "number_of_trades": 18,
    "net_profit": -58206.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3233.6666666666665,
    "average_win": null,
    "average_loss": -3423.8823529411766
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 7,
    "net_profit": -22574.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3224.8571428571427,
    "average_win": null,
    "average_loss": -3224.8571428571427
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": -22233.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2779.125,
    "average_win": null,
    "average_loss": -3176.1428571428573
  },
  {
    "session": "NewYork",
    "number_of_trades": 6,
    "net_profit": 5127.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.3672636103151863,
    "expectancy": 854.5,
    "average_win": 9543.5,
    "average_loss": -3490.0
  },
  {
    "session": "Tokyo",
    "number_of_trades": 7,
    "net_profit": -12736.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.4184474885844749,
    "expectancy": -1819.4285714285713,
    "average_win": 9164.0,
    "average_loss": -3650.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": 15307.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 5.0494708994709,
    "expectancy": 5102.333333333333,
    "average_win": 9543.5,
    "average_loss": -3780.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 5,
    "net_profit": -14832.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2966.4,
    "average_win": null,
    "average_loss": -3708.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 7,
    "net_profit": -26022.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3717.4285714285716,
    "average_win": null,
    "average_loss": -3717.4285714285716
  },
  {
    "weekday": "Tue",
    "number_of_trades": 5,
    "net_profit": -14305.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2861.0,
    "average_win": null,
    "average_loss": -2861.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 8,
    "net_profit": -12564.0,
    "win_rate": 0.125,
    "profit_factor": 0.421759941089838,
    "expectancy": -1570.5,
    "average_win": 9164.0,
    "average_loss": -3104.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_-0.000237-0.00129",
    "number_of_trades": 10,
    "net_profit": -33239.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3323.9,
    "average_win": null,
    "average_loss": -3323.9
  },
  {
    "atr_band": "ATR_0.00129-0.00179",
    "number_of_trades": 8,
    "net_profit": -9210.0,
    "win_rate": 0.125,
    "profit_factor": 0.49874823119625555,
    "expectancy": -1151.25,
    "average_win": 9164.0,
    "average_loss": -3062.3333333333335
  },
  {
    "atr_band": "ATR_0.00179-0.00268",
    "number_of_trades": 10,
    "net_profit": -9967.0,
    "win_rate": 0.2,
    "profit_factor": 0.6569491292076822,
    "expectancy": -996.7,
    "average_win": 9543.5,
    "average_loss": -3631.75
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.16-42.49",
    "number_of_trades": 10,
    "net_profit": -33098.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3309.8,
    "average_win": null,
    "average_loss": -3677.5555555555557
  },
  {
    "adx_band": "ADX_42.49-48.61",
    "number_of_trades": 8,
    "net_profit": -15716.0,
    "win_rate": 0.125,
    "profit_factor": 0.3812111189857469,
    "expectancy": -1964.5,
    "average_win": 9682.0,
    "average_loss": -3628.285714285714
  },
  {
    "adx_band": "ADX_48.61-56.11",
    "number_of_trades": 10,
    "net_profit": -3602.0,
    "win_rate": 0.2,
    "profit_factor": 0.8375355193721528,
    "expectancy": -360.2,
    "average_win": 9284.5,
    "average_loss": -2771.375
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.619-2.993",
    "number_of_trades": 9,
    "net_profit": -33471.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3719.0,
    "average_win": null,
    "average_loss": -3719.0
  },
  {
    "hold_time_band": "HOLD_H_2.993-8.552",
    "number_of_trades": 10,
    "net_profit": -32797.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3279.7,
    "average_win": null,
    "average_loss": -3644.1111111111113
  },
  {
    "hold_time_band": "HOLD_H_8.552-84.86",
    "number_of_trades": 9,
    "net_profit": 13852.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.9620112507813043,
    "expectancy": 1539.111111111111,
    "average_win": 9417.0,
    "average_loss": -2399.8333333333335
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-326-720",
    "number_of_trades": 9,
    "net_profit": -32975.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3663.8888888888887,
    "average_win": null,
    "average_loss": -3663.8888888888887
  },
  {
    "mfe_band": "MFE_3273-9669",
    "number_of_trades": 10,
    "net_profit": 13244.0,
    "win_rate": 0.3,
    "profit_factor": 1.8825214899713467,
    "expectancy": 1324.4,
    "average_win": 9417.0,
    "average_loss": -2501.1666666666665
  },
  {
    "mfe_band": "MFE_720-3273",
    "number_of_trades": 9,
    "net_profit": -32685.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3631.6666666666665,
    "average_win": null,
    "average_loss": -3631.6666666666665
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-3503--195",
    "number_of_trades": 10,
    "net_profit": 14352.0,
    "win_rate": 0.3,
    "profit_factor": 2.032592272825383,
    "expectancy": 1435.2,
    "average_win": 9417.0,
    "average_loss": -2316.5
  },
  {
    "mae_band": "MAE_-3659--3503",
    "number_of_trades": 8,
    "net_profit": -28886.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3610.75,
    "average_win": null,
    "average_loss": -3610.75
  },
  {
    "mae_band": "MAE_-4399--3659",
    "number_of_trades": 10,
    "net_profit": -37882.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3788.2,
    "average_win": null,
    "average_loss": -3788.2
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 17,
    "net_profit": -58206.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3423.8823529411766,
    "average_win": null,
    "average_loss": -3423.8823529411766
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 11,
    "net_profit": 5790.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 1.257780152263924,
    "expectancy": 526.3636363636364,
    "average_win": 9417.0,
    "average_loss": -3208.714285714286
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 4,
    "net_profit": -1250.0,
    "win_rate": 0.25,
    "profit_factor": 0.8826841858282497,
    "expectancy": -312.5,
    "average_win": 9405.0,
    "average_loss": -3551.6666666666665
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 3,
    "net_profit": -7321.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2440.3333333333335,
    "average_win": null,
    "average_loss": -3660.5
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 21,
    "net_profit": -43845.0,
    "win_rate": 0.09523809523809523,
    "profit_factor": 0.3006173134899746,
    "expectancy": -2087.8571428571427,
    "average_win": 9423.0,
    "average_loss": -3299.5263157894738
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 22,
    "net_profit": -80533.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3660.590909090909,
    "average_win": null,
    "average_loss": -3660.590909090909
  },
  {
    "close_reason": "SL",
    "number_of_trades": 3,
    "net_profit": -134.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -44.666666666666664,
    "average_win": null,
    "average_loss": -67.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 3,
    "net_profit": 28251.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9417.0,
    "average_win": 9417.0,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 14,
    "net_profit": -34565.0,
    "win_rate": 0.07142857142857142,
    "profit_factor": 0.21389583807141233,
    "expectancy": -2468.9285714285716,
    "average_win": 9405.0,
    "average_loss": -3382.3076923076924
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 7,
    "net_profit": 362.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.0195845055182862,
    "expectancy": 51.714285714285715,
    "average_win": 9423.0,
    "average_loss": -3696.8
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 4,
    "net_profit": -11143.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2785.75,
    "average_win": null,
    "average_loss": -2785.75
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 3,
    "net_profit": -7070.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2356.6666666666665,
    "average_win": null,
    "average_loss": -3535.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": -10977.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3659.0,
    "average_win": null,
    "average_loss": -3659.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 8,
    "net_profit": 669.0,
    "win_rate": 0.25,
    "profit_factor": 1.0363231621240092,
    "expectancy": 83.625,
    "average_win": 9543.5,
    "average_loss": -3683.6
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 5,
    "net_profit": -18680.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3736.0,
    "average_win": null,
    "average_loss": -3736.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": -10734.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3578.0,
    "average_win": null,
    "average_loss": -3578.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 9,
    "net_profit": -12694.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.4192515326196358,
    "expectancy": -1410.4444444444443,
    "average_win": 9164.0,
    "average_loss": -2732.25
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00385-2.097",
    "number_of_trades": 9,
    "net_profit": 17033.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.5183633446247105,
    "expectancy": 1892.5555555555557,
    "average_win": 9417.0,
    "average_loss": -2243.6
  },
  {
    "giveback_band": "GIVEBACK_2.097-4.728",
    "number_of_trades": 9,
    "net_profit": -32992.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3665.777777777778,
    "average_win": null,
    "average_loss": -3665.777777777778
  },
  {
    "giveback_band": "GIVEBACK_4.728-20.85",
    "number_of_trades": 9,
    "net_profit": -33023.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3669.222222222222,
    "average_win": null,
    "average_loss": -3669.222222222222
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
