# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 19
- MFEデータのある負けトレード数: 19
- うち一度含み益になった数: 18
- 割合: 94.74%
- 反転前の平均含み益: 2211.50

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 33
- 平均Giveback比率: 314.50%
- 中央値Giveback比率: 138.71%
- 損益ゼロ以下まで完全反転した割合: 63.64%

## Time Stop（時間切れ決済）

- Time Stopによる決済件数: 1
- 純損益: -617.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -617.00

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
- 純損益: -61532.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3619.53
- 平均逆行幅（R）: 0.7589
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 4,
    "net_profit": -14847.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3711.75,
    "average_win": null,
    "average_loss": -3711.75
  },
  "SELL": {
    "number_of_trades": 13,
    "net_profit": -46685.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3591.153846153846,
    "average_win": null,
    "average_loss": -3591.153846153846
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6348
- 最終Entry候補まで到達: 57
- Stage別棄却数（market_regime）: 5236
- Stage別棄却数（htf_bias）: 178
- Stage別棄却数（trend_strength_or_momentum_filter）: 432
- Stage別棄却数（setup_or_trigger）: 445
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5236,
  "CONFIRMATION_ADX_TOO_LOW": 82,
  "RSI_FILTERED": 350,
  "ENTRY_PATTERN_NOT_FOUND": 445,
  "TREND_NOT_ALIGNED": 178
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 7,
    "net_profit": -618.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.9583754293796727,
    "expectancy": -88.28571428571429,
    "average_win": 7114.5,
    "average_loss": -3711.75
  },
  {
    "direction": "SELL",
    "number_of_trades": 27,
    "net_profit": 1609.0,
    "win_rate": 0.37037037037037035,
    "profit_factor": 1.0340082854244166,
    "expectancy": 59.592592592592595,
    "average_win": 4892.1,
    "average_loss": -3154.133333333333
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 6,
    "net_profit": -18114.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3019.0,
    "average_win": null,
    "average_loss": -3622.8
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": 783.0,
    "win_rate": 0.25,
    "profit_factor": 1.0429653204565408,
    "expectancy": 97.875,
    "average_win": 9503.5,
    "average_loss": -3644.8
  },
  {
    "session": "NewYork",
    "number_of_trades": 11,
    "net_profit": 25641.0,
    "win_rate": 0.6363636363636364,
    "profit_factor": 4.336065573770492,
    "expectancy": 2331.0,
    "average_win": 4761.0,
    "average_loss": -1921.5
  },
  {
    "session": "Tokyo",
    "number_of_trades": 9,
    "net_profit": -7319.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.596415770609319,
    "expectancy": -813.2222222222222,
    "average_win": 3605.3333333333335,
    "average_loss": -3627.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 5,
    "net_profit": -1088.0,
    "win_rate": 0.4,
    "profit_factor": 0.8991565483362685,
    "expectancy": -217.6,
    "average_win": 4850.5,
    "average_loss": -3596.3333333333335
  },
  {
    "weekday": "Mon",
    "number_of_trades": 5,
    "net_profit": 3524.0,
    "win_rate": 0.6,
    "profit_factor": 1.4818156959256221,
    "expectancy": 704.8,
    "average_win": 3612.6666666666665,
    "average_loss": -3657.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 10,
    "net_profit": 25964.0,
    "win_rate": 0.5,
    "profit_factor": 3.2083864931530153,
    "expectancy": 2596.4,
    "average_win": 7544.2,
    "average_loss": -2939.25
  },
  {
    "weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": -14482.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3620.5,
    "average_win": null,
    "average_loss": -3620.5
  },
  {
    "weekday": "Wed",
    "number_of_trades": 10,
    "net_profit": -12927.0,
    "win_rate": 0.2,
    "profit_factor": 0.2744569792894427,
    "expectancy": -1292.7,
    "average_win": 2445.0,
    "average_loss": -2969.5
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_-0.000161-0.00171",
    "number_of_trades": 12,
    "net_profit": -10229.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.6489343446476988,
    "expectancy": -852.4166666666666,
    "average_win": 9454.0,
    "average_loss": -3642.125
  },
  {
    "atr_band": "ATR_0.00171-0.00223",
    "number_of_trades": 10,
    "net_profit": -7680.0,
    "win_rate": 0.3,
    "profit_factor": 0.6501935777727169,
    "expectancy": -768.0,
    "average_win": 4758.333333333333,
    "average_loss": -3659.1666666666665
  },
  {
    "atr_band": "ATR_0.00223-0.00303",
    "number_of_trades": 12,
    "net_profit": 18900.0,
    "win_rate": 0.5833333333333334,
    "profit_factor": 2.707779886148008,
    "expectancy": 1575.0,
    "average_win": 4281.0,
    "average_loss": -2213.4
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.04-41.43",
    "number_of_trades": 12,
    "net_profit": -2508.0,
    "win_rate": 0.25,
    "profit_factor": 0.8850543104633576,
    "expectancy": -209.0,
    "average_win": 6437.0,
    "average_loss": -3117.0
  },
  {
    "adx_band": "ADX_41.43-48.25",
    "number_of_trades": 11,
    "net_profit": 28204.0,
    "win_rate": 0.5454545454545454,
    "profit_factor": 2.9627000695894226,
    "expectancy": 2564.0,
    "average_win": 7095.666666666667,
    "average_loss": -3592.5
  },
  {
    "adx_band": "ADX_48.25-69.24",
    "number_of_trades": 11,
    "net_profit": -24705.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.048710050057758955,
    "expectancy": -2245.909090909091,
    "average_win": 421.6666666666667,
    "average_loss": -3246.25
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.23-3.066",
    "number_of_trades": 12,
    "net_profit": -26891.0,
    "win_rate": 0.08333333333333333,
    "profit_factor": 0.2585270355970993,
    "expectancy": -2240.9166666666665,
    "average_win": 9376.0,
    "average_loss": -3626.7
  },
  {
    "hold_time_band": "HOLD_H_15.93-114.2",
    "number_of_trades": 12,
    "net_profit": 40028.0,
    "win_rate": 0.8333333333333334,
    "profit_factor": 10.7273390036452,
    "expectancy": 3335.6666666666665,
    "average_win": 4414.3,
    "average_loss": -2057.5
  },
  {
    "hold_time_band": "HOLD_H_3.066-15.93",
    "number_of_trades": 10,
    "net_profit": -12146.0,
    "win_rate": 0.1,
    "profit_factor": 0.44225559076089455,
    "expectancy": -1214.6,
    "average_win": 9631.0,
    "average_loss": -3111.0
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-104-2161",
    "number_of_trades": 11,
    "net_profit": -36730.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3339.090909090909,
    "average_win": null,
    "average_loss": -3339.090909090909
  },
  {
    "mfe_band": "MFE_2161-6150",
    "number_of_trades": 11,
    "net_profit": -24187.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.04846768165545458,
    "expectancy": -2198.818181818182,
    "average_win": 410.6666666666667,
    "average_loss": -3631.285714285714
  },
  {
    "mfe_band": "MFE_6150-9622",
    "number_of_trades": 12,
    "net_profit": 61908.0,
    "win_rate": 0.75,
    "profit_factor": 6191.8,
    "expectancy": 5159.0,
    "average_win": 6879.777777777777,
    "average_loss": -10.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2458--362",
    "number_of_trades": 12,
    "net_profit": 57043.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 5705.3,
    "expectancy": 4753.583333333333,
    "average_win": 7131.625,
    "average_loss": -10.0
  },
  {
    "mae_band": "MAE_-3603--2458",
    "number_of_trades": 10,
    "net_profit": -11770.0,
    "win_rate": 0.4,
    "profit_factor": 0.3412436335143001,
    "expectancy": -1177.0,
    "average_win": 1524.25,
    "average_loss": -2977.8333333333335
  },
  {
    "mae_band": "MAE_-3762--3603",
    "number_of_trades": 12,
    "net_profit": -44282.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3690.1666666666665,
    "average_win": null,
    "average_loss": -3690.1666666666665
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 23,
    "net_profit": 21997.0,
    "win_rate": 0.43478260869565216,
    "profit_factor": 1.6069477401909387,
    "expectancy": 956.3913043478261,
    "average_win": 5823.9,
    "average_loss": -3020.1666666666665
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 11,
    "net_profit": -21006.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.18948952425049195,
    "expectancy": -1909.6363636363637,
    "average_win": 2455.5,
    "average_loss": -3702.4285714285716
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 6,
    "net_profit": 5408.0,
    "win_rate": 0.5,
    "profit_factor": 2.2562137049941926,
    "expectancy": 901.3333333333334,
    "average_win": 3237.6666666666665,
    "average_loss": -1435.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 4,
    "net_profit": -10961.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2740.25,
    "average_win": null,
    "average_loss": -3653.6666666666665
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 24,
    "net_profit": 6544.0,
    "win_rate": 0.375,
    "profit_factor": 1.1395517454630755,
    "expectancy": 272.6666666666667,
    "average_win": 5937.444444444444,
    "average_loss": -3607.153846153846
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 20,
    "net_profit": -56135.0,
    "win_rate": 0.1,
    "profit_factor": 0.09676744597660461,
    "expectancy": -2806.75,
    "average_win": 3007.0,
    "average_loss": -3452.722222222222
  },
  {
    "close_reason": "SL",
    "number_of_trades": 8,
    "net_profit": 156.0,
    "win_rate": 0.5,
    "profit_factor": 16.6,
    "expectancy": 19.5,
    "average_win": 41.5,
    "average_loss": -10.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 6,
    "net_profit": 56970.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9495.0,
    "average_win": 9495.0,
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
    "net_profit": -14850.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.41780687654369386,
    "expectancy": -1237.5,
    "average_win": 2664.25,
    "average_loss": -3643.8571428571427
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 9,
    "net_profit": -3450.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.8439125910509886,
    "expectancy": -383.3333333333333,
    "average_win": 9326.5,
    "average_loss": -3157.5714285714284
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 8,
    "net_profit": -1153.0,
    "win_rate": 0.25,
    "profit_factor": 0.893319763138416,
    "expectancy": -144.125,
    "average_win": 4827.5,
    "average_loss": -2702.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 5,
    "net_profit": 20444.0,
    "win_rate": 0.8,
    "profit_factor": 6.464848970863406,
    "expectancy": 4088.8,
    "average_win": 6046.25,
    "average_loss": -3741.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 6,
    "net_profit": -2104.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.8155356829738734,
    "expectancy": -350.6666666666667,
    "average_win": 4651.0,
    "average_loss": -2851.5
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 5,
    "net_profit": 21385.0,
    "win_rate": 0.6,
    "profit_factor": 3.9238446814328687,
    "expectancy": 4277.0,
    "average_win": 9566.333333333334,
    "average_loss": -3657.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 8,
    "net_profit": -372.0,
    "win_rate": 0.375,
    "profit_factor": 0.9745866921710616,
    "expectancy": -46.5,
    "average_win": 4755.333333333333,
    "average_loss": -3659.5
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 6,
    "net_profit": -1454.0,
    "win_rate": 0.5,
    "profit_factor": 0.8698997852541159,
    "expectancy": -242.33333333333334,
    "average_win": 3240.6666666666665,
    "average_loss": -3725.3333333333335
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 9,
    "net_profit": -16464.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.06587234042553192,
    "expectancy": -1829.3333333333333,
    "average_win": 1161.0,
    "average_loss": -2937.5
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0341-0.995",
    "number_of_trades": 11,
    "net_profit": 63125.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 5738.636363636364,
    "average_win": 5738.636363636364,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.995-2.36",
    "number_of_trades": 11,
    "net_profit": -18602.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.0013421377570193805,
    "expectancy": -1691.090909090909,
    "average_win": 25.0,
    "average_loss": -2661.0
  },
  {
    "giveback_band": "GIVEBACK_2.36-34.48",
    "number_of_trades": 11,
    "net_profit": -40007.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3637.0,
    "average_win": null,
    "average_loss": -3637.0
  }
]
```

## time_stop_reason_code別

```json
[
  {
    "time_stop_reason_code": "MAX_HOLDING_BARS_MIN_MFE_NOT_REACHED",
    "number_of_trades": 1,
    "net_profit": -617.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -617.0,
    "average_win": null,
    "average_loss": -617.0
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
