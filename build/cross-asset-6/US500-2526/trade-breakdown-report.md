# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 33
- MFEデータのある負けトレード数: 33
- うち一度含み益になった数: 31
- 割合: 93.94%
- 反転前の平均含み益: 1645.58

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 47
- 平均Giveback比率: 458.31%
- 中央値Giveback比率: 222.82%
- 損益ゼロ以下まで完全反転した割合: 72.34%

## Time Stop（時間切れ決済）

- Time Stopによる決済件数: 2
- 純損益: 2067.00
- プロフィットファクター: 算出不能
- 勝率: 100.00%
- 期待値: 1033.50

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

- 決済件数: 30
- 純損益: -90961.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3032.03
- 平均逆行幅（R）: 0.7819
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 30,
    "net_profit": -90961.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3032.0333333333333,
    "average_win": null,
    "average_loss": -3032.0333333333333
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 9781
- 最終Entry候補まで到達: 114
- Stage別棄却数（market_regime）: 7812
- Stage別棄却数（htf_bias）: 278
- Stage別棄却数（trend_strength_or_momentum_filter）: 841
- Stage別棄却数（setup_or_trigger）: 736
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 7812,
  "TREND_NOT_ALIGNED": 278,
  "ENTRY_PATTERN_NOT_FOUND": 736,
  "RSI_FILTERED": 730,
  "CONFIRMATION_ADX_TOO_LOW": 111
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 49,
    "net_profit": -14274.0,
    "win_rate": 0.2653061224489796,
    "profit_factor": 0.8446908287725635,
    "expectancy": -291.3061224489796,
    "average_win": 5971.7692307692305,
    "average_loss": -2785.060606060606
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 10,
    "net_profit": -17198.0,
    "win_rate": 0.1,
    "profit_factor": 0.2382513177127165,
    "expectancy": -1719.8,
    "average_win": 5379.0,
    "average_loss": -2822.125
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 9,
    "net_profit": -6914.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.5758282208588957,
    "expectancy": -768.2222222222222,
    "average_win": 9386.0,
    "average_loss": -2328.5714285714284
  },
  {
    "session": "NewYork",
    "number_of_trades": 21,
    "net_profit": 9756.0,
    "win_rate": 0.38095238095238093,
    "profit_factor": 1.276162708409998,
    "expectancy": 464.57142857142856,
    "average_win": 5635.375,
    "average_loss": -2943.9166666666665
  },
  {
    "session": "Tokyo",
    "number_of_trades": 9,
    "net_profit": 82.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.0046319832796702,
    "expectancy": 9.11111111111111,
    "average_win": 5928.333333333333,
    "average_loss": -2950.5
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 12,
    "net_profit": -15554.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.46067961165048543,
    "expectancy": -1296.1666666666667,
    "average_win": 6643.0,
    "average_loss": -2884.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 15,
    "net_profit": -13718.0,
    "win_rate": 0.2,
    "profit_factor": 0.5691718224930121,
    "expectancy": -914.5333333333333,
    "average_win": 6041.0,
    "average_loss": -2894.6363636363635
  },
  {
    "weekday": "Thu",
    "number_of_trades": 5,
    "net_profit": 10041.0,
    "win_rate": 0.4,
    "profit_factor": 4.604091888011486,
    "expectancy": 2008.2,
    "average_win": 6413.5,
    "average_loss": -1393.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 5,
    "net_profit": 16041.0,
    "win_rate": 0.8,
    "profit_factor": 6.6862814604750085,
    "expectancy": 3208.2,
    "average_win": 4715.5,
    "average_loss": -2821.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 12,
    "net_profit": -11084.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.5673523556735236,
    "expectancy": -923.6666666666666,
    "average_win": 7267.5,
    "average_loss": -2846.5555555555557
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_11.31-16.04",
    "number_of_trades": 17,
    "net_profit": -2942.0,
    "win_rate": 0.35294117647058826,
    "profit_factor": 0.9003893685457931,
    "expectancy": -173.05882352941177,
    "average_win": 4432.166666666667,
    "average_loss": -2953.5
  },
  {
    "atr_band": "ATR_4.628-8.529",
    "number_of_trades": 17,
    "net_profit": -13673.0,
    "win_rate": 0.17647058823529413,
    "profit_factor": 0.6587636327335347,
    "expectancy": -804.2941176470588,
    "average_win": 8798.666666666666,
    "average_loss": -3082.230769230769
  },
  {
    "atr_band": "ATR_8.529-11.31",
    "number_of_trades": 15,
    "net_profit": 2341.0,
    "win_rate": 0.26666666666666666,
    "profit_factor": 1.1049634578307852,
    "expectancy": 156.06666666666666,
    "average_win": 6161.0,
    "average_loss": -2230.3
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.08-41.93",
    "number_of_trades": 17,
    "net_profit": -21094.0,
    "win_rate": 0.17647058823529413,
    "profit_factor": 0.4246515560646974,
    "expectancy": -1240.8235294117646,
    "average_win": 5189.666666666667,
    "average_loss": -2820.230769230769
  },
  {
    "adx_band": "ADX_41.93-47.58",
    "number_of_trades": 15,
    "net_profit": 9487.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.412370685908024,
    "expectancy": 632.4666666666667,
    "average_win": 6498.6,
    "average_loss": -2556.222222222222
  },
  {
    "adx_band": "ADX_47.58-63.97",
    "number_of_trades": 17,
    "net_profit": -2667.0,
    "win_rate": 0.29411764705882354,
    "profit_factor": 0.9172715428996836,
    "expectancy": -156.88235294117646,
    "average_win": 5914.2,
    "average_loss": -2930.7272727272725
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.185-2.706",
    "number_of_trades": 16,
    "net_profit": -40145.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2509.0625,
    "average_win": null,
    "average_loss": -2867.5
  },
  {
    "hold_time_band": "HOLD_H_15-98.02",
    "number_of_trades": 17,
    "net_profit": 39748.0,
    "win_rate": 0.5882352941176471,
    "profit_factor": 3.239954916877994,
    "expectancy": 2338.1176470588234,
    "average_win": 5749.3,
    "average_loss": -2957.5
  },
  {
    "hold_time_band": "HOLD_H_2.706-15",
    "number_of_trades": 16,
    "net_profit": -13877.0,
    "win_rate": 0.1875,
    "profit_factor": 0.5920569127201105,
    "expectancy": -867.3125,
    "average_win": 6713.333333333333,
    "average_loss": -2616.6923076923076
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-92-1157",
    "number_of_trades": 16,
    "net_profit": -44003.0,
    "win_rate": 0.0625,
    "profit_factor": 0.02293720579092282,
    "expectancy": -2750.1875,
    "average_win": 1033.0,
    "average_loss": -3002.4
  },
  {
    "mfe_band": "MFE_1157-4105",
    "number_of_trades": 16,
    "net_profit": -41181.0,
    "win_rate": 0.0625,
    "profit_factor": 0.02449366338979036,
    "expectancy": -2573.8125,
    "average_win": 1034.0,
    "average_loss": -3015.3571428571427
  },
  {
    "mfe_band": "MFE_4105-8520",
    "number_of_trades": 17,
    "net_profit": 70910.0,
    "win_rate": 0.6470588235294118,
    "profit_factor": 16.229810996563575,
    "expectancy": 4171.176470588235,
    "average_win": 6869.636363636364,
    "average_loss": -1164.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1921--199",
    "number_of_trades": 17,
    "net_profit": 65285.0,
    "win_rate": 0.6470588235294118,
    "profit_factor": 24.011984490659145,
    "expectancy": 3840.294117647059,
    "average_win": 6192.909090909091,
    "average_loss": -945.6666666666666
  },
  {
    "mae_band": "MAE_-2954--1921",
    "number_of_trades": 16,
    "net_profit": -23206.0,
    "win_rate": 0.125,
    "profit_factor": 0.29070513800165054,
    "expectancy": -1450.375,
    "average_win": 4755.5,
    "average_loss": -2336.9285714285716
  },
  {
    "mae_band": "MAE_-4025--2954",
    "number_of_trades": 16,
    "net_profit": -56353.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3522.0625,
    "average_win": null,
    "average_loss": -3522.0625
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 2,
    "net_profit": -6087.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3043.5,
    "average_win": null,
    "average_loss": -3043.5
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 47,
    "net_profit": -8187.0,
    "win_rate": 0.2765957446808511,
    "profit_factor": 0.9046026567233745,
    "expectancy": -174.19148936170214,
    "average_win": 5971.7692307692305,
    "average_loss": -2768.3870967741937
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 1,
    "net_profit": 3900.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 3900.0,
    "average_win": 3900.0,
    "average_loss": null
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 18,
    "net_profit": 1857.0,
    "win_rate": 0.2777777777777778,
    "profit_factor": 1.0643986683312525,
    "expectancy": 103.16666666666667,
    "average_win": 6138.6,
    "average_loss": -2621.4545454545455
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 30,
    "net_profit": -20031.0,
    "win_rate": 0.23333333333333334,
    "profit_factor": 0.6824055429595218,
    "expectancy": -667.7,
    "average_win": 6148.571428571428,
    "average_loss": -2866.8636363636365
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 34,
    "net_profit": -80565.0,
    "win_rate": 0.11764705882352941,
    "profit_factor": 0.11429073998746715,
    "expectancy": -2369.5588235294117,
    "average_win": 2599.0,
    "average_loss": -3032.0333333333333
  },
  {
    "close_reason": "SL",
    "number_of_trades": 6,
    "net_profit": -946.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -157.66666666666666,
    "average_win": null,
    "average_loss": -315.3333333333333
  },
  {
    "close_reason": "TP",
    "number_of_trades": 9,
    "net_profit": 67237.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7470.777777777777,
    "average_win": 7470.777777777777,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 8,
    "net_profit": 3799.0,
    "win_rate": 0.375,
    "profit_factor": 1.2500329077267343,
    "expectancy": 474.875,
    "average_win": 6331.0,
    "average_loss": -3038.8
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 13,
    "net_profit": -16339.0,
    "win_rate": 0.15384615384615385,
    "profit_factor": 0.48566122076368556,
    "expectancy": -1256.8461538461538,
    "average_win": 7714.0,
    "average_loss": -3176.7
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 20,
    "net_profit": -29759.0,
    "win_rate": 0.15,
    "profit_factor": 0.20013439053890605,
    "expectancy": -1487.95,
    "average_win": 2482.0,
    "average_loss": -2480.3333333333335
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 8,
    "net_profit": 28025.0,
    "win_rate": 0.625,
    "profit_factor": 4.6203332902725744,
    "expectancy": 3503.125,
    "average_win": 7153.2,
    "average_loss": -2580.3333333333335
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 11,
    "net_profit": -13471.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.4877557228686592,
    "expectancy": -1224.6363636363637,
    "average_win": 6413.5,
    "average_loss": -2922.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": 3883.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.2777340676632574,
    "expectancy": 554.7142857142857,
    "average_win": 8932.0,
    "average_loss": -2796.2
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 5,
    "net_profit": 11749.0,
    "win_rate": 0.4,
    "profit_factor": 5.217157214644652,
    "expectancy": 2349.8,
    "average_win": 7267.5,
    "average_loss": -1393.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 11,
    "net_profit": -4489.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.769948239635115,
    "expectancy": -408.09090909090907,
    "average_win": 5008.0,
    "average_loss": -2787.5714285714284
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 15,
    "net_profit": -11946.0,
    "win_rate": 0.26666666666666666,
    "profit_factor": 0.5926898291793106,
    "expectancy": -796.4,
    "average_win": 4345.75,
    "average_loss": -2932.9
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-1.202-1.002",
    "number_of_trades": 16,
    "net_profit": 77633.0,
    "win_rate": 0.8125,
    "profit_factor": null,
    "expectancy": 4852.0625,
    "average_win": 5971.7692307692305,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1.002-3.314",
    "number_of_trades": 15,
    "net_profit": -36519.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2434.6,
    "average_win": null,
    "average_loss": -2434.6
  },
  {
    "giveback_band": "GIVEBACK_3.314-23.39",
    "number_of_trades": 16,
    "net_profit": -48025.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3001.5625,
    "average_win": null,
    "average_loss": -3001.5625
  }
]
```

## time_stop_reason_code別

```json
[
  {
    "time_stop_reason_code": "MAX_HOLDING_BARS_MIN_MFE_NOT_REACHED",
    "number_of_trades": 2,
    "net_profit": 2067.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 1033.5,
    "average_win": 1033.5,
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
