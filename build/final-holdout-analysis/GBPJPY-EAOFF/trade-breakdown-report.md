# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 35
- MFEデータのある負けトレード数: 35
- うち一度含み益になった数: 32
- 割合: 91.43%
- 反転前の平均含み益: 2374.28

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 49
- 平均Giveback比率: 1318.06%
- 中央値Giveback比率: 155.28%
- 損益ゼロ以下まで完全反転した割合: 67.35%

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

- 決済件数: 0
- 純損益: 0.00
- プロフィットファクター: 算出不能
- 勝率: 算出不能
- 期待値: 0.00
- 平均逆行幅（R）: 算出不能
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 10488
- 最終Entry候補まで到達: 107
- Stage別棄却数（market_regime）: 8825
- Stage別棄却数（htf_bias）: 240
- Stage別棄却数（trend_strength_or_momentum_filter）: 755
- Stage別棄却数（setup_or_trigger）: 561
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 8825,
  "CONFIRMATION_ADX_TOO_LOW": 119,
  "RSI_FILTERED": 636,
  "ENTRY_PATTERN_NOT_FOUND": 561,
  "TREND_NOT_ALIGNED": 240
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 46,
    "net_profit": -14564.0,
    "win_rate": 0.32608695652173914,
    "profit_factor": 0.8583392504547267,
    "expectancy": -316.60869565217394,
    "average_win": 5883.0,
    "average_loss": -3426.9666666666667
  },
  {
    "direction": "SELL",
    "number_of_trades": 6,
    "net_profit": -13361.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.41789744260009587,
    "expectancy": -2226.8333333333335,
    "average_win": 9592.0,
    "average_loss": -4590.6
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 7,
    "net_profit": 22294.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 5.53222199634072,
    "expectancy": 3184.8571428571427,
    "average_win": 6803.25,
    "average_loss": -2459.5
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 18,
    "net_profit": -20021.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.5615103265511728,
    "expectancy": -1112.2777777777778,
    "average_win": 4273.0,
    "average_loss": -3804.9166666666665
  },
  {
    "session": "NewYork",
    "number_of_trades": 14,
    "net_profit": -33900.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.21025043680838673,
    "expectancy": -2421.4285714285716,
    "average_win": 4512.5,
    "average_loss": -3577.0833333333335
  },
  {
    "session": "Tokyo",
    "number_of_trades": 13,
    "net_profit": 3702.0,
    "win_rate": 0.3076923076923077,
    "profit_factor": 1.114758671998512,
    "expectancy": 284.7692307692308,
    "average_win": 8990.25,
    "average_loss": -3584.3333333333335
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 8,
    "net_profit": -17060.0,
    "win_rate": 0.125,
    "profit_factor": 0.1397307246230649,
    "expectancy": -2132.5,
    "average_win": 2771.0,
    "average_loss": -2833.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 12,
    "net_profit": 13827.0,
    "win_rate": 0.4166666666666667,
    "profit_factor": 1.5908216895269838,
    "expectancy": 1152.25,
    "average_win": 7446.0,
    "average_loss": -3343.285714285714
  },
  {
    "weekday": "Thu",
    "number_of_trades": 10,
    "net_profit": -607.0,
    "win_rate": 0.3,
    "profit_factor": 0.978171749136939,
    "expectancy": -60.7,
    "average_win": 9067.0,
    "average_loss": -3972.5714285714284
  },
  {
    "weekday": "Tue",
    "number_of_trades": 15,
    "net_profit": -19929.0,
    "win_rate": 0.26666666666666666,
    "profit_factor": 0.4851983880967142,
    "expectancy": -1328.6,
    "average_win": 4695.75,
    "average_loss": -3871.2
  },
  {
    "weekday": "Wed",
    "number_of_trades": 7,
    "net_profit": -4156.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 0.7403798100949526,
    "expectancy": -593.7142857142857,
    "average_win": 3950.6666666666665,
    "average_loss": -4002.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.148-0.253",
    "number_of_trades": 18,
    "net_profit": 19123.0,
    "win_rate": 0.5,
    "profit_factor": 1.5592174523336062,
    "expectancy": 1062.388888888889,
    "average_win": 5924.333333333333,
    "average_loss": -4274.5
  },
  {
    "atr_band": "ATR_0.253-0.308",
    "number_of_trades": 17,
    "net_profit": -6353.0,
    "win_rate": 0.23529411764705882,
    "profit_factor": 0.8273031233859788,
    "expectancy": -373.70588235294116,
    "average_win": 7608.5,
    "average_loss": -2829.769230769231
  },
  {
    "atr_band": "ATR_0.308-0.464",
    "number_of_trades": 17,
    "net_profit": -40695.0,
    "win_rate": 0.17647058823529413,
    "profit_factor": 0.257105825224995,
    "expectancy": -2393.823529411765,
    "average_win": 4694.666666666667,
    "average_loss": -3912.785714285714
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.18-42.34",
    "number_of_trades": 18,
    "net_profit": -656.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.9842685851318945,
    "expectancy": -36.44444444444444,
    "average_win": 6840.666666666667,
    "average_loss": -3475.0
  },
  {
    "adx_band": "ADX_42.34-45.78",
    "number_of_trades": 17,
    "net_profit": -24216.0,
    "win_rate": 0.23529411764705882,
    "profit_factor": 0.4225486455551316,
    "expectancy": -1424.4705882352941,
    "average_win": 4430.0,
    "average_loss": -3494.6666666666665
  },
  {
    "adx_band": "ADX_45.78-67.96",
    "number_of_trades": 17,
    "net_profit": -3053.0,
    "win_rate": 0.35294117647058826,
    "profit_factor": 0.927526942980582,
    "expectancy": -179.58823529411765,
    "average_win": 6512.166666666667,
    "average_loss": -3829.6363636363635
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.988-9.178",
    "number_of_trades": 17,
    "net_profit": -38678.0,
    "win_rate": 0.11764705882352941,
    "profit_factor": 0.32043713542764773,
    "expectancy": -2275.176470588235,
    "average_win": 9119.0,
    "average_loss": -4065.4285714285716
  },
  {
    "hold_time_band": "HOLD_H_15.97-76.59",
    "number_of_trades": 18,
    "net_profit": 16664.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 1.691854189155526,
    "expectancy": 925.7777777777778,
    "average_win": 5093.75,
    "average_loss": -2408.6
  },
  {
    "hold_time_band": "HOLD_H_9.178-15.97",
    "number_of_trades": 17,
    "net_profit": -5911.0,
    "win_rate": 0.35294117647058826,
    "profit_factor": 0.8679401251117069,
    "expectancy": -347.70588235294116,
    "average_win": 6474.833333333333,
    "average_loss": -4069.090909090909
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-120-1682",
    "number_of_trades": 17,
    "net_profit": -77698.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4570.470588235294,
    "average_win": null,
    "average_loss": -4570.470588235294
  },
  {
    "mfe_band": "MFE_1682-4696",
    "number_of_trades": 18,
    "net_profit": -37542.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.20228634567166717,
    "expectancy": -2085.6666666666665,
    "average_win": 2380.0,
    "average_loss": -3361.5714285714284
  },
  {
    "mfe_band": "MFE_4696-9536",
    "number_of_trades": 17,
    "net_profit": 87315.0,
    "win_rate": 0.7058823529411765,
    "profit_factor": 88.14071856287426,
    "expectancy": 5136.176470588235,
    "average_win": 7359.75,
    "average_loss": -250.5
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2536--444",
    "number_of_trades": 18,
    "net_profit": 74112.0,
    "win_rate": 0.6111111111111112,
    "profit_factor": 30.479713603818617,
    "expectancy": 4117.333333333333,
    "average_win": 6966.0,
    "average_loss": -419.0
  },
  {
    "mae_band": "MAE_-4454--2536",
    "number_of_trades": 16,
    "net_profit": -25617.0,
    "win_rate": 0.25,
    "profit_factor": 0.4185486982772318,
    "expectancy": -1601.0625,
    "average_win": 4610.0,
    "average_loss": -3671.4166666666665
  },
  {
    "mae_band": "MAE_-7669--4454",
    "number_of_trades": 18,
    "net_profit": -76420.0,
    "win_rate": 0.05555555555555555,
    "profit_factor": 0.03499135002714955,
    "expectancy": -4245.555555555556,
    "average_win": 2771.0,
    "average_loss": -4658.294117647059
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 12,
    "net_profit": 4091.0,
    "win_rate": 0.4166666666666667,
    "profit_factor": 1.1488177519097853,
    "expectancy": 340.9166666666667,
    "average_win": 6316.2,
    "average_loss": -4581.666666666667
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 40,
    "net_profit": -32016.0,
    "win_rate": 0.275,
    "profit_factor": 0.6742103549332465,
    "expectancy": -800.4,
    "average_win": 6023.272727272727,
    "average_loss": -3388.689655172414
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 5,
    "net_profit": -5370.0,
    "win_rate": 0.2,
    "profit_factor": 0.6308263440120996,
    "expectancy": -1074.0,
    "average_win": 9176.0,
    "average_loss": -3636.5
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 4,
    "net_profit": 26008.0,
    "win_rate": 0.75,
    "profit_factor": null,
    "expectancy": 6502.0,
    "average_win": 8669.333333333334,
    "average_loss": null
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 43,
    "net_profit": -48563.0,
    "win_rate": 0.27906976744186046,
    "profit_factor": 0.56334520212919,
    "expectancy": -1129.3720930232557,
    "average_win": 5221.083333333333,
    "average_loss": -3587.6129032258063
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 9,
    "net_profit": 784.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 1.0897435897435896,
    "expectancy": 87.11111111111111,
    "average_win": 2380.0,
    "average_loss": -1747.2
  },
  {
    "close_reason": "SL",
    "number_of_trades": 33,
    "net_profit": -116895.0,
    "win_rate": 0.06060606060606061,
    "profit_factor": 0.0011194093620221148,
    "expectancy": -3542.2727272727275,
    "average_win": 65.5,
    "average_loss": -3900.866666666667
  },
  {
    "close_reason": "TP",
    "number_of_trades": 10,
    "net_profit": 88186.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8818.6,
    "average_win": 8818.6,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 17,
    "net_profit": -18164.0,
    "win_rate": 0.29411764705882354,
    "profit_factor": 0.5988604491950266,
    "expectancy": -1068.4705882352941,
    "average_win": 5423.4,
    "average_loss": -4116.454545454545
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 10,
    "net_profit": 18561.0,
    "win_rate": 0.4,
    "profit_factor": 2.141864041833282,
    "expectancy": 1856.1,
    "average_win": 8704.0,
    "average_loss": -2709.1666666666665
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 7,
    "net_profit": -10597.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.4640671622920144,
    "expectancy": -1513.857142857143,
    "average_win": 9176.0,
    "average_loss": -3295.5
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 18,
    "net_profit": -17725.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.6012642566305986,
    "expectancy": -984.7222222222222,
    "average_win": 4454.666666666667,
    "average_loss": -3704.4166666666665
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 11,
    "net_profit": -28108.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.24177928839254403,
    "expectancy": -2555.2727272727275,
    "average_win": 8963.0,
    "average_loss": -3707.1
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": -3178.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.7898842975206611,
    "expectancy": -454.0,
    "average_win": 5973.5,
    "average_loss": -3025.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 10,
    "net_profit": -611.0,
    "win_rate": 0.4,
    "profit_factor": 0.9722361066933248,
    "expectancy": -61.1,
    "average_win": 5349.0,
    "average_loss": -3667.8333333333335
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 14,
    "net_profit": -725.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.9739555268168265,
    "expectancy": -51.785714285714285,
    "average_win": 6778.0,
    "average_loss": -3093.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 10,
    "net_profit": 4697.0,
    "win_rate": 0.5,
    "profit_factor": 1.198001854818312,
    "expectancy": 469.7,
    "average_win": 5683.8,
    "average_loss": -4744.4
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0165-1",
    "number_of_trades": 17,
    "net_profit": 97837.0,
    "win_rate": 0.9411764705882353,
    "profit_factor": null,
    "expectancy": 5755.117647058823,
    "average_win": 6114.8125,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1-3.057",
    "number_of_trades": 15,
    "net_profit": -33823.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2254.866666666667,
    "average_win": null,
    "average_loss": -2254.866666666667
  },
  {
    "giveback_band": "GIVEBACK_3.057-350",
    "number_of_trades": 17,
    "net_profit": -78000.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4588.235294117647,
    "average_win": null,
    "average_loss": -4588.235294117647
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
