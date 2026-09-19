# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 21
- MFEデータのある負けトレード数: 21
- うち一度含み益になった数: 19
- 割合: 90.48%
- 反転前の平均含み益: 2474.84

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 28
- 平均Giveback比率: 597.17%
- 中央値Giveback比率: 301.03%
- 損益ゼロ以下まで完全反転した割合: 75.00%

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

- 決済件数: 18
- 純損益: -68221.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3790.06
- 平均逆行幅（R）: 0.7798
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 7,
    "net_profit": -26345.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3763.5714285714284,
    "average_win": null,
    "average_loss": -3763.5714285714284
  },
  "SELL": {
    "number_of_trades": 11,
    "net_profit": -41876.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3806.909090909091,
    "average_win": null,
    "average_loss": -3806.909090909091
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 5911
- 最終Entry候補まで到達: 47
- Stage別棄却数（market_regime）: 4698
- Stage別棄却数（htf_bias）: 220
- Stage別棄却数（trend_strength_or_momentum_filter）: 598
- Stage別棄却数（setup_or_trigger）: 348
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 4698,
  "ENTRY_PATTERN_NOT_FOUND": 348,
  "RSI_FILTERED": 535,
  "CONFIRMATION_ADX_TOO_LOW": 63,
  "TREND_NOT_ALIGNED": 220
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 11,
    "net_profit": -4964.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.8121760187672632,
    "expectancy": -451.27272727272725,
    "average_win": 7155.0,
    "average_loss": -3303.625
  },
  {
    "direction": "SELL",
    "number_of_trades": 19,
    "net_profit": -11033.0,
    "win_rate": 0.21052631578947367,
    "profit_factor": 0.7371405427298502,
    "expectancy": -580.6842105263158,
    "average_win": 7735.0,
    "average_loss": -3228.6923076923076
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 9,
    "net_profit": -22630.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2514.4444444444443,
    "average_win": null,
    "average_loss": -2828.75
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 2,
    "net_profit": 5982.0,
    "win_rate": 0.5,
    "profit_factor": 2.6003210272873196,
    "expectancy": 2991.0,
    "average_win": 9720.0,
    "average_loss": -3738.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 4,
    "net_profit": -7915.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1978.75,
    "average_win": null,
    "average_loss": -2638.3333333333335
  },
  {
    "session": "Tokyo",
    "number_of_trades": 15,
    "net_profit": 8566.0,
    "win_rate": 0.4,
    "profit_factor": 1.25106245786805,
    "expectancy": 571.0666666666667,
    "average_win": 7114.166666666667,
    "average_loss": -3791.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 6,
    "net_profit": 3444.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2247454972592013,
    "expectancy": 574.0,
    "average_win": 9384.0,
    "average_loss": -3831.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 5,
    "net_profit": -8760.0,
    "win_rate": 0.2,
    "profit_factor": 0.23076923076923078,
    "expectancy": -1752.0,
    "average_win": 2628.0,
    "average_loss": -2847.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 8,
    "net_profit": 6704.0,
    "win_rate": 0.375,
    "profit_factor": 1.4493899986593377,
    "expectancy": 838.0,
    "average_win": 7207.333333333333,
    "average_loss": -3729.5
  },
  {
    "weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": -11605.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2901.25,
    "average_win": null,
    "average_loss": -2901.25
  },
  {
    "weekday": "Wed",
    "number_of_trades": 7,
    "net_profit": -5780.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.6189094745170436,
    "expectancy": -825.7142857142857,
    "average_win": 9387.0,
    "average_loss": -3033.4
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_44.64-67.14",
    "number_of_trades": 10,
    "net_profit": 1392.0,
    "win_rate": 0.3,
    "profit_factor": 1.0520121062661136,
    "expectancy": 139.2,
    "average_win": 9385.0,
    "average_loss": -3823.285714285714
  },
  {
    "atr_band": "ATR_67.14-95.62",
    "number_of_trades": 10,
    "net_profit": -6775.0,
    "win_rate": 0.2,
    "profit_factor": 0.6406407468307431,
    "expectancy": -677.5,
    "average_win": 6039.0,
    "average_loss": -3142.1666666666665
  },
  {
    "atr_band": "ATR_95.62-140.1",
    "number_of_trades": 10,
    "net_profit": -10614.0,
    "win_rate": 0.2,
    "profit_factor": 0.5341876590889142,
    "expectancy": -1061.4,
    "average_win": 6086.0,
    "average_loss": -2848.25
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.3-42.56",
    "number_of_trades": 10,
    "net_profit": -3655.0,
    "win_rate": 0.2,
    "profit_factor": 0.83986856516977,
    "expectancy": -365.5,
    "average_win": 9585.0,
    "average_loss": -2853.125
  },
  {
    "adx_band": "ADX_42.56-46.66",
    "number_of_trades": 10,
    "net_profit": -8245.0,
    "win_rate": 0.2,
    "profit_factor": 0.6897693494374836,
    "expectancy": -824.5,
    "average_win": 9166.0,
    "average_loss": -3796.714285714286
  },
  {
    "adx_band": "ADX_46.66-60.6",
    "number_of_trades": 10,
    "net_profit": -4097.0,
    "win_rate": 0.3,
    "profit_factor": 0.7843684210526316,
    "expectancy": -409.7,
    "average_win": 4967.666666666667,
    "average_loss": -3166.6666666666665
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.00678-3.371",
    "number_of_trades": 10,
    "net_profit": -38350.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3835.0,
    "average_win": null,
    "average_loss": -3835.0
  },
  {
    "hold_time_band": "HOLD_H_3.371-8.034",
    "number_of_trades": 10,
    "net_profit": 2318.0,
    "win_rate": 0.3,
    "profit_factor": 1.0886899295990204,
    "expectancy": 231.8,
    "average_win": 9484.666666666666,
    "average_loss": -3733.714285714286
  },
  {
    "hold_time_band": "HOLD_H_8.034-50",
    "number_of_trades": 10,
    "net_profit": 20035.0,
    "win_rate": 0.4,
    "profit_factor": 6.116189989785496,
    "expectancy": 2003.5,
    "average_win": 5987.75,
    "average_loss": -979.0
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-736-1381",
    "number_of_trades": 10,
    "net_profit": -38026.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3802.6,
    "average_win": null,
    "average_loss": -3802.6
  },
  {
    "mfe_band": "MFE_1381-6297",
    "number_of_trades": 10,
    "net_profit": -27307.0,
    "win_rate": 0.1,
    "profit_factor": 0.09564497433349893,
    "expectancy": -2730.7,
    "average_win": 2888.0,
    "average_loss": -3774.375
  },
  {
    "mfe_band": "MFE_6297-1.003e+04",
    "number_of_trades": 10,
    "net_profit": 49336.0,
    "win_rate": 0.6,
    "profit_factor": 273.57458563535914,
    "expectancy": 4933.6,
    "average_win": 8252.833333333334,
    "average_loss": -60.333333333333336
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-3259--180",
    "number_of_trades": 10,
    "net_profit": 49618.0,
    "win_rate": 0.6,
    "profit_factor": 313.062893081761,
    "expectancy": 4961.8,
    "average_win": 8296.166666666666,
    "average_loss": -79.5
  },
  {
    "mae_band": "MAE_-3789--3259",
    "number_of_trades": 10,
    "net_profit": -27057.0,
    "win_rate": 0.1,
    "profit_factor": 0.08852956038403234,
    "expectancy": -2705.7,
    "average_win": 2628.0,
    "average_loss": -3298.3333333333335
  },
  {
    "mae_band": "MAE_-4048--3789",
    "number_of_trades": 10,
    "net_profit": -38558.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3855.8,
    "average_win": null,
    "average_loss": -3855.8
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 15,
    "net_profit": -15071.0,
    "win_rate": 0.13333333333333333,
    "profit_factor": 0.5577109317681584,
    "expectancy": -1004.7333333333333,
    "average_win": 9502.0,
    "average_loss": -3097.7272727272725
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 15,
    "net_profit": -926.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.9730241500859382,
    "expectancy": -61.733333333333334,
    "average_win": 6680.2,
    "average_loss": -3432.7
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 4,
    "net_profit": -1680.0,
    "win_rate": 0.25,
    "profit_factor": 0.8526315789473684,
    "expectancy": -420.0,
    "average_win": 9720.0,
    "average_loss": -3800.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 26,
    "net_profit": -14317.0,
    "win_rate": 0.23076923076923078,
    "profit_factor": 0.7488333742675696,
    "expectancy": -550.6538461538462,
    "average_win": 7114.166666666667,
    "average_loss": -3166.777777777778
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 20,
    "net_profit": -62705.0,
    "win_rate": 0.1,
    "profit_factor": 0.08085486873543338,
    "expectancy": -3135.25,
    "average_win": 2758.0,
    "average_loss": -3790.0555555555557
  },
  {
    "close_reason": "SL",
    "number_of_trades": 5,
    "net_profit": -181.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -36.2,
    "average_win": null,
    "average_loss": -60.333333333333336
  },
  {
    "close_reason": "TP",
    "number_of_trades": 5,
    "net_profit": 46889.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9377.8,
    "average_win": 9377.8,
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
    "net_profit": -26523.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3315.375,
    "average_win": null,
    "average_loss": -3315.375
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 6,
    "net_profit": -2925.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.8031760985128861,
    "expectancy": -487.5,
    "average_win": 5968.0,
    "average_loss": -3715.25
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 4,
    "net_profit": 1995.0,
    "win_rate": 0.25,
    "profit_factor": 1.258252427184466,
    "expectancy": 498.75,
    "average_win": 9720.0,
    "average_loss": -3862.5
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 12,
    "net_profit": 11456.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.5937904939615404,
    "expectancy": 954.6666666666666,
    "average_win": 7687.25,
    "average_loss": -2756.1428571428573
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 8,
    "net_profit": 22281.0,
    "win_rate": 0.5,
    "profit_factor": 2.4539937353171495,
    "expectancy": 2785.125,
    "average_win": 9401.25,
    "average_loss": -3831.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 3,
    "net_profit": -11366.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3788.6666666666665,
    "average_win": null,
    "average_loss": -3788.6666666666665
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 9,
    "net_profit": -2830.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.811358485535262,
    "expectancy": -314.44444444444446,
    "average_win": 6086.0,
    "average_loss": -3000.4
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": -11552.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2888.0,
    "average_win": null,
    "average_loss": -2888.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 6,
    "net_profit": -12530.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.17337379601530545,
    "expectancy": -2088.3333333333335,
    "average_win": 2628.0,
    "average_loss": -3031.6
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0199-1.002",
    "number_of_trades": 10,
    "net_profit": 52383.0,
    "win_rate": 0.7,
    "profit_factor": 2382.0454545454545,
    "expectancy": 5238.3,
    "average_win": 7486.428571428572,
    "average_loss": -22.0
  },
  {
    "giveback_band": "GIVEBACK_1.002-3.684",
    "number_of_trades": 8,
    "net_profit": -22679.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2834.875,
    "average_win": null,
    "average_loss": -2834.875
  },
  {
    "giveback_band": "GIVEBACK_3.684-69",
    "number_of_trades": 10,
    "net_profit": -37869.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3786.9,
    "average_win": null,
    "average_loss": -3786.9
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
