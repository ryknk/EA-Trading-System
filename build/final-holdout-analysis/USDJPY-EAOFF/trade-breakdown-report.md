# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 29
- MFEデータのある負けトレード数: 29
- うち一度含み益になった数: 29
- 割合: 100.00%
- 反転前の平均含み益: 2591.17

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 38
- 平均Giveback比率: 2407.37%
- 中央値Giveback比率: 228.72%
- 損益ゼロ以下まで完全反転した割合: 81.58%

## Time Stop（時間切れ決済）

- Time Stopによる決済件数: 1
- 純損益: -2521.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -2521.00

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

- 決済件数: 0
- 純損益: 0.00
- プロフィットファクター: 算出不能
- 勝率: 算出不能
- 期待値: 0.00
- 平均逆行幅（R）: 算出不能
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 10264
- 最終Entry候補まで到達: 64
- Stage別棄却数（market_regime）: 8555
- Stage別棄却数（htf_bias）: 362
- Stage別棄却数（trend_strength_or_momentum_filter）: 796
- Stage別棄却数（setup_or_trigger）: 487
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 8555,
  "CONFIRMATION_ADX_TOO_LOW": 84,
  "RSI_FILTERED": 712,
  "ENTRY_PATTERN_NOT_FOUND": 487,
  "TREND_NOT_ALIGNED": 362
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 20,
    "net_profit": -32003.0,
    "win_rate": 0.25,
    "profit_factor": 0.46831804891015416,
    "expectancy": -1600.15,
    "average_win": 5637.8,
    "average_loss": -4299.428571428572
  },
  {
    "direction": "SELL",
    "number_of_trades": 18,
    "net_profit": -33576.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.3474813432835821,
    "expectancy": -1865.3333333333333,
    "average_win": 8940.0,
    "average_loss": -3430.4
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 13,
    "net_profit": -33681.0,
    "win_rate": 0.15384615384615385,
    "profit_factor": 0.20997818591232145,
    "expectancy": -2590.846153846154,
    "average_win": 4476.0,
    "average_loss": -4263.3
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": 665.0,
    "win_rate": 0.25,
    "profit_factor": 1.0388707037643208,
    "expectancy": 83.125,
    "average_win": 8886.5,
    "average_loss": -2851.3333333333335
  },
  {
    "session": "NewYork",
    "number_of_trades": 8,
    "net_profit": -13470.0,
    "win_rate": 0.25,
    "profit_factor": 0.4363780911335202,
    "expectancy": -1683.75,
    "average_win": 5214.5,
    "average_loss": -3983.1666666666665
  },
  {
    "session": "Tokyo",
    "number_of_trades": 9,
    "net_profit": -19093.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.31830191373893174,
    "expectancy": -2121.4444444444443,
    "average_win": 8915.0,
    "average_loss": -4001.1428571428573
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 11,
    "net_profit": -40245.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.035100338056534564,
    "expectancy": -3658.6363636363635,
    "average_win": 1464.0,
    "average_loss": -4634.333333333333
  },
  {
    "weekday": "Mon",
    "number_of_trades": 4,
    "net_profit": -288.0,
    "win_rate": 0.25,
    "profit_factor": 0.9687567802126275,
    "expectancy": -72.0,
    "average_win": 8930.0,
    "average_loss": -3072.6666666666665
  },
  {
    "weekday": "Thu",
    "number_of_trades": 9,
    "net_profit": -6211.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.5913278062903013,
    "expectancy": -690.1111111111111,
    "average_win": 4493.5,
    "average_loss": -2533.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 9,
    "net_profit": -22392.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.27925840092699883,
    "expectancy": -2488.0,
    "average_win": 8676.0,
    "average_loss": -3883.5
  },
  {
    "weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": 3557.0,
    "win_rate": 0.4,
    "profit_factor": 1.2460740228294707,
    "expectancy": 711.4,
    "average_win": 9006.0,
    "average_loss": -4818.333333333333
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.0504-0.178",
    "number_of_trades": 13,
    "net_profit": -38096.0,
    "win_rate": 0.07692307692307693,
    "profit_factor": 0.18989495172883086,
    "expectancy": -2930.4615384615386,
    "average_win": 8930.0,
    "average_loss": -4275.090909090909
  },
  {
    "atr_band": "ATR_0.178-0.246",
    "number_of_trades": 12,
    "net_profit": -12936.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.598198478024538,
    "expectancy": -1078.0,
    "average_win": 4814.75,
    "average_loss": -4599.285714285715
  },
  {
    "atr_band": "ATR_0.246-0.636",
    "number_of_trades": 13,
    "net_profit": -14547.0,
    "win_rate": 0.15384615384615385,
    "profit_factor": 0.5513923582200019,
    "expectancy": -1119.0,
    "average_win": 8940.0,
    "average_loss": -2947.909090909091
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.3-42.67",
    "number_of_trades": 13,
    "net_profit": -41666.0,
    "win_rate": 0.07692307692307693,
    "profit_factor": 0.03394389056341294,
    "expectancy": -3205.076923076923,
    "average_win": 1464.0,
    "average_loss": -3920.909090909091
  },
  {
    "adx_band": "ADX_42.67-46.44",
    "number_of_trades": 12,
    "net_profit": -12890.0,
    "win_rate": 0.25,
    "profit_factor": 0.5774186145625021,
    "expectancy": -1074.1666666666667,
    "average_win": 5871.0,
    "average_loss": -3812.875
  },
  {
    "adx_band": "ADX_46.44-61.13",
    "number_of_trades": 13,
    "net_profit": -11023.0,
    "win_rate": 0.23076923076923078,
    "profit_factor": 0.7100355122977772,
    "expectancy": -847.9230769230769,
    "average_win": 8997.333333333334,
    "average_loss": -3801.5
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.463-5.428",
    "number_of_trades": 13,
    "net_profit": -56786.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4368.153846153846,
    "average_win": null,
    "average_loss": -4732.166666666667
  },
  {
    "hold_time_band": "HOLD_H_13.91-60",
    "number_of_trades": 13,
    "net_profit": -6981.0,
    "win_rate": 0.23076923076923078,
    "profit_factor": 0.7366356056890633,
    "expectancy": -537.0,
    "average_win": 6508.666666666667,
    "average_loss": -2650.7
  },
  {
    "hold_time_band": "HOLD_H_5.428-13.91",
    "number_of_trades": 12,
    "net_profit": -1812.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.9360959266443308,
    "expectancy": -151.0,
    "average_win": 6635.75,
    "average_loss": -4050.714285714286
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_2031-4272",
    "number_of_trades": 12,
    "net_profit": -43127.0,
    "win_rate": 0.08333333333333333,
    "profit_factor": 0.03283173734610123,
    "expectancy": -3593.9166666666665,
    "average_win": 1464.0,
    "average_loss": -4053.7272727272725
  },
  {
    "mfe_band": "MFE_4272-9049",
    "number_of_trades": 13,
    "net_profit": 33913.0,
    "win_rate": 0.38461538461538464,
    "profit_factor": 4.178350515463918,
    "expectancy": 2608.6923076923076,
    "average_win": 8916.6,
    "average_loss": -1778.3333333333333
  },
  {
    "mfe_band": "MFE_9.999-2031",
    "number_of_trades": 13,
    "net_profit": -56365.0,
    "win_rate": 0.07692307692307693,
    "profit_factor": 0.0003901608526788089,
    "expectancy": -4335.7692307692305,
    "average_win": 22.0,
    "average_loss": -4698.916666666667
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-3411--459",
    "number_of_trades": 13,
    "net_profit": 44858.0,
    "win_rate": 0.5384615384615384,
    "profit_factor": 38.04211395540875,
    "expectancy": 3450.6153846153848,
    "average_win": 6581.285714285715,
    "average_loss": -302.75
  },
  {
    "mae_band": "MAE_-4536--3411",
    "number_of_trades": 11,
    "net_profit": -43773.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3979.3636363636365,
    "average_win": null,
    "average_loss": -3979.3636363636365
  },
  {
    "mae_band": "MAE_-4792--4536",
    "number_of_trades": 14,
    "net_profit": -66664.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4761.714285714285,
    "average_win": null,
    "average_loss": -4761.714285714285
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 16,
    "net_profit": -23751.0,
    "win_rate": 0.1875,
    "profit_factor": 0.4297889707824166,
    "expectancy": -1484.4375,
    "average_win": 5967.333333333333,
    "average_loss": -3204.076923076923
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 22,
    "net_profit": -41828.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.40241445817558397,
    "expectancy": -1901.2727272727273,
    "average_win": 7041.75,
    "average_loss": -4374.6875
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": -4573.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2286.5,
    "average_win": null,
    "average_loss": -2286.5
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 8,
    "net_profit": 537.0,
    "win_rate": 0.25,
    "profit_factor": 1.0314605425039545,
    "expectancy": 67.125,
    "average_win": 8803.0,
    "average_loss": -3413.8
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 28,
    "net_profit": -61543.0,
    "win_rate": 0.17857142857142858,
    "profit_factor": 0.3162344732573384,
    "expectancy": -2197.964285714286,
    "average_win": 5692.6,
    "average_loss": -4091.181818181818
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 4,
    "net_profit": -1855.0,
    "win_rate": 0.5,
    "profit_factor": 0.44477701287039806,
    "expectancy": -463.75,
    "average_win": 743.0,
    "average_loss": -1670.5
  },
  {
    "close_reason": "SL",
    "number_of_trades": 29,
    "net_profit": -108307.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3734.7241379310344,
    "average_win": null,
    "average_loss": -4011.3703703703704
  },
  {
    "close_reason": "TP",
    "number_of_trades": 5,
    "net_profit": 44583.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8916.6,
    "average_win": 8916.6,
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
    "net_profit": -25421.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.2909065550906555,
    "expectancy": -2118.4166666666665,
    "average_win": 5214.5,
    "average_loss": -3983.3333333333335
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": -5432.0,
    "win_rate": 0.25,
    "profit_factor": 0.7666365940628088,
    "expectancy": -679.0,
    "average_win": 8922.5,
    "average_loss": -4655.4
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 12,
    "net_profit": -11842.0,
    "win_rate": 0.25,
    "profit_factor": 0.600431892566724,
    "expectancy": -986.8333333333334,
    "average_win": 5931.666666666667,
    "average_loss": -3293.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 6,
    "net_profit": -22884.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3814.0,
    "average_win": null,
    "average_loss": -3814.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 12,
    "net_profit": -25014.0,
    "win_rate": 0.08333333333333333,
    "profit_factor": 0.26383943023632245,
    "expectancy": -2084.5,
    "average_win": 8965.0,
    "average_loss": -3397.9
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": -7702.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.5743810786914235,
    "expectancy": -1100.2857142857142,
    "average_win": 5197.0,
    "average_loss": -3619.2
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 7,
    "net_profit": -9506.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.48961073825503354,
    "expectancy": -1358.0,
    "average_win": 4559.5,
    "average_loss": -4656.25
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 6,
    "net_profit": -10492.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.45262938230383976,
    "expectancy": -1748.6666666666667,
    "average_win": 8676.0,
    "average_loss": -3833.6
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 6,
    "net_profit": -12865.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.40932047750229567,
    "expectancy": -2144.1666666666665,
    "average_win": 8915.0,
    "average_loss": -4356.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00937-1.088",
    "number_of_trades": 13,
    "net_profit": 45672.0,
    "win_rate": 0.5384615384615384,
    "profit_factor": 116.04282115869017,
    "expectancy": 3513.230769230769,
    "average_win": 6581.285714285715,
    "average_loss": -99.25
  },
  {
    "giveback_band": "GIVEBACK_1.088-3.171",
    "number_of_trades": 12,
    "net_profit": -50119.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4176.583333333333,
    "average_win": null,
    "average_loss": -4176.583333333333
  },
  {
    "giveback_band": "GIVEBACK_3.171-461",
    "number_of_trades": 13,
    "net_profit": -61132.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4702.461538461538,
    "average_win": null,
    "average_loss": -4702.461538461538
  }
]
```

## time_stop_reason_code別

```json
[
  {
    "time_stop_reason_code": "MAX_HOLDING_BARS_MIN_MFE_NOT_REACHED",
    "number_of_trades": 1,
    "net_profit": -2521.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2521.0,
    "average_win": null,
    "average_loss": -2521.0
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
