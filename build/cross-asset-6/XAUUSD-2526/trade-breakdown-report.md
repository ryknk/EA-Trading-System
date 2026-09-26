# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 18
- MFEデータのある負けトレード数: 18
- うち一度含み益になった数: 17
- 割合: 94.44%
- 反転前の平均含み益: 2255.24

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 30
- 平均Giveback比率: 311.46%
- 中央値Giveback比率: 100.34%
- 損益ゼロ以下まで完全反転した割合: 60.00%

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
- 純損益: -41217.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -2944.07
- 平均逆行幅（R）: 0.7656
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 13,
    "net_profit": -38011.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2923.923076923077,
    "average_win": null,
    "average_loss": -2923.923076923077
  },
  "SELL": {
    "number_of_trades": 1,
    "net_profit": -3206.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3206.0,
    "average_win": null,
    "average_loss": -3206.0
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 9811
- 最終Entry候補まで到達: 112
- Stage別棄却数（market_regime）: 7747
- Stage別棄却数（htf_bias）: 320
- Stage別棄却数（trend_strength_or_momentum_filter）: 802
- Stage別棄却数（setup_or_trigger）: 830
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 7747,
  "TREND_NOT_ALIGNED": 320,
  "ENTRY_PATTERN_NOT_FOUND": 830,
  "RSI_FILTERED": 747,
  "CONFIRMATION_ADX_TOO_LOW": 55
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 29,
    "net_profit": 30500.0,
    "win_rate": 0.3793103448275862,
    "profit_factor": 1.698020368463211,
    "expectancy": 1051.7241379310344,
    "average_win": 6745.0,
    "average_loss": -2570.294117647059
  },
  {
    "direction": "SELL",
    "number_of_trades": 2,
    "net_profit": 6388.0,
    "win_rate": 0.5,
    "profit_factor": 2.9925140361821585,
    "expectancy": 3194.0,
    "average_win": 9594.0,
    "average_loss": -3206.0
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 10,
    "net_profit": -2278.0,
    "win_rate": 0.3,
    "profit_factor": 0.9051939404028633,
    "expectancy": -227.8,
    "average_win": 7250.0,
    "average_loss": -3432.5714285714284
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": 9211.0,
    "win_rate": 0.375,
    "profit_factor": 1.7642080809756906,
    "expectancy": 1151.375,
    "average_win": 7088.0,
    "average_loss": -2410.6
  },
  {
    "session": "NewYork",
    "number_of_trades": 6,
    "net_profit": 21128.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 4.846349899872565,
    "expectancy": 3521.3333333333335,
    "average_win": 6655.25,
    "average_loss": -2746.5
  },
  {
    "session": "Tokyo",
    "number_of_trades": 7,
    "net_profit": 8827.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 2.657030223390276,
    "expectancy": 1261.0,
    "average_win": 7077.0,
    "average_loss": -1331.75
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 6,
    "net_profit": -16553.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2758.8333333333335,
    "average_win": null,
    "average_loss": -2758.8333333333335
  },
  {
    "weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": 17344.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 4.936450295052201,
    "expectancy": 2477.714285714286,
    "average_win": 7250.0,
    "average_loss": -1101.5
  },
  {
    "weekday": "Thu",
    "number_of_trades": 6,
    "net_profit": 25857.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 4.760471204188482,
    "expectancy": 4309.5,
    "average_win": 8183.25,
    "average_loss": -3438.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": 6792.0,
    "win_rate": 0.5,
    "profit_factor": 2.9994112452163675,
    "expectancy": 1698.0,
    "average_win": 5094.5,
    "average_loss": -1698.5
  },
  {
    "weekday": "Wed",
    "number_of_trades": 8,
    "net_profit": 3448.0,
    "win_rate": 0.375,
    "profit_factor": 1.2200523326313102,
    "expectancy": 431.0,
    "average_win": 6372.333333333333,
    "average_loss": -3917.25
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_11.43-17.11",
    "number_of_trades": 11,
    "net_profit": 24428.0,
    "win_rate": 0.45454545454545453,
    "profit_factor": 2.498190739037105,
    "expectancy": 2220.7272727272725,
    "average_win": 8146.6,
    "average_loss": -2717.5
  },
  {
    "atr_band": "ATR_4.448-6.614",
    "number_of_trades": 11,
    "net_profit": 873.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 1.0402731005212897,
    "expectancy": 79.36363636363636,
    "average_win": 7516.666666666667,
    "average_loss": -3096.714285714286
  },
  {
    "atr_band": "ATR_6.614-11.43",
    "number_of_trades": 9,
    "net_profit": 11587.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 2.29913667451508,
    "expectancy": 1287.4444444444443,
    "average_win": 5126.5,
    "average_loss": -1783.8
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.25-41.66",
    "number_of_trades": 11,
    "net_profit": 33431.0,
    "win_rate": 0.5454545454545454,
    "profit_factor": 5.15034140285537,
    "expectancy": 3039.181818181818,
    "average_win": 6914.333333333333,
    "average_loss": -1611.0
  },
  {
    "adx_band": "ADX_41.66-44.28",
    "number_of_trades": 9,
    "net_profit": -7698.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.6746132386507735,
    "expectancy": -855.3333333333334,
    "average_win": 7980.0,
    "average_loss": -3379.714285714286
  },
  {
    "adx_band": "ADX_44.28-65.96",
    "number_of_trades": 11,
    "net_profit": 11155.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 1.7344614169080854,
    "expectancy": 1014.0909090909091,
    "average_win": 6585.75,
    "average_loss": -2531.3333333333335
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.363-5.121",
    "number_of_trades": 11,
    "net_profit": -15768.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.4801872486318982,
    "expectancy": -1433.4545454545455,
    "average_win": 7283.0,
    "average_loss": -3370.4444444444443
  },
  {
    "hold_time_band": "HOLD_H_14.83-79.11",
    "number_of_trades": 11,
    "net_profit": 45971.0,
    "win_rate": 0.6363636363636364,
    "profit_factor": 9.359883615202763,
    "expectancy": 4179.181818181818,
    "average_win": 7352.857142857143,
    "average_loss": -1833.0
  },
  {
    "hold_time_band": "HOLD_H_5.121-14.83",
    "number_of_trades": 9,
    "net_profit": 6685.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.6039934947596675,
    "expectancy": 742.7777777777778,
    "average_win": 5917.666666666667,
    "average_loss": -1844.6666666666667
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-36-1697",
    "number_of_trades": 11,
    "net_profit": -31792.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2890.181818181818,
    "average_win": null,
    "average_loss": -2890.181818181818
  },
  {
    "mfe_band": "MFE_1697-6461",
    "number_of_trades": 9,
    "net_profit": -6070.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.5975601670755155,
    "expectancy": -674.4444444444445,
    "average_win": 4506.5,
    "average_loss": -2513.8333333333335
  },
  {
    "mfe_band": "MFE_6461-9673",
    "number_of_trades": 11,
    "net_profit": 74750.0,
    "win_rate": 0.9090909090909091,
    "profit_factor": 2876.0,
    "expectancy": 6795.454545454545,
    "average_win": 7477.6,
    "average_loss": -26.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1255--170",
    "number_of_trades": 11,
    "net_profit": 70876.0,
    "win_rate": 0.9090909090909091,
    "profit_factor": null,
    "expectancy": 6443.272727272727,
    "average_win": 7087.6,
    "average_loss": null
  },
  {
    "mae_band": "MAE_-2944--1255",
    "number_of_trades": 9,
    "net_profit": -1519.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.8947477827050998,
    "expectancy": -168.77777777777777,
    "average_win": 6456.5,
    "average_loss": -2061.714285714286
  },
  {
    "mae_band": "MAE_-4705--2944",
    "number_of_trades": 11,
    "net_profit": -32469.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2951.7272727272725,
    "average_win": null,
    "average_loss": -2951.7272727272725
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 4,
    "net_profit": 6543.0,
    "win_rate": 0.5,
    "profit_factor": 1.974385703648548,
    "expectancy": 1635.75,
    "average_win": 6629.0,
    "average_loss": -3357.5
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 27,
    "net_profit": 30345.0,
    "win_rate": 0.37037037037037035,
    "profit_factor": 1.7551137211964365,
    "expectancy": 1123.888888888889,
    "average_win": 7053.1,
    "average_loss": -2511.625
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": 5330.0,
    "win_rate": 0.5,
    "profit_factor": 281.5263157894737,
    "expectancy": 2665.0,
    "average_win": 5349.0,
    "average_loss": -19.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 29,
    "net_profit": 31558.0,
    "win_rate": 0.3793103448275862,
    "profit_factor": 1.6731368115694722,
    "expectancy": 1088.2068965517242,
    "average_win": 7130.909090909091,
    "average_loss": -2757.764705882353
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 16,
    "net_profit": -33954.0,
    "win_rate": 0.125,
    "profit_factor": 0.17621369823131233,
    "expectancy": -2122.125,
    "average_win": 3631.5,
    "average_loss": -2944.0714285714284
  },
  {
    "close_reason": "SL",
    "number_of_trades": 5,
    "net_profit": -5684.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1136.8,
    "average_win": null,
    "average_loss": -1421.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 10,
    "net_profit": 76526.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7652.6,
    "average_win": 7652.6,
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
    "net_profit": 9443.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.6544005544005544,
    "expectancy": 1049.2222222222222,
    "average_win": 7957.666666666667,
    "average_loss": -2886.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 13,
    "net_profit": -24556.0,
    "win_rate": 0.07692307692307693,
    "profit_factor": 0.24314994606256743,
    "expectancy": -1888.923076923077,
    "average_win": 7889.0,
    "average_loss": -2703.75
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 4,
    "net_profit": 18204.0,
    "win_rate": 0.75,
    "profit_factor": 701.1538461538462,
    "expectancy": 4551.0,
    "average_win": 6076.666666666667,
    "average_loss": -26.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 5,
    "net_profit": 33797.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 6759.4,
    "average_win": 6759.4,
    "average_loss": null
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 7,
    "net_profit": 4882.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.3382994941445499,
    "expectancy": 697.4285714285714,
    "average_win": 9656.5,
    "average_loss": -2886.2
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 5,
    "net_profit": 7398.0,
    "win_rate": 0.4,
    "profit_factor": 2.6639676113360324,
    "expectancy": 1479.6,
    "average_win": 5922.0,
    "average_loss": -1482.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 6,
    "net_profit": 12748.0,
    "win_rate": 0.5,
    "profit_factor": 2.853984874927283,
    "expectancy": 2124.6666666666665,
    "average_win": 6541.333333333333,
    "average_loss": -3438.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 7,
    "net_profit": 23336.0,
    "win_rate": 0.5714285714285714,
    "profit_factor": 12.070208728652752,
    "expectancy": 3333.714285714286,
    "average_win": 6361.0,
    "average_loss": -702.6666666666666
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 6,
    "net_profit": -11476.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.3972689075630252,
    "expectancy": -1912.6666666666667,
    "average_win": 7564.0,
    "average_loss": -3808.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0172-0.0971",
    "number_of_trades": 10,
    "net_profit": 76526.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7652.6,
    "average_win": 7652.6,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.0971-2.756",
    "number_of_trades": 10,
    "net_profit": -3857.0,
    "win_rate": 0.2,
    "profit_factor": 0.6531474820143884,
    "expectancy": -385.7,
    "average_win": 3631.5,
    "average_loss": -1588.5714285714287
  },
  {
    "giveback_band": "GIVEBACK_2.756-28.85",
    "number_of_trades": 10,
    "net_profit": -32837.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3283.7,
    "average_win": null,
    "average_loss": -3283.7
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
