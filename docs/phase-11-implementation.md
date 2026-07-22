# Phase 11 実装記録

## 実装目的

取引判断と監査保存の障害を早期に検知し、フェイルセーフ停止の原因を環境別に追跡する。個人利用の低頻度システムであることを前提に、メトリクス系列、ログ量、ダッシュボードの固定費を抑える。

## 変更ファイル

- `services/decision_api/src/decision_api/monitoring.py`: 依存ライブラリなしのEMF出力
- `services/decision_api/src/decision_api/handler.py`: Decision結果・内部エラー・遅延・リプレイの計測
- `services/decision_api/src/decision_api/telemetry_handler.py`: Telemetry障害・Risk拒否・遅延の計測
- `infra/ea_trading_system_stack.py`: SNS、8アラーム、任意Dashboard、Logs Insights widget
- `infra/config.py`: 環境別リプレイ閾値・ログレベル
- `services/decision_api/tests/test_monitoring.py`: EMF、dimension、無効化、監視障害分離、handler統合テスト
- `infra/tests/test_stack.py`: SNS、アラーム通知、任意DashboardのCDKテスト
- `tools/test-phase11.ps1`: Phase 11一括検証
- `README.md`、`docs/aws-infrastructure.md`、`docs/security.md`、`docs/operations.md`: 日本語の監視・運用文書

## 設計判断

- Lambdaが例外をHTTP 500へ変換するため、標準Lambda `Errors`だけに依存せず、捕捉済み内部エラーをカスタムメトリクス化する。
- EMFを標準出力し、invocationごとのPutMetricData API呼び出しと追加SDK依存を避ける。
- dimensionは `Environment`、`Service` の2つに固定する。候補ID、request ID、symbol、理由コードをdimensionにしない。
- DecisionのML・LLM状態とTelemetry event typeはログ属性として保持し、Logs Insightsで集計する。すべてをカスタムメトリクス化しない。
- 監視コードは例外を外へ出さず、ALLOW/VETO、HTTP応答、Telemetry保存結果へ影響しない。
- アラームはSNS Topicへ接続するが、メール購読は `alarm_email` contextが指定された場合だけ作る。
- Dashboardは固定費を避けるため既定無効とし、必要な環境だけ明示的に有効化する。
- 取引候補がない時間は正常であるため、API無通信を障害としてアラームにしない。

## 想定リスクと対策

- メトリクス費用: 低カーディナリティdimensionと必要最小限のメトリクスに限定し、`metrics_enabled=false`も用意する。
- ログ費用: 環境別保持期間、設定可能なログレベル、候補・イベント発生時だけの出力を使用する。
- アラーム過多: 5分単位、欠損はnotBreaching、VETOそのものはアラームにしない。
- 500見逃し: Lambda標準Errors、カスタム内部エラー、API Gateway 5xxの異なる層で検知する。
- 通知未達: SNS Topic ARNを出力し、購読確認とテスト通知をdeploy後チェックリストへ入れる。
- 監視障害の売買波及: EMF生成・出力失敗を握りつぶす単体テストを追加する。
- 情報漏えい: 秘密情報・認証ヘッダー・口座番号・高カーディナリティIDをメトリクスdimensionへ含めない。

## 実装内容

- Decision: `DecisionRequestCount`、`DecisionAllowCount`、`DecisionVetoCount`、`DecisionInternalErrorCount`、`DecisionLatencyMs`、`SecurityReplayRejectedCount`。
- Telemetry: `TelemetryRequestCount`、`TelemetryInternalErrorCount`、`TelemetryLatencyMs`、`RiskRejectedCount`、`SecurityReplayRejectedCount`。
- 非dimension属性: outcome、reason code、ML status、LLM status、Telemetry event type。
- SNS通知対象: Decision標準Lambda error、Decision p99 duration、Telemetry標準Lambda error、Decision内部エラー、Telemetry内部エラー、リプレイ拒否、HTTP API 5xx、Lambda throttle。
- 任意Dashboard: Decision結果、p99 latency、API 4xx・5xx、Lambda error・throttle、ML・LLM結果、Telemetry結果。
- CDK context: `alarm_email`、`enable_dashboard`、`metrics_enabled`、`log_level`。

## テスト結果

- Phase 11監視・CDK対象テスト: 11件成功。
- Python・Lambda・CDK全回帰: 68件成功。
- CDK synth: 成功。
- MQL5コードはPhase 11で変更していない。

## 残課題

- AWS実環境へdeployし、SNS購読確認、テスト通知、実EMF抽出、Dashboardクエリを検証する。
- AWS BudgetsとCost Anomaly Detectionは通知先・月額上限を利用者が確定してから設定する。
- Risk拒否メトリクスはTelemetry有効時だけAWSへ到達する。無効時はローカルJSONLを正とする。
- EA heartbeatのリモート監視は未実装。候補がない時間を障害扱いしない別設計が必要である。
- Phase 12で本番runbook、deploy手順、リリースゲートを最終統合する。
