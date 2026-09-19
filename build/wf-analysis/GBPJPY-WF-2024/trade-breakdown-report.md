# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 22
- MFEデータのある負けトレード数: 22
- うち一度含み益になった数: 21
- 割合: 95.45%
- 反転前の平均含み益: 2762.76

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 33
- 平均Giveback比率: 361.47%
- 中央値Giveback比率: 104.06%
- 損益ゼロ以下まで完全反転した割合: 63.64%

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

- 決済件数: 13
- 純損益: -48001.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3692.38
- 平均逆行幅（R）: 0.7793
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 13,
    "net_profit": -48001.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3692.3846153846152,
    "average_win": null,
    "average_loss": -3692.3846153846152
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6312
- 最終Entry候補まで到達: 72
- Stage別棄却数（market_regime）: 5237
- Stage別棄却数（htf_bias）: 81
- Stage別棄却数（trend_strength_or_momentum_filter）: 481
- Stage別棄却数（setup_or_trigger）: 441
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5237,
  "RSI_FILTERED": 440,
  "CONFIRMATION_ADX_TOO_LOW": 41,
  "TREND_NOT_ALIGNED": 81,
  "ENTRY_PATTERN_NOT_FOUND": 441
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 31,
    "net_profit": -5045.0,
    "win_rate": 0.3548387096774194,
    "profit_factor": 0.9276443169594837,
    "expectancy": -162.74193548387098,
    "average_win": 5880.0,
    "average_loss": -3486.25
  },
  {
    "direction": "SELL",
    "number_of_trades": 3,
    "net_profit": 9099.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 455.95,
    "expectancy": 3033.0,
    "average_win": 9119.0,
    "average_loss": -10.0
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 14,
    "net_profit": -5861.0,
    "win_rate": 0.21428571428571427,
    "profit_factor": 0.7563297717540431,
    "expectancy": -418.64285714285717,
    "average_win": 6064.0,
    "average_loss": -2186.6363636363635
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 5,
    "net_profit": -19785.0,
    "win_rate": 0.2,
    "profit_factor": 0.003826594834096974,
    "expectancy": -3957.0,
    "average_win": 76.0,
    "average_loss": -4965.25
  },
  {
    "session": "NewYork",
    "number_of_trades": 8,
    "net_profit": 4401.0,
    "win_rate": 0.5,
    "profit_factor": 1.3081501190309481,
    "expectancy": 550.125,
    "average_win": 4670.75,
    "average_loss": -3570.5
  },
  {
    "session": "Tokyo",
    "number_of_trades": 7,
    "net_profit": 25299.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 3.1905792709325485,
    "expectancy": 3614.1428571428573,
    "average_win": 9212.0,
    "average_loss": -3849.6666666666665
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 8,
    "net_profit": -18804.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2350.5,
    "average_win": null,
    "average_loss": -2350.5
  },
  {
    "weekday": "Mon",
    "number_of_trades": 8,
    "net_profit": -11996.0,
    "win_rate": 0.5,
    "profit_factor": 0.021134230926152592,
    "expectancy": -1499.5,
    "average_win": 64.75,
    "average_loss": -3063.75
  },
  {
    "weekday": "Thu",
    "number_of_trades": 7,
    "net_profit": 22697.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 2.643519188993483,
    "expectancy": 3242.4285714285716,
    "average_win": 9126.75,
    "average_loss": -4603.333333333333
  },
  {
    "weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": 14720.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 5.214142570855998,
    "expectancy": 4906.666666666667,
    "average_win": 9106.5,
    "average_loss": -3493.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 8,
    "net_profit": -2563.0,
    "win_rate": 0.25,
    "profit_factor": 0.8801384277229575,
    "expectancy": -320.375,
    "average_win": 9410.0,
    "average_loss": -3563.8333333333335
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.129-0.212",
    "number_of_trades": 12,
    "net_profit": 2472.0,
    "win_rate": 0.4166666666666667,
    "profit_factor": 1.0732032337350825,
    "expectancy": 206.0,
    "average_win": 7248.2,
    "average_loss": -4824.142857142857
  },
  {
    "atr_band": "ATR_0.212-0.297",
    "number_of_trades": 10,
    "net_profit": -11835.0,
    "win_rate": 0.3,
    "profit_factor": 0.4537019940915805,
    "expectancy": -1183.5,
    "average_win": 3276.3333333333335,
    "average_loss": -3094.8571428571427
  },
  {
    "atr_band": "ATR_0.297-0.546",
    "number_of_trades": 12,
    "net_profit": 13417.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.9374650642817217,
    "expectancy": 1118.0833333333333,
    "average_win": 6932.25,
    "average_loss": -1789.0
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.02-41.68",
    "number_of_trades": 12,
    "net_profit": 1200.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.0459207102403183,
    "expectancy": 100.0,
    "average_win": 6833.0,
    "average_loss": -3266.5
  },
  {
    "adx_band": "ADX_41.68-43.01",
    "number_of_trades": 11,
    "net_profit": -659.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 0.9673147505207816,
    "expectancy": -59.90909090909091,
    "average_win": 4875.75,
    "average_loss": -2880.285714285714
  },
  {
    "adx_band": "ADX_43.01-63.06",
    "number_of_trades": 11,
    "net_profit": 3513.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 1.1498017142126136,
    "expectancy": 319.3636363636364,
    "average_win": 6741.0,
    "average_loss": -3350.1428571428573
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.616-5.5",
    "number_of_trades": 11,
    "net_profit": -38943.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3540.2727272727275,
    "average_win": null,
    "average_loss": -3540.2727272727275
  },
  {
    "hold_time_band": "HOLD_H_11.1-92.63",
    "number_of_trades": 12,
    "net_profit": 49305.0,
    "win_rate": 0.8333333333333334,
    "profit_factor": 7.800689655172413,
    "expectancy": 4108.75,
    "average_win": 5655.5,
    "average_loss": -3625.0
  },
  {
    "hold_time_band": "HOLD_H_5.5-11.1",
    "number_of_trades": 11,
    "net_profit": -6308.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.7321671195652174,
    "expectancy": -573.4545454545455,
    "average_win": 8622.0,
    "average_loss": -2616.8888888888887
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-126-2196",
    "number_of_trades": 11,
    "net_profit": -41329.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3757.181818181818,
    "average_win": null,
    "average_loss": -3757.181818181818
  },
  {
    "mfe_band": "MFE_2196-6623",
    "number_of_trades": 11,
    "net_profit": -27959.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.005866875266676149,
    "expectancy": -2541.7272727272725,
    "average_win": 82.5,
    "average_loss": -3124.8888888888887
  },
  {
    "mfe_band": "MFE_6623-9665",
    "number_of_trades": 12,
    "net_profit": 73342.0,
    "win_rate": 0.8333333333333334,
    "profit_factor": 252.17123287671234,
    "expectancy": 6111.833333333333,
    "average_win": 7363.4,
    "average_loss": -146.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1464--240",
    "number_of_trades": 12,
    "net_profit": 43901.0,
    "win_rate": 0.5833333333333334,
    "profit_factor": 27.8671970624235,
    "expectancy": 3658.4166666666665,
    "average_win": 6505.0,
    "average_loss": -326.8
  },
  {
    "mae_band": "MAE_-3564--1464",
    "number_of_trades": 10,
    "net_profit": -6685.0,
    "win_rate": 0.4,
    "profit_factor": 0.7352265525982256,
    "expectancy": -668.5,
    "average_win": 4640.75,
    "average_loss": -4208.0
  },
  {
    "mae_band": "MAE_-4420--3564",
    "number_of_trades": 12,
    "net_profit": -33162.0,
    "win_rate": 0.08333333333333333,
    "profit_factor": 0.22632573548281734,
    "expectancy": -2763.5,
    "average_win": 9701.0,
    "average_loss": -3896.6363636363635
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 5,
    "net_profit": 4185.0,
    "win_rate": 0.2,
    "profit_factor": 1.848196189704094,
    "expectancy": 837.0,
    "average_win": 9119.0,
    "average_loss": -1233.5
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 29,
    "net_profit": -131.0,
    "win_rate": 0.3793103448275862,
    "profit_factor": 0.9979787381771613,
    "expectancy": -4.517241379310345,
    "average_win": 5880.0,
    "average_loss": -3600.6111111111113
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 1,
    "net_profit": 8897.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8897.0,
    "average_win": 8897.0,
    "average_loss": null
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 5,
    "net_profit": -3792.0,
    "win_rate": 0.2,
    "profit_factor": 0.014296854691967767,
    "expectancy": -758.4,
    "average_win": 55.0,
    "average_loss": -961.75
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 28,
    "net_profit": -1051.0,
    "win_rate": 0.35714285714285715,
    "profit_factor": 0.9840511092901151,
    "expectancy": -37.535714285714285,
    "average_win": 6484.7,
    "average_loss": -3661.0
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 14,
    "net_profit": -47912.0,
    "win_rate": 0.07142857142857142,
    "profit_factor": 0.0018541280389991876,
    "expectancy": -3422.285714285714,
    "average_win": 89.0,
    "average_loss": -3692.3846153846152
  },
  {
    "close_reason": "SL",
    "number_of_trades": 12,
    "net_profit": -21574.0,
    "win_rate": 0.25,
    "profit_factor": 0.007818248712288447,
    "expectancy": -1797.8333333333333,
    "average_win": 56.666666666666664,
    "average_loss": -2416.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 8,
    "net_profit": 73540.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9192.5,
    "average_win": 9192.5,
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
    "net_profit": 11656.0,
    "win_rate": 0.5,
    "profit_factor": 1.7366026289180991,
    "expectancy": 971.3333333333334,
    "average_win": 4580.0,
    "average_loss": -2637.3333333333335
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 10,
    "net_profit": -7978.0,
    "win_rate": 0.3,
    "profit_factor": 0.7049665323027995,
    "expectancy": -797.8,
    "average_win": 6354.333333333333,
    "average_loss": -3863.0
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 5,
    "net_profit": -14.0,
    "win_rate": 0.2,
    "profit_factor": 0.9983618066931897,
    "expectancy": -2.8,
    "average_win": 8532.0,
    "average_loss": -2136.5
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 7,
    "net_profit": 390.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.0212719537471364,
    "expectancy": 55.714285714285715,
    "average_win": 9362.0,
    "average_loss": -3666.8
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 10,
    "net_profit": -12819.0,
    "win_rate": 0.1,
    "profit_factor": 0.4283357117374242,
    "expectancy": -1281.9,
    "average_win": 9605.0,
    "average_loss": -2491.5555555555557
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 3,
    "net_profit": 4969.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.0597142247814033,
    "expectancy": 1656.3333333333333,
    "average_win": 9658.0,
    "average_loss": -2344.5
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 7,
    "net_profit": 21961.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 2.5571864142381053,
    "expectancy": 3137.285714285714,
    "average_win": 9016.0,
    "average_loss": -4701.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 6,
    "net_profit": -7307.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 0.034232090933121864,
    "expectancy": -1217.8333333333333,
    "average_win": 64.75,
    "average_loss": -3783.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 8,
    "net_profit": -2750.0,
    "win_rate": 0.25,
    "profit_factor": 0.8688164861899538,
    "expectancy": -343.75,
    "average_win": 9106.5,
    "average_loss": -3493.8333333333335
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0303-0.994",
    "number_of_trades": 11,
    "net_profit": 73760.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 6705.454545454545,
    "average_win": 6705.454545454545,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.994-3.358",
    "number_of_trades": 11,
    "net_profit": -16978.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.002291825821237586,
    "expectancy": -1543.4545454545455,
    "average_win": 39.0,
    "average_loss": -1701.7
  },
  {
    "giveback_band": "GIVEBACK_3.358-24.7",
    "number_of_trades": 11,
    "net_profit": -49110.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4464.545454545455,
    "average_win": null,
    "average_loss": -4464.545454545455
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
