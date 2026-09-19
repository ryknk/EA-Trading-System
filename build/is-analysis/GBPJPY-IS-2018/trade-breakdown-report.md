# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 24
- MFEデータのある負けトレード数: 24
- うち一度含み益になった数: 24
- 割合: 100.00%
- 反転前の平均含み益: 1927.71

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 33
- 平均Giveback比率: 932.55%
- 中央値Giveback比率: 302.24%
- 損益ゼロ以下まで完全反転した割合: 72.73%

## Time Stop（時間切れ決済）

- Time Stopによる決済件数: 1
- 純損益: 390.00
- プロフィットファクター: 算出不能
- 勝率: 100.00%
- 期待値: 390.00

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

- 決済件数: 21
- 純損益: -76475.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3641.67
- 平均逆行幅（R）: 0.7670
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 10,
    "net_profit": -36289.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3628.9,
    "average_win": null,
    "average_loss": -3628.9
  },
  "SELL": {
    "number_of_trades": 11,
    "net_profit": -40186.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3653.2727272727275,
    "average_win": null,
    "average_loss": -3653.2727272727275
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6192
- 最終Entry候補まで到達: 55
- Stage別棄却数（market_regime）: 5147
- Stage別棄却数（htf_bias）: 159
- Stage別棄却数（trend_strength_or_momentum_filter）: 497
- Stage別棄却数（setup_or_trigger）: 334
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5147,
  "ENTRY_PATTERN_NOT_FOUND": 334,
  "RSI_FILTERED": 454,
  "TREND_NOT_ALIGNED": 159,
  "CONFIRMATION_ADX_TOO_LOW": 43
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 14,
    "net_profit": -15683.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.56783047204387,
    "expectancy": -1120.2142857142858,
    "average_win": 5151.5,
    "average_loss": -3628.9
  },
  {
    "direction": "SELL",
    "number_of_trades": 19,
    "net_profit": -11805.0,
    "win_rate": 0.2631578947368421,
    "profit_factor": 0.7116934499096371,
    "expectancy": -621.3157894736842,
    "average_win": 5828.2,
    "average_loss": -2924.714285714286
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 7,
    "net_profit": -18636.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2662.285714285714,
    "average_win": null,
    "average_loss": -2662.285714285714
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 5,
    "net_profit": -5666.0,
    "win_rate": 0.2,
    "profit_factor": 0.6189643577673167,
    "expectancy": -1133.2,
    "average_win": 9204.0,
    "average_loss": -3717.5
  },
  {
    "session": "NewYork",
    "number_of_trades": 6,
    "net_profit": 13649.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 2.9847317144103536,
    "expectancy": 2274.8333333333335,
    "average_win": 5131.5,
    "average_loss": -3438.5
  },
  {
    "session": "Tokyo",
    "number_of_trades": 15,
    "net_profit": -16835.0,
    "win_rate": 0.26666666666666666,
    "profit_factor": 0.5431726907630522,
    "expectancy": -1122.3333333333333,
    "average_win": 5004.25,
    "average_loss": -3350.181818181818
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 9,
    "net_profit": 9712.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 1.5261105092091007,
    "expectancy": 1079.111111111111,
    "average_win": 7043.0,
    "average_loss": -3692.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": -9226.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.49940314704286487,
    "expectancy": -1318.0,
    "average_win": 9204.0,
    "average_loss": -3071.6666666666665
  },
  {
    "weekday": "Thu",
    "number_of_trades": 7,
    "net_profit": -14721.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.025809013301568394,
    "expectancy": -2103.0,
    "average_win": 390.0,
    "average_loss": -2518.5
  },
  {
    "weekday": "Tue",
    "number_of_trades": 2,
    "net_profit": -1631.0,
    "win_rate": 0.5,
    "profit_factor": 0.5615591397849462,
    "expectancy": -815.5,
    "average_win": 2089.0,
    "average_loss": -3720.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 8,
    "net_profit": -11622.0,
    "win_rate": 0.25,
    "profit_factor": 0.4597936227572743,
    "expectancy": -1452.75,
    "average_win": 4946.0,
    "average_loss": -3585.6666666666665
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.141-0.196",
    "number_of_trades": 11,
    "net_profit": -293.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.9846460200178169,
    "expectancy": -26.636363636363637,
    "average_win": 6263.333333333333,
    "average_loss": -2385.375
  },
  {
    "atr_band": "ATR_0.196-0.262",
    "number_of_trades": 11,
    "net_profit": -8797.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.7015133007600435,
    "expectancy": -799.7272727272727,
    "average_win": 6891.666666666667,
    "average_loss": -3684.0
  },
  {
    "atr_band": "ATR_0.262-0.32",
    "number_of_trades": 11,
    "net_profit": -18398.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.35850767085076707,
    "expectancy": -1672.5454545454545,
    "average_win": 3427.3333333333335,
    "average_loss": -3585.0
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.02-42.61",
    "number_of_trades": 11,
    "net_profit": 5590.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 1.2548554755174615,
    "expectancy": 508.1818181818182,
    "average_win": 9174.666666666666,
    "average_loss": -2741.75
  },
  {
    "adx_band": "ADX_42.61-45.25",
    "number_of_trades": 11,
    "net_profit": -19091.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.3585013440860215,
    "expectancy": -1735.5454545454545,
    "average_win": 3556.3333333333335,
    "average_loss": -3720.0
  },
  {
    "adx_band": "ADX_45.25-70.88",
    "number_of_trades": 11,
    "net_profit": -13987.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.4523706980932618,
    "expectancy": -1271.5454545454545,
    "average_win": 3851.3333333333335,
    "average_loss": -3192.625
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_1.01-4.393",
    "number_of_trades": 11,
    "net_profit": -27632.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.2498642632207623,
    "expectancy": -2512.0,
    "average_win": 9204.0,
    "average_loss": -3683.6
  },
  {
    "hold_time_band": "HOLD_H_4.393-9.691",
    "number_of_trades": 11,
    "net_profit": -19530.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.3270158511371468,
    "expectancy": -1775.4545454545455,
    "average_win": 9490.0,
    "average_loss": -2902.0
  },
  {
    "hold_time_band": "HOLD_H_9.691-79.33",
    "number_of_trades": 11,
    "net_profit": 19674.0,
    "win_rate": 0.6363636363636364,
    "profit_factor": 2.7289744265752702,
    "expectancy": 1788.5454545454545,
    "average_win": 4436.142857142857,
    "average_loss": -2844.75
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_1108-4903",
    "number_of_trades": 11,
    "net_profit": -35732.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.010796744366314158,
    "expectancy": -3248.3636363636365,
    "average_win": 390.0,
    "average_loss": -3612.2
  },
  {
    "mfe_band": "MFE_21-1108",
    "number_of_trades": 11,
    "net_profit": -40353.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3668.4545454545455,
    "average_win": null,
    "average_loss": -3668.4545454545455
  },
  {
    "mfe_band": "MFE_4903-9360",
    "number_of_trades": 11,
    "net_profit": 48597.0,
    "win_rate": 0.7272727272727273,
    "profit_factor": 64.94342105263158,
    "expectancy": 4417.909090909091,
    "average_win": 6169.625,
    "average_loss": -253.33333333333334
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2813--304",
    "number_of_trades": 11,
    "net_profit": 39497.0,
    "win_rate": 0.7272727272727273,
    "profit_factor": 52.96973684210526,
    "expectancy": 3590.6363636363635,
    "average_win": 5032.125,
    "average_loss": -253.33333333333334
  },
  {
    "mae_band": "MAE_-3645--2813",
    "number_of_trades": 11,
    "net_profit": -25510.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.27114285714285713,
    "expectancy": -2319.090909090909,
    "average_win": 9490.0,
    "average_loss": -3500.0
  },
  {
    "mae_band": "MAE_-4037--3645",
    "number_of_trades": 11,
    "net_profit": -41475.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3770.4545454545455,
    "average_win": null,
    "average_loss": -3770.4545454545455
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 17,
    "net_profit": 8221.0,
    "win_rate": 0.35294117647058826,
    "profit_factor": 1.272787603278362,
    "expectancy": 483.5882352941176,
    "average_win": 6393.0,
    "average_loss": -2739.7272727272725
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 16,
    "net_profit": -35709.0,
    "win_rate": 0.1875,
    "profit_factor": 0.24181493906322987,
    "expectancy": -2231.8125,
    "average_win": 3796.3333333333335,
    "average_loss": -3622.923076923077
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 1,
    "net_profit": -3704.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3704.0,
    "average_win": null,
    "average_loss": -3704.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 2,
    "net_profit": -3929.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1964.5,
    "average_win": null,
    "average_loss": -1964.5
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 30,
    "net_profit": -19855.0,
    "win_rate": 0.3,
    "profit_factor": 0.714735208758369,
    "expectancy": -661.8333333333334,
    "average_win": 5527.444444444444,
    "average_loss": -3314.3809523809523
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 24,
    "net_profit": -72934.0,
    "win_rate": 0.125,
    "profit_factor": 0.04630271330500164,
    "expectancy": -3038.9166666666665,
    "average_win": 1180.3333333333333,
    "average_loss": -3641.6666666666665
  },
  {
    "close_reason": "SL",
    "number_of_trades": 4,
    "net_profit": -664.0,
    "win_rate": 0.25,
    "profit_factor": 0.12631578947368421,
    "expectancy": -166.0,
    "average_win": 96.0,
    "average_loss": -253.33333333333334
  },
  {
    "close_reason": "TP",
    "number_of_trades": 5,
    "net_profit": 46110.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9222.0,
    "average_win": 9222.0,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 13,
    "net_profit": -27493.0,
    "win_rate": 0.15384615384615385,
    "profit_factor": 0.25852908654494455,
    "expectancy": -2114.846153846154,
    "average_win": 4793.0,
    "average_loss": -3370.818181818182
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 7,
    "net_profit": -5466.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.6373648245206661,
    "expectancy": -780.8571428571429,
    "average_win": 4803.5,
    "average_loss": -3014.6
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 6,
    "net_profit": 12579.0,
    "win_rate": 0.5,
    "profit_factor": 2.7827380952380953,
    "expectancy": 2096.5,
    "average_win": 6545.0,
    "average_loss": -2352.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 7,
    "net_profit": -7108.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.6057025572751983,
    "expectancy": -1015.4285714285714,
    "average_win": 5459.5,
    "average_loss": -3605.4
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 7,
    "net_profit": 4653.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.318785968758564,
    "expectancy": 664.7142857142857,
    "average_win": 6416.333333333333,
    "average_loss": -3649.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": 3791.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.2574358277875866,
    "expectancy": 541.5714285714286,
    "average_win": 6172.333333333333,
    "average_loss": -3681.5
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 8,
    "net_profit": -5219.0,
    "win_rate": 0.25,
    "profit_factor": 0.6546224604592681,
    "expectancy": -652.375,
    "average_win": 4946.0,
    "average_loss": -2518.5
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": -11288.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2822.0,
    "average_win": null,
    "average_loss": -2822.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 7,
    "net_profit": -19425.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.09709956307520684,
    "expectancy": -2775.0,
    "average_win": 2089.0,
    "average_loss": -3585.6666666666665
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0191-1.071",
    "number_of_trades": 11,
    "net_profit": 49484.0,
    "win_rate": 0.8181818181818182,
    "profit_factor": 189.15209125475286,
    "expectancy": 4498.545454545455,
    "average_win": 5527.444444444444,
    "average_loss": -131.5
  },
  {
    "giveback_band": "GIVEBACK_1.071-4.252",
    "number_of_trades": 11,
    "net_profit": -36619.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3329.0,
    "average_win": null,
    "average_loss": -3329.0
  },
  {
    "giveback_band": "GIVEBACK_4.252-161",
    "number_of_trades": 11,
    "net_profit": -40353.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3668.4545454545455,
    "average_win": null,
    "average_loss": -3668.4545454545455
  }
]
```

## time_stop_reason_code別

```json
[
  {
    "time_stop_reason_code": "MAX_HOLDING_BARS_MIN_MFE_NOT_REACHED",
    "number_of_trades": 1,
    "net_profit": 390.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 390.0,
    "average_win": 390.0,
    "average_loss": null
  }
]
```

## range_exit_reason_code別

```json
[]
```

## trend_reversal_trend_direction別

```json
[]
```
