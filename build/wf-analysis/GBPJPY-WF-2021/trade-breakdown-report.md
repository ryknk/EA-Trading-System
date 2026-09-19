# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 15
- MFEデータのある負けトレード数: 15
- うち一度含み益になった数: 15
- 割合: 100.00%
- 反転前の平均含み益: 2052.73

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 25
- 平均Giveback比率: 513.39%
- 中央値Giveback比率: 154.50%
- 損益ゼロ以下まで完全反転した割合: 60.00%

## Time Stop（時間切れ決済）

- Time Stopによる決済件数: 1
- 純損益: 1742.00
- プロフィットファクター: 算出不能
- 勝率: 100.00%
- 期待値: 1742.00

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

- 決済件数: 11
- 純損益: -40417.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3674.27
- 平均逆行幅（R）: 0.7582
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 8,
    "net_profit": -29226.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3653.25,
    "average_win": null,
    "average_loss": -3653.25
  },
  "SELL": {
    "number_of_trades": 3,
    "net_profit": -11191.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3730.3333333333335,
    "average_win": null,
    "average_loss": -3730.3333333333335
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6273
- 最終Entry候補まで到達: 49
- Stage別棄却数（market_regime）: 5166
- Stage別棄却数（htf_bias）: 291
- Stage別棄却数（trend_strength_or_momentum_filter）: 476
- Stage別棄却数（setup_or_trigger）: 291
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5166,
  "RSI_FILTERED": 458,
  "ENTRY_PATTERN_NOT_FOUND": 291,
  "CONFIRMATION_ADX_TOO_LOW": 18,
  "TREND_NOT_ALIGNED": 291
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 21,
    "net_profit": 30785.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.9231161354163544,
    "expectancy": 1465.952380952381,
    "average_win": 7126.0,
    "average_loss": -2779.0833333333335
  },
  {
    "direction": "SELL",
    "number_of_trades": 4,
    "net_profit": -1174.0,
    "win_rate": 0.25,
    "profit_factor": 0.8950942721830042,
    "expectancy": -293.5,
    "average_win": 10017.0,
    "average_loss": -3730.3333333333335
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 8,
    "net_profit": 10888.0,
    "win_rate": 0.375,
    "profit_factor": 1.5908720898681283,
    "expectancy": 1361.0,
    "average_win": 9771.666666666666,
    "average_loss": -3685.4
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 4,
    "net_profit": 15087.0,
    "win_rate": 0.5,
    "profit_factor": 5.275148767356192,
    "expectancy": 3771.75,
    "average_win": 9308.0,
    "average_loss": -1764.5
  },
  {
    "session": "NewYork",
    "number_of_trades": 5,
    "net_profit": -9526.0,
    "win_rate": 0.2,
    "profit_factor": 0.15459708910188144,
    "expectancy": -1905.2,
    "average_win": 1742.0,
    "average_loss": -2817.0
  },
  {
    "session": "Tokyo",
    "number_of_trades": 8,
    "net_profit": 13162.0,
    "win_rate": 0.5,
    "profit_factor": 2.1631318487097912,
    "expectancy": 1645.25,
    "average_win": 6119.5,
    "average_loss": -2829.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 4,
    "net_profit": 1479.0,
    "win_rate": 0.25,
    "profit_factor": 1.1938655131734173,
    "expectancy": 369.75,
    "average_win": 9108.0,
    "average_loss": -2543.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 6,
    "net_profit": 11195.0,
    "win_rate": 0.5,
    "profit_factor": 2.2204295214215635,
    "expectancy": 1865.8333333333333,
    "average_win": 6789.333333333333,
    "average_loss": -3057.6666666666665
  },
  {
    "weekday": "Thu",
    "number_of_trades": 5,
    "net_profit": 681.0,
    "win_rate": 0.4,
    "profit_factor": 1.074199171932883,
    "expectancy": 136.2,
    "average_win": 4929.5,
    "average_loss": -3059.3333333333335
  },
  {
    "weekday": "Tue",
    "number_of_trades": 6,
    "net_profit": 7882.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.717981417380215,
    "expectancy": 1313.6666666666667,
    "average_win": 9430.0,
    "average_loss": -2744.5
  },
  {
    "weekday": "Wed",
    "number_of_trades": 4,
    "net_profit": 8374.0,
    "win_rate": 0.5,
    "profit_factor": 2.104457926668425,
    "expectancy": 2093.5,
    "average_win": 7978.0,
    "average_loss": -3791.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.109-0.175",
    "number_of_trades": 9,
    "net_profit": 24448.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 2.8409638554216867,
    "expectancy": 2716.4444444444443,
    "average_win": 9432.0,
    "average_loss": -2656.0
  },
  {
    "atr_band": "ATR_0.175-0.212",
    "number_of_trades": 8,
    "net_profit": 689.0,
    "win_rate": 0.375,
    "profit_factor": 1.0382013750277224,
    "expectancy": 86.125,
    "average_win": 6241.666666666667,
    "average_loss": -3607.2
  },
  {
    "atr_band": "ATR_0.212-0.516",
    "number_of_trades": 8,
    "net_profit": 4474.0,
    "win_rate": 0.375,
    "profit_factor": 1.33832425892317,
    "expectancy": 559.25,
    "average_win": 5899.333333333333,
    "average_loss": -2644.8
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.21-41.03",
    "number_of_trades": 9,
    "net_profit": -9776.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.5352728655637954,
    "expectancy": -1086.2222222222222,
    "average_win": 5630.0,
    "average_loss": -3005.1428571428573
  },
  {
    "adx_band": "ADX_41.03-44.84",
    "number_of_trades": 8,
    "net_profit": 6339.0,
    "win_rate": 0.375,
    "profit_factor": 1.3513858093126385,
    "expectancy": 792.375,
    "average_win": 8126.333333333333,
    "average_loss": -3608.0
  },
  {
    "adx_band": "ADX_44.84-51.57",
    "number_of_trades": 8,
    "net_profit": 33048.0,
    "win_rate": 0.625,
    "profit_factor": 7.048316251830161,
    "expectancy": 4131.0,
    "average_win": 7702.4,
    "average_loss": -1821.3333333333333
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.661-7.429",
    "number_of_trades": 8,
    "net_profit": -12548.0,
    "win_rate": 0.125,
    "profit_factor": 0.431599927523102,
    "expectancy": -1568.5,
    "average_win": 9528.0,
    "average_loss": -3153.714285714286
  },
  {
    "hold_time_band": "HOLD_H_18.72-64",
    "number_of_trades": 9,
    "net_profit": 38137.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 6.244361936193619,
    "expectancy": 4237.444444444444,
    "average_win": 7568.166666666667,
    "average_loss": -2424.0
  },
  {
    "hold_time_band": "HOLD_H_7.429-18.72",
    "number_of_trades": 8,
    "net_profit": 4022.0,
    "win_rate": 0.375,
    "profit_factor": 1.2647446024223274,
    "expectancy": 502.75,
    "average_win": 6404.666666666667,
    "average_loss": -3038.4
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_1500-7457",
    "number_of_trades": 8,
    "net_profit": -15325.0,
    "win_rate": 0.25,
    "profit_factor": 0.10672650967591513,
    "expectancy": -1915.625,
    "average_win": 915.5,
    "average_loss": -2859.3333333333335
  },
  {
    "mfe_band": "MFE_66-1500",
    "number_of_trades": 8,
    "net_profit": -27354.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3419.25,
    "average_win": null,
    "average_loss": -3419.25
  },
  {
    "mfe_band": "MFE_7457-1.001e+04",
    "number_of_trades": 9,
    "net_profit": 72290.0,
    "win_rate": 0.8888888888888888,
    "profit_factor": 2410.6666666666665,
    "expectancy": 8032.222222222223,
    "average_win": 9040.0,
    "average_loss": -30.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2416--204",
    "number_of_trades": 9,
    "net_profit": 35212.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 10.096357530353913,
    "expectancy": 3912.4444444444443,
    "average_win": 6513.833333333333,
    "average_loss": -1290.3333333333333
  },
  {
    "mae_band": "MAE_-3619--2416",
    "number_of_trades": 7,
    "net_profit": 14213.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.311404318139878,
    "expectancy": 2030.4285714285713,
    "average_win": 8350.333333333334,
    "average_loss": -2709.5
  },
  {
    "mae_band": "MAE_-3929--3619",
    "number_of_trades": 9,
    "net_profit": -19814.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.3357916261607053,
    "expectancy": -2201.5555555555557,
    "average_win": 10017.0,
    "average_loss": -3728.875
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 6,
    "net_profit": -5578.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.6304981452040276,
    "expectancy": -929.6666666666666,
    "average_win": 9518.0,
    "average_loss": -3019.2
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 19,
    "net_profit": 35189.0,
    "win_rate": 0.47368421052631576,
    "profit_factor": 2.1951161526966443,
    "expectancy": 1852.0526315789473,
    "average_win": 7181.444444444444,
    "average_loss": -2944.4
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 1,
    "net_profit": -252.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -252.0,
    "average_win": null,
    "average_loss": -252.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 2,
    "net_profit": -3668.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1834.0,
    "average_win": null,
    "average_loss": -1834.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 22,
    "net_profit": 33531.0,
    "win_rate": 0.45454545454545453,
    "profit_factor": 1.825480059084195,
    "expectancy": 1524.1363636363637,
    "average_win": 7415.1,
    "average_loss": -3385.0
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 16,
    "net_profit": -36829.0,
    "win_rate": 0.125,
    "profit_factor": 0.1725679622556729,
    "expectancy": -2301.8125,
    "average_win": 3840.5,
    "average_loss": -3179.285714285714
  },
  {
    "close_reason": "SL",
    "number_of_trades": 2,
    "net_profit": 59.0,
    "win_rate": 0.5,
    "profit_factor": 2.966666666666667,
    "expectancy": 29.5,
    "average_win": 89.0,
    "average_loss": -30.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 7,
    "net_profit": 66381.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9483.0,
    "average_win": 9483.0,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 12,
    "net_profit": 13468.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.5549237742068398,
    "expectancy": 1122.3333333333333,
    "average_win": 9434.5,
    "average_loss": -3033.75
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": 15303.0,
    "win_rate": 0.625,
    "profit_factor": 2.379518615343009,
    "expectancy": 1912.875,
    "average_win": 5279.2,
    "average_loss": -3697.6666666666665
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 3,
    "net_profit": 7927.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 4.792822966507177,
    "expectancy": 2642.3333333333335,
    "average_win": 10017.0,
    "average_loss": -1045.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 2,
    "net_profit": -7087.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3543.5,
    "average_win": null,
    "average_loss": -3543.5
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 5,
    "net_profit": 11612.0,
    "win_rate": 0.6,
    "profit_factor": 2.578789938817131,
    "expectancy": 2322.4,
    "average_win": 6322.333333333333,
    "average_loss": -3677.5
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 5,
    "net_profit": -1637.0,
    "win_rate": 0.2,
    "profit_factor": 0.8533811016569637,
    "expectancy": -327.4,
    "average_win": 9528.0,
    "average_loss": -2791.25
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": -3669.0,
    "win_rate": 0.25,
    "profit_factor": 0.6181307243963364,
    "expectancy": -917.25,
    "average_win": 5939.0,
    "average_loss": -3202.6666666666665
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 6,
    "net_profit": 1647.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.1791580550418796,
    "expectancy": 274.5,
    "average_win": 5420.0,
    "average_loss": -2298.25
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": 21658.0,
    "win_rate": 0.6,
    "profit_factor": 4.000138523341183,
    "expectancy": 4331.6,
    "average_win": 9625.666666666666,
    "average_loss": -3609.5
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0167-0.257",
    "number_of_trades": 8,
    "net_profit": 72320.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9040.0,
    "average_win": 9040.0,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.257-2.89",
    "number_of_trades": 8,
    "net_profit": -9554.0,
    "win_rate": 0.25,
    "profit_factor": 0.1608256477821695,
    "expectancy": -1194.25,
    "average_win": 915.5,
    "average_loss": -1897.5
  },
  {
    "giveback_band": "GIVEBACK_2.89-55.83",
    "number_of_trades": 9,
    "net_profit": -33155.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3683.8888888888887,
    "average_win": null,
    "average_loss": -3683.8888888888887
  }
]
```

## time_stop_reason_code別

```json
[
  {
    "time_stop_reason_code": "MAX_HOLDING_BARS_MIN_MFE_NOT_REACHED",
    "number_of_trades": 1,
    "net_profit": 1742.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 1742.0,
    "average_win": 1742.0,
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
