# 本番準備状況レポート

評価日: 2026-07-21  
対象: CoreEA 1.13 / Phase 13  
判定: **NO-GO**

## 1. エグゼクティブサマリー

既存の責務分離（Strategy、External Decision、Risk、Trading、Logging）とフェイルセーフ方針は維持されている。Risk Managerは外部ALLOW後に最新市場・口座状態で再計算され、1つでもGuard、Margin、OrderCheckが失敗すれば注文しない。既存ポジション監視は候補生成より前に実行される。

Phase 13ではMQL5の実コンパイル、Script実行、Python/Lambda/CDK回帰試験を実施し、安全境界、Strategy単位停止、Tester用Mock、LLM Shadow Mode、ML評価指標、CloudWatch Alarm、再現用バックテスト設定を追加した。自動試験は通過し、Strategy Testerも2025年USDJPY/H1で完走したが、総損益-95,024円・Profit Factor 0.59・最大Drawdown 10%到達という損失結果であった（2026-08-09時点、受入基準未凍結のため合否未判定）。実市場OOS/Walk Forward、AWS dev実通信、LLM実通信、Demo/VPSは依然未検証である。このため実資金運用は **NO-GO** とする。

### 現状リポジトリ監査

- アーキテクチャ: CoreEA/Controllerが確定足Strategyを起点にDecision API、Risk Manager、Order Managerへ進み、Position Managerを候補処理より先に実行する。AWSはHTTP API、Decision/Telemetry Lambda、DynamoDB、S3、CloudWatch/SNSをCDKでdev・staging・production分離する。
- 実装済み: MQL5 Strategy/Risk/Trading/API/監査、HMAC認証・Replay対策、ML線形baselineと校正、LLM構造化VETO、DynamoDB監査、分析指標、IaC、開発release gate。
- 暫定・未実装: 実市場model artifact、定期Heartbeat、MT5レポートimporter、Shadow効果の統計評価、AWS実環境の障害注入、MQL5 VPS運用証跡。
- テスト状況: 純粋ルールと外部境界の自動テストは整備されている。一方、Broker状態を使う日付・position・margin/order統合、real tickバックテスト、実クラウド経路は未検証である。
- 本番リスク: 実データ成績と約定再現性が不明、外部依存障害時の実測がない、無候補時の死活監視がない、運用通知と緊急手順が演習されていない。

## 2. テスト結果

| 区分 | 結果 | 証跡・注記 |
|---|---|---|
| MetaEditor compile | PASS | EA＋7 Script、全て0 errors / 0 warnings |
| MQL5 Script runtime | PASS | 7/7で `TEST_SUITE_PASS` |
| Python/Lambda/CDK unit | PASS | 78 passed |
| CDK synth | PASS | dev stack synth完了 |
| Strategy Tester | LOCALLY TESTED（損益結果は要判断） | 2026-07-21 23:13、USDJPY/H1/2025年、100%リアルティック、Mock ALLOWで完走。総損益-95,024円、PF 0.59、最大DD10%到達（詳細は`results/backtests/20260721-231302-USDJPY-H1/run-metadata.json`） |
| AWS dev integration | NOT VERIFIED | AWS認証・endpointを使用していない |
| LLM provider実通信 | NOT VERIFIED | API key/modelを使用していない |
| Demo/MQL5 VPS | NOT VERIFIED | 未接続 |

`TestDecisionApiRules`は全AssertionとPASSマーカーを出したがTerminal process exit codeは1だった。他の6 Scriptは0。テストランナーはAssertion/PASSマーカーを正としているが、exit code差異は未解消事項として追跡する。

## 3. MQL5ビルド結果

`tools/link-mt5.ps1`でInclude、Experts、Testsの3 Junctionを確認した。`tools/compile-mql5.ps1`をMetaEditor build 6034で実行し、CoreEA、TestTrendFollowingRules、TestPositionSizer、TestRiskGuards、TestTradingRules、TestDecisionApiRules、TestAuditRules、TestProductionSafetyRulesが全て0 errors / 0 warningsだった。build logは `build/metaeditor/` に保存される。

## 4. 単体テスト結果

PositionSizerは残高/Equity相当0、risk 0/負値、SL損失0、極小/極大損失、min未満、max超過、step切捨て、TickSize/TickValue異常を純粋ルールで確認した。Spreadは通常、直前、一致、超過、crossed quote、Bid/Ask/point異常を確認した。Daily LossとDDは0、直前、一致、超過、無効baselineを確認した。Exposureは0、上限未満、一致、超過、同一Symbol拒否を確認した。

DailyLossの日付切替、Broker server time、永続lock、Balance更新、実ポジション列挙、BUY/SELL混在はコードレビュー済みだが、実口座状態を使う統合実行は `NOT VERIFIED` である。Risk統合の「外部ALLOWでもRisk拒否なら発注しない」は既存TestTradingRulesとController順序で確認した。

## 5. Strategy Tester結果

2026-07-21 23:13、USDJPY/H1、2025-01-01〜2025-12-31、Every tick based on real ticks（100%リアルティック）、Mock ALLOW（`InpTesterDecisionMode=1`, `InpTesterFixedMlProbability=0.65`）、`InpEnableTradeMutations=true`（Strategy Tester内のみ、EA既定値は変更せず）で完走した。Broker表示は`XMTrading-MT5`/`Tradexfin Limited`だが、Demo口座かReal口座かは記録がなく **NOT VERIFIED**。

結果: 総損益 -95,024円（総利益135,076円、総損失-230,100円）、Profit Factor 0.59、Sharpe -4.09、最大Drawdown 95,024円（残高比10%、上限到達）、取引数66（ロング6/勝率0%、ショート60/勝率26.67%）、最大連敗9（-43,130円）。手数料合計0円、スワップ合計-10,846円、価格損益合計-84,178円。全132注文が`filled`で、拒否・requoteに該当する注文は現れなかった。証跡は`results/backtests/20260721-231302-USDJPY-H1/`（`.htm`/`.png`/`tester.ini`/`run-metadata.json`）。

一方、以下は本実行でも **NOT VERIFIED** のまま。
- Terminal/EAログ（Journal/Expertsタブ）が保存されておらず、Spread/Margin/OrderCheckの拒否動作は未検証（本実行では拒否が1件も発生していない）
- 事前固定された受入基準がなく、上記結果の合否は未判定
- Demo/Real口座の区別
- Git Commit SHA（実行時刻がリポジトリ最初のコミットより前のため対応するSHAが存在しない）

2026-08-10、上記の期間制約の原因を確定した。Broker（XMTrading-MT5/Tradexfin Limited）はUSDJPYのreal tickデータを2022年1月分以降しか保持しておらず、2020-2021を指定すると「ヒストリー品質0%リアルティック」（OHLCからの合成tick）に自動的に切り替わることを確認した（`results/backtests/20260810-144215-USDJPY-H1/`、この結果はNOT VERIFIED扱いで損益評価に使用しない）。この制約を受け、**ブローカーをOANDA証券MT5（東京サーバー）へ切り替え、2015年以降のreal tickデータで検証をやり直す方針を決定した。** OANDA証券デモ口座開設完了後にStrategy Testerを再実行し、以後はOANDA側データを正式なIn-Sample/Out-of-Sample/Walk Forward系列とする。上記のXMTrading-MT5実行結果（総損益-95,024円等）は参考記録として保持するが、production release gateの証跡としては使用しない。

## 6. Out-of-Sample結果

実市場データとproduction候補モデルがないため **NOT VERIFIED**。2015〜2022をIn-Sample、2023〜2025をOOSとする案は、実データの取得期間とラベルhorizonを確認後に凍結する。OOSを閾値調整へ再利用してはならない。

## 7. Walk Forward結果

TimeSeriesSplitとgapの実装・合成データ試験はPASSした。実市場データによるローリング期間比較と取引指標は **NOT VERIFIED**。

## 8. ML検証

特徴量生成、時系列順序、train/calibration/OOS間gap、train期間だけのScaler fit、校正期間分離をレビューした。合成OOS値を変更してもtraining scalerが変化しないテストがある。ROC-AUC、Brier Score、Log Loss、Precision、Recall、F1、return MAEと、0.50/0.55/0.60/0.65/0.70のTrade Count、return合計、Profit Factor、DD、Expectancy比較を出力する。

Probability calibrationは独立calibration期間のPlatt Scalingである。実市場でのcalibration curve、期間別安定性、コスト込み収益性は **NOT VERIFIED**。モデル複雑化は行っていない。

## 9. LLM Shadow評価

AWS側に `LLM_SHADOW_MODE` を追加し、既定trueとした。有効なVETOは `llm.status=VETO` と監査情報を保存しつつ最終ALLOWへ非適用とする。Timeout、不正JSON、UNKNOWN、BUY/SELL、欠落、confidence範囲外などのエラーはShadow中でもVETOを維持する。

PythonにA（LLM未適用）とB（記録済みVETO除外）を同一定義で比較する関数を追加した。Shadow実績ログがないため効果は **NOT VERIFIED**。有効性が実務的・統計的に確認できるまでproductionでVETO適用を推奨しない。

## 10. AWS統合結果

API Gateway→Lambda→ML→LLM→DynamoDBの単体・メモリrepository試験はPASSした。API認証、timestamp、nonce、idempotency、期限、ML/LLM失敗、Telemetry validationはテスト対象である。AWS devへdeployしていないため、実サービス横断フローは **NOT VERIFIED**。

## 11. 異常系テスト結果

単体テストでは4xx相当validation/auth、重複request、ML error、LLM error/timeout/invalid、repository conditional conflict、不正入力を安全側へ処理する。MQL5はHTTP非200、WebRequest失敗、空/過大response、不正JSON、request_id mismatch、期限切れをVETOにする。API待ち時間は既定4500msで、失敗後も次Tickで既存ポジション監視を先に実行する。

Lambda実timeout、API Gateway実5xx、DynamoDB実障害、429、ネットワーク遮断のdev障害注入は **NOT VERIFIED**。

## 12. セキュリティレビュー

作業ツリーをAWS Access Key、Secret Key、OpenAI形式key、Slack token、private key、Broker passwordの代表patternで走査し一致なし。履歴情報を持つ通常のGit repositoryではないため、Git履歴全体のsecret scanは **NOT VERIFIED**。`.gitignore`へ`.set`、decision secret、API key text、生成バックテストdirectoryを追加した。

EAは長期AWS鍵を持たず、失効可能なkey IDとHMAC共有鍵ファイルを使う。server側secretはSSM SecureStringを使用する。HTTPS、timestamp、nonce、request_id/idempotency、response TTL検証がある。実際の鍵ローテーションと侵害対応訓練は未実施。

## 13. 残存リスク

1. Strategy Testerは2025年分（XMTrading-MT5）について完走したが総損益-95,024円・PF 0.59の損失結果であり、受入基準未凍結のため合否未判定。XMTrading-MT5はreal tickを2022年1月分以降しか保持していないため、OANDA証券MT5へ切り替えて再検証する方針を2026-08-10に決定した（切替未完了）。OOS、Walk Forward、Demoも未完了で、戦略とRiskの実データ挙動が不明。
2. AWS dev実通信と障害注入、Alarm通知到達が未検証。
3. 独立した定期EA Heartbeatが未実装で、無候補時間帯の死活判定が弱い。
4. Kill Switchはコード・純粋ルールのみで、保有position中のSL/TP/安全決済継続を端末で実証していない。
5. LLM Shadowの効果ログがなく、LLMを本番判断へ適用する根拠がない。
6. `TestDecisionApiRules`のTerminal exit code 1を調査する必要がある。
7. production用model checksum、endpoint、通知、Budget、rollback drill、VPS secret配布が未確定。

## 14. 本番移行判定

**NO-GO**。現時点で許可できるのは、ローカル開発とAWS dev/stagingでの非取引検証、および `InpEnableTradeMutations=false` のDemo観測準備までである。実注文を伴うDemo開始前にもStrategy Tester完了が必要であり、小額実口座・productionはOOS、Walk Forward、Demo、AWS障害試験、Kill Switch実証、運用通知確認が揃うまで禁止する。
