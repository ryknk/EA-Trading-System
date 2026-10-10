# パフォーマンス分析レポート

- 取引数: 55
- 純利益: 7654.00
- 収益率: 0.77%
- CAGR: 0.34%
- 最大ドローダウン: 64227.00 (6.20%)
- ドローダウン算出元: ACCOUNT_EQUITY_SNAPSHOTS
- プロフィットファクター: 1.0685
- シャープレシオ: -0.1086
- 勝率: 25.45%
- 期待値: 139.16
- 最大連敗: 11

バックテスト結果だけを本番移行理由にしないでください。OOS、ウォークフォワード、デモ、小額実口座の順に検証します。

## Strategy別

```json
[
  {
    "strategy": "BREAKOUT",
    "number_of_trades": 45,
    "net_profit": 19334.0,
    "win_rate": 0.26666666666666666,
    "profit_factor": 1.2259436718476102,
    "expectancy": 429.64444444444445,
    "average_win": 8742.0,
    "average_loss": -2950.689655172414
  },
  {
    "strategy": "PULLBACK",
    "number_of_trades": 10,
    "net_profit": -11680.0,
    "win_rate": 0.2,
    "profit_factor": 0.5541133804161099,
    "expectancy": -1168.0,
    "average_win": 7257.5,
    "average_loss": -3274.375
  }
]
```

## Symbol別

```json
[
  {
    "symbol": "EURJPY_HIST",
    "number_of_trades": 55,
    "net_profit": 7654.0,
    "win_rate": 0.2545454545454545,
    "profit_factor": 1.0684829776763745,
    "expectancy": 139.16363636363636,
    "average_win": 8529.92857142857,
    "average_loss": -3020.675675675676
  }
]
```
