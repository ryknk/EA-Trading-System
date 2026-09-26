# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 20
- MFEデータのある負けトレード数: 20
- うち一度含み益になった数: 18
- 割合: 90.00%
- 反転前の平均含み益: 2498.00

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 30
- 平均Giveback比率: 1654.55%
- 中央値Giveback比率: 143.40%
- 損益ゼロ以下まで完全反転した割合: 70.00%

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

- 決済件数: 17
- 純損益: -54422.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3201.29
- 平均逆行幅（R）: 0.7727
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 17,
    "net_profit": -54422.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3201.294117647059,
    "average_win": null,
    "average_loss": -3201.294117647059
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 5915
- 最終Entry候補まで到達: 63
- Stage別棄却数（market_regime）: 4690
- Stage別棄却数（htf_bias）: 210
- Stage別棄却数（trend_strength_or_momentum_filter）: 494
- Stage別棄却数（setup_or_trigger）: 458
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 4690,
  "CONFIRMATION_ADX_TOO_LOW": 47,
  "RSI_FILTERED": 447,
  "ENTRY_PATTERN_NOT_FOUND": 458,
  "TREND_NOT_ALIGNED": 210
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 32,
    "net_profit": -1576.0,
    "win_rate": 0.28125,
    "profit_factor": 0.9711809238196247,
    "expectancy": -49.25,
    "average_win": 5901.111111111111,
    "average_loss": -2734.3
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 7,
    "net_profit": -17298.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2471.1428571428573,
    "average_win": null,
    "average_loss": -2471.1428571428573
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 6,
    "net_profit": -2064.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.8106074509084236,
    "expectancy": -344.0,
    "average_win": 8834.0,
    "average_loss": -2724.5
  },
  {
    "session": "NewYork",
    "number_of_trades": 10,
    "net_profit": 23762.0,
    "win_rate": 0.5,
    "profit_factor": 3.0295524427741714,
    "expectancy": 2376.2,
    "average_win": 7094.0,
    "average_loss": -2927.0
  },
  {
    "session": "Tokyo",
    "number_of_trades": 9,
    "net_profit": -5976.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.5957245298335814,
    "expectancy": -664.0,
    "average_win": 2935.3333333333335,
    "average_loss": -2956.4
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 7,
    "net_profit": 12645.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 4.936799501867995,
    "expectancy": 1806.4285714285713,
    "average_win": 5285.666666666667,
    "average_loss": -1606.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 1,
    "net_profit": -3163.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3163.0,
    "average_win": null,
    "average_loss": -3163.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 6,
    "net_profit": -18184.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3030.6666666666665,
    "average_win": null,
    "average_loss": -3030.6666666666665
  },
  {
    "weekday": "Tue",
    "number_of_trades": 8,
    "net_profit": 9821.0,
    "win_rate": 0.375,
    "profit_factor": 1.952662721893491,
    "expectancy": 1227.625,
    "average_win": 6710.0,
    "average_loss": -2061.8
  },
  {
    "weekday": "Wed",
    "number_of_trades": 10,
    "net_profit": -2695.0,
    "win_rate": 0.3,
    "profit_factor": 0.8640125138762741,
    "expectancy": -269.5,
    "average_win": 5707.666666666667,
    "average_loss": -3303.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_3.437-5.036",
    "number_of_trades": 11,
    "net_profit": -14321.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.3815158713020946,
    "expectancy": -1301.909090909091,
    "average_win": 8834.0,
    "average_loss": -2894.375
  },
  {
    "atr_band": "ATR_5.036-6.55",
    "number_of_trades": 10,
    "net_profit": 12036.0,
    "win_rate": 0.4,
    "profit_factor": 1.8327106683271066,
    "expectancy": 1203.6,
    "average_win": 6622.5,
    "average_loss": -2409.0
  },
  {
    "atr_band": "ATR_6.55-9.211",
    "number_of_trades": 11,
    "net_profit": 709.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 1.0415178310007613,
    "expectancy": 64.45454545454545,
    "average_win": 4446.5,
    "average_loss": -2846.1666666666665
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.82-43.09",
    "number_of_trades": 11,
    "net_profit": -1665.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.9283778552071235,
    "expectancy": -151.36363636363637,
    "average_win": 7194.0,
    "average_loss": -3321.0
  },
  {
    "adx_band": "ADX_43.09-47.17",
    "number_of_trades": 10,
    "net_profit": -586.0,
    "win_rate": 0.2,
    "profit_factor": 0.9512398069562323,
    "expectancy": -58.6,
    "average_win": 5716.0,
    "average_loss": -1716.857142857143
  },
  {
    "adx_band": "ADX_47.17-55.87",
    "number_of_trades": 11,
    "net_profit": 675.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 1.0347561917511972,
    "expectancy": 61.36363636363637,
    "average_win": 5024.0,
    "average_loss": -3236.8333333333335
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.476-3.192",
    "number_of_trades": 11,
    "net_profit": -30651.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2786.4545454545455,
    "average_win": null,
    "average_loss": -3065.1
  },
  {
    "hold_time_band": "HOLD_H_12.63-87",
    "number_of_trades": 11,
    "net_profit": -3115.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 0.7703141129626899,
    "expectancy": -283.1818181818182,
    "average_win": 2611.75,
    "average_loss": -2712.4
  },
  {
    "hold_time_band": "HOLD_H_3.192-12.63",
    "number_of_trades": 10,
    "net_profit": 32190.0,
    "win_rate": 0.5,
    "profit_factor": 4.073617874534517,
    "expectancy": 3219.0,
    "average_win": 8532.6,
    "average_loss": -2094.6
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-150-2074",
    "number_of_trades": 11,
    "net_profit": -34809.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3164.4545454545455,
    "average_win": null,
    "average_loss": -3164.4545454545455
  },
  {
    "mfe_band": "MFE_2074-4824",
    "number_of_trades": 10,
    "net_profit": -15707.0,
    "win_rate": 0.2,
    "profit_factor": 0.2012306753458096,
    "expectancy": -1570.7,
    "average_win": 1978.5,
    "average_loss": -2458.0
  },
  {
    "mfe_band": "MFE_4824-9215",
    "number_of_trades": 11,
    "net_profit": 48940.0,
    "win_rate": 0.6363636363636364,
    "profit_factor": 230.76525821596243,
    "expectancy": 4449.090909090909,
    "average_win": 7021.857142857143,
    "average_loss": -213.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2075--63",
    "number_of_trades": 11,
    "net_profit": 39603.0,
    "win_rate": 0.5454545454545454,
    "profit_factor": 18.64053452115813,
    "expectancy": 3600.2727272727275,
    "average_win": 6974.666666666667,
    "average_loss": -748.3333333333334
  },
  {
    "mae_band": "MAE_-3228--2075",
    "number_of_trades": 10,
    "net_profit": -3199.0,
    "win_rate": 0.3,
    "profit_factor": 0.7787843164373142,
    "expectancy": -319.9,
    "average_win": 3754.0,
    "average_loss": -2410.1666666666665
  },
  {
    "mae_band": "MAE_-3960--3228",
    "number_of_trades": 11,
    "net_profit": -37980.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3452.7272727272725,
    "average_win": null,
    "average_loss": -3452.7272727272725
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 7,
    "net_profit": -2068.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.8687067487778554,
    "expectancy": -295.42857142857144,
    "average_win": 6841.5,
    "average_loss": -3150.2
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 25,
    "net_profit": 492.0,
    "win_rate": 0.28,
    "profit_factor": 1.0126364453576473,
    "expectancy": 19.68,
    "average_win": 5632.428571428572,
    "average_loss": -2595.6666666666665
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 3,
    "net_profit": 11874.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 6.382592928377154,
    "expectancy": 3958.0,
    "average_win": 7040.0,
    "average_loss": -2206.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 5,
    "net_profit": 1496.0,
    "win_rate": 0.2,
    "profit_factor": 1.2038702643772146,
    "expectancy": 299.2,
    "average_win": 8834.0,
    "average_loss": -2446.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 24,
    "net_profit": -14946.0,
    "win_rate": 0.25,
    "profit_factor": 0.6689114350272474,
    "expectancy": -622.75,
    "average_win": 5032.666666666667,
    "average_loss": -2821.375
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 21,
    "net_profit": -43975.0,
    "win_rate": 0.19047619047619047,
    "profit_factor": 0.19196280915806108,
    "expectancy": -2094.0476190476193,
    "average_win": 2611.75,
    "average_loss": -3201.294117647059
  },
  {
    "close_reason": "SL",
    "number_of_trades": 6,
    "net_profit": -264.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -44.0,
    "average_win": null,
    "average_loss": -88.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 5,
    "net_profit": 42663.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8532.6,
    "average_win": 8532.6,
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
    "net_profit": -6610.0,
    "win_rate": 0.25,
    "profit_factor": 0.19888498363834686,
    "expectancy": -1652.5,
    "average_win": 1641.0,
    "average_loss": -2750.3333333333335
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 11,
    "net_profit": -21320.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.29296279100616834,
    "expectancy": -1938.1818181818182,
    "average_win": 8834.0,
    "average_loss": -3015.4
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 8,
    "net_profit": -2019.0,
    "win_rate": 0.125,
    "profit_factor": 0.7060279557367501,
    "expectancy": -252.375,
    "average_win": 4849.0,
    "average_loss": -1717.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 9,
    "net_profit": 28373.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 4.014235631573356,
    "expectancy": 3152.5555555555557,
    "average_win": 6297.666666666667,
    "average_loss": -3137.6666666666665
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 6,
    "net_profit": 6209.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.1887803944093434,
    "expectancy": 1034.8333333333333,
    "average_win": 5716.0,
    "average_loss": -1741.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 3,
    "net_profit": 1686.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.5330382548213721,
    "expectancy": 562.0,
    "average_win": 4849.0,
    "average_loss": -3163.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 9,
    "net_profit": -1944.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.8980437404940473,
    "expectancy": -216.0,
    "average_win": 5707.666666666667,
    "average_loss": -3177.8333333333335
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 6,
    "net_profit": 3454.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.4919527132887054,
    "expectancy": 575.6666666666666,
    "average_win": 5237.5,
    "average_loss": -1755.25
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 8,
    "net_profit": -10981.0,
    "win_rate": 0.125,
    "profit_factor": 0.45670888581040964,
    "expectancy": -1372.625,
    "average_win": 9231.0,
    "average_loss": -3368.6666666666665
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0218-1",
    "number_of_trades": 12,
    "net_profit": 53110.0,
    "win_rate": 0.75,
    "profit_factor": null,
    "expectancy": 4425.833333333333,
    "average_win": 5901.111111111111,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1-2.103",
    "number_of_trades": 8,
    "net_profit": -16873.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2109.125,
    "average_win": null,
    "average_loss": -2109.125
  },
  {
    "giveback_band": "GIVEBACK_2.103-437",
    "number_of_trades": 10,
    "net_profit": -31574.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3157.4,
    "average_win": null,
    "average_loss": -3157.4
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
