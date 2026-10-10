# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 21
- MFEデータのある負けトレード数: 21
- うち一度含み益になった数: 18
- 割合: 85.71%
- 反転前の平均含み益: 3035.17

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 27
- 平均Giveback比率: 381.16%
- 中央値Giveback比率: 179.25%
- 損益ゼロ以下まで完全反転した割合: 74.07%

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
- 純損益: -65832.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3872.47
- 平均逆行幅（R）: 0.7847
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 16,
    "net_profit": -62108.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3881.75,
    "average_win": null,
    "average_loss": -3881.75
  },
  "SELL": {
    "number_of_trades": 1,
    "net_profit": -3724.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3724.0,
    "average_win": null,
    "average_loss": -3724.0
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 5894
- 最終Entry候補まで到達: 61
- Stage別棄却数（market_regime）: 4555
- Stage別棄却数（htf_bias）: 299
- Stage別棄却数（trend_strength_or_momentum_filter）: 624
- Stage別棄却数（setup_or_trigger）: 355
- Stage別棄却数（other）: 0

```json
{
  "ENTRY_PATTERN_NOT_FOUND": 355,
  "REGIME_NOT_TRENDING": 4555,
  "RSI_FILTERED": 602,
  "TREND_NOT_ALIGNED": 299,
  "CONFIRMATION_ADX_TOO_LOW": 22
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 28,
    "net_profit": -5089.0,
    "win_rate": 0.25,
    "profit_factor": 0.9181648602579359,
    "expectancy": -181.75,
    "average_win": 8156.714285714285,
    "average_loss": -3109.3
  },
  {
    "direction": "SELL",
    "number_of_trades": 2,
    "net_profit": -3724.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1862.0,
    "average_win": null,
    "average_loss": -3724.0
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 5,
    "net_profit": -19162.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3832.4,
    "average_win": null,
    "average_loss": -3832.4
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 3,
    "net_profit": 2980.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.8002148227712138,
    "expectancy": 993.3333333333334,
    "average_win": 6704.0,
    "average_loss": -3724.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 6,
    "net_profit": -3440.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.7139531016131715,
    "expectancy": -573.3333333333334,
    "average_win": 8586.0,
    "average_loss": -3006.5
  },
  {
    "session": "Tokyo",
    "number_of_trades": 16,
    "net_profit": 10809.0,
    "win_rate": 0.3125,
    "profit_factor": 1.3486999161236208,
    "expectancy": 675.5625,
    "average_win": 8361.4,
    "average_loss": -2818.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 6,
    "net_profit": 9190.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 3.272502472799209,
    "expectancy": 1531.6666666666667,
    "average_win": 6617.0,
    "average_loss": -1348.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": 13148.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.088951465959914,
    "expectancy": 1878.2857142857142,
    "average_win": 8407.333333333334,
    "average_loss": -3018.5
  },
  {
    "weekday": "Thu",
    "number_of_trades": 9,
    "net_profit": -17203.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.3474071545085543,
    "expectancy": -1911.4444444444443,
    "average_win": 9158.0,
    "average_loss": -3765.8571428571427
  },
  {
    "weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": -2324.0,
    "win_rate": 0.25,
    "profit_factor": 0.8031676124333023,
    "expectancy": -581.0,
    "average_win": 9483.0,
    "average_loss": -3935.6666666666665
  },
  {
    "weekday": "Wed",
    "number_of_trades": 4,
    "net_profit": -11624.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2906.0,
    "average_win": null,
    "average_loss": -2906.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_42.14-63.88",
    "number_of_trades": 10,
    "net_profit": -5173.0,
    "win_rate": 0.3,
    "profit_factor": 0.7798442354343108,
    "expectancy": -517.3,
    "average_win": 6108.0,
    "average_loss": -3916.1666666666665
  },
  {
    "atr_band": "ATR_63.88-93.41",
    "number_of_trades": 10,
    "net_profit": -13829.0,
    "win_rate": 0.1,
    "profit_factor": 0.40678620452985587,
    "expectancy": -1382.9,
    "average_win": 9483.0,
    "average_loss": -2914.0
  },
  {
    "atr_band": "ATR_93.41-125.1",
    "number_of_trades": 10,
    "net_profit": 10189.0,
    "win_rate": 0.3,
    "profit_factor": 1.5334275692372128,
    "expectancy": 1018.9,
    "average_win": 9763.333333333334,
    "average_loss": -2728.714285714286
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.16-42.04",
    "number_of_trades": 10,
    "net_profit": -3946.0,
    "win_rate": 0.2,
    "profit_factor": 0.7464987793909803,
    "expectancy": -394.6,
    "average_win": 5810.0,
    "average_loss": -2594.3333333333335
  },
  {
    "adx_band": "ADX_42.04-43.33",
    "number_of_trades": 10,
    "net_profit": -3560.0,
    "win_rate": 0.2,
    "profit_factor": 0.8446635832097041,
    "expectancy": -356.0,
    "average_win": 9679.0,
    "average_loss": -2864.75
  },
  {
    "adx_band": "ADX_43.33-52.83",
    "number_of_trades": 10,
    "net_profit": -1307.0,
    "win_rate": 0.3,
    "profit_factor": 0.9523444906293298,
    "expectancy": -130.7,
    "average_win": 8706.333333333334,
    "average_loss": -3918.0
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.387-5.625",
    "number_of_trades": 10,
    "net_profit": -38520.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3852.0,
    "average_win": null,
    "average_loss": -3852.0
  },
  {
    "hold_time_band": "HOLD_H_16.46-91",
    "number_of_trades": 10,
    "net_profit": 21994.0,
    "win_rate": 0.3,
    "profit_factor": 6.406588003933137,
    "expectancy": 2199.4,
    "average_win": 8687.333333333334,
    "average_loss": -813.6
  },
  {
    "hold_time_band": "HOLD_H_5.625-16.46",
    "number_of_trades": 10,
    "net_profit": 7713.0,
    "win_rate": 0.4,
    "profit_factor": 1.3307177772060714,
    "expectancy": 771.3,
    "average_win": 7758.75,
    "average_loss": -3887.0
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-180-1273",
    "number_of_trades": 10,
    "net_profit": -38692.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3869.2,
    "average_win": null,
    "average_loss": -3869.2
  },
  {
    "mfe_band": "MFE_1273-6827",
    "number_of_trades": 10,
    "net_profit": -24118.0,
    "win_rate": 0.1,
    "profit_factor": 0.11174130819092516,
    "expectancy": -2411.8,
    "average_win": 3034.0,
    "average_loss": -3394.0
  },
  {
    "mfe_band": "MFE_6827-1.01e+04",
    "number_of_trades": 10,
    "net_profit": 53997.0,
    "win_rate": 0.6,
    "profit_factor": 819.1363636363636,
    "expectancy": 5399.7,
    "average_win": 9010.5,
    "average_loss": -22.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2987--504",
    "number_of_trades": 10,
    "net_profit": 50327.0,
    "win_rate": 0.6,
    "profit_factor": 763.530303030303,
    "expectancy": 5032.7,
    "average_win": 8398.833333333334,
    "average_loss": -22.0
  },
  {
    "mae_band": "MAE_-3867--2987",
    "number_of_trades": 10,
    "net_profit": -19659.0,
    "win_rate": 0.1,
    "profit_factor": 0.25429579334673597,
    "expectancy": -1965.9,
    "average_win": 6704.0,
    "average_loss": -3295.375
  },
  {
    "mae_band": "MAE_-4160--3867",
    "number_of_trades": 10,
    "net_profit": -39481.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3948.1,
    "average_win": null,
    "average_loss": -3948.1
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 5,
    "net_profit": -11716.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2343.2,
    "average_win": null,
    "average_loss": -2929.0
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 25,
    "net_profit": 2903.0,
    "win_rate": 0.28,
    "profit_factor": 1.0535668155146327,
    "expectancy": 116.12,
    "average_win": 8156.714285714285,
    "average_loss": -3187.8823529411766
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 1,
    "net_profit": -3696.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3696.0,
    "average_win": null,
    "average_loss": -3696.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 1,
    "net_profit": -4160.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -4160.0,
    "average_win": null,
    "average_loss": -4160.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 28,
    "net_profit": -957.0,
    "win_rate": 0.25,
    "profit_factor": 0.9835153477796534,
    "expectancy": -34.17857142857143,
    "average_win": 8156.714285714285,
    "average_loss": -3055.4736842105262
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 19,
    "net_profit": -56094.0,
    "win_rate": 0.10526315789473684,
    "profit_factor": 0.1479219832300401,
    "expectancy": -2952.315789473684,
    "average_win": 4869.0,
    "average_loss": -3872.470588235294
  },
  {
    "close_reason": "SL",
    "number_of_trades": 6,
    "net_profit": -78.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -13.0,
    "average_win": null,
    "average_loss": -19.5
  },
  {
    "close_reason": "TP",
    "number_of_trades": 5,
    "net_profit": 47359.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9471.8,
    "average_win": 9471.8,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 5,
    "net_profit": 24729.0,
    "win_rate": 0.6,
    "profit_factor": 7.433142559833507,
    "expectancy": 4945.8,
    "average_win": 9524.333333333334,
    "average_loss": -1922.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 2,
    "net_profit": 2980.0,
    "win_rate": 0.5,
    "profit_factor": 1.8002148227712138,
    "expectancy": 1490.0,
    "average_win": 6704.0,
    "average_loss": -3724.0
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 7,
    "net_profit": -12424.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.19627377409755467,
    "expectancy": -1774.857142857143,
    "average_win": 3034.0,
    "average_loss": -3091.6
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 16,
    "net_profit": -24098.0,
    "win_rate": 0.125,
    "profit_factor": 0.4380654789665143,
    "expectancy": -1506.125,
    "average_win": 9393.0,
    "average_loss": -3298.769230769231
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 6,
    "net_profit": 843.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.0742796722178165,
    "expectancy": 140.5,
    "average_win": 6096.0,
    "average_loss": -3783.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 5,
    "net_profit": -1960.0,
    "win_rate": 0.2,
    "profit_factor": 0.8351833165153044,
    "expectancy": -392.0,
    "average_win": 9932.0,
    "average_loss": -3964.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 5,
    "net_profit": -18782.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3756.4,
    "average_win": null,
    "average_loss": -3756.4
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 9,
    "net_profit": 26929.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 4.347712580805569,
    "expectancy": 2992.1111111111113,
    "average_win": 8743.25,
    "average_loss": -1608.8
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": -15843.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3168.6,
    "average_win": null,
    "average_loss": -3168.6
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0261-1.001",
    "number_of_trades": 9,
    "net_profit": 57097.0,
    "win_rate": 0.7777777777777778,
    "profit_factor": null,
    "expectancy": 6344.111111111111,
    "average_win": 8156.714285714285,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1.001-3.167",
    "number_of_trades": 9,
    "net_profit": -19152.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2128.0,
    "average_win": null,
    "average_loss": -2128.0
  },
  {
    "giveback_band": "GIVEBACK_3.167-30.6",
    "number_of_trades": 9,
    "net_profit": -35249.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3916.5555555555557,
    "average_win": null,
    "average_loss": -3916.5555555555557
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
