# Phase 8 実装記録

## 実装前

### 実装目的

ML閾値を通過した取引候補だけをLLMへ送り、方向を変更させず `ALLOW / VETO` の異常環境フィルターとして利用する。LLMの不正応答、拒否、タイムアウト、認証・通信障害はすべて新規注文拒否へ倒す。

### 変更ファイル

- `services/decision_api/src/decision_api/llm.py`: LLMインターフェース、OpenAI Responses APIアダプター、厳格JSON検証
- `services/decision_api/src/decision_api/service.py`: ML通過時だけのLLM呼出しと最終外部判断
- `services/decision_api/src/decision_api/handler.py`: provider factory、SSM APIキー取得
- `services/decision_api/src/decision_api/repository.py`: LLM監査項目保存
- `infra/`: provider、model、prompt、timeout、temperature、IAM設定
- `mt5/`: 外部API timeout budget調整
- `services/decision_api/tests/`、`infra/tests/`: 正常・異常・短絡・監査テスト
- `tools/test-phase8.ps1`: Phase 8一括検証

### 設計判断

- アプリケーション層は `LlmDecisionProvider` にだけ依存し、OpenAI固有HTTP形式をアダプターへ閉じ込める。Anthropic等は別アダプターとして追加できる。
- OpenAIはResponses APIの `text.format` JSON Schemaとstrict指定を使う。SDK依存を追加せず、標準ライブラリHTTP境界をモック可能にする。
- provider/modelは明示設定が必要で、既定は無効とする。未設定で外部APIを呼ばない。
- temperatureは初期0、最大出力160 tokens、provider timeoutは3秒とする。temperature非対応モデルでは設定を空にして送信を省略できる。
- 入力は固定方向、集約市場特徴量、RR、距離率、ML出力だけとし、口座番号、生ログ、APIキー、生のSL/TP価格を送らない。
- LLMには外部ニュースを知っていると仮定させない。提供データに見える不整合・異常・不確実性だけを評価させる。
- 信頼度は監査専用で、ロット、レバレッジ、Risk Managerの閾値変更に使用しない。

### 想定リスク

- LLMは実時間ニュースや経済指標カレンダーへ接続していないため、未知のニュースを検知できない。将来は構造化カレンダー情報を別の決定論的サービスから入力する。
- モデル更新で出力傾向や対応パラメーターが変わり得る。modelとprompt versionを固定し、更新ごとに回帰評価する。
- provider APIキー漏えい、費用増、流量制限があり得る。SSM SecureString、ML前段、短い出力、低スロットリング、予算通知を使う。
- LLM ALLOWは発注権限ではない。EA応答検証とRisk Managerが最終拒否できる。
- 外部呼出しによりEA応答が遅くなる。EA 4.5秒、LLM 3秒、Lambda/API 5秒のtimeout budgetを設定する。

## 実装後

### 実装内容

- `LlmDecisionProvider.decide(request, ml)` と `LlmDecision` を実装した。
- OpenAI Responses APIへstrict JSON Schemaで `decision`、`confidence`、`reason` の3項目だけを要求する。
- BUY/SELL返却、未知・欠落・重複フィールド、Markdown囲み、NaN/Infinity、bool confidence、空・過長・制御文字reasonを拒否する。
- provider responseはcompleted、message、単一output_textだけを受理し、refusal、incomplete、複数出力、不正JSONを拒否する。
- ML REJECTED/ERROR時はLLM呼出しゼロ、LLM VETO時は最終VETO、LLM ALLOW時だけ外部判断ALLOWとする。
- timeout・provider error・不正応答は `VETO / LLM_INFERENCE_ERROR` とする。
- model、provider、prompt version、要求・応答時刻、decision、confidence、reasonをDynamoDB監査項目へ保存する。APIキー、生prompt、生provider response、思考過程は保存しない。
- OpenAI APIキーは `/ea-trading-system/<environment>/providers/openai/api-key` のSSM SecureStringから実行時取得する。
- EAのDecision API timeout初期値を2.5秒から4.5秒へ変更した。既存ポジション管理は外部API非依存のままである。

### テスト結果

- Python 3.12 / pytest: 44件成功。
- 対象: ML短絡、LLM ALLOW/VETO、timeout、不正decision、不正confidence、重複・欠落・追加JSON、Markdown、refusal、不正provider response、最小入力、temperature、監査保存、Lambda統合ALLOW、CDK回帰。
- CDK synth: 成功。
- OpenAI実API呼出し、APIキー登録、AWS deployは未実施。

### 残課題

- dev環境で専用APIキー、固定model、prompt versionを設定し、低額上限で疎通・遅延・費用を検証する。
- 過去候補を使ったLLM回帰評価セットを作り、VETO率、再現性、偽陽性を測定する。
- provider/modelごとにtemperature対応と構造化出力対応を確認する。
- Phase 9で候補、ML、LLM、注文、決済を同じ追跡IDで照会できる監査モデルへ拡張する。
- Phase 11でLLM呼出し数、VETO数、error、latency、概算利用量、予算通知を追加する。

