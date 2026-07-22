# Phase 6 実装記録

## 実装前

### 実装目的

Phase 5のMQL5クライアントが呼び出す `POST /v1/trade-decisions` を、低固定費のAWSサーバーレス構成として実装する。ML・LLM未配備時にも新規注文を許可しない境界を先に完成させる。

### 変更ファイル

- `services/decision_api/src/decision_api/`: Lambdaの検証、認証、永続化、判断サービス、ハンドラー
- `services/decision_api/tests/`: Lambda単体・異常系テスト
- `infra/`: AWS CDK v2スタックとテスト
- `tools/test-phase6.ps1`: Phase 6の一括検証
- `README.md`、`docs/`: セットアップ、セキュリティ、運用手順

### 設計判断

- API GatewayはREST APIより低コストなHTTP APIを採用し、正確な経路を `$default` ステージの `/v1/trade-decisions` とする。
- Lambda本体はPython 3.12標準ライブラリのみで動作させ、配布物を小さくする。
- 署名はPhase 5と同じHMAC-SHA256とし、共有鍵はParameter Store SecureStringから復号取得する。AWSアクセスキーをEAへ保存しない。
- DynamoDBは単一テーブル・オンデマンド課金とし、nonceの一回性とrequest IDの冪等性を条件付き書込みで保証する。
- ML未配備中の正常応答はHTTP 200でも `VETO / ML_NOT_IMPLEMENTED` とし、LLMは呼び出さない。
- `dev`、`staging`、`production` は別スタック、別テーブル、別バケット、別Parameter Store名前空間にする。本番は別AWSアカウントを推奨する。

### 想定リスク

- 共有鍵がMQL5端末から漏えいする可能性は残る。ファイル権限、専用key ID、定期ローテーション、失効手順が必要である。
- API Gateway到達後にLambda認証するため、不正リクエストにも少額の呼出し費用が発生する。低いスロットリング値と予算通知で抑制する。
- DynamoDB障害、Parameter Store障害、LambdaタイムアウトはHTTP 5xxとなる。EAはこれをVETOとして扱う。
- CDK deployはAWSに課金対象リソースを作るため、このPhaseでは実行しない。

## 実装後

### 実装内容

- 16 KiB上限、UTF-8、重複JSONキー、NaN/Infinity、必須・未知フィールド、型・範囲、UUIDv4、時刻、BUY/SELL別SL/TP位置を厳格検証する。
- Phase 5互換の5行正規化文字列でHMAC署名を検証し、定数時間比較を行う。
- 署名時刻の許容差を初期60秒とし、本文時刻と署名ヘッダー時刻も一致させる。
- nonce再利用を拒否し、同じrequest ID・同じ本文は同じ応答を返す。request IDが同じで本文が異なる場合は409で拒否する。
- 認証情報、署名、生の特徴量をログへ出さず、request ID、EA ID、最終判断、理由コードだけを構造化ログに残す。
- DynamoDB TTL、S3暗号化・HTTPS強制・公開遮断、IAM最小権限、APIスロットリング、ログ保持、Lambdaエラー・p99時間アラームをCDK化した。
- devは14日、stagingは30日、productionは90日のログ保持とした。本番データは削除ポリシーRETAIN、DynamoDB PITR有効とした。

### テスト結果

- Python 3.12 / pytest: 21件成功。
- 対象: JSON異常、重複キー、追加・欠落、NaN、売買価格関係、HMAC、時刻切れ、リプレイ、冪等性競合、依存先タイムアウト、フェイルセーフVETO、環境設定、CDKリソース・経路・スロットリング・保持期間。
- CDK synth: 成功。生成CloudFormation 18リソースからLambda、HTTP API、経路、DynamoDB、S3、CloudWatch Alarmを確認した。
- AWS実環境deployおよびMQL5からの疎通試験は未実施。AWSアカウントへ変更を加えないためである。

### 残課題

- Phase 7でバージョン固定したML推論プロバイダー、閾値、モデル成果物読込み、MLエラー時VETOを実装する。
- Phase 8でLLMプロバイダー抽象化、厳格JSON、タイムアウト、エラー時VETOを実装する。
- Phase 9で候補・注文・ポジション・決済・日次スナップショットを同じ追跡IDへ拡張する。
- 初回deploy時にAWS Budgets通知先、CloudWatch Alarm通知先、Parameter Storeの共有鍵を運用者が設定する。
- AWS実環境で署名付き疎通、429、5xx、タイムアウト、鍵ローテーションを確認するまで取引変更を有効化しない。

