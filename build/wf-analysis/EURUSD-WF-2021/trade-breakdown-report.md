# トレード条件別分析レポート

分析結果に基づく閾値の自動変更は行っていません。過剰最適化を避けるため、
本レポートは仮説の発見・検証にのみ使用し、変更の適用はユーザー判断で行ってください。

## 含み益からの反転（負けトレードが一度含み益になってからSLに到達したか）

- 負けトレード数: 17
- MFEデータのある負けトレード数: 17
- うち一度含み益になった数: 17
- 割合: 100.00%
- 反転前の平均含み益: 1941.59

## 決済時点でのGiveback（含み益ピークからの取りこぼし）

- 含み益（MFE>0）に達したトレード数: 29
- 平均Giveback比率: 357.57%
- 中央値Giveback比率: 221.90%
- 損益ゼロ以下まで完全反転した割合: 65.52%

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

- 決済件数: 16
- 純損益: -60038.00
- プロフィットファクター: 0.0000
- 勝率: 0.00%
- 期待値: -3752.38
- 平均逆行幅（R）: 0.7613
- うちTP相当R到達済みだった可能性のある件数（早期Exitの取りこぼし候補）: 0
- 上記件数の純損益合計: 算出不能

方向別:
```json
{
  "BUY": {
    "number_of_trades": 8,
    "net_profit": -29775.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3721.875,
    "average_win": null,
    "average_loss": -3721.875
  },
  "SELL": {
    "number_of_trades": 8,
    "net_profit": -30263.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3782.875,
    "average_win": null,
    "average_loss": -3782.875
  }
}
```

## 段階的Entry判定パイプライン（InpEntryUseStagedPipeline=true時のみ記録）

- 評価済み確定足数: 6270
- 最終Entry候補まで到達: 47
- Stage別棄却数（market_regime）: 5213
- Stage別棄却数（htf_bias）: 216
- Stage別棄却数（trend_strength_or_momentum_filter）: 424
- Stage別棄却数（setup_or_trigger）: 370
- Stage別棄却数（other）: 0

```json
{
  "REGIME_NOT_TRENDING": 5213,
  "RSI_FILTERED": 385,
  "ENTRY_PATTERN_NOT_FOUND": 370,
  "CONFIRMATION_ADX_TOO_LOW": 39,
  "TREND_NOT_ALIGNED": 216
}
```

## direction別

```json
[
  {
    "direction": "BUY",
    "number_of_trades": 14,
    "net_profit": -1390.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.9534852591774587,
    "expectancy": -99.28571428571429,
    "average_win": 7123.25,
    "average_loss": -3320.3333333333335
  },
  {
    "direction": "SELL",
    "number_of_trades": 15,
    "net_profit": 29777.0,
    "win_rate": 0.4,
    "profit_factor": 1.9839407857780127,
    "expectancy": 1985.1333333333334,
    "average_win": 10006.666666666666,
    "average_loss": -3782.875
  }
]
```

## session別

```json
[
  {
    "session": "London",
    "number_of_trades": 10,
    "net_profit": 34373.0,
    "win_rate": 0.5,
    "profit_factor": 3.2798302049479338,
    "expectancy": 3437.3,
    "average_win": 9890.0,
    "average_loss": -3769.25
  },
  {
    "session": "London_NewYork_Overlap",
    "number_of_trades": 6,
    "net_profit": 4744.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.316942811330839,
    "expectancy": 790.6666666666666,
    "average_win": 9856.0,
    "average_loss": -3742.0
  },
  {
    "session": "NewYork",
    "number_of_trades": 8,
    "net_profit": -8545.0,
    "win_rate": 0.25,
    "profit_factor": 0.5456478970596055,
    "expectancy": -1068.125,
    "average_win": 5131.0,
    "average_loss": -3134.5
  },
  {
    "session": "Tokyo",
    "number_of_trades": 5,
    "net_profit": -2185.0,
    "win_rate": 0.2,
    "profit_factor": 0.8065344430671153,
    "expectancy": -437.0,
    "average_win": 9109.0,
    "average_loss": -3764.6666666666665
  }
]
```

## weekday別

```json
[
  {
    "weekday": "Fri",
    "number_of_trades": 9,
    "net_profit": 15509.0,
    "win_rate": 0.4444444444444444,
    "profit_factor": 2.0055108921161824,
    "expectancy": 1723.2222222222222,
    "average_win": 7733.25,
    "average_loss": -3084.8
  },
  {
    "weekday": "Mon",
    "number_of_trades": 3,
    "net_profit": -7437.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2479.0,
    "average_win": null,
    "average_loss": -3718.5
  },
  {
    "weekday": "Thu",
    "number_of_trades": 8,
    "net_profit": 9990.0,
    "win_rate": 0.375,
    "profit_factor": 1.5305082045563168,
    "expectancy": 1248.75,
    "average_win": 9607.0,
    "average_loss": -3766.2
  },
  {
    "weekday": "Tue",
    "number_of_trades": 5,
    "net_profit": -1892.0,
    "win_rate": 0.2,
    "profit_factor": 0.8307994991951351,
    "expectancy": -378.4,
    "average_win": 9290.0,
    "average_loss": -3727.3333333333335
  },
  {
    "weekday": "Wed",
    "number_of_trades": 4,
    "net_profit": 12217.0,
    "win_rate": 0.5,
    "profit_factor": 2.680005500550055,
    "expectancy": 3054.25,
    "average_win": 9744.5,
    "average_loss": -3636.0
  }
]
```

## atr_band別

```json
[
  {
    "atr_band": "ATR_-0.000329-0.000915",
    "number_of_trades": 10,
    "net_profit": 38327.0,
    "win_rate": 0.5,
    "profit_factor": 4.398386238694804,
    "expectancy": 3832.7,
    "average_win": 9921.0,
    "average_loss": -3759.3333333333335
  },
  {
    "atr_band": "ATR_0.000915-0.00129",
    "number_of_trades": 9,
    "net_profit": -3475.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 0.8491229593608892,
    "expectancy": -386.1111111111111,
    "average_win": 9778.5,
    "average_loss": -3290.285714285714
  },
  {
    "atr_band": "ATR_0.00129-0.00245",
    "number_of_trades": 10,
    "net_profit": -6465.0,
    "win_rate": 0.3,
    "profit_factor": 0.7497677659080353,
    "expectancy": -646.5,
    "average_win": 6457.0,
    "average_loss": -3690.8571428571427
  }
]
```

## adx_band別

```json
[
  {
    "adx_band": "ADX_40.12-42.57",
    "number_of_trades": 10,
    "net_profit": 10993.0,
    "win_rate": 0.4,
    "profit_factor": 1.5842057713769464,
    "expectancy": 1099.3,
    "average_win": 7452.5,
    "average_loss": -3763.4
  },
  {
    "adx_band": "ADX_42.57-45.53",
    "number_of_trades": 9,
    "net_profit": 14297.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 1.9612721038122773,
    "expectancy": 1588.5555555555557,
    "average_win": 9723.333333333334,
    "average_loss": -2974.6
  },
  {
    "adx_band": "ADX_45.53-54.81",
    "number_of_trades": 10,
    "net_profit": 3097.0,
    "win_rate": 0.3,
    "profit_factor": 1.1170622921076505,
    "expectancy": 309.7,
    "average_win": 9851.0,
    "average_loss": -3779.4285714285716
  }
]
```

## hold_time_band別

```json
[
  {
    "hold_time_band": "HOLD_H_0.604-2.459",
    "number_of_trades": 10,
    "net_profit": 3257.0,
    "win_rate": 0.3,
    "profit_factor": 1.1245030581039754,
    "expectancy": 325.7,
    "average_win": 9805.666666666666,
    "average_loss": -3737.1428571428573
  },
  {
    "hold_time_band": "HOLD_H_16.89-72",
    "number_of_trades": 10,
    "net_profit": 24017.0,
    "win_rate": 0.5,
    "profit_factor": 2.5941192088145493,
    "expectancy": 2401.7,
    "average_win": 7816.6,
    "average_loss": -3013.2
  },
  {
    "hold_time_band": "HOLD_H_2.459-16.89",
    "number_of_trades": 9,
    "net_profit": 1113.0,
    "win_rate": 0.2222222222222222,
    "profit_factor": 1.0588266384778013,
    "expectancy": 123.66666666666667,
    "average_win": 10016.5,
    "average_loss": -3784.0
  }
]
```

## mfe_band別

```json
[
  {
    "mfe_band": "MFE_155-2102",
    "number_of_trades": 10,
    "net_profit": -37491.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3749.1,
    "average_win": null,
    "average_loss": -3749.1
  },
  {
    "mfe_band": "MFE_2102-6683",
    "number_of_trades": 9,
    "net_profit": -21778.0,
    "win_rate": 0.1111111111111111,
    "profit_factor": 0.03410653301991396,
    "expectancy": -2419.777777777778,
    "average_win": 769.0,
    "average_loss": -3757.8333333333335
  },
  {
    "mfe_band": "MFE_6683-1.036e+04",
    "number_of_trades": 10,
    "net_profit": 87656.0,
    "win_rate": 0.9,
    "profit_factor": 812.6296296296297,
    "expectancy": 8765.6,
    "average_win": 9751.555555555555,
    "average_loss": -108.0
  }
]
```

## mae_band別

```json
[
  {
    "mae_band": "MAE_-2453--118",
    "number_of_trades": 10,
    "net_profit": 67944.0,
    "win_rate": 0.7,
    "profit_factor": 630.1111111111111,
    "expectancy": 6794.4,
    "average_win": 9721.714285714286,
    "average_loss": -108.0
  },
  {
    "mae_band": "MAE_-3724--2453",
    "number_of_trades": 9,
    "net_profit": -1432.0,
    "win_rate": 0.3333333333333333,
    "profit_factor": 0.9346506639894127,
    "expectancy": -159.11111111111111,
    "average_win": 6827.0,
    "average_loss": -3652.1666666666665
  },
  {
    "mae_band": "MAE_-4090--3724",
    "number_of_trades": 10,
    "net_profit": -38125.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3812.5,
    "average_win": null,
    "average_loss": -3812.5
  }
]
```

## market_regime_trend別

```json
[
  {
    "market_regime_trend": "TrendDown",
    "number_of_trades": 16,
    "net_profit": 24757.0,
    "win_rate": 0.375,
    "profit_factor": 1.728039994118512,
    "expectancy": 1547.3125,
    "average_win": 9793.666666666666,
    "average_loss": -3778.3333333333335
  },
  {
    "market_regime_trend": "TrendUp",
    "number_of_trades": 13,
    "net_profit": 3630.0,
    "win_rate": 0.3076923076923077,
    "profit_factor": 1.1388623235530393,
    "expectancy": 279.2307692307692,
    "average_win": 7442.75,
    "average_loss": -3267.625
  }
]
```

## market_regime_volatility別

```json
[
  {
    "market_regime_volatility": "HighVolatility",
    "number_of_trades": 2,
    "net_profit": 5713.0,
    "win_rate": 0.5,
    "profit_factor": 2.5113756613756615,
    "expectancy": 2856.5,
    "average_win": 9493.0,
    "average_loss": -3780.0
  },
  {
    "market_regime_volatility": "LowVolatility",
    "number_of_trades": 6,
    "net_profit": 22854.0,
    "win_rate": 0.5,
    "profit_factor": 4.061486939048895,
    "expectancy": 3809.0,
    "average_win": 10106.333333333334,
    "average_loss": -3732.5
  },
  {
    "market_regime_volatility": "NormalVolatility",
    "number_of_trades": 21,
    "net_profit": -180.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.9963190936790659,
    "expectancy": -8.571428571428571,
    "average_win": 8120.166666666667,
    "average_loss": -3492.9285714285716
  }
]
```

## close_reason別

```json
[
  {
    "close_reason": "EXPERT",
    "number_of_trades": 17,
    "net_profit": -59269.0,
    "win_rate": 0.058823529411764705,
    "profit_factor": 0.012808554582098005,
    "expectancy": -3486.4117647058824,
    "average_win": 769.0,
    "average_loss": -3752.375
  },
  {
    "close_reason": "SL",
    "number_of_trades": 3,
    "net_profit": -108.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -36.0,
    "average_win": null,
    "average_loss": -108.0
  },
  {
    "close_reason": "TP",
    "number_of_trades": 9,
    "net_profit": 87764.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 9751.555555555555,
    "average_win": 9751.555555555555,
    "average_loss": null
  }
]
```

## close_session別

```json
[
  {
    "close_session": "London",
    "number_of_trades": 13,
    "net_profit": 18845.0,
    "win_rate": 0.38461538461538464,
    "profit_factor": 1.6267460423041107,
    "expectancy": 1449.6153846153845,
    "average_win": 9782.6,
    "average_loss": -3758.5
  },
  {
    "close_session": "London_NewYork_Overlap",
    "number_of_trades": 8,
    "net_profit": 21608.0,
    "win_rate": 0.375,
    "profit_factor": 3.7881290322580643,
    "expectancy": 2701.0,
    "average_win": 9786.0,
    "average_loss": -2583.3333333333335
  },
  {
    "close_session": "NewYork",
    "number_of_trades": 7,
    "net_profit": -8325.0,
    "win_rate": 0.2857142857142857,
    "profit_factor": 0.5521063108624308,
    "expectancy": -1189.2857142857142,
    "average_win": 5131.0,
    "average_loss": -3717.4
  },
  {
    "close_session": "Tokyo",
    "number_of_trades": 1,
    "net_profit": -3741.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3741.0,
    "average_win": null,
    "average_loss": -3741.0
  }
]
```

## close_weekday別

```json
[
  {
    "close_weekday": "Fri",
    "number_of_trades": 10,
    "net_profit": 43557.0,
    "win_rate": 0.6,
    "profit_factor": 3.8232434534612394,
    "expectancy": 4355.7,
    "average_win": 9830.833333333334,
    "average_loss": -3857.0
  },
  {
    "close_weekday": "Mon",
    "number_of_trades": 7,
    "net_profit": -14230.0,
    "win_rate": 0.14285714285714285,
    "profit_factor": 0.051270084672311485,
    "expectancy": -2032.857142857143,
    "average_win": 769.0,
    "average_loss": -2999.8
  },
  {
    "close_weekday": "Thu",
    "number_of_trades": 4,
    "net_profit": -1772.0,
    "win_rate": 0.25,
    "profit_factor": 0.8426986240568132,
    "expectancy": -443.0,
    "average_win": 9493.0,
    "average_loss": -3755.0
  },
  {
    "close_weekday": "Tue",
    "number_of_trades": 4,
    "net_profit": 1787.0,
    "win_rate": 0.25,
    "profit_factor": 1.2381713981074236,
    "expectancy": 446.75,
    "average_win": 9290.0,
    "average_loss": -3751.5
  },
  {
    "close_weekday": "Wed",
    "number_of_trades": 4,
    "net_profit": -955.0,
    "win_rate": 0.25,
    "profit_factor": 0.912793352205278,
    "expectancy": -238.75,
    "average_win": 9996.0,
    "average_loss": -3650.3333333333335
  }
]
```

## giveback_band別

```json
[
  {
    "giveback_band": "GIVEBACK_-0.0085-0.89",
    "number_of_trades": 10,
    "net_profit": 88533.0,
    "win_rate": 1.0,
    "profit_factor": null,
    "expectancy": 8853.3,
    "average_win": 8853.3,
    "average_loss": null
  },
  {
    "giveback_band": "GIVEBACK_0.89-2.802",
    "number_of_trades": 9,
    "net_profit": -22655.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2517.222222222222,
    "average_win": null,
    "average_loss": -3236.4285714285716
  },
  {
    "giveback_band": "GIVEBACK_2.802-24.35",
    "number_of_trades": 10,
    "net_profit": -37491.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -3749.1,
    "average_win": null,
    "average_loss": -3749.1
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
