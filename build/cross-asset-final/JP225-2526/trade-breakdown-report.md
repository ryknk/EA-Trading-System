# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 26
- MFEデータのある負けトレード数: 26
- うち一度含み益になった数: 23
- 割合: 88.46%
- 反転前の平均含み益: 2062.13

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 41
- 平均Giveback比率: 283.43%
- 中央値Giveback比率: 101.60%
- 損益ゼロ以下まで完全反転した割合: 68.29%

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

- 決済件数: 23
- 純損益: -82467.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3585.52
- 平均逆行幅（R）: 0.7639
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 16,
    "net_profit": -57877.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3617.3125,
    "average_win": null,
    "average_loss": -3617.3125
  },
  "SELL": {
    "number_of_trades": 7,
    "net_profit": -24590.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3512.8571428571427,
    "average_win": null,
    "average_loss": -3512.8571428571427
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 9784
- 最終Entry候補まで到達: 97
- Stage別棄却数（market_regime）: 7894
- Stage別棄却数（htf_bias）: 263
- Stage別棄却数（trend_strength_or_momentum_filter）: 944
- Stage別棄却数（setup_or_trigger）: 586
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 7894,
  "ENTRY_PATTERN_NOT_FOUND": 586,
  "RSI_FILTERED": 802,
  "TREND_NOT_ALIGNED": 263,
  "CONFIRMATION_ADX_TOO_LOW": 142
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 37,
    "net_profit": 25027.0,
    "win_rate": 0.35135135135135137,
    "profit_factor": 1.4310763559949704,
    "expectancy": 676.4054054054054,
    "average_win": 6391.076923076923,
    "average_loss": -3055.6315789473683
  },
  {
    "direction": "SELL",
    "number_of_trades": 7,
    "net_profit": -24590.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3512.8571428571427,
    "average_win": null,
    "average_loss": -3512.8571428571427
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 11,
    "net_profit": 5346.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 1.2958494742667404,
    "expectancy": 486.0,
    "average_win": 5854.0,
    "average_loss": -3614.0
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 3,
    "net_profit": 5250.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.411290322580645,
    "expectancy": 1750.0,
    "average_win": 8970.0,
    "average_loss": -3720.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 14,
    "net_profit": -4170.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.8308041872920555,
    "expectancy": -297.85714285714283,
    "average_win": 5119.0,
    "average_loss": -3080.75
  },
  {
    "session": "Tokyo",
    "number_of_trades": 16,
    "net_profit": -5989.0,
    "win_rate": 0.25,
    "profit_factor": 0.8346082682057938,
    "expectancy": -374.3125,
    "average_win": 7555.5,
    "average_loss": -3017.5833333333335
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 12,
    "net_profit": 2388.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.0952039229757207,
    "expectancy": 199.0,
    "average_win": 6867.75,
    "average_loss": -3583.285714285714
  },
  {
    "weekday": "Mon",
    "number_of_trades": 9,
    "net_profit": -15122.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.15292404212413174,
    "expectancy": -1680.2222222222222,
    "average_win": 1365.0,
    "average_loss": -3570.4
  },
  {
    "weekday": "Thu",
    "number_of_trades": 5,
    "net_profit": 1655.0,
    "win_rate": 0.4,
    "profit_factor": 1.1509347925216598,
    "expectancy": 331.0,
    "average_win": 6310.0,
    "average_loss": -3655.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 10,
    "net_profit": 13031.0,
    "win_rate": 0.4,
    "profit_factor": 1.73183196675278,
    "expectancy": 1303.1,
    "average_win": 7709.25,
    "average_loss": -2967.6666666666665
  },
  {
    "weekday": "Wed",
    "number_of_trades": 8,
    "net_profit": -1515.0,
    "win_rate": 0.125,
    "profit_factor": 0.8615300246778174,
    "expectancy": -189.375,
    "average_win": 9426.0,
    "average_loss": -2188.2
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_147.9-209.4",
    "number_of_trades": 14,
    "net_profit": 22872.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.282494112369631,
    "expectancy": 1633.7142857142858,
    "average_win": 6784.333333333333,
    "average_loss": -2972.3333333333335
  },
  {
    "atr_band": "ATR_209.4-504.7",
    "number_of_trades": 15,
    "net_profit": -14344.0,
    "win_rate": 0.2,
    "profit_factor": 0.5977114651110612,
    "expectancy": -956.2666666666667,
    "average_win": 7104.0,
    "average_loss": -3241.4545454545455
  },
  {
    "atr_band": "ATR_84.64-147.9",
    "number_of_trades": 15,
    "net_profit": -8091.0,
    "win_rate": 0.26666666666666666,
    "profit_factor": 0.722502315052989,
    "expectancy": -539.4,
    "average_win": 5266.5,
    "average_loss": -3239.6666666666665
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.03-42.51",
    "number_of_trades": 15,
    "net_profit": 4659.0,
    "win_rate": 0.4666666666666667,
    "profit_factor": 1.1877342144497722,
    "expectancy": 310.6,
    "average_win": 4210.857142857143,
    "average_loss": -3545.285714285714
  },
  {
    "adx_band": "ADX_42.51-46.1",
    "number_of_trades": 14,
    "net_profit": 10187.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.404663541749424,
    "expectancy": 727.6428571428571,
    "average_win": 8840.25,
    "average_loss": -2797.1111111111113
  },
  {
    "adx_band": "ADX_46.1-58.2",
    "number_of_trades": 15,
    "net_profit": -14409.0,
    "win_rate": 0.13333333333333333,
    "profit_factor": 0.558764086232239,
    "expectancy": -960.6,
    "average_win": 9123.5,
    "average_loss": -3265.6
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.069-5.824",
    "number_of_trades": 15,
    "net_profit": -50300.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3353.3333333333335,
    "average_win": null,
    "average_loss": -3353.3333333333335
  },
  {
    "hold_time_band": "HOLD_H_11.36-91",
    "number_of_trades": 15,
    "net_profit": 45863.0,
    "win_rate": 0.6,
    "profit_factor": 7.08989510025229,
    "expectancy": 3057.5333333333333,
    "average_win": 5932.666666666667,
    "average_loss": -2510.3333333333335
  },
  {
    "hold_time_band": "HOLD_H_5.824-11.36",
    "number_of_trades": 14,
    "net_profit": 4874.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.1964055448098,
    "expectancy": 348.14285714285717,
    "average_win": 7422.5,
    "average_loss": -3102.0
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-50-1363",
    "number_of_trades": 15,
    "net_profit": -53160.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3544.0,
    "average_win": null,
    "average_loss": -3544.0
  },
  {
    "mfe_band": "MFE_1363-5673",
    "number_of_trades": 14,
    "net_profit": -21325.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.27431429932620977,
    "expectancy": -1523.2142857142858,
    "average_win": 2015.25,
    "average_loss": -3265.1111111111113
  },
  {
    "mfe_band": "MFE_5673-9600",
    "number_of_trades": 15,
    "net_profit": 74922.0,
    "win_rate": 0.6,
    "profit_factor": 742.8019801980198,
    "expectancy": 4994.8,
    "average_win": 8335.888888888889,
    "average_loss": -50.5
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1957--130",
    "number_of_trades": 15,
    "net_profit": 54450.0,
    "win_rate": 0.6,
    "profit_factor": 540.1089108910891,
    "expectancy": 3630.0,
    "average_win": 6061.222222222223,
    "average_loss": -50.5
  },
  {
    "mae_band": "MAE_-3557--1957",
    "number_of_trades": 14,
    "net_profit": -11773.0,
    "win_rate": 0.21428571428571427,
    "profit_factor": 0.6198456521037167,
    "expectancy": -840.9285714285714,
    "average_win": 6398.666666666667,
    "average_loss": -3096.9
  },
  {
    "mae_band": "MAE_-3835--3557",
    "number_of_trades": 15,
    "net_profit": -42240.0,
    "win_rate": 0.06666666666666667,
    "profit_factor": 0.18103030420536287,
    "expectancy": -2816.0,
    "average_win": 9337.0,
    "average_loss": -3684.0714285714284
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 14,
    "net_profit": -34235.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.10555192684519922,
    "expectancy": -2445.3571428571427,
    "average_win": 2020.0,
    "average_loss": -3189.5833333333335
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 30,
    "net_profit": 34672.0,
    "win_rate": 0.36666666666666664,
    "profit_factor": 1.7813936716848462,
    "expectancy": 1155.7333333333333,
    "average_win": 7185.818181818182,
    "average_loss": -3169.4285714285716
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 1,
    "net_profit": 8775.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8775.0,
    "average_win": 8775.0,
    "average_loss": null
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 43,
    "net_profit": -8338.0,
    "win_rate": 0.27906976744186046,
    "profit_factor": 0.8991130954541605,
    "expectancy": -193.90697674418604,
    "average_win": 6192.416666666667,
    "average_loss": -3178.730769230769
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 28,
    "net_profit": -70696.0,
    "win_rate": 0.17857142857142858,
    "profit_factor": 0.14273588223168054,
    "expectancy": -2524.8571428571427,
    "average_win": 2354.2,
    "average_loss": -3585.521739130435
  },
  {
    "close_reason": "SL",
    "number_of_trades": 8,
    "net_profit": -180.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -22.5,
    "average_win": null,
    "average_loss": -60.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 8,
    "net_profit": 71313.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8914.125,
    "average_win": 8914.125,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 9,
    "net_profit": -10644.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.41079435372266815,
    "expectancy": -1182.6666666666667,
    "average_win": 2473.6666666666665,
    "average_loss": -3613.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 4,
    "net_profit": 4690.0,
    "win_rate": 0.25,
    "profit_factor": 2.34,
    "expectancy": 1172.5,
    "average_win": 8190.0,
    "average_loss": -1166.6666666666667
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 11,
    "net_profit": 3942.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 1.215174672489083,
    "expectancy": 358.3636363636364,
    "average_win": 5565.5,
    "average_loss": -3664.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 20,
    "net_profit": 2449.0,
    "win_rate": 0.25,
    "profit_factor": 1.0572704737851364,
    "expectancy": 122.45,
    "average_win": 9042.2,
    "average_loss": -3289.3846153846152
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 11,
    "net_profit": 4487.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 1.1802152783356092,
    "expectancy": 407.90909090909093,
    "average_win": 7346.25,
    "average_loss": -3556.8571428571427
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 6,
    "net_profit": -18542.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3090.3333333333335,
    "average_win": null,
    "average_loss": -3708.4
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 6,
    "net_profit": -1675.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.8491126925502207,
    "expectancy": -279.1666666666667,
    "average_win": 9426.0,
    "average_loss": -2220.2
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 13,
    "net_profit": 5427.0,
    "win_rate": 0.38461538461538464,
    "profit_factor": 1.3128675198893116,
    "expectancy": 417.46153846153845,
    "average_win": 4554.6,
    "average_loss": -2891.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 8,
    "net_profit": 10740.0,
    "win_rate": 0.375,
    "profit_factor": 1.9981412639405205,
    "expectancy": 1342.5,
    "average_win": 7166.666666666667,
    "average_loss": -3586.6666666666665
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0273-1",
    "number_of_trades": 18,
    "net_profit": 83084.0,
    "win_rate": 0.7222222222222222,
    "profit_factor": null,
    "expectancy": 4615.777777777777,
    "average_win": 6391.076923076923,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1-3.295",
    "number_of_trades": 9,
    "net_profit": -22177.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2464.1111111111113,
    "average_win": null,
    "average_loss": -2464.1111111111113
  },
  {
    "giveback_band": "GIVEBACK_3.295-17",
    "number_of_trades": 14,
    "net_profit": -50013.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3572.3571428571427,
    "average_win": null,
    "average_loss": -3572.3571428571427
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
