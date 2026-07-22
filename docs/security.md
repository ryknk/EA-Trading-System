# セキュリティ

通信はHTTPSのみとする。MQL5にAWSアクセスキーやLLMキーを埋め込まない。初期認証はランダムなEA認証情報によるHMAC-SHA256署名を推奨し、認証情報はMT5入力値ではなく端末側の保護ファイル等から読み込む方式を検証する。ただしMQL5 VPS上の完全な秘密情報保護は保証できないため、漏えいを前提に低権限・失効可能・環境別・EA別とする。

署名対象は `method + path + timestamp + nonce + SHA256(body)` の正規形式とする。APIは許容時刻差（初期60秒）、nonce・request_idの条件付き書き込み、時刻、本文ハッシュ、定数時間比較を検証する。同一IDで本文ハッシュが異なる要求は拒否する。認証情報のIDだけをヘッダーに載せ、秘密情報はSSM SecureStringに保存する。

API Gatewayの流量制限、Lambdaの予約済み同時実行数、要求本文サイズ制限、JSON Schema、文字列長・数値範囲検査を行う。ログから署名、秘密情報、口座識別子を削除する。DynamoDB、S3、CloudWatchはAWS管理鍵による暗号化を初期値とし、IAMはリソース単位の最小権限とする。

IP許可リストはMQL5 VPSの送信IP安定性に依存するため補助策とし、認証の代替にしない。APIキー単独は利用量の識別には使えても秘密漏えい・リプレイ攻撃対策が弱いため、HMACとnonceを優先する。

## MQL5認証情報

Phase 5ではキーIDだけをEA入力値とし、HMAC秘密情報は `MQL5\Files\EaTradingSystem\decision-api-secret.txt` からUTF-8で読み込む。絶対パス、親ディレクトリ参照、短すぎる秘密情報を拒否する。秘密情報や署名はログへ出力しない。ファイルはソース管理およびジャンクション対象に含めない。

MQL5のファイル操作はターミナルのファイルサンドボックス内に制限される。MQL5 VPSの公式移行手順ではWebRequest許可URLとEA入力値の移行は説明されているが、任意の秘密ファイル移行は明示保証されていない。そのため、本番VPS移行前に秘密ファイルの利用可否を実機で確認する。確認できない場合は、失効可能な短期トークンの安全な配布方式をPhase 6以降で追加し、長期AWS認証情報をEAへ置く設計には変更しない。

## Phase 6のサーバー認証

共有鍵は `/ea-trading-system/<environment>/credentials/<key-id>` のParameter Store SecureStringへ保存する。Lambdaはkey IDを許可文字へ限定してから参照し、IAM復号権限も環境別prefixだけに限定する。AWSアクセスキーやLLMキーをEAへ渡さない。

署名は定数時間比較し、初期60秒の時刻差、UUIDv4 nonceのDynamoDB条件付き書込み、本文timestampと署名ヘッダー時刻の一致を検証する。request IDの再利用時は本文hashが一致する場合だけ保存済み応答を返す。署名、共有鍵、生の市場特徴量をCloudWatch Logsへ出力しない。

鍵ローテーション時は新しいkey IDと共有鍵を追加し、EAを更新・同期して正常性を確認してから旧Parameterを削除する。漏えい時は該当Parameterを直ちに無効化し、EAの新規注文を停止する。

## LLM APIキーと送信データ

OpenAI APIキーは `/ea-trading-system/<environment>/providers/openai/api-key` のSSM SecureStringへ保存し、CDK context、Lambda環境変数、ソース、ログへ入れない。用途別・環境別の専用キーを使用し、provider側の利用上限も設定する。漏えい時はprovider側で失効し、新しいキーへローテーションする。

LLMへは口座番号、balance、equity、保有量、API認証情報、生ログ、生のSL/TP価格を送らない。固定方向と集約比率・指標だけを送る。providerへのrequest/response本文や思考過程は保存せず、model、prompt version、時刻、ALLOW/VETO、confidence、短いreasonだけを監査保存する。

Phase 11のCloudWatchメトリクスdimensionは環境名と固定Service名だけにする。key ID、request ID、event ID、候補ID、口座番号、symbol、LLM reasonをdimensionへ含めない。リプレイ拒否は件数だけをメトリクス化し、認証ヘッダー、nonce、署名、共有鍵をログへ出力しない。SNS通知本文にも秘密情報を含めない。
