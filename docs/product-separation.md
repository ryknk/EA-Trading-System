# 開発基盤と製品EAの分離

本書は、本リポジトリを「EAの研究・検証・分析を行う開発基盤」として整理し、販売EA本体を別リポジトリ `EA-Product` へ分離するための現状調査・境界定義・移行計画と、その実施記録である。設計判断は `DECISIONS.md` DEC-044〜DEC-047。

**2026-10-11、製品EAのソースを [ryknk/EA-Product](https://github.com/ryknk/EA-Product) へ分離した**（5章）。本リポジトリは `product/` にsubmoduleとして製品の特定commitを取り込む。1章は分離前の調査記録である。

---

## 1. 現状調査（2026-10-10、`dev` 1a1f7d1 時点）

### 1.1 構成要素と責務

| 領域 | 場所 | 責務 | 実行時依存 |
| --- | --- | --- | --- |
| EA本体 | `mt5/Experts/CoreEA.mq5`、`mt5/Include/{Core,Strategy,Signal,Filter,Risk,Trading}` | Trend/Range戦略、Entry/Exit、Risk Manager、注文・ポジション管理 | MT5のみ |
| EA内の外部連携 | `mt5/Include/External`（Decision API、Telemetry、Heartbeat、Mock） | AWS判断API・監視への送信（既定無効） | AWS（有効化時のみ） |
| EA内の監査・研究計測 | `mt5/Include/Logging`（監査JSONL、TradeAnalytics、Entry/Breakout Timing分析） | 監査ログ出力、研究用の仮想トレード計測 | MT5のみ |
| MT5補助ツール | `mt5/Tools`、`mt5/Experts/{DiagnoseSymbolSpecEA,ExportM1BarsEA}.mq5`、`mt5/Include/Diagnostics` | tick投入・Custom Symbol診断・M1出力 | MT5のみ |
| MQL5単体テスト | `mt5/Tests`（13 Script） | Risk・Trading・Strategy規則、外部API規則、研究計測の単体テスト | MT5 |
| Strategy Tester設定 | `mt5/test-config/*.ini`（95件）、`mt5/test-config/cases/*.json`（CaseFile 76件） | テンプレートと検証ケース定義 | — |
| Runner | `tools/run-strategy-tester.ps1`、`tools/lib/Mt5ExecutionBackend.psm1`、`tools/lib/ValidationManifest.psm1` | 単体・複数ケース実行、Host/VM実行、Timeout、report・監査JSONL回収、manifest・summary生成 | MT5、Python |
| ビルド・テスト | `tools/link-mt5.ps1`、`tools/compile-mql5.ps1`、`tools/run-mql5-tests.ps1` | MT5 Data Folderへのjunction作成、MetaEditorコンパイル、Script Test | MT5 |
| Python分析 | `python/analysis` | 成績指標、過学習診断、条件別分析、コスト感応度、ベンチマーク比較 | pandas |
| Tickデータ | `python/tickdata`、`tools/tick-data.ps1`、`tools/tick-data/` | 取得・正規化・検証・MT5変換・投入・照合 | Node.js、MT5 |
| ML | `python/ml` | 特徴量・ラベル・学習 | scikit-learn |
| Decision API | `services/decision_api` | Lambda（判断・Telemetry・Heartbeat） | AWS |
| IaC | `infra` | CDK v2 | AWS |
| リリースゲート | `tools/release-gate.ps1`、`contracts/production-release-evidence.schema.json` | 開発・本番ゲート | 上記すべて |

### 1.2 依存関係

以下は調査時点の構成である。研究計測の依存は段階1（2026-10-10）で分離した（3章、DEC-045）。

```text
CoreEA.mq5
  └─ Core/EAController.mqh
       ├─ Strategy / Signal / Filter / Risk / Trading         ← 製品の中核
       ├─ External/{DecisionApiClient,MockDecisionProvider,HeartbeatApiClient}
       └─ Logging/{TradeLogger,AuditPayloadBuilder,AuditEventPublisher,
                   TradeAnalyticsTracker,EntryTimingAnalyzer,BreakoutTimingAnalyzer}
            ├─ AuditPayloadBuilder → EntryTimingAnalyzer, BreakoutTimingAnalyzer
            └─ AuditEventPublisher → External/TelemetryApiClient

tools/run-strategy-tester.ps1
  ├─ *.ini（Expert=EaTradingSystem\CoreEA、Inp* 入力）
  ├─ MT5 Data Folder（link-mt5.ps1 のjunction経由で mt5/ を参照）
  ├─ Common\Files\<InpAuditLogDirectory>\audit-<ReportName>.jsonl
  └─ python -m python.analysis.reports → performance-summary.json → summary.csv
```

Python・AWS・CDKはMQL5ソースへ依存しない。両者の接点は次の2つだけである。

1. **EA入力（ini `[TesterInputs]`）**: Runnerは `InpSymbol`・`InpAuditRunId` を書き換え、`InpAuditLogDirectory` を読む。テンプレートは `InpTesterDecisionMode`・`InpTesterFixedMlProbability`・`InpTesterResetPersistentState` 等のTester専用入力を使う。
2. **監査JSONL**: EAが出力し、`python/analysis` が読む。イベント種別は `python/analysis/reports.py` の `SUPPORTED_AUDIT_EVENTS` が事実上の契約であり、`contracts/` にJSON Schemaはない。

### 1.3 既存実装の状況

| 項目 | 状況 |
| --- | --- |
| CaseFile | 76件。全件オブジェクト形式（`description`・`cases`）で、ケースは `case_name`・`symbol`・`from_date`・`to_date`・`template` のみ |
| manifest.json | 1.0: Run ID、CaseFile・TemplateのSHA-256、ケースの結果。**検証対象のcommit・ex5・MT5 build・データ識別は記録していなかった**（本対応で1.1へ拡張） |
| 単体テスト | MQL5 13 Script、Python（分析・tickdata・ML）、Lambda、CDK、Runner実行バックエンド（`tools/test-mt5-execution-backend.ps1`） |
| IS / OOS / Walk Forward / Final Holdout | CaseFileとして実施済み（`docs/backtesting.md`、`TASKS.md` 2.1）。Final Holdoutは消費済み |
| 過学習診断・ベンチマーク比較 | `python.analysis.overfitting`、`python.analysis.benchmark_comparison` |
| 監査ログ | FILE_COMMON・Run ID単位（DEC-030） |
| リリースゲート | 開発ゲートは自動。本番ゲートは証跡JSONのフィールド検査で、**証跡と検証結果manifest・対象commitの関連づけは未実装** |

### 1.4 分離時に影響する結合箇所

| 結合箇所 | 内容 | 分離時の扱い |
| --- | --- | --- |
| `EAController.mqh` のinclude | 製品中核と、外部連携・研究計測（Entry/Breakout Timing）を同一EAへ静的に結合 研究計測は段階1で `EA_TRADING_SYSTEM_RESEARCH_BUILD` 定義時だけincludeする構造へ変更済み。外部連携は未対応（2.3節） |
| `AuditPayloadBuilder.mqh` | 監査ペイロード生成が研究計測クラスへ依存 | 段階1で `Research/TimingAnalysisHook.mqh` へ移設済み |
| `tools/link-mt5.ps1` | junctionの参照元が `mt5/` 固定 | 製品checkoutを参照元に指定できるようにする |
| `tools/compile-mql5.ps1`・`run-mql5-tests.ps1` | 対象EA・テストの一覧が固定で、製品テストと研究テストが混在 | 製品テストは製品リポジトリへ移し、両方で実行する |
| `tools/release-gate.ps1`・`python/tests/test_documentation.py` | `mt5/Experts/CoreEA.mq5`・`EAController.mqh` を直接読み、安全初期値と呼出順序を静的検査 | 製品リポジトリにも同じ検査を置き、開発基盤側は製品パスを引数で受け取る |
| `*.ini`（95件） | `Expert=EaTradingSystem\CoreEA` を埋め込み | junction名を維持すれば変更不要 |
| `mt5/**/*.ex5` | コンパイル済みバイナリをGit管理 | 製品リポジトリではリリース成果物として扱う（検討事項） |

### 1.5 保守性の課題（修正済みと明記した項目以外は本対応では変更しない）

* Strategy Testerテンプレート95件の多くは `StrategyTester-Generic-H1.ini` と1〜2入力だけが異なる複製で、既定値変更時に全件の追随が必要になる。
* `tools/test-phase6.ps1`〜`test-phase13.ps1` はPhase単位の歴史的な入口で、内容が重複している。
* 単体実行モード（`-CaseFile` なし）はmanifestを出力しない。正式な検証はCaseFile経由で行う。
* `HANDOFF.md`・`CONTRIBUTING.md` は安定Branchを `master` と記載しているが、実運用は `main` / `dev` である（文書と運用の不一致）。
* `compile-mql5.ps1`（開発ゲートに含む）はGit管理下の `mt5/**/*.ex5` と `build/metaeditor/*.log` を再生成するため、ソースを変えなくても作業ツリーに差分が出る。
* `python/tests/test_tickdata_pipeline.py` の `test_convert_is_reused_until_inputs_change_and_force_rebuilds` は、Windowsのファイル時刻がシステムクロックの刻み（約15.6ms）で更新されるため、同じ刻み内の再生成で更新時刻が変わらず断続的に失敗していた（修正前30回中7回）。2026-10-10、更新時刻を既知の過去値へ戻してから判定する方式へ修正した（変換処理本体は更新時刻を使っておらず影響なし）。
* 複数ケース実行の完了ログ `STRATEGY_TESTER_BATCH_COMPLETED` で、件数が1件のときWindows PowerShell 5.1では `succeeded=`/`failed=` が空欄になっていた（`Where-Object` が単一の `PSCustomObject` を返し `.Count` が `$null` になるため。ログのみでmanifest・summaryは正しい）。2026-10-10修正済み。

---

## 2. 目標アーキテクチャ

### 2.1 責務

| | 開発基盤（本リポジトリ） | 製品（`EA-Product`、将来） |
| --- | --- | --- |
| 正本 | Runner、CaseFile、テンプレート、分析、tick、ML、AWS、リリースゲート | 販売EAのMQL5ソース（Strategy、Entry/Exit、Risk、Trading、Broker/Symbol対応） |
| テスト | Runner・分析・manifestの回帰テスト、検証ケース | 製品の単体テスト（Risk・Trading・Strategy規則）、安全初期値の静的検査 |
| 依存 | 製品の特定commitを参照する | Python・AWS・LLM・tick取得ツールへ依存しない。MQL5だけで通常の取引・リスク管理が完結する |
| リリース | 検証結果と合否基準を製品commitへ関連づける | バージョン・リリースノート・ユーザー向け文書 |

製品コードを両リポジトリで二重管理しない。開発基盤は製品ソースを**読み取り専用で参照**し、研究用の変更は製品リポジトリへのPull Requestとしてだけ反映する（自動混入させない）。

### 2.2 連携方式

| 方式 | 検証対象の固定 | 既存構成との適合 | 評価 |
| --- | --- | --- | --- |
| A. Git submodule（`product/` に製品を配置） | 開発基盤の履歴に製品commitが固定される | junction元を `product/mt5` に変えるだけ | **推奨** |
| B. 任意の別checkout + `-ProductSourceRoot` | manifestにcommit・dirtyを記録するだけで、履歴には固定されない | 変更が最小 | 移行初期の暫定運用として可 |
| C. 製品のリリース成果物（ex5 + tag）を取得 | ex5のSHA-256で固定 | ソースhashとの対応づけが別途必要 | 将来、販売版の最終確認に併用 |

推奨はA。いずれの方式でも、Runnerは `-ProductSourceRoot` で製品ソースを受け取り、manifest.jsonへ製品のcommit・未コミット変更の有無・ソースハッシュ・EAバージョン・実行したex5のSHA-256を記録する（本対応で実装済み）。

### 2.3 製品ビルドと研究ビルド

**リリースゲートの証跡は、販売するex5と同一のバイナリで取得しなければならない。** 研究用の計測を足したEAで取得した成績は、販売版の性能証跡として使わない。

* 製品ビルド: 製品リポジトリのEAそのもの。性能・安全ゲートの証跡はこのビルドだけで取得する（manifestの `expert_ex5_sha256` と製品リリースのex5ハッシュの一致で確認する）。
* 研究ビルド: Entry/Breakout Timing分析等の研究計測やShadow Mode用の外部連携を含むEA。探索的分析にだけ使い、ゲート証跡には使わない。

段階1（2026-10-10、DEC-045）で、研究計測の取り込みを `#ifdef EA_TRADING_SYSTEM_RESEARCH_BUILD` で切り替える構造にした。

* `mt5/Include/Research/TimingAnalysisHook.mqh`: Entry/Breakout Timing分析器の初期化・Tick処理・監査記録と、そのPayload生成（`CTimingAnalysisPayloadBuilder`）。EAControllerから研究計測への入口はこれだけである。
* マクロ未定義（製品ビルド）: EA中核は研究計測なしでコンパイルされる。`InpEnableEntryTimingAnalysis` または `InpEnableBreakoutTimingAnalysis` をtrueにすると、黙って無視せず初期化を拒否する（`RESEARCH_BUILD_REQUIRED`）。`mt5/Tests/TestProductBuildWithoutResearch.mq5` がinclude経路に研究計測が含まれないことを検査する。
* 現行の `CoreEA.mq5` はマクロを定義する研究ビルドのままである（既存テンプレート・CaseFileの挙動を変えないため）。研究計測の入力（`InpEnableEntryTimingAnalysis` 等）も `CoreEA.mq5` と `Config.mqh` に残っている。製品EAから外すのは製品リポジトリ作成時（段階4）とする。

段階2（2026-10-11、DEC-046）で、外部連携（Decision API・ML/LLM、Telemetry、Heartbeat、Tester判断Mock）を製品へ**含めない**ことを決定し、同じマクロで研究ビルドだけに含める構造にした。

* 製品ビルド `mt5/Experts/ProductEA.mq5` を追加した。入力・設定組み立て・イベント処理は `mt5/Include/Core/EAEntryPoint.mqh` に移し、`CoreEA.mq5`（研究ビルド）と共有する（研究専用の入力は `#ifdef` 内）。
* 製品ビルドは外部判断の工程を持たず、候補はローカル検査の後、Risk Manager（最終権限）・`InpEnableTradeMutations`・`OrderCheck` で判断される。外部の失敗を許可へ変換するのではなく、工程がコンパイルされない。研究ビルドは従来どおりDecision API無効・障害時に新規注文を拒否する。
* 製品ビルドは監査JSONLをローカルへ記録するだけで、Telemetry送信・Heartbeatを行わない。
* **試験運用（Demo・小額実口座）は製品ビルドで行う**（ユーザー決定、2026-10-11）。ゲート証跡も製品ビルドで取得する。製品ビルドのStrategy Testerテンプレートは `mt5/test-config/StrategyTester-Product-H1.ini`。
* Kill Switch判定 `CDecisionPolicyRules` は通信を伴わない規則だが `External/IDecisionProvider.mqh` にあるため、製品ビルドもこのヘッダだけをincludeしている。汎用ユーティリティ `External/CryptoUtils.mqh`（UUID・JSONエスケープ）も監査ログが使う。製品リポジトリ作成時に配置を見直す。

### 2.4 検証レイヤーと合否区分

CaseFileの `validation_layer` で検証レイヤーを区別し、manifestへ合否区分（`gate_category`）を導出して記録する。

| validation_layer | 内容 | gate_category |
| --- | --- | --- |
| `strategy_test` | 単発のStrategy Tester確認 | performance |
| `in_sample` | 開発期間 | performance |
| `out_of_sample` | OOS | performance |
| `walk_forward` | Walk Forward | performance |
| `final_holdout` | 最終確認期間（一度だけ評価） | performance |
| `multi_symbol` | 複数銘柄・初見資産 | performance |
| `cost_stress` | コスト感応度・spread拡大等のストレス | performance |
| `operational_fault` | 運用障害試験（外部API障害、Risk lock等） | safety |
| `forward_test` | Demo・小額実口座のフォワード | performance |

性能評価（performance）と安全機能（safety）は別々に合否を判定し、一方の合格で他方を代替しない。PFだけで販売可否を判断しない。

### 2.5 合否基準の事前固定

CaseFileの `acceptance_criteria` に合否基準ファイルのパスを指定すると、Runnerは実行前に実在を確認し、manifestへパスとSHA-256を記録する。基準ファイルが結果より前に存在し、内容が変わっていないことを、manifestのハッシュと基準ファイルのGit履歴で確認できる。**数値基準そのものは本対応では定めていない**（現状のデータと検証実績から別途決定する。既存のベンチマーク受入基準は `docs/release-gate.md`）。

---

## 3. 移行手順（Phase C、2026-10-11に段階1〜5を実施）

各段階は独立してコミット・検証・切り戻しできる単位とする。段階1〜3は本リポジトリ内で完結し、既存の `dev` / `main` 運用を変えない。

| 段階 | 作業 | 検証 | 切り戻し |
| --- | --- | --- | --- |
| 1（**実施済み** 2026-10-10） | 研究計測（`EntryTimingAnalyzer`・`BreakoutTimingAnalyzer`）と監査ペイロード生成の依存を分け、製品中核が研究計測なしでコンパイルできるincludeにする | `compile-mql5.ps1`、`run-mql5-tests.ps1`、既存CaseFileの再実行で成績が変わらないこと（4章） | 該当コミットのrevert |
| 2（**実施済み** 2026-10-11） | 外部連携を製品へ含めるかを決定し、`DECISIONS.md` へ記録する（含めない。DEC-046）。製品ビルド `ProductEA` を追加する | 製品ビルドと研究ビルド（常時許可Mock）の成績・監査イベントの一致（4.2節） | 該当コミットのrevert |
| 3（**実施済み** 2026-10-11） | `link-mt5.ps1`・`compile-mql5.ps1`・`run-mql5-tests.ps1`・`release-gate.ps1` を製品submoduleに対応させる（5.2節） | 既定引数で従来どおり動くこと、別パス指定で同じ結果になること | revert |
| 4（**実施済み** 2026-10-11、ユーザー承認済み） | `EA-Product` リポジトリを作成し、`mt5/Experts/ProductEA.mq5`・製品中核の `mt5/Include`・製品テストを `git filter-branch` で履歴付きで移す | 製品リポジトリ単独でコンパイル・テストが通ること | 製品リポジトリを破棄（本リポジトリは未変更） |
| 5（**実施済み** 2026-10-11、ユーザー承認済み） | 本リポジトリへsubmodule `product/` を追加し、junction元を `product/mt5` へ切り替える。旧 `mt5/` の製品ファイルを削除する | 開発ゲート一式、代表CaseFile（例: Walk Forward）の再実行で成績・ex5ハッシュが段階4前と一致すること | submoduleの削除と旧ファイルの復元（revert） |
| 6 | 製品リリースごとに、manifestの `provenance.product.commit`・`expert_ex5_sha256` と本番証跡を関連づける（本番証跡スキーマへの追加を検討） | `release-gate.ps1 -Mode Production` の回帰テスト | revert |

### 3.1 リスク

* 段階1でinclude構造を変えると、監査ペイロードの内容が変わり分析結果が変わる可能性がある。既存CaseFileを再実行し、`performance-summary.json` が一致することを確認してから進める。
* MT5のjunction・Data Folderは端末ごとの設定であり、切替時に旧EAのex5が残ると古いバイナリで検証する恐れがある。manifestの `expert_ex5_sha256`・`expert_ex5_older_than_source` で確認する。
* 段階4・5は履歴の書き換え・大量のファイル移動を伴い、既存ブランチ（`feature/mt5-vm-execution-backend` 等）とのマージ衝突が起きる。未マージのブランチを先に整理する。
* submoduleは更新・clone手順が増える。`git clone --recurse-submodules` と更新手順を `CONTRIBUTING.md` に追記する必要がある。

---

## 4. 本対応で実施した内容（Phase B）

| 内容 | 状態 |
| --- | --- |
| CaseFileの任意メタデータ（`validation_layer`、`acceptance_criteria`、`data_manifest`）と、MT5起動前の検証 | Implemented / Unit Tested |
| manifest.json 1.1（製品・検証基盤のcommit・dirty・ソースハッシュ、MT5端末バージョン、EAバージョン、ex5のSHA-256、実効tester.iniのSHA-256、合否区分） | Implemented / Unit Tested / Locally Tested（Host実行で1ケース確認） |
| Runnerの `-ProductSourceRoot` 引数（既定は `mt5/`） | Implemented / Unit Tested |
| 監査JSONL→分析CLI→成績指標の回帰テスト、Runnerと分析出力のキー契約テスト | Unit Tested |

VM実行モードでの新規項目の記録は未確認（NOT VERIFIED）。VM実行時はex5がVM側にあるため `expert_ex5_sha256` とMT5端末バージョンを記録しない。

### 4.1 段階1（研究計測のinclude分離、2026-10-10）

| 内容 | 状態 |
| --- | --- |
| `Research/TimingAnalysisHook.mqh` への研究計測の集約、`AuditPayloadBuilder.mqh` から研究計測依存の除去、EAControllerの `#ifdef` 切替 | Implemented / Locally Tested |
| 製品ビルド検査 `TestProductBuildWithoutResearch`（研究計測のincludeを一時的に戻すと失敗することを確認） | Unit Tested |
| 変更前後の成績・監査イベントの一致 | Locally Tested（下表） |

変更前（HEAD 795a9d8の製品ソース、run `20261010-222848`）と変更後（run `20261010-223352`）で、USDJPY_HIST 2021年の3ケースを同じテンプレートで実行し、`performance-summary.json` の全指標と、監査JSONLの全イベント（実行ごとに変わる `event_id` を除く）が完全一致した。ex5のSHA-256は前後で異なり、別バイナリで実行したことを確認している。

| ケース | テンプレート | 取引数 | 純損益 | PF | 研究計測イベント | 結果 |
| --- | --- | ---: | ---: | ---: | --- | --- |
| BASE | `StrategyTester-Generic-H1.ini` | 28 | 23,799 | 1.448 | なし | 一致 |
| ENTRYTIMING | `StrategyTester-Generic-EntryTiming-H1.ini` | 28 | 23,799 | 1.448 | ENTRY_TIMING 1,357件 | 一致 |
| BREAKOUTTIMING | `StrategyTester-Generic-BreakoutTiming-H1.ini` | 28 | 23,799 | 1.448 | BREAKOUT_TIMING 691件 | 一致 |

この数値は不変性の確認のための1銘柄・1年の結果であり、性能評価ではない。他の銘柄・期間での一致は未確認（NOT VERIFIED）。

### 4.2 段階2（外部連携を製品から除外、2026-10-11）

| 内容 | 状態 |
| --- | --- |
| `EAEntryPoint.mqh` への入口の共通化、`ProductEA.mq5` 追加、EAController・AuditEventPublisherの外部連携を研究ビルド限定に変更 | Implemented / Locally Tested |
| `TestProductBuildWithoutResearch` に外部連携4モジュールの非混入検査を追加 | Unit Tested（追加した外部連携の検査について、混入時に失敗することの確認は未実施。仕組みは段階1で確認済み） |
| Release Gateの静的検査を入口ファイルへ変更し、製品EAが研究マクロを定義しないこと、既存ポジション監視がRisk Managerの新規注文評価より先であることを追加 | Implemented（開発ゲートで実行） |

検証（USDJPY_HIST・EURUSD_HIST、2021年）:

* 研究ビルド不変: 段階1の3ケース（run `20261010-223352`）と変更後（run `20261011-002041`）で、成績指標・監査イベント（`event_id` 除く）が完全一致した。
* 製品ビルド: `ProductEA`（`StrategyTester-Product-H1.ini`）と、研究ビルド `CoreEA`（`StrategyTester-Generic-H1.ini`、Tester判断Mock常時許可）で、成績指標が完全一致し、監査イベントも研究ビルドだけが出力する `EXTERNAL_DECISION` と外部判断由来の `request_id` を除いて完全一致した（run `20261011-002041`・`20261011-002333`）。製品ビルドの `EXTERNAL_DECISION` は0件。

| 銘柄 | 取引数 | 純損益 | PF | `EXTERNAL_DECISION`（研究/製品） | 結果 |
| --- | ---: | ---: | ---: | --- | --- |
| USDJPY_HIST | 28 | 23,799 | 1.448 | 48 / 0 | 一致 |
| EURUSD_HIST | 29 | 28,365 | 1.472 | 47 / 0 | 一致 |

この結果は、これまで研究ビルドの常時許可Mockで取得してきた成績が、製品ビルドの判断経路と同じであることを2銘柄・1年で確認したものであり、性能評価ではない。他の銘柄・期間は未確認（NOT VERIFIED）。

---

## 5. 製品リポジトリの分離（段階3〜5、2026-10-11実施、DEC-047）

### 5.1 分離条件と判定

| 条件 | 結果 |
| --- | --- |
| 製品ビルドのinclude閉包が研究ルート（`EaTradingSystemResearch`）を `#ifdef` 外で参照しない | 満たす（静的解析、`TestProductBuildWithoutResearch`） |
| 製品テストが研究ファイルに依存しない | 満たす（`TestProductionSafetyRules`・`TestAuditPayloadBuilder` の研究部分を `TestMockDecisionProvider`・`TestTimingAnalysisPayload` へ分離） |
| 分離前の変更がコミット済みで、履歴付きで抽出できる | 満たす（ユーザー承認のうえ `2ae9fec`・`4b9d01c` をコミット） |
| GitHubリポジトリ作成・push権限 | 満たす（`ryknk` アカウント、`repo` スコープ、ユーザー承認） |
| 未マージのブランチが製品ファイルを変更していない | 満たす（`feature/mt5-vm-execution-backend` はdevへマージ済み） |

### 5.2 実施内容

* 製品リポジトリ: [ryknk/EA-Product](https://github.com/ryknk/EA-Product)（private、`main`・`dev`）。
* 履歴: `git filter-branch --index-filter` で製品ファイル62件（`ProductEA.mq5`、Include 41件、製品テスト10件とその起動設定）の履歴だけを抽出した。パスを変えていないため、ファイルごとの履歴が残る（元の78コミット中、製品ファイルを変更した38コミット）。各コミットに `Source-Commit: ryknk/EA-Trading-System@<sha>` を追記した。抽出後のファイルは元リポジトリ `4b9d01c` と全件同一blobであることを確認した。元リポジトリの履歴は変更していない。
* 製品リポジトリに追加: README・CLAUDE.md・`.gitignore`（ex5・ビルドログを管理対象外）、単独利用時の `tools/link-mt5.ps1`・`compile-mql5.ps1`・`run-mql5-tests.ps1`。
* 開発基盤: 製品ファイル62件と対応するex5を削除し、`product/` にsubmodule（`branch = main`）を追加した。`mt5/` には研究ビルド `CoreEA`、研究用Include（`EaTradingSystemResearch` ルート）、研究テスト、診断ツールが残る。
* 研究用ファイルの参照は分離前に `EaTradingSystemResearch` ルートへ変更した（`4b9d01c`）。製品の `EAController.mqh`・`AuditEventPublisher.mqh` には研究ビルド用の `#ifdef` ブロックが残るが、製品ビルドではコンパイルされない。
* ツール: `link-mt5.ps1`（`-Relink` で既存ジャンクションだけを張り替え）、`compile-mql5.ps1`（製品側は `product/tools/compile-mql5.ps1` を呼ぶ）、`run-mql5-tests.ps1`（製品・研究の `Test*.ini` を列挙）、`release-gate.ps1`（静的検査を `product/` に向け、submoduleが記録commitと一致することを検査）、Runner（`-ProductSourceRoot` 既定を `product/mt5` に変更、研究ビルドのEAバージョンを開発基盤側から解決）。
* 製品ビルドのStrategy Testerテンプレートは `Expert=EaTradingSystemProduct\ProductEA` に変更した。研究ビルドのテンプレート（`Expert=EaTradingSystem\CoreEA`）は変更していない。

### 5.3 検証

| 検証 | 結果 |
| --- | --- |
| GitHubからcloneした製品リポジトリだけでコンパイル（MetaEditor `/include` を製品Includeだけの一時ルートに限定） | `ProductEA` と製品テスト10件、計11件が0 errors・0 warnings。同条件で研究ルートを参照するファイルは「not found」で失敗し、開発基盤のファイルへ解決されないことを確認 |
| 開発基盤からのコンパイル（submodule経由） | 製品11件・研究7件、計18件が0 errors・0 warnings |
| MQL5実行テスト | 製品10件・研究6件、計16件PASS |
| Python・Lambda・CDK | 246件PASS |
| 移行前後のStrategy Tester（USDJPY_HIST・EURUSD_HIST 2021年、製品ビルド2ケース・研究ビルド3ケース） | 分離前 run `20261011-004835` と分離後 run `20261011-005814` で、全5ケースの成績指標と監査イベント（`event_id` 除く）が完全一致 |
| 分離後のmanifest | `provenance.product` が製品リポジトリ（submodule）のcommit `6046e48`・`dirty=false` を記録。製品ケースのExpertは `EaTradingSystemProduct\ProductEA` |

ソースハッシュ（`source_tree_sha256`）は、分離前が開発基盤の `mt5/Experts`・`mt5/Include` 全体（研究用ファイルを含む）、分離後が製品ファイルだけを対象にするため値は一致しない。同一性はblob照合と上記の結果一致で確認した。ex5のSHA-256も再コンパイルにより変わる。

製品の単独実行スクリプト（`product/tools/run-mql5-tests.ps1`）による単体テスト実行は、開発基盤のジャンクションと同名のため未実施（開発基盤の `run-mql5-tests.ps1` で同じ製品テストを実行済み）。VM実行モードは分離後の構成で未確認（NOT VERIFIED）。

### 5.4 運用手順

* 新規clone: `git clone --recurse-submodules https://github.com/ryknk/EA-Trading-System.git` → `.\tools\link-mt5.ps1`。
* 既存環境の移行: `git pull` → `git submodule update --init` → MT5終了 → `.\tools\link-mt5.ps1 -Relink` → `.\tools\compile-mql5.ps1`。
* 製品の変更: 製品リポジトリで変更・コミットし（`dev` → `main` はPull Request）、開発基盤で `git -C product checkout <commit>` → `git add product` → 検証 → コミット。
* 切り戻し: 開発基盤で分離コミットをrevertし、`git submodule deinit product`、`.\tools\link-mt5.ps1 -Relink`（`Include\EaTradingSystem` を `mt5\Include` へ戻す）、再コンパイル。製品リポジトリはGitHub上に残る（削除は不要。削除する場合はユーザーが操作する）。

### 5.5 残課題

* 製品リポジトリのブランチ保護（`main` への直接push禁止等）はGitHub上でユーザーが設定する。
* VM実行モード、他の銘柄・期間での前後一致は未確認。
* 本番証跡JSONとmanifest（製品commit・ex5 SHA-256）の関連づけは未実装。
* `HANDOFF.md`（Git管理外）は分離前の構成の記述のまま。
