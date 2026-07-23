# 1. 目的

このファイルは、今後実施する開発・検証・運用準備タスクを管理する。

現在の本番移行判定は **NO-GO** である。

完了状態は、次の記号で管理する。

```text
[ ] 未着手
[-] 作業中
[x] 完了
[!] Blocked
```

タスクを完了扱いにする場合は、可能な限りテスト結果、ログ、レポート、スクリーンショット、Git Commit SHAなどの証跡を残す。

---

# 2. 最優先タスク

## 2.1 Strategy Tester

`results/backtests/20260721-231302-USDJPY-H1/`に、実行済みレポート（`ets-20260721-231302-USDJPY-H1.htm`/`.png`）が存在することを2026-07-23の調査で確認した。USDJPY/H1、2025.01.01-2025.12.31、100% real ticks、Mock ALLOW（`InpTesterDecisionMode=1`, `InpTesterFixedMlProbability=0.65`）、`InpEnableTradeMutations=true`（Strategy Tester内のみ）で完走している。結果は総損益 **-95,024円**、Profit Factor **0.59**、最大Drawdown **10%（口座上限到達）**、取引数66、ロング勝率0%/ショート勝率26.67%、最大連敗9。ただしHANDOFF.md、`docs/production-readiness-report.md`、`docs/production-readiness-checklist.md`はこの結果を反映しておらず「口座未指定で未開始」のまま更新が必要（未実施）。同ディレクトリ以前の3回の試行（`20260721-220506`,`20260721-230456`,`20260721-231041`）は`tester.ini`のみでレポートが生成されておらず失敗している。

* [x] Demo Broker口座へログインする（実行成功の前提として達成。ただしDemo口座かReal口座かは未確認 — Broker表示は`XMTrading-MT5`/`Tradexfin Limited`）
* [x] Broker上のUSDJPYの実Symbol名を確認する（`USDJPY`表記で実行できている）
* [x] USDJPYのreal tick履歴を取得する（2025年分のみ。2020-2025期間では3回とも開始できず、原因未確認）
* [x] `mt5/test-config/StrategyTester-USDJPY-H1.ini` を確認する
* [x] `.\tools\run-strategy-tester.ps1 -TimeoutSeconds 900` を実行する（2026-07-21 23:13に完了）
* [x] Strategy Testerレポートが生成されることを確認する（`.htm`/`.png`が存在）
* [ ] TerminalログとEAログを保存する（保存有無・保存先は未確認）
* [ ] Entry、Exit、SL、TP、Lot計算を確認する（レポート内の個別取引データはまだ精査していない）
* [ ] Spread、Margin、OrderCheckの拒否動作を確認する
* [ ] 実行条件とGit Commit SHAをMetadataへ記録する（`run-metadata.template.json`を複製した記録が見つからない — 未実施）
* [ ] 結果を事前固定した受入基準と比較する（受入基準自体がまだ文書化・凍結されていない）
* [ ] HANDOFF.md / `docs/production-readiness-report.md` / `docs/production-readiness-checklist.md`の「口座未指定で未開始」という記載を、実際の完走結果に合わせて更新する
* [ ] 2020-2025期間で開始できなかった原因（tick履歴不足、Symbol仕様、Broker側制約等）を確認し、正式な検証対象期間を決定する
* [ ] 今回の結果（総損益-95,024円、Profit Factor 0.59、最大DD10%到達、ロング勝率0%）を踏まえ、Strategyパラメータの見直し・再実行・期間拡大のいずれで進めるかを判断する

## 2.2 `TestDecisionApiRules` の終了コード

* [ ] `TEST_SUITE_PASS` にもかかわらずProcess Exit Code 1となる状態を再現する
* [ ] MT5 Terminal側の終了理由を確認する
* [ ] Script、Runner、Terminal設定のどこに原因があるか特定する
* [ ] テスト結果判定方法が誤検知しないことを確認する
* [ ] 修正後に全MQL5 Script Testを再実行する

---

# 3. 実市場データとモデル

## 3.1 データ準備

* [ ] 使用する市場データSourceを決定する
* [ ] データ利用条件とライセンスを確認する
* [ ] TimezoneとDSTの扱いを決定する
* [ ] Point-in-time整合性を確認する
* [ ] Spread、Commission、Swap、Slippageのデータ条件を決定する
* [ ] Data Quality Checkを実装または実行する

## 3.2 検証期間

* [ ] In-Sample期間を固定する
* [ ] Calibration期間を固定する
* [ ] Out-of-Sample期間を固定する
* [ ] Label Horizonに応じたgapを固定する
* [ ] OOS確認後に同じ期間を再利用しない運用を確立する

## 3.3 ML評価

* [ ] 実市場データでTrainingを実行する
* [ ] Probability Calibrationを実行する
* [ ] OOS評価を実行する
* [ ] Walk Forward評価を実行する
* [ ] 閾値候補を比較する
* [ ] 取引コスト込みで評価する
* [ ] 期間別・相場環境別の安定性を確認する
* [ ] production候補Model Artifactを生成する
* [ ] Model VersionとSHA-256を記録する
* [ ] Model Artifactと評価Reportを保管する

---

# 4. AWS dev

## 4.1 初回デプロイ

* [ ] 使用するAWS Accountを確定する
* [ ] 使用するAWS Regionを確定する
* [ ] AWS CLIの認証先を確認する
* [ ] CDK Bootstrapの要否を確認する
* [ ] ModelとLLMを未設定にしたフェイルセーフ状態で`cdk diff`を確認する
* [ ] dev StackをDeployする
* [ ] CloudFormation Outputを記録する
* [ ] Decision API URLを記録する
* [ ] Telemetry API URLを記録する
* [ ] DynamoDB Tableを記録する
* [ ] Model Bucketを記録する
* [ ] SNS Topicを記録する

## 4.2 Secretと認証

* [ ] Decision API用HMAC共有鍵を安全に生成する
* [ ] Server側SecretをSSM SecureStringへ登録する
* [ ] EA側Secret Fileを作成する
* [ ] SecretがGit、ログ、Shell Historyへ残っていないことを確認する
* [ ] 正常な署名付きRequestを送信する
* [ ] 不正署名を拒否することを確認する
* [ ] Clock Skewを拒否することを確認する
* [ ] Nonce Replayを拒否することを確認する
* [ ] Duplicate RequestのIdempotencyを確認する

## 4.3 実通信

* [ ] Decision APIの正常応答を確認する
* [ ] DecisionがDynamoDBへ保存されることを確認する
* [ ] Telemetry APIの正常応答を確認する
* [ ] Trade EventがDynamoDBへ保存されることを確認する
* [ ] Candidate IndexからDecisionとEventを取得する
* [ ] CloudWatch Logsを確認する
* [ ] EMF Metricsを確認する

## 4.4 Alarm

* [ ] SNS Email Subscriptionを承認する
* [ ] Lambda Error Alarmを試験する
* [ ] API 5xx Alarmを試験する
* [ ] ML Error Alarmを試験する
* [ ] LLM Error Alarmを試験する
* [ ] DynamoDB System Error Alarmの検証方法を決定する
* [ ] Alarm通知が実際に到達することを確認する
* [ ] Alarm復旧時の挙動を確認する
* [ ] AWS Budgetsを設定する
* [ ] 費用異常通知を設定する

## 4.5 障害試験

* [ ] Lambda Timeout
* [ ] API Gateway 5xx
* [ ] HTTP 429
* [ ] DynamoDB Error
* [ ] S3 Model取得失敗
* [ ] Model checksum不一致
* [ ] SSM Parameter取得失敗
* [ ] Network切断
* [ ] DNS障害
* [ ] TLS障害
* [ ] Telemetry障害

---

# 5. LLM API

## 5.1 接続準備

* [ ] LLM Providerを確定する
* [ ] 固定Model IDを確定する
* [ ] Prompt Versionを確定する
* [ ] API KeyをSSM SecureStringへ登録する
* [ ] `llm_shadow_mode=true` を確認する
* [ ] CDK Diffを確認する
* [ ] dev Stackを再Deployする

## 5.2 実通信

* [ ] 実LLM APIへの接続を確認する
* [ ] 構造化されたALLOWを確認する
* [ ] 構造化されたVETOを確認する
* [ ] Timeout時のVETOを確認する
* [ ] Provider Error時のVETOを確認する
* [ ] 不正JSON時のVETOを確認する
* [ ] 必須Field欠落時のVETOを確認する
* [ ] 不正Decision値を拒否する
* [ ] Confidence範囲外を拒否する
* [ ] Secretがログへ出ていないことを確認する

## 5.3 Shadow Mode評価

* [ ] Shadow Modeログを一定期間蓄積する
* [ ] LLM未適用の結果を作成する
* [ ] 記録済みVETO適用時の結果を作成する
* [ ] VETO率を測定する
* [ ] 誤VETOを分析する
* [ ] Net Profitへの影響を分析する
* [ ] Drawdownへの影響を分析する
* [ ] 取引数への影響を分析する
* [ ] API Latencyを分析する
* [ ] Token使用量と費用を分析する
* [ ] 実務上の効果量を評価する
* [ ] productionでVETOを適用するか判断する

---

# 6. Demo口座

## 6.1 観測モード

次の設定で開始する。

```text
InpDecisionApiEnabled = true
InpTelemetryEnabled = true
InpEnableTradeMutations = false
```

* [ ] Strategy候補生成を確認する
* [ ] Decision API Requestを確認する
* [ ] ML判定を確認する
* [ ] LLM Shadow判定を確認する
* [ ] Risk判定を確認する
* [ ] ローカルJSONLを確認する
* [ ] TelemetryとDynamoDBを確認する
* [ ] Clock Skewを確認する
* [ ] API Latencyを確認する
* [ ] Broker Symbol仕様を確認する

## 6.2 障害試験

* [ ] Emergency Stop
* [ ] Strategy Stop
* [ ] Decision API停止
* [ ] API Timeout
* [ ] HTTP 4xx
* [ ] HTTP 5xx
* [ ] HTTP 429
* [ ] 不正JSON
* [ ] request ID不一致
* [ ] TTL切れ
* [ ] Clock Skew
* [ ] Replay
* [ ] ML Error
* [ ] LLM Error
* [ ] LLM Timeout
* [ ] DynamoDB障害
* [ ] Network切断
* [ ] Spread急拡大
* [ ] Margin不足
* [ ] OrderCheck失敗
* [ ] 約定拒否
* [ ] Stop Level違反
* [ ] Freeze Level違反

## 6.3 取引モード

観測モードと障害試験完了後にのみ実施する。

* [ ] ユーザー承認を得る
* [ ] 設定の証跡を保存する
* [ ] `InpEnableTradeMutations=true` に変更する
* [ ] 新規Entryを確認する
* [ ] Lot計算を確認する
* [ ] SL・TPを確認する
* [ ] Spread Guardを確認する
* [ ] Position Limitを確認する
* [ ] 約定とSlippageを確認する
* [ ] Exitを確認する
* [ ] MT5再起動後のPosition再認識を確認する

## 6.4 既存ポジション保護

* [ ] ポジション保有中にEmergency Stopを有効化する
* [ ] 新規注文が停止することを確認する
* [ ] 既存ポジション監視が継続することを確認する
* [ ] Broker側SLが維持されることを確認する
* [ ] TPが維持されることを確認する
* [ ] 保護SLなしPositionの検出を確認する
* [ ] 緊急決済を確認する
* [ ] Decision API停止中の管理継続を確認する
* [ ] LLM停止中の管理継続を確認する
* [ ] Telemetry停止中の管理継続を確認する

---

# 7. MQL5 VPS

* [ ] WebRequest許可URLを設定する
* [ ] EA Inputを確認する
* [ ] AutoTrading設定を確認する
* [ ] Secret Fileの配置方法を確認する
* [ ] VPS上でSecret Fileを読み込めることを確認する
* [ ] VPSからDecision APIへ接続する
* [ ] VPSからTelemetry APIへ接続する
* [ ] UTCとBroker Server Timeを確認する
* [ ] Audit JSONLを確認する
* [ ] VPS同期後の設定維持を確認する
* [ ] VPS再起動後のEA復旧を確認する
* [ ] VPS再起動後のPosition認識を確認する
* [ ] SL・TP継続を確認する
* [ ] Emergency Stopを確認する
* [ ] 外部障害時の新規注文拒否を確認する
* [ ] 長時間連続運転を実施する
* [ ] Weekend跨ぎを確認する
* [ ] Market Close・Openを確認する
* [ ] ログ容量と保持方法を確認する

---

# 8. 運用・監視の残タスク

* [ ] 独立した定期EA Heartbeatを設計する
* [ ] Heartbeatを実装する
* [ ] 無候補時間帯の死活判定を実装する
* [ ] MT5 Report Importerの必要性を評価する
* [ ] 必要ならMT5 Report Importerを実装する
* [ ] Telemetry自動再送キューの必要性を評価する
* [ ] 必要なら再送キューを実装する
* [ ] Secret Rotation手順を作成する
* [ ] Secret Rotationを演習する
* [ ] Incident Response手順を作成する
* [ ] 緊急停止と手動決済を演習する
* [ ] Model Rollbackを演習する
* [ ] CDK Rollbackを演習する

---

# 9. 小額実口座

以下の全項目完了後のみ着手する。

* [ ] Strategy Tester合格
* [ ] OOS合格
* [ ] Walk Forward合格
* [ ] AWS dev実通信合格
* [ ] LLM Shadow評価完了
* [ ] Demo障害試験合格
* [ ] Demo取引モード合格
* [ ] MQL5 VPS継続運転合格
* [ ] Alarm通知確認
* [ ] Kill Switch実証
* [ ] SL・TP継続実証
* [ ] 運用・Rollback手順の演習
* [ ] ユーザーによる明示的承認

---

# 10. Production Gate

* [ ] OOS Reportを保管する
* [ ] Walk Forward Reportを保管する
* [ ] Demo Reportを保管する
* [ ] Small Real Reportを保管する
* [ ] ML Model Versionを記録する
* [ ] ML Model SHA-256を記録する
* [ ] LLM Provider・Model・Prompt Versionを記録する
* [ ] AWS AccountとRegionを記録する
* [ ] VPS Secret File確認を記録する
* [ ] SNS通知確認を記録する
* [ ] Budgets確認を記録する
* [ ] Rollback Drill結果を記録する
* [ ] Production Evidence JSONを作成する
* [ ] Production Release Gateを実行する
* [ ] 承認者と承認時刻を記録する
