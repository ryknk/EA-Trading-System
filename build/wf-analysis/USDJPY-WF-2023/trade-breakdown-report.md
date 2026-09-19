# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 13
- MFEデータのある負けトレード数: 13
- うち一度含み益になった数: 12
- 割合: 92.31%
- 反転前の平均含み益: 3014.83

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 20
- 平均Giveback比率: 221.21%
- 中央値Giveback比率: 104.38%
- 損益ゼロ以下まで完全反転した割合: 65.00%

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

- 決済件数: 9
- 純損益: -33733.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3748.11
- 平均逆行幅（R）: 0.7954
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 5,
    "net_profit": -19360.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3872.0,
    "average_win": null,
    "average_loss": -3872.0
  },
  "SELL": {
    "number_of_trades": 4,
    "net_profit": -14373.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3593.25,
    "average_win": null,
    "average_loss": -3593.25
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6329
- 最終Entry候補まで到達: 38
- Stage別棄却数（market_regime）: 5359
- Stage別棄却数（htf_bias）: 142
- Stage別棄却数（trend_strength_or_momentum_filter）: 482
- Stage別棄却数（setup_or_trigger）: 308
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5359,
  "RSI_FILTERED": 444,
  "ENTRY_PATTERN_NOT_FOUND": 308,
  "CONFIRMATION_ADX_TOO_LOW": 38,
  "TREND_NOT_ALIGNED": 142
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 15,
    "net_profit": 22494.0,
    "win_rate": 0.4,
    "profit_factor": 1.8935764509593611,
    "expectancy": 1499.6,
    "average_win": 7944.5,
    "average_loss": -3146.625
  },
  {
    "direction": "SELL",
    "number_of_trades": 6,
    "net_profit": -13713.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.05251157327437297,
    "expectancy": -2285.5,
    "average_win": 760.0,
    "average_loss": -2894.6
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 1,
    "net_profit": -3597.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3597.0,
    "average_win": null,
    "average_loss": -3597.0
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 4,
    "net_profit": 5857.0,
    "win_rate": 0.5,
    "profit_factor": 2.4960408684546618,
    "expectancy": 1464.25,
    "average_win": 4886.0,
    "average_loss": -3915.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 7,
    "net_profit": -5432.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.6505628819556127,
    "expectancy": -776.0,
    "average_win": 5056.5,
    "average_loss": -3109.0
  },
  {
    "session": "Tokyo",
    "number_of_trades": 9,
    "net_profit": 11953.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.720537705708602,
    "expectancy": 1328.111111111111,
    "average_win": 9514.0,
    "average_loss": -2764.8333333333335
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 2,
    "net_profit": -100.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -50.0,
    "average_win": null,
    "average_loss": -100.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": 14985.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.102567875800162,
    "expectancy": 2140.714285714286,
    "average_win": 9525.333333333334,
    "average_loss": -3397.75
  },
  {
    "weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": -10213.0,
    "win_rate": 0.25,
    "profit_factor": 0.06926091315046022,
    "expectancy": -2553.25,
    "average_win": 760.0,
    "average_loss": -3657.6666666666665
  },
  {
    "weekday": "Tue",
    "number_of_trades": 6,
    "net_profit": -5490.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.6335602723267921,
    "expectancy": -915.0,
    "average_win": 9492.0,
    "average_loss": -2996.4
  },
  {
    "weekday": "Wed",
    "number_of_trades": 2,
    "net_profit": 9599.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 4799.5,
    "average_win": 4799.5,
    "average_loss": null
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.0602-0.147",
    "number_of_trades": 7,
    "net_profit": 33076.0,
    "win_rate": 0.7142857142857143,
    "profit_factor": 7.695546558704454,
    "expectancy": 4725.142857142857,
    "average_win": 7603.2,
    "average_loss": -4940.0
  },
  {
    "atr_band": "ATR_0.147-0.219",
    "number_of_trades": 7,
    "net_profit": -18481.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2640.1428571428573,
    "average_win": null,
    "average_loss": -2640.1428571428573
  },
  {
    "atr_band": "ATR_0.219-0.566",
    "number_of_trades": 7,
    "net_profit": -5814.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.6416640986132511,
    "expectancy": -830.5714285714286,
    "average_win": 5205.5,
    "average_loss": -3245.0
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.11-41.65",
    "number_of_trades": 7,
    "net_profit": -3539.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.7264646776936157,
    "expectancy": -505.57142857142856,
    "average_win": 9399.0,
    "average_loss": -2156.3333333333335
  },
  {
    "adx_band": "ADX_41.65-43.54",
    "number_of_trades": 7,
    "net_profit": 8467.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.7944267217113905,
    "expectancy": 1209.5714285714287,
    "average_win": 6375.0,
    "average_loss": -3552.6666666666665
  },
  {
    "adx_band": "ADX_43.54-56.37",
    "number_of_trades": 7,
    "net_profit": 3853.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.24006230529595,
    "expectancy": 550.4285714285714,
    "average_win": 6634.333333333333,
    "average_loss": -4012.5
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.0234-7.163",
    "number_of_trades": 7,
    "net_profit": -9974.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.4851597584266763,
    "expectancy": -1424.857142857143,
    "average_win": 9399.0,
    "average_loss": -3874.6
  },
  {
    "hold_time_band": "HOLD_H_15.49-109",
    "number_of_trades": 7,
    "net_profit": 15619.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 4.422217353198948,
    "expectancy": 2231.285714285714,
    "average_win": 5045.75,
    "average_loss": -1521.3333333333333
  },
  {
    "hold_time_band": "HOLD_H_7.163-15.49",
    "number_of_trades": 7,
    "net_profit": 3136.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.1996307849003756,
    "expectancy": 448.0,
    "average_win": 9422.5,
    "average_loss": -3141.8
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-78-2647",
    "number_of_trades": 7,
    "net_profit": -28108.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4015.4285714285716,
    "average_win": null,
    "average_loss": -4015.4285714285716
  },
  {
    "mfe_band": "MFE_2647-7914",
    "number_of_trades": 7,
    "net_profit": -10029.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.08736008736008737,
    "expectancy": -1432.7142857142858,
    "average_win": 480.0,
    "average_loss": -2197.8
  },
  {
    "mfe_band": "MFE_7914-9484",
    "number_of_trades": 7,
    "net_profit": 46918.0,
    "win_rate": 0.7142857142857143,
    "profit_factor": 86.4608378870674,
    "expectancy": 6702.571428571428,
    "average_win": 9493.4,
    "average_loss": -549.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1773--147",
    "number_of_trades": 7,
    "net_profit": 38760.0,
    "win_rate": 0.7142857142857143,
    "profit_factor": 341.0,
    "expectancy": 5537.142857142857,
    "average_win": 7774.8,
    "average_loss": -57.0
  },
  {
    "mae_band": "MAE_-3525--1773",
    "number_of_trades": 7,
    "net_profit": -6771.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.5800669808980402,
    "expectancy": -967.2857142857143,
    "average_win": 9353.0,
    "average_loss": -3224.8
  },
  {
    "mae_band": "MAE_-4940--3525",
    "number_of_trades": 7,
    "net_profit": -23208.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.008544087491455913,
    "expectancy": -3315.4285714285716,
    "average_win": 200.0,
    "average_loss": -3901.3333333333335
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 2,
    "net_profit": -2780.0,
    "win_rate": 0.5,
    "profit_factor": 0.21468926553672316,
    "expectancy": -1390.0,
    "average_win": 760.0,
    "average_loss": -3540.0
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 19,
    "net_profit": 11561.0,
    "win_rate": 0.3157894736842105,
    "profit_factor": 1.3201960892926383,
    "expectancy": 608.4736842105264,
    "average_win": 7944.5,
    "average_loss": -3008.8333333333335
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 3,
    "net_profit": -2880.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.2087912087912088,
    "expectancy": -960.0,
    "average_win": 760.0,
    "average_loss": -1820.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 5,
    "net_profit": 23959.0,
    "win_rate": 0.6,
    "profit_factor": 6.488888888888889,
    "expectancy": 4791.8,
    "average_win": 9441.333333333334,
    "average_loss": -2182.5
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 13,
    "net_profit": -12298.0,
    "win_rate": 0.23076923076923078,
    "profit_factor": 0.6113270756297209,
    "expectancy": -946.0,
    "average_win": 6447.666666666667,
    "average_loss": -3515.6666666666665
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 10,
    "net_profit": -32973.0,
    "win_rate": 0.1,
    "profit_factor": 0.022529866895917943,
    "expectancy": -3297.3,
    "average_win": 760.0,
    "average_loss": -3748.1111111111113
  },
  {
    "close_reason": "SL",
    "number_of_trades": 6,
    "net_profit": -5713.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.03382377811601556,
    "expectancy": -952.1666666666666,
    "average_win": 200.0,
    "average_loss": -1478.25
  },
  {
    "close_reason": "TP",
    "number_of_trades": 5,
    "net_profit": 47467.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9493.4,
    "average_win": 9493.4,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 10,
    "net_profit": 1305.0,
    "win_rate": 0.3,
    "profit_factor": 1.0710010881392817,
    "expectancy": 130.5,
    "average_win": 6561.666666666667,
    "average_loss": -2625.714285714286
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 3,
    "net_profit": 6152.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 2.7378531073446326,
    "expectancy": 2050.6666666666665,
    "average_win": 4846.0,
    "average_loss": -3540.0
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 4,
    "net_profit": -13790.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3447.5,
    "average_win": null,
    "average_loss": -4596.666666666667
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 4,
    "net_profit": 15114.0,
    "win_rate": 0.5,
    "profit_factor": 4.839939024390244,
    "expectancy": 3778.5,
    "average_win": 9525.0,
    "average_loss": -1968.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": -7433.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2477.6666666666665,
    "average_win": null,
    "average_loss": -3716.5
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 4,
    "net_profit": -10304.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2576.0,
    "average_win": null,
    "average_loss": -2576.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 2,
    "net_profit": -3340.0,
    "win_rate": 0.5,
    "profit_factor": 0.05649717514124294,
    "expectancy": -1670.0,
    "average_win": 200.0,
    "average_loss": -3540.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 10,
    "net_profit": 21008.0,
    "win_rate": 0.5,
    "profit_factor": 2.1789001122334457,
    "expectancy": 2100.8,
    "average_win": 7765.6,
    "average_loss": -3564.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 2,
    "net_profit": 8850.0,
    "win_rate": 0.5,
    "profit_factor": 17.120218579234972,
    "expectancy": 4425.0,
    "average_win": 9399.0,
    "average_loss": -549.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0211-0.98",
    "number_of_trades": 7,
    "net_profit": 48427.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 6918.142857142857,
    "average_win": 6918.142857142857,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.98-2.232",
    "number_of_trades": 6,
    "net_profit": -7998.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1333.0,
    "average_win": null,
    "average_loss": -1599.6
  },
  {
    "giveback_band": "GIVEBACK_2.232-9.824",
    "number_of_trades": 7,
    "net_profit": -26708.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3815.4285714285716,
    "average_win": null,
    "average_loss": -3815.4285714285716
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
