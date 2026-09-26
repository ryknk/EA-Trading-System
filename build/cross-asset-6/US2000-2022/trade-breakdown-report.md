# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 17
- MFEデータのある負けトレード数: 17
- うち一度含み益になった数: 16
- 割合: 94.12%
- 反転前の平均含み益: 1838.38

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 19
- 平均Giveback比率: 357.64%
- 中央値Giveback比率: 236.45%
- 損益ゼロ以下まで完全反転した割合: 84.21%

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
- 純損益: -39660.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -2832.86
- 平均逆行幅（R）: 0.7850
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "SELL": {
    "number_of_trades": 14,
    "net_profit": -39660.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2832.8571428571427,
    "average_win": null,
    "average_loss": -2832.8571428571427
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 5908
- 最終Entry候補まで到達: 32
- Stage別棄却数（market_regime）: 4751
- Stage別棄却数（htf_bias）: 277
- Stage別棄却数（trend_strength_or_momentum_filter）: 584
- Stage別棄却数（setup_or_trigger）: 264
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 4751,
  "TREND_NOT_ALIGNED": 277,
  "RSI_FILTERED": 532,
  "ENTRY_PATTERN_NOT_FOUND": 264,
  "CONFIRMATION_ADX_TOO_LOW": 52
}
```

## direction別

```json
[
  {
    "direction": "SELL",
    "number_of_trades": 20,
    "net_profit": -23078.0,
    "win_rate": 0.15,
    "profit_factor": 0.42417286291731127,
    "expectancy": -1153.9,
    "average_win": 5666.666666666667,
    "average_loss": -2357.529411764706
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 5,
    "net_profit": -11229.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2245.8,
    "average_win": null,
    "average_loss": -2245.8
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 2,
    "net_profit": -6402.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3201.0,
    "average_win": null,
    "average_loss": -3201.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 9,
    "net_profit": -1228.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.9282416876059136,
    "expectancy": -136.44444444444446,
    "average_win": 7942.5,
    "average_loss": -2444.714285714286
  },
  {
    "session": "Tokyo",
    "number_of_trades": 4,
    "net_profit": -4219.0,
    "win_rate": 0.25,
    "profit_factor": 0.20903637045369328,
    "expectancy": -1054.75,
    "average_win": 1115.0,
    "average_loss": -1778.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 5,
    "net_profit": -3948.0,
    "win_rate": 0.2,
    "profit_factor": 0.6746064452320119,
    "expectancy": -789.6,
    "average_win": 8185.0,
    "average_loss": -3033.25
  },
  {
    "weekday": "Mon",
    "number_of_trades": 2,
    "net_profit": -2958.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1479.0,
    "average_win": null,
    "average_loss": -1479.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": -8566.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2141.5,
    "average_win": null,
    "average_loss": -2141.5
  },
  {
    "weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": 5908.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 3.0323357413140695,
    "expectancy": 1969.3333333333333,
    "average_win": 4407.5,
    "average_loss": -2907.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 6,
    "net_profit": -13514.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2252.3333333333335,
    "average_win": null,
    "average_loss": -2252.3333333333335
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_10.69-15.01",
    "number_of_trades": 7,
    "net_profit": -11657.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.08730034450360163,
    "expectancy": -1665.2857142857142,
    "average_win": 1115.0,
    "average_loss": -2128.6666666666665
  },
  {
    "atr_band": "ATR_4.836-7.773",
    "number_of_trades": 7,
    "net_profit": -8496.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.4754260311187948,
    "expectancy": -1213.7142857142858,
    "average_win": 7700.0,
    "average_loss": -2699.3333333333335
  },
  {
    "atr_band": "ATR_7.773-10.69",
    "number_of_trades": 6,
    "net_profit": -2925.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.7367236723672367,
    "expectancy": -487.5,
    "average_win": 8185.0,
    "average_loss": -2222.0
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.29-41.94",
    "number_of_trades": 7,
    "net_profit": -6422.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.560347778462381,
    "expectancy": -917.4285714285714,
    "average_win": 8185.0,
    "average_loss": -2434.5
  },
  {
    "adx_band": "ADX_41.94-44.87",
    "number_of_trades": 6,
    "net_profit": -5996.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.5622079439252337,
    "expectancy": -999.3333333333334,
    "average_win": 7700.0,
    "average_loss": -2739.2
  },
  {
    "adx_band": "ADX_44.87-60.69",
    "number_of_trades": 7,
    "net_profit": -10660.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.09469214437367304,
    "expectancy": -1522.857142857143,
    "average_win": 1115.0,
    "average_loss": -1962.5
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.352-2.698",
    "number_of_trades": 7,
    "net_profit": -9239.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.46975436179981633,
    "expectancy": -1319.857142857143,
    "average_win": 8185.0,
    "average_loss": -2904.0
  },
  {
    "hold_time_band": "HOLD_H_2.698-6.945",
    "number_of_trades": 6,
    "net_profit": -6493.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.542520961037131,
    "expectancy": -1082.1666666666667,
    "average_win": 7700.0,
    "average_loss": -2838.6
  },
  {
    "hold_time_band": "HOLD_H_6.945-22",
    "number_of_trades": 7,
    "net_profit": -7346.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.13178111334357642,
    "expectancy": -1049.4285714285713,
    "average_win": 1115.0,
    "average_loss": -1410.1666666666667
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-0.001-932.7",
    "number_of_trades": 7,
    "net_profit": -19158.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2736.8571428571427,
    "average_win": null,
    "average_loss": -2736.8571428571427
  },
  {
    "mfe_band": "MFE_2799-8160",
    "number_of_trades": 7,
    "net_profit": 10958.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.8136378682555447,
    "expectancy": 1565.4285714285713,
    "average_win": 5666.666666666667,
    "average_loss": -1510.5
  },
  {
    "mfe_band": "MFE_932.7-2799",
    "number_of_trades": 6,
    "net_profit": -14878.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2479.6666666666665,
    "average_win": null,
    "average_loss": -2479.6666666666665
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2189--513",
    "number_of_trades": 7,
    "net_profit": 4645.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.9978517722878626,
    "expectancy": 663.5714285714286,
    "average_win": 4650.0,
    "average_loss": -931.0
  },
  {
    "mae_band": "MAE_-2647--2189",
    "number_of_trades": 6,
    "net_profit": -5001.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.6062514762617117,
    "expectancy": -833.5,
    "average_win": 7700.0,
    "average_loss": -2540.2
  },
  {
    "mae_band": "MAE_-3808--2647",
    "number_of_trades": 7,
    "net_profit": -22722.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3246.0,
    "average_win": null,
    "average_loss": -3246.0
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 16,
    "net_profit": -25014.0,
    "win_rate": 0.125,
    "profit_factor": 0.2605752460906323,
    "expectancy": -1563.375,
    "average_win": 4407.5,
    "average_loss": -2416.3571428571427
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 4,
    "net_profit": 1936.0,
    "win_rate": 0.25,
    "profit_factor": 1.309809569531125,
    "expectancy": 484.0,
    "average_win": 8185.0,
    "average_loss": -2083.0
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 3,
    "net_profit": -4094.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.21405260126703782,
    "expectancy": -1364.6666666666667,
    "average_win": 1115.0,
    "average_loss": -2604.5
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 2,
    "net_profit": -6402.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3201.0,
    "average_win": null,
    "average_loss": -3201.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 15,
    "net_profit": -12582.0,
    "win_rate": 0.13333333333333333,
    "profit_factor": 0.5580145431552324,
    "expectancy": -838.8,
    "average_win": 7942.5,
    "average_loss": -2189.769230769231
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 16,
    "net_profit": -38945.0,
    "win_rate": 0.0625,
    "profit_factor": 0.027833250124812782,
    "expectancy": -2434.0625,
    "average_win": 1115.0,
    "average_loss": -2670.6666666666665
  },
  {
    "close_reason": "SL",
    "number_of_trades": 2,
    "net_profit": -18.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -9.0,
    "average_win": null,
    "average_loss": -9.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 2,
    "net_profit": 15885.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7942.5,
    "average_win": 7942.5,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 2,
    "net_profit": -2776.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1388.0,
    "average_win": null,
    "average_loss": -1388.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 6,
    "net_profit": -15091.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2515.1666666666665,
    "average_win": null,
    "average_loss": -2515.1666666666665
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 8,
    "net_profit": -5622.0,
    "win_rate": 0.25,
    "profit_factor": 0.6232408524326498,
    "expectancy": -702.75,
    "average_win": 4650.0,
    "average_loss": -2487.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 4,
    "net_profit": 411.0,
    "win_rate": 0.25,
    "profit_factor": 1.0563863355741527,
    "expectancy": 102.75,
    "average_win": 7700.0,
    "average_loss": -2429.6666666666665
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 5,
    "net_profit": -3948.0,
    "win_rate": 0.2,
    "profit_factor": 0.6746064452320119,
    "expectancy": -789.6,
    "average_win": 8185.0,
    "average_loss": -3033.25
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 1,
    "net_profit": -2558.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2558.0,
    "average_win": null,
    "average_loss": -2558.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 5,
    "net_profit": -8580.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1716.0,
    "average_win": null,
    "average_loss": -1716.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": 4393.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.328394315089205,
    "expectancy": 1464.3333333333333,
    "average_win": 7700.0,
    "average_loss": -1653.5
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 6,
    "net_profit": -12385.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.08259259259259259,
    "expectancy": -2064.1666666666665,
    "average_win": 1115.0,
    "average_loss": -2700.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00426-1.899",
    "number_of_trades": 6,
    "net_profit": 16582.0,
    "win_rate": 0.5,
    "profit_factor": 40.66985645933014,
    "expectancy": 2763.6666666666665,
    "average_win": 5666.666666666667,
    "average_loss": -139.33333333333334
  },
  {
    "giveback_band": "GIVEBACK_1.899-3.948",
    "number_of_trades": 6,
    "net_profit": -16694.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2782.3333333333335,
    "average_win": null,
    "average_loss": -2782.3333333333335
  },
  {
    "giveback_band": "GIVEBACK_3.948-15.25",
    "number_of_trades": 7,
    "net_profit": -19711.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2815.8571428571427,
    "average_win": null,
    "average_loss": -2815.8571428571427
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
