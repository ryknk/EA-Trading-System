# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 19
- MFEデータのある負けトレード数: 19
- うち一度含み益になった数: 17
- 割合: 89.47%
- 反転前の平均含み益: 2778.71

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 22
- 平均Giveback比率: 1083.92%
- 中央値Giveback比率: 194.54%
- 損益ゼロ以下まで完全反転した割合: 81.82%

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

- 決済件数: 15
- 純損益: -55109.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3673.93
- 平均逆行幅（R）: 0.7584
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 7,
    "net_profit": -25903.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3700.4285714285716,
    "average_win": null,
    "average_loss": -3700.4285714285716
  },
  "SELL": {
    "number_of_trades": 8,
    "net_profit": -29206.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3650.75,
    "average_win": null,
    "average_loss": -3650.75
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6193
- 最終Entry候補まで到達: 40
- Stage別棄却数（market_regime）: 5215
- Stage別棄却数（htf_bias）: 168
- Stage別棄却数（trend_strength_or_momentum_filter）: 463
- Stage別棄却数（setup_or_trigger）: 307
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5215,
  "ENTRY_PATTERN_NOT_FOUND": 307,
  "RSI_FILTERED": 434,
  "CONFIRMATION_ADX_TOO_LOW": 29,
  "TREND_NOT_ALIGNED": 168
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 8,
    "net_profit": -16443.0,
    "win_rate": 0.125,
    "profit_factor": 0.36520866308921746,
    "expectancy": -2055.375,
    "average_win": 9460.0,
    "average_loss": -3700.4285714285716
  },
  {
    "direction": "SELL",
    "number_of_trades": 16,
    "net_profit": -1030.0,
    "win_rate": 0.1875,
    "profit_factor": 0.9657089589506276,
    "expectancy": -64.375,
    "average_win": 9669.0,
    "average_loss": -2503.0833333333335
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 7,
    "net_profit": -22649.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3235.5714285714284,
    "average_win": null,
    "average_loss": -3235.5714285714284
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 3,
    "net_profit": 5824.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.601760176017602,
    "expectancy": 1941.3333333333333,
    "average_win": 9460.0,
    "average_loss": -3636.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 8,
    "net_profit": -18505.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2313.125,
    "average_win": null,
    "average_loss": -2313.125
  },
  {
    "session": "Tokyo",
    "number_of_trades": 6,
    "net_profit": 17857.0,
    "win_rate": 0.5,
    "profit_factor": 2.60152466367713,
    "expectancy": 2976.1666666666665,
    "average_win": 9669.0,
    "average_loss": -3716.6666666666665
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 5,
    "net_profit": -1212.0,
    "win_rate": 0.2,
    "profit_factor": 0.8886438809261301,
    "expectancy": -242.4,
    "average_win": 9672.0,
    "average_loss": -3628.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 6,
    "net_profit": -21885.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3647.5,
    "average_win": null,
    "average_loss": -3647.5
  },
  {
    "weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": 1826.0,
    "win_rate": 0.25,
    "profit_factor": 1.239193083573487,
    "expectancy": 456.5,
    "average_win": 9460.0,
    "average_loss": -2544.6666666666665
  },
  {
    "weekday": "Tue",
    "number_of_trades": 5,
    "net_profit": -1534.0,
    "win_rate": 0.2,
    "profit_factor": 0.8657330415754924,
    "expectancy": -306.8,
    "average_win": 9891.0,
    "average_loss": -2856.25
  },
  {
    "weekday": "Wed",
    "number_of_trades": 4,
    "net_profit": 5332.0,
    "win_rate": 0.25,
    "profit_factor": 2.296692607003891,
    "expectancy": 1333.0,
    "average_win": 9444.0,
    "average_loss": -1370.6666666666667
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.108-0.149",
    "number_of_trades": 8,
    "net_profit": 3979.0,
    "win_rate": 0.25,
    "profit_factor": 1.258847254748894,
    "expectancy": 497.375,
    "average_win": 9675.5,
    "average_loss": -3074.4
  },
  {
    "atr_band": "ATR_0.149-0.198",
    "number_of_trades": 8,
    "net_profit": -12777.0,
    "win_rate": 0.125,
    "profit_factor": 0.4250033751856352,
    "expectancy": -1597.125,
    "average_win": 9444.0,
    "average_loss": -3174.4285714285716
  },
  {
    "atr_band": "ATR_0.198-0.287",
    "number_of_trades": 8,
    "net_profit": -8675.0,
    "win_rate": 0.125,
    "profit_factor": 0.5271706546029323,
    "expectancy": -1084.375,
    "average_win": 9672.0,
    "average_loss": -2621.0
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.44-42.65",
    "number_of_trades": 8,
    "net_profit": 3903.0,
    "win_rate": 0.25,
    "profit_factor": 1.2565568921317294,
    "expectancy": 487.875,
    "average_win": 9558.0,
    "average_loss": -2535.5
  },
  {
    "adx_band": "ADX_42.65-49.78",
    "number_of_trades": 8,
    "net_profit": -22141.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2767.625,
    "average_win": null,
    "average_loss": -3163.0
  },
  {
    "adx_band": "ADX_49.78-61.87",
    "number_of_trades": 8,
    "net_profit": 765.0,
    "win_rate": 0.25,
    "profit_factor": 1.0411600129129452,
    "expectancy": 95.625,
    "average_win": 9675.5,
    "average_loss": -3097.6666666666665
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.353-2.761",
    "number_of_trades": 8,
    "net_profit": -12476.0,
    "win_rate": 0.125,
    "profit_factor": 0.4312545587162655,
    "expectancy": -1559.5,
    "average_win": 9460.0,
    "average_loss": -3656.0
  },
  {
    "hold_time_band": "HOLD_H_2.761-7.915",
    "number_of_trades": 8,
    "net_profit": -2738.0,
    "win_rate": 0.25,
    "profit_factor": 0.875957051601504,
    "expectancy": -342.25,
    "average_win": 9667.5,
    "average_loss": -3678.8333333333335
  },
  {
    "hold_time_band": "HOLD_H_7.915-64.16",
    "number_of_trades": 8,
    "net_profit": -2259.0,
    "win_rate": 0.125,
    "profit_factor": 0.8106613024893136,
    "expectancy": -282.375,
    "average_win": 9672.0,
    "average_loss": -1704.4285714285713
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-48-1034",
    "number_of_trades": 8,
    "net_profit": -29503.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3687.875,
    "average_win": null,
    "average_loss": -3687.875
  },
  {
    "mfe_band": "MFE_1034-5312",
    "number_of_trades": 8,
    "net_profit": -25606.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3200.75,
    "average_win": null,
    "average_loss": -3658.0
  },
  {
    "mfe_band": "MFE_5312-9870",
    "number_of_trades": 8,
    "net_profit": 37636.0,
    "win_rate": 0.5,
    "profit_factor": 46.290012033694346,
    "expectancy": 4704.5,
    "average_win": 9616.75,
    "average_loss": -207.75
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2625--156",
    "number_of_trades": 8,
    "net_profit": 38053.0,
    "win_rate": 0.5,
    "profit_factor": 92.91545893719807,
    "expectancy": 4756.625,
    "average_win": 9616.75,
    "average_loss": -138.0
  },
  {
    "mae_band": "MAE_-3717--2625",
    "number_of_trades": 8,
    "net_profit": -25572.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3196.5,
    "average_win": null,
    "average_loss": -3196.5
  },
  {
    "mae_band": "MAE_-3888--3717",
    "number_of_trades": 8,
    "net_profit": -29954.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3744.25,
    "average_win": null,
    "average_loss": -3744.25
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 13,
    "net_profit": 6719.0,
    "win_rate": 0.23076923076923078,
    "profit_factor": 1.3014626704953338,
    "expectancy": 516.8461538461538,
    "average_win": 9669.0,
    "average_loss": -2476.4444444444443
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 11,
    "net_profit": -24192.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.28111256388921907,
    "expectancy": -2199.2727272727275,
    "average_win": 9460.0,
    "average_loss": -3365.2
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 1,
    "net_profit": -3732.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3732.0,
    "average_win": null,
    "average_loss": -3732.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 23,
    "net_profit": -13741.0,
    "win_rate": 0.17391304347826086,
    "profit_factor": 0.7368027888446215,
    "expectancy": -597.4347826086956,
    "average_win": 9616.75,
    "average_loss": -2900.4444444444443
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 15,
    "net_profit": -55109.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3673.9333333333334,
    "average_win": null,
    "average_loss": -3673.9333333333334
  },
  {
    "close_reason": "SL",
    "number_of_trades": 5,
    "net_profit": -831.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -166.2,
    "average_win": null,
    "average_loss": -207.75
  },
  {
    "close_reason": "TP",
    "number_of_trades": 4,
    "net_profit": 38467.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9616.75,
    "average_win": 9616.75,
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
    "net_profit": 206.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 1.0107689894923937,
    "expectancy": 22.88888888888889,
    "average_win": 9667.5,
    "average_loss": -2732.714285714286
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 5,
    "net_profit": 1790.0,
    "win_rate": 0.2,
    "profit_factor": 1.2333767926988266,
    "expectancy": 358.0,
    "average_win": 9460.0,
    "average_loss": -2556.6666666666665
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 5,
    "net_profit": -4723.0,
    "win_rate": 0.2,
    "profit_factor": 0.6718999652657173,
    "expectancy": -944.6,
    "average_win": 9672.0,
    "average_loss": -3598.75
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 5,
    "net_profit": -14746.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2949.2,
    "average_win": null,
    "average_loss": -2949.2
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 6,
    "net_profit": -1380.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.8751357220412594,
    "expectancy": -230.0,
    "average_win": 9672.0,
    "average_loss": -2763.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": -25543.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3649.0,
    "average_win": null,
    "average_loss": -3649.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": 5125.0,
    "win_rate": 0.25,
    "profit_factor": 2.182237600922722,
    "expectancy": 1281.25,
    "average_win": 9460.0,
    "average_loss": -1445.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": -1376.0,
    "win_rate": 0.25,
    "profit_factor": 0.8778734356971687,
    "expectancy": -344.0,
    "average_win": 9891.0,
    "average_loss": -3755.6666666666665
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 3,
    "net_profit": 5701.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.523109804969276,
    "expectancy": 1900.3333333333333,
    "average_win": 9444.0,
    "average_loss": -1871.5
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00724-1.024",
    "number_of_trades": 8,
    "net_profit": 38053.0,
    "win_rate": 0.5,
    "profit_factor": 92.91545893719807,
    "expectancy": 4756.625,
    "average_win": 9616.75,
    "average_loss": -138.0
  },
  {
    "giveback_band": "GIVEBACK_1.024-3.516",
    "number_of_trades": 6,
    "net_profit": -18802.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3133.6666666666665,
    "average_win": null,
    "average_loss": -3133.6666666666665
  },
  {
    "giveback_band": "GIVEBACK_3.516-156.5",
    "number_of_trades": 8,
    "net_profit": -29452.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3681.5,
    "average_win": null,
    "average_loss": -3681.5
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
