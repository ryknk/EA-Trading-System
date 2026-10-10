# 開発基盤と製品EAの分離

本書は、本リポジトリを「EAの研究・検証・分析を行う開発基盤」として整理し、販売EA本体を将来の別リポジトリ（仮称 `EA-Product`）へ分離するための現状調査・境界定義・移行計画である。設計判断は `DECISIONS.md` DEC-044。

現時点では**リポジトリ分離は未実施**であり、製品EAのソースは引き続き本リポジトリの `mt5/` にある。本書の「移行手順」は計画であり、実施済みではない。

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
| `EAController.mqh` のinclude | 製品中核と、外部連携・研究計測（Entry/Breakout Timing）を同一EAへ静的に結合 | 製品から研究計測・外部連携を外すにはinclude構造の変更が必要（2.3節） |
| `AuditPayloadBuilder.mqh` | 監査ペイロード生成が研究計測クラスへ依存 | 研究計測イベントの生成を研究側へ移す |
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

外部連携（Decision API・Telemetry・Heartbeat）を製品へ含めるかは**未決定**である（含めない場合、製品はAWSへ依存しない。含める場合も既定無効と安全側の失敗時挙動を維持する）。

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

## 3. 移行手順（Phase C、未実施）

各段階は独立してコミット・検証・切り戻しできる単位とする。段階1〜3は本リポジトリ内で完結し、既存の `dev` / `main` 運用を変えない。

| 段階 | 作業 | 検証 | 切り戻し |
| --- | --- | --- | --- |
| 1 | 研究計測（`EntryTimingAnalyzer`・`BreakoutTimingAnalyzer`）と監査ペイロード生成の依存を分け、製品中核が研究計測なしでコンパイルできるincludeにする | `compile-mql5.ps1`、`run-mql5-tests.ps1`、既存CaseFileの再実行で成績が変わらないこと | 該当コミットのrevert |
| 2 | 外部連携を製品へ含めるかを決定し、`DECISIONS.md` へ記録する | — | — |
| 3 | `link-mt5.ps1`・`compile-mql5.ps1`・`run-mql5-tests.ps1`・`release-gate.ps1` が製品ソースのルートを引数で受け取れるようにする（既定は現行の `mt5/`） | 既定引数で従来どおり動くこと、別パス指定で同じ結果になること | revert |
| 4 | `EA-Product` リポジトリを作成し、`mt5/Experts/CoreEA.mq5`・製品中核の `mt5/Include`・製品テストを `git filter-repo` 等で履歴付きで移す（**ユーザー承認が必要**） | 製品リポジトリ単独でコンパイル・テストが通ること | 製品リポジトリを破棄（本リポジトリは未変更） |
| 5 | 本リポジトリへsubmodule `product/` を追加し、junction元を `product/mt5` へ切り替える。旧 `mt5/` の製品ファイルを削除する（**ユーザー承認が必要**） | 開発ゲート一式、代表CaseFile（例: Walk Forward）の再実行で成績・ex5ハッシュが段階4前と一致すること | submoduleの削除と旧ファイルの復元（revert） |
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
