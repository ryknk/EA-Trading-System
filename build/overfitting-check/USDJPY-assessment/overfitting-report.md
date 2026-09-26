# 過学習疑い診断レポート

本レポートは過学習を断定するものではなく、疑いを検出する診断である。
Final Holdout期間は本判定に使用していない。

- 総合判定: **INSUFFICIENT_DATA**
- 判定信頼性の警告: あり（取引数不足）

## 判定理由

- FOLD2020: 判定スコア 0.0/10.0 → LOW
- FOLD2020: 取引数不足の疑い (IS=52, FOLD2020=22)
- FOLD2021: 判定スコア 0.0/10.0 → LOW
- FOLD2021: 取引数不足の疑い (IS=52, FOLD2021=28)
- FOLD2022: 判定スコア 0.0/10.0 → LOW
- FOLD2023: 判定スコア 0.0/10.0 → LOW
- FOLD2023: 取引数不足の疑い (IS=52, FOLD2023=20)
- FOLD2024: 判定スコア 3.0/10.0 → MODERATE
- FOLD2024/sharpe_ratio: IS=-0.3044321714208741 → -0.6467683163565996 (劣化率112.5%, HIGH)
- FOLD2024/expectancy: IS=-394.38461538461536 → -517.28 (劣化率31.2%, MODERATE)
- FOLD2024: 取引数不足の疑い (IS=52, FOLD2024=25)
- Walk Forward総合: 5Fold平均スコア 0.6/10.0 → LOW (最悪Fold: FOLD2024, スコア 3.0)
- 取引数が閾値(30件)未満の期間があるため、過学習判定の信頼性は低い。判定はINSUFFICIENT_DATAとする。

## 閾値設定

```json
{
  "degradation_moderate_rate": 0.3,
  "degradation_high_rate": 0.5,
  "score_moderate": 2.0,
  "score_high": 5.0,
  "minimum_trade_count": 30,
  "drawdown_relative_floor": 0.05
}
```

## Walk Forward比較

```json
[
  {
    "period": "FOLD2020",
    "in_sample_trade_count": 52,
    "comparison_trade_count": 22,
    "trade_count_sufficient": false,
    "score": 0.0,
    "max_score": 10.0,
    "classification": "LOW",
    "metric_comparisons": [
      {
        "metric": "profit_factor",
        "in_sample_value": 0.8279328109006091,
        "comparison_value": 1.6159273626806094,
        "degradation_rate": -0.9517614731596822,
        "severity": "LOW"
      },
      {
        "metric": "sharpe_ratio",
        "in_sample_value": -0.3044321714208741,
        "comparison_value": 0.7492560933132669,
        "degradation_rate": -3.46115937686963,
        "severity": "LOW"
      },
      {
        "metric": "expectancy",
        "in_sample_value": -394.38461538461536,
        "comparison_value": 995.9545454545455,
        "degradation_rate": -3.5253382272106673,
        "severity": "LOW"
      },
      {
        "metric": "net_profit",
        "in_sample_value": -20508.0,
        "comparison_value": 21911.0,
        "degradation_rate": -2.0684123268968206,
        "severity": "LOW"
      },
      {
        "metric": "max_drawdown_rate",
        "in_sample_value": 0.03335570642543326,
        "comparison_value": 0.01249756640382181,
        "degradation_rate": -0.4171628004322289,
        "severity": "LOW"
      }
    ]
  },
  {
    "period": "FOLD2021",
    "in_sample_trade_count": 52,
    "comparison_trade_count": 28,
    "trade_count_sufficient": false,
    "score": 0.0,
    "max_score": 10.0,
    "classification": "LOW",
    "metric_comparisons": [
      {
        "metric": "profit_factor",
        "in_sample_value": 0.8279328109006091,
        "comparison_value": 1.4480992638059913,
        "degradation_rate": -0.7490540835442641,
        "severity": "LOW"
      },
      {
        "metric": "sharpe_ratio",
        "in_sample_value": -0.3044321714208741,
        "comparison_value": 0.7613374416528818,
        "degradation_rate": -3.5008442376490527,
        "severity": "LOW"
      },
      {
        "metric": "expectancy",
        "in_sample_value": -394.38461538461536,
        "comparison_value": 849.9642857142857,
        "degradation_rate": -3.1551659282788598,
        "severity": "LOW"
      },
      {
        "metric": "net_profit",
        "in_sample_value": -20508.0,
        "comparison_value": 23799.0,
        "degradation_rate": -2.1604739613809247,
        "severity": "LOW"
      },
      {
        "metric": "max_drawdown_rate",
        "in_sample_value": 0.03335570642543326,
        "comparison_value": 0.03252471376384496,
        "degradation_rate": -0.016619853231765874,
        "severity": "LOW"
      }
    ]
  },
  {
    "period": "FOLD2022",
    "in_sample_trade_count": 52,
    "comparison_trade_count": 30,
    "trade_count_sufficient": true,
    "score": 0.0,
    "max_score": 10.0,
    "classification": "LOW",
    "metric_comparisons": [
      {
        "metric": "profit_factor",
        "in_sample_value": 0.8279328109006091,
        "comparison_value": 1.7078273033636422,
        "degradation_rate": -1.0627607468604863,
        "severity": "LOW"
      },
      {
        "metric": "sharpe_ratio",
        "in_sample_value": -0.3044321714208741,
        "comparison_value": 0.774635983427881,
        "degradation_rate": -3.5445273402361783,
        "severity": "LOW"
      },
      {
        "metric": "expectancy",
        "in_sample_value": -394.38461538461536,
        "comparison_value": 1113.2,
        "degradation_rate": -3.822625316949484,
        "severity": "LOW"
      },
      {
        "metric": "net_profit",
        "in_sample_value": -20508.0,
        "comparison_value": 33396.0,
        "degradation_rate": -2.628437682855471,
        "severity": "LOW"
      },
      {
        "metric": "max_drawdown_rate",
        "in_sample_value": 0.03335570642543326,
        "comparison_value": 0.016096,
        "degradation_rate": -0.34519412850866515,
        "severity": "LOW"
      }
    ]
  },
  {
    "period": "FOLD2023",
    "in_sample_trade_count": 52,
    "comparison_trade_count": 20,
    "trade_count_sufficient": false,
    "score": 0.0,
    "max_score": 10.0,
    "classification": "LOW",
    "metric_comparisons": [
      {
        "metric": "profit_factor",
        "in_sample_value": 0.8279328109006091,
        "comparison_value": 0.975957907456825,
        "degradation_rate": -0.17878877924308503,
        "severity": "LOW"
      },
      {
        "metric": "sharpe_ratio",
        "in_sample_value": -0.3044321714208741,
        "comparison_value": -0.025447492586141377,
        "degradation_rate": -0.9164099757677696,
        "severity": "LOW"
      },
      {
        "metric": "expectancy",
        "in_sample_value": -394.38461538461536,
        "comparison_value": -47.75,
        "degradation_rate": -0.8789252974448996,
        "severity": "LOW"
      },
      {
        "metric": "net_profit",
        "in_sample_value": -20508.0,
        "comparison_value": -955.0,
        "degradation_rate": -0.9534328067095768,
        "severity": "LOW"
      },
      {
        "metric": "max_drawdown_rate",
        "in_sample_value": 0.03335570642543326,
        "comparison_value": 0.03612447617569455,
        "degradation_rate": 0.0553753950052259,
        "severity": "LOW"
      }
    ]
  },
  {
    "period": "FOLD2024",
    "in_sample_trade_count": 52,
    "comparison_trade_count": 25,
    "trade_count_sufficient": false,
    "score": 3.0,
    "max_score": 10.0,
    "classification": "MODERATE",
    "metric_comparisons": [
      {
        "metric": "profit_factor",
        "in_sample_value": 0.8279328109006091,
        "comparison_value": 0.7628809270600315,
        "degradation_rate": 0.07857145288132188,
        "severity": "LOW"
      },
      {
        "metric": "sharpe_ratio",
        "in_sample_value": -0.3044321714208741,
        "comparison_value": -0.6467683163565996,
        "degradation_rate": 1.1245071220230847,
        "severity": "HIGH"
      },
      {
        "metric": "expectancy",
        "in_sample_value": -394.38461538461536,
        "comparison_value": -517.28,
        "degradation_rate": 0.3116130290618295,
        "severity": "MODERATE"
      },
      {
        "metric": "net_profit",
        "in_sample_value": -20508.0,
        "comparison_value": -12932.0,
        "degradation_rate": -0.3694168129510435,
        "severity": "LOW"
      },
      {
        "metric": "max_drawdown_rate",
        "in_sample_value": 0.03335570642543326,
        "comparison_value": 0.024774,
        "degradation_rate": -0.1716341285086651,
        "severity": "LOW"
      }
    ]
  }
]
```

```json
{
  "fold_count": 5,
  "mean_score": 0.6,
  "worst_fold": "FOLD2024",
  "worst_fold_score": 3.0,
  "classification": "LOW"
}
```
