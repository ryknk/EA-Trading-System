# 1. 目的

このファイルは、Claude Codeが `EA-Trading-System` を安全かつ一貫した方針で変更するための、プロジェクト固有の作業ルールを定義する。

詳細な仕様や手順は本ファイルへ重複記載せず、次の文書を正本とする。

* システム構成: `docs/architecture.md`
* 設定値: `docs/configuration.md`
* バックテスト: `docs/backtesting.md`
* AWS構成・デプロイ: `docs/aws-infrastructure.md`
* MT5開発・VPS移行: `docs/mt5-development.md`
* リリース条件: `docs/release-gate.md`
* 本番準備状況: `docs/production-readiness-report.md`
* 本番チェックリスト: `docs/production-readiness-checklist.md`
* 実装ロードマップ: `docs/implementation-roadmap.md`
* 引き継ぎ情報: `HANDOFF.md`
* 今後のタスク: `TASKS.md`
* 設計判断と技術選定理由: `DECISIONS.md`
* Git・ブランチ運用: `CONTRIBUTING.md`

文書と実装が矛盾する場合、推測で修正せず、該当箇所を報告すること。

---

# 2. 現在の安全状態

現在の本番移行判定は **NO-GO** である。

少なくとも次の外部検証は未完了である。

* Strategy Tester
* 実市場データによるOOS・Walk Forward
* AWS dev実通信
* LLM API実通信
* Demo口座
* MQL5 VPS
* 小額実口座

現在の進捗と未確認事項は `docs/production-readiness-report.md` と `TASKS.md` を参照すること。

次の安全な初期値を、検証手順上の明示的な理由なく変更しない。

```text
InpEnableTradeMutations = false
InpDecisionApiEnabled = false
InpTelemetryEnabled = false
```

特に `InpEnableTradeMutations=true` への変更は、ユーザーの明示的な許可なしに行わない。

---

# 3. 作業開始時の確認

重要な作業を開始する前に、次を行う。

1. `git status` を確認する。
2. 現在のブランチを確認する。
3. 未コミット差分を確認する。
4. `HANDOFF.md` と関連する `docs/` を読む。
5. 対象コードと関連テストを読む。
6. `TASKS.md` で現在の優先順位を確認する。
7. 技術選定や責務境界へ触れる場合は `DECISIONS.md` を確認する。

ユーザーが作成した未コミット変更を上書き、削除、整形しない。

対象外のファイルを便乗して変更しない。

---

# 4. アーキテクチャ上の不変条件

詳細は `docs/architecture.md` を正本とする。

最低限、次の条件を維持する。

## 4.1 Risk Managerが最終権限を持つ

Strategy、ML、LLM、Decision APIが承認しても、Risk Managerが拒否した場合は発注しない。

外部 `ALLOW` を直接の発注命令として扱わない。

## 4.2 既存ポジション管理を優先する

既存ポジション監視は、新規候補生成より先に実行する。

外部API、ML、LLM、Telemetryの障害によって、既存ポジション保護を停止させない。

## 4.3 外部障害時は新規注文を拒否する

次のような異常を、自動ALLOWへ変換しない。

* Timeout
* HTTPエラー
* WebRequest失敗
* 認証失敗
* Replay検出
* 不正JSON
* Schema不一致
* request ID不一致
* TTL切れ
* ML例外
* LLM例外
* Risk計算不能
* Margin不足
* OrderCheck失敗

外部障害で拒否した古い候補を、復旧後に自動再発注しない。

古い `ALLOW` を別候補へ流用しない。

## 4.4 Telemetryはベストエフォートとする

Telemetryの失敗によって、次を変更しない。

* 売買判断
* 注文結果
* 既存ポジション管理
* SL・TP管理

ローカル監査記録をTelemetryより先に保存する。

---

# 5. 責務境界

主要ディレクトリの責務を維持する。

```text
mt5/
  EA、Strategy、Risk、Trading、External、Logging、MQL5テスト

services/decision_api/
  Decision APIとTelemetry APIのLambdaアプリケーション

python/
  特徴量生成、ML学習・推論・評価、分析レポート

infra/
  AWS CDK v2によるInfrastructure as Code

contracts/
  API、Telemetry、レポート、リリース証跡のJSON Schema

docs/
  設計、設定、検証、運用、リリース文書

tools/
  コンパイル、テスト、Strategy Tester、Release Gate用スクリプト
```

Strategyから直接発注処理を呼び出さない。

Lambda Handlerへ認証、ML、LLM、Repositoryの全ロジックを集中させない。

Provider固有のLLM処理をApplication Logicへ直接埋め込まない。

API契約の正本は `contracts/` のJSON Schemaとする。

---

# 6. MQL5実装ルール

既存コードの形式と命名を優先する。

* `#property strict` を維持する。
* コンパイル警告を放置しない。
* 金額、価格、Lot、Pointを混同しない。
* Broker仕様を固定値として埋め込まない。
* Volume Min、Max、Step、Tick Size、Tick Value、Digitsを明示的に扱う。
* Lotを安全側でない方向へ丸めない。
* 最小Lot未満を無条件で最小Lotへ引き上げない。
* Netting口座とHedging口座の差を考慮する。
* Magic Number等で所有ポジションを識別する。
* 他EAや手動注文を誤って管理しない。
* 発注前に `OrderCheck` を実行する。
* Order送信成功だけで約定成功とみなさない。
* RetcodeとTrade Resultを確認する。
* 部分約定、Stop Level、Freeze Levelを考慮する。
* SL・TP変更失敗を無視しない。
* 確定していない足をEntry判定へ使用しない。
* 同一確定足で候補を重複生成しない。
* 重い外部通信を無条件に毎Tick実行しない。

時刻を扱う場合は、UTC、Broker Server Time、Local Time、Bar Timeを明確に区別する。

---

# 7. Python実装ルール

Python 3.12を使用する。AWS Lambda実行環境（`infra/ea_trading_system_stack.py`）が`PYTHON_3_12`に固定されているため、ローカル開発でも3.12で統一する。

* 公開関数へ型ヒントを付ける。
* `Any` を必要最小限にする。
* Mutable Default Argumentを使用しない。
* 例外を無言で破棄しない。
* 外部境界では例外を安全側の結果へ変換する。
* NaN、Infinityなどの非有限値を拒否する。
* 外部契約でNaive Datetimeを使用しない。
* 入力Schemaを境界で検証する。
* API内部のStack Traceや秘密情報をレスポンスへ含めない。
* 同じ意味のDTOを複数箇所へ重複定義しない。

ML処理では、未来情報やOOS情報をTraining、Scaler Fit、Feature Selectionへ使用しない。

---

# 8. AWS・CDK実装ルール

詳細は `docs/aws-infrastructure.md` と `DECISIONS.md` を参照する。

* AWS CDK v2とPythonを維持する。
* dev、staging、productionを分離する。
* IAMは必要最小限にする。
* SecretをCDK ContextやCloudFormation Outputへ含めない。
* stagingとproductionのデータリソース保護を弱めない。
* Infrastructure変更時は `cdk synth` と `cdk diff` を確認する。
* CloudWatch Dimensionへ高カーディナリティ値を追加しない。
* MetricsやLoggingの失敗を取引判断へ影響させない。

明示的な設計変更なしに、次を追加しない。

* NAT Gateway
* RDS
* 常時稼働EC2
* 常時稼働Container
* LambdaのVPC配置
* 広範なIAM Wildcard
* productionリソースの自動削除

---

# 9. ML・LLM実装ルール

## 9.1 ML

* 時系列順序を維持する。
* Training、Calibration、OOSを分離する。
* 必要なgapを設ける。
* OOS結果を見た後、同じOOS期間へ再最適化しない。
* Model ArtifactとSHA-256を検証する。
* Model未設定、checksum不一致、ロード失敗時はVETOする。
* 複雑なモデルへ変更する場合は、OOSとWalk Forwardで改善を示す。

## 9.2 LLM

* LLMをStrategy生成主体や直接の発注主体にしない。
* 構造化された `ALLOW` または `VETO` だけを受け付ける。
* 自然言語を曖昧に発注判断へ変換しない。
* Schema不一致、Timeout、Provider Error、不正値はVETOする。
* Provider、Model、PromptにはVersionを持たせる。
* Prompt変更時はVersionを更新し、回帰評価する。
* Shadow Modeの既定値を無断で変更しない。
* LLM API疎通成功と、LLMの投資判断上の有効性を混同しない。

---

# 10. Secretとログ

次をGit、文書、テストデータ、プロンプトへ保存しない。

* AWS Access Key
* AWS Secret Key
* Session Token
* LLM API Key
* HMAC共有鍵
* Broker Password
* Private Key
* 完全なAccount Login Number
* Authorization Header
* Secret Fileの内容

Server側SecretはSSM Parameter Store SecureStringを使用する。

EA側の共有鍵は、指定されたMQL5 Secret Fileから読み込む。

疑わしい秘密情報を発見した場合、値を出力せず、ファイル名と種類だけを報告する。

ログには必要に応じて次を含める。

* UTC Timestamp
* Environment
* Service
* EA ID
* Strategy ID
* Trade Candidate ID
* Request ID
* Event Type
* Decision
* Reason Code
* Model Version
* Prompt Version
* Duration
* Error Category

---

# 11. テスト

変更箇所に対応するテストを実行する。

## MQL5

```powershell
.\tools\compile-mql5.ps1
.\tools\run-mql5-tests.ps1
```

MQL5 Script Testの前に、必要に応じてMT5を終了する。

## CDK

```powershell
cd infra
cdk synth -c environment=dev
```

## Development Release Gate

重要な変更後は、可能な限り次を実行する。

```powershell
.\tools\release-gate.ps1 -Mode Development
```

テストを実行できない場合は、次を報告する。

* 実行できなかったテスト
* 理由
* 必要な環境
* 代替確認
* 残存リスク
* ユーザーが実行するコマンド

実行していない試験を「PASS」や「検証済み」と記載しない。

---

# 12. 文書更新

実装変更時は、正本となる関連文書を更新する。

* Architecture: `docs/architecture.md`
* 設定: `docs/configuration.md`
* AWS: `docs/aws-infrastructure.md`
* Backtest: `docs/backtesting.md`
* Release条件: `docs/release-gate.md`
* 本番準備状況: `docs/production-readiness-report.md`
* 将来タスク: `TASKS.md`
* 設計判断: `DECISIONS.md`
* Git運用: `CONTRIBUTING.md`

次の状態を区別して記載する。

* Implemented
* Unit Tested
* Locally Tested
* Synthesized
* Deployed
* Integration Tested
* Demo Verified
* Production Verified

確認できない内容は `NOT VERIFIED` または「未確認」とする。

---

# 13. 操作制限

ユーザーの明示的な許可なしに次を実行しない。

* `cdk bootstrap`
* `cdk deploy`
* `cdk destroy`
* AWSリソースの作成・削除
* SSM Secretの登録・取得
* MT5 AutoTradingの有効化
* Demo口座での注文
* 実口座での注文
* MQL5 VPSへの同期
* `InpEnableTradeMutations=true`
* production設定の変更
* production Modelの配備
* Git commit
* Git push
* Pull Request作成
* Force Push
* Branch削除

操作が必要な場合は、事前に次を提示する。

* 実行コマンド
* 変更対象
* 安全性への影響
* 費用への影響
* Rollback方法
* 確認すべき結果

---

# 14. 禁止される実装

次を導入しない。

* Martingale
* ナンピン
* 損失後の自動Lot増加
* 無制限のポジション追加
* Stop Lossなしの通常運用
* 外部API応答だけに基づく発注
* LLM自然言語からの直接発注
* Error時またはTimeout時の自動ALLOW
* 古いALLOWの再利用
* API復旧後の自動再発注
* Secretのコード埋込み
* OOSを利用した過剰最適化
* テストを通すための安全条件緩和
* productionでのDEBUG常用
* Telemetry成功を注文条件にする
* 外部API障害による既存ポジション管理停止

---

# 15. 実装作業の進め方

重要な変更は次の順序で進める。

1. 関連文書、コード、テストを読む。
2. Git状態と未コミット差分を確認する。
3. 現在の挙動を確認する。
4. 変更目的と影響範囲を整理する。
5. 最小限の変更を実装する。
6. テストを追加または更新する。
7. 関連テストを実行する。
8. Git Diffをレビューする。
9. Secret混入を確認する。
10. 関連文書を更新する。
11. 残存リスクと未確認事項を報告する。

作業完了時は、以下を報告する。

* 変更ファイル
* 変更理由
* 安全性への影響
* 実行したテスト
* 実行できなかったテスト
* 未確認事項
* 残存リスク
* Rollback方法

---

# 16. 判断に迷った場合

安全性に関わる判断で迷った場合は、次を優先する。

1. 新規注文を拒否する。
2. 既存ポジション保護を継続する。
3. Secretを出力しない。
4. productionを変更しない。
5. リスク閾値を緩和しない。
6. 古い候補を再利用しない。
7. 推測で実装しない。
8. 不明点を「未確認」とする。
9. 必要な確認ファイルまたは操作を示す。
10. 安全性への影響をユーザーへ報告する。

本プロジェクトでは、動かないことより、危険な状態で動くことの方が重大な障害である。
