# 1. 目的

このファイルは、システムの主要な技術選定、設計意図、採用しなかった方式を記録する。

実装仕様そのものは `docs/` を正本とし、このファイルには主に「なぜその方式を選んだか」を記載する。

新しい重要な設計判断を行う場合は、既存項目を上書きせず、新しいDecisionとして追記する。

---

# DEC-001: ルールベースStrategyを起点とする

**状態:** 採用

## 判断

売買候補はMQL5の決定論的なルールベースStrategyから生成する。

MLやLLMを、売買候補をゼロから生成する主体にはしない。

## 理由

* Backtestと再現試験を行いやすい
* 判断経路を説明しやすい
* LLMの非決定性を発注起点へ持ち込まない
* 外部サービス停止時の影響範囲を限定できる
* ML・LLMの効果を追加Filterとして比較できる

## 影響

Strategy、ML、LLM、Risk、Orderの責務を分離する必要がある。

---

# DEC-002: Risk Managerを最終発注権限とする

**状態:** 採用

## 判断

Strategy、ML、LLM、Decision APIがすべてALLOWでも、EA内部のRisk Managerが拒否した場合は発注しない。

## 理由

* 外部応答後に価格、Spread、Equity、Marginが変化する可能性がある
* 外部サービスへ口座の最終発注権限を与えない
* API障害や不正応答から注文経路を分離する
* 最新のBroker・Account状態で再評価する必要がある

## 影響

外部 `ALLOW` は短時間だけ有効な候補承認として扱う。

---

# DEC-003: 既存ポジション管理を外部APIへ依存させない

**状態:** 採用

## 判断

SL確認、保護されていないポジションの検出、緊急クローズなどはEA内部で処理する。

## 理由

* AWS、Network、ML、LLM障害中も損失拡大を防ぐ必要がある
* 新規注文機能と既存ポジション保護では可用性要件が異なる
* 外部障害による管理停止が最も危険な障害の一つである

## 影響

Position Managerは新規候補生成より先に実行する。

---

# DEC-004: 外部障害時はFail Closedとする

**状態:** 採用

## 判断

Timeout、HTTPエラー、不正JSON、認証失敗、ML・LLM例外などは新規注文VETOとする。

## 理由

自動売買では、注文機会を失うことより、不明な状態で発注することの方が重大なリスクとなるため。

## 影響

Error時の自動ALLOWや、古いALLOWの再利用は禁止する。

---

# DEC-005: AWSはサーバーレス構成とする

**状態:** 採用

## 判断

初期AWS構成には次を使用する。

* API Gateway HTTP API
* Lambda
* DynamoDB On-Demand
* S3
* CloudWatch
* SNS
* SSM Parameter Store

次は初期構成へ含めない。

* 常時稼働EC2
* RDS
* NAT Gateway
* LambdaのVPC配置

## 理由

* 個人運用規模で固定費を抑える
* 運用対象を減らす
* 低頻度な売買候補処理に適している
* AWSサービス間の統合が容易
* VPC・NATによる構成と費用の複雑化を避ける

## 再検討条件

固定IP、Private Resource接続、常時接続などが必須になった場合。

---

# DEC-006: AWS CDK v2とPythonを採用する

**状態:** 採用

## 判断

Infrastructure as CodeにはAWS CDK v2とPython 3.12を使用する。

## 理由

* Application側とPythonのToolingを共有できる
* AWS固有サービスを簡潔に表現できる
* 個人規模で開発速度を優先できる
* Unit TestとSynthを開発Gateへ組み込みやすい

## 採用しなかった方式

Terraformは複数Cloud対応に優れるが、本プロジェクトではAWS固有統合と開発速度を優先した。

---

# DEC-007: API GatewayはHTTP APIを使用する

**状態:** 採用

## 理由

* REST APIより低コスト
* 現在必要なRoutingとLambda Integrationを満たす
* 初期規模では高度なREST API機能が不要

## 再検討条件

Usage PlanやREST API固有機能が必須になった場合。

---

# DEC-008: DynamoDBはOn-Demandと単一テーブルを基本とする

**状態:** 採用

## 理由

* 初期Trafficが予測しづらい
* Capacity管理を減らせる
* Request、Decision、EventをCandidate単位で相関できる
* 常時稼働Databaseを持たずに済む

## 注意点

Replay防止用nonceだけにTTLを設定する。

Decisionや取引監査データを誤ってTTL削除しない。

---

# DEC-009: EA認証にはHMAC共有鍵を使用する

**状態:** 採用

## 判断

EAには長期AWS Access Keyを持たせず、失効可能なKey IDとHMAC共有鍵を使用する。

## 理由

* AWS IAM CredentialをMT5端末へ配布しない
* Key単位で失効できる
* Timestamp、Nonce、Request IDと組み合わせてReplayを防げる
* MT5から実装可能な認証方式である

## 注意点

共有鍵はInput ParameterやGitへ保存せず、MQL5 Secret Fileから読み込む。

---

# DEC-010: Server側SecretはSSM Parameter Store SecureStringを使用する

**状態:** 採用

## 理由

* 初期規模ではSecret数と更新頻度が小さい
* Secrets Managerより低コストにできる
* Lambda IAMで環境別Pathへアクセスを制限できる

## 再検討条件

自動Rotationや高度なSecret Lifecycle管理が必要になった場合はSecrets Managerを検討する。

---

# DEC-011: MLは線形Baselineから開始する

**状態:** 採用

## 理由

* 過学習リスクを抑えやすい
* 説明しやすい
* Calibrationと時系列評価を確立しやすい
* 複雑なModelの効果をBaselineと比較できる

## 複雑化の条件

OOS、Walk Forward、Calibration、推論時間、運用コストで明確な改善を確認できた場合のみ検討する。

---

# DEC-012: Probability Calibrationには独立期間を使用する

**状態:** 採用

## 理由

* Training Dataへ過剰適合した確率をそのまま利用しない
* Threshold判断に使用する確率の信頼性を高める
* Training、Calibration、OOSを分離してデータ漏洩を防ぐ

## 注意点

OOSをCalibrationへ使用しない。

---

# DEC-013: LLMはML通過後だけ呼び出す

**状態:** 採用

## 理由

* API費用を抑える
* Latencyの影響を限定する
* 明らかに低品質な候補を先にMLで除外できる
* LLMを補助Filterへ限定できる

---

# DEC-014: LLMは構造化出力のみ受け付ける

**状態:** 採用

## 判断

LLM Decisionは契約に適合する `ALLOW` または `VETO` に限定する。

## 理由

* 自然言語の曖昧な解釈を発注経路へ持ち込まない
* Test可能性を高める
* Provider間の違いを吸収しやすい
* 不正応答を安全に拒否できる

---

# DEC-015: LLM Shadow Modeを既定有効とする

**状態:** 採用

## 判断

正常なLLM VETOは記録するが、効果確認までは最終Decisionへ適用しない。

## 理由

* 実データでLLMの効果を検証できていない
* 誤VETOによる機会損失を測定する必要がある
* LLMなしとVETO適用時を同じ候補集合で比較できる

## 例外

Timeout、Provider Error、不正応答はShadow Mode中でも安全側にVETOする。

---

# DEC-016: ローカルJSONLを監査の一次記録とする

**状態:** 採用

## 理由

* AWS Telemetry障害時にも記録を残せる
* 発注経路をTelemetry成功へ依存させない
* MT5端末側で起きたイベントを先に保全できる
* 将来の再送や手動調査に利用できる

## 現在の制約

Telemetry自動再送キューは未実装である。

---

# DEC-017: CloudWatch EMFを使用する

**状態:** 採用

## 理由

* 明示的なPutMetricData呼出しを減らせる
* Lambdaの構造化ログと一緒に管理できる
* Metrics出力失敗をApplication Logicから分離しやすい

## Dimension制約

高カーディナリティ値をDimensionへ使用しない。

---

# DEC-018: CloudWatch Dashboardは既定無効とする

**状態:** 採用

## 理由

継続的な固定費を抑え、必要な環境だけ明示的に有効化するため。

---

# DEC-019: 環境をdev、staging、productionへ分離する

**状態:** 採用

## 理由

* Secretとデータを分離する
* productionへ直接変更を適用しない
* 段階的な検証とRollbackを可能にする

## 方針

productionは別AWS Accountを推奨する。

---

# DEC-020: リリースは証跡ベースとする

**状態:** 採用

## 判断

実装完了やUnit Test PASSだけではproduction承認としない。

OOS、Walk Forward、Demo、小額実口座、AWS、VPS、通知、Rollback等の証跡を必要とする。

## 理由

自動売買では、コード品質だけでなく、実市場、Broker、Cloud、運用体制を含めて安全性を判断する必要がある。

---

# DEC-021: ナンピン・Martingaleを採用しない

**状態:** 採用

## 理由

* Tail Riskが大きい
* 損失局面でExposureが増加する
* 短期的な勝率と引き換えに破綻リスクが高まる
* 本プロジェクトの安全性優先方針と一致しない

---

# DEC-022: Git履歴は今後、機能単位で分割する

**状態:** 採用

## 背景

初期実装は多くのPhaseが1つのInitial Commitへ含まれており、Git履歴からPhaseごとの意図を追跡しにくい。

## 判断

今後は、独立してレビュー可能な機能・修正単位でCommitする。

詳細は `CONTRIBUTING.md` を参照する。
