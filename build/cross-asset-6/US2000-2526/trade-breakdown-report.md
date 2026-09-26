# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 35
- MFEデータのある負けトレード数: 35
- うち一度含み益になった数: 34
- 割合: 97.14%
- 反転前の平均含み益: 2190.94

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 46
- 平均Giveback比率: 295.53%
- 中央値Giveback比率: 207.65%
- 損益ゼロ以下まで完全反転した割合: 76.09%

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

- 決済件数: 28
- 純損益: -83437.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -2979.89
- 平均逆行幅（R）: 0.7671
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 24,
    "net_profit": -71798.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2991.5833333333335,
    "average_win": null,
    "average_loss": -2991.5833333333335
  },
  "SELL": {
    "number_of_trades": 4,
    "net_profit": -11639.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2909.75,
    "average_win": null,
    "average_loss": -2909.75
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 9781
- 最終Entry候補まで到達: 83
- Stage別棄却数（market_regime）: 7898
- Stage別棄却数（htf_bias）: 402
- Stage別棄却数（trend_strength_or_momentum_filter）: 767
- Stage別棄却数（setup_or_trigger）: 631
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 7898,
  "TREND_NOT_ALIGNED": 402,
  "RSI_FILTERED": 671,
  "ENTRY_PATTERN_NOT_FOUND": 631,
  "CONFIRMATION_ADX_TOO_LOW": 96
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 41,
    "net_profit": -6129.0,
    "win_rate": 0.24390243902439024,
    "profit_factor": 0.9162624841173336,
    "expectancy": -149.4878048780488,
    "average_win": 6706.4,
    "average_loss": -2439.766666666667
  },
  {
    "direction": "SELL",
    "number_of_trades": 6,
    "net_profit": -3817.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.6737049068216789,
    "expectancy": -636.1666666666666,
    "average_win": 7881.0,
    "average_loss": -2339.6
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 8,
    "net_profit": -4129.0,
    "win_rate": 0.125,
    "profit_factor": 0.656203164029975,
    "expectancy": -516.125,
    "average_win": 7881.0,
    "average_loss": -2001.6666666666667
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 14,
    "net_profit": -1791.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.9431915500999144,
    "expectancy": -127.92857142857143,
    "average_win": 7434.0,
    "average_loss": -3152.7
  },
  {
    "session": "NewYork",
    "number_of_trades": 14,
    "net_profit": -1014.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.9595613160518445,
    "expectancy": -72.42857142857143,
    "average_win": 6015.25,
    "average_loss": -2507.5
  },
  {
    "session": "Tokyo",
    "number_of_trades": 11,
    "net_profit": -3012.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.8149763498986424,
    "expectancy": -273.8181818181818,
    "average_win": 6633.5,
    "average_loss": -1808.7777777777778
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 13,
    "net_profit": 13241.0,
    "win_rate": 0.38461538461538464,
    "profit_factor": 1.594513290229885,
    "expectancy": 1018.5384615384615,
    "average_win": 7102.6,
    "average_loss": -2784.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 12,
    "net_profit": -15120.0,
    "win_rate": 0.08333333333333333,
    "profit_factor": 0.3292223060201411,
    "expectancy": -1260.0,
    "average_win": 7421.0,
    "average_loss": -2254.1
  },
  {
    "weekday": "Thu",
    "number_of_trades": 7,
    "net_profit": 3313.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.3195100781174656,
    "expectancy": 473.2857142857143,
    "average_win": 6841.0,
    "average_loss": -2073.8
  },
  {
    "weekday": "Tue",
    "number_of_trades": 6,
    "net_profit": 1676.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.1649119354521302,
    "expectancy": 279.3333333333333,
    "average_win": 5919.5,
    "average_loss": -2540.75
  },
  {
    "weekday": "Wed",
    "number_of_trades": 9,
    "net_profit": -13056.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.33203724547221936,
    "expectancy": -1450.6666666666667,
    "average_win": 6490.0,
    "average_loss": -2443.25
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_2.82-6",
    "number_of_trades": 16,
    "net_profit": -16047.0,
    "win_rate": 0.1875,
    "profit_factor": 0.5816954277670612,
    "expectancy": -1002.9375,
    "average_win": 7438.333333333333,
    "average_loss": -3196.8333333333335
  },
  {
    "atr_band": "ATR_6-8.994",
    "number_of_trades": 15,
    "net_profit": -657.0,
    "win_rate": 0.2,
    "profit_factor": 0.9716541548019674,
    "expectancy": -43.8,
    "average_win": 7507.0,
    "average_loss": -1931.5
  },
  {
    "atr_band": "ATR_8.994-13.53",
    "number_of_trades": 16,
    "net_profit": 6758.0,
    "win_rate": 0.3125,
    "profit_factor": 1.2894094471328852,
    "expectancy": 422.375,
    "average_win": 6021.8,
    "average_loss": -2122.818181818182
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.09-43.09",
    "number_of_trades": 16,
    "net_profit": 2911.0,
    "win_rate": 0.25,
    "profit_factor": 1.1123764669549105,
    "expectancy": 181.9375,
    "average_win": 7203.75,
    "average_loss": -2354.909090909091
  },
  {
    "adx_band": "ADX_43.09-47.67",
    "number_of_trades": 15,
    "net_profit": -6461.0,
    "win_rate": 0.26666666666666666,
    "profit_factor": 0.805050992698087,
    "expectancy": -430.73333333333335,
    "average_win": 6670.25,
    "average_loss": -3012.909090909091
  },
  {
    "adx_band": "ADX_47.67-68.05",
    "number_of_trades": 16,
    "net_profit": -6396.0,
    "win_rate": 0.1875,
    "profit_factor": 0.7525246662797447,
    "expectancy": -399.75,
    "average_win": 6483.0,
    "average_loss": -1988.076923076923
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.503-2.817",
    "number_of_trades": 16,
    "net_profit": -7119.0,
    "win_rate": 0.25,
    "profit_factor": 0.810018146883006,
    "expectancy": -444.9375,
    "average_win": 7588.25,
    "average_loss": -3122.6666666666665
  },
  {
    "hold_time_band": "HOLD_H_11.09-79",
    "number_of_trades": 16,
    "net_profit": 1041.0,
    "win_rate": 0.25,
    "profit_factor": 1.0469193671970072,
    "expectancy": 65.0625,
    "average_win": 5807.0,
    "average_loss": -1848.9166666666667
  },
  {
    "hold_time_band": "HOLD_H_2.817-11.09",
    "number_of_trades": 15,
    "net_profit": -3868.0,
    "win_rate": 0.2,
    "profit_factor": 0.8467025998731769,
    "expectancy": -257.8666666666667,
    "average_win": 7121.333333333333,
    "average_loss": -2293.818181818182
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-63-1448",
    "number_of_trades": 16,
    "net_profit": -45227.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2826.6875,
    "average_win": null,
    "average_loss": -2826.6875
  },
  {
    "mfe_band": "MFE_1448-4488",
    "number_of_trades": 15,
    "net_profit": -35984.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2398.9333333333334,
    "average_win": null,
    "average_loss": -2398.9333333333334
  },
  {
    "mfe_band": "MFE_4488-8514",
    "number_of_trades": 16,
    "net_profit": 71265.0,
    "win_rate": 0.6875,
    "profit_factor": 20.36548913043478,
    "expectancy": 4454.0625,
    "average_win": 6813.181818181818,
    "average_loss": -920.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2125-0",
    "number_of_trades": 16,
    "net_profit": 48887.0,
    "win_rate": 0.5,
    "profit_factor": 15.072251007484168,
    "expectancy": 3055.4375,
    "average_win": 6545.125,
    "average_loss": -496.2857142857143
  },
  {
    "mae_band": "MAE_-2898--2125",
    "number_of_trades": 15,
    "net_profit": -5623.0,
    "win_rate": 0.2,
    "profit_factor": 0.8006523203460134,
    "expectancy": -374.8666666666667,
    "average_win": 7528.0,
    "average_loss": -2350.5833333333335
  },
  {
    "mae_band": "MAE_-3826--2898",
    "number_of_trades": 16,
    "net_profit": -53210.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3325.625,
    "average_win": null,
    "average_loss": -3325.625
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 12,
    "net_profit": -2299.0,
    "win_rate": 0.25,
    "profit_factor": 0.905320813771518,
    "expectancy": -191.58333333333334,
    "average_win": 7327.666666666667,
    "average_loss": -2698.0
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 35,
    "net_profit": -7647.0,
    "win_rate": 0.22857142857142856,
    "profit_factor": 0.8738306192149681,
    "expectancy": -218.4857142857143,
    "average_win": 6620.25,
    "average_loss": -2331.1153846153848
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": -5471.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2735.5,
    "average_win": null,
    "average_loss": -2735.5
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 13,
    "net_profit": 6411.0,
    "win_rate": 0.3076923076923077,
    "profit_factor": 1.274855305466238,
    "expectancy": 493.15384615384613,
    "average_win": 7434.0,
    "average_loss": -2915.625
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 32,
    "net_profit": -10886.0,
    "win_rate": 0.21875,
    "profit_factor": 0.805936357964168,
    "expectancy": -340.1875,
    "average_win": 6458.428571428572,
    "average_loss": -2243.8
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 32,
    "net_profit": -74770.0,
    "win_rate": 0.0625,
    "profit_factor": 0.11756027900060191,
    "expectancy": -2336.5625,
    "average_win": 4980.5,
    "average_loss": -2824.366666666667
  },
  {
    "close_reason": "SL",
    "number_of_trades": 6,
    "net_profit": -160.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -26.666666666666668,
    "average_win": null,
    "average_loss": -32.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 9,
    "net_profit": 64984.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7220.444444444444,
    "average_win": 7220.444444444444,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 2,
    "net_profit": -3250.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1625.0,
    "average_win": null,
    "average_loss": -1625.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 22,
    "net_profit": -23655.0,
    "win_rate": 0.13636363636363635,
    "profit_factor": 0.5050116135512357,
    "expectancy": -1075.2272727272727,
    "average_win": 8044.666666666667,
    "average_loss": -2654.9444444444443
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 16,
    "net_profit": 7463.0,
    "win_rate": 0.3125,
    "profit_factor": 1.287414311022106,
    "expectancy": 466.4375,
    "average_win": 6685.8,
    "average_loss": -2360.5454545454545
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 7,
    "net_profit": 9496.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.2041592695916816,
    "expectancy": 1356.5714285714287,
    "average_win": 5794.0,
    "average_loss": -1971.5
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 13,
    "net_profit": 7116.0,
    "win_rate": 0.3076923076923077,
    "profit_factor": 1.290354170066917,
    "expectancy": 547.3846153846154,
    "average_win": 7906.0,
    "average_loss": -2723.1111111111113
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 8,
    "net_profit": -11707.0,
    "win_rate": 0.125,
    "profit_factor": 0.34152652005174644,
    "expectancy": -1463.375,
    "average_win": 6072.0,
    "average_loss": -2963.1666666666665
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 5,
    "net_profit": -1067.0,
    "win_rate": 0.2,
    "profit_factor": 0.8770312319926242,
    "expectancy": -213.4,
    "average_win": 7610.0,
    "average_loss": -2169.25
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 12,
    "net_profit": 8851.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.6190376276402294,
    "expectancy": 737.5833333333334,
    "average_win": 5787.25,
    "average_loss": -1787.25
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 9,
    "net_profit": -13139.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.3306332467267818,
    "expectancy": -1459.888888888889,
    "average_win": 6490.0,
    "average_loss": -2453.625
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0396-1.009",
    "number_of_trades": 16,
    "net_profit": 74844.0,
    "win_rate": 0.6875,
    "profit_factor": 742.0297029702971,
    "expectancy": 4677.75,
    "average_win": 6813.181818181818,
    "average_loss": -25.25
  },
  {
    "giveback_band": "GIVEBACK_1.009-2.677",
    "number_of_trades": 14,
    "net_profit": -36471.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2605.0714285714284,
    "average_win": null,
    "average_loss": -2605.0714285714284
  },
  {
    "giveback_band": "GIVEBACK_2.677-19",
    "number_of_trades": 16,
    "net_profit": -45673.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2854.5625,
    "average_win": null,
    "average_loss": -2854.5625
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
