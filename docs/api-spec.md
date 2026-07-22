# 取引判断API v1

`POST /v1/trade-decisions`、`Content-Type: application/json` とする。要求・応答の機械可読定義は `contracts/` のJSON Schemaを正とする。

ヘッダーは `X-EA-Key-Id`、`X-EA-Timestamp`、`X-EA-Nonce`、`X-EA-Signature`、`Idempotency-Key` とする。本文の `request_id` と `Idempotency-Key` は一致させる。

署名はHMAC-SHA256の小文字16進数とする。正規化文字列は次の5行を改行文字 `\n` で連結する。

```text
POST
/v1/trade-decisions
<Unix UTC timestamp>
<nonce>
<lowercase SHA-256 hex of UTF-8 body>
```

初期構成ではAPI Gateway HTTP APIの既定ステージを使い、署名対象パスと実URLの末尾を `/v1/trade-decisions` に一致させる。nonceとrequest IDは要求ごとに生成し、APIキーIDには英数字、ピリオド、アンダースコア、ハイフンだけを許可する。

成功時も取引判断としては `ALLOW` / `VETO` のみを返す。HTTPタイムアウト、5xx、429、スキーマ不一致はEA側でVETO相当とする。4xxは再送せず、設定・入力エラーとして記録する。`expires_at` は短時間（初期30秒）とし、EAはサーバー時刻との差を考慮しつつ期限切れを拒否する。

APIは要求の冪等性を保証するが、市場状態が変わった後の再利用は保証しない。EAは同一候補のALLOWを再発注に使用しない。

EAはレスポンスの追加フィールド、重複フィールド、不正な型、制御文字、未知のdecision、request ID不一致、時刻ずれ、期限切れ、過長TTLを拒否する。ALLOWにはMLの`PASSED`と設定閾値、LLMの`ALLOW`が必須である。

Phase 6のサーバーは、JSONの重複キー、非有限数、未知・欠落フィールド、不正なUUID、BUY/SELLに矛盾するSL/TP位置、16 KiB超の本文を400で拒否する。署名不正・時刻切れは401、nonce再利用と冪等性競合は409、依存先障害は500とする。これらはすべてEA側で新規注文拒否となる。

モデル未設定時の認証済み正常応答はHTTP 200で次の状態を返す。これは通信成功を取引許可と誤認しないためのフェイルセーフである。

```json
{
  "schema_version": "1.0",
  "request_id": "要求と同じUUID",
  "decision": "VETO",
  "reason_code": "ML_INFERENCE_ERROR",
  "ml": {"status": "ERROR", "model_version": "not-configured"},
  "llm": {"status": "NOT_CALLED"},
  "created_at": "UTC日時",
  "expires_at": "作成時刻の30秒後"
}
```

Phase 7以降、ML閾値未達は `VETO / ML_THRESHOLD_NOT_MET` とし、`ml.status=REJECTED`、勝率、期待return、モデル版を返す。モデル未設定、S3障害、checksum不一致、スキーマ不一致、非有限出力、scope不一致は `VETO / ML_INFERENCE_ERROR` とし、`ml.status=ERROR`、`llm.status=NOT_CALLED` を返す。

ML通過後のLLM ALLOWは `decision=ALLOW`、`reason_code=APPROVED`、`llm.status=ALLOW` とする。LLM VETOは `VETO / LLM_VETO`、timeout・refusal・不正JSON・provider errorは `VETO / LLM_INFERENCE_ERROR` とする。HTTP 200、MLのPASSED、LLMのALLOW、応答期限、EA設定閾値、Risk Managerのすべてを通過するまで注文は許可しない。

## 取引イベントAPI v1

`POST /v1/trade-events` は取引判断APIと同じ認証ヘッダー、16 KiB上限、厳格UTF-8 JSON、HMAC-SHA256方式を使用する。署名の第2行だけを `/v1/trade-events` とし、`Idempotency-Key` は本文のUUIDv4 `event_id` と一致させる。本文timestampと署名timestampも一致させる。

要求の正本は `contracts/trade-event-request.schema.json`、応答の正本は `contracts/trade-event-response.schema.json` とする。イベント型は `CANDIDATE`、`EXTERNAL_DECISION`、`RISK_DECISION`、`ORDER_SUBMISSION`、`DEAL`、`POSITION_SNAPSHOT`、`TRADE_CLOSED`、`ACCOUNT_SNAPSHOT`、`SYSTEM_ERROR` の9種で、型ごとにpayloadの必須・許可項目を固定する。未知項目、欠落、重複キー、非有限数、制御文字、不正ticket、不正時刻は拒否する。

保存成功はHTTP 200の `ACCEPTED`、同じevent ID・同じ本文hashの再送はHTTP 200の `DUPLICATE` とする。同じevent IDで本文が異なる場合は409、認証不正は401、入力不正は400、保存障害は500である。EA側はこのAPIをベストエフォート監査として扱い、どの応答も発注・決済・リスク削減の可否へ反映しない。
