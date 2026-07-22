# EA Trading System

## システム概要

MetaTrader 5上のルールベース戦略を起点に、AWS上のML/LLMフィルターと、EA内の独立Risk Managerを組み合わせる個人向け自動売買基盤です。利益最大化よりも、安全性、再現性、可観測性、フェイルセーフを優先します。

> **重要**: 本ソフトウェアは投資助言ではありません。バックテスト結果だけで実口座へ移行しません。Strategy Tester、Out-of-Sample、Walk Forward、デモ、小額実口座の順に検証し、損失可能性を理解した上で利用します。

Phase 13の本番準備状況は [本番準備状況レポート](docs/production-readiness-report.md) と [本番運用前チェックリスト](docs/production-readiness-checklist.md) を参照してください。2026-07-21時点の判定は、外部環境と実市場検証が未完了のため **NO-GO** です。

## 現在の状態

Phase 12（日本語文書統合・リリースゲート）まで実装済みです。必須文書、安全な初期値、秘密情報混入、API契約、Python・Lambda・CDK、MQL5実コンパイル・script testを一括検証できます。

ただし、これはproduction運用可能という意味ではありません。AWS deploy、実データモデル配備、LLM実API疎通、MQL5 VPS上の秘密ファイル、OOS・Walk Forward・デモ・小額実口座は未検証です。現時点のproductionゲートは不合格です。

## アーキテクチャ概要

1. MQL5 Strategyが確定足で売買方向と根拠を生成
2. ローカルFilter通過時だけDecision APIを呼び出す
3. Lambdaが入力検証、リプレイ検査、ML推論を実施
4. ML閾値通過時だけLLMへ問い合わせ、`ALLOW` / `VETO`を取得
5. EAが応答の整合性・有効期限を検査
6. EA内Risk Managerが最終承認し、Order Managerが発注
7. 外部障害・不正応答・Risk Manager異常はすべて新規注文拒否
8. 取引イベントをローカルJSONLへ記録し、有効時だけ別のTelemetry APIへベストエフォート送信

既存ポジションのSL、緊急クローズ、リスク削減は外部APIに依存しません。詳細は [architecture](docs/architecture.md) を参照してください。

## ディレクトリ

- `mt5/`: EA、Strategy、Risk、Trading、External、Logging
- `services/decision_api/`: Lambdaアプリケーション（Phase 6以降）
- `python/`: 特徴量、学習、推論、分析（Phase 7以降）
- `infra/`: AWS CDK（Python、Phase 6以降）
- `contracts/`: API JSON Schemaとバージョン管理された契約
- `docs/`: 設計・運用文書

## セットアップ / ローカル開発

Python 3.12仮想環境を作成し、`pip install -r infra/requirements-dev.txt` と `pip install -r python/requirements.txt` で依存を導入します。`.\tools\test-phase12.ps1` でLambda・ML・LLM・監査API・分析・監視・文書・CDKテストとsynthを一括実行できます。MQL5は連携済みjunctionを利用し、`.\tools\compile-mql5.ps1` でコンパイルします。

ローカルMT5とはdirectory junctionで連携済みです。全targetのcompileは `.\tools\compile-mql5.ps1`、全script testはMT5を閉じて `.\tools\run-mql5-tests.ps1` を実行します。詳細は [MT5 local development](docs/mt5-development.md) を参照してください。

## AWSデプロイ

AWS CDK v2（Python）を採用しています。ML設定に加え、明示的に `-c llm_provider=openai -c llm_model=<固定モデルID>` を指定した場合だけLLMを有効化します。OpenAI APIキーは `/ea-trading-system/dev/providers/openai/api-key` のSecureStringへ登録します。秘密値をCDK context、出力、Gitへ保存してはいけません。

Phase 11ではSNS Alert Topicを作成します。`-c alarm_email=<通知先>` を指定した場合は確認メールへの承認後に通知が有効になります。CloudWatch Dashboardは固定費を避けるため既定無効で、必要な環境だけ `-c enable_dashboard=true` を指定します。`-c metrics_enabled=false` でEMF、`-c log_level=WARNING` などでログ量を調整できます。

初回deployはモデル・LLM未設定のフェイルセーフVETO状態でdevへ行い、S3 model、SHA-256、SSM SecureString、SNS購読を確認してから設定付きで再deployします。productionへ直接deployしません。詳細は [AWSインフラ](docs/aws-infrastructure.md) と [リリースゲート](docs/release-gate.md) を参照してください。

## MQL5への配置 / VPS移行

`mt5/Experts`、`mt5/Include`、`mt5/Tests` はdirectory junctionでローカルMT5と連携します。VPS移行前にWebRequest許可URL、EA設定、AutoTrading、シンボル仕様、UTC時刻、監査ログ、共有鍵ファイル読込を確認し、チャートとEAをMQL5 VPSへ同期します。PythonやWebサーバーはMQL5 VPSへ配置しません。詳細は [MT5ローカル開発・VPS移行](docs/mt5-development.md) を参照してください。

## 設定の原則

資金額、通貨ペア、時間足、指標期間、閾値、リスク率、損失上限、API URL、タイムアウトは外部設定化します。秘密情報をソース管理しません。初期値は1トレード0.5%、日次損失2%、最大ドローダウン10%です。

`InpEnableTradeMutations` と `InpDecisionApiEnabled` の初期値はfalseです。新規注文には検証済み外部ALLOWと最新Risk承認の両方が必要です。ただし同じマジックナンバーの既存ポジションに保護SLがない場合、取引変更が有効かつ`InpCloseUnprotectedPositions=true`ではPosition Managerが外部APIに依存せず緊急決済を試行します。

監査ファイルは既定で有効で、端末の `MQL5\Files\EaTradingSystem\Audit\audit-YYYYMMDD.jsonl` に追記します。`InpTelemetryEnabled` は既定でfalseです。有効化時はCDK出力のTelemetry API URLを `InpTelemetryApiUrl` とMT5のWebRequest許可リストへ設定します。テレメトリ障害は記録だけ行い、既存ポジション管理や売買判断を変更しません。

全入力値、初期値、変更時の注意点は [設定](docs/configuration.md) を参照してください。

## バックテスト

検証順は Strategy Tester → In-Sample → Out-of-Sample → Walk Forward → Demo → Small Real → Production です。Net Profit、CAGR、Max Drawdown、Profit Factor、Sharpe、Win Rate、Average Win/Loss、Expectancy、最大連敗、取引数を同じ定義で記録します。

Phase 9監査JSONLからレポートを作る例:

```powershell
$env:PYTHONPATH='.'
python -m python.analysis.reports `
  --input audit-20250701.jsonl `
  --input audit-20250702.jsonl `
  --initial-balance 1000000 `
  --output build/performance-report
```

JSON、Markdown、正規化取引CSV、資産曲線CSV、月次成績CSVを出力します。詳細は [backtesting](docs/backtesting.md) を参照してください。

## 障害時対応

外部API、ML、LLM、JSON、認証、時刻、Risk Managerの異常時は新規注文を停止します。既存ポジション管理を継続し、候補IDと理由コードをローカルログへ記録します。復旧後も自動再発注せず、新しい確定足の新規候補として再評価します。

## 本番運用前チェックリスト

- OOS / Walk Forward / Demoの受入基準を満たした
- 最大損失、最大DD、ポジション数、証拠金余力を確認した
- API障害、タイムアウト、不正JSON、LLM障害の拒否動作を確認した
- ブローカーのtick value、volume step、stop levelで検証した
- アラーム、ログ保持、予算アラート、秘密情報ローテーションを確認した
- 小額実口座で十分なフォワード期間を完了した
- 緊急停止と手動決済の手順を実施した

上記だけで承認せず、証跡を伴う [リリースゲート](docs/release-gate.md) を実行します。現在はAWS・VPS・OOS・デモ・小額実口座の証跡がないためproduction不合格です。

```powershell
.\tools\release-gate.ps1 -Mode Development
```

## 実装フェーズ

ロードマップと各Phaseの目的・変更範囲・リスクは [implementation-roadmap](docs/implementation-roadmap.md) に記載しています。
