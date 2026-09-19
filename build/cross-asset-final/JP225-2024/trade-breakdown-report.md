# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 14
- MFEデータのある負けトレード数: 14
- うち一度含み益になった数: 13
- 割合: 92.86%
- 反転前の平均含み益: 1902.23

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 20
- 平均Giveback比率: 471.12%
- 中央値Giveback比率: 224.28%
- 損益ゼロ以下まで完全反転した割合: 70.00%

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
- 純損益: -48624.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3740.31
- 平均逆行幅（R）: 0.7616
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 13,
    "net_profit": -48624.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3740.3076923076924,
    "average_win": null,
    "average_loss": -3740.3076923076924
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 5897
- 最終Entry候補まで到達: 46
- Stage別棄却数（market_regime）: 4828
- Stage別棄却数（htf_bias）: 241
- Stage別棄却数（trend_strength_or_momentum_filter）: 453
- Stage別棄却数（setup_or_trigger）: 329
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 4828,
  "CONFIRMATION_ADX_TOO_LOW": 82,
  "ENTRY_PATTERN_NOT_FOUND": 329,
  "RSI_FILTERED": 371,
  "TREND_NOT_ALIGNED": 241
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 19,
    "net_profit": -8110.0,
    "win_rate": 0.2631578947368421,
    "profit_factor": 0.8334873216302228,
    "expectancy": -426.8421052631579,
    "average_win": 8119.0,
    "average_loss": -3478.9285714285716
  },
  {
    "direction": "SELL",
    "number_of_trades": 2,
    "net_profit": 9590.0,
    "win_rate": 0.5,
    "profit_factor": null,
    "expectancy": 4795.0,
    "average_win": 9590.0,
    "average_loss": null
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 2,
    "net_profit": 11315.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 5657.5,
    "average_win": 5657.5,
    "average_loss": null
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 3,
    "net_profit": -7476.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2492.0,
    "average_win": null,
    "average_loss": -2492.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 7,
    "net_profit": -13524.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.40183112919633773,
    "expectancy": -1932.0,
    "average_win": 9085.0,
    "average_loss": -3768.1666666666665
  },
  {
    "session": "Tokyo",
    "number_of_trades": 9,
    "net_profit": 11165.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.599624060150376,
    "expectancy": 1240.5555555555557,
    "average_win": 9928.333333333334,
    "average_loss": -3724.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 6,
    "net_profit": -9150.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.5117395944503735,
    "expectancy": -1525.0,
    "average_win": 9590.0,
    "average_loss": -3748.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 6,
    "net_profit": -1301.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.885686670767068,
    "expectancy": -216.83333333333334,
    "average_win": 10080.0,
    "average_loss": -2845.25
  },
  {
    "weekday": "Thu",
    "number_of_trades": 5,
    "net_profit": 13151.0,
    "win_rate": 0.6,
    "profit_factor": 2.8054640307523337,
    "expectancy": 2630.2,
    "average_win": 6811.666666666667,
    "average_loss": -3642.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 1,
    "net_profit": -3770.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3770.0,
    "average_win": null,
    "average_loss": -3770.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 3,
    "net_profit": 2550.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.3386454183266931,
    "expectancy": 850.0,
    "average_win": 10080.0,
    "average_loss": -3765.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_104.6-140.7",
    "number_of_trades": 7,
    "net_profit": -8716.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5362843158118749,
    "expectancy": -1245.142857142857,
    "average_win": 10080.0,
    "average_loss": -3132.6666666666665
  },
  {
    "atr_band": "ATR_140.7-392.5",
    "number_of_trades": 7,
    "net_profit": -3569.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.7602123085192153,
    "expectancy": -509.85714285714283,
    "average_win": 5657.5,
    "average_loss": -3721.0
  },
  {
    "atr_band": "ATR_88.57-104.6",
    "number_of_trades": 7,
    "net_profit": 13765.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.9161397670549085,
    "expectancy": 1966.4285714285713,
    "average_win": 9596.666666666666,
    "average_loss": -3756.25
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.02-42.16",
    "number_of_trades": 7,
    "net_profit": -8566.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5405985197897673,
    "expectancy": -1223.7142857142858,
    "average_win": 10080.0,
    "average_loss": -3107.6666666666665
  },
  {
    "adx_band": "ADX_42.16-45.79",
    "number_of_trades": 7,
    "net_profit": -6984.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.6282931502474852,
    "expectancy": -997.7142857142857,
    "average_win": 5902.5,
    "average_loss": -3757.8
  },
  {
    "adx_band": "ADX_45.79-64.63",
    "number_of_trades": 7,
    "net_profit": 17030.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.5110913930789707,
    "expectancy": 2432.8571428571427,
    "average_win": 9433.333333333334,
    "average_loss": -3756.6666666666665
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.492-3.798",
    "number_of_trades": 7,
    "net_profit": -22620.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3231.4285714285716,
    "average_win": null,
    "average_loss": -3770.0
  },
  {
    "hold_time_band": "HOLD_H_3.798-8.894",
    "number_of_trades": 7,
    "net_profit": 46.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.0024646378054007,
    "expectancy": 6.571428571428571,
    "average_win": 9355.0,
    "average_loss": -3732.8
  },
  {
    "hold_time_band": "HOLD_H_8.894-59.09",
    "number_of_trades": 7,
    "net_profit": 24054.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 4.241342137178278,
    "expectancy": 3436.285714285714,
    "average_win": 7868.75,
    "average_loss": -2473.6666666666665
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-0.001-1548",
    "number_of_trades": 7,
    "net_profit": -26259.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3751.285714285714,
    "average_win": null,
    "average_loss": -3751.285714285714
  },
  {
    "mfe_band": "MFE_1548-4823",
    "number_of_trades": 7,
    "net_profit": -20640.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.07712944332662643,
    "expectancy": -2948.5714285714284,
    "average_win": 1725.0,
    "average_loss": -3727.5
  },
  {
    "mfe_band": "MFE_4823-9960",
    "number_of_trades": 7,
    "net_profit": 48379.0,
    "win_rate": 0.7142857142857143,
    "profit_factor": 598.2716049382716,
    "expectancy": 6911.285714285715,
    "average_win": 9692.0,
    "average_loss": -81.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2360--60",
    "number_of_trades": 7,
    "net_profit": 40024.0,
    "win_rate": 0.7142857142857143,
    "profit_factor": 495.12345679012344,
    "expectancy": 5717.714285714285,
    "average_win": 8021.0,
    "average_loss": -81.0
  },
  {
    "mae_band": "MAE_-3757--2360",
    "number_of_trades": 7,
    "net_profit": -11989.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.4567492863292401,
    "expectancy": -1712.7142857142858,
    "average_win": 10080.0,
    "average_loss": -3678.1666666666665
  },
  {
    "mae_band": "MAE_-3990--3757",
    "number_of_trades": 7,
    "net_profit": -26555.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3793.5714285714284,
    "average_win": null,
    "average_loss": -3793.5714285714284
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 4,
    "net_profit": 1990.0,
    "win_rate": 0.25,
    "profit_factor": 1.2618421052631579,
    "expectancy": 497.5,
    "average_win": 9590.0,
    "average_loss": -3800.0
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 17,
    "net_profit": -510.0,
    "win_rate": 0.29411764705882354,
    "profit_factor": 0.9875927502736893,
    "expectancy": -30.0,
    "average_win": 8119.0,
    "average_loss": -3425.4166666666665
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 1,
    "net_profit": -3654.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3654.0,
    "average_win": null,
    "average_loss": -3654.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 20,
    "net_profit": 5134.0,
    "win_rate": 0.3,
    "profit_factor": 1.113959734523096,
    "expectancy": 256.7,
    "average_win": 8364.166666666666,
    "average_loss": -3465.4615384615386
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 14,
    "net_profit": -46899.0,
    "win_rate": 0.07142857142857142,
    "profit_factor": 0.03547630799605133,
    "expectancy": -3349.9285714285716,
    "average_win": 1725.0,
    "average_loss": -3740.3076923076924
  },
  {
    "close_reason": "SL",
    "number_of_trades": 2,
    "net_profit": -81.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -40.5,
    "average_win": null,
    "average_loss": -81.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 5,
    "net_profit": 48460.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9692.0,
    "average_win": 9692.0,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 3,
    "net_profit": 7710.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 3.118131868131868,
    "expectancy": 2570.0,
    "average_win": 5675.0,
    "average_loss": -3640.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 1,
    "net_profit": -81.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -81.0,
    "average_win": null,
    "average_loss": -81.0
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 5,
    "net_profit": -5335.0,
    "win_rate": 0.2,
    "profit_factor": 0.6425460636515913,
    "expectancy": -1067.0,
    "average_win": 9590.0,
    "average_loss": -3731.25
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 12,
    "net_profit": -814.0,
    "win_rate": 0.25,
    "profit_factor": 0.9729199241491733,
    "expectancy": -67.83333333333333,
    "average_win": 9748.333333333334,
    "average_loss": -3757.375
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 8,
    "net_profit": 1716.0,
    "win_rate": 0.375,
    "profit_factor": 1.0918432883750804,
    "expectancy": 214.5,
    "average_win": 6800.0,
    "average_loss": -3736.8
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 6,
    "net_profit": -18640.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3106.6666666666665,
    "average_win": null,
    "average_loss": -3728.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 1,
    "net_profit": 9625.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9625.0,
    "average_win": 9625.0,
    "average_loss": null
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": 6229.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.617501947546092,
    "expectancy": 2076.3333333333335,
    "average_win": 10080.0,
    "average_loss": -1925.5
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 3,
    "net_profit": 2550.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.3386454183266931,
    "expectancy": 850.0,
    "average_win": 10080.0,
    "average_loss": -3765.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0142-1.005",
    "number_of_trades": 7,
    "net_profit": 50185.0,
    "win_rate": 0.8571428571428571,
    "profit_factor": null,
    "expectancy": 7169.285714285715,
    "average_win": 8364.166666666666,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1.005-3.248",
    "number_of_trades": 6,
    "net_profit": -18746.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3124.3333333333335,
    "average_win": null,
    "average_loss": -3124.3333333333335
  },
  {
    "giveback_band": "GIVEBACK_3.248-30",
    "number_of_trades": 7,
    "net_profit": -26209.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3744.1428571428573,
    "average_win": null,
    "average_loss": -3744.1428571428573
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
