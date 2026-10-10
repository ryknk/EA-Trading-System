# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 13
- MFEデータのある負けトレード数: 13
- うち一度含み益になった数: 12
- 割合: 92.31%
- 反転前の平均含み益: 1755.42

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 28
- 平均Giveback比率: 537.37%
- 中央値Giveback比率: 98.25%
- 損益ゼロ以下まで完全反転した割合: 46.43%

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

- 決済件数: 11
- 純損益: -40166.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3651.45
- 平均逆行幅（R）: 0.7611
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 10,
    "net_profit": -36344.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3634.4,
    "average_win": null,
    "average_loss": -3634.4
  },
  "SELL": {
    "number_of_trades": 1,
    "net_profit": -3822.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3822.0,
    "average_win": null,
    "average_loss": -3822.0
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6345
- 最終Entry候補まで到達: 50
- Stage別棄却数（market_regime）: 5185
- Stage別棄却数（htf_bias）: 175
- Stage別棄却数（trend_strength_or_momentum_filter）: 508
- Stage別棄却数（setup_or_trigger）: 427
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5185,
  "ENTRY_PATTERN_NOT_FOUND": 427,
  "RSI_FILTERED": 461,
  "CONFIRMATION_ADX_TOO_LOW": 47,
  "TREND_NOT_ALIGNED": 175
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 27,
    "net_profit": 17776.0,
    "win_rate": 0.5185185185185185,
    "profit_factor": 1.4155504126049046,
    "expectancy": 658.3703703703703,
    "average_win": 4325.214285714285,
    "average_loss": -3564.75
  },
  {
    "direction": "SELL",
    "number_of_trades": 2,
    "net_profit": 5412.0,
    "win_rate": 0.5,
    "profit_factor": 2.416012558869702,
    "expectancy": 2706.0,
    "average_win": 9234.0,
    "average_loss": -3822.0
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 6,
    "net_profit": 4208.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2861417108663131,
    "expectancy": 701.3333333333334,
    "average_win": 9457.0,
    "average_loss": -3676.5
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 10,
    "net_profit": -5181.0,
    "win_rate": 0.6,
    "profit_factor": 0.6837575535616187,
    "expectancy": -518.1,
    "average_win": 1867.0,
    "average_loss": -4095.75
  },
  {
    "session": "NewYork",
    "number_of_trades": 4,
    "net_profit": -7946.0,
    "win_rate": 0.25,
    "profit_factor": 0.011322632823192734,
    "expectancy": -1986.5,
    "average_win": 91.0,
    "average_loss": -2679.0
  },
  {
    "session": "Tokyo",
    "number_of_trades": 9,
    "net_profit": 32107.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 5.2964003746821895,
    "expectancy": 3567.4444444444443,
    "average_win": 6596.666666666667,
    "average_loss": -3736.5
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 7,
    "net_profit": 16612.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 2.3219799458857233,
    "expectancy": 2373.1428571428573,
    "average_win": 7294.5,
    "average_loss": -4188.666666666667
  },
  {
    "weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": -8583.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 0.24017351274787535,
    "expectancy": -1226.142857142857,
    "average_win": 904.3333333333334,
    "average_loss": -3765.3333333333335
  },
  {
    "weekday": "Thu",
    "number_of_trades": 6,
    "net_profit": 11540.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 2.599002355549397,
    "expectancy": 1923.3333333333333,
    "average_win": 4689.25,
    "average_loss": -3608.5
  },
  {
    "weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": -11698.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2924.5,
    "average_win": null,
    "average_loss": -2924.5
  },
  {
    "weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": 15317.0,
    "win_rate": 0.8,
    "profit_factor": 5.007587650444793,
    "expectancy": 3063.4,
    "average_win": 4784.75,
    "average_loss": -3822.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.0739-0.145",
    "number_of_trades": 10,
    "net_profit": -13213.0,
    "win_rate": 0.4,
    "profit_factor": 0.43410852713178294,
    "expectancy": -1321.3,
    "average_win": 2534.0,
    "average_loss": -3891.5
  },
  {
    "atr_band": "ATR_0.145-0.214",
    "number_of_trades": 9,
    "net_profit": 10385.0,
    "win_rate": 0.5555555555555556,
    "profit_factor": 1.955821445006903,
    "expectancy": 1153.888888888889,
    "average_win": 4250.0,
    "average_loss": -3621.6666666666665
  },
  {
    "atr_band": "ATR_0.214-0.631",
    "number_of_trades": 10,
    "net_profit": 26016.0,
    "win_rate": 0.6,
    "profit_factor": 3.100605571255551,
    "expectancy": 2601.6,
    "average_win": 6400.166666666667,
    "average_loss": -3096.25
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.29-42.27",
    "number_of_trades": 10,
    "net_profit": 16828.0,
    "win_rate": 0.5,
    "profit_factor": 2.4376762067492526,
    "expectancy": 1682.8,
    "average_win": 5706.6,
    "average_loss": -2926.25
  },
  {
    "adx_band": "ADX_42.27-45.89",
    "number_of_trades": 9,
    "net_profit": 982.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 1.0494511028300937,
    "expectancy": 109.11111111111111,
    "average_win": 5210.0,
    "average_loss": -3971.6
  },
  {
    "adx_band": "ADX_45.89-56.57",
    "number_of_trades": 10,
    "net_profit": 5378.0,
    "win_rate": 0.6,
    "profit_factor": 1.3576749135408352,
    "expectancy": 537.8,
    "average_win": 3402.3333333333335,
    "average_loss": -3759.0
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.709-7.162",
    "number_of_trades": 10,
    "net_profit": 15423.0,
    "win_rate": 0.4,
    "profit_factor": 1.7062136544713586,
    "expectancy": 1542.3,
    "average_win": 9315.5,
    "average_loss": -3639.8333333333335
  },
  {
    "hold_time_band": "HOLD_H_15.8-88",
    "number_of_trades": 10,
    "net_profit": 4609.0,
    "win_rate": 0.8,
    "profit_factor": 1.516183223205286,
    "expectancy": 460.9,
    "average_win": 1692.25,
    "average_loss": -4464.5
  },
  {
    "hold_time_band": "HOLD_H_7.162-15.8",
    "number_of_trades": 9,
    "net_profit": 3156.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.1993556945234034,
    "expectancy": 350.6666666666667,
    "average_win": 6329.0,
    "average_loss": -3166.2
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-0.001-2130",
    "number_of_trades": 10,
    "net_profit": -28844.0,
    "win_rate": 0.1,
    "profit_factor": 0.03724966622162884,
    "expectancy": -2884.4,
    "average_win": 1116.0,
    "average_loss": -3328.8888888888887
  },
  {
    "mfe_band": "MFE_2130-8546",
    "number_of_trades": 9,
    "net_profit": -13725.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 0.17513071699020374,
    "expectancy": -1525.0,
    "average_win": 728.5,
    "average_loss": -4159.75
  },
  {
    "mfe_band": "MFE_8546-9500",
    "number_of_trades": 10,
    "net_profit": 65757.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 6575.7,
    "average_win": 6575.7,
    "average_loss": null
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2215--264",
    "number_of_trades": 10,
    "net_profit": 57477.0,
    "win_rate": 0.9,
    "profit_factor": null,
    "expectancy": 5747.7,
    "average_win": 6386.333333333333,
    "average_loss": null
  },
  {
    "mae_band": "MAE_-3545--2215",
    "number_of_trades": 9,
    "net_profit": 4280.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 1.5330012453300124,
    "expectancy": 475.55555555555554,
    "average_win": 2051.6666666666665,
    "average_loss": -2676.6666666666665
  },
  {
    "mae_band": "MAE_-6942--3545",
    "number_of_trades": 10,
    "net_profit": -38569.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3856.9,
    "average_win": null,
    "average_loss": -3856.9
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 2,
    "net_profit": 8191.0,
    "win_rate": 0.5,
    "profit_factor": 8.853307766059444,
    "expectancy": 4095.5,
    "average_win": 9234.0,
    "average_loss": -1043.0
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 27,
    "net_profit": 14997.0,
    "win_rate": 0.5185185185185185,
    "profit_factor": 1.3291992273246114,
    "expectancy": 555.4444444444445,
    "average_win": 4325.214285714285,
    "average_loss": -3796.3333333333335
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 3,
    "net_profit": 164.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 1.1572387344199424,
    "expectancy": 54.666666666666664,
    "average_win": 603.5,
    "average_loss": -1043.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 1,
    "net_profit": 0.0,
    "win_rate": 0.0,
    "profit_factor": null,
    "expectancy": 0.0,
    "average_win": null,
    "average_loss": null
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 25,
    "net_profit": 23024.0,
    "win_rate": 0.52,
    "profit_factor": 1.5053999473175872,
    "expectancy": 920.96,
    "average_win": 5275.384615384615,
    "average_loss": -3796.3333333333335
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 14,
    "net_profit": -37704.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.08505423572520567,
    "expectancy": -2693.1428571428573,
    "average_win": 1752.5,
    "average_loss": -3434.0833333333335
  },
  {
    "close_reason": "SL",
    "number_of_trades": 8,
    "net_profit": -4359.0,
    "win_rate": 0.75,
    "profit_factor": 0.19128014842300556,
    "expectancy": -544.875,
    "average_win": 171.83333333333334,
    "average_loss": -5390.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 7,
    "net_profit": 65251.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9321.57142857143,
    "average_win": 9321.57142857143,
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
    "net_profit": 4269.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.2883095833051934,
    "expectancy": 609.8571428571429,
    "average_win": 6358.666666666667,
    "average_loss": -3701.75
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 5,
    "net_profit": 6147.0,
    "win_rate": 0.6,
    "profit_factor": 2.6924559471365637,
    "expectancy": 1229.4,
    "average_win": 3259.6666666666665,
    "average_loss": -3632.0
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 6,
    "net_profit": 20627.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 3.8155883155883155,
    "expectancy": 3437.8333333333335,
    "average_win": 6988.25,
    "average_loss": -3663.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 11,
    "net_profit": -7855.0,
    "win_rate": 0.45454545454545453,
    "profit_factor": 0.6229720648939234,
    "expectancy": -714.0909090909091,
    "average_win": 2595.8,
    "average_loss": -3472.3333333333335
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 8,
    "net_profit": 17624.0,
    "win_rate": 0.625,
    "profit_factor": 2.637766006876684,
    "expectancy": 2203.0,
    "average_win": 5677.0,
    "average_loss": -3587.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 5,
    "net_profit": -16686.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3337.2,
    "average_win": null,
    "average_loss": -4171.5
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 6,
    "net_profit": 11364.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 2.524550576871478,
    "expectancy": 1894.0,
    "average_win": 4704.5,
    "average_loss": -3727.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 5,
    "net_profit": 161.0,
    "win_rate": 0.8,
    "profit_factor": 1.0438931297709924,
    "expectancy": 32.2,
    "average_win": 957.25,
    "average_loss": -3668.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": 10725.0,
    "win_rate": 0.4,
    "profit_factor": 2.335616438356164,
    "expectancy": 2145.0,
    "average_win": 9377.5,
    "average_loss": -2676.6666666666665
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00926-0.955",
    "number_of_trades": 9,
    "net_profit": 68756.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7639.555555555556,
    "average_win": 7639.555555555556,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.955-2.221",
    "number_of_trades": 9,
    "net_profit": -3900.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 0.2090853782194281,
    "expectancy": -433.3333333333333,
    "average_win": 171.83333333333334,
    "average_loss": -2465.5
  },
  {
    "giveback_band": "GIVEBACK_2.221-65.86",
    "number_of_trades": 10,
    "net_profit": -38122.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3812.2,
    "average_win": null,
    "average_loss": -3812.2
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
