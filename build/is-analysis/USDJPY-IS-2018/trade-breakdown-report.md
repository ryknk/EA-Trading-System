# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 14
- MFEデータのある負けトレード数: 14
- うち一度含み益になった数: 14
- 割合: 100.00%
- 反転前の平均含み益: 1794.50

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 23
- 平均Giveback比率: 416.89%
- 中央値Giveback比率: 219.66%
- 損益ゼロ以下まで完全反転した割合: 60.87%

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
- 純損益: -52898.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3778.43
- 平均逆行幅（R）: 0.7733
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 7,
    "net_profit": -26539.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3791.285714285714,
    "average_win": null,
    "average_loss": -3791.285714285714
  },
  "SELL": {
    "number_of_trades": 7,
    "net_profit": -26359.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3765.5714285714284,
    "average_win": null,
    "average_loss": -3765.5714285714284
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6194
- 最終Entry候補まで到達: 30
- Stage別棄却数（market_regime）: 5143
- Stage別棄却数（htf_bias）: 241
- Stage別棄却数（trend_strength_or_momentum_filter）: 493
- Stage別棄却数（setup_or_trigger）: 287
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5143,
  "RSI_FILTERED": 452,
  "TREND_NOT_ALIGNED": 241,
  "ENTRY_PATTERN_NOT_FOUND": 287,
  "CONFIRMATION_ADX_TOO_LOW": 41
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 14,
    "net_profit": 14794.0,
    "win_rate": 0.5,
    "profit_factor": 1.5574437620106258,
    "expectancy": 1056.7142857142858,
    "average_win": 5904.714285714285,
    "average_loss": -3791.285714285714
  },
  {
    "direction": "SELL",
    "number_of_trades": 9,
    "net_profit": -15719.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.4036571948859972,
    "expectancy": -1746.5555555555557,
    "average_win": 5320.0,
    "average_loss": -3765.5714285714284
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 3,
    "net_profit": 2382.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.3260333972077745,
    "expectancy": 794.0,
    "average_win": 9688.0,
    "average_loss": -3653.0
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 2,
    "net_profit": -7556.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3778.0,
    "average_win": null,
    "average_loss": -3778.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 8,
    "net_profit": 5510.0,
    "win_rate": 0.5,
    "profit_factor": 1.3564036222509703,
    "expectancy": 688.75,
    "average_win": 5242.5,
    "average_loss": -3865.0
  },
  {
    "session": "Tokyo",
    "number_of_trades": 10,
    "net_profit": -1261.0,
    "win_rate": 0.4,
    "profit_factor": 0.9441442239546421,
    "expectancy": -126.1,
    "average_win": 5328.75,
    "average_loss": -3762.6666666666665
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": -12154.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4051.3333333333335,
    "average_win": null,
    "average_loss": -4051.3333333333335
  },
  {
    "weekday": "Mon",
    "number_of_trades": 5,
    "net_profit": 15601.0,
    "win_rate": 0.6,
    "profit_factor": 3.014331826985152,
    "expectancy": 3120.2,
    "average_win": 7782.0,
    "average_loss": -3872.5
  },
  {
    "weekday": "Thu",
    "number_of_trades": 5,
    "net_profit": 10462.0,
    "win_rate": 0.6,
    "profit_factor": 2.479146048352891,
    "expectancy": 2092.4,
    "average_win": 5845.0,
    "average_loss": -3536.5
  },
  {
    "weekday": "Tue",
    "number_of_trades": 5,
    "net_profit": -9678.0,
    "win_rate": 0.4,
    "profit_factor": 0.12352834631407354,
    "expectancy": -1935.6,
    "average_win": 682.0,
    "average_loss": -3680.6666666666665
  },
  {
    "weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": -5156.0,
    "win_rate": 0.2,
    "profit_factor": 0.6535877452297769,
    "expectancy": -1031.2,
    "average_win": 9728.0,
    "average_loss": -3721.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.085-0.116",
    "number_of_trades": 8,
    "net_profit": 13827.0,
    "win_rate": 0.5,
    "profit_factor": 1.931424722128663,
    "expectancy": 1728.375,
    "average_win": 7168.0,
    "average_loss": -3711.25
  },
  {
    "atr_band": "ATR_0.116-0.146",
    "number_of_trades": 7,
    "net_profit": -7111.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.631935817805383,
    "expectancy": -1015.8571428571429,
    "average_win": 6104.5,
    "average_loss": -3864.0
  },
  {
    "atr_band": "ATR_0.146-0.214",
    "number_of_trades": 8,
    "net_profit": -7641.0,
    "win_rate": 0.375,
    "profit_factor": 0.5921101798964394,
    "expectancy": -955.125,
    "average_win": 3697.3333333333335,
    "average_loss": -3746.6
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.09-41.92",
    "number_of_trades": 8,
    "net_profit": 26821.0,
    "win_rate": 0.625,
    "profit_factor": 3.3408099144702392,
    "expectancy": 3352.625,
    "average_win": 7655.8,
    "average_loss": -3819.3333333333335
  },
  {
    "adx_band": "ADX_41.92-45.19",
    "number_of_trades": 7,
    "net_profit": -16818.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.07501924980750192,
    "expectancy": -2402.5714285714284,
    "average_win": 682.0,
    "average_loss": -3636.4
  },
  {
    "adx_band": "ADX_45.19-58.55",
    "number_of_trades": 8,
    "net_profit": -10928.0,
    "win_rate": 0.25,
    "profit_factor": 0.5301401668243185,
    "expectancy": -1366.0,
    "average_win": 6165.0,
    "average_loss": -3876.3333333333335
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.92-5.104",
    "number_of_trades": 8,
    "net_profit": -30365.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3795.625,
    "average_win": null,
    "average_loss": -3795.625
  },
  {
    "hold_time_band": "HOLD_H_11.76-35",
    "number_of_trades": 8,
    "net_profit": 28959.0,
    "win_rate": 0.875,
    "profit_factor": 9.04863813229572,
    "expectancy": 3619.875,
    "average_win": 4651.0,
    "average_loss": -3598.0
  },
  {
    "hold_time_band": "HOLD_H_5.104-11.76",
    "number_of_trades": 7,
    "net_profit": 481.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.0254026934248746,
    "expectancy": 68.71428571428571,
    "average_win": 9708.0,
    "average_loss": -3787.0
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_114-1694",
    "number_of_trades": 8,
    "net_profit": -29871.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3733.875,
    "average_win": null,
    "average_loss": -3733.875
  },
  {
    "mfe_band": "MFE_1694-4105",
    "number_of_trades": 7,
    "net_profit": -18065.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.07020433372793247,
    "expectancy": -2580.714285714286,
    "average_win": 682.0,
    "average_loss": -3885.8
  },
  {
    "mfe_band": "MFE_4105-9971",
    "number_of_trades": 8,
    "net_profit": 47011.0,
    "win_rate": 0.875,
    "profit_factor": 14.065869927737632,
    "expectancy": 5876.375,
    "average_win": 7229.857142857143,
    "average_loss": -3598.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-3279--132",
    "number_of_trades": 8,
    "net_profit": 42285.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 5285.625,
    "average_win": 5285.625,
    "average_loss": null
  },
  {
    "mae_band": "MAE_-3729--3279",
    "number_of_trades": 7,
    "net_profit": -11962.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.4474826789838337,
    "expectancy": -1708.857142857143,
    "average_win": 9688.0,
    "average_loss": -3608.3333333333335
  },
  {
    "mae_band": "MAE_-4338--3729",
    "number_of_trades": 8,
    "net_profit": -31248.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3906.0,
    "average_win": null,
    "average_loss": -3906.0
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 9,
    "net_profit": -7516.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.7200849130386205,
    "expectancy": -835.1111111111111,
    "average_win": 9667.5,
    "average_loss": -3835.8571428571427
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 14,
    "net_profit": 6591.0,
    "win_rate": 0.5,
    "profit_factor": 1.2530425768802549,
    "expectancy": 470.7857142857143,
    "average_win": 4662.571428571428,
    "average_loss": -3721.0
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 3,
    "net_profit": -2234.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 0.3790994997220678,
    "expectancy": -744.6666666666666,
    "average_win": 682.0,
    "average_loss": -3598.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 1,
    "net_profit": -3780.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3780.0,
    "average_win": null,
    "average_loss": -3780.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 19,
    "net_profit": 5089.0,
    "win_rate": 0.3684210526315789,
    "profit_factor": 1.1117970123022847,
    "expectancy": 267.8421052631579,
    "average_win": 7229.857142857143,
    "average_loss": -3793.3333333333335
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 19,
    "net_profit": -39947.0,
    "win_rate": 0.2631578947368421,
    "profit_factor": 0.244829672199327,
    "expectancy": -2102.4736842105262,
    "average_win": 2590.2,
    "average_loss": -3778.4285714285716
  },
  {
    "close_reason": "TP",
    "number_of_trades": 4,
    "net_profit": 39022.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9755.5,
    "average_win": 9755.5,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 7,
    "net_profit": 23006.0,
    "win_rate": 0.7142857142857143,
    "profit_factor": 3.9908996359854396,
    "expectancy": 3286.5714285714284,
    "average_win": 6139.6,
    "average_loss": -3846.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 3,
    "net_profit": 4318.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 2.1961218836565095,
    "expectancy": 1439.3333333333333,
    "average_win": 3964.0,
    "average_loss": -3610.0
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 5,
    "net_profit": -5902.0,
    "win_rate": 0.2,
    "profit_factor": 0.6214239897370109,
    "expectancy": -1180.4,
    "average_win": 9688.0,
    "average_loss": -3897.5
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 8,
    "net_profit": -22347.0,
    "win_rate": 0.125,
    "profit_factor": 0.14069830039221717,
    "expectancy": -2793.375,
    "average_win": 3659.0,
    "average_loss": -3715.1428571428573
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 7,
    "net_profit": 1883.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 1.120304114490161,
    "expectancy": 269.0,
    "average_win": 5845.0,
    "average_loss": -3913.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 2,
    "net_profit": 5992.0,
    "win_rate": 0.5,
    "profit_factor": 2.621212121212121,
    "expectancy": 2996.0,
    "average_win": 9688.0,
    "average_loss": -3696.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 1,
    "net_profit": -3575.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3575.0,
    "average_win": null,
    "average_loss": -3575.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 5,
    "net_profit": 2165.0,
    "win_rate": 0.4,
    "profit_factor": 1.1883755329330896,
    "expectancy": 433.0,
    "average_win": 6829.0,
    "average_loss": -3831.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 8,
    "net_profit": -7390.0,
    "win_rate": 0.375,
    "profit_factor": 0.600151498755546,
    "expectancy": -923.75,
    "average_win": 3697.3333333333335,
    "average_loss": -3696.4
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0277-0.669",
    "number_of_trades": 8,
    "net_profit": 51521.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 6440.125,
    "average_win": 6440.125,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.669-3.361",
    "number_of_trades": 7,
    "net_profit": -21889.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.020231860704534265,
    "expectancy": -3127.0,
    "average_win": 452.0,
    "average_loss": -3723.5
  },
  {
    "giveback_band": "GIVEBACK_3.361-32.67",
    "number_of_trades": 8,
    "net_profit": -30557.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3819.625,
    "average_win": null,
    "average_loss": -3819.625
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
