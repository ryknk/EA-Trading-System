# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 16
- MFEデータのある負けトレード数: 16
- うち一度含み益になった数: 14
- 割合: 87.50%
- 反転前の平均含み益: 1804.64

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 15
- 平均Giveback比率: 1743.05%
- 中央値Giveback比率: 332.89%
- 損益ゼロ以下まで完全反転した割合: 93.33%

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

- 決済件数: 12
- 純損益: -39090.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3257.50
- 平均逆行幅（R）: 0.7851
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 12,
    "net_profit": -39090.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3257.5,
    "average_win": null,
    "average_loss": -3257.5
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 4462
- 最終Entry候補まで到達: 25
- Stage別棄却数（market_regime）: 3543
- Stage別棄却数（htf_bias）: 532
- Stage別棄却数（trend_strength_or_momentum_filter）: 200
- Stage別棄却数（setup_or_trigger）: 162
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 3543,
  "TREND_NOT_ALIGNED": 532,
  "RSI_FILTERED": 184,
  "ENTRY_PATTERN_NOT_FOUND": 162,
  "CONFIRMATION_ADX_TOO_LOW": 16
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 16,
    "net_profit": -39776.0,
    "win_rate": 0.0625,
    "profit_factor": 0.003931585405554303,
    "expectancy": -2486.0,
    "average_win": 157.0,
    "average_loss": -2662.2
  },
  {
    "direction": "SELL",
    "number_of_trades": 1,
    "net_profit": -14.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -14.0,
    "average_win": null,
    "average_loss": -14.0
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 4,
    "net_profit": -12072.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3018.0,
    "average_win": null,
    "average_loss": -3018.0
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 4,
    "net_profit": -10877.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2719.25,
    "average_win": null,
    "average_loss": -2719.25
  },
  {
    "session": "NewYork",
    "number_of_trades": 4,
    "net_profit": -12681.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3170.25,
    "average_win": null,
    "average_loss": -3170.25
  },
  {
    "session": "Tokyo",
    "number_of_trades": 5,
    "net_profit": -4160.0,
    "win_rate": 0.2,
    "profit_factor": 0.03636784804262219,
    "expectancy": -832.0,
    "average_win": 157.0,
    "average_loss": -1079.25
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 1,
    "net_profit": -7.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -7.0,
    "average_win": null,
    "average_loss": -7.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 4,
    "net_profit": -9715.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2428.75,
    "average_win": null,
    "average_loss": -2428.75
  },
  {
    "weekday": "Thu",
    "number_of_trades": 5,
    "net_profit": -9486.0,
    "win_rate": 0.2,
    "profit_factor": 0.01628124027792181,
    "expectancy": -1897.2,
    "average_win": 157.0,
    "average_loss": -2410.75
  },
  {
    "weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": -10795.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2698.75,
    "average_win": null,
    "average_loss": -2698.75
  },
  {
    "weekday": "Wed",
    "number_of_trades": 3,
    "net_profit": -9787.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3262.3333333333335,
    "average_win": null,
    "average_loss": -3262.3333333333335
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_2.771-4.6",
    "number_of_trades": 6,
    "net_profit": -20200.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3366.6666666666665,
    "average_win": null,
    "average_loss": -3366.6666666666665
  },
  {
    "atr_band": "ATR_4.6-6.841",
    "number_of_trades": 5,
    "net_profit": -10672.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2134.4,
    "average_win": null,
    "average_loss": -2134.4
  },
  {
    "atr_band": "ATR_6.841-13.19",
    "number_of_trades": 6,
    "net_profit": -8918.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.017300275482093664,
    "expectancy": -1486.3333333333333,
    "average_win": 157.0,
    "average_loss": -1815.0
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.05-40.84",
    "number_of_trades": 6,
    "net_profit": -9988.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1664.6666666666667,
    "average_win": null,
    "average_loss": -1664.6666666666667
  },
  {
    "adx_band": "ADX_40.84-45.24",
    "number_of_trades": 5,
    "net_profit": -16690.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3338.0,
    "average_win": null,
    "average_loss": -3338.0
  },
  {
    "adx_band": "ADX_45.24-53.74",
    "number_of_trades": 6,
    "net_profit": -13112.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.011832089833446378,
    "expectancy": -2185.3333333333335,
    "average_win": 157.0,
    "average_loss": -2653.8
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.272-2.136",
    "number_of_trades": 6,
    "net_profit": -17897.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2982.8333333333335,
    "average_win": null,
    "average_loss": -2982.8333333333335
  },
  {
    "hold_time_band": "HOLD_H_2.136-6.652",
    "number_of_trades": 5,
    "net_profit": -15935.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3187.0,
    "average_win": null,
    "average_loss": -3187.0
  },
  {
    "hold_time_band": "HOLD_H_6.652-65.88",
    "number_of_trades": 6,
    "net_profit": -5958.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.025674570727718723,
    "expectancy": -993.0,
    "average_win": 157.0,
    "average_loss": -1223.0
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-17-313",
    "number_of_trades": 6,
    "net_profit": -18173.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3028.8333333333335,
    "average_win": null,
    "average_loss": -3028.8333333333335
  },
  {
    "mfe_band": "MFE_2337-5018",
    "number_of_trades": 6,
    "net_profit": -10557.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1759.5,
    "average_win": null,
    "average_loss": -1759.5
  },
  {
    "mfe_band": "MFE_313-2337",
    "number_of_trades": 5,
    "net_profit": -11060.0,
    "win_rate": 0.2,
    "profit_factor": 0.013996612284924667,
    "expectancy": -2212.0,
    "average_win": 157.0,
    "average_loss": -2804.25
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2309--826",
    "number_of_trades": 6,
    "net_profit": -2638.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.056171735241502686,
    "expectancy": -439.6666666666667,
    "average_win": 157.0,
    "average_loss": -559.0
  },
  {
    "mae_band": "MAE_-3399--2309",
    "number_of_trades": 5,
    "net_profit": -15257.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3051.4,
    "average_win": null,
    "average_loss": -3051.4
  },
  {
    "mae_band": "MAE_-4018--3399",
    "number_of_trades": 6,
    "net_profit": -21895.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3649.1666666666665,
    "average_win": null,
    "average_loss": -3649.1666666666665
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 5,
    "net_profit": -13097.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2619.4,
    "average_win": null,
    "average_loss": -2619.4
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 12,
    "net_profit": -26693.0,
    "win_rate": 0.08333333333333333,
    "profit_factor": 0.0058472998137802604,
    "expectancy": -2224.4166666666665,
    "average_win": 157.0,
    "average_loss": -2440.909090909091
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": -4497.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2248.5,
    "average_win": null,
    "average_loss": -2248.5
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 6,
    "net_profit": -18054.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3009.0,
    "average_win": null,
    "average_loss": -3009.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 9,
    "net_profit": -17239.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.00902506323292711,
    "expectancy": -1915.4444444444443,
    "average_win": 157.0,
    "average_loss": -2174.5
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 14,
    "net_profit": -39758.0,
    "win_rate": 0.07142857142857142,
    "profit_factor": 0.003933358386571465,
    "expectancy": -2839.8571428571427,
    "average_win": 157.0,
    "average_loss": -3070.3846153846152
  },
  {
    "close_reason": "SL",
    "number_of_trades": 3,
    "net_profit": -32.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -10.666666666666666,
    "average_win": null,
    "average_loss": -10.666666666666666
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 2,
    "net_profit": -6605.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3302.5,
    "average_win": null,
    "average_loss": -3302.5
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 9,
    "net_profit": -19400.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2155.5555555555557,
    "average_win": null,
    "average_loss": -2155.5555555555557
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 5,
    "net_profit": -10113.0,
    "win_rate": 0.2,
    "profit_factor": 0.015287244401168451,
    "expectancy": -2022.6,
    "average_win": 157.0,
    "average_loss": -2567.5
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 1,
    "net_profit": -3672.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3672.0,
    "average_win": null,
    "average_loss": -3672.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": -3529.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.042593597395550735,
    "expectancy": -1176.3333333333333,
    "average_win": 157.0,
    "average_loss": -1843.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 4,
    "net_profit": -7784.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1946.0,
    "average_win": null,
    "average_loss": -1946.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 2,
    "net_profit": -5957.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2978.5,
    "average_win": null,
    "average_loss": -2978.5
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": -11908.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2977.0,
    "average_win": null,
    "average_loss": -2977.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 4,
    "net_profit": -10612.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2653.0,
    "average_win": null,
    "average_loss": -2653.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_0.907-2.208",
    "number_of_trades": 5,
    "net_profit": -3060.0,
    "win_rate": 0.2,
    "profit_factor": 0.048803232825613926,
    "expectancy": -612.0,
    "average_win": 157.0,
    "average_loss": -804.25
  },
  {
    "giveback_band": "GIVEBACK_2.208-5.463",
    "number_of_trades": 5,
    "net_profit": -14885.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2977.0,
    "average_win": null,
    "average_loss": -2977.0
  },
  {
    "giveback_band": "GIVEBACK_5.463-174.6",
    "number_of_trades": 5,
    "net_profit": -14416.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2883.2,
    "average_win": null,
    "average_loss": -2883.2
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
