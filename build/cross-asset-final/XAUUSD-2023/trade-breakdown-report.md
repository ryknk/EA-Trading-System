# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 7
- MFEデータのある負けトレード数: 7
- うち一度含み益になった数: 6
- 割合: 85.71%
- 反転前の平均含み益: 1687.00

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 9
- 平均Giveback比率: 458.05%
- 中央値Giveback比率: 188.88%
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

- 決済件数: 7
- 純損益: -23590.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3370.00
- 平均逆行幅（R）: 0.7599
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 4,
    "net_profit": -13389.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3347.25,
    "average_win": null,
    "average_loss": -3347.25
  },
  "SELL": {
    "number_of_trades": 3,
    "net_profit": -10201.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3400.3333333333335,
    "average_win": null,
    "average_loss": -3400.3333333333335
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 2956
- 最終Entry候補まで到達: 14
- Stage別棄却数（market_regime）: 2342
- Stage別棄却数（htf_bias）: 188
- Stage別棄却数（trend_strength_or_momentum_filter）: 243
- Stage別棄却数（setup_or_trigger）: 169
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 2342,
  "TREND_NOT_ALIGNED": 188,
  "ENTRY_PATTERN_NOT_FOUND": 169,
  "RSI_FILTERED": 231,
  "CONFIRMATION_ADX_TOO_LOW": 12
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 6,
    "net_profit": 3402.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2540891776831729,
    "expectancy": 567.0,
    "average_win": 8395.5,
    "average_loss": -3347.25
  },
  {
    "direction": "SELL",
    "number_of_trades": 4,
    "net_profit": -1100.0,
    "win_rate": 0.25,
    "profit_factor": 0.8921674345652387,
    "expectancy": -275.0,
    "average_win": 9101.0,
    "average_loss": -3400.3333333333335
  }
]
```

## session別

```json
[
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 1,
    "net_profit": 7504.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7504.0,
    "average_win": 7504.0,
    "average_loss": null
  },
  {
    "session": "NewYork",
    "number_of_trades": 4,
    "net_profit": -1482.0,
    "win_rate": 0.25,
    "profit_factor": 0.8623827653449717,
    "expectancy": -370.5,
    "average_win": 9287.0,
    "average_loss": -3589.6666666666665
  },
  {
    "session": "Tokyo",
    "number_of_trades": 5,
    "net_profit": -3720.0,
    "win_rate": 0.2,
    "profit_factor": 0.7098510256610249,
    "expectancy": -744.0,
    "average_win": 9101.0,
    "average_loss": -3205.25
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 1,
    "net_profit": -3875.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3875.0,
    "average_win": null,
    "average_loss": -3875.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 1,
    "net_profit": 9101.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9101.0,
    "average_win": 9101.0,
    "average_loss": null
  },
  {
    "weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": 2457.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.359736456808199,
    "expectancy": 819.0,
    "average_win": 9287.0,
    "average_loss": -3415.0
  },
  {
    "weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": -12885.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3221.25,
    "average_win": null,
    "average_loss": -3221.25
  },
  {
    "weekday": "Wed",
    "number_of_trades": 1,
    "net_profit": 7504.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7504.0,
    "average_win": 7504.0,
    "average_loss": null
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_3.327-4.253",
    "number_of_trades": 4,
    "net_profit": -2514.0,
    "win_rate": 0.25,
    "profit_factor": 0.7490517069275304,
    "expectancy": -628.5,
    "average_win": 7504.0,
    "average_loss": -3339.3333333333335
  },
  {
    "atr_band": "ATR_4.253-4.899",
    "number_of_trades": 3,
    "net_profit": -9697.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3232.3333333333335,
    "average_win": null,
    "average_loss": -3232.3333333333335
  },
  {
    "atr_band": "ATR_4.899-5.316",
    "number_of_trades": 3,
    "net_profit": 14513.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 4.7452903225806455,
    "expectancy": 4837.666666666667,
    "average_win": 9194.0,
    "average_loss": -3875.0
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_42.22-43.78",
    "number_of_trades": 4,
    "net_profit": -477.0,
    "win_rate": 0.25,
    "profit_factor": 0.950198371267488,
    "expectancy": -119.25,
    "average_win": 9101.0,
    "average_loss": -3192.6666666666665
  },
  {
    "adx_band": "ADX_43.78-44.91",
    "number_of_trades": 3,
    "net_profit": -10705.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3568.3333333333335,
    "average_win": null,
    "average_loss": -3568.3333333333335
  },
  {
    "adx_band": "ADX_44.91-60.87",
    "number_of_trades": 3,
    "net_profit": 13484.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 5.077411551254913,
    "expectancy": 4494.666666666667,
    "average_win": 8395.5,
    "average_loss": -3307.0
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_1.024-5.088",
    "number_of_trades": 3,
    "net_profit": 273.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.037754114230397,
    "expectancy": 91.0,
    "average_win": 7504.0,
    "average_loss": -3615.5
  },
  {
    "hold_time_band": "HOLD_H_10.31-21.23",
    "number_of_trades": 4,
    "net_profit": 11543.0,
    "win_rate": 0.5,
    "profit_factor": 2.6863403944485027,
    "expectancy": 2885.75,
    "average_win": 9194.0,
    "average_loss": -3422.5
  },
  {
    "hold_time_band": "HOLD_H_5.088-10.31",
    "number_of_trades": 3,
    "net_profit": -9514.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3171.3333333333335,
    "average_win": null,
    "average_loss": -3171.3333333333335
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-117-445",
    "number_of_trades": 3,
    "net_profit": -9578.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3192.6666666666665,
    "average_win": null,
    "average_loss": -3192.6666666666665
  },
  {
    "mfe_band": "MFE_4360-9233",
    "number_of_trades": 3,
    "net_profit": 25892.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8630.666666666666,
    "average_win": 8630.666666666666,
    "average_loss": null
  },
  {
    "mfe_band": "MFE_445-4360",
    "number_of_trades": 4,
    "net_profit": -14012.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3503.0,
    "average_win": null,
    "average_loss": -3503.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-3115--674",
    "number_of_trades": 3,
    "net_profit": 25892.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8630.666666666666,
    "average_win": 8630.666666666666,
    "average_loss": null
  },
  {
    "mae_band": "MAE_-3307--3115",
    "number_of_trades": 3,
    "net_profit": -9514.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3171.3333333333335,
    "average_win": null,
    "average_loss": -3171.3333333333335
  },
  {
    "mae_band": "MAE_-3893--3307",
    "number_of_trades": 4,
    "net_profit": -14076.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3519.0,
    "average_win": null,
    "average_loss": -3519.0
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 2,
    "net_profit": 5794.0,
    "win_rate": 0.5,
    "profit_factor": 2.7520411248866044,
    "expectancy": 2897.0,
    "average_win": 9101.0,
    "average_loss": -3307.0
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 8,
    "net_profit": -3492.0,
    "win_rate": 0.25,
    "profit_factor": 0.8278361189173199,
    "expectancy": -436.5,
    "average_win": 8395.5,
    "average_loss": -3380.5
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 1,
    "net_profit": 9101.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9101.0,
    "average_win": 9101.0,
    "average_loss": null
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 9,
    "net_profit": -6799.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.7117846545146248,
    "expectancy": -755.4444444444445,
    "average_win": 8395.5,
    "average_loss": -3370.0
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 7,
    "net_profit": -23590.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3370.0,
    "average_win": null,
    "average_loss": -3370.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 3,
    "net_profit": 25892.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8630.666666666666,
    "average_win": 8630.666666666666,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 4,
    "net_profit": -227.0,
    "win_rate": 0.25,
    "profit_factor": 0.9761404246373765,
    "expectancy": -56.75,
    "average_win": 9287.0,
    "average_loss": -3171.3333333333335
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 1,
    "net_profit": 7504.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7504.0,
    "average_win": 7504.0,
    "average_loss": null
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 3,
    "net_profit": -10538.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3512.6666666666665,
    "average_win": null,
    "average_loss": -3512.6666666666665
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 2,
    "net_profit": 5563.0,
    "win_rate": 0.5,
    "profit_factor": 2.5723572639909555,
    "expectancy": 2781.5,
    "average_win": 9101.0,
    "average_loss": -3538.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": 1874.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.2527991366518278,
    "expectancy": 624.6666666666666,
    "average_win": 9287.0,
    "average_loss": -3706.5
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 1,
    "net_profit": -3292.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3292.0,
    "average_win": null,
    "average_loss": -3292.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 5,
    "net_profit": -3784.0,
    "win_rate": 0.2,
    "profit_factor": 0.7063251843228561,
    "expectancy": -756.8,
    "average_win": 9101.0,
    "average_loss": -3221.25
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 1,
    "net_profit": 7504.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7504.0,
    "average_win": 7504.0,
    "average_loss": null
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.00685-1.194",
    "number_of_trades": 3,
    "net_profit": 25892.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8630.666666666666,
    "average_win": 8630.666666666666,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1.194-8.558",
    "number_of_trades": 3,
    "net_profit": -10474.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3491.3333333333335,
    "average_win": null,
    "average_loss": -3491.3333333333335
  },
  {
    "giveback_band": "GIVEBACK_8.558-10.95",
    "number_of_trades": 3,
    "net_profit": -9760.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3253.3333333333335,
    "average_win": null,
    "average_loss": -3253.3333333333335
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
