# パフォーマンス分析レポート

- 取引数: 45
- 純利益: -66868.00
- 収益率: -6.69%
- CAGR: -3.07%
- 最大ドローダウン: 67209.00 (6.62%)
- ドローダウン算出元: ACCOUNT_EQUITY_SNAPSHOTS
- プロフィットファクター: 0.4328
- シャープレシオ: -0.1516
- 勝率: 15.56%
- 期待値: -1485.96
- 最大連敗: 13

バックテスト結果だけを本番移行理由にしないでください。OOS、ウォークフォワード、デモ、小額実口座の順に検証します。

## Strategy別

```json
[
  {
    "strategy": "BREAKOUT",
    "number_of_trades": 41,
    "net_profit": -55980.0,
    "win_rate": 0.17073170731707318,
    "profit_factor": 0.47680776096526073,
    "expectancy": -1365.3658536585365,
    "average_win": 7288.142857142857,
    "average_loss": -3343.65625
  },
  {
    "strategy": "PULLBACK",
    "number_of_trades": 4,
    "net_profit": -10888.0,
    "win_rate": 0.0,
    "profit_factor": 0.0,
    "expectancy": -2722.0,
    "average_win": null,
    "average_loss": -3629.3333333333335
  }
]
```

## Symbol別

```json
[
  {
    "symbol": "EURUSD_HIST",
    "number_of_trades": 45,
    "net_profit": -66868.0,
    "win_rate": 0.15555555555555556,
    "profit_factor": 0.4327692242439666,
    "expectancy": -1485.9555555555555,
    "average_win": 7288.142857142857,
    "average_loss": -3368.1428571428573
  }
]
```
