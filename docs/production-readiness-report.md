# 本番準備状況レポート

評価日: 2026-07-21  
対象: CoreEA 1.13 / Phase 13  
判定: **NO-GO**

## 1. エグゼクティブサマリー

既存の責務分離（Strategy、External Decision、Risk、Trading、Logging）とフェイルセーフ方針は維持されている。Risk Managerは外部ALLOW後に最新市場・口座状態で再計算され、1つでもGuard、Margin、OrderCheckが失敗すれば注文しない。既存ポジション監視は候補生成より前に実行される。

Phase 13ではMQL5の実コンパイル、Script実行、Python/Lambda/CDK回帰試験を実施し、安全境界、Strategy単位停止、Tester用Mock、LLM Shadow Mode、ML評価指標、CloudWatch Alarm、再現用バックテスト設定を追加した。自動試験は通過したが、Strategy TesterはBroker口座未指定で開始できず、実市場OOS/Walk Forward、AWS dev実通信、LLM実通信、Demo/VPSが未検証である。このため実資金運用は **NO-GO** とする。

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
| Strategy Tester | NOT VERIFIED | `tester not started because the account is not specified` |
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

USDJPY/H1、2020-01-01〜2025-12-31、Every tick based on real ticks、Mock ALLOWの設定を作成してCLI起動した。Terminalは口座未指定を理由にTesterを開始せず、レポートも生成しなかった。したがってEntry、Exit、SL、TP、lot、Spread、最大position、注文拒否の履歴検証および全損益指標は **NOT VERIFIED** である。

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

1. Strategy Tester、OOS、Walk Forward、Demoが未完了で、戦略とRiskの実データ挙動が不明。
2. AWS dev実通信と障害注入、Alarm通知到達が未検証。
3. 独立した定期EA Heartbeatが未実装で、無候補時間帯の死活判定が弱い。
4. Kill Switchはコード・純粋ルールのみで、保有position中のSL/TP/安全決済継続を端末で実証していない。
5. LLM Shadowの効果ログがなく、LLMを本番判断へ適用する根拠がない。
6. `TestDecisionApiRules`のTerminal exit code 1を調査する必要がある。
7. production用model checksum、endpoint、通知、Budget、rollback drill、VPS secret配布が未確定。

## 14. 本番移行判定

**NO-GO**。現時点で許可できるのは、ローカル開発とAWS dev/stagingでの非取引検証、および `InpEnableTradeMutations=false` のDemo観測準備までである。実注文を伴うDemo開始前にもStrategy Tester完了が必要であり、小額実口座・productionはOOS、Walk Forward、Demo、AWS障害試験、Kill Switch実証、運用通知確認が揃うまで禁止する。
