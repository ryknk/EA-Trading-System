# Phase 10 実装記録

## 実装目的

バックテスト、フォワードテスト、デモ、実運用で同じ指標定義を使用し、結果の比較可能性と再現性を確保する。Phase 9監査ログから決済済み取引と口座equityを復元し、将来の管理画面でも利用できる機械可読レポートを生成する。

## 変更ファイル

- `python/analysis/drawdown.py`: DD曲線、ピーク・谷・回復時刻の算出
- `python/analysis/performance.py`: 取引正規化、主要パフォーマンス指標、日次収益率
- `python/analysis/reports.py`: 監査JSONL・CSV入力、候補相関、Strategy・symbol・月次集計、CLI、成果物出力
- `python/tests/test_analysis.py`: 指標定義、異常入力、日跨ぎ相関、CLI、厳格JSONテスト
- `contracts/performance-report.schema.json`: 管理画面向けレポート契約v1
- `tools/test-phase10.ps1`: Phase 10一括検証
- `README.md`、`python/README.md`、`docs/backtesting.md`、`docs/operations.md`: 日本語の利用・運用文書

## 設計判断

- 分析の1行は約定ではなく、重複しない決済済み取引とする。部分約定の生DEALを直接合計しない。
- Phase 9 `TRADE_CLOSED.payload.pnl` はcommission、swap、fee込みの純損益であり、commission・swap列を再加算しない。
- 複数の日別JSONLを一括走査し、候補日と決済日が異なっても `trade_candidate_id` でStrategyを相関する。
- 最大DDとSharpeは口座equityスナップショットを優先し、ない場合だけ決済損益曲線を使用する。算出元をレポートへ保存する。
- 初回スナップショットが含み損状態でもDDを過小評価しないよう、ユーザー指定の初期残高を基準点にする。
- Profit Factorの分母がゼロ、標本不足のSharpe、1日未満のCAGRはInfinityやNaNを出さずJSON `null` とする。
- 時刻はUTC offset必須、数値は有限値必須とし、未知列・欠落列・重複trade IDを拒否する。
- Phase 10はpandas・numpyだけを使い、サーバー実行に不要な描画依存を増やさない。資産曲線・月次CSVを可視化入力として出力する。

## 想定リスクと対策

- 指標定義差: 定義をJSON `definitions` と `docs/backtesting.md` に固定し、schema versionを付ける。
- 手数料二重計上: `net_pnl`を正本とし、commission・swapは説明列に限定するテストを設ける。
- 含み損の見落とし: account equityスナップショットがある場合は最大DDとSharpeで優先する。
- 日跨ぎ相関切れ: 全入力JSONLをまとめて相関する回帰テストを設ける。
- 不正データによる好成績化: 非有限値、時刻逆転、重複、非正の数量・価格、naive時刻を即時拒否する。
- 少数標本の過大評価: 算出不能値をnullにし、取引数と分析期間を必ず併記する。

## 実装内容

- 純利益、収益率、CAGR、最大DD金額・率、Profit Factor、Sharpe、勝率、平均利益、平均損失、Expectancy、最大連敗、取引数を実装した。
- DDのピーク、谷、回復時刻と、決済損益だけの参考DDを併記する。
- Strategy別・symbol別に取引数、純利益、勝率、Profit Factor、Expectancyを集計する。
- 月次純利益、月初残高、月次収益率を出力する。
- Phase 9監査JSONL、正規化CSV、追加equityスナップショットCSVをCLIから読み込める。
- `performance-summary.json`、`report.md`、`trades-normalized.csv`、`equity-curve.csv`、`monthly-performance.csv` を生成する。
- JSONはNaN・Infinityを禁止し、将来のWeb管理画面向け契約を追加した。

## テスト結果

- Phase 10分析テスト: 10件成功。
- Python・Lambda・CDK全回帰: 61件成功。
- CDK synth: 成功。
- MQL5コードはPhase 10で変更していない。

## 残課題

- MT5 Strategy TesterのHTML/XML出力を正規化取引形式へ変換するimporter。
- バックテストとフォワード間のスリッページ、拒否率、API latency、ML・LLM VETO率の差分レポート。
- ウォークフォワード各foldの統合レポートと受入基準の自動判定。
- bootstrap信頼区間、Monte Carlo取引順序入替、パラメータ摂動などの頑健性分析。
- Phase 11でCloudWatchメトリクスとアラームを分析レポートへ関連付ける。
- Web管理画面や静的グラフ生成は後続。Phase 10のJSON・CSVを正本として利用する。
