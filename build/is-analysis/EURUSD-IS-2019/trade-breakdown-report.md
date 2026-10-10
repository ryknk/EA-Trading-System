# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 7
- MFEデータのある負けトレード数: 7
- うち一度含み益になった数: 6
- 割合: 85.71%
- 反転前の平均含み益: 1943.50

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 9
- 平均Giveback比率: 261.61%
- 中央値Giveback比率: 215.65%
- 損益ゼロ以下まで完全反転した割合: 77.78%

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

- 決済件数: 7
- 純損益: -26272.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3753.14
- 平均逆行幅（R）: 0.7680
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 1,
    "net_profit": -3693.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3693.0,
    "average_win": null,
    "average_loss": -3693.0
  },
  "SELL": {
    "number_of_trades": 6,
    "net_profit": -22579.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3763.1666666666665,
    "average_win": null,
    "average_loss": -3763.1666666666665
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6219
- 最終Entry候補まで到達: 18
- Stage別棄却数（market_regime）: 5349
- Stage別棄却数（htf_bias）: 338
- Stage別棄却数（trend_strength_or_momentum_filter）: 337
- Stage別棄却数（setup_or_trigger）: 177
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5349,
  "TREND_NOT_ALIGNED": 338,
  "RSI_FILTERED": 302,
  "ENTRY_PATTERN_NOT_FOUND": 177,
  "CONFIRMATION_ADX_TOO_LOW": 35
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 1,
    "net_profit": -3693.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3693.0,
    "average_win": null,
    "average_loss": -3693.0
  },
  {
    "direction": "SELL",
    "number_of_trades": 9,
    "net_profit": -12802.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.43301297665972804,
    "expectancy": -1422.4444444444443,
    "average_win": 4888.5,
    "average_loss": -3763.1666666666665
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 2,
    "net_profit": -7413.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3706.5,
    "average_win": null,
    "average_loss": -3706.5
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 4,
    "net_profit": -11441.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2860.25,
    "average_win": null,
    "average_loss": -3813.6666666666665
  },
  {
    "session": "NewYork",
    "number_of_trades": 1,
    "net_profit": 77.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 77.0,
    "average_win": 77.0,
    "average_loss": null
  },
  {
    "session": "Tokyo",
    "number_of_trades": 3,
    "net_profit": 2282.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.307630088972769,
    "expectancy": 760.6666666666666,
    "average_win": 9700.0,
    "average_loss": -3709.0
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 1,
    "net_profit": 0.0,
    "win_rate": 0.0,
    "profit_factor": null,
    "expectancy": 0.0,
    "average_win": null,
    "average_loss": null
  },
  {
    "weekday": "Thu",
    "number_of_trades": 1,
    "net_profit": -3743.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3743.0,
    "average_win": null,
    "average_loss": -3743.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": 2266.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.3048157115953727,
    "expectancy": 755.3333333333334,
    "average_win": 9700.0,
    "average_loss": -3717.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 5,
    "net_profit": -15018.0,
    "win_rate": 0.2,
    "profit_factor": 0.005101026830076184,
    "expectancy": -3003.6,
    "average_win": 77.0,
    "average_loss": -3773.75
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_-0.000419-0.000636",
    "number_of_trades": 4,
    "net_profit": -11439.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2859.75,
    "average_win": null,
    "average_loss": -3813.0
  },
  {
    "atr_band": "ATR_0.000636-0.000816",
    "number_of_trades": 2,
    "net_profit": 6028.0,
    "win_rate": 0.5,
    "profit_factor": 2.6416122004357296,
    "expectancy": 3014.0,
    "average_win": 9700.0,
    "average_loss": -3672.0
  },
  {
    "atr_band": "ATR_0.000816-0.00148",
    "number_of_trades": 4,
    "net_profit": -11084.0,
    "win_rate": 0.25,
    "profit_factor": 0.006899023385001344,
    "expectancy": -2771.0,
    "average_win": 77.0,
    "average_loss": -3720.3333333333335
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40-43.17",
    "number_of_trades": 4,
    "net_profit": -1461.0,
    "win_rate": 0.25,
    "profit_factor": 0.8690977510975719,
    "expectancy": -365.25,
    "average_win": 9700.0,
    "average_loss": -3720.3333333333335
  },
  {
    "adx_band": "ADX_43.17-45.41",
    "number_of_trades": 3,
    "net_profit": -3770.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.020015596568754873,
    "expectancy": -1256.6666666666667,
    "average_win": 77.0,
    "average_loss": -3847.0
  },
  {
    "adx_band": "ADX_45.41-48.33",
    "number_of_trades": 3,
    "net_profit": -11264.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3754.6666666666665,
    "average_win": null,
    "average_loss": -3754.6666666666665
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.129-2.591",
    "number_of_trades": 3,
    "net_profit": -11335.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3778.3333333333335,
    "average_win": null,
    "average_loss": -3778.3333333333335
  },
  {
    "hold_time_band": "HOLD_H_2.591-8.367",
    "number_of_trades": 3,
    "net_profit": -7365.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2455.0,
    "average_win": null,
    "average_loss": -3682.5
  },
  {
    "hold_time_band": "HOLD_H_8.367-11.41",
    "number_of_trades": 4,
    "net_profit": 2205.0,
    "win_rate": 0.5,
    "profit_factor": 1.2912044374009508,
    "expectancy": 551.25,
    "average_win": 4888.5,
    "average_loss": -3786.0
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-273-1308",
    "number_of_trades": 4,
    "net_profit": -14849.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3712.25,
    "average_win": null,
    "average_loss": -3712.25
  },
  {
    "mfe_band": "MFE_1308-3738",
    "number_of_trades": 2,
    "net_profit": -7576.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3788.0,
    "average_win": null,
    "average_loss": -3788.0
  },
  {
    "mfe_band": "MFE_3738-9668",
    "number_of_trades": 4,
    "net_profit": 5930.0,
    "win_rate": 0.5,
    "profit_factor": 2.5414608786067063,
    "expectancy": 1482.5,
    "average_win": 4888.5,
    "average_loss": -3847.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-3672--181",
    "number_of_trades": 3,
    "net_profit": 9777.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": null,
    "expectancy": 3259.0,
    "average_win": 4888.5,
    "average_loss": null
  },
  {
    "mae_band": "MAE_-3743--3672",
    "number_of_trades": 3,
    "net_profit": -11090.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3696.6666666666665,
    "average_win": null,
    "average_loss": -3696.6666666666665
  },
  {
    "mae_band": "MAE_-3851--3743",
    "number_of_trades": 4,
    "net_profit": -15182.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3795.5,
    "average_win": null,
    "average_loss": -3795.5
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 8,
    "net_profit": -9059.0,
    "win_rate": 0.25,
    "profit_factor": 0.5190592482480357,
    "expectancy": -1132.375,
    "average_win": 4888.5,
    "average_loss": -3767.2
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 2,
    "net_profit": -7436.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3718.0,
    "average_win": null,
    "average_loss": -3718.0
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 1,
    "net_profit": -3725.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3725.0,
    "average_win": null,
    "average_loss": -3725.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 2,
    "net_profit": -3741.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1870.5,
    "average_win": null,
    "average_loss": -3741.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 7,
    "net_profit": -9029.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.5198872700202063,
    "expectancy": -1289.857142857143,
    "average_win": 4888.5,
    "average_loss": -3761.2
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 7,
    "net_profit": -26272.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3753.1428571428573,
    "average_win": null,
    "average_loss": -3753.1428571428573
  },
  {
    "close_reason": "SL",
    "number_of_trades": 2,
    "net_profit": 77.0,
    "win_rate": 0.5,
    "profit_factor": null,
    "expectancy": 38.5,
    "average_win": 77.0,
    "average_loss": null
  },
  {
    "close_reason": "TP",
    "number_of_trades": 1,
    "net_profit": 9700.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9700.0,
    "average_win": 9700.0,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 3,
    "net_profit": -11159.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3719.6666666666665,
    "average_win": null,
    "average_loss": -3719.6666666666665
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 5,
    "net_profit": -1566.0,
    "win_rate": 0.2,
    "profit_factor": 0.8609976921711344,
    "expectancy": -313.2,
    "average_win": 9700.0,
    "average_loss": -3755.3333333333335
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 2,
    "net_profit": -3770.0,
    "win_rate": 0.5,
    "profit_factor": 0.020015596568754873,
    "expectancy": -1885.0,
    "average_win": 77.0,
    "average_loss": -3847.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 1,
    "net_profit": 0.0,
    "win_rate": 0.0,
    "profit_factor": null,
    "expectancy": 0.0,
    "average_win": null,
    "average_loss": null
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": -11238.0,
    "win_rate": 0.25,
    "profit_factor": 0.006805125939019001,
    "expectancy": -2809.5,
    "average_win": 77.0,
    "average_loss": -3771.6666666666665
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 3,
    "net_profit": 2266.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.3048157115953727,
    "expectancy": 755.3333333333334,
    "average_win": 9700.0,
    "average_loss": -3717.0
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 2,
    "net_profit": -7523.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3761.5,
    "average_win": null,
    "average_loss": -3761.5
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00431-1.686",
    "number_of_trades": 3,
    "net_profit": 9777.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": null,
    "expectancy": 3259.0,
    "average_win": 4888.5,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1.686-3.779",
    "number_of_trades": 3,
    "net_profit": -11423.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3807.6666666666665,
    "average_win": null,
    "average_loss": -3807.6666666666665
  },
  {
    "giveback_band": "GIVEBACK_3.779-5.768",
    "number_of_trades": 3,
    "net_profit": -11108.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3702.6666666666665,
    "average_win": null,
    "average_loss": -3702.6666666666665
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
