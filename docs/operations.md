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

VETO件数やRisk拒否件数だけでは通知しない。これらは安全側の通常判断を含むため、DashboardまたはLogs Insightsで比率と理由を日次・週次レビューする。取引候補がない期間はAPI無通信が正常になり得るため、欠損メトリクスだけで障害判定しない。

Dashboardは必要な環境だけ `-c enable_dashboard=true` で有効化する。利用しないDashboardは次回deployで無効化する。CloudWatch、SNS、カスタムメトリクス、ログ取込・保存の実請求を月次で確認し、AWS BudgetsとCost Anomaly Detectionの通知先・上限は本番deploy前に別途設定する。

## Phase 12の本番昇格

開発ゲートは `.\tools\release-gate.ps1 -Mode Development` で実行する。これは静的検査、全Python・Lambda・CDKテスト、CDK synth、MetaEditor compile、MT5 script testを行うが、AWS deployや取引は行わない。

Productionゲートには `contracts/production-release-evidence.schema.json` に従う証跡が必要である。OOS、Walk Forward、demo、小額実口座のレポート、model checksum、固定LLM model・prompt、AWS account・region、VPS秘密ファイル、SNS、Budgets、rollback drillを確認する。証跡不足時はゲート失敗を正常な安全動作として扱い、フラグを有効化しない。

有効化はDecision・Telemetryの観測だけを先に行い、取引変更を最後にする。最初から3フラグを同時にtrueにしない。production移行後も日次・週次レビューを続け、最大DD、Daily Loss、認証、モデル、アラーム、費用のいずれかに異常があれば前段環境へ戻す。

## Demo Forward Test手順

1. BrokerのDemo口座を作成し、MT5へログインする。口座番号・パスワードはリポジトリへ保存しない。
2. `tools/link-mt5.ps1`、`tools/compile-mql5.ps1`、`tools/run-mql5-tests.ps1`を順に実行する。
3. USDJPY H1チャートへCoreEAを配置し、最初は `InpEnableTradeMutations=false`、`InpDecisionApiEnabled=false`、`InpTelemetryEnabled=false` とする。
4. MT5のWebRequest許可リストへstagingのDecision APIとTelemetry APIのHTTPS originを追加する。
5. `MQL5\Files\EaTradingSystem\decision-api-secret.txt`へstaging専用共有鍵を配置する。長期AWS Access Keyは配置しない。
6. Telemetryだけを有効化し、ローカルJSONLとDynamoDBの `trade_candidate_id` を照合する。
7. Decision APIを有効化し、`LLM_SHADOW_MODE=true` のまま、VETO・timeout・期限切れ応答が記録されることを確認する。
8. `InpEmergencyStop=true` または `InpStrategyEnabled=false` で新規候補処理が止まり、既存ポジション監視が継続することをExpertsログで確認する。
9. 証跡を保存してから小ロットDemoで `InpEnableTradeMutations=true` とし、注文、SL、TP、約定差、Risk拒否を日次確認する。
10. MQL5 VPS移行後、端末側EAを二重稼働させない。VPS Journal、EA Journal、ローカル監査、CloudWatchを照合する。

定期Heartbeatは未実装である。production前にTimerベースの低頻度HeartbeatまたはMT5外部監視を追加・検証する。
