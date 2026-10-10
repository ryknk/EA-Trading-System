# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 30
- MFEデータのある負けトレード数: 30
- うち一度含み益になった数: 30
- 割合: 100.00%
- 反転前の平均含み益: 2334.80

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 39
- 平均Giveback比率: 1857.72%
- 中央値Giveback比率: 214.34%
- 損益ゼロ以下まで完全反転した割合: 82.05%

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

- 決済件数: 25
- 純損益: -88384.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3535.36
- 平均逆行幅（R）: 0.7669
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 12,
    "net_profit": -42131.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3510.9166666666665,
    "average_win": null,
    "average_loss": -3510.9166666666665
  },
  "SELL": {
    "number_of_trades": 13,
    "net_profit": -46253.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3557.923076923077,
    "average_win": null,
    "average_loss": -3557.923076923077
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 10264
- 最終Entry候補まで到達: 64
- Stage別棄却数（market_regime）: 8555
- Stage別棄却数（htf_bias）: 362
- Stage別棄却数（trend_strength_or_momentum_filter）: 796
- Stage別棄却数（setup_or_trigger）: 487
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 8555,
  "CONFIRMATION_ADX_TOO_LOW": 84,
  "RSI_FILTERED": 712,
  "ENTRY_PATTERN_NOT_FOUND": 487,
  "TREND_NOT_ALIGNED": 362
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 20,
    "net_profit": -18235.0,
    "win_rate": 0.25,
    "profit_factor": 0.6132309584915265,
    "expectancy": -911.75,
    "average_win": 5782.4,
    "average_loss": -3367.6428571428573
  },
  {
    "direction": "SELL",
    "number_of_trades": 19,
    "net_profit": -29521.0,
    "win_rate": 0.10526315789473684,
    "profit_factor": 0.3772072319149385,
    "expectancy": -1553.7368421052631,
    "average_win": 8940.0,
    "average_loss": -2962.5625
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 13,
    "net_profit": -25005.0,
    "win_rate": 0.15384615384615385,
    "profit_factor": 0.2636275289336514,
    "expectancy": -1923.4615384615386,
    "average_win": 4476.0,
    "average_loss": -3395.7
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 9,
    "net_profit": 520.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 1.028927458834001,
    "expectancy": 57.77777777777778,
    "average_win": 9248.0,
    "average_loss": -2568.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 8,
    "net_profit": -7698.0,
    "win_rate": 0.25,
    "profit_factor": 0.5753296188006841,
    "expectancy": -962.25,
    "average_win": 5214.5,
    "average_loss": -3021.1666666666665
  },
  {
    "session": "Tokyo",
    "number_of_trades": 9,
    "net_profit": -15573.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.36405586409670043,
    "expectancy": -1730.3333333333333,
    "average_win": 8915.0,
    "average_loss": -3498.285714285714
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 11,
    "net_profit": -31447.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.04448360730454863,
    "expectancy": -2858.818181818182,
    "average_win": 1464.0,
    "average_loss": -3656.777777777778
  },
  {
    "weekday": "Mon",
    "number_of_trades": 4,
    "net_profit": 1975.0,
    "win_rate": 0.25,
    "profit_factor": 1.2839683680805176,
    "expectancy": 493.75,
    "average_win": 8930.0,
    "average_loss": -2318.3333333333335
  },
  {
    "weekday": "Thu",
    "number_of_trades": 9,
    "net_profit": -3094.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.7438953728995944,
    "expectancy": -343.77777777777777,
    "average_win": 4493.5,
    "average_loss": -2013.5
  },
  {
    "weekday": "Tue",
    "number_of_trades": 10,
    "net_profit": -21808.0,
    "win_rate": 0.1,
    "profit_factor": 0.3011824270195789,
    "expectancy": -2180.8,
    "average_win": 9399.0,
    "average_loss": -3467.4444444444443
  },
  {
    "weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": 6618.0,
    "win_rate": 0.4,
    "profit_factor": 1.5808320168509742,
    "expectancy": 1323.6,
    "average_win": 9006.0,
    "average_loss": -3798.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.0504-0.179",
    "number_of_trades": 13,
    "net_profit": -27982.0,
    "win_rate": 0.07692307692307693,
    "profit_factor": 0.2419267446900737,
    "expectancy": -2152.4615384615386,
    "average_win": 8930.0,
    "average_loss": -3355.6363636363635
  },
  {
    "atr_band": "ATR_0.179-0.254",
    "number_of_trades": 13,
    "net_profit": -7980.0,
    "win_rate": 0.3076923076923077,
    "profit_factor": 0.7146126886488806,
    "expectancy": -613.8461538461538,
    "average_win": 4995.5,
    "average_loss": -3495.25
  },
  {
    "atr_band": "ATR_0.254-0.636",
    "number_of_trades": 13,
    "net_profit": -11794.0,
    "win_rate": 0.15384615384615385,
    "profit_factor": 0.6025476848419492,
    "expectancy": -907.2307692307693,
    "average_win": 8940.0,
    "average_loss": -2697.6363636363635
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.3-42.37",
    "number_of_trades": 13,
    "net_profit": -36525.0,
    "win_rate": 0.07692307692307693,
    "profit_factor": 0.03853747137329227,
    "expectancy": -2809.6153846153848,
    "average_win": 1464.0,
    "average_loss": -3453.5454545454545
  },
  {
    "adx_band": "ADX_42.37-46.42",
    "number_of_trades": 13,
    "net_profit": -9532.0,
    "win_rate": 0.23076923076923078,
    "profit_factor": 0.6579589493325678,
    "expectancy": -733.2307692307693,
    "average_win": 6112.0,
    "average_loss": -3096.4444444444443
  },
  {
    "adx_band": "ADX_46.42-61.13",
    "number_of_trades": 13,
    "net_profit": -1699.0,
    "win_rate": 0.23076923076923078,
    "profit_factor": 0.9407828238820536,
    "expectancy": -130.69230769230768,
    "average_win": 8997.333333333334,
    "average_loss": -2869.1
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.461-4.182",
    "number_of_trades": 13,
    "net_profit": -47703.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3669.4615384615386,
    "average_win": null,
    "average_loss": -3669.4615384615386
  },
  {
    "hold_time_band": "HOLD_H_4.182-8.238",
    "number_of_trades": 13,
    "net_profit": -13544.0,
    "win_rate": 0.15384615384615385,
    "profit_factor": 0.575063533398174,
    "expectancy": -1041.8461538461538,
    "average_win": 9164.5,
    "average_loss": -3541.4444444444443
  },
  {
    "hold_time_band": "HOLD_H_8.238-60",
    "number_of_trades": 13,
    "net_profit": 13491.0,
    "win_rate": 0.38461538461538464,
    "profit_factor": 1.9010820197702378,
    "expectancy": 1037.7692307692307,
    "average_win": 5692.6,
    "average_loss": -1871.5
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_1850-4102",
    "number_of_trades": 13,
    "net_profit": -37084.0,
    "win_rate": 0.07692307692307693,
    "profit_factor": 0.03797862405312857,
    "expectancy": -2852.6153846153848,
    "average_win": 1464.0,
    "average_loss": -3212.3333333333335
  },
  {
    "mfe_band": "MFE_4102-9321",
    "number_of_trades": 13,
    "net_profit": 32096.0,
    "win_rate": 0.38461538461538464,
    "profit_factor": 3.429674489023467,
    "expectancy": 2468.923076923077,
    "average_win": 9061.2,
    "average_loss": -2201.6666666666665
  },
  {
    "mfe_band": "MFE_9.999-1850",
    "number_of_trades": 13,
    "net_profit": -42768.0,
    "win_rate": 0.07692307692307693,
    "profit_factor": 0.0005141388174807198,
    "expectancy": -3289.846153846154,
    "average_win": 22.0,
    "average_loss": -3565.8333333333335
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-3214--459",
    "number_of_trades": 13,
    "net_profit": 42742.0,
    "win_rate": 0.5384615384615384,
    "profit_factor": 11.55358024691358,
    "expectancy": 3287.846153846154,
    "average_win": 6684.571428571428,
    "average_loss": -1012.5
  },
  {
    "mae_band": "MAE_-3564--3214",
    "number_of_trades": 13,
    "net_profit": -41363.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3181.769230769231,
    "average_win": null,
    "average_loss": -3181.769230769231
  },
  {
    "mae_band": "MAE_-4264--3564",
    "number_of_trades": 13,
    "net_profit": -49135.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3779.6153846153848,
    "average_win": null,
    "average_loss": -3779.6153846153848
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 17,
    "net_profit": -22481.0,
    "win_rate": 0.17647058823529413,
    "profit_factor": 0.44330535126166953,
    "expectancy": -1322.4117647058824,
    "average_win": 5967.333333333333,
    "average_loss": -2884.5
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 22,
    "net_profit": -25275.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.533370257546386,
    "expectancy": -1148.8636363636363,
    "average_win": 7222.5,
    "average_loss": -3385.3125
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": -3440.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1720.0,
    "average_win": null,
    "average_loss": -1720.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 8,
    "net_profit": 4625.0,
    "win_rate": 0.25,
    "profit_factor": 1.3374927028604786,
    "expectancy": 578.125,
    "average_win": 9164.5,
    "average_loss": -2740.8
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 29,
    "net_profit": -48941.0,
    "win_rate": 0.1724137931034483,
    "profit_factor": 0.36772001446953645,
    "expectancy": -1687.6206896551723,
    "average_win": 5692.6,
    "average_loss": -3365.391304347826
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 28,
    "net_profit": -87718.0,
    "win_rate": 0.07142857142857142,
    "profit_factor": 0.01665844580960495,
    "expectancy": -3132.785714285714,
    "average_win": 743.0,
    "average_loss": -3430.923076923077
  },
  {
    "close_reason": "SL",
    "number_of_trades": 6,
    "net_profit": -5344.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -890.6666666666666,
    "average_win": null,
    "average_loss": -1336.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 5,
    "net_profit": 45306.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9061.2,
    "average_win": 9061.2,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 10,
    "net_profit": -12355.0,
    "win_rate": 0.2,
    "profit_factor": 0.45773349719101125,
    "expectancy": -1235.5,
    "average_win": 5214.5,
    "average_loss": -3254.8571428571427
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": -732.0,
    "win_rate": 0.25,
    "profit_factor": 0.9605964364536793,
    "expectancy": -91.5,
    "average_win": 8922.5,
    "average_loss": -3715.4
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 12,
    "net_profit": -7313.0,
    "win_rate": 0.25,
    "profit_factor": 0.7168905578568386,
    "expectancy": -609.4166666666666,
    "average_win": 6172.666666666667,
    "average_loss": -2870.1111111111113
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 9,
    "net_profit": -27356.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3039.5555555555557,
    "average_win": null,
    "average_loss": -3039.5555555555557
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 12,
    "net_profit": -18454.0,
    "win_rate": 0.08333333333333333,
    "profit_factor": 0.3269630548160035,
    "expectancy": -1537.8333333333333,
    "average_win": 8965.0,
    "average_loss": -2741.9
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": -3201.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.7645457888929753,
    "expectancy": -457.2857142857143,
    "average_win": 5197.0,
    "average_loss": -2719.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 7,
    "net_profit": -5843.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.6094773426012565,
    "expectancy": -834.7142857142857,
    "average_win": 4559.5,
    "average_loss": -3740.5
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 9,
    "net_profit": -18716.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.33430553085541526,
    "expectancy": -2079.5555555555557,
    "average_win": 9399.0,
    "average_loss": -3514.375
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 4,
    "net_profit": -1542.0,
    "win_rate": 0.25,
    "profit_factor": 0.8525389691115999,
    "expectancy": -385.5,
    "average_win": 8915.0,
    "average_loss": -3485.6666666666665
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00937-1.556",
    "number_of_trades": 13,
    "net_profit": 45581.0,
    "win_rate": 0.5384615384615384,
    "profit_factor": 38.639141205615196,
    "expectancy": 3506.230769230769,
    "average_win": 6684.571428571428,
    "average_loss": -302.75
  },
  {
    "giveback_band": "GIVEBACK_1.556-2.751",
    "number_of_trades": 13,
    "net_profit": -47007.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3615.923076923077,
    "average_win": null,
    "average_loss": -3615.923076923077
  },
  {
    "giveback_band": "GIVEBACK_2.751-346",
    "number_of_trades": 13,
    "net_profit": -46330.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3563.846153846154,
    "average_win": null,
    "average_loss": -3563.846153846154
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
