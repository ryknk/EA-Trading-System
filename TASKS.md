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

**2026-08-10決定: ブローカーをXMTrading-MT5からOANDA証券MT5（東京サーバー）へ切り替える。** 理由は、XMTrading-MT5がUSDJPYのreal tickデータを2022年1月分以降しか保持しておらず、2015年以降を対象にした検証ができないため（詳細は本節末尾の原因調査結果を参照）。OANDA証券のデモ口座開設完了後、Strategy Testerを再実行し、以後はOANDA側データを正式なIn-Sample/Out-of-Sample系列として扱う。以下のXMTrading結果は削除せず参考記録として保持するが、正式な受入基準比較・OOS・Walk Forwardの対象にはしない。

* [ ] OANDA証券デモ口座の開設を完了する（ユーザー作業）
* [ ] OANDA証券MT5（東京サーバー）端末をインストールする
* [ ] `tools/link-mt5.ps1`のJunction先をOANDA MT5端末のデータフォルダへ向け直す（`-TerminalData`パラメータで指定）
* [ ] OANDA側のUSDJPY Symbol仕様を確認する（Symbol名表記、Digits、Volume Min/Max/Step、Tick Size/Value、Stop Level/Freeze Level、レバレッジ=国内規制上限25倍、スワップ体系）
* [x] OANDA側でUSDJPYのreal tick履歴を2015年以降で取得する（2026-08-16試行、**失敗**）
* [x] `.\tools\run-strategy-tester.ps1`をOANDA側データで再実行する（2026-08-16、2015.01.01-2025.12.31指定で完走、exit=0）
* [x] 新しいレポートを`results/backtests/<run-id>-USDJPY-H1/`へ保存する（`results/backtests/20260816-113850-USDJPY-H1/`）
* [ ] 新結果を踏まえてHANDOFF.md / `docs/production-readiness-report.md` / `docs/production-readiness-checklist.md`を更新する

**2026-08-16重大な判明事項: OANDA証券でもreal tickの深い履歴は取得できなかった。** 実行は完走したが「ヒストリー品質2%リアルティック」となり、ほぼ全期間が合成tickだった。OANDA-Japan MT5 Demoサーバーの`.../ticks/USDJPY/`を確認したところ、real tickの`.tkc`ファイルは2025-09〜2026-08の約1年分（一部欠落あり）しか存在せず、2015〜2024年分は皆無だった。詳細は`results/backtests/20260816-113850-USDJPY-H1/INVALID-2pct-real-ticks.md`。

比較: XMTrading-MT5は2022-01以降（約4.5年分）のreal tickを保持していたのに対し、OANDA-Japan MT5 Demoは2025-09以降（約1年分）しか保持していない。**ブローカー切替はreal tick履歴の深さを改善するどころか悪化させた。** これはブローカー固有の問題ではなく、MT5デモ口座サーバー一般がraw tickレベルの長期履歴を保持しない構造的制約である可能性が高い（Real口座や有償tickデータベンダーでの挙動は未確認）。

* [x] 2015年以降のreal tick取得という当初目標をどう扱うか判断する（**2026-08-16解決**: OANDA証券のWeb版Tickダウンロードツールから2016年9月以降のUSDJPY real tick CSV（120か月分、圧縮4.0GB）を取得。MT5デモ口座サーバーのライブtickキャッシュとは別に、Custom Symbol `USDJPY_HIST`（`USDJPY`の仕様を複製）へ`mt5/Tools/ImportOandaTicks.mq5`経由で投入する方式を確立した。詳細は`DECISIONS.md` DEC-023を参照）

**2026-08-16: Custom Symbol `USDJPY_HIST`への投入完了。** 全119ファイル・約8億8,097万tick（9月分の825万tickと合わせ累計約8億8,922万tick、2016-09〜2026-08）をパースエラー0件で投入した。Strategy Testerで2016年9月単月・2020年通年（月境界をまたぐ12か月）の両方について「ヒストリー品質100%リアルティック」を確認済み（`results/backtests/oanda-hist-validation-2016-09/`、`results/backtests/oanda-hist-validation-2020/`）。2020年通年のMock ALLOW実行では総損益-83,262円・取引数117（正式なIS/OOS期間としてはまだ採用しておらず、スポットチェック目的の参考値）。

* [x] 正式なIn-Sample/Out-of-Sample/Walk Forward期間を`USDJPY_HIST`（2016-09〜2026-08の範囲内）で確定する（2026-08-16確定、`DECISIONS.md` DEC-024参照。開発・In-Sample=2016-09〜2020-12、OOS/Walk Forward評価=2021-01〜2024-12、Final Holdout=2025-01〜2026-08、Walk Forwardは4年学習→1年検証のローリング5Fold。ユーザー指定の開始日2016-01は`USDJPY_HIST`の実データ開始2016-09と矛盾していたため、実際に取得済みの範囲へ補正した）
* [x] In-Sample期間でStrategy Testerを実行し、`run-metadata.json`を作成する（2026-08-16実施。当初期間2016-09〜2020-12で実行したところ取引数0件の異常が判明し、原因調査の結果Tester開始日が`USDJPY_HIST`実データ最古日（2016-08-31）に近すぎ、D1/H4インジケーターのウォームアップに必要なバッファ（実測で9〜10か月必要）が不足していたことが判明。詳細な原因調査・二分探索の経緯は`results/backtests/20260816-180519-USDJPY-H1/ANOMALY-zero-trades.md`、期間補正は`DECISIONS.md` DEC-025を参照。開始日を**2017-09-01**へ補正した上で正式再実行し完走（`results/backtests/20260816-193344-USDJPY-H1/`）: ヒストリー品質100%リアルティック、取引数55・約定数110、総損益-65,696円、Profit Factor 0.66、最大DD 96,450円（9%）、Sharpe -3.20、期待利得-1,194.47円、ロング40件/勝率27.50%、ショート15件/勝率20.00%、最大連敗17件（-80,818円）。受入基準未凍結のため合否は未判定）
* [ ] Walk Forward各Fold（Fold1: 学習2017-09〜2019-12/検証2020 〜 Fold5: 学習2020-01〜2023-12/検証2024、DEC-025でFold1学習開始を補正）を実行する。rule-based Strategyには学習ステップがないため、当面は各Foldの検証年についてのみ固定パラメータでStrategy Testerを実行する（学習を伴うWalk Forward評価は3.3節のML評価タスクで別途実施する）
* [ ] Final Holdout期間（2025-01〜2026-08）は、EA・MLモデル・閾値・SL/TP等を確定し他の全ゲートが完了するまで実行しない（一度だけの評価として温存する）
* [x] 新結果を踏まえてHANDOFF.md / `docs/production-readiness-report.md` / `docs/production-readiness-checklist.md`を更新する（2026-08-16実施）

---

`results/backtests/20260721-231302-USDJPY-H1/`に、実行済みレポート（`ets-20260721-231302-USDJPY-H1.htm`/`.png`）が存在することを2026-07-23の調査で確認した。USDJPY/H1、2025.01.01-2025.12.31、100% real ticks、Mock ALLOW（`InpTesterDecisionMode=1`, `InpTesterFixedMlProbability=0.65`）、`InpEnableTradeMutations=true`（Strategy Tester内のみ）で完走している。結果は総損益 **-95,024円**、Profit Factor **0.59**、最大Drawdown **10%（口座上限到達）**、取引数66、ロング勝率0%/ショート勝率26.67%、最大連敗9。ただしHANDOFF.md、`docs/production-readiness-report.md`、`docs/production-readiness-checklist.md`はこの結果を反映しておらず「口座未指定で未開始」のまま更新が必要（未実施）。同ディレクトリ以前の3回の試行（`20260721-220506`,`20260721-230456`,`20260721-231041`）は`tester.ini`のみでレポートが生成されておらず失敗している。

* [x] Demo Broker口座へログインする（実行成功の前提として達成。ただしDemo口座かReal口座かは未確認 — Broker表示は`XMTrading-MT5`/`Tradexfin Limited`）
* [x] Broker上のUSDJPYの実Symbol名を確認する（`USDJPY`表記で実行できている）
* [x] USDJPYのreal tick履歴を取得する（2025年分のみ。2020-2025期間では3回とも開始できず、原因未確認）
* [x] `mt5/test-config/StrategyTester-USDJPY-H1.ini` を確認する
* [x] `.\tools\run-strategy-tester.ps1 -TimeoutSeconds 900` を実行する（2026-07-21 23:13に完了）
* [x] Strategy Testerレポートが生成されることを確認する（`.htm`/`.png`が存在）
* [ ] TerminalログとEAログを保存する（2026-08-09調査: `results/backtests/20260721-231302-USDJPY-H1/`には`.htm`/`.png`/`tester.ini`のみが存在し、Journal/Expertsタブのログファイルは見つからない。保存先・保存有無は依然未確認）
* [x] Entry、Exit、SL、TP、Lot計算を確認する（2026-08-09、レポート内`注文`/`取引`テーブルを精査。132注文・66決済すべて`filled`、Entryコメント`trend-ea-v1-USDJPY-<bar time>`とExitコメント`sl <price>`/`tp <price>`が対応し、SL/TP価格とLot(0.03〜0.17、0.5%リスクに応じ変動)に矛盾なし。Commission合計0、Swap合計-10,846円、価格損益合計-84,178円で総損益-95,024円と一致することを確認。詳細は`run-metadata.json`の`metrics`を参照）
* [ ] Spread、Margin、OrderCheckの拒否動作を確認する（2026-08-09調査: 132注文はすべて`filled`で、拒否・requoteに該当する注文はレポートに1件も現れなかった。したがって拒否動作そのものは本実行では検証できていない。EAログが残っていないため追加確認も不可）
* [x] 実行条件とGit Commit SHAをMetadataへ記録する（`results/backtests/20260721-231302-USDJPY-H1/run-metadata.json`を作成。ただし実行時刻2026-07-21 23:13:02はリポジトリ最初のコミット651bcc5(2026-07-22 20:07:10)より前のため、対応するGit Commit SHAは存在せず記録不可＝`null`）
* [ ] 結果を事前固定した受入基準と比較する（受入基準自体がまだ文書化・凍結されていない — ユーザー判断待ち）
* [x] HANDOFF.md / `docs/production-readiness-report.md` / `docs/production-readiness-checklist.md`の「口座未指定で未開始」という記載を、実際の完走結果に合わせて更新する（2026-08-09実施）
* [x] 2020-2025期間で開始できなかった原因（tick履歴不足、Symbol仕様、Broker側制約等）を確認し、正式な検証対象期間を決定する（2026-08-10確認: 過去の`account is not specified`失敗は、当時の実行スクリプトのReport出力パス形式に起因していたとみられ、現行の`tools/run-strategy-tester.ps1`では再現しない（2020.01.01-2021.12.31を指定した実行がexit=0で正常終了）。ただし本質的な制約が判明: Broker（XMTrading-MT5/Tradexfin Limited）はUSDJPYのreal tickデータを**2022年1月分以降しか保持していない**（`.../ticks/USDJPY/`に202201.tkc以降のみ存在。OHLC M1バーは2016年から存在するが、real tickはない）。2020-2021を指定して実行すると、MT5がOHLCから合成tickを自動生成し「ヒストリー品質0%リアルティック」で完走してしまう（`results/backtests/20260810-144215-USDJPY-H1/INVALID-0pct-real-ticks.md`に詳細記録、このディレクトリの結果は無効・参考専用）。**結論: 2020〜2021年を含むreal tickベースの検証は本Broker/口座では不可能。** この結論を受け、2026-08-10にOANDA証券MT5への切替とOANDA側での2015年以降real tick取得が決定した（本節冒頭を参照）。XMTrading側での期間拡大は行わない）
* [ ] 今回の結果（総損益-95,024円、Profit Factor 0.59、最大DD10%到達、ロング勝率0%/6件、ショート勝率26.67%/60件）を踏まえ、Strategyパラメータの見直し・再実行・期間拡大のいずれで進めるかを判断する（ユーザー判断待ち。詳細は作業報告を参照）

## 2.2 `TestDecisionApiRules` の終了コード

**2026-08-16追記**: 本番運用ブローカーをOANDA証券MT5へ切り替え（`DECISIONS.md` DEC-023）、`tools/compile-mql5.ps1`・`tools/run-mql5-tests.ps1`・`tools/run-strategy-tester.ps1`・`tools/release-gate.ps1`・`tools/link-mt5.ps1`のデフォルト対象をOANDA端末へ変更した上で、Compile・7 Script Testを再実行した。結果はXMTrading環境と同一（全PASS、`TestDecisionApiRules`のみexit code 1）。この事象はBroker固有ではなく、Script/Runner/Terminal設定側の問題であることが裏付けられた。

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
