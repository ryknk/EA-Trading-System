# Phase 12 実装記録

## 実装目的

Phase 1〜11の設計・実装・運用手順を日本語で統合し、安全な初期値と検証証跡を機械的に確認する。開発完了と本番承認を分離し、AWS・VPS・OOS・デモ等の証跡がない状態で実売買を有効化できない運用ゲートを定義する。

## 変更ファイル

- `README.md`: システム概要、現状、本番不合格、総合テスト、設定・VPS・release gate導線
- `docs/configuration.md`: MQL5全inputとAWS contextの日本語設定表
- `docs/release-gate.md`: 開発・本番ゲート、証跡、フラグ有効化順序
- `docs/mt5-development.md`: Phase 12実測結果、MQL5 VPS移行、rollback
- `docs/aws-infrastructure.md`: dev初回deploy、model・LLM設定、diff・rollback手順
- `docs/operations.md`: 本番チェックリストと未完了条件
- `contracts/production-release-evidence.schema.json`: 秘密値を含まない本番証跡契約
- `tools/release-gate.ps1`: 文書、安全初期値、秘密情報、契約、全テスト、MQL5実検証ゲート
- `tools/test-phase12.ps1`: Phase 12全回帰・CDK synth
- `python/tests/test_documentation.py`: 必須文書、日本語、README章、安全初期値、JSON、リンク整合性
- `mt5/Experts/CoreEA.mq5`: Phase 12 version・説明へ更新。売買ロジックは変更しない

## 設計判断

- release gateはAWS deploy、外部送信、発注を行わない。破壊的・課金対象操作は人間の明示手順に残す。
- Developmentはコード・文書・CDK・MQL5を実行検証し、Productionは追加で実績証跡JSONと参照レポートを必須にする。
- production証跡にはAWS account・region、model version・checksum、固定LLM model・prompt、検証済みフラグ、レポート相対pathだけを保存し、秘密値と口座番号を含めない。
- MQL5 VPSで共有鍵ファイルを読めることを実機確認できない場合はproduction不合格とする。
- `InpEnableTradeMutations`、Decision API、Telemetryは引き続き既定falseとし、監査ファイルだけを既定trueにする。
- 初期資金100万円を定数化せず、EAは専用口座の実equity、分析はCLIのinitial balanceを使う。
- READMEやチェックリストだけに依存せず、日本語文書、リンク、契約、安全初期値を自動テストする。

## 想定リスクと対策

- 文書と実装の乖離: 文書・README章・MQL5初期値・相対リンクをテスト対象にする。
- チェックリストの形骸化: ProductionではOOS、Walk Forward、demo、小額実口座の実ファイルを要求する。
- 秘密情報混入: 既知の秘密ファイル名とAWS access key形式をrelease gateで検査し、証跡directoryをGit管理外にする。
- 誤deploy: release gate自体はsynthまでとし、deployはaccount・region・diffを人間が確認する別手順にする。
- MQL5 VPS差異: 秘密ファイル、WebRequest、時刻、Journalを実機ゲートへ含める。
- 古い検証結果: 証跡にmodel・prompt version、checksum、承認UTC時刻を固定する。
- 本番適格の誤認: READMEとrelease gate冒頭に現時点のproduction不合格理由を明記する。

## 実装内容

- 必須日本語docsとREADMEの運用章を自動検査する。
- CoreEAの危険な3フラグfalse、監査trueを静的検査する。
- JSON Schema全件の構文とMarkdown相対リンクを検査する。
- 開発release gateからPython・Lambda・CDK全回帰、CDK synth、MQL5全対象コンパイル、MT5 script testを実行する。
- Productionではschema v1の証跡、4段階の評価レポート、VPS・SNS・Budgets・rollback検証を要求する。
- MQL5設定、VPS移行、AWS段階deploy、障害・rollback、本番フラグ有効化順序を文書化する。

## テスト結果

- 文書・リリースゲートテスト: 5件成功。
- Python・Lambda・CDK全回帰: 73件成功。
- CDK synth: 成功。
- MetaEditor実コンパイル: CoreEAとテスト6本、合計7対象が0 errors / 0 warnings。
- MT5 script test: 6スイート成功。
- Development release gate: 成功。
- Production release gate: 証跡未作成のため意図どおり不合格。

## 残課題

- dev AWS accountへの初回deployと実疎通。
- 実履歴データでのML学習、OOS、Walk Forward、model artifact固定。
- LLM providerの実回帰、利用上限、費用、timeout検証。
- MQL5 VPS上の共有鍵ファイルとWebRequest実機検証。
- demo、小額実口座の十分な期間・取引数・障害訓練。
- SNS通知、AWS Budgets、Cost Anomaly Detection、rollback drillの実証跡。

これらが完了するまでproductionへ昇格せず、取引変更フラグをfalseに維持する。
