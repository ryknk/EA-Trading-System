# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 23
- MFEデータのある負けトレード数: 23
- うち一度含み益になった数: 22
- 割合: 95.65%
- 反転前の平均含み益: 1937.91

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 30
- 平均Giveback比率: 350.77%
- 中央値Giveback比率: 238.24%
- 損益ゼロ以下まで完全反転した割合: 76.67%

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

- 決済件数: 21
- 純損益: -72210.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3438.57
- 平均逆行幅（R）: 0.7814
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 21,
    "net_profit": -72210.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3438.5714285714284,
    "average_win": null,
    "average_loss": -3438.5714285714284
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 5897
- 最終Entry候補まで到達: 55
- Stage別棄却数（market_regime）: 4537
- Stage別棄却数（htf_bias）: 253
- Stage別棄却数（trend_strength_or_momentum_filter）: 696
- Stage別棄却数（setup_or_trigger）: 356
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 4537,
  "RSI_FILTERED": 640,
  "ENTRY_PATTERN_NOT_FOUND": 356,
  "CONFIRMATION_ADX_TOO_LOW": 56,
  "TREND_NOT_ALIGNED": 253
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 31,
    "net_profit": -21654.0,
    "win_rate": 0.22580645161290322,
    "profit_factor": 0.7058280124983018,
    "expectancy": -698.516129032258,
    "average_win": 7422.285714285715,
    "average_loss": -3200.4347826086955
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 5,
    "net_profit": -4906.0,
    "win_rate": 0.2,
    "profit_factor": 0.6375858757479501,
    "expectancy": -981.2,
    "average_win": 8631.0,
    "average_loss": -3384.25
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": 345.0,
    "win_rate": 0.25,
    "profit_factor": 1.0207643695455912,
    "expectancy": 43.125,
    "average_win": 8480.0,
    "average_loss": -2769.1666666666665
  },
  {
    "session": "NewYork",
    "number_of_trades": 8,
    "net_profit": -10215.0,
    "win_rate": 0.25,
    "profit_factor": 0.4802584715579526,
    "expectancy": -1276.875,
    "average_win": 4719.5,
    "average_loss": -3275.6666666666665
  },
  {
    "session": "Tokyo",
    "number_of_trades": 10,
    "net_profit": -6878.0,
    "win_rate": 0.2,
    "profit_factor": 0.7110569652159301,
    "expectancy": -687.8,
    "average_win": 8463.0,
    "average_loss": -3400.5714285714284
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 5,
    "net_profit": 7857.0,
    "win_rate": 0.4,
    "profit_factor": 2.164517563361494,
    "expectancy": 1571.4,
    "average_win": 7302.0,
    "average_loss": -3373.5
  },
  {
    "weekday": "Mon",
    "number_of_trades": 8,
    "net_profit": -15572.0,
    "win_rate": 0.125,
    "profit_factor": 0.35644914658842003,
    "expectancy": -1946.5,
    "average_win": 8625.0,
    "average_loss": -3456.714285714286
  },
  {
    "weekday": "Thu",
    "number_of_trades": 7,
    "net_profit": 4957.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.4127737530185693,
    "expectancy": 708.1428571428571,
    "average_win": 8483.0,
    "average_loss": -2401.8
  },
  {
    "weekday": "Tue",
    "number_of_trades": 6,
    "net_profit": -20057.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3342.8333333333335,
    "average_win": null,
    "average_loss": -3342.8333333333335
  },
  {
    "weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": 1161.0,
    "win_rate": 0.4,
    "profit_factor": 1.1095283018867925,
    "expectancy": 232.2,
    "average_win": 5880.5,
    "average_loss": -3533.3333333333335
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_18.13-39.14",
    "number_of_trades": 10,
    "net_profit": -4996.0,
    "win_rate": 0.3,
    "profit_factor": 0.7924904469180927,
    "expectancy": -499.6,
    "average_win": 6360.0,
    "average_loss": -3439.4285714285716
  },
  {
    "atr_band": "ATR_39.14-55.39",
    "number_of_trades": 10,
    "net_profit": -22039.0,
    "win_rate": 0.1,
    "profit_factor": 0.30432449494949493,
    "expectancy": -2203.9,
    "average_win": 9641.0,
    "average_loss": -3520.0
  },
  {
    "atr_band": "ATR_55.39-79.77",
    "number_of_trades": 11,
    "net_profit": 5381.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 1.301389044471827,
    "expectancy": 489.1818181818182,
    "average_win": 7745.0,
    "average_loss": -2550.5714285714284
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.29-42.43",
    "number_of_trades": 11,
    "net_profit": -2506.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.9139216157730223,
    "expectancy": -227.8181818181818,
    "average_win": 8869.0,
    "average_loss": -3639.125
  },
  {
    "adx_band": "ADX_42.43-47.06",
    "number_of_trades": 10,
    "net_profit": -8228.0,
    "win_rate": 0.2,
    "profit_factor": 0.5342729382464482,
    "expectancy": -822.8,
    "average_win": 4719.5,
    "average_loss": -2523.8571428571427
  },
  {
    "adx_band": "ADX_47.06-58.53",
    "number_of_trades": 10,
    "net_profit": -10920.0,
    "win_rate": 0.2,
    "profit_factor": 0.5929929183749534,
    "expectancy": -1092.0,
    "average_win": 7955.0,
    "average_loss": -3353.75
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.341-2.164",
    "number_of_trades": 10,
    "net_profit": -21165.0,
    "win_rate": 0.1,
    "profit_factor": 0.2825423728813559,
    "expectancy": -2116.5,
    "average_win": 8335.0,
    "average_loss": -3277.777777777778
  },
  {
    "hold_time_band": "HOLD_H_13.44-68.56",
    "number_of_trades": 11,
    "net_profit": 18961.0,
    "win_rate": 0.45454545454545453,
    "profit_factor": 2.182475834112878,
    "expectancy": 1723.7272727272727,
    "average_win": 6999.2,
    "average_loss": -3207.0
  },
  {
    "hold_time_band": "HOLD_H_2.164-13.44",
    "number_of_trades": 10,
    "net_profit": -19450.0,
    "win_rate": 0.1,
    "profit_factor": 0.3072128227960819,
    "expectancy": -1945.0,
    "average_win": 8625.0,
    "average_loss": -3119.4444444444443
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-30-1370",
    "number_of_trades": 10,
    "net_profit": -31311.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3131.1,
    "average_win": null,
    "average_loss": -3131.1
  },
  {
    "mfe_band": "MFE_1370-3717",
    "number_of_trades": 10,
    "net_profit": -34827.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3482.7,
    "average_win": null,
    "average_loss": -3482.7
  },
  {
    "mfe_band": "MFE_3717-9624",
    "number_of_trades": 11,
    "net_profit": 44484.0,
    "win_rate": 0.6363636363636364,
    "profit_factor": 6.953426124197002,
    "expectancy": 4044.0,
    "average_win": 7422.285714285715,
    "average_loss": -2490.6666666666665
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2856--48",
    "number_of_trades": 11,
    "net_profit": 46439.0,
    "win_rate": 0.6363636363636364,
    "profit_factor": 9.417437012869312,
    "expectancy": 4221.727272727273,
    "average_win": 7422.285714285715,
    "average_loss": -1839.0
  },
  {
    "mae_band": "MAE_-3526--2856",
    "number_of_trades": 9,
    "net_profit": -26833.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2981.4444444444443,
    "average_win": null,
    "average_loss": -2981.4444444444443
  },
  {
    "mae_band": "MAE_-4121--3526",
    "number_of_trades": 11,
    "net_profit": -41260.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3750.909090909091,
    "average_win": null,
    "average_loss": -3750.909090909091
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 9,
    "net_profit": -14730.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.3692999357739242,
    "expectancy": -1636.6666666666667,
    "average_win": 8625.0,
    "average_loss": -2919.375
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 22,
    "net_profit": -6924.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.8622226644115013,
    "expectancy": -314.72727272727275,
    "average_win": 7221.833333333333,
    "average_loss": -3350.3333333333335
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 5,
    "net_profit": 11027.0,
    "win_rate": 0.4,
    "profit_factor": 3.2398943733495837,
    "expectancy": 2205.4,
    "average_win": 7975.0,
    "average_loss": -2461.5
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 8,
    "net_profit": -3895.0,
    "win_rate": 0.25,
    "profit_factor": 0.81323423639415,
    "expectancy": -486.875,
    "average_win": 8480.0,
    "average_loss": -3475.8333333333335
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 18,
    "net_profit": -28786.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.3981853152701121,
    "expectancy": -1599.2222222222222,
    "average_win": 6348.666666666667,
    "average_loss": -3188.8
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 23,
    "net_profit": -71487.0,
    "win_rate": 0.043478260869565216,
    "profit_factor": 0.02880160854266578,
    "expectancy": -3108.1304347826085,
    "average_win": 2120.0,
    "average_loss": -3345.7727272727275
  },
  {
    "close_reason": "SL",
    "number_of_trades": 2,
    "net_profit": -3.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1.5,
    "average_win": null,
    "average_loss": -3.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 6,
    "net_profit": 49836.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8306.0,
    "average_win": 8306.0,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 4,
    "net_profit": -11464.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2866.0,
    "average_win": null,
    "average_loss": -2866.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 12,
    "net_profit": -13565.0,
    "win_rate": 0.25,
    "profit_factor": 0.5845456494441211,
    "expectancy": -1130.4166666666667,
    "average_win": 6362.0,
    "average_loss": -3627.8888888888887
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 13,
    "net_profit": 10096.0,
    "win_rate": 0.3076923076923077,
    "profit_factor": 1.443312549398437,
    "expectancy": 776.6153846153846,
    "average_win": 8217.5,
    "average_loss": -2846.75
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 2,
    "net_profit": -6721.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3360.5,
    "average_win": null,
    "average_loss": -3360.5
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 5,
    "net_profit": 11298.0,
    "win_rate": 0.4,
    "profit_factor": 3.4465136422693807,
    "expectancy": 2259.6,
    "average_win": 7958.0,
    "average_loss": -2309.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 8,
    "net_profit": -4111.0,
    "win_rate": 0.25,
    "profit_factor": 0.7950137122911992,
    "expectancy": -513.875,
    "average_win": 7972.0,
    "average_loss": -3342.5
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 6,
    "net_profit": -157.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.985205427817565,
    "expectancy": -26.166666666666668,
    "average_win": 5227.5,
    "average_loss": -2653.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 7,
    "net_profit": -24281.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3468.714285714286,
    "average_win": null,
    "average_loss": -3468.714285714286
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": -4403.0,
    "win_rate": 0.2,
    "profit_factor": 0.6864853318142979,
    "expectancy": -880.6,
    "average_win": 9641.0,
    "average_loss": -3511.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00606-1.866",
    "number_of_trades": 10,
    "net_profit": 48605.0,
    "win_rate": 0.7,
    "profit_factor": 15.504625484929871,
    "expectancy": 4860.5,
    "average_win": 7422.285714285715,
    "average_loss": -1675.5
  },
  {
    "giveback_band": "GIVEBACK_1.866-3.368",
    "number_of_trades": 10,
    "net_profit": -32677.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3267.7,
    "average_win": null,
    "average_loss": -3267.7
  },
  {
    "giveback_band": "GIVEBACK_3.368-32.38",
    "number_of_trades": 10,
    "net_profit": -34361.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3436.1,
    "average_win": null,
    "average_loss": -3436.1
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
