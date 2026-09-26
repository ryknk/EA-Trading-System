# 過学習疑い診断レポート

本レポートは過学習を断定するものではなく、疑いを検出する診断である。
Final Holdout期間は本判定に使用していない。

- 総合判定: **INSUFFICIENT_DATA**
- 判定信頼性の警告: あり（取引数不足）

## 判定理由

- FOLD2020: 判定スコア 1.0/10.0 → LOW
- FOLD2020/net_profit: IS=33398.0 → 20416.0 (劣化率38.9%, MODERATE)
- FOLD2020: 取引数不足の疑い (IS=64, FOLD2020=29)
- FOLD2021: 判定スコア 1.0/10.0 → LOW
- FOLD2021/net_profit: IS=33398.0 → 21897.0 (劣化率34.4%, MODERATE)
- FOLD2021: 取引数不足の疑い (IS=64, FOLD2021=25)
- FOLD2022: 判定スコア 1.0/10.0 → LOW
- FOLD2022/net_profit: IS=33398.0 → 21032.0 (劣化率37.0%, MODERATE)
- FOLD2022: 取引数不足の疑い (IS=64, FOLD2022=13)
- FOLD2023: 判定スコア 1.0/10.0 → LOW
- FOLD2023/net_profit: IS=33398.0 → 18556.0 (劣化率44.4%, MODERATE)
- FOLD2023: 取引数不足の疑い (IS=64, FOLD2023=24)
- FOLD2024: 判定スコア 4.0/10.0 → MODERATE
- FOLD2024/sharpe_ratio: IS=0.655024309148594 → 0.40067766621490514 (劣化率38.8%, MODERATE)
- FOLD2024/expectancy: IS=521.84375 → 352.0571428571429 (劣化率32.5%, MODERATE)
- FOLD2024/net_profit: IS=33398.0 → 12322.0 (劣化率63.1%, HIGH)
- Walk Forward総合: 5Fold平均スコア 1.6/10.0 → LOW (最悪Fold: FOLD2024, スコア 4.0)
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
    "in_sample_trade_count": 64,
    "comparison_trade_count": 29,
    "trade_count_sufficient": false,
    "score": 1.0,
    "max_score": 10.0,
    "classification": "LOW",
    "metric_comparisons": [
      {
        "metric": "profit_factor",
        "in_sample_value": 1.2729085293108238,
        "comparison_value": 1.3708628519527701,
        "degradation_rate": -0.07695315129593848,
        "severity": "LOW"
      },
      {
        "metric": "sharpe_ratio",
        "in_sample_value": 0.655024309148594,
        "comparison_value": 0.6928741330037045,
        "degradation_rate": -0.057783846074824306,
        "severity": "LOW"
      },
      {
        "metric": "expectancy",
        "in_sample_value": 521.84375,
        "comparison_value": 704.0,
        "degradation_rate": -0.3490628181328223,
        "severity": "LOW"
      },
      {
        "metric": "net_profit",
        "in_sample_value": 33398.0,
        "comparison_value": 20416.0,
        "degradation_rate": 0.3887059105335649,
        "severity": "MODERATE"
      },
      {
        "metric": "max_drawdown_rate",
        "in_sample_value": 0.03703340291034081,
        "comparison_value": 0.012703,
        "degradation_rate": -0.4866080582068162,
        "severity": "LOW"
      }
    ]
  },
  {
    "period": "FOLD2021",
    "in_sample_trade_count": 64,
    "comparison_trade_count": 25,
    "trade_count_sufficient": false,
    "score": 1.0,
    "max_score": 10.0,
    "classification": "LOW",
    "metric_comparisons": [
      {
        "metric": "profit_factor",
        "in_sample_value": 1.2729085293108238,
        "comparison_value": 1.4954520771110509,
        "degradation_rate": -0.17483074602439524,
        "severity": "LOW"
      },
      {
        "metric": "sharpe_ratio",
        "in_sample_value": 0.655024309148594,
        "comparison_value": 0.8178817985816456,
        "degradation_rate": -0.24862816105975527,
        "severity": "LOW"
      },
      {
        "metric": "expectancy",
        "in_sample_value": 521.84375,
        "comparison_value": 875.88,
        "degradation_rate": -0.6784334391280915,
        "severity": "LOW"
      },
      {
        "metric": "net_profit",
        "in_sample_value": 33398.0,
        "comparison_value": 21897.0,
        "degradation_rate": 0.34436193784058927,
        "severity": "MODERATE"
      },
      {
        "metric": "max_drawdown_rate",
        "in_sample_value": 0.03703340291034081,
        "comparison_value": 0.01242540612222345,
        "degradation_rate": -0.4921599357623472,
        "severity": "LOW"
      }
    ]
  },
  {
    "period": "FOLD2022",
    "in_sample_trade_count": 64,
    "comparison_trade_count": 13,
    "trade_count_sufficient": false,
    "score": 1.0,
    "max_score": 10.0,
    "classification": "LOW",
    "metric_comparisons": [
      {
        "metric": "profit_factor",
        "in_sample_value": 1.2729085293108238,
        "comparison_value": 1.8315344166370142,
        "degradation_rate": -0.4388578397134638,
        "severity": "LOW"
      },
      {
        "metric": "sharpe_ratio",
        "in_sample_value": 0.655024309148594,
        "comparison_value": 0.8170349302269369,
        "degradation_rate": -0.2473352802568894,
        "severity": "LOW"
      },
      {
        "metric": "expectancy",
        "in_sample_value": 521.84375,
        "comparison_value": 1617.8461538461538,
        "degradation_rate": -2.1002501301321588,
        "severity": "LOW"
      },
      {
        "metric": "net_profit",
        "in_sample_value": 33398.0,
        "comparison_value": 21032.0,
        "degradation_rate": 0.3702616923169052,
        "severity": "MODERATE"
      },
      {
        "metric": "max_drawdown_rate",
        "in_sample_value": 0.03703340291034081,
        "comparison_value": 0.010883,
        "degradation_rate": -0.5230080582068162,
        "severity": "LOW"
      }
    ]
  },
  {
    "period": "FOLD2023",
    "in_sample_trade_count": 64,
    "comparison_trade_count": 24,
    "trade_count_sufficient": false,
    "score": 1.0,
    "max_score": 10.0,
    "classification": "LOW",
    "metric_comparisons": [
      {
        "metric": "profit_factor",
        "in_sample_value": 1.2729085293108238,
        "comparison_value": 1.4558541738318675,
        "degradation_rate": -0.14372253803664425,
        "severity": "LOW"
      },
      {
        "metric": "sharpe_ratio",
        "in_sample_value": 0.655024309148594,
        "comparison_value": 0.717424937734487,
        "degradation_rate": -0.0952645996711204,
        "severity": "LOW"
      },
      {
        "metric": "expectancy",
        "in_sample_value": 521.84375,
        "comparison_value": 773.1666666666666,
        "degradation_rate": -0.4816056849711559,
        "severity": "LOW"
      },
      {
        "metric": "net_profit",
        "in_sample_value": 33398.0,
        "comparison_value": 18556.0,
        "degradation_rate": 0.4443978681358165,
        "severity": "MODERATE"
      },
      {
        "metric": "max_drawdown_rate",
        "in_sample_value": 0.03703340291034081,
        "comparison_value": 0.01805957645362093,
        "degradation_rate": -0.37947652913439756,
        "severity": "LOW"
      }
    ]
  },
  {
    "period": "FOLD2024",
    "in_sample_trade_count": 64,
    "comparison_trade_count": 35,
    "trade_count_sufficient": true,
    "score": 4.0,
    "max_score": 10.0,
    "classification": "MODERATE",
    "metric_comparisons": [
      {
        "metric": "profit_factor",
        "in_sample_value": 1.2729085293108238,
        "comparison_value": 1.1747256175377896,
        "degradation_rate": 0.07713273146672386,
        "severity": "LOW"
      },
      {
        "metric": "sharpe_ratio",
        "in_sample_value": 0.655024309148594,
        "comparison_value": 0.40067766621490514,
        "degradation_rate": 0.3883010742979764,
        "severity": "MODERATE"
      },
      {
        "metric": "expectancy",
        "in_sample_value": 521.84375,
        "comparison_value": 352.0571428571429,
        "degradation_rate": 0.3253590890814676,
        "severity": "MODERATE"
      },
      {
        "metric": "net_profit",
        "in_sample_value": 33398.0,
        "comparison_value": 12322.0,
        "degradation_rate": 0.6310557518414276,
        "severity": "HIGH"
      },
      {
        "metric": "max_drawdown_rate",
        "in_sample_value": 0.03703340291034081,
        "comparison_value": 0.015835918534800812,
        "degradation_rate": -0.4239496875107999,
        "severity": "LOW"
      }
    ]
  }
]
```

```json
{
  "fold_count": 5,
  "mean_score": 1.6,
  "worst_fold": "FOLD2024",
  "worst_fold_score": 4.0,
  "classification": "LOW"
}
```
