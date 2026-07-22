# LLM設計

## Shadow Mode

`LLM_SHADOW_MODE=true`では、ML通過後にLLMを呼び出し、ALLOW/VETO、provider、model、prompt version、confidence、reason、時刻を監査保存する。有効なVETOは最終注文判断へ適用せず、応答理由を `LLM_SHADOW_VETO_RECORDED` とする。一方、timeout、HTTP error、不正JSON、decision欠落、UNKNOWN、BUY/SELL、confidence範囲外は判断不能であり、Shadow ModeでもフェイルセーフVETOとする。

Shadowログは `python.analysis.shadow_evaluation.compare_llm_shadow` で、A（LLM未適用）とB（VETO除外）を比較できる。ただし反実仮想比較だけで因果効果は証明できない。十分な件数、異なる相場局面、コスト込み指標で効果を確認できるまで、productionでLLM VETOを適用しない。

LLMは方向を決めず、ML通過済み候補に対する異常環境フィルターとして `ALLOW` または `VETO` のみ返す。入力は方向、集約特徴量、ML出力、リスクリワード比、データ時刻などの構造化情報に限定し、口座番号、秘密情報、生ログを含めない。

アプリケーション層に `ILlmDecisionProvider.decide(request) -> LlmDecision` を置き、OpenAIやAnthropic等のアダプターを分離する。プロバイダーとモデル名は設定値、プロンプトはバージョン付き、temperatureは対応範囲で最小とし、JSON Schemaによる構造化出力を使う。

許容スキーマは `decision`、`confidence`、`reason` のみを基本とし、判断値不正、項目欠落、過長な理由、タイムアウト、流量制限、プロバイダーエラー、解析エラーはVETOとする。信頼度は発注権限やロット増加に利用しない。要求・応答時刻、モデル、プロンプトのバージョン、判断、信頼度、理由、エラーコードを監査保存する。生の思考過程は要求・保存しない。

## Phase 8実装

`LlmDecisionProvider` をアプリケーション境界とし、初期アダプターにOpenAI Responses APIを実装した。構造化出力は `text.format` のstrict JSON Schemaを使う。公式仕様は [OpenAI Structured Outputs](https://developers.openai.com/api/docs/guides/structured-outputs) と [Responses API Create](https://developers.openai.com/api/reference/resources/responses/methods/create) を参照する。

providerとmodelの既定値は空であり、明示設定されない限り外部通信しない。modelは可用性・レイテンシ・費用・構造化出力の回帰評価後に固定する。自動的に最新modelへ追従しない。prompt version初期値は `trade-filter-v1`、temperature初期値は0、最大出力160、timeoutは3秒とする。temperature非対応modelでは設定を空にして送信を省略する。

入力は固定済み方向、symbol、timeframe、観測時刻、spread、RSI、ATR比率、EMA乖離、return、volatility、時刻・曜日、RR、SL/TP距離率、ML勝率・期待return・model versionだけである。口座情報、生ログ、生の注文価格、秘密情報を含めない。

LLMはニュースや外部事実へ接続していない。提供されていないニュースを知っていると仮定させず、構造値の不整合・異常・不確実性だけを判定させる。経済指標カレンダーが必要な場合は、将来、決定論的な構造データとして別途供給する。

ML REJECTED/ERRORではLLMを呼ばない。LLMのrefusal、incomplete、複数出力、Markdown、不正JSON、未知値、timeout、API errorは `LLM_INFERENCE_ERROR` としてVETOする。LLM ALLOWは外部フィルター通過を意味するだけで、Risk Managerの最終権限を変更しない。
