# パフォーマンス分析レポート

- 取引数: 52
- 純利益: -20508.00
- 収益率: -2.05%
- CAGR: -0.90%
- 最大ドローダウン: 33694.00 (3.34%)
- ドローダウン算出元: ACCOUNT_EQUITY_SNAPSHOTS
- プロフィットファクター: 0.8279
- シャープレシオ: -0.3044
- 勝率: 30.77%
- 期待値: -394.38
- 最大連敗: 10

バックテスト結果だけを本番移行理由にしないでください。OOS、ウォークフォワード、デモ、小額実口座の順に検証します。

## Strategy別

```json
[
  {
    "strategy": "BREAKOUT",
    "number_of_trades": 39,
    "net_profit": -13161.0,
    "win_rate": 0.28205128205128205,
    "profit_factor": 0.8512343446217842,
    "expectancy": -337.46153846153845,
    "average_win": 6846.090909090909,
    "average_loss": -3276.5925925925926
  },
  {
    "strategy": "PULLBACK",
    "number_of_trades": 13,
    "net_profit": -7347.0,
    "win_rate": 0.38461538461538464,
    "profit_factor": 0.7608242724135685,
    "expectancy": -565.1538461538462,
    "average_win": 4674.2,
    "average_loss": -3839.75
  }
]
```

## Symbol別

```json
[
  {
    "symbol": "USDJPY_HIST",
    "number_of_trades": 52,
    "net_profit": -20508.0,
    "win_rate": 0.3076923076923077,
    "profit_factor": 0.8279328109006091,
    "expectancy": -394.38461538461536,
    "average_win": 6167.375,
    "average_loss": -3405.3142857142857
  }
]
```
