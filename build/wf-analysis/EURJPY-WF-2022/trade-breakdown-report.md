# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 11
- MFEデータのある負けトレード数: 11
- うち一度含み益になった数: 11
- 割合: 100.00%
- 反転前の平均含み益: 1436.36

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 19
- 平均Giveback比率: 1181.45%
- 中央値Giveback比率: 199.35%
- 損益ゼロ以下まで完全反転した割合: 57.89%

## Time Stop（時間切れ決済）

- Time Stopによる決済件数: 1
- 純損益: 827.00
- プロフィットファクター: 算出不能
- 勝率: 100.00%
- 期待値: 827.00

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

- 決済件数: 10
- 純損益: -35673.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3567.30
- 平均逆行幅（R）: 0.7544
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 9,
    "net_profit": -32265.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3585.0,
    "average_win": null,
    "average_loss": -3585.0
  },
  "SELL": {
    "number_of_trades": 1,
    "net_profit": -3408.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3408.0,
    "average_win": null,
    "average_loss": -3408.0
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6344
- 最終Entry候補まで到達: 27
- Stage別棄却数（market_regime）: 5355
- Stage別棄却数（htf_bias）: 293
- Stage別棄却数（trend_strength_or_momentum_filter）: 402
- Stage別棄却数（setup_or_trigger）: 267
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5355,
  "RSI_FILTERED": 355,
  "ENTRY_PATTERN_NOT_FOUND": 267,
  "CONFIRMATION_ADX_TOO_LOW": 47,
  "TREND_NOT_ALIGNED": 293
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 17,
    "net_profit": 3649.0,
    "win_rate": 0.4117647058823529,
    "profit_factor": 1.0980123556271824,
    "expectancy": 214.64705882352942,
    "average_win": 5839.857142857143,
    "average_loss": -3723.0
  },
  {
    "direction": "SELL",
    "number_of_trades": 2,
    "net_profit": 6420.0,
    "win_rate": 0.5,
    "profit_factor": 2.8838028169014085,
    "expectancy": 3210.0,
    "average_win": 9828.0,
    "average_loss": -3408.0
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 6,
    "net_profit": 17079.0,
    "win_rate": 0.5,
    "profit_factor": 2.599606631076145,
    "expectancy": 2846.5,
    "average_win": 9252.0,
    "average_loss": -3559.0
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 4,
    "net_profit": -10218.0,
    "win_rate": 0.25,
    "profit_factor": 0.07487550928021729,
    "expectancy": -2554.5,
    "average_win": 827.0,
    "average_loss": -3681.6666666666665
  },
  {
    "session": "NewYork",
    "number_of_trades": 3,
    "net_profit": -5150.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.277395818717553,
    "expectancy": -1716.6666666666667,
    "average_win": 1977.0,
    "average_loss": -3563.5
  },
  {
    "session": "Tokyo",
    "number_of_trades": 6,
    "net_profit": 8358.0,
    "win_rate": 0.5,
    "profit_factor": 1.7089659852404784,
    "expectancy": 1393.0,
    "average_win": 6715.666666666667,
    "average_loss": -3929.6666666666665
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 4,
    "net_profit": -11214.0,
    "win_rate": 0.25,
    "profit_factor": 0.06868200315588406,
    "expectancy": -2803.5,
    "average_win": 827.0,
    "average_loss": -4013.6666666666665
  },
  {
    "weekday": "Mon",
    "number_of_trades": 5,
    "net_profit": -12811.0,
    "win_rate": 0.2,
    "profit_factor": 0.0682909090909091,
    "expectancy": -2562.2,
    "average_win": 939.0,
    "average_loss": -3437.5
  },
  {
    "weekday": "Thu",
    "number_of_trades": 1,
    "net_profit": -3794.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3794.0,
    "average_win": null,
    "average_loss": -3794.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 7,
    "net_profit": 32484.0,
    "win_rate": 0.7142857142857143,
    "profit_factor": 5.415386706537991,
    "expectancy": 4640.571428571428,
    "average_win": 7968.2,
    "average_loss": -3678.5
  },
  {
    "weekday": "Wed",
    "number_of_trades": 2,
    "net_profit": 5404.0,
    "win_rate": 0.5,
    "profit_factor": 2.462121212121212,
    "expectancy": 2702.0,
    "average_win": 9100.0,
    "average_loss": -3696.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.146-0.226",
    "number_of_trades": 6,
    "net_profit": 8913.0,
    "win_rate": 0.5,
    "profit_factor": 1.8013846430498113,
    "expectancy": 1485.5,
    "average_win": 6678.333333333333,
    "average_loss": -3707.3333333333335
  },
  {
    "atr_band": "ATR_0.226-0.281",
    "number_of_trades": 7,
    "net_profit": 19127.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 2.784568016420974,
    "expectancy": 2732.4285714285716,
    "average_win": 7461.25,
    "average_loss": -3572.6666666666665
  },
  {
    "atr_band": "ATR_0.281-0.614",
    "number_of_trades": 6,
    "net_profit": -17971.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.043994041919353126,
    "expectancy": -2995.1666666666665,
    "average_win": 827.0,
    "average_loss": -3759.6
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.36-41.39",
    "number_of_trades": 7,
    "net_profit": 11447.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 2.100990670385688,
    "expectancy": 1635.2857142857142,
    "average_win": 5461.0,
    "average_loss": -3465.6666666666665
  },
  {
    "adx_band": "ADX_41.39-44.52",
    "number_of_trades": 5,
    "net_profit": -6193.0,
    "win_rate": 0.2,
    "profit_factor": 0.6107234898485134,
    "expectancy": -1238.6,
    "average_win": 9716.0,
    "average_loss": -3977.25
  },
  {
    "adx_band": "ADX_44.52-56.15",
    "number_of_trades": 7,
    "net_profit": 4815.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.3359614847892827,
    "expectancy": 687.8571428571429,
    "average_win": 6382.333333333333,
    "average_loss": -3583.0
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.177-3.082",
    "number_of_trades": 6,
    "net_profit": -8066.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.546395231132606,
    "expectancy": -1344.3333333333333,
    "average_win": 9716.0,
    "average_loss": -3556.4
  },
  {
    "hold_time_band": "HOLD_H_12.56-66",
    "number_of_trades": 7,
    "net_profit": 1057.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 1.0876015249461297,
    "expectancy": 151.0,
    "average_win": 3280.75,
    "average_loss": -4022.0
  },
  {
    "hold_time_band": "HOLD_H_3.082-12.56",
    "number_of_trades": 6,
    "net_profit": 17078.0,
    "win_rate": 0.5,
    "profit_factor": 2.582761816496756,
    "expectancy": 2846.3333333333335,
    "average_win": 9289.333333333334,
    "average_loss": -3596.6666666666665
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_1187-3651",
    "number_of_trades": 6,
    "net_profit": -12144.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.1269590222861251,
    "expectancy": -2024.0,
    "average_win": 883.0,
    "average_loss": -3477.5
  },
  {
    "mfe_band": "MFE_35-1187",
    "number_of_trades": 6,
    "net_profit": -23068.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3844.6666666666665,
    "average_win": null,
    "average_loss": -3844.6666666666665
  },
  {
    "mfe_band": "MFE_3651-9819",
    "number_of_trades": 7,
    "net_profit": 45281.0,
    "win_rate": 0.8571428571428571,
    "profit_factor": 13.371857923497268,
    "expectancy": 6468.714285714285,
    "average_win": 8156.833333333333,
    "average_loss": -3660.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-3016--820",
    "number_of_trades": 7,
    "net_profit": 48730.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 6961.428571428572,
    "average_win": 6961.428571428572,
    "average_loss": null
  },
  {
    "mae_band": "MAE_-3591--3016",
    "number_of_trades": 5,
    "net_profit": -11496.0,
    "win_rate": 0.2,
    "profit_factor": 0.14673792028501448,
    "expectancy": -2299.2,
    "average_win": 1977.0,
    "average_loss": -3368.25
  },
  {
    "mae_band": "MAE_-6225--3591",
    "number_of_trades": 7,
    "net_profit": -27165.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3880.714285714286,
    "average_win": null,
    "average_loss": -3880.714285714286
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 3,
    "net_profit": 7359.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 3.159330985915493,
    "expectancy": 2453.0,
    "average_win": 5383.5,
    "average_loss": -3408.0
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 16,
    "net_profit": 2710.0,
    "win_rate": 0.375,
    "profit_factor": 1.0727907601396722,
    "expectancy": 169.375,
    "average_win": 6656.666666666667,
    "average_loss": -3723.0
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 1,
    "net_profit": -3408.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3408.0,
    "average_win": null,
    "average_loss": -3408.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 3,
    "net_profit": 20633.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 6877.666666666667,
    "average_win": 6877.666666666667,
    "average_loss": null
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 15,
    "net_profit": -7156.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.8077894171367177,
    "expectancy": -477.06666666666666,
    "average_win": 6014.8,
    "average_loss": -3723.0
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 13,
    "net_profit": -31930.0,
    "win_rate": 0.23076923076923078,
    "profit_factor": 0.1049252936394472,
    "expectancy": -2456.153846153846,
    "average_win": 1247.6666666666667,
    "average_loss": -3567.3
  },
  {
    "close_reason": "SL",
    "number_of_trades": 1,
    "net_profit": -4965.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4965.0,
    "average_win": null,
    "average_loss": -4965.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 5,
    "net_profit": 46964.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9392.8,
    "average_win": 9392.8,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 5,
    "net_profit": 14062.0,
    "win_rate": 0.6,
    "profit_factor": 2.8852393082182597,
    "expectancy": 2812.4,
    "average_win": 7173.666666666667,
    "average_loss": -3729.5
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": -3324.0,
    "win_rate": 0.25,
    "profit_factor": 0.8444111589589964,
    "expectancy": -415.5,
    "average_win": 9020.0,
    "average_loss": -3560.6666666666665
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 6,
    "net_profit": -669.0,
    "win_rate": 0.5,
    "profit_factor": 0.943377063055438,
    "expectancy": -111.5,
    "average_win": 3715.3333333333335,
    "average_loss": -3938.3333333333335
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 2,
    "net_profit": -7076.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3538.0,
    "average_win": null,
    "average_loss": -3538.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 4,
    "net_profit": -10761.0,
    "win_rate": 0.25,
    "profit_factor": 0.07136693130824992,
    "expectancy": -2690.25,
    "average_win": 827.0,
    "average_loss": -3862.6666666666665
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 1,
    "net_profit": -3794.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3794.0,
    "average_win": null,
    "average_loss": -3794.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 8,
    "net_profit": 14939.0,
    "win_rate": 0.5,
    "profit_factor": 2.0314139740403205,
    "expectancy": 1867.375,
    "average_win": 7355.75,
    "average_loss": -3621.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 4,
    "net_profit": 16761.0,
    "win_rate": 0.75,
    "profit_factor": 5.534902597402597,
    "expectancy": 4190.25,
    "average_win": 6819.0,
    "average_loss": -3696.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00542-0.459",
    "number_of_trades": 6,
    "net_profit": 47791.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7965.166666666667,
    "average_win": 7965.166666666667,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.459-3.603",
    "number_of_trades": 6,
    "net_profit": -11439.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.2031347962382445,
    "expectancy": -1906.5,
    "average_win": 1458.0,
    "average_loss": -3588.75
  },
  {
    "giveback_band": "GIVEBACK_3.603-98.6",
    "number_of_trades": 7,
    "net_profit": -26283.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3754.714285714286,
    "average_win": null,
    "average_loss": -3754.714285714286
  }
]
```

## time_stop_reason_code別

```json
[
  {
    "time_stop_reason_code": "MAX_HOLDING_BARS_MIN_MFE_NOT_REACHED",
    "number_of_trades": 1,
    "net_profit": 827.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 827.0,
    "average_win": 827.0,
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
