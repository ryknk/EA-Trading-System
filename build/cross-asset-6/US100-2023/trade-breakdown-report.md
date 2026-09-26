# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 23
- MFEデータのある負けトレード数: 23
- うち一度含み益になった数: 22
- 割合: 95.65%
- 反転前の平均含み益: 2318.95

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 31
- 平均Giveback比率: 949.95%
- 中央値Giveback比率: 237.63%
- 損益ゼロ以下まで完全反転した割合: 74.19%

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

- 決済件数: 18
- 純損益: -63639.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3535.50
- 平均逆行幅（R）: 0.7791
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 18,
    "net_profit": -63639.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3535.5,
    "average_win": null,
    "average_loss": -3535.5
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 5892
- 最終Entry候補まで到達: 46
- Stage別棄却数（market_regime）: 4643
- Stage別棄却数（htf_bias）: 358
- Stage別棄却数（trend_strength_or_momentum_filter）: 495
- Stage別棄却数（setup_or_trigger）: 350
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 4643,
  "RSI_FILTERED": 458,
  "CONFIRMATION_ADX_TOO_LOW": 37,
  "ENTRY_PATTERN_NOT_FOUND": 350,
  "TREND_NOT_ALIGNED": 358
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 32,
    "net_profit": -646.0,
    "win_rate": 0.25,
    "profit_factor": 0.9902760634614806,
    "expectancy": -20.1875,
    "average_win": 8223.5,
    "average_loss": -2888.4347826086955
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 6,
    "net_profit": 1764.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 1.2403924775143091,
    "expectancy": 294.0,
    "average_win": 9102.0,
    "average_loss": -1467.6
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 6,
    "net_profit": -7293.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.5058943089430894,
    "expectancy": -1215.5,
    "average_win": 7467.0,
    "average_loss": -3690.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 11,
    "net_profit": -7765.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.7143330144948863,
    "expectancy": -705.9090909090909,
    "average_win": 9708.5,
    "average_loss": -3020.222222222222
  },
  {
    "session": "Tokyo",
    "number_of_trades": 9,
    "net_profit": 12648.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 1.7373207415180132,
    "expectancy": 1405.3333333333333,
    "average_win": 7450.5,
    "average_loss": -3430.8
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 2,
    "net_profit": 4007.0,
    "win_rate": 0.5,
    "profit_factor": 2.158092485549133,
    "expectancy": 2003.5,
    "average_win": 7467.0,
    "average_loss": -3460.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 8,
    "net_profit": -10472.0,
    "win_rate": 0.125,
    "profit_factor": 0.4804524707283191,
    "expectancy": -1309.0,
    "average_win": 9684.0,
    "average_loss": -2879.4285714285716
  },
  {
    "weekday": "Thu",
    "number_of_trades": 9,
    "net_profit": -2684.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.8508640328943713,
    "expectancy": -298.22222222222223,
    "average_win": 7656.5,
    "average_loss": -2571.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 6,
    "net_profit": 1267.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.087258953168044,
    "expectancy": 211.16666666666666,
    "average_win": 7893.5,
    "average_loss": -3630.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 7,
    "net_profit": 7236.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.7024560722259974,
    "expectancy": 1033.7142857142858,
    "average_win": 8768.5,
    "average_loss": -2575.25
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_17.11-29.99",
    "number_of_trades": 11,
    "net_profit": -16645.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.3535169145919913,
    "expectancy": -1513.1818181818182,
    "average_win": 9102.0,
    "average_loss": -2860.777777777778
  },
  {
    "atr_band": "ATR_29.99-38.98",
    "number_of_trades": 10,
    "net_profit": 3428.0,
    "win_rate": 0.3,
    "profit_factor": 1.14285118973205,
    "expectancy": 342.8,
    "average_win": 9141.666666666666,
    "average_loss": -3428.1428571428573
  },
  {
    "atr_band": "ATR_38.98-59.69",
    "number_of_trades": 11,
    "net_profit": 12571.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 1.753205512282804,
    "expectancy": 1142.8181818181818,
    "average_win": 7315.25,
    "average_loss": -2384.285714285714
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.33-43.33",
    "number_of_trades": 11,
    "net_profit": 14483.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 1.817740387329908,
    "expectancy": 1316.6363636363637,
    "average_win": 8048.5,
    "average_loss": -2530.1428571428573
  },
  {
    "adx_band": "ADX_43.33-49.09",
    "number_of_trades": 10,
    "net_profit": -20527.0,
    "win_rate": 0.1,
    "profit_factor": 0.26673572908480386,
    "expectancy": -2052.7,
    "average_win": 7467.0,
    "average_loss": -3110.4444444444443
  },
  {
    "adx_band": "ADX_49.09-62.76",
    "number_of_trades": 11,
    "net_profit": 5398.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 1.2604081238844131,
    "expectancy": 490.72727272727275,
    "average_win": 8709.0,
    "average_loss": -2961.285714285714
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.147-1.734",
    "number_of_trades": 11,
    "net_profit": -35476.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3225.090909090909,
    "average_win": null,
    "average_loss": -3225.090909090909
  },
  {
    "hold_time_band": "HOLD_H_1.734-10.38",
    "number_of_trades": 10,
    "net_profit": -3987.0,
    "win_rate": 0.2,
    "profit_factor": 0.8118185679898051,
    "expectancy": -398.7,
    "average_win": 8600.0,
    "average_loss": -3026.714285714286
  },
  {
    "hold_time_band": "HOLD_H_10.38-134",
    "number_of_trades": 11,
    "net_profit": 38817.0,
    "win_rate": 0.5454545454545454,
    "profit_factor": 4.97267424009825,
    "expectancy": 3528.818181818182,
    "average_win": 8098.0,
    "average_loss": -1954.2
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-203-1477",
    "number_of_trades": 11,
    "net_profit": -38569.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3506.2727272727275,
    "average_win": null,
    "average_loss": -3506.2727272727275
  },
  {
    "mfe_band": "MFE_1477-6506",
    "number_of_trades": 10,
    "net_profit": -27823.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2782.3,
    "average_win": null,
    "average_loss": -2782.3
  },
  {
    "mfe_band": "MFE_6506-9709",
    "number_of_trades": 11,
    "net_profit": 65746.0,
    "win_rate": 0.7272727272727273,
    "profit_factor": 1566.3809523809523,
    "expectancy": 5976.909090909091,
    "average_win": 8223.5,
    "average_loss": -21.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2591--245",
    "number_of_trades": 11,
    "net_profit": 56047.0,
    "win_rate": 0.6363636363636364,
    "profit_factor": 984.280701754386,
    "expectancy": 5095.181818181818,
    "average_win": 8014.857142857143,
    "average_loss": -19.0
  },
  {
    "mae_band": "MAE_-3487--2591",
    "number_of_trades": 10,
    "net_profit": -16289.0,
    "win_rate": 0.1,
    "profit_factor": 0.37284872752473724,
    "expectancy": -1628.9,
    "average_win": 9684.0,
    "average_loss": -2885.8888888888887
  },
  {
    "mae_band": "MAE_-4016--3487",
    "number_of_trades": 11,
    "net_profit": -40404.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3673.090909090909,
    "average_win": null,
    "average_loss": -3673.090909090909
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 11,
    "net_profit": -14731.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.46968824249406005,
    "expectancy": -1339.1818181818182,
    "average_win": 6523.5,
    "average_loss": -3086.4444444444443
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 21,
    "net_profit": 14085.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.3643677566225165,
    "expectancy": 670.7142857142857,
    "average_win": 8790.166666666666,
    "average_loss": -2761.1428571428573
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 3,
    "net_profit": 5538.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 132.85714285714286,
    "expectancy": 1846.0,
    "average_win": 5580.0,
    "average_loss": -21.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 6,
    "net_profit": -5042.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.6435237556561086,
    "expectancy": -840.3333333333334,
    "average_win": 9102.0,
    "average_loss": -2828.8
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 23,
    "net_profit": -1142.0,
    "win_rate": 0.2608695652173913,
    "profit_factor": 0.9781427040269484,
    "expectancy": -49.65217391304348,
    "average_win": 8517.666666666666,
    "average_loss": -3265.5
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 20,
    "net_profit": -60691.0,
    "win_rate": 0.05,
    "profit_factor": 0.08419972537007138,
    "expectancy": -3034.55,
    "average_win": 5580.0,
    "average_loss": -3487.9473684210525
  },
  {
    "close_reason": "SL",
    "number_of_trades": 5,
    "net_profit": -163.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -32.6,
    "average_win": null,
    "average_loss": -40.75
  },
  {
    "close_reason": "TP",
    "number_of_trades": 7,
    "net_profit": 60208.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8601.142857142857,
    "average_win": 8601.142857142857,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 1,
    "net_profit": -3472.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3472.0,
    "average_win": null,
    "average_loss": -3472.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 13,
    "net_profit": -16486.0,
    "win_rate": 0.15384615384615385,
    "profit_factor": 0.480755905511811,
    "expectancy": -1268.1538461538462,
    "average_win": 7632.0,
    "average_loss": -3175.0
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 13,
    "net_profit": 36607.0,
    "win_rate": 0.46153846153846156,
    "profit_factor": 3.630380110656032,
    "expectancy": 2815.923076923077,
    "average_win": 8420.666666666666,
    "average_loss": -1988.142857142857
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 5,
    "net_profit": -17295.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3459.0,
    "average_win": null,
    "average_loss": -3459.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": 382.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.0539167254763584,
    "expectancy": 127.33333333333333,
    "average_win": 7467.0,
    "average_loss": -3542.5
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 6,
    "net_profit": -17524.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2920.6666666666665,
    "average_win": null,
    "average_loss": -2920.6666666666665
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 9,
    "net_profit": 407.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 1.0229153763864647,
    "expectancy": 45.22222222222222,
    "average_win": 9084.0,
    "average_loss": -2537.285714285714
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 5,
    "net_profit": -3996.0,
    "win_rate": 0.2,
    "profit_factor": 0.7078947368421052,
    "expectancy": -799.2,
    "average_win": 9684.0,
    "average_loss": -3420.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 9,
    "net_profit": 20085.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 2.9342257318952236,
    "expectancy": 2231.6666666666665,
    "average_win": 7617.25,
    "average_loss": -2596.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0489-1.003",
    "number_of_trades": 11,
    "net_profit": 65769.0,
    "win_rate": 0.7272727272727273,
    "profit_factor": 3462.5263157894738,
    "expectancy": 5979.0,
    "average_win": 8223.5,
    "average_loss": -9.5
  },
  {
    "giveback_band": "GIVEBACK_1.003-3.388",
    "number_of_trades": 9,
    "net_profit": -24000.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2666.6666666666665,
    "average_win": null,
    "average_loss": -2666.6666666666665
  },
  {
    "giveback_band": "GIVEBACK_3.388-206.5",
    "number_of_trades": 11,
    "net_profit": -38700.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3518.181818181818,
    "average_win": null,
    "average_loss": -3518.181818181818
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
