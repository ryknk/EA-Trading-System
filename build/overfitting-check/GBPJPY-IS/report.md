# パフォーマンス分析レポート

- 取引数: 64
- 純利益: 33398.00
- 収益率: 3.34%
- CAGR: 1.51%
- 最大ドローダウン: 37365.00 (3.70%)
- ドローダウン算出元: ACCOUNT_EQUITY_SNAPSHOTS
- プロフィットファクター: 1.2729
- シャープレシオ: 0.6550
- 勝率: 35.94%
- 期待値: 521.84
- 最大連敗: 7

バックテスト結果だけを本番移行理由にしないでください。OOS、ウォークフォワード、デモ、小額実口座の順に検証します。

## Strategy別

```json
[
  {
    "strategy": "BREAKOUT",
    "number_of_trades": 56,
    "net_profit": 40580.0,
    "win_rate": 0.375,
    "profit_factor": 1.389989812981721,
    "expectancy": 724.6428571428571,
    "average_win": 6887.333333333333,
    "average_loss": -3060.4117647058824
  },
  {
    "strategy": "PULLBACK",
    "number_of_trades": 8,
    "net_profit": -7182.0,
    "win_rate": 0.25,
    "profit_factor": 0.6080550098231827,
    "expectancy": -897.75,
    "average_win": 5571.0,
    "average_loss": -3054.0
  }
]
```

## Symbol別

```json
[
  {
    "symbol": "GBPJPY_HIST",
    "number_of_trades": 64,
    "net_profit": 33398.0,
    "win_rate": 0.359375,
    "profit_factor": 1.2729085293108238,
    "expectancy": 521.84375,
    "average_win": 6772.869565217391,
    "average_loss": -3059.45
  }
]
```
