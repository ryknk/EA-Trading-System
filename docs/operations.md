# 運用

EAは最終確定足、API状態、リスクガード状態、日次口座スナップショット、未決済ポジションをローカルログへ出す。外部監視停止中でもSLと既存ポジション管理を継続する。新規注文停止は安全状態であり、無理な自動復旧発注を行わない。独立した定期Heartbeat送信はPhase 13時点で未実装であり、候補が発生しない時間帯の死活監視は `NOT VERIFIED` とする。

緊急時は自動売買停止、新規注文フラグ停止、未決済ポジション確認、必要なら手動リスク削減、ログ保全の順に対応する。認証情報漏えい時はサーバー側で失効し、新しい認証情報を配布する。モデル・プロンプトの切り戻しはバージョン固定で行う。

Phase 4以降、`InpEnableTradeMutations=false`は試行運転状態である。trueへ変更する前にマジックナンバーの重複がないことを確認する。同じマジックナンバーの既存ポジションにSLがない場合、Position Managerの緊急決済対象になり得る。`EMERGENCY_CLOSE_ALREADY_ATTEMPTED`は曖昧な再送を避ける停止状態であり、ポジション・注文・約定を手動確認してから対応する。

日次に有効証拠金、損益、DD、ガード発動、外部エラー、注文・約定差を確認する。週次に戦略・シンボル別成績、費用、遅延、データ品質を確認する。変更は開発 → ステージング・デモ → 本番の順とし、本番設定の変更を監査記録する。

## Phase 6のAWS運用

deploy前にAWSアカウント・リージョン・環境名を確認し、Parameter Store SecureStringへ共有鍵を登録する。`cdk synth` と差分を確認し、CloudWatch Alarm通知先とAWS Budgetsを別途設定する。API URLをEAへ設定してWebRequest許可リストへ追加するが、ML/LLMが配備・検証されるまで `InpDecisionApiEnabled` と `InpEnableTradeMutations` はfalseのままとする。

401が増えた場合はEAとLambdaのUTC時刻、key ID、共有鍵、正規化対象URLを確認する。409はnonce再利用またはrequest ID競合として調査する。429、500、タイムアウト時は新規注文を停止したまま、Lambda、DynamoDB、Parameter Store、API Gatewayのメトリクスを確認する。復旧確認には新しい候補IDを使い、期限切れALLOWを再利用しない。

## Phase 7のモデル運用

モデル配備前に、入力データ期間、重複・欠損、ラベル定義、コスト仮定、学習・校正・OOS境界、ウォークフォワード結果をレビューする。合成データで生成したモデルを配備してはいけない。成果物アップロード後はS3の実バイト列からSHA-256を計算し、CDK contextへ設定する。

モデル更新は新しいversionとS3キーを使い、既存オブジェクトを上書きしない。dev、staging・デモの順で推論値と拒否率を比較し、productionは明示的に切り替える。`ML_INFERENCE_ERROR` が発生した場合はchecksum、キー、bucket、IAM、特徴量schema、symbol/timeframeを確認し、新規注文停止を維持する。旧モデルへの切戻しは旧キーとchecksumの再deployで行う。

## Phase 8のLLM運用

LLMはprovider/modelを空にした状態が既定である。有効化前に環境別APIキー、利用上限、固定model、prompt version、temperature対応、構造化出力対応を確認する。devで過去候補の回帰セットを実行し、ALLOW/VETO、invalid、refusal、timeout、p95 latency、費用を記録する。

更新はmodel IDまたはprompt versionを必ず変更し、staging・デモで比較してからproductionへ反映する。`LLM_INFERENCE_ERROR` 増加時はprovider status、SSM、IAM、model availability、timeout、構造化出力形式を確認し、新規注文停止を維持する。LLMだけを無効化した場合はフェイルオープンせず、ML通過候補もVETOとなる。

## Phase 9の監査運用

ローカル監査は `InpAuditFileEnabled=true` を既定とし、`MQL5\Files` 配下の設定ディレクトリへ日別JSONLで追記する。端末ログの `AUDIT_EVENT` とJSONLの `event_id`、`trade_candidate_id`、`request_id` を使って判断から決済まで相関する。ログには共有鍵、署名、口座ログイン番号、LLM生prompt・生responseを含めない。

Telemetry APIはAWS配備とdev検証後にだけ `InpTelemetryEnabled=true` とする。URL末尾は `/v1/trade-events` とし、Decision APIと同じkey ID・共有鍵で別パスを署名する。HTTP失敗は `TELEMETRY_UPLOAD_FAILED ... trading_impact=none` として扱い、注文を再送したり既存ポジション管理を停止したりしない。Phase 9は自動再送を実装していないため、障害期間のJSONLを保全し、DynamoDBの欠損範囲を候補IDとUTC時刻で記録する。

DynamoDBで重複event IDかつ本文hashが同一なら `DUPLICATE` は正常な冪等再送である。event IDが同じで本文が異なる409は改ざん、生成不具合、誤再送として調査する。Telemetry Lambdaの500増加時はDynamoDB、SSM、IAM、API Gateway、Lambdaエラーアラームを確認するが、取引可否の判断系障害とは区別する。

## Phase 10の分析運用

バックテスト、OOS、ウォークフォワード、デモ、実運用ごとに入力ファイル、初期残高、無リスク金利、設定、モデル版、プロンプト版、生成済み `performance-summary.json` を同じ成果物単位で保全する。結果を確認してから受入閾値を変更した場合、その期間をOOSとして再利用しない。

日別監査JSONLは分析前に欠損日とファイルサイズを確認し、複数日を1回のコマンドへ渡す。`drawdown_source=CLOSED_TRADES` のレポートは含み損を捉えないため、デモ・本番評価では `ACCOUNT_EQUITY_SNAPSHOTS` を優先する。取引数が少ない、CAGR・Sharpe・Profit Factorがnull、期間が短い場合は昇格判断を保留する。

## Phase 11の監視運用

deploy後にCloudFormation出力 `OperationsAlertTopicArn` を確認する。`alarm_email` を指定した場合、AWSから届く購読確認を承認するまで通知されない。devでテストアラームを発生させ、ALARMとOKの通知到達、環境名、アラーム名を確認してからstaging・productionへ進める。

アラーム対応は次の優先順位とする。

1. Decision内部エラーまたはHTTP 5xx: 新規注文はEA側VETOになる。Lambda、DynamoDB、S3モデル、SSM、LLM providerの順に確認し、既存ポジション管理がMT5単独で継続していることを確認する。
2. Decision p99 duration: EA timeoutより先にLambda処理が完了しているか確認する。MLモデル読込、LLM latency、provider timeoutを調べ、期限切れALLOWを再利用しない。
3. Telemetry内部エラー: 売買判断への影響はない。ローカルJSONLを保全し、DynamoDB・IAM・SSM復旧後の欠損範囲を記録する。
4. リプレイ拒否: 時計ずれや同一nonce再送を確認する。意図しない増加ならkey IDを失効し、共有鍵をローテーションする。
5. Lambda throttle: 全tick呼出しなど候補生成頻度の異常、予約同時実行数、API Gateway制限を確認する。制限を安易に引き上げず、呼出し元の異常を先に調べる。

6. Heartbeat欠損: EA停止、端末ハング、MT5の切断、VPS停止、WebRequest許可URL・Secret File不備、Heartbeat API障害のいずれかである。まずMT5/VPS上でEAが稼働し既存ポジションのSL/TPが維持されているかを確認する。EAが稼働しているのに欠損する場合はExpertsログの `HEARTBEAT_SEND_FAILED`、Heartbeat LambdaのError/内部エラーAlarm、DynamoDB障害を確認する。Heartbeat障害だけを理由に既存ポジションを決済・EAを停止しない。
7. Heartbeat内部エラー: DynamoDB・SSM・IAMを確認する。取引判断・Telemetryへの影響はない。

VETO件数やRisk拒否件数だけでは通知しない。これらは安全側の通常判断を含むため、DashboardまたはLogs Insightsで比率と理由を日次・週次レビューする。取引候補がない期間はAPI無通信が正常になり得るため、欠損メトリクスだけで障害判定しない。例外はHeartbeat欠損Alarmで、Heartbeatは候補の有無に関係なく定期送信されるため、欠損をEA停止・ハング・通信断の兆候として扱う。

### Alarm通知経路の試験手順

通知経路はAlarmの状態を一時的に変更して試験できる。AWS環境へ変更を加えるため、実行前に対象account・region・環境を確認し、devから行う。Alarm状態は次回のメトリクス評価で実状態へ戻る。

```powershell
aws cloudwatch describe-alarms --alarm-name-prefix ea-trading-system-dev- --query "MetricAlarms[].{Name:AlarmName,Actions:AlarmActions,State:StateValue}"
aws sns list-subscriptions-by-topic --topic-arn <OperationsAlertTopicArn>
aws cloudwatch set-alarm-state --alarm-name ea-trading-system-dev-lambda-errors --state-value ALARM --state-reason "notification path test"
```

確認項目は、全Alarmの `AlarmActions` がOperations Topicを指すこと、購読が `PendingConfirmation` でないこと、通知メールに環境名とAlarm名が含まれ秘密情報を含まないこと、次回評価でOKへ戻ることである。Heartbeat欠損Alarmは状態変更ではなく、EAのHeartbeatを実際に止めてALARM・OK両方の通知で確認する。`alarm_email` 未指定のdevでは通知が届かないため、CDK warningとOutput `AlarmEmailSubscriptionConfigured=false` を確認する。

### Secretキャッシュとローテーション

Lambdaは共有鍵とLLM APIキーを最大 `secret_cache_ttl_seconds`（既定300秒）保持する。鍵ローテーションは新しいkey IDのParameterを追加し、EAのkey IDを切り替えて正常性を確認してから旧Parameterを削除する（新しいkey IDはキャッシュされていないため即時反映）。同一Parameterを上書きする緊急時は、TTL経過を待つか、Lambda設定の再deployで実行環境を入れ替える。漏えい時は旧Parameterを削除し、TTL経過までは旧鍵が受理され得ることを前提に、EAの新規注文停止を先に行う。

Dashboardは必要な環境だけ `-c enable_dashboard=true` で有効化する。利用しないDashboardは次回deployで無効化する。CloudWatch、SNS、カスタムメトリクス、ログ取込・保存の実請求を月次で確認し、AWS BudgetsとCost Anomaly Detectionの通知先・上限は本番deploy前に別途設定する。

## Phase 12の本番昇格

開発ゲートは `.\tools\release-gate.ps1 -Mode Development` で実行する。これは静的検査、全Python・Lambda・CDKテスト、CDK synth、MetaEditor compile、MT5 script testを行うが、AWS deployや取引は行わない。

Productionゲートには `contracts/production-release-evidence.schema.json`（schema 2.0、製品ビルド `ProductEA` 用、DEC-049）に従う証跡が必要である。リリースする製品commit・ex5、Strategy Testerのmanifest（同じcommit・ex5・事前固定の合否基準、Walk ForwardとFinal Holdoutを含む）、OOS・Walk Forward・Final Holdout・Demo・小額実口座・ベンチマーク比較のレポート、試験運用で使ったex5、プッシュ通知の受信・Kill Switch・Rollbackの演習、リスク上限の確認、ベンチマーク受入基準の合否、承認者と承認時刻を確認する（詳細は `docs/release-gate.md`「本番ゲート」）。証跡不足時はゲート失敗を正常な安全動作として扱い、取引変更を有効化しない。

有効化はDecision・Telemetryの観測だけを先に行い、取引変更を最後にする。最初から3フラグを同時にtrueにしない。production移行後も日次・週次レビューを続け、最大DD、Daily Loss、認証、モデル、アラーム、費用のいずれかに異常があれば前段環境へ戻す。

## 製品ビルドによる試験運用（2026-10-11追加、`DECISIONS.md` DEC-046）

試験運用（Demo・小額実口座）は製品ビルド `ProductEA` で行う。`ProductEA` はDecision API・ML/LLM・Telemetry・Heartbeatを含まず、新規注文をローカルの戦略・フィルタ・Risk Manager・`OrderCheck` で判断する。AWS、WebRequest許可リスト、共有鍵ファイルは不要である。

1. BrokerのDemo口座を作成し、MT5へログインする。口座番号・パスワードはリポジトリへ保存しない。
2. `git submodule update --init` で製品submodule（`product/`、`ryknk/EA-Product`）を開発基盤に記録したcommitへ揃え、`tools/link-mt5.ps1`、`tools/compile-mql5.ps1`、`tools/run-mql5-tests.ps1`を順に実行する。試験運用に使う製品commitと `ProductEA` のex5 SHA-256を記録する。
3. 対象チャートへ `ProductEA`（ナビゲーター上は `Experts\EaTradingSystemProduct`）を配置し、最初は `InpEnableTradeMutations=false`（既定）のまま、候補・Risk判断・`TRADE_MUTATIONS_DISABLED` による注文ブロックがローカル監査JSONLとExpertsログへ記録されることを確認する。
4. `InpEmergencyStop=true` または `InpStrategyEnabled=false` で新規候補処理が止まり、既存ポジション監視が継続することをExpertsログで確認する。
5. 証跡を保存し、ユーザーの明示的な許可を得てから小ロットで `InpEnableTradeMutations=true` とし、注文、SL、TP、約定差、Risk拒否を日次確認する。
6. MQL5 VPS移行後、端末側EAを二重稼働させない。VPS Journal、EA Journal、ローカル監査JSONLを照合する。

### 稼働監視（2026-10-12追加、`DECISIONS.md` DEC-048）

製品ビルドにはHeartbeatがないため、EAのプッシュ通知と日次稼働報告で稼働を監視する（設定は `docs/configuration.md`「稼働監視」）。

1. スマートフォンへMetaTrader 5アプリを入れ、MetaQuotes IDを確認する。MT5端末のツール→オプション→通知でMetaQuotes IDを設定し、「テスト」で受信を確認する。MQL5 VPSへ移行した後もVPS上のEAから通知が届くかは未確認のため、移行後に起動通知または日次稼働報告の受信で確認する。
2. `ProductEA` の `InpPushNotificationsEnabled=true` とし、起動通知（`STARTED`）が届くことを確認する。`PUSH_NOTIFICATION_NOT_CONFIGURED` がExpertsログに出た場合は1を見直す。
3. 毎日、日本時間07:00（22:00 UTC）以降に日次稼働報告（`REPORT DAILY_ALIVE`）が届いていることを確認する。**届いていない場合は、端末・VPS・EAの停止を疑い、VPS JournalとEA Journalを確認する**（端末やVPSごと停止した場合、EAは通知できない）。報告の `positions`・`last_tick_age`・`connected`・`new_orders`・`risk_lock` も確認する。報告は週末・休場日も届く。報告時刻以降にEAを起動・再起動した日は報告の代わりに起動通知（`STARTED`）が届く。
4. 次の通知を受けた場合は、Expertsログと監査JSONLで原因を確認する。
   * `STOPPED`・`INIT_FAILED`: EAが停止・起動失敗した。意図しない停止であれば再起動前に原因を記録する。
   * `DISCONNECTED`（5分以上の切断）: 新規注文は不可。復帰（`RECONNECTED`）しなければ端末・VPS・Brokerの状態を確認する。
   * `TICK_STALL`（取引セッション中10分以上Tickなし）: 祝日・臨時休場か、Broker・接続の異常かを確認する。
   * `RISK_LOCK`: 日次損失・最大DD等で新規注文が停止した（既存ポジション管理は継続）。解除は `RISK_LOCK_CLEARED` で通知される。
   * `POSITION_MONITOR_ERROR`・`RISK_STATE_UNAVAILABLE`・`ORDER_ERROR`: 新規注文が止まる、または発注に失敗した。同じ種類の再通知は60分間抑制される。
5. EAのハング（`OnTick` が戻らない状態）は通知されない。日次稼働報告が届かない、または端末のGlobalVariable `ETS.ALIVE.<MagicNumber>.TIMER` が5分以上更新されていない場合（更新間隔は60秒）に疑う。`MONITOR_TIMER_FAILED` を受けた場合は生存信号・検知・日次稼働報告が動かないため、EAを再起動する。

### 取引開始前の通知確認（2026-10-12追加）

通知は注文と独立しているため、取引を始める前に確認できる。`InpEnableTradeMutations=false`（既定）のまま、MT5のAutoTradingも無効にして行う（EAは起動・監視・通知を行うが、注文は出ない）。Demo口座を使う。Strategy Testerでは稼働監視が動かないため、通常の端末で行う。

1. 通知経路: ツール→オプション→通知でMetaQuotes IDを設定し、「テスト」でスマートフォンに届くことを確認する。
2. 起動通知: 対象チャートへ `ProductEA`（ナビゲーター上は `Experts\EaTradingSystemProduct`）を `InpPushNotificationsEnabled=true` で配置する。Expertsログに `OPERATIONAL_MONITOR_STATE push=enabled` が出て `PUSH_NOTIFICATION_NOT_CONFIGURED` が出ないこと、起動通知（`STARTED trade_mutations=off`）が届くことを確認する。
3. 日次稼働報告: `InpDailyReportHourUtc` を現在のUTC時刻より後の時（例: 現在が03:20 UTCなら4）に変更し、その時刻を過ぎてから約1分以内に `REPORT DAILY_ALIVE` が届くことを確認する。現在の時以前を指定すると、その日の報告は起動通知で代えられて届かない。入力の変更でEAが再初期化されるため、停止通知（`STOPPED reason=PARAMETERS_CHANGED`）と起動通知も届く。確認後は22へ戻す。
4. 切断・復帰: 端末のネットワークを5分以上切ってから戻し、復帰通知（`RECONNECTED after=<分>min`）が届くことを確認する。回線ごと切れている間は切断通知（`DISCONNECTED`）を送れないため、Expertsログに `OPERATIONAL_ALERT ... DISCONNECTED` と `PUSH_NOTIFICATION_FAILED` が記録され、通知自体は届かない（再送もしない）。切断通知がスマートフォンに届くのは、インターネットは使えるがBrokerとの接続だけが切れた場合である。
5. 停止通知: チャートからEAを外し、`STOPPED reason=REMOVED` が届くことを確認する。
6. 確認日時、受信した通知、Expertsログの該当行を記録し、試験運用の証跡として保管する。

取引開始前に確認しにくい項目:

* Tick停止の通知（`TICK_STALL`）: 取引セッション中にTickを止める手段がない。判定規則は単体テスト（`TestOperationalMonitorRules`）で確認済み。
* Risk Lock・エラーの通知: 意図的に発生させにくい。端末ログへの出力までは結合テストで確認済み。
* 日次稼働報告が毎日届くこと: 日数を要するため、取引変更を有効にする前の観測期間（「製品ビルドによる試験運用」の手順3）で兼ねて確認する。
* MQL5 VPS上での通知: VPSの契約が必要。取引変更を無効にしたままチャートをVPSへ移行し、起動通知と日次稼働報告の受信で確認できる。

## Demo Forward Test手順（研究ビルド・AWS連携の検証用）

以下は研究ビルド `CoreEA` でAWS連携（Decision API・Telemetry・Heartbeat）を検証する場合の手順であり、製品の試験運用には使わない。

1. BrokerのDemo口座を作成し、MT5へログインする。口座番号・パスワードはリポジトリへ保存しない。
2. `tools/link-mt5.ps1`、`tools/compile-mql5.ps1`、`tools/run-mql5-tests.ps1`を順に実行する。
3. USDJPY H1チャートへCoreEAを配置し、最初は `InpEnableTradeMutations=false`、`InpDecisionApiEnabled=false`、`InpTelemetryEnabled=false` とする。
4. MT5のWebRequest許可リストへstagingのDecision API、Telemetry API、Heartbeat APIのHTTPS originを追加する。
5. `MQL5\Files\EaTradingSystem\decision-api-secret.txt`へstaging専用共有鍵を配置する。長期AWS Access Keyは配置しない。
6. Heartbeatを有効化し（`InpHeartbeatEnabled=true`）、DynamoDBの最終Heartbeat時刻が更新され、EA停止時にHeartbeat欠損Alarmが通知されることを確認する。続いてTelemetryだけを有効化し、ローカルJSONLとDynamoDBの `trade_candidate_id` を照合する。
7. Decision APIを有効化し、`LLM_SHADOW_MODE=true` のまま、VETO・timeout・期限切れ応答が記録されることを確認する。
8. `InpEmergencyStop=true` または `InpStrategyEnabled=false` で新規候補処理が止まり、既存ポジション監視が継続することをExpertsログで確認する。
9. 証跡を保存してから小ロットDemoで `InpEnableTradeMutations=true` とし、注文、SL、TP、約定差、Risk拒否を日次確認する。
10. MQL5 VPS移行後、端末側EAを二重稼働させない。VPS Journal、EA Journal、ローカル監査、CloudWatchを照合する。

定期Heartbeatは2026-09-26に実装した（未検証）。Demo Forward Testの観測モードで `InpHeartbeatEnabled=true`、`InpHeartbeatApiUrl=<HeartbeatApiUrl出力>` を設定し、WebRequest許可リストへ同じURLを登録する。EAを停止してから `heartbeat_stale_minutes` 経過後にHeartbeat欠損AlarmのSNS通知が届き、再開後にOK通知が届くことを確認する。
