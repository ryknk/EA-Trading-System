# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 32
- MFEデータのある負けトレード数: 32
- うち一度含み益になった数: 28
- 割合: 87.50%
- 反転前の平均含み益: 2326.14

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 46
- 平均Giveback比率: 275.86%
- 中央値Giveback比率: 102.12%
- 損益ゼロ以下まで完全反転した割合: 63.04%

## Time Stop（時間切れ決済）

- Time Stopによる決済件数: 1
- 純損益: 834.00
- プロフィットファクター: 算出不能
- 勝率: 100.00%
- 期待値: 834.00

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

- 決済件数: 26
- 純損益: -79470.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3056.54
- 平均逆行幅（R）: 0.7755
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 22,
    "net_profit": -66920.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3041.818181818182,
    "average_win": null,
    "average_loss": -3041.818181818182
  },
  "SELL": {
    "number_of_trades": 4,
    "net_profit": -12550.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3137.5,
    "average_win": null,
    "average_loss": -3137.5
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 9780
- 最終Entry候補まで到達: 102
- Stage別棄却数（market_regime）: 7829
- Stage別棄却数（htf_bias）: 223
- Stage別棄却数（trend_strength_or_momentum_filter）: 1047
- Stage別棄却数（setup_or_trigger）: 579
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 7829,
  "TREND_NOT_ALIGNED": 223,
  "ENTRY_PATTERN_NOT_FOUND": 579,
  "RSI_FILTERED": 842,
  "CONFIRMATION_ADX_TOO_LOW": 205
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 45,
    "net_profit": 18655.0,
    "win_rate": 0.35555555555555557,
    "profit_factor": 1.2773853954470433,
    "expectancy": 414.55555555555554,
    "average_win": 5369.25,
    "average_loss": -2401.8928571428573
  },
  {
    "direction": "SELL",
    "number_of_trades": 5,
    "net_profit": -3694.0,
    "win_rate": 0.2,
    "profit_factor": 0.7056573705179283,
    "expectancy": -738.8,
    "average_win": 8856.0,
    "average_loss": -3137.5
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 11,
    "net_profit": -14863.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.39725860740500424,
    "expectancy": -1351.1818181818182,
    "average_win": 4898.0,
    "average_loss": -2739.8888888888887
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": 2975.0,
    "win_rate": 0.375,
    "profit_factor": 1.1993566977149366,
    "expectancy": 371.875,
    "average_win": 5966.0,
    "average_loss": -2984.6
  },
  {
    "session": "NewYork",
    "number_of_trades": 20,
    "net_profit": -223.0,
    "win_rate": 0.3,
    "profit_factor": 0.9936185434253827,
    "expectancy": -11.15,
    "average_win": 5787.0,
    "average_loss": -2688.076923076923
  },
  {
    "session": "Tokyo",
    "number_of_trades": 11,
    "net_profit": 27072.0,
    "win_rate": 0.5454545454545454,
    "profit_factor": 6.131159969673996,
    "expectancy": 2461.090909090909,
    "average_win": 5391.333333333333,
    "average_loss": -1055.2
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 9,
    "net_profit": 12056.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.9207973726418697,
    "expectancy": 1339.5555555555557,
    "average_win": 8383.0,
    "average_loss": -2182.1666666666665
  },
  {
    "weekday": "Mon",
    "number_of_trades": 11,
    "net_profit": 5442.0,
    "win_rate": 0.45454545454545453,
    "profit_factor": 1.418550992155053,
    "expectancy": 494.72727272727275,
    "average_win": 3688.8,
    "average_loss": -2167.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 12,
    "net_profit": 2796.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.1515447154471545,
    "expectancy": 233.0,
    "average_win": 5311.5,
    "average_loss": -2635.714285714286
  },
  {
    "weekday": "Tue",
    "number_of_trades": 10,
    "net_profit": 3512.0,
    "win_rate": 0.3,
    "profit_factor": 1.2169374266477238,
    "expectancy": 351.2,
    "average_win": 6567.0,
    "average_loss": -2312.714285714286
  },
  {
    "weekday": "Wed",
    "number_of_trades": 8,
    "net_profit": -8845.0,
    "win_rate": 0.25,
    "profit_factor": 0.5361581624626357,
    "expectancy": -1105.625,
    "average_win": 5112.0,
    "average_loss": -3178.1666666666665
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_105.8-160",
    "number_of_trades": 17,
    "net_profit": 21352.0,
    "win_rate": 0.47058823529411764,
    "profit_factor": 2.0138651471984805,
    "expectancy": 1256.0,
    "average_win": 5301.5,
    "average_loss": -2340.0
  },
  {
    "atr_band": "ATR_39-78.05",
    "number_of_trades": 17,
    "net_profit": -14409.0,
    "win_rate": 0.17647058823529413,
    "profit_factor": 0.6357039921118499,
    "expectancy": -847.5882352941177,
    "average_win": 8381.333333333334,
    "average_loss": -2825.214285714286
  },
  {
    "atr_band": "ATR_78.05-105.8",
    "number_of_trades": 16,
    "net_profit": 8018.0,
    "win_rate": 0.375,
    "profit_factor": 1.4178217821782177,
    "expectancy": 501.125,
    "average_win": 4534.666666666667,
    "average_loss": -2132.222222222222
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.02-41.95",
    "number_of_trades": 17,
    "net_profit": 7343.0,
    "win_rate": 0.35294117647058826,
    "profit_factor": 1.373594505214958,
    "expectancy": 431.94117647058823,
    "average_win": 4499.666666666667,
    "average_loss": -1965.5
  },
  {
    "adx_band": "ADX_41.95-45.85",
    "number_of_trades": 16,
    "net_profit": -2536.0,
    "win_rate": 0.3125,
    "profit_factor": 0.9205613331662699,
    "expectancy": -158.5,
    "average_win": 5877.6,
    "average_loss": -2902.181818181818
  },
  {
    "adx_band": "ADX_45.85-54.66",
    "number_of_trades": 17,
    "net_profit": 10154.0,
    "win_rate": 0.35294117647058826,
    "profit_factor": 1.3597647392290249,
    "expectancy": 597.2941176470588,
    "average_win": 6396.333333333333,
    "average_loss": -2565.818181818182
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.19-2.247",
    "number_of_trades": 17,
    "net_profit": -28923.0,
    "win_rate": 0.11764705882352941,
    "profit_factor": 0.35832187070151306,
    "expectancy": -1701.3529411764705,
    "average_win": 8075.5,
    "average_loss": -3004.9333333333334
  },
  {
    "hold_time_band": "HOLD_H_17.29-85.04",
    "number_of_trades": 17,
    "net_profit": 41429.0,
    "win_rate": 0.5882352941176471,
    "profit_factor": 5.065253655185948,
    "expectancy": 2437.0,
    "average_win": 5162.0,
    "average_loss": -1698.5
  },
  {
    "hold_time_band": "HOLD_H_2.247-17.29",
    "number_of_trades": 16,
    "net_profit": 2455.0,
    "win_rate": 0.3125,
    "profit_factor": 1.1000489037411363,
    "expectancy": 153.4375,
    "average_win": 5398.6,
    "average_loss": -2230.7272727272725
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-59-1492",
    "number_of_trades": 17,
    "net_profit": -52605.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3094.4117647058824,
    "average_win": null,
    "average_loss": -3094.4117647058824
  },
  {
    "mfe_band": "MFE_1492-4977",
    "number_of_trades": 16,
    "net_profit": -19514.0,
    "win_rate": 0.25,
    "profit_factor": 0.2788617886178862,
    "expectancy": -1219.625,
    "average_win": 1886.5,
    "average_loss": -2460.0
  },
  {
    "mfe_band": "MFE_4977-9497",
    "number_of_trades": 17,
    "net_profit": 87080.0,
    "win_rate": 0.7647058823529411,
    "profit_factor": 632.0144927536232,
    "expectancy": 5122.35294117647,
    "average_win": 6709.076923076923,
    "average_loss": -34.5
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1492--78",
    "number_of_trades": 17,
    "net_profit": 58525.0,
    "win_rate": 0.6470588235294118,
    "profit_factor": 327.9553072625698,
    "expectancy": 3442.6470588235293,
    "average_win": 5336.727272727273,
    "average_loss": -35.8
  },
  {
    "mae_band": "MAE_-2979--1492",
    "number_of_trades": 16,
    "net_profit": 1248.0,
    "win_rate": 0.3125,
    "profit_factor": 1.0497250776954339,
    "expectancy": 78.0,
    "average_win": 5269.2,
    "average_loss": -2281.6363636363635
  },
  {
    "mae_band": "MAE_-4357--2979",
    "number_of_trades": 17,
    "net_profit": -44812.0,
    "win_rate": 0.058823529411764705,
    "profit_factor": 0.17815354142977663,
    "expectancy": -2636.0,
    "average_win": 9714.0,
    "average_loss": -3407.875
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 16,
    "net_profit": 2981.0,
    "win_rate": 0.3125,
    "profit_factor": 1.1111525411089154,
    "expectancy": 186.3125,
    "average_win": 5960.0,
    "average_loss": -2438.090909090909
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 34,
    "net_profit": 11980.0,
    "win_rate": 0.35294117647058826,
    "profit_factor": 1.2261059942624188,
    "expectancy": 352.3529411764706,
    "average_win": 5413.666666666667,
    "average_loss": -2523.0476190476193
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 7,
    "net_profit": 5830.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 1.7109756097560975,
    "expectancy": 832.8571428571429,
    "average_win": 3507.5,
    "average_loss": -2733.3333333333335
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 12,
    "net_profit": -15638.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.4512597375254404,
    "expectancy": -1303.1666666666667,
    "average_win": 6430.0,
    "average_loss": -2849.8
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 31,
    "net_profit": 24769.0,
    "win_rate": 0.3548387096774194,
    "profit_factor": 1.5746201136759077,
    "expectancy": 799.0,
    "average_win": 6170.363636363636,
    "average_loss": -2268.684210526316
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 31,
    "net_profit": -68874.0,
    "win_rate": 0.16129032258064516,
    "profit_factor": 0.13333333333333333,
    "expectancy": -2221.7419354838707,
    "average_win": 2119.2,
    "average_loss": -3056.5384615384614
  },
  {
    "close_reason": "SL",
    "number_of_trades": 7,
    "net_profit": -333.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -47.57142857142857,
    "average_win": null,
    "average_loss": -55.5
  },
  {
    "close_reason": "TP",
    "number_of_trades": 12,
    "net_profit": 84168.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7014.0,
    "average_win": 7014.0,
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
    "net_profit": 14800.0,
    "win_rate": 0.5,
    "profit_factor": 2.2140103354933967,
    "expectancy": 1850.0,
    "average_win": 6747.75,
    "average_loss": -3047.75
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 21,
    "net_profit": -346.0,
    "win_rate": 0.23809523809523808,
    "profit_factor": 0.9898013323115015,
    "expectancy": -16.476190476190474,
    "average_win": 6716.0,
    "average_loss": -2261.733333333333
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 13,
    "net_profit": -471.0,
    "win_rate": 0.3076923076923077,
    "profit_factor": 0.9810226036504291,
    "expectancy": -36.23076923076923,
    "average_win": 6087.0,
    "average_loss": -2757.6666666666665
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 8,
    "net_profit": 978.0,
    "win_rate": 0.5,
    "profit_factor": 1.1102966053907748,
    "expectancy": 122.25,
    "average_win": 2461.25,
    "average_loss": -2216.75
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 11,
    "net_profit": -2521.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.8706383415435139,
    "expectancy": -229.1818181818182,
    "average_win": 5655.666666666667,
    "average_loss": -2784.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 10,
    "net_profit": 13160.0,
    "win_rate": 0.4,
    "profit_factor": 2.3626009525781737,
    "expectancy": 1316.0,
    "average_win": 5704.5,
    "average_loss": -1609.6666666666667
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 8,
    "net_profit": 8820.0,
    "win_rate": 0.5,
    "profit_factor": 1.7441154138192863,
    "expectancy": 1102.5,
    "average_win": 5168.25,
    "average_loss": -2963.25
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 11,
    "net_profit": 6194.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 1.4689582071471836,
    "expectancy": 563.0909090909091,
    "average_win": 4850.5,
    "average_loss": -1886.857142857143
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 10,
    "net_profit": -10692.0,
    "win_rate": 0.2,
    "profit_factor": 0.5822784810126582,
    "expectancy": -1069.2,
    "average_win": 7452.0,
    "average_loss": -3199.5
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.117-0.657",
    "number_of_trades": 15,
    "net_profit": 93008.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 6200.533333333334,
    "average_win": 6200.533333333334,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.657-2.238",
    "number_of_trades": 15,
    "net_profit": -16335.0,
    "win_rate": 0.13333333333333333,
    "profit_factor": 0.09706483887015643,
    "expectancy": -1089.0,
    "average_win": 878.0,
    "average_loss": -1507.5833333333333
  },
  {
    "giveback_band": "GIVEBACK_2.238-20.09",
    "number_of_trades": 16,
    "net_profit": -49080.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3067.5,
    "average_win": null,
    "average_loss": -3067.5
  }
]
```

## time_stop_reason_code別

```json
[
  {
    "time_stop_reason_code": "MAX_HOLDING_BARS_MIN_MFE_NOT_REACHED",
    "number_of_trades": 1,
    "net_profit": 834.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 834.0,
    "average_win": 834.0,
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
