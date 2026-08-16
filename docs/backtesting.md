# バックテスト

検証ゲートはStrategy Tester、インサンプル、アウトオブサンプル、ウォークフォワード、デモ、小額実口座、本番の順とし、前段を満たさず昇格しない。受入基準は実装前に固定し、結果を見て変更した場合は新しいアウトオブサンプル期間を確保する。

純利益、CAGR、最大ドローダウン、プロフィットファクター、シャープレシオ、勝率、平均利益・平均損失、期待値、最大連敗、取引数を、スプレッド、手数料、スワップ、スリッページを含む同一定義で記録する。約定差、拒否、API遅延、ML/LLM拒否率をバックテスト・フォワードテスト・実運用で比較する。

時点整合データ、確定足、タイムゾーン、DST、シンボル仕様を固定する。スプレッド拡大、スリッページ、通信欠損、モデル拒否、開始時期変更、パラメータ摂動のストレステストを行う。バックテストの好成績だけを本番移行理由にしない。

## Phase 13 Strategy Tester再現手順

`tools/run-strategy-tester.ps1`は `mt5/test-config/StrategyTester-USDJPY-H1.ini` を使い、USDJPY/H1、2020-01-01〜2025-12-31、Every tick based on real ticks、Mock ALLOWで実行する。事前にBroker口座へログインし、USDJPYのreal tick履歴を取得して、起動中のMT5を終了する。

```powershell
.\tools\run-strategy-tester.ps1 -TimeoutSeconds 900
```

結果は `results/backtests/<run-id>-USDJPY-H1/` へ保存する。メタデータは `results/backtests/run-metadata.template.json` を複製し、EA・Strategy・Config版と全入力値を記録する。

Phase 13の自動試行は初回`account is not specified`で開始できなかったが、2026-07-21にXMTrading-MT5（USDJPY/H1/2025年、100%リアルティック）で完走した（`results/backtests/20260721-231302-USDJPY-H1/`、総損益-95,024円・Profit Factor 0.59）。ただし2026-08-10、XMTrading-MT5はUSDJPYのreal tickデータを2022年1月分以降しか保持していないことを確認した（2020-2021指定時は「ヒストリー品質0%リアルティック」の合成データにフォールバックする）。このためブローカーをOANDA証券MT5（東京サーバー）へ切り替えたが、OANDA-Japan MT5 Demoサーバーのライブtickキャッシュも直近約1年分しか保持しておらず、同様に「ヒストリー品質2%リアルティック」となることが判明した（`results/backtests/20260816-113850-USDJPY-H1/INVALID-2pct-real-ticks.md`）。

2026-08-16、OANDA証券のWeb版Tickダウンロードツールから2016年9月以降のUSDJPY real tick（120か月分）を取得し、`USDJPY`の仕様を複製したCustom Symbol「USDJPY_HIST」へ`mt5/Tools/ImportOandaTicks.mq5`で投入する方式（`DECISIONS.md` DEC-023）で解決した。2016年9月単月・2020年通年の両方で「ヒストリー品質100%リアルティック」を確認済み。今後の実市場tick検証は`USDJPY_HIST`（2016-09〜2026-08の範囲）を対象に実行する。

**2026-08-16確定: In-Sample/Out-of-Sample/Walk Forward期間（`DECISIONS.md` DEC-024）。**

* 開発・In-Sample: **2017-09〜2020-12**（DEC-025で補正。当初案は2016-09だったが、Strategy Tester起動時のD1/H4インジケーターウォームアップに実データ最古日から約10か月のバッファが必要と判明したため、安全マージンを含めて2017-09へ補正した）
* OOS / Walk Forward評価: 2021-01〜2024-12
* Final Holdout: 2025-01〜2026-08（EA・MLモデル・閾値・SL/TP等をすべて固定した後に一度だけ評価する。開発・パラメータ調整・ML閾値調整には一切使用しない）

**2026-08-16判明: Custom Symbolのバッファ不足による取引数0件の異常。** In-Sample期間（当初案2016-09〜2020-12）でStrategy Testerを実行したところ完走したが、全期間（26,882本のH1確定足）で`SIGNAL_ERROR code=MARKET_DATA_UNAVAILABLE`となり取引が1件も発生しなかった。原因調査の結果、Tester起動時点でD1/H4インジケーターの計算に必要な事前バッファ（実データ最古日からの経過期間）が不足していたことが判明し、テスト実行中に指標が後から回復することもないと確認した。二分探索の結果、必要バッファは実データ最古日（2016-08-31）から約9〜10か月と判明し、In-Sample開始日を2017-09-01へ補正した（DEC-025）。詳細は`results/backtests/20260816-180519-USDJPY-H1/ANOMALY-zero-trades.md`参照。

Walk Forwardは、過去期間で学習・最適化し、直後の未来期間で検証するローリング方式（4年学習→1年検証、5 Fold）とする。

| Fold | 学習期間 | 検証期間 |
| --- | --- | --- |
| 1 | 2017-09〜2019-12 | 2020 |
| 2 | 2017-01〜2020-12 | 2021 |
| 3 | 2018-01〜2021-12 | 2022 |
| 4 | 2019-01〜2022-12 | 2023 |
| 5 | 2020-01〜2023-12 | 2024 |

Fold 1の学習期間開始もDEC-025に合わせて2017-09へ補正した。Fold 2以降の学習期間はrule-based Strategyの直接実行対象ではなく将来のML学習パイプライン向けであり、同様のバッファ制約が生じるかは未検証（DEC-025注意点参照）。OOS結果を見た後、同じOOS期間・Final Holdout期間へ再最適化しない。`mt5/test-config/StrategyTester-USDJPY-H1.ini`と`tools/run-strategy-tester.ps1`の既定Symbol/期間は、Final Holdoutを誤って消費しないようIn-Sample期間（`USDJPY_HIST`、2017-09-01〜2020-12-31）へ設定してある。各期間の実行は`-FromDate`/`-ToDate`を明示指定する。ML学習コードは時系列分割・gap・Walk Forwardと0.50/0.55/0.60/0.65/0.70の事前固定閾値比較を出力するが、実市場データでの評価は未実施である。

## Phase 10の共通指標定義

- 純利益: 決済済み取引の `net_pnl` 合計。`net_pnl` はcommission、swap、fee込みで、別列を再加算しない
- 収益率: `終了残高 / 初期残高 - 1`
- CAGR: 最初の建玉時刻から最後の決済時刻までが1日以上の場合に実時間で年率換算。1日未満または数値表現不能の場合は算出不能
- 最大DD: 口座equityスナップショットがあればそのピークから谷までを使用。なければ決済済み損益曲線を使用し、算出元を必ず記録
- Profit Factor: 総利益を総損失の絶対値で除算。損失取引がない場合は無限大にせず算出不能とする
- Sharpe: 暦日の日次収益率、標本標準偏差、年率化係数 `sqrt(365.2425)`。口座equityスナップショットがあればそれを優先し、なければ決済済み損益を使用する。無リスク金利はCLI設定値
- 勝率: 利益取引数を全取引数で除算。損益ゼロは勝ちに含めない
- 平均利益・平均損失: 正・負の取引を別々に平均。該当取引がなければ算出不能
- Expectancy: 1取引あたりの平均純損益
- 最大連敗: 純損益が負の連続数。損益ゼロで連敗を終了
- 取引数: 重複しない決済済み取引数

## 入力と検証

Phase 9の監査JSONL、または1行を1決済済み取引とする正規化CSVを受け付ける。複数の日別JSONLをまとめて読み、前日の候補と翌日以降の決済を候補IDで相関する。時刻にはUTC offsetを必須とし、重複trade ID、未知列、欠落列、非有限値、負またはゼロの数量・価格、決済が建玉より前のデータを拒否する。

```powershell
$env:PYTHONPATH='.'
python -m python.analysis.reports `
  --input audit-20250701.jsonl `
  --input audit-20250702.jsonl `
  --initial-balance 1000000 `
  --annual-risk-free-rate 0 `
  --output build/performance-report
```

出力はバージョン付きJSONサマリー、日本語Markdown、正規化取引CSV、DD付き資産曲線CSV、月次成績CSVである。JSON契約は `contracts/performance-report.schema.json` を正とし、将来の管理画面も同じ出力を利用する。
