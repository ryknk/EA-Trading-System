# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 7
- MFEデータのある負けトレード数: 7
- うち一度含み益になった数: 7
- 割合: 100.00%
- 反転前の平均含み益: 1376.00

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 12
- 平均Giveback比率: 504.71%
- 中央値Giveback比率: 238.40%
- 損益ゼロ以下まで完全反転した割合: 66.67%

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

- 決済件数: 6
- 純損益: -22469.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3744.83
- 平均逆行幅（R）: 0.7781
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 6,
    "net_profit": -22469.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3744.8333333333335,
    "average_win": null,
    "average_loss": -3744.8333333333335
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 2051
- 最終Entry候補まで到達: 13
- Stage別棄却数（market_regime）: 1691
- Stage別棄却数（htf_bias）: 88
- Stage別棄却数（trend_strength_or_momentum_filter）: 144
- Stage別棄却数（setup_or_trigger）: 115
- Stage別棄却数（other）: 0

```json
{
  "ENTRY_PATTERN_NOT_FOUND": 115,
  "REGIME_NOT_TRENDING": 1691,
  "RSI_FILTERED": 118,
  "CONFIRMATION_ADX_TOO_LOW": 26,
  "TREND_NOT_ALIGNED": 88
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 11,
    "net_profit": -2612.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 0.8871560029377457,
    "expectancy": -237.45454545454547,
    "average_win": 5133.75,
    "average_loss": -3306.714285714286
  },
  {
    "direction": "SELL",
    "number_of_trades": 1,
    "net_profit": 0.0,
    "win_rate": 0.0,
    "profit_factor": null,
    "expectancy": 0.0,
    "average_win": null,
    "average_loss": null
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 2,
    "net_profit": 5927.0,
    "win_rate": 0.5,
    "profit_factor": 2.615866957470011,
    "expectancy": 2963.5,
    "average_win": 9595.0,
    "average_loss": -3668.0
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 3,
    "net_profit": 2163.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.280181347150259,
    "expectancy": 721.0,
    "average_win": 9883.0,
    "average_loss": -3860.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 5,
    "net_profit": -6328.0,
    "win_rate": 0.4,
    "profit_factor": 0.14312796208530806,
    "expectancy": -1265.6,
    "average_win": 528.5,
    "average_loss": -3692.5
  },
  {
    "session": "Tokyo",
    "number_of_trades": 2,
    "net_profit": -4374.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2187.0,
    "average_win": null,
    "average_loss": -2187.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": -7233.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.017789244975556763,
    "expectancy": -2411.0,
    "average_win": 131.0,
    "average_loss": -3682.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 3,
    "net_profit": -3478.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.21026339691189827,
    "expectancy": -1159.3333333333333,
    "average_win": 926.0,
    "average_loss": -2202.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 2,
    "net_profit": -4100.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2050.0,
    "average_win": null,
    "average_loss": -4100.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 1,
    "net_profit": -3620.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3620.0,
    "average_win": null,
    "average_loss": -3620.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 3,
    "net_profit": 15819.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 5.323312380431812,
    "expectancy": 5273.0,
    "average_win": 9739.0,
    "average_loss": -3659.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.092-0.124",
    "number_of_trades": 4,
    "net_profit": 3089.0,
    "win_rate": 0.5,
    "profit_factor": 1.4001295336787565,
    "expectancy": 772.25,
    "average_win": 5404.5,
    "average_loss": -3860.0
  },
  {
    "atr_band": "ATR_0.124-0.154",
    "number_of_trades": 4,
    "net_profit": 5191.0,
    "win_rate": 0.25,
    "profit_factor": 2.1787011807447776,
    "expectancy": 1297.75,
    "average_win": 9595.0,
    "average_loss": -2202.0
  },
  {
    "atr_band": "ATR_0.154-0.235",
    "number_of_trades": 4,
    "net_profit": -10892.0,
    "win_rate": 0.25,
    "profit_factor": 0.011884242039372222,
    "expectancy": -2723.0,
    "average_win": 131.0,
    "average_loss": -3674.3333333333335
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.05-42.54",
    "number_of_trades": 4,
    "net_profit": -7548.0,
    "win_rate": 0.25,
    "profit_factor": 0.1092754307292896,
    "expectancy": -1887.0,
    "average_win": 926.0,
    "average_loss": -2824.6666666666665
  },
  {
    "adx_band": "ADX_42.54-44.2",
    "number_of_trades": 4,
    "net_profit": -7215.0,
    "win_rate": 0.25,
    "profit_factor": 0.017832834195480533,
    "expectancy": -1803.75,
    "average_win": 131.0,
    "average_loss": -3673.0
  },
  {
    "adx_band": "ADX_44.2-54.97",
    "number_of_trades": 4,
    "net_profit": 12151.0,
    "win_rate": 0.5,
    "profit_factor": 2.658386788590146,
    "expectancy": 3037.75,
    "average_win": 9739.0,
    "average_loss": -3663.5
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.658-3.047",
    "number_of_trades": 4,
    "net_profit": -11446.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2861.5,
    "average_win": null,
    "average_loss": -3815.3333333333335
  },
  {
    "hold_time_band": "HOLD_H_13.87-77.68",
    "number_of_trades": 4,
    "net_profit": 7281.0,
    "win_rate": 0.75,
    "profit_factor": 2.9898879475266464,
    "expectancy": 1820.25,
    "average_win": 3646.6666666666665,
    "average_loss": -3659.0
  },
  {
    "hold_time_band": "HOLD_H_3.047-13.87",
    "number_of_trades": 4,
    "net_profit": 1553.0,
    "win_rate": 0.25,
    "profit_factor": 1.1931111663765233,
    "expectancy": 388.25,
    "average_win": 9595.0,
    "average_loss": -2680.6666666666665
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_125-1462",
    "number_of_trades": 4,
    "net_profit": -12124.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3031.0,
    "average_win": null,
    "average_loss": -3031.0
  },
  {
    "mfe_band": "MFE_1462-4755",
    "number_of_trades": 4,
    "net_profit": -10097.0,
    "win_rate": 0.25,
    "profit_factor": 0.08400616891953189,
    "expectancy": -2524.25,
    "average_win": 926.0,
    "average_loss": -3674.3333333333335
  },
  {
    "mfe_band": "MFE_4755-9857",
    "number_of_trades": 4,
    "net_profit": 19609.0,
    "win_rate": 0.75,
    "profit_factor": null,
    "expectancy": 4902.25,
    "average_win": 6536.333333333333,
    "average_loss": null
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2407--494",
    "number_of_trades": 4,
    "net_profit": 20404.0,
    "win_rate": 0.75,
    "profit_factor": null,
    "expectancy": 5101.0,
    "average_win": 6801.333333333333,
    "average_loss": null
  },
  {
    "mae_band": "MAE_-3671--2407",
    "number_of_trades": 4,
    "net_profit": -7826.0,
    "win_rate": 0.25,
    "profit_factor": 0.016463491265552344,
    "expectancy": -1956.5,
    "average_win": 131.0,
    "average_loss": -2652.3333333333335
  },
  {
    "mae_band": "MAE_-4100--3671",
    "number_of_trades": 4,
    "net_profit": -15190.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3797.5,
    "average_win": null,
    "average_loss": -3797.5
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 3,
    "net_profit": -7796.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2598.6666666666665,
    "average_win": null,
    "average_loss": -3898.0
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 9,
    "net_profit": 5184.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 1.3376978698456126,
    "expectancy": 576.0,
    "average_win": 5133.75,
    "average_loss": -3070.2
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 1,
    "net_profit": -3659.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3659.0,
    "average_win": null,
    "average_loss": -3659.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 1,
    "net_profit": -3726.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3726.0,
    "average_win": null,
    "average_loss": -3726.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 10,
    "net_profit": 4773.0,
    "win_rate": 0.4,
    "profit_factor": 1.3028169014084507,
    "expectancy": 477.3,
    "average_win": 5133.75,
    "average_loss": -3152.4
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 8,
    "net_profit": -22221.0,
    "win_rate": 0.125,
    "profit_factor": 0.040005184257139156,
    "expectancy": -2777.625,
    "average_win": 926.0,
    "average_loss": -3306.714285714286
  },
  {
    "close_reason": "SL",
    "number_of_trades": 2,
    "net_profit": 131.0,
    "win_rate": 0.5,
    "profit_factor": null,
    "expectancy": 65.5,
    "average_win": 131.0,
    "average_loss": null
  },
  {
    "close_reason": "TP",
    "number_of_trades": 2,
    "net_profit": 19478.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9739.0,
    "average_win": 9739.0,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 1,
    "net_profit": 9883.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9883.0,
    "average_win": 9883.0,
    "average_loss": null
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 5,
    "net_profit": -943.0,
    "win_rate": 0.4,
    "profit_factor": 0.9177424982554082,
    "expectancy": -188.6,
    "average_win": 5260.5,
    "average_loss": -3821.3333333333335
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 4,
    "net_profit": -11005.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2751.25,
    "average_win": null,
    "average_loss": -3668.3333333333335
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 2,
    "net_profit": -547.0,
    "win_rate": 0.5,
    "profit_factor": 0.19321533923303835,
    "expectancy": -273.5,
    "average_win": 131.0,
    "average_loss": -678.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 2,
    "net_profit": -7364.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3682.0,
    "average_win": null,
    "average_loss": -3682.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 2,
    "net_profit": -3595.0,
    "win_rate": 0.5,
    "profit_factor": 0.03515834675254965,
    "expectancy": -1797.5,
    "average_win": 131.0,
    "average_loss": -3726.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": 2124.0,
    "win_rate": 0.25,
    "profit_factor": 1.273746616832066,
    "expectancy": 531.0,
    "average_win": 9883.0,
    "average_loss": -3879.5
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": -3372.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.21544904606793858,
    "expectancy": -1124.0,
    "average_win": 926.0,
    "average_loss": -2149.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 1,
    "net_profit": 9595.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9595.0,
    "average_win": 9595.0,
    "average_loss": null
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00898-0.995",
    "number_of_trades": 4,
    "net_profit": 20535.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 5133.75,
    "average_win": 5133.75,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.995-3.103",
    "number_of_trades": 4,
    "net_profit": -11023.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2755.75,
    "average_win": null,
    "average_loss": -3674.3333333333335
  },
  {
    "giveback_band": "GIVEBACK_3.103-33.8",
    "number_of_trades": 4,
    "net_profit": -12124.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3031.0,
    "average_win": null,
    "average_loss": -3031.0
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
