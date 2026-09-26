# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 8
- MFEデータのある負けトレード数: 8
- うち一度含み益になった数: 7
- 割合: 87.50%
- 反転前の平均含み益: 3086.57

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 13
- 平均Giveback比率: 140.45%
- 中央値Giveback比率: 100.58%
- 損益ゼロ以下まで完全反転した割合: 53.85%

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
- 純損益: -21750.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3625.00
- 平均逆行幅（R）: 0.7717
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 6,
    "net_profit": -21750.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3625.0,
    "average_win": null,
    "average_loss": -3625.0
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 3481
- 最終Entry候補まで到達: 28
- Stage別棄却数（market_regime）: 2855
- Stage別棄却数（htf_bias）: 117
- Stage別棄却数（trend_strength_or_momentum_filter）: 288
- Stage別棄却数（setup_or_trigger）: 193
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 2855,
  "ENTRY_PATTERN_NOT_FOUND": 193,
  "RSI_FILTERED": 262,
  "CONFIRMATION_ADX_TOO_LOW": 26,
  "TREND_NOT_ALIGNED": 117
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 14,
    "net_profit": 24026.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 2.0999908433293655,
    "expectancy": 1716.142857142857,
    "average_win": 7644.666666666667,
    "average_loss": -2730.25
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 7,
    "net_profit": 2754.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 1.1892263295314003,
    "expectancy": 393.42857142857144,
    "average_win": 8654.0,
    "average_loss": -2910.8
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 2,
    "net_profit": -3739.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1869.5,
    "average_win": null,
    "average_loss": -1869.5
  },
  {
    "session": "NewYork",
    "number_of_trades": 4,
    "net_profit": 15525.0,
    "win_rate": 0.75,
    "profit_factor": 5.37447168216399,
    "expectancy": 3881.25,
    "average_win": 6358.0,
    "average_loss": -3549.0
  },
  {
    "session": "Tokyo",
    "number_of_trades": 1,
    "net_profit": 9486.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9486.0,
    "average_win": 9486.0,
    "average_loss": null
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": 10780.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 174.8709677419355,
    "expectancy": 3593.3333333333335,
    "average_win": 5421.0,
    "average_loss": -62.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 4,
    "net_profit": 2226.0,
    "win_rate": 0.25,
    "profit_factor": 1.306611570247934,
    "expectancy": 556.5,
    "average_win": 9486.0,
    "average_loss": -2420.0
  },
  {
    "weekday": "Thu",
    "number_of_trades": 5,
    "net_profit": 5999.0,
    "win_rate": 0.4,
    "profit_factor": 1.553260167850226,
    "expectancy": 1199.8,
    "average_win": 8421.0,
    "average_loss": -3614.3333333333335
  },
  {
    "weekday": "Tue",
    "number_of_trades": 2,
    "net_profit": 5021.0,
    "win_rate": 0.5,
    "profit_factor": 2.3655153657873265,
    "expectancy": 2510.5,
    "average_win": 8698.0,
    "average_loss": -3677.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_14.74-23.39",
    "number_of_trades": 5,
    "net_profit": 1122.0,
    "win_rate": 0.2,
    "profit_factor": 1.1498397435897436,
    "expectancy": 224.4,
    "average_win": 8610.0,
    "average_loss": -1872.0
  },
  {
    "atr_band": "ATR_23.39-38.95",
    "number_of_trades": 4,
    "net_profit": 15291.0,
    "win_rate": 0.75,
    "profit_factor": 5.04203013481364,
    "expectancy": 3822.75,
    "average_win": 6358.0,
    "average_loss": -3783.0
  },
  {
    "atr_band": "ATR_38.95-64.18",
    "number_of_trades": 5,
    "net_profit": 7613.0,
    "win_rate": 0.4,
    "profit_factor": 1.7201778450477723,
    "expectancy": 1522.6,
    "average_win": 9092.0,
    "average_loss": -3523.6666666666665
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.09-43.12",
    "number_of_trades": 5,
    "net_profit": -2327.0,
    "win_rate": 0.2,
    "profit_factor": 0.7872359879308768,
    "expectancy": -465.4,
    "average_win": 8610.0,
    "average_loss": -2734.25
  },
  {
    "adx_band": "ADX_43.12-46.77",
    "number_of_trades": 4,
    "net_profit": 28560.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 7140.0,
    "average_win": 7140.0,
    "average_loss": null
  },
  {
    "adx_band": "ADX_46.77-50.99",
    "number_of_trades": 5,
    "net_profit": -2207.0,
    "win_rate": 0.2,
    "profit_factor": 0.7976157725813847,
    "expectancy": -441.4,
    "average_win": 8698.0,
    "average_loss": -2726.25
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_17.28-85",
    "number_of_trades": 5,
    "net_profit": 15325.0,
    "win_rate": 0.6,
    "profit_factor": 5.087756735129368,
    "expectancy": 3065.0,
    "average_win": 6358.0,
    "average_loss": -1874.5
  },
  {
    "hold_time_band": "HOLD_H_2.071-6.09",
    "number_of_trades": 5,
    "net_profit": -14544.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2908.8,
    "average_win": null,
    "average_loss": -2908.8
  },
  {
    "hold_time_band": "HOLD_H_6.09-17.28",
    "number_of_trades": 4,
    "net_profit": 23245.0,
    "win_rate": 0.75,
    "profit_factor": 7.5497323189630885,
    "expectancy": 5811.25,
    "average_win": 8931.333333333334,
    "average_loss": -3549.0
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_-28-3003",
    "number_of_trades": 5,
    "net_profit": -18073.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3614.6,
    "average_win": null,
    "average_loss": -3614.6
  },
  {
    "mfe_band": "MFE_3003-7410",
    "number_of_trades": 4,
    "net_profit": -2297.0,
    "win_rate": 0.25,
    "profit_factor": 0.3905545237463518,
    "expectancy": -574.25,
    "average_win": 1472.0,
    "average_loss": -1256.3333333333333
  },
  {
    "mfe_band": "MFE_7410-9469",
    "number_of_trades": 5,
    "net_profit": 44396.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8879.2,
    "average_win": 8879.2,
    "average_loss": null
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2062--655",
    "number_of_trades": 5,
    "net_profit": 28204.0,
    "win_rate": 0.8,
    "profit_factor": 455.9032258064516,
    "expectancy": 5640.8,
    "average_win": 7066.5,
    "average_loss": -62.0
  },
  {
    "mae_band": "MAE_-3521--2062",
    "number_of_trades": 4,
    "net_profit": 10580.0,
    "win_rate": 0.5,
    "profit_factor": 2.5066932497863856,
    "expectancy": 2645.0,
    "average_win": 8801.0,
    "average_loss": -3511.0
  },
  {
    "mae_band": "MAE_-3848--3521",
    "number_of_trades": 5,
    "net_profit": -14758.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2951.6,
    "average_win": null,
    "average_loss": -2951.6
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 3,
    "net_profit": 5829.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.6461451567353853,
    "expectancy": 1943.0,
    "average_win": 9370.0,
    "average_loss": -1770.5
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 11,
    "net_profit": 18197.0,
    "win_rate": 0.45454545454545453,
    "profit_factor": 1.994317250423474,
    "expectancy": 1654.2727272727273,
    "average_win": 7299.6,
    "average_loss": -3050.1666666666665
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 4,
    "net_profit": 1046.0,
    "win_rate": 0.25,
    "profit_factor": 1.1382866208355367,
    "expectancy": 261.5,
    "average_win": 8610.0,
    "average_loss": -2521.3333333333335
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 10,
    "net_profit": 22980.0,
    "win_rate": 0.5,
    "profit_factor": 2.6094691133211936,
    "expectancy": 2298.0,
    "average_win": 7451.6,
    "average_loss": -2855.6
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 7,
    "net_profit": -20278.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.06767816091954024,
    "expectancy": -2896.8571428571427,
    "average_win": 1472.0,
    "average_loss": -3625.0
  },
  {
    "close_reason": "SL",
    "number_of_trades": 2,
    "net_profit": -92.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -46.0,
    "average_win": null,
    "average_loss": -46.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 5,
    "net_profit": 44396.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8879.2,
    "average_win": 8879.2,
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
    "net_profit": -2077.0,
    "win_rate": 0.5,
    "profit_factor": 0.41476472245703017,
    "expectancy": -1038.5,
    "average_win": 1472.0,
    "average_loss": -3549.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 6,
    "net_profit": 2448.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.1690374257699212,
    "expectancy": 408.0,
    "average_win": 8465.0,
    "average_loss": -3620.5
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 4,
    "net_profit": 18004.0,
    "win_rate": 0.5,
    "profit_factor": 196.69565217391303,
    "expectancy": 4501.0,
    "average_win": 9048.0,
    "average_loss": -46.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 2,
    "net_profit": 5651.0,
    "win_rate": 0.5,
    "profit_factor": 2.5194944877655283,
    "expectancy": 2825.5,
    "average_win": 9370.0,
    "average_loss": -3719.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 3,
    "net_profit": 4621.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 2.279700913874273,
    "expectancy": 1540.3333333333333,
    "average_win": 8232.0,
    "average_loss": -1805.5
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 3,
    "net_profit": 15345.0,
    "win_rate": 0.6666666666666666,
    "profit_factor": 5.370549700939903,
    "expectancy": 5115.0,
    "average_win": 9428.0,
    "average_loss": -3511.0
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 3,
    "net_profit": 1316.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.1804222648752398,
    "expectancy": 438.6666666666667,
    "average_win": 8610.0,
    "average_loss": -3647.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 5,
    "net_profit": 2744.0,
    "win_rate": 0.4,
    "profit_factor": 1.3695125235658496,
    "expectancy": 548.8,
    "average_win": 5085.0,
    "average_loss": -2475.3333333333335
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0018-1.908",
    "number_of_trades": 4,
    "net_profit": 10866.0,
    "win_rate": 0.5,
    "profit_factor": 119.1086956521739,
    "expectancy": 2716.5,
    "average_win": 5479.0,
    "average_loss": -46.0
  },
  {
    "giveback_band": "GIVEBACK_-0.01038--0.0018",
    "number_of_trades": 4,
    "net_profit": 34910.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8727.5,
    "average_win": 8727.5,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1.908-4.221",
    "number_of_trades": 5,
    "net_profit": -17967.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3593.4,
    "average_win": null,
    "average_loss": -3593.4
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
