# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 4
- MFEデータのある負けトレード数: 4
- うち一度含み益になった数: 2
- 割合: 50.00%
- 反転前の平均含み益: 3503.00

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 8
- 平均Giveback比率: 86.32%
- 中央値Giveback比率: 99.42%
- 損益ゼロ以下まで完全反転した割合: 37.50%

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

- 決済件数: 3
- 純損益: -10731.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3577.00
- 平均逆行幅（R）: 0.7574
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 3,
    "net_profit": -10731.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3577.0,
    "average_win": null,
    "average_loss": -3577.0
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 2050
- 最終Entry候補まで到達: 20
- Stage別棄却数（market_regime）: 1650
- Stage別棄却数（htf_bias）: 53
- Stage別棄却数（trend_strength_or_momentum_filter）: 183
- Stage別棄却数（setup_or_trigger）: 144
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 1650,
  "TREND_NOT_ALIGNED": 53,
  "RSI_FILTERED": 167,
  "ENTRY_PATTERN_NOT_FOUND": 144,
  "CONFIRMATION_ADX_TOO_LOW": 16
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 10,
    "net_profit": 9090.0,
    "win_rate": 0.5,
    "profit_factor": 1.8349407550289336,
    "expectancy": 909.0,
    "average_win": 3995.4,
    "average_loss": -2721.75
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 3,
    "net_profit": 2177.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.3092768859212955,
    "expectancy": 725.6666666666666,
    "average_win": 9216.0,
    "average_loss": -3519.5
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 1,
    "net_profit": 0.0,
    "win_rate": 0.0,
    "profit_factor": null,
    "expectancy": 0.0,
    "average_win": null,
    "average_loss": null
  },
  {
    "session": "NewYork",
    "number_of_trades": 5,
    "net_profit": 7069.0,
    "win_rate": 0.8,
    "profit_factor": 2.914680390032503,
    "expectancy": 1413.8,
    "average_win": 2690.25,
    "average_loss": -3692.0
  },
  {
    "session": "Tokyo",
    "number_of_trades": 1,
    "net_profit": -156.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -156.0,
    "average_win": null,
    "average_loss": -156.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 1,
    "net_profit": 7.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7.0,
    "average_win": 7.0,
    "average_loss": null
  },
  {
    "weekday": "Mon",
    "number_of_trades": 4,
    "net_profit": -1923.0,
    "win_rate": 0.25,
    "profit_factor": 0.5002598752598753,
    "expectancy": -480.75,
    "average_win": 1925.0,
    "average_loss": -1924.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": 1714.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2435004972297201,
    "expectancy": 571.3333333333334,
    "average_win": 8753.0,
    "average_loss": -3519.5
  },
  {
    "weekday": "Wed",
    "number_of_trades": 2,
    "net_profit": 9292.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 4646.0,
    "average_win": 4646.0,
    "average_loss": null
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.13-0.21",
    "number_of_trades": 4,
    "net_profit": 1793.0,
    "win_rate": 0.25,
    "profit_factor": 1.2415465445237774,
    "expectancy": 448.25,
    "average_win": 9216.0,
    "average_loss": -2474.3333333333335
  },
  {
    "atr_band": "ATR_0.21-0.258",
    "number_of_trades": 2,
    "net_profit": 76.0,
    "win_rate": 0.5,
    "profit_factor": null,
    "expectancy": 38.0,
    "average_win": 76.0,
    "average_loss": null
  },
  {
    "atr_band": "ATR_0.258-0.365",
    "number_of_trades": 4,
    "net_profit": 7221.0,
    "win_rate": 0.75,
    "profit_factor": 3.084584295612009,
    "expectancy": 1805.25,
    "average_win": 3561.6666666666665,
    "average_loss": -3464.0
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.57-41.68",
    "number_of_trades": 4,
    "net_profit": 3411.0,
    "win_rate": 0.5,
    "profit_factor": 1.4693821384340169,
    "expectancy": 852.75,
    "average_win": 5339.0,
    "average_loss": -3633.5
  },
  {
    "adx_band": "ADX_41.68-46.88",
    "number_of_trades": 2,
    "net_profit": 9216.0,
    "win_rate": 0.5,
    "profit_factor": null,
    "expectancy": 4608.0,
    "average_win": 9216.0,
    "average_loss": null
  },
  {
    "adx_band": "ADX_46.88-60.01",
    "number_of_trades": 4,
    "net_profit": -3537.0,
    "win_rate": 0.5,
    "profit_factor": 0.02292817679558011,
    "expectancy": -884.25,
    "average_win": 41.5,
    "average_loss": -1810.0
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.994-4.614",
    "number_of_trades": 4,
    "net_profit": -10731.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2682.75,
    "average_win": null,
    "average_loss": -3577.0
  },
  {
    "hold_time_band": "HOLD_H_16.64-76.95",
    "number_of_trades": 4,
    "net_profit": 1852.0,
    "win_rate": 0.75,
    "profit_factor": 12.871794871794872,
    "expectancy": 463.0,
    "average_win": 669.3333333333334,
    "average_loss": -156.0
  },
  {
    "hold_time_band": "HOLD_H_4.614-16.64",
    "number_of_trades": 2,
    "net_profit": 17969.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8984.5,
    "average_win": 8984.5,
    "average_loss": null
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-78-2825",
    "number_of_trades": 3,
    "net_profit": -10731.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3577.0,
    "average_win": null,
    "average_loss": -3577.0
  },
  {
    "mfe_band": "MFE_2825-7183",
    "number_of_trades": 3,
    "net_profit": 1769.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 12.33974358974359,
    "expectancy": 589.6666666666666,
    "average_win": 1925.0,
    "average_loss": -156.0
  },
  {
    "mfe_band": "MFE_7183-9180",
    "number_of_trades": 4,
    "net_profit": 18052.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 4513.0,
    "average_win": 4513.0,
    "average_loss": null
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-1256--360",
    "number_of_trades": 4,
    "net_profit": 8836.0,
    "win_rate": 0.75,
    "profit_factor": null,
    "expectancy": 2209.0,
    "average_win": 2945.3333333333335,
    "average_loss": null
  },
  {
    "mae_band": "MAE_-2641--1256",
    "number_of_trades": 3,
    "net_profit": 10985.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 71.41666666666667,
    "expectancy": 3661.6666666666665,
    "average_win": 5570.5,
    "average_loss": -156.0
  },
  {
    "mae_band": "MAE_-3692--2641",
    "number_of_trades": 3,
    "net_profit": -10731.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3577.0,
    "average_win": null,
    "average_loss": -3577.0
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 1,
    "net_profit": 0.0,
    "win_rate": 0.0,
    "profit_factor": null,
    "expectancy": 0.0,
    "average_win": null,
    "average_loss": null
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 9,
    "net_profit": 9090.0,
    "win_rate": 0.5555555555555556,
    "profit_factor": 1.8349407550289336,
    "expectancy": 1010.0,
    "average_win": 3995.4,
    "average_loss": -2721.75
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 1,
    "net_profit": 8753.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8753.0,
    "average_win": 8753.0,
    "average_loss": null
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 9,
    "net_profit": 337.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 1.0309543492238449,
    "expectancy": 37.44444444444444,
    "average_win": 2806.0,
    "average_loss": -2721.75
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 5,
    "net_profit": -8962.0,
    "win_rate": 0.2,
    "profit_factor": 0.1768163865160283,
    "expectancy": -1792.4,
    "average_win": 1925.0,
    "average_loss": -2721.75
  },
  {
    "close_reason": "SL",
    "number_of_trades": 3,
    "net_profit": 83.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": null,
    "expectancy": 27.666666666666668,
    "average_win": 41.5,
    "average_loss": null
  },
  {
    "close_reason": "TP",
    "number_of_trades": 2,
    "net_profit": 17969.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8984.5,
    "average_win": 8984.5,
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
    "net_profit": -3388.0,
    "win_rate": 0.5,
    "profit_factor": 0.021939953810623556,
    "expectancy": -1694.0,
    "average_win": 76.0,
    "average_loss": -3464.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 3,
    "net_profit": 7566.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 3.1163636363636362,
    "expectancy": 2522.0,
    "average_win": 5570.5,
    "average_loss": -3575.0
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 2,
    "net_profit": -3692.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1846.0,
    "average_win": null,
    "average_loss": -3692.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 3,
    "net_profit": 8604.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 56.15384615384615,
    "expectancy": 2868.0,
    "average_win": 4380.0,
    "average_loss": -156.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 1,
    "net_profit": 8753.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8753.0,
    "average_win": 8753.0,
    "average_loss": null
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 3,
    "net_profit": -3685.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.001895991332611051,
    "expectancy": -1228.3333333333333,
    "average_win": 7.0,
    "average_loss": -3692.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": -6963.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.010796988208552351,
    "expectancy": -2321.0,
    "average_win": 76.0,
    "average_loss": -3519.5
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 1,
    "net_profit": 1925.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 1925.0,
    "average_win": 1925.0,
    "average_loss": null
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 2,
    "net_profit": 9060.0,
    "win_rate": 0.5,
    "profit_factor": 59.07692307692308,
    "expectancy": 4530.0,
    "average_win": 9216.0,
    "average_loss": -156.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00492-0.542",
    "number_of_trades": 3,
    "net_profit": 19894.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 6631.333333333333,
    "average_win": 6631.333333333333,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.542-1",
    "number_of_trades": 2,
    "net_profit": 83.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 41.5,
    "average_win": 41.5,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1-2.57",
    "number_of_trades": 3,
    "net_profit": -3731.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1243.6666666666667,
    "average_win": null,
    "average_loss": -1865.5
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
