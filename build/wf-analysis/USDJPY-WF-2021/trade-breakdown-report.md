# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 16
- MFEデータのある負けトレード数: 16
- うち一度含み益になった数: 15
- 割合: 93.75%
- 反転前の平均含み益: 2152.93

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 27
- 平均Giveback比率: 539.96%
- 中央値Giveback比率: 113.93%
- 損益ゼロ以下まで完全反転した割合: 62.96%

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

- 決済件数: 14
- 純損益: -51986.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3713.29
- 平均逆行幅（R）: 0.7626
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 13,
    "net_profit": -48386.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3722.0,
    "average_win": null,
    "average_loss": -3722.0
  },
  "SELL": {
    "number_of_trades": 1,
    "net_profit": -3600.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3600.0,
    "average_win": null,
    "average_loss": -3600.0
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6272
- 最終Entry候補まで到達: 48
- Stage別棄却数（market_regime）: 5081
- Stage別棄却数（htf_bias）: 290
- Stage別棄却数（trend_strength_or_momentum_filter）: 436
- Stage別棄却数（setup_or_trigger）: 417
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5081,
  "ENTRY_PATTERN_NOT_FOUND": 417,
  "RSI_FILTERED": 410,
  "CONFIRMATION_ADX_TOO_LOW": 26,
  "TREND_NOT_ALIGNED": 290
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 26,
    "net_profit": 19489.0,
    "win_rate": 0.38461538461538464,
    "profit_factor": 1.402573795211832,
    "expectancy": 749.5769230769231,
    "average_win": 6790.0,
    "average_loss": -3457.9285714285716
  },
  {
    "direction": "SELL",
    "number_of_trades": 2,
    "net_profit": -4227.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2113.5,
    "average_win": null,
    "average_loss": -2113.5
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 10,
    "net_profit": -2974.0,
    "win_rate": 0.2,
    "profit_factor": 0.868074346803886,
    "expectancy": -297.4,
    "average_win": 9784.5,
    "average_loss": -3220.4285714285716
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 5,
    "net_profit": 23577.0,
    "win_rate": 0.6,
    "profit_factor": 7.133454734651405,
    "expectancy": 4715.4,
    "average_win": 9140.333333333334,
    "average_loss": -3844.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 5,
    "net_profit": -2314.0,
    "win_rate": 0.6,
    "profit_factor": 0.43214723926380366,
    "expectancy": -462.8,
    "average_win": 587.0,
    "average_loss": -2037.5
  },
  {
    "session": "Tokyo",
    "number_of_trades": 8,
    "net_profit": -3027.0,
    "win_rate": 0.25,
    "profit_factor": 0.8635010822510822,
    "expectancy": -378.375,
    "average_win": 9574.5,
    "average_loss": -3696.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 5,
    "net_profit": -7481.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1496.2,
    "average_win": null,
    "average_loss": -2493.6666666666665
  },
  {
    "weekday": "Mon",
    "number_of_trades": 6,
    "net_profit": -808.0,
    "win_rate": 0.5,
    "profit_factor": 0.9252682204957454,
    "expectancy": -134.66666666666666,
    "average_win": 3334.6666666666665,
    "average_loss": -3604.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": 14805.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 4.995951417004049,
    "expectancy": 4935.0,
    "average_win": 9255.0,
    "average_loss": -3705.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 6,
    "net_profit": 20604.0,
    "win_rate": 0.5,
    "profit_factor": 3.5446461652463874,
    "expectancy": 3434.0,
    "average_win": 9567.0,
    "average_loss": -2699.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 8,
    "net_profit": -11858.0,
    "win_rate": 0.25,
    "profit_factor": 0.47398305460675155,
    "expectancy": -1482.25,
    "average_win": 5342.5,
    "average_loss": -3757.1666666666665
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.0705-0.0869",
    "number_of_trades": 9,
    "net_profit": 5074.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2211278654231674,
    "expectancy": 563.7777777777778,
    "average_win": 9340.0,
    "average_loss": -3824.3333333333335
  },
  {
    "atr_band": "ATR_0.0869-0.111",
    "number_of_trades": 9,
    "net_profit": 12673.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.5985116044399597,
    "expectancy": 1408.111111111111,
    "average_win": 6867.0,
    "average_loss": -1982.0
  },
  {
    "atr_band": "ATR_0.111-0.158",
    "number_of_trades": 10,
    "net_profit": -2485.0,
    "win_rate": 0.4,
    "profit_factor": 0.8858206212093365,
    "expectancy": -248.5,
    "average_win": 4819.75,
    "average_loss": -3627.3333333333335
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.55-42.02",
    "number_of_trades": 10,
    "net_profit": 21727.0,
    "win_rate": 0.5,
    "profit_factor": 2.1812003914319886,
    "expectancy": 2172.7,
    "average_win": 8024.2,
    "average_loss": -3678.8
  },
  {
    "adx_band": "ADX_42.02-44.6",
    "number_of_trades": 9,
    "net_profit": 6280.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 1.5256549761446387,
    "expectancy": 697.7777777777778,
    "average_win": 4556.75,
    "average_loss": -2986.75
  },
  {
    "adx_band": "ADX_44.6-53.97",
    "number_of_trades": 9,
    "net_profit": -12745.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.4283984392519173,
    "expectancy": -1416.111111111111,
    "average_win": 9552.0,
    "average_loss": -3185.285714285714
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.187-3.052",
    "number_of_trades": 9,
    "net_profit": -4463.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.8001522478953967,
    "expectancy": -495.8888888888889,
    "average_win": 8934.5,
    "average_loss": -3722.0
  },
  {
    "hold_time_band": "HOLD_H_3.052-8.676",
    "number_of_trades": 9,
    "net_profit": 9916.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.52767134951043,
    "expectancy": 1101.7777777777778,
    "average_win": 9569.333333333334,
    "average_loss": -3758.4
  },
  {
    "hold_time_band": "HOLD_H_8.676-23.47",
    "number_of_trades": 10,
    "net_profit": 9809.0,
    "win_rate": 0.5,
    "profit_factor": 1.8519194024665624,
    "expectancy": 980.9,
    "average_win": 4264.6,
    "average_loss": -2302.8
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-99-1800",
    "number_of_trades": 9,
    "net_profit": -33456.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3717.3333333333335,
    "average_win": null,
    "average_loss": -3717.3333333333335
  },
  {
    "mfe_band": "MFE_1800-7525",
    "number_of_trades": 9,
    "net_profit": -17754.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.07323693688990969,
    "expectancy": -1972.6666666666667,
    "average_win": 1403.0,
    "average_loss": -3192.8333333333335
  },
  {
    "mfe_band": "MFE_7525-9938",
    "number_of_trades": 10,
    "net_profit": 66472.0,
    "win_rate": 0.9,
    "profit_factor": 2659.88,
    "expectancy": 6647.2,
    "average_win": 7388.555555555556,
    "average_loss": -25.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2302--90",
    "number_of_trades": 10,
    "net_profit": 38040.0,
    "win_rate": 0.7,
    "profit_factor": 59.34355828220859,
    "expectancy": 3804.0,
    "average_win": 5527.428571428572,
    "average_loss": -326.0
  },
  {
    "mae_band": "MAE_-3674--2302",
    "number_of_trades": 8,
    "net_profit": 14976.0,
    "win_rate": 0.375,
    "profit_factor": 2.052276559865093,
    "expectancy": 1872.0,
    "average_win": 9736.0,
    "average_loss": -3558.0
  },
  {
    "mae_band": "MAE_-4263--3674",
    "number_of_trades": 10,
    "net_profit": -37754.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3775.4,
    "average_win": null,
    "average_loss": -3775.4
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 4,
    "net_profit": -11745.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2936.25,
    "average_win": null,
    "average_loss": -2936.25
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 24,
    "net_profit": 27007.0,
    "win_rate": 0.4166666666666667,
    "profit_factor": 1.6604308805908101,
    "expectancy": 1125.2916666666667,
    "average_win": 6790.0,
    "average_loss": -3407.75
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 3,
    "net_profit": 2176.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2912985274431057,
    "expectancy": 725.3333333333334,
    "average_win": 9646.0,
    "average_loss": -3735.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 25,
    "net_profit": 13086.0,
    "win_rate": 0.36,
    "profit_factor": 1.2897183846971307,
    "expectancy": 523.44,
    "average_win": 6472.666666666667,
    "average_loss": -3226.285714285714
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 15,
    "net_profit": -50583.0,
    "win_rate": 0.06666666666666667,
    "profit_factor": 0.026988035240256992,
    "expectancy": -3372.2,
    "average_win": 1403.0,
    "average_loss": -3713.285714285714
  },
  {
    "close_reason": "SL",
    "number_of_trades": 6,
    "net_profit": -294.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.549079754601227,
    "expectancy": -49.0,
    "average_win": 179.0,
    "average_loss": -326.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 7,
    "net_profit": 66139.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9448.42857142857,
    "average_win": 9448.42857142857,
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
    "net_profit": 8589.0,
    "win_rate": 0.5,
    "profit_factor": 1.7667380824852705,
    "expectancy": 1073.625,
    "average_win": 4947.75,
    "average_loss": -3734.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 11,
    "net_profit": -10130.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.6596788281932406,
    "expectancy": -920.9090909090909,
    "average_win": 6545.333333333333,
    "average_loss": -3720.75
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 4,
    "net_profit": 18896.0,
    "win_rate": 0.5,
    "profit_factor": 756.84,
    "expectancy": 4724.0,
    "average_win": 9460.5,
    "average_loss": -25.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 5,
    "net_profit": -2093.0,
    "win_rate": 0.2,
    "profit_factor": 0.8202662086732503,
    "expectancy": -418.6,
    "average_win": 9552.0,
    "average_loss": -2911.25
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 6,
    "net_profit": 2442.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 1.326426948268948,
    "expectancy": 407.0,
    "average_win": 9923.0,
    "average_loss": -2493.6666666666665
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 4,
    "net_profit": -1166.0,
    "win_rate": 0.25,
    "profit_factor": 0.8921568627450981,
    "expectancy": -291.5,
    "average_win": 9646.0,
    "average_loss": -3604.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": 2837.0,
    "win_rate": 0.5,
    "profit_factor": 1.396616804138124,
    "expectancy": 709.25,
    "average_win": 4995.0,
    "average_loss": -3576.5
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 7,
    "net_profit": 21589.0,
    "win_rate": 0.7142857142857143,
    "profit_factor": 3.890093708165997,
    "expectancy": 3084.1428571428573,
    "average_win": 5811.8,
    "average_loss": -3735.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 7,
    "net_profit": -10440.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.4706419227258899,
    "expectancy": -1491.4285714285713,
    "average_win": 9282.0,
    "average_loss": -3287.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0157-0.982",
    "number_of_trades": 9,
    "net_profit": 67754.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7528.222222222223,
    "average_win": 7528.222222222223,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.982-2.748",
    "number_of_trades": 9,
    "net_profit": -15476.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.009345794392523364,
    "expectancy": -1719.5555555555557,
    "average_win": 146.0,
    "average_loss": -2603.6666666666665
  },
  {
    "giveback_band": "GIVEBACK_2.748-66",
    "number_of_trades": 9,
    "net_profit": -33320.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3702.222222222222,
    "average_win": null,
    "average_loss": -3702.222222222222
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
