# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 17
- MFEデータのある負けトレード数: 17
- うち一度含み益になった数: 14
- 割合: 82.35%
- 反転前の平均含み益: 2494.57

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 22
- 平均Giveback比率: 338.27%
- 中央値Giveback比率: 146.87%
- 損益ゼロ以下まで完全反転した割合: 63.64%

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
- 純損益: -48516.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3732.00
- 平均逆行幅（R）: 0.7745
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 10,
    "net_profit": -37188.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3718.8,
    "average_win": null,
    "average_loss": -3718.8
  },
  "SELL": {
    "number_of_trades": 3,
    "net_profit": -11328.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3776.0,
    "average_win": null,
    "average_loss": -3776.0
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6335
- 最終Entry候補まで到達: 52
- Stage別棄却数（market_regime）: 5205
- Stage別棄却数（htf_bias）: 93
- Stage別棄却数（trend_strength_or_momentum_filter）: 646
- Stage別棄却数（setup_or_trigger）: 339
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5205,
  "RSI_FILTERED": 570,
  "TREND_NOT_ALIGNED": 93,
  "ENTRY_PATTERN_NOT_FOUND": 339,
  "CONFIRMATION_ADX_TOO_LOW": 76
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 20,
    "net_profit": -10978.0,
    "win_rate": 0.35,
    "profit_factor": 0.745130360086365,
    "expectancy": -548.9,
    "average_win": 4585.0,
    "average_loss": -3313.3076923076924
  },
  {
    "direction": "SELL",
    "number_of_trades": 5,
    "net_profit": -1828.0,
    "win_rate": 0.2,
    "profit_factor": 0.8387864891083869,
    "expectancy": -365.6,
    "average_win": 9511.0,
    "average_loss": -2834.75
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 10,
    "net_profit": 3485.0,
    "win_rate": 0.3,
    "profit_factor": 1.2195137314184934,
    "expectancy": 348.5,
    "average_win": 6453.666666666667,
    "average_loss": -2268.0
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 2,
    "net_profit": -1224.0,
    "win_rate": 0.5,
    "profit_factor": 0.6409504253446758,
    "expectancy": -612.0,
    "average_win": 2185.0,
    "average_loss": -3409.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 5,
    "net_profit": -7120.0,
    "win_rate": 0.2,
    "profit_factor": 0.567725092586971,
    "expectancy": -1424.0,
    "average_win": 9351.0,
    "average_loss": -4117.75
  },
  {
    "session": "Tokyo",
    "number_of_trades": 8,
    "net_profit": -7947.0,
    "win_rate": 0.375,
    "profit_factor": 0.5740244425385935,
    "expectancy": -993.375,
    "average_win": 3569.6666666666665,
    "average_loss": -3731.2
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 4,
    "net_profit": -6761.0,
    "win_rate": 0.25,
    "profit_factor": 0.14047800661072973,
    "expectancy": -1690.25,
    "average_win": 1105.0,
    "average_loss": -2622.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": -5719.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.6230059327620303,
    "expectancy": -817.0,
    "average_win": 4725.5,
    "average_loss": -3034.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": -5219.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.2951107509454349,
    "expectancy": -1739.6666666666667,
    "average_win": 2185.0,
    "average_loss": -3702.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": -11439.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3813.0,
    "average_win": null,
    "average_loss": -3813.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 8,
    "net_profit": 16332.0,
    "win_rate": 0.5,
    "profit_factor": 2.303119763823506,
    "expectancy": 2041.5,
    "average_win": 7216.25,
    "average_loss": -3133.25
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.0827-0.161",
    "number_of_trades": 9,
    "net_profit": -15275.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.38730897276483095,
    "expectancy": -1697.2222222222222,
    "average_win": 4828.0,
    "average_loss": -3561.5714285714284
  },
  {
    "atr_band": "ATR_0.161-0.218",
    "number_of_trades": 7,
    "net_profit": 9369.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 1.8607257694074415,
    "expectancy": 1338.4285714285713,
    "average_win": 5063.5,
    "average_loss": -3628.3333333333335
  },
  {
    "atr_band": "ATR_0.218-0.409",
    "number_of_trades": 9,
    "net_profit": -6900.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.6289524628952463,
    "expectancy": -766.6666666666666,
    "average_win": 5848.0,
    "average_loss": -2656.5714285714284
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.18-42.39",
    "number_of_trades": 9,
    "net_profit": -6159.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.6723936170212766,
    "expectancy": -684.3333333333334,
    "average_win": 4213.666666666667,
    "average_loss": -3133.3333333333335
  },
  {
    "adx_band": "ADX_42.39-47.16",
    "number_of_trades": 7,
    "net_profit": -1902.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 0.8368502316006176,
    "expectancy": -271.7142857142857,
    "average_win": 3252.0,
    "average_loss": -2914.5
  },
  {
    "adx_band": "ADX_47.16-59.88",
    "number_of_trades": 9,
    "net_profit": -4745.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.8019119979961593,
    "expectancy": -527.2222222222222,
    "average_win": 9604.5,
    "average_loss": -3422.0
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_-0.001-7.622",
    "number_of_trades": 8,
    "net_profit": -28353.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3544.125,
    "average_win": null,
    "average_loss": -3544.125
  },
  {
    "hold_time_band": "HOLD_H_10.12-31",
    "number_of_trades": 9,
    "net_profit": 20183.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 2.9004708097928438,
    "expectancy": 2242.5555555555557,
    "average_win": 5133.833333333333,
    "average_loss": -3540.0
  },
  {
    "hold_time_band": "HOLD_H_7.622-10.12",
    "number_of_trades": 8,
    "net_profit": -4636.0,
    "win_rate": 0.25,
    "profit_factor": 0.6997214845521083,
    "expectancy": -579.5,
    "average_win": 5401.5,
    "average_loss": -2573.1666666666665
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-260-1015",
    "number_of_trades": 8,
    "net_profit": -31576.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3947.0,
    "average_win": null,
    "average_loss": -3947.0
  },
  {
    "mfe_band": "MFE_1015-5260",
    "number_of_trades": 8,
    "net_profit": -19240.0,
    "win_rate": 0.25,
    "profit_factor": 0.14602751886373724,
    "expectancy": -2405.0,
    "average_win": 1645.0,
    "average_loss": -3755.0
  },
  {
    "mfe_band": "MFE_5260-9581",
    "number_of_trades": 9,
    "net_profit": 38010.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 125.2156862745098,
    "expectancy": 4223.333333333333,
    "average_win": 6386.0,
    "average_loss": -102.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1875--420",
    "number_of_trades": 9,
    "net_profit": 26384.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 5.70219212261629,
    "expectancy": 2931.5555555555557,
    "average_win": 5332.5,
    "average_loss": -1870.3333333333333
  },
  {
    "mae_band": "MAE_-3690--1875",
    "number_of_trades": 7,
    "net_profit": -4676.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.6727094561489466,
    "expectancy": -668.0,
    "average_win": 4805.5,
    "average_loss": -2857.4
  },
  {
    "mae_band": "MAE_-4182--3690",
    "number_of_trades": 9,
    "net_profit": -34514.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3834.8888888888887,
    "average_win": null,
    "average_loss": -3834.8888888888887
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 10,
    "net_profit": 3616.0,
    "win_rate": 0.4,
    "profit_factor": 1.1914949954985967,
    "expectancy": 361.6,
    "average_win": 5624.75,
    "average_loss": -3147.1666666666665
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 15,
    "net_profit": -16422.0,
    "win_rate": 0.26666666666666666,
    "profit_factor": 0.537786033944102,
    "expectancy": -1094.8,
    "average_win": 4776.75,
    "average_loss": -3229.909090909091
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 3,
    "net_profit": -5207.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.2955898268398268,
    "expectancy": -1735.6666666666667,
    "average_win": 2185.0,
    "average_loss": -3696.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 6,
    "net_profit": -15052.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2508.6666666666665,
    "average_win": null,
    "average_loss": -2508.6666666666665
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 16,
    "net_profit": 7453.0,
    "win_rate": 0.4375,
    "profit_factor": 1.2331393893893894,
    "expectancy": 465.8125,
    "average_win": 5631.571428571428,
    "average_loss": -3552.0
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 15,
    "net_profit": -45226.0,
    "win_rate": 0.13333333333333333,
    "profit_factor": 0.06781268035287327,
    "expectancy": -3015.0666666666666,
    "average_win": 1645.0,
    "average_loss": -3732.0
  },
  {
    "close_reason": "SL",
    "number_of_trades": 6,
    "net_profit": -5644.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.042740841248303935,
    "expectancy": -940.6666666666666,
    "average_win": 126.0,
    "average_loss": -1474.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 4,
    "net_profit": 38064.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9516.0,
    "average_win": 9516.0,
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
    "net_profit": -10164.0,
    "win_rate": 0.2,
    "profit_factor": 0.09805661549383264,
    "expectancy": -2032.8,
    "average_win": 1105.0,
    "average_loss": -2817.25
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 5,
    "net_profit": -5386.0,
    "win_rate": 0.2,
    "profit_factor": 0.638280725319006,
    "expectancy": -1077.2,
    "average_win": 9504.0,
    "average_loss": -3722.5
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 7,
    "net_profit": -7786.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5546785632578357,
    "expectancy": -1112.2857142857142,
    "average_win": 9698.0,
    "average_loss": -2914.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 8,
    "net_profit": 10530.0,
    "win_rate": 0.625,
    "profit_factor": 1.9778066672857275,
    "expectancy": 1316.25,
    "average_win": 4259.8,
    "average_loss": -3589.6666666666665
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 5,
    "net_profit": -4576.0,
    "win_rate": 0.4,
    "profit_factor": 0.4182557843885075,
    "expectancy": -915.2,
    "average_win": 1645.0,
    "average_loss": -2622.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 4,
    "net_profit": -11761.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2940.25,
    "average_win": null,
    "average_loss": -2940.25
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 5,
    "net_profit": -1188.0,
    "win_rate": 0.4,
    "profit_factor": 0.8905170030411944,
    "expectancy": -237.6,
    "average_win": 4831.5,
    "average_loss": -3617.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": 2241.0,
    "win_rate": 0.5,
    "profit_factor": 1.3108183079056865,
    "expectancy": 560.25,
    "average_win": 4725.5,
    "average_loss": -3605.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 7,
    "net_profit": 2478.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.1481702941879932,
    "expectancy": 354.0,
    "average_win": 9601.0,
    "average_loss": -3344.8
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0132-0.981",
    "number_of_trades": 8,
    "net_profit": 41606.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 5200.75,
    "average_win": 5200.75,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.981-3.567",
    "number_of_trades": 6,
    "net_profit": -11605.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1934.1666666666667,
    "average_win": null,
    "average_loss": -1934.1666666666667
  },
  {
    "giveback_band": "GIVEBACK_3.567-15.14",
    "number_of_trades": 8,
    "net_profit": -30026.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3753.25,
    "average_win": null,
    "average_loss": -3753.25
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
