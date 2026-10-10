# バックテスト

検証ゲートはStrategy Tester、インサンプル、アウトオブサンプル、ウォークフォワード、デモ、小額実口座、本番の順とし、前段を満たさず昇格しない。受入基準は実装前に固定し、結果を見て変更した場合は新しいアウトオブサンプル期間を確保する。

純利益、CAGR、最大ドローダウン、プロフィットファクター、シャープレシオ、勝率、平均利益・平均損失、期待値、最大連敗、取引数を、スプレッド、手数料、スワップ、スリッページを含む同一定義で記録する。約定差、拒否、API遅延、ML/LLM拒否率をバックテスト・フォワードテスト・実運用で比較する。

時点整合データ、確定足、タイムゾーン、DST、シンボル仕様を固定する。スプレッド拡大、スリッページ、通信欠損、モデル拒否、開始時期変更、パラメータ摂動のストレステストを行う。バックテストの好成績だけを本番移行理由にしない。

## Phase 13 Strategy Tester再現手順

`tools/run-strategy-tester.ps1`は `mt5/test-config/StrategyTester-USDJPY-H1.ini` を使い、USDJPY/H1、2020-01-01〜2025-12-31、Every tick based on real ticks、Mock ALLOWで実行する。事前にBroker口座へログインし、USDJPYのreal tick履歴を取得して、起動中のMT5を終了する。

```powershell
.\tools\run-strategy-tester.ps1 -TimeoutSeconds 900
```

結果は `results/backtests/<run-id>-<Symbol>-<Period>/` へ保存する（`<Symbol>`・`<Period>`はTemplateの`[Tester]`セクションから読み取る。`-Symbol`未指定時は`StrategyTester-USDJPY-H1.ini`の`Symbol=USDJPY_HIST`がそのまま使われるため、`<run-id>-USDJPY_HIST-H1/`となる）。メタデータは `results/backtests/run-metadata.template.json` を複製し、EA・Strategy・Config版と全入力値を記録する。

## tickデータの取得・MT5投入（2026-09-21追加、`DECISIONS.md` DEC-036）

OANDA以外のヒストリカルtick（Dukascopy等）の取得・正規化・検証・MT5 Custom Symbolへの投入は`tools/tick-data.ps1`で行う。取込後のCustom Symbolは、上記の`-CaseFile`ケースの`symbol`に指定すればStrategy Testerで使える。

**2026-09-22: 既存の`*_HIST`10銘柄（OANDA由来）を再投入した**。旧Importerがバッチごとに末尾128 tick（全体で0.641%）を保存していなかったため、元zipから補った（`DECISIONS.md` DEC-037、[tickデータパイプライン](tick-data-pipeline.md)）。**このため、それ以前に得たバックテスト結果（IS・Walk Forward・Final Holdout・他資産確認）は再投入前のtickによる値**だった（バーも再生成されており、結果が微小に変わり得る）。同日、IS期間の一部・Walk Forward・Final Holdoutを再実行して影響を確認した（EA・パラメータは無変更）。IS期間はほぼ無変化（純利益差+0.6%）だったが、Walk Forward（+7.8%）・Final Holdout（損失37%縮小）では無視できない幅の変化があった。ただし年次expectancyのトレンド形状・Final Holdoutでの符号反転・NO-GO判定という中核的な結論は維持された。詳細は`docs/production-readiness-report.md` 7.5節、`TASKS.md` 3.1節を参照。他資産確認（3資産・6資産）は今回は再実行していない。

## 複数ケース実行（Cross-Asset Validation、OOS、Walk Forward、Stress Test等の共通基盤）

`tools/run-strategy-tester.ps1`は`-CaseFile`を指定すると、複数銘柄・複数期間のケースを同じ1ケース実行処理で順番に実行する汎用Runnerとして動作する（`-CaseFile`未指定時は従来どおりの単体実行）。用途別の専用Runnerは追加せず、Cross-Asset Validation・OOS・Walk Forward・Final Holdout・Stress Testいずれもこの基盤を使う。

CaseFileはJSON配列（または`cases`キーを持つオブジェクト）で、各ケースへ最低限`case_name`・`symbol`・`from_date`・`to_date`・`template`を指定する。`template`は同一の入力パラメータ（`[TesterInputs]`）を複数ケースで共有する汎用Template（例: `mt5/test-config/StrategyTester-Generic-H1.ini`）を指すことができ、`symbol`・`from_date`・`to_date`はケースごとに実行時へ上書きされる（Templateが宣言する`Symbol`/`InpSymbol`を`-CaseFile`経由・`-Symbol`明示指定時のみ上書きする。単体実行をデフォルト引数のまま呼び出した場合はTemplateの値をそのまま使う＝既存の単体実行との後方互換性を維持）。

```powershell
.\tools\run-strategy-tester.ps1 -CaseFile mt5\test-config\cases\cross-symbol-2020-2024.json
```

結果は `results/backtests/<run-id>-cases/` 配下へ保存する。

* `manifest.json`: Run ID、InstallPath/TerminalData/TimeoutSeconds、CaseFileパスとSHA-256、ケースごとのSymbol/期間/Template/Template SHA-256/Expert/Deposit/実行結果（Succeeded/Failed）・失敗理由・監査ログ格納先・分析結果パスを記録する（再現用の識別情報）。
* 各ケースの結果は `<CaseName>-<Symbol>-<FromDateCompact>_<ToDateCompact>/` の専用フォルダへ保存し、ケース間の結果混同を防ぐ（監査JSONLの混入防止処理は既存どおりケースごとに実行する）。
* 全ケース終了後、監査JSONLが取得できたケースは既存の`python.analysis.reports`を再利用してケース単位の`performance-summary.json`等を生成し、`summary.csv`・`summary.md`へCaseName・Symbol・FromDate・ToDate・Net Profit・CAGR・Max Drawdown・Profit Factor・Sharpe Ratio・Win Rate・Average Win/Loss・Expectancy・Max Consecutive Losses・Trades・Status・ResultPathを集計する。
* 1ケースが失敗（Terminal未検出、Timeout、レポート未生成等）しても後続ケースは継続し、失敗理由は`manifest.json`と`summary.csv`/`summary.md`へ記録される。

**進捗ログ（2026-09-13追加）。** 複数ケース実行中はターミナルへ次の進捗ログを出力する（`manifest.json`等の実行結果ファイルには記録しない、ログ専用の概算値）。

```text
STRATEGY_TESTER_BATCH_START total=<ケース総数> case_file=<CaseFileパス>
STRATEGY_TESTER_CASE_START case=<CaseName> index=<現在の件数>/<総数> symbol=... from=... to=...
STRATEGY_TESTER_CASE_END case=<CaseName> index=<現在の件数>/<総数> status=Succeeded|Failed elapsed_seconds=<当該ケースの所要秒数> remaining=<残り件数> eta_seconds=<残り件数×平均所要秒数の概算値>
STRATEGY_TESTER_BATCH_COMPLETED total=... succeeded=... failed=... manifest=... summary=...
```

`eta_seconds`はそれまでに完了したケースの平均所要時間から算出する概算値であり、ケースごとの期間長・銘柄・Timeout設定の違いは考慮しない。

Phase 13の自動試行は初回`account is not specified`で開始できなかったが、2026-07-21にXMTrading-MT5（USDJPY/H1/2025年、100%リアルティック）で完走した（`results/backtests/20260721-231302-USDJPY-H1/`、総損益-95,024円・Profit Factor 0.59）。ただし2026-08-10、XMTrading-MT5はUSDJPYのreal tickデータを2022年1月分以降しか保持していないことを確認した（2020-2021指定時は「ヒストリー品質0%リアルティック」の合成データにフォールバックする）。このためブローカーをOANDA証券MT5（東京サーバー）へ切り替えたが、OANDA-Japan MT5 Demoサーバーのライブtickキャッシュも直近約1年分しか保持しておらず、同様に「ヒストリー品質2%リアルティック」となることが判明した（`results/backtests/20260816-113850-USDJPY-H1/INVALID-2pct-real-ticks.md`）。

2026-08-16、OANDA証券のWeb版Tickダウンロードツールから2016年9月以降のUSDJPY real tick（120か月分）を取得し、`USDJPY`の仕様を複製したCustom Symbol「USDJPY_HIST」へ`mt5/Tools/ImportOandaTicks.mq5`で投入する方式（`DECISIONS.md` DEC-023）で解決した。2016年9月単月・2020年通年の両方で「ヒストリー品質100%リアルティック」を確認済み。今後の実市場tick検証は`USDJPY_HIST`（2016-09〜2026-08の範囲）を対象に実行する。

**2026-08-16確定: In-Sample/Out-of-Sample/Walk Forward期間（`DECISIONS.md` DEC-024）。**

* 開発・In-Sample: **2017-09〜2020-12**（DEC-025で補正。当初案は2016-09だったが、Strategy Tester起動時のD1/H4インジケーターウォームアップに実データ最古日から約10か月のバッファが必要と判明したため、安全マージンを含めて2017-09へ補正した）
* OOS / Walk Forward評価: 2021-01〜2024-12
* Final Holdout: 2025-01〜2026-08（EA・MLモデル・閾値・SL/TP等をすべて固定した後に一度だけ評価する。開発・パラメータ調整・ML閾値調整には一切使用しない。**2026-09-17実施済み**。4銘柄合計で純利益-28,991円・期待値-160.2円/トレードとなり、Walk Forward（+290.4円/トレード）から明確に悪化した。原因分析の結果、戦略コアの実質勝率が2021年以降緩やかに悪化し続ける構造的トレンドの延長と判明。Final Holdoutは消費済みのため代替期間なし。詳細は`TASKS.md` 2.1.4節、`docs/production-readiness-report.md` 7.5節参照）

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

## 非FX資産（JP225・US30・XAUUSD・US100・US500・US2000）のCustom Symbol仕様設定（2026-09-19、`DECISIONS.md` DEC-033・DEC-035）

接続先Broker（OANDA-Japan MT5 Demo）は全51銘柄がFXのみで、JP225・US30・XAUUSDの実Symbolがない。複製元なしで作成した`JP225_HIST`・`US30_HIST`・`XAUUSD_HIST`は仕様が初期値のままで、現行EAを実行しても取引が成立しなかった（Point=0.0001・契約サイズ100000・Volume 1e-8等のため、`SPREAD_TOO_WIDE`・`TICK_VALUE_UNAVAILABLE`・`INVALID_EXPOSURE_INPUT`で全候補が拒否される）。EA側の不具合ではなく、Custom Symbol側の仕様未設定が原因である。

| 状態 | 内容 |
| --- | --- |
| JP225_HIST | 仕様設定・バー再生成・EA動作確認済み（Locally Tested。2021-04〜12でRISK_DECISION承認10件、証拠金も計算される） |
| US30_HIST | 同上（2021-04〜12で承認19件、`required_margin`約18.5万円）。バー再生成は2020-04〜2026-09の全月・約1.25億tick、失敗0 |
| XAUUSD_HIST | 同上（2023-07〜12で承認10件、`required_margin`約5.5万円）。バー再生成は2022-06〜2026-09の全月・約2.46億tick、失敗0 |
| US100_HIST | 仕様設定・動作確認済み（Locally Tested。2021-06〜12で承認14件、`required_margin`約5.4万〜24.2万円。InpMaxSpreadPoints=60。DEC-035） |
| US500_HIST | 同上（2021-04〜12で承認34件。InpMaxSpreadPoints=20） |
| US2000_HIST | 同上（2021-04〜12で承認17件。InpMaxSpreadPoints=540） |

**手順（銘柄ごと。すべてMT5停止中に実行する）:**

1. `bases\Custom\ticks\<symbol>`をバックアップする（Digits変更でバー履歴が消えるため。tickは消えない）。
2. `mt5/Tools/ApplyCfdSymbolSpec.mq5`で仕様を適用する（`InpApply=true`。`InpApply=false`は現状値の出力のみ）。`InpMarginRateOnly=true`はCalcModeと証拠金率のみを設定し、Digitsを変えないためバー履歴は消えない。
3. Digitsを変えるとバー履歴（`.hcc`）が消えるため、**手順1でtickフォルダとバー履歴の両方をバックアップしておき、適用後にバー履歴のバックアップを戻す**（Digits変更後に元のバー履歴を戻しても動作することを、未使用のUS500_HISTで確認済み）。`RebuildBarsFromTicks`（`ApplyCfdSymbolSpec`の`InpRebuildFromMonth`を含む）は、terminalのtick読み取りAPIが直近月で約1%しか返さない仕様のため、直近月のtickを欠落させる（2026-09-19に3銘柄で発生し、バックアップから復元）ので、使わない。バー履歴のバックアップがない場合は、影響月のバーを`BarsFileTool`の削除モードで削除し、`ExportM1BarsEA`でTesterに全tickから生成させたバーを取り込む（DECISIONS.md DEC-033、TASKS.md参照）。
4. `mt5/Experts/DiagnoseSymbolSpecEA.mq5`（Strategy Tester内でSymbol仕様と`OrderCalcProfit`/`OrderCalcMargin`を出力）で、Tester内の仕様を確認する。Terminal上の診断（`mt5/Tools/DiagnoseSymbolSpec.mq5`）はカスタム銘柄のTickSize/TickValueが0に見えるため判定に使わない（Tester内の値が正）。

**証拠金計算（Tester、実測）:** CFD（2）は数量×契約サイズ×価格×証拠金率で計算される。CFDINDEX（3）・FUTURES（1）は`SYMBOL_MARGIN_INITIAL`（固定額）×証拠金率で、固定額が0だと証拠金が0になる。CFDLEVERAGE（4）は口座レバレッジでも割られる。よって非FX資産はCFD（2）を使う。

**Testerのレバレッジ（2026-09-19判明）:** iniの`Leverage=10`のような数値のみの指定は無視され、Testerは`terminal.ini`に保存された値（実測で1:100）を使う。`Leverage=1:25`のように`1:N`形式で書くと反映される。既存の全テンプレート（77件）は`Leverage=10`だったため、2026-09-19までの全実行が1:100で走っていた（実口座のレバレッジは1:25）。同日、77件を`Leverage=1:25`へ修正し、以降の実行は1:25で走る。Final Holdout（4銘柄・181トレード・-28,991円）とWalk Forward（20ケース・520トレード）を1:25で再実行し、取引数・純損益が完全一致することを確認した（最低の証拠金維持率は低下したがガード150%には抵触せず）。詳細はTASKS.mdを参照。過去の`run-metadata`のtemplate_sha256は修正前のテンプレートのハッシュである。

**注意:** これらの資産は初見資産であり、動作確認以外（パラメータ探索・採用判断・Final Holdoutの代替）の根拠には使わない。仕様値は2026-09-19にOANDA公式ページの原文で照合した（`DECISIONS.md` DEC-033・DEC-035の「原ページとの照合結果」。US100・US500・US2000も同様にDEC-035へ記録。US100の最小取引単位も2021-05-31より前は1.00で、動作確認は2021-06-01以降で行う。US30のVolume Maxは100が正で、`ApplyCfdSymbolSpec.mq5`は訂正済み、実Symbolへは2026-09-19に再適用済み。XAUUSDの取引数量の刻みは原ページに記載なく未確認。US30の最小取引単位は2021-05-31より前は1.00だった。Custom Symbolは変更せず、US30・US100の動作確認は2021-06-01以降で行い、それ以前を含む結果は「当時は発注できなかった数量を含む」と注記する。DEC-033）。`InpMaxSpreadPoints`は非FX資産では専用テンプレートで決める（Pointが正しくなっても、既定値30では全候補が拒否される）。値はFX4銘柄の30 pointsの価格比（0.0227%）を基準価格へ適用して事前に固定した（JP225 110、US30 110、XAUUSD 770 points、`DECISIONS.md` DEC-034）。結果を見て調整しない。ただし全期間のスプレッド分布を確認した結果、JP225の2024年以降とXAUUSDの2025年以降は、Brokerのスプレッド水準の変化により固定値では候補の1〜4割が`SPREAD_TOO_WIDE`で拒否される（US30は全期間で2%以下）。非FX資産の結果には`SPREAD_TOO_WIDE`の割合を併記し、これらの期間を他の期間と単純に比較しない（DEC-034「追加確認」）。

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

## 過学習疑い診断

`python.analysis.overfitting` は、In-Sample・Out-of-Sample・Walk Forward各Foldの `performance-summary.json`（上記コマンドの出力）を比較し、過学習の疑いを診断する。過学習を断定する機能ではなく、疑いを検出する診断機能である。Final Holdout（2025-01〜2026-08）は本診断の対象に含めない。

Profit Factor、Sharpe Ratio、Expectancy、Net Profitの劣化率（`(IS − 比較対象) / |IS|`）と、Max Drawdownの悪化率（`(比較対象 − IS) / max(|IS|, drawdown_relative_floor)`）をそれぞれ算出し、各指標をLOW/MODERATE/HIGH/UNKNOWN（算出不能）に区分してスコア化する。単一指標のHIGHのみではMODERATE止まりとし、複数指標が揃って劣化した場合のみHIGHへ総合判定する。Walk Forwardは各Foldを個別に比較したうえで、Foldごとのスコア平均で総合判定する。IS側またはOOS/WF側いずれかの取引数が閾値未満の場合、判定結果はLOW/MODERATE/HIGHではなく`INSUFFICIENT_DATA`とし、信頼性が低いことを明示する。

閾値（劣化率・スコア・最小取引数等）はハードコードせず、`--thresholds-json`でJSONファイルから上書きできる。既定値は`OverfittingThresholds`（`python/analysis/overfitting.py`）を参照。

```powershell
$env:PYTHONPATH='.'
python -m python.analysis.overfitting `
  --in-sample results/backtests/<is-run>/performance-summary.json `
  --oos results/backtests/<oos-run>/performance-summary.json `
  --walk-forward-fold FOLD1=results/backtests/<fold1-run>/performance-summary.json `
  --walk-forward-fold FOLD2=results/backtests/<fold2-run>/performance-summary.json `
  --output build/overfitting-report
```

出力は `overfitting-assessment.json`（JSON契約は `contracts/overfitting-report.schema.json` を正とする）と `overfitting-report.md` である。

## 条件別分析（Entry/Exit改善根拠の把握）

`python.analysis.trade_breakdown` は、Phase 9監査JSONL（`CANDIDATE`・`RISK_DECISION`・`TRADE_CLOSED`・`TRADE_ANALYTICS`イベント）から1トレードごとの文脈情報を再構成し、条件別（Buy/Sell、Entry曜日、Entry Session、ATR帯、ADX帯、保有時間帯、MFE帯、MAE帯、市場レジームTrend、市場レジームVolatility、決済トリガー`close_reason`、Exit曜日`close_weekday`、Exit Session`close_session`、Giveback帯`giveback_band`）にTrades・Win Rate・Profit Factor・Expectancy・Net Profit・平均利益・平均損失を集計する。エントリー条件自体の改善かExit条件の改善か、特定方向・時間帯・相場環境による偏りがあるか、負けトレードが一度含み益になってからSLに到達しているかを判断する材料を提供するための分析専用機能であり、閾値の自動変更は行わない。

**Exit（決済）側の分析（2026-08-17実装）。** `TRADE_CLOSED`ペイロードへMT5の`DEAL_REASON`（決済を発生させたトリガー）を`close_reason`として追加記録した（`SL`/`TP`/`SO`/`EXPERT`/`CLIENT`等。`EXPERT`はEA発注によるEmergency Close等）。現時点のEAにはトレーリングストップや時間切れ決済のロジックはなく、決済は事実上SL到達・TP到達・保護SLなしのEmergency closeの3種類のみである。あわせて、決済時刻（Exit）基準の曜日・Session（`close_weekday`・`close_session`、Entry基準の既存`weekday`・`session`とは別集計）と、一度到達した含み益（MFE）に対して決済までにどれだけ手放したかを示すGiveback比率（`giveback_ratio`=`(mfe-net_pnl)/mfe`、MFE<=0のトレードは対象外）を追加した。レポートの`giveback_from_peak_profit`セクションは、勝敗を問わず含み益到達後の平均・中央値Giveback比率と、損益ゼロ以下まで完全反転した割合（`giveback_ratio>=1.0`）を要約する。これらはエントリー条件ではなく、決済ロジック（SL/TP幅、保有時間、決済タイミング）の改善余地を判断する材料である。

**市場レジーム判定（2026-08-17実装）。** EA側`CMarketRegimeClassifier`（`mt5/Include/Filter/MarketRegimeClassifier.mqh`）が、既存のADX/ATR/H1 EMA(Fast) Indicatorハンドルを再利用し、確定足データのみでEntry候補ごとにTrend（`TrendUp`/`TrendDown`/`Range`）とVolatility（`HighVolatility`/`NormalVolatility`/`LowVolatility`）を判定する。判定に必要なデータが不足する場合（バックテスト開始直後のバッファ不足等）は`Unknown`とする。閾値は固定値ではなくEA input（`InpRegimeTrendAdxMin`・`InpRegimeAtrBaselinePeriod`・`InpRegimeHighVolatilityRatio`・`InpRegimeLowVolatilityRatio`・`InpRegimeMaSlopeLookback`、詳細は`docs/configuration.md`）で設定する。判定結果は`CANDIDATE`イベントpayloadの`market_regime_trend`・`market_regime_volatility`へ記録されるのみで、Entry判定・売買制御には一切使用しない（判定と売買制御の分離）。現時点ではレジームによるEntry禁止・売買ロジック変更は行っていない。

**段階的Entry判定パイプライン（2026-08-22実装）。** 市場レジーム判定は当初分析専用（Entry判定に不使用）だったが、`InpEntryUseStagedPipeline`（既定値`false`）を`true`にすると、`CTrendFollowingStrategy::Evaluate()`をMarket Regime→HTF Bias（D1/H4トレンド一致）→Setup（押し目/戻り成立）→Entry Trigger（再加速/レンジ突破）→Entryという4段階として明示的に評価し、Market RegimeがRange/Unknownの確定足を追加で棄却できるようになった（`InpEntryRequireMarketRegimeTrend`、既定値`true`）。`InpEntryUseStagedPipeline=false`では判定式・発注挙動とも既存方式と完全に同一である（Strategy Tester再実行による実証は`DECISIONS.md` DEC-027参照）。`InpEntryUseStagedPipeline=true`の場合のみ、毎確定足の評価結果（成立・否決を問わず）を新規イベント`ENTRY_PIPELINE`（`stage_market_regime`・`stage_htf_bias`・`stage_breakout_setup_passed`・`stage_breakout_trigger_passed`・`stage_pullback_setup_passed`・`stage_pullback_trigger_passed`・`final_status`・`reason_code`）へ記録する。`python.analysis.trade_breakdown.entry_pipeline_funnel_summary()`がこのログから、各段階（`market_regime`・`htf_bias`・`trend_strength_or_momentum_filter`・`setup_or_trigger`）でどれだけ棄却されたかを集計し、`write_report(..., input_paths=...)`経由でレポートJSON（`entry_pipeline_funnel`キー、任意項目）・Markdownへ出力する。詳細な設定項目は`docs/configuration.md`「段階的Entry判定パイプライン」を参照。

`InpAuditFileEnabled=true`（既定値）でStrategy Testerを実行すると、`Terminal\Common\Files\EaTradingSystem\Audit\audit-<run-id>.jsonl`（`FILE_COMMON`、2026-09-07変更、旧: `MQL5\Files`配下の`audit-YYYYMMDD.jsonl`）にCANDIDATE（エントリー時ATR・ADX・Spread・時刻を含む）、RISK_DECISION（承認リスク額）、TRADE_CLOSED、TRADE_ANALYTICS（MFE・MAE、`mfe_time`・`post_peak_mae`）が記録される。`tools/run-strategy-tester.ps1` はStrategy Tester実行のたびに`InpAuditRunId`へReport名と同一の値を設定するため、run-idはReport名（例: `ets-20200101-000000-USDJPY-H1`）と一致する。実行後にこの`audit-<run-id>.jsonl`を検出できた場合、自動的に `results/backtests/<run-id>-USDJPY-H1/audit/` へ複製する（見つからない場合はベストエフォートで警告を出すのみで、Strategy Tester自体の成功判定には影響しない）。`FILE_COMMON`はStrategy Tester Agentのサンドボックスの外に保存されるため、VM実行でMT5終了後にサンドボックスがcleanupされても監査JSONLは消失しない（詳細はDECISIONS.md DEC-030を参照）。

**Peak到達時刻・Peak後の最大逆行の追跡（2026-09-06追加）。** 従来のTRADE_ANALYTICSはMFE/MAEの最終値のみを記録し、いつPeakに到達したか・Peak後どこまで逆行したかは分からなかった（`POSITION_SNAPSHOT`は日次1回のみで再構成不可）。`CTradeAnalyticsTracker`（`mt5/Include/Logging/TradeAnalyticsTracker.mqh`）へ`mfe_time`（MFEが最後に更新された時刻＝Peak到達時刻）と`post_peak_mae`（Peak確定後に観測された含み損益の最小値、新高値更新のたびに現在値へリセット）の追跡を追加し、`TRADE_ANALYTICS`のPayloadへ含めた。更新ロジックは純粋関数`CTradeAnalyticsRules::UpdateExtreme`へ分離し、`TestTradeAnalyticsTracker.mq5`で単体テストする。`python.analysis.trade_breakdown.build_trade_context()`はこれらから`time_to_peak_hours`（Entry→Peak）・`peak_to_close_hours`（Peak→Close）・`post_peak_mae_r`（Peak確定後の最大逆行、R換算）・`reached_tp_equivalent_r`（MFE_RがそのトレードのTP相当R（CANDIDATE.risk_reward_ratio）以上に達したかの近似指標）を算出する。2026-09-06以前の監査ログ（新フィールド無し）は該当列がNaN/NaTになるのみで後方互換。

```powershell
$env:PYTHONPATH='.'
python -m python.analysis.trade_breakdown `
  --input results/backtests/<run-id>-USDJPY-H1/audit/audit-<run-id>.jsonl `
  --output build/trade-breakdown-report
```

出力は `trade-breakdown-report.json`（JSON契約は `contracts/trade-breakdown-report.schema.json` を正とする）、`trade-breakdown-report.md`、および条件別列（`entry_atr`・`entry_adx`・`entry_spread_points`・`risk_budget`・`mfe`・`mae`・`r_multiple`・`hold_time_hours`・`weekday`・`session`・`atr_band`・`adx_band`・`hold_time_band`・`mfe_band`・`mae_band`・`market_regime_trend`・`market_regime_volatility`・`close_reason`・`close_weekday`・`close_session`・`giveback_ratio`・`giveback_band`）を付加した `trades-with-context.csv` である。ATR帯・ADX帯・保有時間帯・MFE帯・MAE帯・Giveback帯は実データの分位点（三分位）から算出し、固定のしきい値をハードコードしない。Session区分（Tokyo/London/London_NewYork_Overlap/NewYork）はUTC時刻に基づく概算区分であり、DSTは考慮しない簡略化である。R換算損益（`r_multiple`）は該当候補が承認された `RISK_DECISION` の `risk_budget`（発注時点のリスク許容額）に対する比率で、EA側での追加ロジックなしにPython側で算出する。`market_regime_trend`・`market_regime_volatility`はEA側の判定結果をそのまま再構成した値であり、Python側は判定ロジックを持たない。`close_reason`はMT5の`DEAL_REASON`をそのまま文字列化した値であり、EA側で決済理由を推定・分類するロジックは持たない。CLIから実行した場合（`--input`で指定した監査JSONLに`ENTRY_PIPELINE`イベントが含まれる場合のみ）、レポートJSON・Markdownへ`entry_pipeline_funnel`（段階的Entry判定パイプラインのStage別棄却件数）が追加される。

### トレンド継続反転Exit比較分析（2026-09-12実装）

条件別分析（`reversal_from_profit`・`giveback_from_peak_profit`）で確認された「トレンド相場の負けトレードの多くが含み益ピーク→反転→初期SL到達というパターンを辿っている」という所見を受け、トレンド継続反転Exit（`InpEnableTrendReversalExit`、既定値`false`、詳細は`docs/configuration.md`「トレンド継続反転Exit」参照）を追加した。目的はIn-SampleのProfit Factor最大化ではなく、OOSで観測された「利益からSLへの反転損失」の抑制であるため、特定パラメータをIS上で最適化して固定するのではなく、**Baseline（`InpEnableTrendReversalExit=false`）とON（`true`）のバックテスト結果を同一期間・同一パラメータで比較する**運用を前提とする。

発動したトレードはEA側`CPositionExitEvaluator::EvaluateTrendReversalExits`が送出する`TREND_REVERSAL_EXIT`イベント（`reason_code`固定値`TrendReversalConfirmed`、`trend_direction`、`peak_price`、`peak_mfe_r_multiple`、`retracement_r_multiple`、`confirmation_count`）で識別する。TIME_STOP_EXIT/RANGE_EXITと同じ理由（MT5の`DEAL_REASON`はEA発注による決済をすべて`EXPERT`に一括りにする）で、`close_reason`だけでは区別できない。

```powershell
$env:PYTHONPATH='.'
# Baseline
python -m python.analysis.trade_breakdown --input results/backtests/<baseline-run-id>-USDJPY-H1/audit/audit-<baseline-run-id>.jsonl --output build/trend-reversal-baseline
# ON
python -m python.analysis.trade_breakdown --input results/backtests/<on-run-id>-USDJPY-H1/audit/audit-<on-run-id>.jsonl --output build/trend-reversal-on
```

`trade-breakdown-report.json`の`trend_reversal_exit`セクション（`trades_closed_by_trend_reversal_exit`・`net_profit`・`profit_factor`・`win_rate`・`expectancy`・`average_peak_mfe_r_multiple`・`average_retracement_r_multiple`・`by_trend_direction`）に加え、レポート全体のPF・Net Profit・Expectancy・Max DD・Win Rate・平均利益/平均損失・Trade数（`aggregate_trade_group`が既存のPerformance Report集計と共通）をBaseline/ON間で比較する。Exit理由別件数は`breakdowns`の`close_reason`列（TIME_STOP_EXIT/RANGE_EXITと同様、実際にはEXPERTへ統合されるため`trend_reversal_exit_triggered`フラグと併用する）、Peak MFEは`mfe_band`・`trend_reversal_peak_mfe_r_multiple`列を参照する。

**「最終的にTPへ到達していた勝ちトレードを早期Exitしていないか」の確認**: `trend_reversal_exit.trades_that_would_likely_have_reached_tp`（および`net_pnl_of_trades_that_would_likely_have_reached_tp`）は、反転Exitで決済されたトレードのうち、既存の汎用指標`reached_tp_equivalent_r`（MFE_RがそのトレードのTP相当R以上に達したか）がTrueだったものの件数・純損益合計を示す。この件数が多い、または純損益合計がプラスに大きい場合、反転Exitが「本来TPへ到達していたはずの利益」を早期に打ち切ってしまっている可能性を示す。`InpTrendReversalActivationR`・`InpTrendReversalRetraceR`・`InpTrendReversalConfirmationTicks`はこの指標とOOS全体のPF/Net Profitの両方を見ながら判断し、IS単体の指標最大化だけを理由に固定しない。

### 初期逆行Exit比較分析（2026-09-12実装・検証）

トレンド継続反転ExitのConfirmationTicksスイープ（Fold1-5×4銘柄、`results/backtests/20260912-150203-cases`、ticks=5設定）で決済されたSLトレード254件を分析したところ、**92.5%（235件）が`InpTrendReversalActivationR`（含み益ピークによる反転監視の開始ライン、既定1.0R）へ一度も到達していない**ことが判明した。トレンド継続反転Exitは含み益ピークの存在を前提とするため、この92.5%の損失パターンには構造的に対処できない。初期逆行Exit（`InpEnableEarlyAdverseExit`、既定値`false`、詳細は`docs/configuration.md`「初期逆行Exit」参照）は、含み益ピークを一切参照せず、建値からの逆行のみを基準にすることで、この損失パターンへの対処を狙う新規Exitである。

**検証結果（2026-09-12〜13実施、Fold1-5×4銘柄、`InpEarlyAdverseExitTriggerR`=0.3/0.5/0.6/0.65/0.7/0.75/0.8/0.85/0.9、ConfirmationTicks=5固定、180ケース）**: Baseline（OFF、`results/backtests/20260912-164730-cases`、514トレード・純利益+118,533円、PF1.108、勝率36.6%）に対し、純利益はTriggerRに対して単調ではなく**TriggerR=0.70で単峰性のピーク（純利益+181,266円、Baseline比+62,733円、PF1.186）**を示した。0.3〜0.65はいずれもBaseline未達（0.5は黒字→赤字に転落）、0.75以降はBaselineへ緩やかに収束する（1.0Rに近づくほど通常のSLとの差がなくなるため構造的に自然）。Fold×銘柄20区分中、0.70で12区分・0.75で14区分・0.80で13区分が改善しており、特定の1銘柄・1年に依存した見かけ上の改善ではない。最良設定（0.70）でも発動率は49.1%（全トレードの約半数）に達しており、この機構は「損切りラインを全体的に手前へシフトして平均損失を圧縮する」タイプの効果であって、悪いトレードだけを狙い撃ちする精密フィルタではない。詳細な数値と追加の調整案（TrendReversalExitとの併用検証等）は`TASKS.md`セクション2.1.3を参照。

**併用検証結果（2026-09-13実施）**: `InpEnableTrendReversalExit=true`（Activation=1.0/Retrace=0.5/Ticks=5）と`InpEnableEarlyAdverseExit=true`（TriggerR=0.7/Ticks=5）を同時に有効化すると、Baseline比+75,214円（+63.5%）、EarlyAdverseExit単独比でも+12,481円の上乗せとなり、単独設定より併用の方が良い結果だった（SL到達件数325→27件）。ただしFold×銘柄20区分中の改善区分数は10区分で、EarlyAdverseExit単独設定（12〜14区分）より頑健性は低い。詳細は`TASKS.md`セクション2.1.3を参照。

**TrendReversalExitを不採用（既定`false`）のまま据え置いた理由**: 併用は集計値（純利益・PF）ではこのセッションで検証した全設定中最良だったが、以下の3点から「併用の方が良い結果だった」ことをそのまま採用理由とはしなかった。

1. **頑健性が単独設定より低い**: 併用の改善区分数はFold×銘柄20区分中10区分にとどまり、実際に採用したEarlyAdverseExit単独設定（TriggerR=0.75、14区分）や0.70（12区分）を下回る。集計値の優位は一部区分での大勝ち・大負けの相殺（分散の拡大）に支えられており、全区分へ一様に効く改善ではない。本プロジェクトでは繰り返し、集計値よりFold単位の改善区分数を頑健性の指標として優先してきた（`TASKS.md`参照）。
2. **検証時点のTriggerRが現行既定と異なる**: 併用検証で使用した`InpEarlyAdverseExitTriggerR=0.7`は、その後の判断で最終的に採用された`0.75`とは異なる値である。現行既定（TriggerR=0.75）を土台にした併用の再検証は実施していないため、「現行既定＋TrendReversalExit」の組み合わせの効果は未確認のまま。
3. **Fold1-5への過剰適合回避を優先した**: 併用検証の時点で、Fold1-5に対する開発中の最適化が既に3ラウンド目（ConfirmationTicksスイープ→TriggerR9点スイープ→併用検証）に達していた。ここでさらに「TriggerR=0.75での併用再検証」を追加することは、同一OOSデータへの適合をもう1ラウンド重ねることを意味するため、探索を打ち切りFinal Holdoutへ進む方針を優先し、意図的に見送った。

したがって、TrendReversalExitは「効果がないと判明した」のではなく、**「単独より頑健性が低く、かつ現行既定TriggerRでの再検証を経ていない状態のまま、これ以上Fold1-5上の探索を重ねないという方針のもとで採用を保留した」**候補として扱う。ユーザーの明示指示による採用もEarlyAdverseExit単独（TriggerR=0.75）のみであり、TrendReversalExit自体を既定`true`へ変更する指示・実施はない。Final Holdoutで現行既定一式（TrendReversalExit OFF）を確認した後、余力があればTriggerR=0.75でのTrendReversalExit併用を独立した追加検証として扱うべきである。

**現時点の判断**: `InpEnableEarlyAdverseExit`は既定`true`（TriggerR=0.75、`ConfirmationTicks`=5）へ採用済みである（2026-09-13、ユーザー明示指示、`TASKS.md`参照）。`InpEnableTrendReversalExit`は上記の理由により既定`false`を維持する。**本節の数値はいずれもFold1-5への複数回のパラメータ適合の結果であり、Final Holdout（2025-01〜2026-08）での確認前に、これ以上の採用範囲拡大の判断をしないこと。**

**独立追加検証の結果（2026-09-26実施）**: 上記の計画（Final Holdout確認後、TriggerR=0.75での併用を独立した追加検証として扱う）に基づき、現行既定（TriggerR=0.75）を土台に`InpEnableTrendReversalExit=true`を追加してFold1-5・4銘柄で再検証した（`results/backtests/20260926-145345-cases`、Baseline=`results/backtests/20260922-114452-cases`）。**懸念どおり、TriggerR=0.7時点の併用検証結果（Baseline比+63.5%）はTriggerR=0.75では再現せず、純利益はむしろ-3.4%悪化した（169,416円→163,721円）。** 改善区分数も10/20と単独設定（14/20）を下回り頑健性も低い。原因はTP到達件数の大幅減少（117件→62件、-47%）で、TrendReversalExit単体の効果自体（151件発動・勝率100%・合計+605,844円、TP取りこぼし0件）は良好だったが、EarlyAdverseExitとの相互作用でTP到達機会自体が失われたと考えられる（詳細因果は未特定）。**結論: TrendReversalExitの追加採用は推奨しない。現行既定（EarlyAdverseExit単独、TrendReversalExit OFF）を維持する。** 詳細は`TASKS.md` 2.1.4節を参照。

発動したトレードはEA側`CPositionExitEvaluator::EvaluateEarlyAdverseExits`が送出する`EARLY_ADVERSE_EXIT`イベント（`reason_code`固定値`EarlyAdverseConfirmed`、`adverse_r_multiple`、`confirmation_count`）で識別する。

```powershell
$env:PYTHONPATH='.'
# Baseline
python -m python.analysis.trade_breakdown --input results/backtests/<baseline-run-id>-USDJPY-H1/audit/audit-<baseline-run-id>.jsonl --output build/early-adverse-baseline
# ON
python -m python.analysis.trade_breakdown --input results/backtests/<on-run-id>-USDJPY-H1/audit/audit-<on-run-id>.jsonl --output build/early-adverse-on
```

`trade-breakdown-report.json`の`early_adverse_exit`セクション（`trades_closed_by_early_adverse_exit`・`net_profit`・`profit_factor`・`win_rate`・`expectancy`・`average_adverse_r_multiple`・`by_direction`）に加え、レポート全体のPF・Net Profit・Expectancy・Max DD・Win Rate・平均利益/平均損失・Trade数をBaseline/ON間で比較する。「最終的にTPへ到達していた勝ちトレードを早期Exitしていないか」の確認は、トレンド継続反転Exitと同じ指標（`early_adverse_exit.trades_that_would_likely_have_reached_tp`・`net_pnl_of_trades_that_would_likely_have_reached_tp`）で行う。

## Entry Timing比較分析（2026-08-22実装）

`InpEnableEntryTimingAnalysis`（既定値`false`）を`true`にすると、EA側`CEntryTimingAnalyzer`（`mt5/Include/Logging/EntryTimingAnalyzer.mqh`）が、同一のプルバックSetupについて次の4方式を**実注文なしのShadow Trade**として並行シミュレートする。

```text
IMMEDIATE    : Setup成立bar自身の終値で即Entry
WAIT_1_BAR   : 1本待ってEntry
WAIT_2_BARS  : 2本待ってEntry
WAIT_TRIGGER : Setup後のTrigger（再加速）成立を待ってEntry（InpEntryTimingMaxWaitBars以内に不成立なら生成しない）
```

Setup検出・SL/TP幾何（`InpStopAtrMultiple`・`InpRiskRewardRatio`）・Trigger判定は、既存の`CTrendFollowingRules`（`IsPullbackSetup`・`IsPullbackTrigger`・`IsBreakout`と同じ関数群）をそのまま再利用するが、`CEntryTimingAnalyzer`は自前のIndicatorハンドルでHTF Bias・ATR/ADX/RSIゲートを独立に再評価する自己完結モジュールであり、実際の`CTrendFollowingStrategy`・`RiskManager`・`OrderManager`・`PositionManager`には一切参照されず、実注文・実ポジションを一切発生させない。`InpEnableEntryTimingAnalysis=false`（既定値）ではIndicatorハンドルすら作成せず、既存の売買判断・監査ログ量に影響しない。ブレイクアウトパターンはSetupとTriggerが同一の価格事象（レンジ突破）であり両者の間に待機できる中間状態が存在しないため、本分析はプルバックパターンのみを対象とする。

Shadow TradeのSL/TP判定はtick粒度（Strategy Testerの"Every tick"モード相当）で行い、価格推移チェックポイント（Entry後1/2/3/5/10/20本経過時点の価格、R倍数）とMFE/MAE（当初SL距離を1RとしたR倍数）を記録する。損益は口座通貨ではなくR倍数で表現する（Shadow TradeはPosition Sizing・Risk Managerを経由しないため、口座通貨建て損益は算出できない）。また、Setup成立bar終値からEntry確定までの間に想定方向へどれだけ順行し、逆側へどれだけ逆行したか（`pre_entry_mfe_r`・`pre_entry_mae_r`、到達時刻付き）を記録する。

**過去データに最も適合する待機方式を自動採用する処理は実装していない。** 4方式すべてを常に並行記録し、優劣の判断・待機方式の変更はユーザーが分析結果を見て行う。

`InpAuditFileEnabled=true`かつ`InpEnableEntryTimingAnalysis=true`でStrategy Testerを実行すると、監査JSONLへ`ENTRY_TIMING_SETUP`（Setup単位、`pre_entry_mfe_r`・`pre_entry_mae_r`・`trigger_found`・`trigger_wait_bars`）と`ENTRY_TIMING_TRADE`（Variant単位、`variant`・`entry_price`・`wait_bars`・`bars_held`・`mfe_r`・`mae_r`・`exit_reason`・`pnl_r`・`checkpoint_r`）が記録される。

```powershell
$env:PYTHONPATH='.'
python -m python.analysis.entry_timing `
  --input results/backtests/<run-id>-USDJPY-H1/audit/audit-<run-id>.jsonl `
  --output build/entry-timing-report
```

出力は `entry-timing-report.json`（JSON契約は `contracts/entry-timing-report.schema.json` を正とする）、`entry-timing-report.md`、`entry-timing-setups.csv`、`entry-timing-trades.csv`である。レポートの`variants`はVariant別（IMMEDIATE/WAIT_1_BAR/WAIT_2_BARS/WAIT_TRIGGER）にTrades・Win Rate・Profit Factor・Expectancy・Net Profit・Max Drawdown（すべてR倍数）・平均MFE/MAE・価格推移チェックポイント平均を集計する。Max Drawdownは基準値100R（アカウント資金とは無関係な相対指標）からの累積R下落幅であり、Variant間の相対比較専用。`pre_entry_excursion`はSetup成立からEntryまでの逆行・順行の平均・中央値とTrigger成立率を要約する。`InpEnableEntryTimingAnalysis=false`のバックテストでは対象イベントが存在せず、`setups_observed=0`・全Variant`trades=0`として返る。

## Breakout Timing比較分析（2026-09-05実装）

Entry Timing比較分析はプルバックパターンのみを対象とし、ブレイクアウトパターンは「SetupとTriggerが同一の価格事象（レンジ突破）であり、両者の間に待機できる中間状態が存在しない」ため対象外としていた。しかし実トレードの大半（Fold1〜5・4銘柄の実績で85.6%）はブレイクアウトが占めており、ブレイクアウト成立直後の反転（ダマシ）による損失がタイミングの問題か、Setup/Trigger条件自体の精度の問題かを切り分けるため、ブレイクアウト専用の比較分析を別途実装した。

`InpEnableBreakoutTimingAnalysis`（既定値`false`）を`true`にすると、EA側`CBreakoutTimingAnalyzer`（`mt5/Include/Logging/BreakoutTimingAnalyzer.mqh`）が、同一のブレイクアウトSetupについて次の4方式を**実注文なしのShadow Trade**として並行シミュレートする。

```text
IMMEDIATE      : ブレイクアウト成立bar自身の終値で即Entry（現行ライブロジックと同一）
CONFIRM_1_BAR  : 1本後の終値時点でもブレイクアウトレベル（Setup成立時点で固定）を維持できていた場合のみEntry
CONFIRM_2_BARS : 2本後について同様
CONFIRM_3_BARS : 3本後について同様（維持できていなければ当Variantのトレードは生成しない）
```

「Trigger成立を待つ」というEntry Timing比較分析の概念はブレイクアウトには適用できないため、代わりに「ブレイクアウトが直後に反転せず維持されたか」を検証する設計とした。維持判定（`CBreakoutTimingRules::HoldsBreakout`）は`CTrendFollowingRules::IsBreakout`と同一の数式だが、レンジ高安値をSetup成立時点の値へ固定して再評価する点が異なる。Setup検出（HTF Bias・ATR/ADX/RSIゲート・ブレイクアウトレンジ）・SL/TP幾何は、`CEntryTimingAnalyzer`と同じ設計方針で`CTrendFollowingStrategy`とは独立に自己完結モジュールとして再評価し、実際の`RiskManager`・`OrderManager`・`PositionManager`には一切参照されず、実注文・実ポジションを一切発生させない。`InpEnableBreakoutTimingAnalysis=false`（既定値）ではIndicatorハンドルすら作成せず、既存の売買判断・監査ログ量に影響しない。

Shadow TradeのSL/TP判定・R換算・チェックポイント記録は`CEntryTimingRules`（Entry Timing比較分析と共通の汎用ロジック）をそのまま再利用する。**過去データに最も適合する確認本数を自動採用する処理は実装していない。**

`InpAuditFileEnabled=true`かつ`InpEnableBreakoutTimingAnalysis=true`でStrategy Testerを実行すると、監査JSONLへ`BREAKOUT_TIMING_SETUP`（Setup単位、`breakout_level_high`・`breakout_level_low`・`pre_entry_mfe_r`・`pre_entry_mae_r`・`confirm_1_bar_held`・`confirm_2_bars_held`・`confirm_3_bars_held`）と`BREAKOUT_TIMING_TRADE`（Variant単位、`variant`・`entry_price`・`wait_bars`・`bars_held`・`mfe_r`・`mae_r`・`exit_reason`・`pnl_r`・`checkpoint_r`）が記録される。

```powershell
$env:PYTHONPATH='.'
python -m python.analysis.breakout_timing `
  --input results/backtests/<run-id>-USDJPY-H1/audit/audit-<run-id>.jsonl `
  --output build/breakout-timing-report
```

出力は `breakout-timing-report.json`（JSON契約は `contracts/breakout-timing-report.schema.json` を正とする）、`breakout-timing-report.md`、`breakout-timing-setups.csv`、`breakout-timing-trades.csv`である。レポートの`variants`はVariant別（IMMEDIATE/CONFIRM_1_BAR/CONFIRM_2_BARS/CONFIRM_3_BARS）にTrades・Win Rate・Profit Factor・Expectancy・Net Profit・Max Drawdown（すべてR倍数）・平均MFE/MAE・価格推移チェックポイント平均を集計する。`confirmation_hold`はSetup数と、1/2/3本後にブレイクアウトレベルを維持できていた（ダマシに遭っていない）割合、およびSetup成立からの逆行・順行の平均・中央値を要約する。`InpEnableBreakoutTimingAnalysis=false`のバックテストでは対象イベントが存在せず、`setups_observed=0`・全Variant`trades=0`として返る。

## コスト感応度分析（2026-08-22実装）

目的は、Profit Factorが低い場合の原因が「Entry/Exitロジック自体の問題」なのか「薄いエッジが取引コスト（Spread・Commission・Swap・Slippage）によって失われている」のかを切り分けることである。**過去データに最も都合よく適合するコスト条件を自動採用する処理は実装していない。** MT5テスターが実際に生成したSpread・Commission・Swap・Slippageをそのまま記録・集計するのみで、EA内部で市場コストを変更・偽装するロジックは持たない。

**記録するコスト項目とEA側の実装。**

- Entry Spread: 既存の`CANDIDATE`イベント`spread_points`（Entry候補生成Tick時点のSpread、Point単位。Phase 9から実装済み）
- Exit Spread: `TRADE_CLOSED`イベントへ新規追加した`exit_spread_points`（Point単位）。決済自体はブローカー側SL/TP等で発生し、EA側は`OnTradeTransaction`が決済デタッチ（`DEAL_ENTRY_OUT`）を検知した直後のTickでベストエフォートに記録する（約定Tickそのものの値ではない近似値、`mt5/Include/Core/EAController.mqh`の`OnTradeTransaction`）
- Entry Slippage: 既存の`ORDER_SUBMISSION`イベント`slippage_points`（要求価格`requested_price`と約定価格`confirmed_price`の差、Point単位。Phase 9から実装済み）
- Exit Slippage: **未対応。** 決済の大半はブローカー側SL/TP自動決済であり、Entry側の`COrderManager::Submit`のような「要求価格」を安全に取得する手段が現アーキテクチャにはないため、Entry側のみ記録する（既知の制約。EXPERT/CLIENT close_reasonの決済もEA発注だが未計測）
- Commission・Swap: 既存の`TRADE_CLOSED`イベント`commission`・`swap`（Phase 9から実装済み、net_pnlへ既に加算済み）
- 約定価格: 既存の`TRADE_CLOSED`イベント`open_price`・`close_price`
- Point→口座通貨換算値: `TRADE_CLOSED`イベントへ新規追加した`point_value`。該当トレードのVolumeにおける1 Point変動の口座通貨換算値を、`OrderCalcProfit`（`Risk/PositionSizer.mqh`のリスクベースLot計算と同じAPI）で算出する。算出できない場合は0（Spread/SlippageのPoint値は口座通貨へ換算不能として扱う）

`python.analysis.cost_sensitivity`は、`trade_breakdown.build_trade_context`（Entry Spread・Exit Spread・point_value等を`trade_candidate_id`で相関済み）へ`ORDER_SUBMISSION.slippage_points`（Entry Slippage、`status=ACCEPTED`のもののみ）を追加相関し、トレードごとに次を算出する。

- `total_spread_cost` = (Entry Spread + Exit Spread) [Point] × `point_value`
- `entry_slippage_cost` = Entry Slippage [Point] × `point_value`
- `total_cost` = `total_spread_cost` + `entry_slippage_cost` − `commission` − `swap`（commission/swapは符号付きのまま。swapがプラス＝スワップ収益の場合は総コストを押し下げる）
- `pnl_before_cost` = `net_pnl` + `total_cost`（Spread・Slippage・Commission・Swapを除いた場合の推定損益）

`point_value`が取得できない（0または欠落）トレードは、Spread/Slippageのコストを0として扱う（`cost_data_available=False`）。この場合`pnl_before_cost`は実際のコストを過小評価する可能性がある。

```powershell
$env:PYTHONPATH='.'
python -m python.analysis.cost_sensitivity `
  --input results/backtests/<run-id>-USDJPY-H1/audit/audit-<run-id>.jsonl `
  --initial-balance 1000000 `
  --output build/cost-sensitivity-report
```

出力は`cost-sensitivity-report.json`（JSON契約は`contracts/cost-sensitivity-report.schema.json`を正とする）、`cost-sensitivity-report.md`、`trades-with-cost.csv`である。レポートは次を比較できる。

- `cost_summary`: 総取引コスト・1トレードあたり平均コスト・Spread/Slippage/Commission/Swapそれぞれの合計
- `performance_with_cost` / `performance_before_cost`: 実績（`net_pnl`）とコスト除外時の推定成績（`pnl_before_cost`）それぞれについて、既存`performance.analyze_performance`と同一定義のTrades・Net Profit・Profit Factor・Win Rate・Expectancy・Max Drawdownを算出（両者の差が大きいほど、コストがエッジを侵食している可能性を示唆する）
- `cost_tier_breakdown`: `total_cost`の実データ三分位によるLow/Normal/High Cost別の同上指標（固定しきい値はハードコードせず、実際に発生したコスト分布から算出する）

## ベンチマーク比較（2026-09-23実装、`DECISIONS.md` DEC-041）

`python.analysis.benchmark_comparison`は、Release Gateの「ベンチマーク受入基準」（`docs/release-gate.md`）を判定する。EAの決済済み取引と、MSCI ACWI（配当込み・円換算）の月末値を比べ、税引き後CAGRとSharpe比の両方でEAが上回るかを期間ごとに判定する。計算上の仮定（東京時間での月・暦年の区切り、複数ケースの損益合算、課税のタイミング等）はDEC-041を正とする。

ベンチマークの月末値はネットワークから自動取得しない。評価期間の開始前月から終了月までの月末値を、次の形式のCSVで用意する（`level`は指数値またはファンドの基準価額）。

```text
month,level
2019-12,123.45
2020-01,125.67
```

ファンドの基準価額を使う場合は信託報酬が控除済みのため、`--benchmark-annual-fee 0`を指定する。指数値を使う場合は、代表的な連動ファンドの信託報酬（年率）を指定する。

```powershell
$env:PYTHONPATH='.'
python -m python.analysis.benchmark_comparison `
  --period walk_forward 2020-01 2024-12 `
  --input walk_forward results/backtests/<walk-forward-run-id>-cases `
  --period final_holdout 2025-01 2026-08 `
  --input final_holdout results/backtests/<final-holdout-run-id>-cases `
  --initial-balance 1000000 `
  --benchmark-csv <月末値CSV> `
  --benchmark-source "<データ源>" `
  --benchmark-retrieved-on <取得日YYYY-MM-DD> `
  --benchmark-annual-fee <信託報酬（年率）> `
  --output build/benchmark-comparison
```

`--input`にディレクトリを指定すると、配下の`trades-normalized.csv`（複数ケース実行の出力）をすべて読み込む。取引CSV・監査JSONLのファイルを直接指定することもできる。評価期間外に決済された取引があるとエラーになる。

出力は`benchmark-comparison.json`（JSON契約は`contracts/benchmark-comparison-report.schema.json`を正とする）と`benchmark-comparison.md`である。全期間で合格した場合だけ`criteria_met`が`true`になり、標準出力へ`BENCHMARK_CRITERIA_MET=true|false`を表示する。
