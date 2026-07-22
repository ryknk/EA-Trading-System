# Phase 5 実装記録

## 実装前

目的は、ルールベース候補が発生した時だけMQL5から取引判断APIを呼び、検証済み外部ALLOWの後にRisk Managerを再評価すること。変更対象はExternal、Config、Signal、Strategy、Controller、CoreEA、テスト、API・セキュリティ文書である。WebRequest制約、HMAC互換性、JSON解析、時刻ずれ、秘密情報配置、API応答中の価格変化を主要リスクとした。

## 実装内容

- `CryptEncode(CRYPT_HASH_SHA256)`を用いたSHA-256とHMAC-SHA256
- UTF-8本文ハッシュ、正規化5行、nonce、Unix UTC時刻による署名
- 秘密情報をEA入力やソースへ置かず、MQL5ファイルサンドボックスから読み込み
- UUID形式のrequest IDとnonce、冪等性ヘッダー
- 市場特徴量と取引案を契約どおりJSON化
- 同期WebRequestに設定可能な短いタイムアウトを適用
- 追加・重複フィールドも拒否する厳格JSONトークナイザーとレスポンスパーサー
- request ID、schema、decision、ML/LLM状態、閾値、時刻差、期限、TTLを検証
- ログ制御文字とヘッダー注入を拒否
- 処理順を戦略 → 外部判定 → 最新Risk再評価 → 注文へ変更
- API無効・全通信異常・解析異常を新規注文拒否として処理

## テスト・検証結果

- CoreEAと5本のテストスクリプト: MetaEditorでエラー0件、警告0件
- `TestDecisionApiRules.mq5`: SHA-256、HMAC既知ベクトル、JSONエスケープ、UUID、正常ALLOW/VETO、不正JSON、未知フィールド、不正decision、ID不一致、期限切れ、ML閾値、LLM VETO、不正日付、ログ制御文字など18項目が成功
- 全5テストスイート、合計64項目がMT5実行で成功
- 実AWSエンドポイントはPhase 6未実装のため、WebRequest統合試験は未実施

## 残課題

- Phase 6でAPI Gateway、Lambda、認証・リプレイガードの実装と契約試験を行う
- 実エンドポイントをMT5のWebRequest許可URLへ登録し、タイムアウト・429・5xx・不正応答を統合試験する
- MQL5 VPS上で秘密ファイルが移行・読込可能か検証する
- API Gatewayの実パスと署名対象パスを一致させる
- ローカル時刻・ブローカー時刻・UTCのDST境界をデモ環境で検証する
