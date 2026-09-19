# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 18
- MFEデータのある負けトレード数: 18
- うち一度含み益になった数: 18
- 割合: 100.00%
- 反転前の平均含み益: 2538.61

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 32
- 平均Giveback比率: 796.29%
- 中央値Giveback比率: 131.02%
- 損益ゼロ以下まで完全反転した割合: 71.88%

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
- 純損益: -51769.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3697.79
- 平均逆行幅（R）: 0.7556
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 13,
    "net_profit": -48025.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3694.230769230769,
    "average_win": null,
    "average_loss": -3694.230769230769
  },
  "SELL": {
    "number_of_trades": 1,
    "net_profit": -3744.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3744.0,
    "average_win": null,
    "average_loss": -3744.0
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6271
- 最終Entry候補まで到達: 67
- Stage別棄却数（market_regime）: 5208
- Stage別棄却数（htf_bias）: 211
- Stage別棄却数（trend_strength_or_momentum_filter）: 439
- Stage別棄却数（setup_or_trigger）: 346
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5208,
  "ENTRY_PATTERN_NOT_FOUND": 346,
  "CONFIRMATION_ADX_TOO_LOW": 59,
  "RSI_FILTERED": 380,
  "TREND_NOT_ALIGNED": 211
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 25,
    "net_profit": -9754.0,
    "win_rate": 0.28,
    "profit_factor": 0.8184660624220654,
    "expectancy": -390.16,
    "average_win": 6282.428571428572,
    "average_loss": -3837.9285714285716
  },
  {
    "direction": "SELL",
    "number_of_trades": 7,
    "net_profit": -673.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.8599375650364204,
    "expectancy": -96.14285714285714,
    "average_win": 2066.0,
    "average_loss": -1201.25
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 7,
    "net_profit": 8819.0,
    "win_rate": 0.42857142857142855,
    "profit_factor": 3.3706989247311827,
    "expectancy": 1259.857142857143,
    "average_win": 4179.666666666667,
    "average_loss": -3720.0
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 7,
    "net_profit": -15646.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.35512323798532686,
    "expectancy": -2235.1428571428573,
    "average_win": 8616.0,
    "average_loss": -4043.6666666666665
  },
  {
    "session": "NewYork",
    "number_of_trades": 5,
    "net_profit": 7159.0,
    "win_rate": 0.4,
    "profit_factor": 7.747408105560791,
    "expectancy": 1431.8,
    "average_win": 4110.0,
    "average_loss": -353.6666666666667
  },
  {
    "session": "Tokyo",
    "number_of_trades": 13,
    "net_profit": -10759.0,
    "win_rate": 0.23076923076923078,
    "profit_factor": 0.6352015732546706,
    "expectancy": -827.6153846153846,
    "average_win": 6244.666666666667,
    "average_loss": -3686.625
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 11,
    "net_profit": -10206.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.5074324324324324,
    "expectancy": -927.8181818181819,
    "average_win": 3504.6666666666665,
    "average_loss": -2960.0
  },
  {
    "weekday": "Mon",
    "number_of_trades": 6,
    "net_profit": 1540.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.1920678473434771,
    "expectancy": 256.6666666666667,
    "average_win": 4779.0,
    "average_loss": -2672.6666666666665
  },
  {
    "weekday": "Thu",
    "number_of_trades": 8,
    "net_profit": 16989.0,
    "win_rate": 0.5,
    "profit_factor": 2.5377443881245476,
    "expectancy": 2123.625,
    "average_win": 7009.25,
    "average_loss": -3682.6666666666665
  },
  {
    "weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": -7488.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1872.0,
    "average_win": null,
    "average_loss": -3744.0
  },
  {
    "weekday": "Wed",
    "number_of_trades": 3,
    "net_profit": -11262.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3754.0,
    "average_win": null,
    "average_loss": -3754.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_0.0895-0.121",
    "number_of_trades": 11,
    "net_profit": -514.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.9724514953371208,
    "expectancy": -46.72727272727273,
    "average_win": 9072.0,
    "average_loss": -3731.6
  },
  {
    "atr_band": "ATR_0.121-0.145",
    "number_of_trades": 10,
    "net_profit": 3750.0,
    "win_rate": 0.6,
    "profit_factor": 1.2226840855106889,
    "expectancy": 375.0,
    "average_win": 3431.6666666666665,
    "average_loss": -4210.0
  },
  {
    "atr_band": "ATR_0.145-0.334",
    "number_of_trades": 11,
    "net_profit": -13663.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.4069363660039934,
    "expectancy": -1242.090909090909,
    "average_win": 9375.0,
    "average_loss": -2559.777777777778
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.12-42.15",
    "number_of_trades": 11,
    "net_profit": -1747.0,
    "win_rate": 0.36363636363636365,
    "profit_factor": 0.9370427763162636,
    "expectancy": -158.8181818181818,
    "average_win": 6500.5,
    "average_loss": -3964.1428571428573
  },
  {
    "adx_band": "ADX_42.15-46.23",
    "number_of_trades": 10,
    "net_profit": -4199.0,
    "win_rate": 0.2,
    "profit_factor": 0.7341395466632898,
    "expectancy": -419.9,
    "average_win": 5797.5,
    "average_loss": -2632.3333333333335
  },
  {
    "adx_band": "ADX_46.23-65.43",
    "number_of_trades": 11,
    "net_profit": -4481.0,
    "win_rate": 0.2727272727272727,
    "profit_factor": 0.701127192689922,
    "expectancy": -407.3636363636364,
    "average_win": 3504.0,
    "average_loss": -2998.6
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.748-4.932",
    "number_of_trades": 11,
    "net_profit": -11510.0,
    "win_rate": 0.18181818181818182,
    "profit_factor": 0.6118567478249141,
    "expectancy": -1046.3636363636363,
    "average_win": 9072.0,
    "average_loss": -3706.75
  },
  {
    "hold_time_band": "HOLD_H_11.51-69.34",
    "number_of_trades": 11,
    "net_profit": 737.0,
    "win_rate": 0.45454545454545453,
    "profit_factor": 1.0700304066894717,
    "expectancy": 67.0,
    "average_win": 2252.2,
    "average_loss": -2104.8
  },
  {
    "hold_time_band": "HOLD_H_4.932-11.51",
    "number_of_trades": 10,
    "net_profit": 346.0,
    "win_rate": 0.2,
    "profit_factor": 1.018847368994444,
    "expectancy": 34.6,
    "average_win": 9352.0,
    "average_loss": -3671.6
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_25-2804",
    "number_of_trades": 11,
    "net_profit": -37624.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3420.3636363636365,
    "average_win": null,
    "average_loss": -3420.3636363636365
  },
  {
    "mfe_band": "MFE_2804-6694",
    "number_of_trades": 10,
    "net_profit": -19729.0,
    "win_rate": 0.2,
    "profit_factor": 0.05657039020657995,
    "expectancy": -1972.9,
    "average_win": 591.5,
    "average_loss": -2987.4285714285716
  },
  {
    "mfe_band": "MFE_6694-9709",
    "number_of_trades": 11,
    "net_profit": 46926.0,
    "win_rate": 0.6363636363636364,
    "profit_factor": null,
    "expectancy": 4266.0,
    "average_win": 6703.714285714285,
    "average_loss": null
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2575--391",
    "number_of_trades": 11,
    "net_profit": 43001.0,
    "win_rate": 0.6363636363636364,
    "profit_factor": 45.05840163934426,
    "expectancy": 3909.181818181818,
    "average_win": 6282.428571428572,
    "average_loss": -488.0
  },
  {
    "mae_band": "MAE_-3713--2575",
    "number_of_trades": 10,
    "net_profit": -15186.0,
    "win_rate": 0.1,
    "profit_factor": 0.16399669694467384,
    "expectancy": -1518.6,
    "average_win": 2979.0,
    "average_loss": -3027.5
  },
  {
    "mae_band": "MAE_-9115--3713",
    "number_of_trades": 11,
    "net_profit": -38242.0,
    "win_rate": 0.09090909090909091,
    "profit_factor": 0.029267673562634853,
    "expectancy": -3476.5454545454545,
    "average_win": 1153.0,
    "average_loss": -3939.5
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 6,
    "net_profit": 1017.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 1.1338333991314646,
    "expectancy": 169.5,
    "average_win": 8616.0,
    "average_loss": -1899.75
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 26,
    "net_profit": -11444.0,
    "win_rate": 0.3076923076923077,
    "profit_factor": 0.7753303099907729,
    "expectancy": -440.15384615384613,
    "average_win": 4936.625,
    "average_loss": -3638.3571428571427
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": -3829.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1914.5,
    "average_win": null,
    "average_loss": -1914.5
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 2,
    "net_profit": -3768.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -1884.0,
    "average_win": null,
    "average_loss": -3768.0
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 28,
    "net_profit": -2830.0,
    "win_rate": 0.32142857142857145,
    "profit_factor": 0.9444433538153477,
    "expectancy": -101.07142857142857,
    "average_win": 5345.444444444444,
    "average_loss": -3395.9333333333334
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 18,
    "net_profit": -41388.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.21296137828740944,
    "expectancy": -2299.3333333333335,
    "average_win": 3733.0,
    "average_loss": -3505.8
  },
  {
    "close_reason": "SL",
    "number_of_trades": 10,
    "net_profit": -5887.0,
    "win_rate": 0.2,
    "profit_factor": 0.010421919650361405,
    "expectancy": -588.7,
    "average_win": 31.0,
    "average_loss": -1983.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 4,
    "net_profit": 36848.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9212.0,
    "average_win": 9212.0,
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
    "net_profit": 20151.0,
    "win_rate": 0.5,
    "profit_factor": 2.8219710669077758,
    "expectancy": 2518.875,
    "average_win": 7802.75,
    "average_loss": -2765.0
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": -6458.0,
    "win_rate": 0.25,
    "profit_factor": 0.5724311440677966,
    "expectancy": -807.25,
    "average_win": 4323.0,
    "average_loss": -3020.8
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 8,
    "net_profit": -7721.0,
    "win_rate": 0.125,
    "profit_factor": 0.4778874763321612,
    "expectancy": -965.125,
    "average_win": 7067.0,
    "average_loss": -3697.0
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 8,
    "net_profit": -16399.0,
    "win_rate": 0.25,
    "profit_factor": 0.06739080982711557,
    "expectancy": -2049.875,
    "average_win": 592.5,
    "average_loss": -3516.8
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 8,
    "net_profit": 4604.0,
    "win_rate": 0.375,
    "profit_factor": 1.3116918285830343,
    "expectancy": 575.5,
    "average_win": 6458.333333333333,
    "average_loss": -3692.75
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 9,
    "net_profit": -2436.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.8147387634040612,
    "expectancy": -270.6666666666667,
    "average_win": 3571.0,
    "average_loss": -2629.8
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 6,
    "net_profit": 6943.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.6284395365677045,
    "expectancy": 1157.1666666666667,
    "average_win": 8995.5,
    "average_loss": -3682.6666666666665
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 6,
    "net_profit": -8276.0,
    "win_rate": 0.16666666666666666,
    "profit_factor": 0.003611846857693234,
    "expectancy": -1379.3333333333333,
    "average_win": 30.0,
    "average_loss": -2768.6666666666665
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 3,
    "net_profit": -11262.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3754.0,
    "average_win": null,
    "average_loss": -3754.0
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0476-1",
    "number_of_trades": 14,
    "net_profit": 48109.0,
    "win_rate": 0.6428571428571429,
    "profit_factor": null,
    "expectancy": 3436.3571428571427,
    "average_win": 5345.444444444444,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_1-2.19",
    "number_of_trades": 7,
    "net_profit": -16024.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2289.1428571428573,
    "average_win": null,
    "average_loss": -2289.1428571428573
  },
  {
    "giveback_band": "GIVEBACK_2.19-151",
    "number_of_trades": 11,
    "net_profit": -42512.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3864.7272727272725,
    "average_win": null,
    "average_loss": -3864.7272727272725
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
