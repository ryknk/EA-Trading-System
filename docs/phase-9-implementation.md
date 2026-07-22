# Phase 9 実装記録

## 実装目的

Strategy候補からML・LLM判断、Risk Manager、注文、約定、ポジション、決済までを1つの `trade_candidate_id` で追跡可能にする。ローカル監査を正本として先に記録し、AWS保存障害が取引管理へ波及しない構造でDynamoDBへ監査データを保存する。

## 変更ファイル

- `mt5/Include/Logging/TradeLogger.mqh`: 厳格な相関ID・イベント型検査、日別JSONL追記
- `mt5/Include/External/TelemetryApiClient.mqh`: 取引イベントAPI向けHMAC署名・ベストエフォート送信
- `mt5/Include/Core/EAController.mqh`: 候補、判断、Risk、注文、約定、決済、スナップショット、エラーの監査生成
- `mt5/Include/External/DecisionApiClient.mqh`: 判断要求へ候補IDとStrategy根拠を追加
- `mt5/Include/Core/Config.mqh`、`mt5/Experts/CoreEA.mq5`: 監査ファイル・Telemetry設定
- `contracts/trade-event-*.schema.json`: イベント要求・応答契約
- `services/decision_api/src/decision_api/telemetry_handler.py`: 認証、入力検証、冪等保存
- `services/decision_api/src/decision_api/event_validation.py`: イベント型別の厳格検証
- `services/decision_api/src/decision_api/repository.py`: 永続判断監査、イベント保存、候補GSI
- `infra/ea_trading_system_stack.py`: Telemetry Lambda、API経路、GSI、ログ、アラーム
- `services/decision_api/tests/`、`infra/tests/`、`mt5/Tests/TestAuditRules.mq5`: 正常・異常・回帰テスト
- `tools/test-phase9.ps1`: Phase 9一括検証

## 設計判断

- Risk Managerの最終権限は変更しない。Telemetryは判断経路から分離し、失敗しても取引状態を変更しない。
- EAは端末ログと日別JSONLへ先に記録する。AWS送信は既定無効で、明示的に有効化した場合だけ行う。
- 判断API自体が候補、Strategy、ML、LLMの監査を保存するため、EAからの `CANDIDATE` と `EXTERNAL_DECISION` はローカル記録に留め、重複通信を抑える。
- Risk以降の事実、約定、決済、日次口座・ポジションスナップショットはTelemetry APIへ送信できる。
- DynamoDBは単一テーブル・オンデマンド課金とし、`candidate-index` の疎GSIで候補時系列を取得する。
- nonceだけをTTL削除対象にし、判断と取引イベントは監査記録として永続化する。
- event IDの同一本文再送は冪等成功、異なる本文は競合として拒否する。
- source IDは環境、key ID、EA IDのhashから生成し、MT5口座番号をAWSへ送らない。

## 想定リスクと対策

- イベント欠損: ローカルJSONLを先行記録し、送信失敗を `trading_impact=none` で明示する。自動再送は残課題。
- 到着順の逆転: event timestampとevent IDを保存し、候補GSIでは時刻順に照会する。状態の上書き更新は行わない。
- 重複: event ID、本文hash、DynamoDB条件付き書込みで冪等化する。
- パーティション集中: source IDで書込みを分離する。個人利用規模で問題が観測された場合だけシャーディングする。
- 機密漏えい: 共有鍵、署名、口座番号、生prompt・生provider responseを保存しない。
- コスト増: 全tick送信を禁止し、候補・取引事実・日次スナップショットだけを送る。Lambda 128 MiB、3秒、DynamoDBオンデマンドを使う。

## 実装内容

- 9種類の監査イベントを固定payloadスキーマで実装した。
- `trade_candidate_id` を判断要求とDynamoDB判断監査へ伝播し、Strategyのpattern、reason code、reasonを保存する。
- ML勝率・期待return・モデル版、LLM provider・model・prompt version・判断・confidence・reason・時刻を候補監査へ保存する。
- Risk結果、ロット、リスク予算、推定損失、必要証拠金、日次損失率、DD率を記録する。
- 注文ticket、deal ticket、retcode、要求・確認価格、数量、スリッページを記録する。
- `OnTradeTransaction` から約定と決済集計を記録し、日次に口座と管理対象ポジションのスナップショットを作る。
- `/v1/trade-events` を判断Lambdaと分離し、同じ共有鍵でも署名パスを分離した。
- CDKへ候補GSI、Telemetry専用ロググループ、Lambdaエラーアラーム、API URL出力を追加した。

## テスト結果

- MetaEditor実コンパイル: CoreEAとテスト6本、合計7対象が0 errors / 0 warnings。
- MT5端末スクリプト: Strategy、PositionSizer、RiskGuards、TradingRules、DecisionApiRules、AuditRulesの6スイートが成功。
- Python/Lambda/CDK: 全9イベント型を含む51テストが成功。
- CDK synth: 成功。
- 実AWS deploy、DynamoDB実書込み、MQL5 VPSからのHTTPS疎通は未実施。

## 残課題

- Phase 10でバックテスト・フォワード結果を監査イベントと結合し、指標とレポートを生成する。
- ローカルJSONLからの署名付き再送ツール、送信済みチェックポイント、欠損検出は未実装。
- 複数端末・複数口座向けsource ID設計とGSI負荷は実運用量を観測して見直す。
- 管理画面向け日付・Strategy・symbol集計索引はアクセスパターン確定後に追加する。
- 実AWS環境ではログ保持、アラーム通知先、AWS Budgets、PITR、権限境界をdeploy前レビューする。
