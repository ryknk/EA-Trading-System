# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 25
- MFEデータのある負けトレード数: 25
- うち一度含み益になった数: 22
- 割合: 88.00%
- 反転前の平均含み益: 2001.77

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 31
- 平均Giveback比率: 298.61%
- 中央値Giveback比率: 203.01%
- 損益ゼロ以下まで完全反転した割合: 70.97%

## Time Stop（時間切れ決済）

- Time Stopによる決済件数: 1
- 純損益: 1152.00
- プロフィットファクター: 算出不能
- 勝率: 100.00%
- 期待値: 1152.00

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
- 純損益: -65995.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3142.62
- 平均逆行幅（R）: 0.7786
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 21,
    "net_profit": -65995.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3142.6190476190477,
    "average_win": null,
    "average_loss": -3142.6190476190477
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 4459
- 最終Entry候補まで到達: 66
- Stage別棄却数（market_regime）: 3571
- Stage別棄却数（htf_bias）: 134
- Stage別棄却数（trend_strength_or_momentum_filter）: 356
- Stage別棄却数（setup_or_trigger）: 332
- Stage別棄却数（other）: 0

```json
{
  "ENTRY_PATTERN_NOT_FOUND": 332,
  "REGIME_NOT_TRENDING": 3571,
  "RSI_FILTERED": 336,
  "CONFIRMATION_ADX_TOO_LOW": 20,
  "TREND_NOT_ALIGNED": 134
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 34,
    "net_profit": -22692.0,
    "win_rate": 0.2647058823529412,
    "profit_factor": 0.6854100815172184,
    "expectancy": -667.4117647058823,
    "average_win": 5493.333333333333,
    "average_loss": -2885.28
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 8,
    "net_profit": -17987.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2248.375,
    "average_win": null,
    "average_loss": -2248.375
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 7,
    "net_profit": -1072.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.9385426818781173,
    "expectancy": -153.14285714285714,
    "average_win": 8185.5,
    "average_loss": -3488.6
  },
  {
    "session": "NewYork",
    "number_of_trades": 8,
    "net_profit": -6177.0,
    "win_rate": 0.375,
    "profit_factor": 0.6202041318248893,
    "expectancy": -772.125,
    "average_win": 3362.3333333333335,
    "average_loss": -3252.8
  },
  {
    "session": "Tokyo",
    "number_of_trades": 11,
    "net_profit": 2544.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 1.124474018984245,
    "expectancy": 231.27272727272728,
    "average_win": 5745.5,
    "average_loss": -2919.714285714286
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 9,
    "net_profit": 1676.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.0876477355925112,
    "expectancy": 186.22222222222223,
    "average_win": 6932.666666666667,
    "average_loss": -3187.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 6,
    "net_profit": -2196.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.8176685486549319,
    "expectancy": -366.0,
    "average_win": 4924.0,
    "average_loss": -3011.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 11,
    "net_profit": -12034.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.5763421932758317,
    "expectancy": -1094.0,
    "average_win": 8185.5,
    "average_loss": -3156.1111111111113
  },
  {
    "weekday": "Tue",
    "number_of_trades": 5,
    "net_profit": -5980.0,
    "win_rate": 0.2,
    "profit_factor": 0.19796137339055794,
    "expectancy": -1196.0,
    "average_win": 1476.0,
    "average_loss": -1864.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 3,
    "net_profit": -4158.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.18550440744368266,
    "expectancy": -1386.0,
    "average_win": 947.0,
    "average_loss": -2552.5
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_3.699-6.514",
    "number_of_trades": 12,
    "net_profit": -14540.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.5296172883439553,
    "expectancy": -1211.6666666666667,
    "average_win": 8185.5,
    "average_loss": -3091.1
  },
  {
    "atr_band": "ATR_6.514-8.379",
    "number_of_trades": 10,
    "net_profit": -5453.0,
    "win_rate": 0.4,
    "profit_factor": 0.7429648833372614,
    "expectancy": -545.3,
    "average_win": 3940.5,
    "average_loss": -3535.8333333333335
  },
  {
    "atr_band": "ATR_8.379-16.15",
    "number_of_trades": 12,
    "net_profit": -2699.0,
    "win_rate": 0.25,
    "profit_factor": 0.8650904728581426,
    "expectancy": -224.91666666666666,
    "average_win": 5769.0,
    "average_loss": -2222.8888888888887
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.07-41.16",
    "number_of_trades": 12,
    "net_profit": -7668.0,
    "win_rate": 0.25,
    "profit_factor": 0.664713598600787,
    "expectancy": -639.0,
    "average_win": 5067.333333333333,
    "average_loss": -2541.1111111111113
  },
  {
    "adx_band": "ADX_41.16-44.82",
    "number_of_trades": 11,
    "net_profit": 1904.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 1.085912823752369,
    "expectancy": 173.0909090909091,
    "average_win": 6016.5,
    "average_loss": -3166.0
  },
  {
    "adx_band": "ADX_44.82-56.05",
    "number_of_trades": 11,
    "net_profit": -16928.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.37535055350553503,
    "expectancy": -1538.909090909091,
    "average_win": 5086.0,
    "average_loss": -3011.1111111111113
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.529-4.512",
    "number_of_trades": 11,
    "net_profit": -25437.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.22925188619216436,
    "expectancy": -2312.4545454545455,
    "average_win": 7566.0,
    "average_loss": -3300.3
  },
  {
    "hold_time_band": "HOLD_H_14.58-109.9",
    "number_of_trades": 12,
    "net_profit": 7157.0,
    "win_rate": 0.4166666666666667,
    "profit_factor": 1.393912708459464,
    "expectancy": 596.4166666666666,
    "average_win": 5065.2,
    "average_loss": -2595.5714285714284
  },
  {
    "hold_time_band": "HOLD_H_4.512-14.58",
    "number_of_trades": 11,
    "net_profit": -4412.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.7895038167938931,
    "expectancy": -401.09090909090907,
    "average_win": 5516.0,
    "average_loss": -2620.0
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-110-1249",
    "number_of_trades": 12,
    "net_profit": -32149.0,
    "win_rate": 0.08333333333333333,
    "profit_factor": 0.034593555749076604,
    "expectancy": -2679.0833333333335,
    "average_win": 1152.0,
    "average_loss": -3027.3636363636365
  },
  {
    "mfe_band": "MFE_1249-3220",
    "number_of_trades": 11,
    "net_profit": -30799.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.02983052983052983,
    "expectancy": -2799.909090909091,
    "average_win": 947.0,
    "average_loss": -3174.6
  },
  {
    "mfe_band": "MFE_3220-8717",
    "number_of_trades": 11,
    "net_profit": 40256.0,
    "win_rate": 0.6363636363636364,
    "profit_factor": 6.681863091037403,
    "expectancy": 3659.6363636363635,
    "average_win": 6763.0,
    "average_loss": -1771.25
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2252-66",
    "number_of_trades": 11,
    "net_profit": 37769.0,
    "win_rate": 0.6363636363636364,
    "profit_factor": 12.111797587525743,
    "expectancy": 3433.5454545454545,
    "average_win": 5881.142857142857,
    "average_loss": -849.75
  },
  {
    "mae_band": "MAE_-3293--2252",
    "number_of_trades": 11,
    "net_profit": -18583.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.3080245764289704,
    "expectancy": -1689.3636363636363,
    "average_win": 4136.0,
    "average_loss": -2983.8888888888887
  },
  {
    "mae_band": "MAE_-3864--3293",
    "number_of_trades": 12,
    "net_profit": -41878.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3489.8333333333335,
    "average_win": null,
    "average_loss": -3489.8333333333335
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 2,
    "net_profit": -5134.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2567.0,
    "average_win": null,
    "average_loss": -2567.0
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 32,
    "net_profit": -17558.0,
    "win_rate": 0.28125,
    "profit_factor": 0.7379324755962865,
    "expectancy": -548.6875,
    "average_win": 5493.333333333333,
    "average_loss": -2912.9565217391305
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 3,
    "net_profit": 1954.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.4035522511358942,
    "expectancy": 651.3333333333334,
    "average_win": 6796.0,
    "average_loss": -2421.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 6,
    "net_profit": -7902.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.5270246004668702,
    "expectancy": -1317.0,
    "average_win": 8805.0,
    "average_loss": -3341.4
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 25,
    "net_profit": -16744.0,
    "win_rate": 0.28,
    "profit_factor": 0.6689796967360576,
    "expectancy": -669.76,
    "average_win": 4834.142857142857,
    "average_loss": -2810.1666666666665
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 25,
    "net_profit": -63507.0,
    "win_rate": 0.12,
    "profit_factor": 0.05329298470528607,
    "expectancy": -2540.28,
    "average_win": 1191.6666666666667,
    "average_loss": -3049.181818181818
  },
  {
    "close_reason": "SL",
    "number_of_trades": 3,
    "net_profit": -5050.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1683.3333333333333,
    "average_win": null,
    "average_loss": -1683.3333333333333
  },
  {
    "close_reason": "TP",
    "number_of_trades": 6,
    "net_profit": 45865.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7644.166666666667,
    "average_win": 7644.166666666667,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 3,
    "net_profit": -6019.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.13594602354292276,
    "expectancy": -2006.3333333333333,
    "average_win": 947.0,
    "average_loss": -3483.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 12,
    "net_profit": -18745.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.30617759188658994,
    "expectancy": -1562.0833333333333,
    "average_win": 4136.0,
    "average_loss": -2701.7
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 12,
    "net_profit": 9844.0,
    "win_rate": 0.4166666666666667,
    "profit_factor": 1.4563322825885407,
    "expectancy": 820.3333333333334,
    "average_win": 6283.2,
    "average_loss": -3081.714285714286
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 7,
    "net_profit": -7772.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.531157628038849,
    "expectancy": -1110.2857142857142,
    "average_win": 8805.0,
    "average_loss": -2762.8333333333335
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 5,
    "net_profit": 2880.0,
    "win_rate": 0.4,
    "profit_factor": 1.2753609331676068,
    "expectancy": 576.0,
    "average_win": 6669.5,
    "average_loss": -3486.3333333333335
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 5,
    "net_profit": 5197.0,
    "win_rate": 0.4,
    "profit_factor": 1.4742653768935938,
    "expectancy": 1039.4,
    "average_win": 8077.5,
    "average_loss": -3652.6666666666665
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 11,
    "net_profit": -12034.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.5763421932758317,
    "expectancy": -1094.0,
    "average_win": 8185.5,
    "average_loss": -3156.1111111111113
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 8,
    "net_profit": -14966.0,
    "win_rate": 0.125,
    "profit_factor": 0.07147288745501923,
    "expectancy": -1870.75,
    "average_win": 1152.0,
    "average_loss": -2302.5714285714284
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": -3769.0,
    "win_rate": 0.4,
    "profit_factor": 0.39131136950904394,
    "expectancy": -753.8,
    "average_win": 1211.5,
    "average_loss": -2064.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0185-1.015",
    "number_of_trades": 11,
    "net_profit": 49349.0,
    "win_rate": 0.8181818181818182,
    "profit_factor": 543.2967032967033,
    "expectancy": 4486.272727272727,
    "average_win": 5493.333333333333,
    "average_loss": -45.5
  },
  {
    "giveback_band": "GIVEBACK_1.015-3.067",
    "number_of_trades": 9,
    "net_profit": -27305.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3033.8888888888887,
    "average_win": null,
    "average_loss": -3033.8888888888887
  },
  {
    "giveback_band": "GIVEBACK_3.067-12.71",
    "number_of_trades": 11,
    "net_profit": -34620.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3147.2727272727275,
    "average_win": null,
    "average_loss": -3147.2727272727275
  }
]
```

## time_stop_reason_code別

```json
[
  {
    "time_stop_reason_code": "MAX_HOLDING_BARS_MIN_MFE_NOT_REACHED",
    "number_of_trades": 1,
    "net_profit": 1152.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 1152.0,
    "average_win": 1152.0,
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
