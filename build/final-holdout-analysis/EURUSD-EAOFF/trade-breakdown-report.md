# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 22
- MFEデータのある負けトレード数: 22
- うち一度含み益になった数: 21
- 割合: 95.45%
- 反転前の平均含み益: 2218.62

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 41
- 平均Giveback比率: 389.30%
- 中央値Giveback比率: 101.90%
- 損益ゼロ以下まで完全反転した割合: 68.29%

## Time Stop（時間切れ決済）

- Time Stopによる決済件数: 1
- 純損益: -4714.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -4714.00

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

- 評価済み確定足数: 10497
- 最終Entry候補まで到達: 77
- Stage別棄却数（market_regime）: 8986
- Stage別棄却数（htf_bias）: 256
- Stage別棄却数（trend_strength_or_momentum_filter）: 699
- Stage別棄却数（setup_or_trigger）: 479
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 8986,
  "RSI_FILTERED": 629,
  "ENTRY_PATTERN_NOT_FOUND": 479,
  "CONFIRMATION_ADX_TOO_LOW": 70,
  "TREND_NOT_ALIGNED": 256
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 35,
    "net_profit": 34460.0,
    "win_rate": 0.34285714285714286,
    "profit_factor": 1.4669629790232532,
    "expectancy": 984.5714285714286,
    "average_win": 9021.333333333334,
    "average_loss": -4099.777777777777
  },
  {
    "direction": "SELL",
    "number_of_trades": 7,
    "net_profit": -9970.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.4963120137415378,
    "expectancy": -1424.2857142857142,
    "average_win": 9824.0,
    "average_loss": -4948.5
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 11,
    "net_profit": 15778.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 1.6316253002401921,
    "expectancy": 1434.3636363636363,
    "average_win": 10189.5,
    "average_loss": -4163.333333333333
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 7,
    "net_profit": -3328.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.8524495677233429,
    "expectancy": -475.42857142857144,
    "average_win": 9613.5,
    "average_loss": -5638.75
  },
  {
    "session": "NewYork",
    "number_of_trades": 8,
    "net_profit": 12829.0,
    "win_rate": 0.375,
    "profit_factor": 1.8051842088746626,
    "expectancy": 1603.625,
    "average_win": 9587.333333333334,
    "average_loss": -3186.6
  },
  {
    "session": "Tokyo",
    "number_of_trades": 16,
    "net_profit": -789.0,
    "win_rate": 0.25,
    "profit_factor": 0.9738065201513844,
    "expectancy": -49.3125,
    "average_win": 7333.25,
    "average_loss": -4303.142857142857
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 12,
    "net_profit": -21115.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.5001065366130827,
    "expectancy": -1759.5833333333333,
    "average_win": 10562.0,
    "average_loss": -4693.222222222223
  },
  {
    "weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": 14863.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 3.9304022082018926,
    "expectancy": 2123.285714285714,
    "average_win": 6645.0,
    "average_loss": -2536.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 8,
    "net_profit": 28858.0,
    "win_rate": 0.5,
    "profit_factor": 3.8606264869151468,
    "expectancy": 3607.25,
    "average_win": 9736.5,
    "average_loss": -5044.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 10,
    "net_profit": -7406.0,
    "win_rate": 0.2,
    "profit_factor": 0.717877414193745,
    "expectancy": -740.6,
    "average_win": 9422.5,
    "average_loss": -3750.1428571428573
  },
  {
    "weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": 9290.0,
    "win_rate": 0.4,
    "profit_factor": 1.9346076458752515,
    "expectancy": 1858.0,
    "average_win": 9615.0,
    "average_loss": -4970.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_-0.000286-0.00107",
    "number_of_trades": 14,
    "net_profit": -26558.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.4396809991982784,
    "expectancy": -1897.0,
    "average_win": 10420.0,
    "average_loss": -5266.444444444444
  },
  {
    "atr_band": "ATR_0.00107-0.00145",
    "number_of_trades": 14,
    "net_profit": 36956.0,
    "win_rate": 0.35714285714285715,
    "profit_factor": 4.221127865423168,
    "expectancy": 2639.714285714286,
    "average_win": 9685.8,
    "average_loss": -2294.6
  },
  {
    "atr_band": "ATR_0.00145-0.00334",
    "number_of_trades": 14,
    "net_profit": 14092.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.4058872663383162,
    "expectancy": 1006.5714285714286,
    "average_win": 8135.166666666667,
    "average_loss": -4339.875
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.01-42.1",
    "number_of_trades": 14,
    "net_profit": 26417.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.8307232704402516,
    "expectancy": 1886.9285714285713,
    "average_win": 9702.833333333334,
    "average_loss": -3975.0
  },
  {
    "adx_band": "ADX_42.1-44.65",
    "number_of_trades": 14,
    "net_profit": 1193.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.0397467932700317,
    "expectancy": 85.21428571428571,
    "average_win": 7802.0,
    "average_loss": -4287.857142857143
  },
  {
    "adx_band": "ADX_44.65-68.72",
    "number_of_trades": 14,
    "net_profit": -3120.0,
    "win_rate": 0.21428571428571427,
    "profit_factor": 0.9018095987411487,
    "expectancy": -222.85714285714286,
    "average_win": 9551.666666666666,
    "average_loss": -4539.285714285715
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_1.129-4.002",
    "number_of_trades": 14,
    "net_profit": -4873.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.8915665331553182,
    "expectancy": -348.07142857142856,
    "average_win": 10016.75,
    "average_loss": -4993.333333333333
  },
  {
    "hold_time_band": "HOLD_H_11.97-87.46",
    "number_of_trades": 14,
    "net_profit": 21604.0,
    "win_rate": 0.35714285714285715,
    "profit_factor": 2.25400510796378,
    "expectancy": 1543.142857142857,
    "average_win": 7766.4,
    "average_loss": -2871.3333333333335
  },
  {
    "hold_time_band": "HOLD_H_4.002-11.97",
    "number_of_trades": 14,
    "net_profit": 7759.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.246928903316148,
    "expectancy": 554.2142857142857,
    "average_win": 9795.25,
    "average_loss": -4488.857142857143
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-50-2096",
    "number_of_trades": 14,
    "net_profit": -66332.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4738.0,
    "average_win": null,
    "average_loss": -4738.0
  },
  {
    "mfe_band": "MFE_2096-7409",
    "number_of_trades": 14,
    "net_profit": -26100.0,
    "win_rate": 0.07142857142857142,
    "profit_factor": 0.04248294078802553,
    "expectancy": -1864.2857142857142,
    "average_win": 1158.0,
    "average_loss": -3407.25
  },
  {
    "mfe_band": "MFE_7409-1.001e+04",
    "number_of_trades": 14,
    "net_profit": 116922.0,
    "win_rate": 0.8571428571428571,
    "profit_factor": null,
    "expectancy": 8351.57142857143,
    "average_win": 9743.5,
    "average_loss": null
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1766--123",
    "number_of_trades": 14,
    "net_profit": 84612.0,
    "win_rate": 0.6428571428571429,
    "profit_factor": 53.26189005558987,
    "expectancy": 6043.714285714285,
    "average_win": 9581.222222222223,
    "average_loss": -539.6666666666666
  },
  {
    "mae_band": "MAE_-4772--1766",
    "number_of_trades": 14,
    "net_profit": 12157.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.617357302457851,
    "expectancy": 868.3571428571429,
    "average_win": 7962.25,
    "average_loss": -3938.4
  },
  {
    "mae_band": "MAE_-7892--4772",
    "number_of_trades": 14,
    "net_profit": -72279.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -5162.785714285715,
    "average_win": null,
    "average_loss": -5162.785714285715
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 8,
    "net_profit": -17057.0,
    "win_rate": 0.125,
    "profit_factor": 0.36058629479682114,
    "expectancy": -2132.125,
    "average_win": 9619.0,
    "average_loss": -4446.0
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 34,
    "net_profit": 41547.0,
    "win_rate": 0.35294117647058826,
    "profit_factor": 1.620901455599725,
    "expectancy": 1221.9705882352941,
    "average_win": 9038.416666666666,
    "average_loss": -4182.125
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 4,
    "net_profit": 15251.0,
    "win_rate": 0.5,
    "profit_factor": 4.395146927871772,
    "expectancy": 3812.75,
    "average_win": 9871.5,
    "average_loss": -2246.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 6,
    "net_profit": -4662.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.6843601895734597,
    "expectancy": -777.0,
    "average_win": 10108.0,
    "average_loss": -4923.333333333333
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 32,
    "net_profit": 13901.0,
    "win_rate": 0.3125,
    "profit_factor": 1.1870223872564847,
    "expectancy": 434.40625,
    "average_win": 8822.9,
    "average_loss": -4372.235294117647
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 4,
    "net_profit": -5215.0,
    "win_rate": 0.25,
    "profit_factor": 0.18170406402008474,
    "expectancy": -1303.75,
    "average_win": 1158.0,
    "average_loss": -2124.3333333333335
  },
  {
    "close_reason": "SL",
    "number_of_trades": 26,
    "net_profit": -87217.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3354.5,
    "average_win": null,
    "average_loss": -4590.368421052632
  },
  {
    "close_reason": "TP",
    "number_of_trades": 12,
    "net_profit": 116922.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9743.5,
    "average_win": 9743.5,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 12,
    "net_profit": 2805.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.0811162521688837,
    "expectancy": 233.75,
    "average_win": 9346.25,
    "average_loss": -4322.5
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 11,
    "net_profit": 26276.0,
    "win_rate": 0.45454545454545453,
    "profit_factor": 2.6800511508951406,
    "expectancy": 2388.7272727272725,
    "average_win": 8383.2,
    "average_loss": -5213.333333333333
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 13,
    "net_profit": 14009.0,
    "win_rate": 0.3076923076923077,
    "profit_factor": 1.5655631812676625,
    "expectancy": 1077.6153846153845,
    "average_win": 9694.75,
    "average_loss": -4128.333333333333
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 6,
    "net_profit": -18600.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3100.0,
    "average_win": null,
    "average_loss": -3720.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 10,
    "net_profit": 260.0,
    "win_rate": 0.3,
    "profit_factor": 1.00852934422465,
    "expectancy": 26.0,
    "average_win": 10247.666666666666,
    "average_loss": -5080.5
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": -5710.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.6525707331913599,
    "expectancy": -815.7142857142857,
    "average_win": 5362.5,
    "average_loss": -5478.333333333333
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 8,
    "net_profit": 28858.0,
    "win_rate": 0.5,
    "profit_factor": 3.8606264869151468,
    "expectancy": 3607.25,
    "average_win": 9736.5,
    "average_loss": -5044.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 8,
    "net_profit": -11115.0,
    "win_rate": 0.125,
    "profit_factor": 0.4531365313653137,
    "expectancy": -1389.375,
    "average_win": 9210.0,
    "average_loss": -3387.5
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 9,
    "net_profit": 12197.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.7501691370933021,
    "expectancy": 1355.2222222222222,
    "average_win": 9485.333333333334,
    "average_loss": -3251.8
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.185-1",
    "number_of_trades": 20,
    "net_profit": 118080.0,
    "win_rate": 0.65,
    "profit_factor": null,
    "expectancy": 5904.0,
    "average_win": 9083.076923076924,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1-3.04",
    "number_of_trades": 7,
    "net_profit": -18876.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2696.5714285714284,
    "average_win": null,
    "average_loss": -2696.5714285714284
  },
  {
    "giveback_band": "GIVEBACK_3.04-38.43",
    "number_of_trades": 14,
    "net_profit": -69491.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4963.642857142857,
    "average_win": null,
    "average_loss": -4963.642857142857
  }
]
```

## time_stop_reason_code別

```json
[
  {
    "time_stop_reason_code": "MAX_HOLDING_BARS_MIN_MFE_NOT_REACHED",
    "number_of_trades": 1,
    "net_profit": -4714.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4714.0,
    "average_win": null,
    "average_loss": -4714.0
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
