# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 19
- MFEデータのある負けトレード数: 19
- うち一度含み益になった数: 17
- 割合: 89.47%
- 反転前の平均含み益: 2360.35

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 24
- 平均Giveback比率: 276.73%
- 中央値Giveback比率: 166.25%
- 損益ゼロ以下まで完全反転した割合: 79.17%

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
- 純損益: -43308.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3331.38
- 平均逆行幅（R）: 0.8081
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 13,
    "net_profit": -43308.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3331.3846153846152,
    "average_win": null,
    "average_loss": -3331.3846153846152
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 5893
- 最終Entry候補まで到達: 52
- Stage別棄却数（market_regime）: 4639
- Stage別棄却数（htf_bias）: 255
- Stage別棄却数（trend_strength_or_momentum_filter）: 576
- Stage別棄却数（setup_or_trigger）: 371
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 4639,
  "CONFIRMATION_ADX_TOO_LOW": 52,
  "RSI_FILTERED": 524,
  "ENTRY_PATTERN_NOT_FOUND": 371,
  "TREND_NOT_ALIGNED": 255
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 25,
    "net_profit": -4606.0,
    "win_rate": 0.2,
    "profit_factor": 0.8994213342067912,
    "expectancy": -184.24,
    "average_win": 8237.8,
    "average_loss": -2544.1666666666665
  },
  {
    "direction": "SELL",
    "number_of_trades": 1,
    "net_profit": -1168.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1168.0,
    "average_win": null,
    "average_loss": -1168.0
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 7,
    "net_profit": -2883.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.7639980353634578,
    "expectancy": -411.85714285714283,
    "average_win": 9333.0,
    "average_loss": -2036.0
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 5,
    "net_profit": -2801.0,
    "win_rate": 0.2,
    "profit_factor": 0.7312931696085956,
    "expectancy": -560.2,
    "average_win": 7623.0,
    "average_loss": -3474.6666666666665
  },
  {
    "session": "NewYork",
    "number_of_trades": 11,
    "net_profit": 6837.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 1.3930213842262589,
    "expectancy": 621.5454545454545,
    "average_win": 8077.666666666667,
    "average_loss": -2485.1428571428573
  },
  {
    "session": "Tokyo",
    "number_of_trades": 3,
    "net_profit": -6927.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2309.0,
    "average_win": null,
    "average_loss": -2309.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": -3954.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1318.0,
    "average_win": null,
    "average_loss": -1977.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 6,
    "net_profit": -727.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.9129341317365269,
    "expectancy": -121.16666666666667,
    "average_win": 7623.0,
    "average_loss": -1670.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 7,
    "net_profit": 5937.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.559039548022599,
    "expectancy": 848.1428571428571,
    "average_win": 8278.5,
    "average_loss": -2655.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": 1852.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.3179945054945055,
    "expectancy": 617.3333333333334,
    "average_win": 7676.0,
    "average_loss": -2912.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 7,
    "net_profit": -8882.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5123799066703266,
    "expectancy": -1268.857142857143,
    "average_win": 9333.0,
    "average_loss": -3035.8333333333335
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_3.02-5.924",
    "number_of_trades": 9,
    "net_profit": -3431.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.8423471028810366,
    "expectancy": -381.22222222222223,
    "average_win": 9166.0,
    "average_loss": -3109.0
  },
  {
    "atr_band": "ATR_5.924-8.283",
    "number_of_trades": 8,
    "net_profit": 13175.0,
    "win_rate": 0.375,
    "profit_factor": 2.3607725676513116,
    "expectancy": 1646.875,
    "average_win": 7619.0,
    "average_loss": -1936.4
  },
  {
    "atr_band": "ATR_8.283-15.48",
    "number_of_trades": 9,
    "net_profit": -15518.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1724.2222222222222,
    "average_win": null,
    "average_loss": -2216.8571428571427
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.47-43.14",
    "number_of_trades": 9,
    "net_profit": 3978.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 1.313302354886981,
    "expectancy": 442.0,
    "average_win": 8337.5,
    "average_loss": -2539.4
  },
  {
    "adx_band": "ADX_43.14-46.72",
    "number_of_trades": 8,
    "net_profit": -12218.0,
    "win_rate": 0.125,
    "profit_factor": 0.38420442518018244,
    "expectancy": -1527.25,
    "average_win": 7623.0,
    "average_loss": -2834.4285714285716
  },
  {
    "adx_band": "ADX_46.72-59",
    "number_of_trades": 9,
    "net_profit": 2466.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 1.170953206239168,
    "expectancy": 274.0,
    "average_win": 8445.5,
    "average_loss": -2060.714285714286
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.255-2.736",
    "number_of_trades": 9,
    "net_profit": -19200.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.282457582778982,
    "expectancy": -2133.3333333333335,
    "average_win": 7558.0,
    "average_loss": -3344.75
  },
  {
    "hold_time_band": "HOLD_H_2.736-6.827",
    "number_of_trades": 8,
    "net_profit": 15051.0,
    "win_rate": 0.375,
    "profit_factor": 2.38031914893617,
    "expectancy": 1881.375,
    "average_win": 8651.666666666666,
    "average_loss": -2726.0
  },
  {
    "hold_time_band": "HOLD_H_6.827-22",
    "number_of_trades": 9,
    "net_profit": -1625.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.8252876034834964,
    "expectancy": -180.55555555555554,
    "average_win": 7676.0,
    "average_loss": -1328.7142857142858
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-218-2094",
    "number_of_trades": 9,
    "net_profit": -29530.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3281.1111111111113,
    "average_win": null,
    "average_loss": -3281.1111111111113
  },
  {
    "mfe_band": "MFE_2094-4196",
    "number_of_trades": 8,
    "net_profit": -17129.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2141.125,
    "average_win": null,
    "average_loss": -2447.0
  },
  {
    "mfe_band": "MFE_4196-9124",
    "number_of_trades": 9,
    "net_profit": 40885.0,
    "win_rate": 0.5555555555555556,
    "profit_factor": 135.49013157894737,
    "expectancy": 4542.777777777777,
    "average_win": 8237.8,
    "average_loss": -101.33333333333333
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1790--161",
    "number_of_trades": 9,
    "net_profit": 33218.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 96.45402298850574,
    "expectancy": 3690.8888888888887,
    "average_win": 8391.5,
    "average_loss": -116.0
  },
  {
    "mae_band": "MAE_-3054--1790",
    "number_of_trades": 8,
    "net_profit": -8920.0,
    "win_rate": 0.125,
    "profit_factor": 0.4607991295411957,
    "expectancy": -1115.0,
    "average_win": 7623.0,
    "average_loss": -2363.285714285714
  },
  {
    "mae_band": "MAE_-4430--3054",
    "number_of_trades": 9,
    "net_profit": -30072.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3341.3333333333335,
    "average_win": null,
    "average_loss": -3341.3333333333335
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 6,
    "net_profit": -2567.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.7780563721251945,
    "expectancy": -427.8333333333333,
    "average_win": 8999.0,
    "average_loss": -2891.5
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 20,
    "net_profit": -3207.0,
    "win_rate": 0.2,
    "profit_factor": 0.9093991016187812,
    "expectancy": -160.35,
    "average_win": 8047.5,
    "average_loss": -2359.8
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": -6138.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3069.0,
    "average_win": null,
    "average_loss": -3069.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 7,
    "net_profit": -10305.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.4252008032128514,
    "expectancy": -1472.142857142857,
    "average_win": 7623.0,
    "average_loss": -2988.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 17,
    "net_profit": 10669.0,
    "win_rate": 0.23529411764705882,
    "profit_factor": 1.4659562388085776,
    "expectancy": 627.5882352941177,
    "average_win": 8391.5,
    "average_loss": -2081.5454545454545
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 15,
    "net_profit": -46448.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3096.5333333333333,
    "average_win": null,
    "average_loss": -3096.5333333333333
  },
  {
    "close_reason": "SL",
    "number_of_trades": 6,
    "net_profit": -515.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -85.83333333333333,
    "average_win": null,
    "average_loss": -128.75
  },
  {
    "close_reason": "TP",
    "number_of_trades": 5,
    "net_profit": 41189.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8237.8,
    "average_win": 8237.8,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 11,
    "net_profit": -13431.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.4099894570374275,
    "expectancy": -1221.0,
    "average_win": 9333.0,
    "average_loss": -2276.4
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 13,
    "net_profit": 89.0,
    "win_rate": 0.23076923076923078,
    "profit_factor": 1.0036943256817898,
    "expectancy": 6.846153846153846,
    "average_win": 8060.0,
    "average_loss": -3011.375
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 2,
    "net_profit": 7568.0,
    "win_rate": 0.5,
    "profit_factor": 71.07407407407408,
    "expectancy": 3784.0,
    "average_win": 7676.0,
    "average_loss": -108.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 5,
    "net_profit": -5926.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1185.2,
    "average_win": null,
    "average_loss": -1975.3333333333333
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 4,
    "net_profit": 652.0,
    "win_rate": 0.25,
    "profit_factor": 1.0935303399799168,
    "expectancy": 163.0,
    "average_win": 7623.0,
    "average_loss": -2323.6666666666665
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 6,
    "net_profit": 7801.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.8909319323892189,
    "expectancy": 1300.1666666666667,
    "average_win": 8278.5,
    "average_loss": -2189.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": -7203.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1800.75,
    "average_win": null,
    "average_loss": -1800.75
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 7,
    "net_profit": -1098.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.9393604683271662,
    "expectancy": -156.85714285714286,
    "average_win": 8504.5,
    "average_loss": -3621.4
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0239-1.017",
    "number_of_trades": 8,
    "net_profit": 41160.0,
    "win_rate": 0.625,
    "profit_factor": 1420.3103448275863,
    "expectancy": 5145.0,
    "average_win": 8237.8,
    "average_loss": -29.0
  },
  {
    "giveback_band": "GIVEBACK_1.017-2.355",
    "number_of_trades": 8,
    "net_profit": -13238.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1654.75,
    "average_win": null,
    "average_loss": -1654.75
  },
  {
    "giveback_band": "GIVEBACK_2.355-13.64",
    "number_of_trades": 8,
    "net_profit": -26449.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3306.125,
    "average_win": null,
    "average_loss": -3306.125
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
