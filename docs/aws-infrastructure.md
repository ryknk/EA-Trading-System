# AWSインフラ

Phase 13ではLambda Error/Duration、API 5xx、Replay、Throttle、Decision/Telemetry内部エラーに加え、`MlErrorCount`、`LlmErrorCount`、DynamoDB GetItem/PutItem `SystemErrors` のAlarmを定義する。ログ保持はdev 14日、staging 30日、production 90日で、productionのDEBUG常用を禁止する。CDK synthは検証済みだが、AWS上のAlarm作成・SNS通知到達は未検証である。

IaCはAWS CDK v2 + Pythonを採用する。アプリと同じPythonの型・テストツール群を使え、個人規模のAWSサーバーレス構成要素を簡潔に表現できるためである。Terraformの複数クラウド対応よりAWS固有統合と開発速度を優先する。

環境ごとにコンテキスト・設定を分け、リソース名、保持期間、アラーム閾値、モデル・プロンプトのバージョンを明示する。本番環境は別口座を推奨する。API Gateway HTTP API、Lambda、DynamoDBオンデマンド、S3、CloudWatchを基本とし、NAT Gateway、常時稼働コンピューティング、RDSは置かない。

CloudWatch LogsはJSONの警告・エラー中心とし、開発14日、ステージング30日、本番90日を初期候補として設定可能にする。カスタムメトリクスはDecisionCount、VetoCount、ErrorCount、Latency、ReplayRejected、RiskReject（EAテレメトリー導入後）とする。AWS Budgetsと費用異常アラートを設定する。

Phase 6では `infra/` にCDK v2スタックを実装した。HTTP APIの `$default` ステージ、ARM64/Python 3.12 Lambda、オンデマンドDynamoDB、暗号化・公開遮断・バージョン管理済みS3、保持期限付きログ、Lambda Error/p99 Durationアラームを作成する。APIはバースト5、毎秒2リクエストを初期上限とする。VPC、NAT Gateway、RDSは使用しない。

環境は `cdk synth -c environment=dev` のように選ぶ。devは破棄可能、stagingとproductionはデータをRETAINしPITRを有効にする。本番は別AWSアカウントを使用し、deploy前にCloudFormation差分、リージョン、AWSアカウント、予算通知先を確認する。

Phase 7ではLambdaへ `ML_MODEL_KEY`、`ML_MODEL_SHA256`、`ML_MIN_WIN_PROBABILITY`、`ML_MIN_EXPECTED_RETURN` を設定する。モデルキーとchecksumはCDK contextで指定できる。モデルbucketはスタック生成名を使用するため、初回deploy後に成果物をアップロードし、checksum付きで再deployする。checksum未設定時はモデルを読み込まず安全にVETOする。

Phase 8では `LLM_PROVIDER`、`LLM_MODEL`、`LLM_PROMPT_VERSION`、`LLM_TIMEOUT_SECONDS`、`LLM_TEMPERATURE` をLambda環境変数へ設定する。provider/modelはCDK contextで明示した場合だけ有効になる。APIキーは環境別SSM SecureStringに置き、Lambda IAMは `/ea-trading-system/<environment>/providers/*` の読取りだけを許可する。NAT GatewayやVPCは追加しない。

Phase 9では同じHTTP APIへ `POST /v1/trade-events` を追加し、判断処理と分離したTelemetry Lambdaへ接続する。DynamoDBへ `candidate-index` GSIを追加し、候補IDから判断・取引イベントを時系列照会できる。Telemetry LambdaはARM64/Python 3.12、128 MiB、3秒timeoutとし、専用ロググループとエラーアラームを持つ。DynamoDBは引き続きオンデマンド課金で、常時稼働サービスは追加しない。

## Phase 11の監視構成

LambdaはCloudWatch Embedded Metric Formatを標準出力し、追加のPutMetricData API呼び出しを行わない。namespaceは `EaTradingSystem`、dimensionは `Environment` と `Service` だけに固定する。候補ID、request ID、symbol、理由コード、event typeはdimensionにせず、高カーディナリティな時系列と費用増加を防ぐ。例外として2026-09-26以降、Heartbeat欠損検知用の `HeartbeatReceivedCount` だけは、CDK context `heartbeat_ea_ids` で明示したEA ID（最大10件）に限り `EaId` dimensionを付与する。

Decisionでは要求数、ALLOW、VETO、捕捉済み内部エラー、処理時間、リプレイ拒否を記録する。Telemetryでは要求数、捕捉済み内部エラー、処理時間、Risk拒否、リプレイ拒否を記録する。ML・LLM状態とTelemetry event typeはEMFの非dimension属性としてLogs Insightsから集計する。監視出力の例外は握りつぶし、取引判断やTelemetry応答を変更しない。

CDKは標準Lambda error・p99 duration、Telemetry error、Decision/Telemetryの捕捉済み内部エラー、API Gateway 5xx、Lambda throttle、リプレイ拒否の8アラームを作る。欠損データは正常とは断定せず、低頻度システムで不要な通知を出さないため `notBreaching` とする。すべてのアラームは環境別SNS Topicへ接続し、`alarm_email` contextがある場合だけメール購読を作る。

CloudWatch Dashboardは継続的な固定費を避けるため既定無効とし、`-c enable_dashboard=true` の環境だけ作成する。Decision結果、p99 latency、AWSサービスhealth、ML・LLM状態、Telemetryイベント状態を表示する。`metrics_enabled=false` でEMFを停止でき、`log_level` はDEBUG、INFO、WARNING、ERROR、CRITICALから選ぶ。ログ保持はdev 14日、staging 30日、production 90日を維持する。

## 2026-09-26の運用基盤改善

- **Heartbeat**: `POST /v1/heartbeats` と専用Lambda `ea-trading-system-<env>-heartbeats`（ARM64/Python 3.12、128 MiB、3秒）を追加した。IAMはDynamoDB書込みと `/ea-trading-system/<env>/credentials/*` の `ssm:GetParameter` だけを持つ。EMFはdimension `Environment`、`Service` に加え、CDK context `heartbeat_ea_ids`（既定 `trend-ea-v1`、最大10件）で明示したEAだけ `EaId` dimensionを付与し、高カーディナリティ化を防ぐ。
- **Heartbeat欠損Alarm**: `ea-trading-system-<env>-heartbeat-missing-<ea_id>`。1分周期Sum < 1、`heartbeat_stale_minutes`（既定5、2〜60）連続、欠損データはBREACHING。ALARMとOKをSNSへ通知する。devは既定無効（`-c heartbeat_alarm_enabled=true` で有効化）、staging/productionは常に有効で無効化するとsynthが失敗する。
- **Heartbeat Lambda error・内部エラーAlarm** を追加し、Lambda throttleとリプレイ拒否の合算式へHeartbeatを加えた。常設Alarmは13個（Heartbeat欠損AlarmはEA数分追加）。
- **通知先検証**: staging/productionは `alarm_email` 未指定または形式不正でsynthを失敗させる。devで未指定の場合はCDK warning（`EaTradingSystem:AlarmEmailMissing`）を出し、Output `AlarmEmailSubscriptionConfigured=false` を記録する。通知先アドレス自体はOutputへ出さない。
- **タイムアウト予算**: Decision Lambdaへ `DECISION_DEADLINE_SECONDS=4.0`、`LLM_DEADLINE_RESERVE_SECONDS=0.5` を追加した。LLM timeout 3.0秒 + 予備 ≤ deadline < EA timeout 4.5秒 < API Gateway integration 5秒 ≤ Lambda 5秒をsynth時に検証する。p99 Duration Alarmの閾値はdeadline（4000 ms）と一致させる。
- **Secretキャッシュ**: Decision・Telemetry・Heartbeat Lambdaへ `SECRET_CACHE_TTL_SECONDS`（CDK context `secret_cache_ttl_seconds`、既定300、0〜3600）を設定する。

いずれもCDK synth・assertionテストまで確認済みで、AWSへのdeploy・Alarm発報・SNS到達は未検証である。Heartbeat追加による費用は、60秒間隔・1 EAでLambda約43,000回/月、DynamoDB書込み約86,000回/月、カスタムメトリクスとAlarm数個の規模であり、常時稼働リソースは追加しない（実請求は未確認）。

## 段階的deploy手順

AWS CLI、Node.js、AWS CDK v2 CLI、Python 3.12を用意し、対象profileのaccount IDとregionを確認する。初回だけ対象account・regionへCDK bootstrapを行う。bootstrapとdeployはAWSへ変更を加えるため、release gateには含めない。

```powershell
aws sts get-caller-identity
aws configure get region
cd infra
cdk bootstrap aws://<AWS_ACCOUNT_ID>/<AWS_REGION>
cdk synth -c environment=dev
cdk diff -c environment=dev
cdk deploy -c environment=dev -c alarm_email=<通知先>
```

初回dev deployはchecksum、LLM provider/modelを設定しないフェイルセーフVETO状態とする。CloudFormation出力のbucket、Decision URL、Telemetry URL、Heartbeat URL、table、SNS Topic、`AlarmEmailSubscriptionConfigured`、`HeartbeatAlarmEnabled`を記録する。staging・productionは `-c alarm_email=<通知先>` を指定しないとsynth・deployが失敗する。共有鍵とLLM APIキーは環境別SSM SecureStringへ安全な手段で登録し、shell history、CDK context、CloudFormation parameter、Gitへ秘密値を残さない。

実データで検証済みのmodel artifactを生成した後、生成済みS3 bucketのversioned keyへアップロードし、実byte列のSHA-256を確認する。次にmodel key・checksum、固定LLM provider/model、通知設定を付けてdevを再deployする。

```powershell
cdk diff `
  -c environment=dev `
  -c ml_model_key=models/USDJPY/H1/<version>/model.json `
  -c ml_model_sha256=<64桁SHA256> `
  -c llm_provider=openai `
  -c llm_model=<固定モデルID>
```

`cdk diff`でIAM、削除・置換、DynamoDB、S3、ログ保持、アラームをレビューしてからdeployする。dev、staging・demo、productionの順を崩さず、productionは別AWS accountを推奨する。production table・bucketをdestroyしない。

rollbackは直前に検証済みのmodel key、checksum、LLM model、prompt versionへ戻して`cdk diff`後に再deployする。CloudFormationが失敗した場合はstack eventを確認し、データresourceを削除して作り直さない。外部障害中はEAがVETOするため、復旧を急いで安全閾値を緩和しない。
