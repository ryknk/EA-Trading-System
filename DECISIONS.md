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

---

# DEC-023: 長期バックテスト用tick履歴はCustom Symbolへ投入する

**状態:** 採用

## 背景

2026-08、Strategy Testerの実市場real tick検証を進める過程で、接続先Broker（XMTrading-MT5、OANDA-Japan MT5 Demoの両方）のMT5デモ口座サーバーが、raw tickレベルの履歴を数年程度しか保持しないことが判明した（XMTradingは2022年1月以降、OANDAデモは直近約1年のみ）。2015年以降を対象にしたIn-Sample/Out-of-Sample検証には、これらのライブ接続先が持つtickキャッシュだけでは不十分である。

OANDA証券が提供するWeb版Tickダウンロードツール（`https://www.oanda.jp/trade/web/tools/tickDownload`、要ログイン）から、2016年9月以降のUSDJPY real tick（Bid/Ask付き、MT5標準のタブ区切りCSV形式）を取得できることを確認した。

## 判断

取得したCSVは、実際の`USDJPY`銘柄の履歴へ直接History Center経由でインポートせず、`CustomSymbolCreate(name, path, "USDJPY")`で仕様を複製したCustom Symbol（`USDJPY_HIST`）を作成し、専用スクリプト `mt5/Tools/ImportOandaTicks.mq5` の`CustomTicksAdd()`で投入する方式を採用する。

投入スクリプトは、MT5端末のStartUp設定（`[StartUp]` `Script=`）経由でCLIから無人実行できる形にし、`tools/link-mt5.ps1`に`Scripts\EaTradingSystemTools`のJunctionを追加した。

## 理由

* History CenterのTick Import機能はGUI操作専用（ファイル選択ダイアログ）であり、120ファイル規模の投入を自動化できない。`CustomTicksAdd()`はMQL5スクリプトから直接呼び出せるため、CLIからの無人・再現可能な実行が可能
* `CustomSymbolCreate`の`origin_name`引数で実`USDJPY`から仕様（Digits、Volume Min/Max/Step、Tick Size/Value等）を複製できるため、Broker固有仕様を再現しつつ、実データのBid/Askをそのまま使うことでヒストリカルなスプレッドも再現できる
* 実際の`USDJPY`銘柄の即時ライブ同期データを上書き・混在させるリスクを避けられる

## 検証結果

2016年9月分（825万tick）およびフル期間2016年9月〜2026年8月分（119ファイル、約8億8,097万tick、パースエラー0件）を投入し、Strategy Testerで2016年9月単月・2020年通年（月境界をまたぐ12か月連続）の両方について「ヒストリー品質100%リアルティック」を確認した（`results/backtests/oanda-hist-validation-2016-09/`、`results/backtests/oanda-hist-validation-2020/`）。

## 影響

* 今後の実市場tick検証（IS/OOS、Walk Forward等）は、Broker実銘柄`USDJPY`ではなくCustom Symbol `USDJPY_HIST`を対象に実行する
* Demo/小額実口座/Productionでの実際の発注は、引き続き実`USDJPY`銘柄・実Brokerの気配値を使用する（Custom Symbolはバックテスト専用）
* Custom Symbolの仕様は作成時点の`USDJPY`のスナップショットであり、Broker側の仕様変更（レバレッジ、Tick Value等）を自動追従しない。将来的な仕様変更時は再作成が必要

---

# DEC-024: In-Sample/Out-of-Sample/Walk Forward期間を確定する

**状態:** 採用

## 背景

DEC-023によりCustom Symbol `USDJPY_HIST`で2016年9月〜2026年8月のUSDJPY real tick履歴が利用可能になった。この範囲内で、最新期間への過学習を避けつつ、最後に完全未使用データでEAの汎化性能を確認できる期間分割が必要だった。

ユーザーからは「使用可能なOANDA公式ティックデータ: 2016-01〜2026-08」として開始日2016-01の案が示されたが、実際に投入済みの`USDJPY_HIST`データは2016年9月分からしか存在しない（DEC-023、`results/backtests/oanda-hist-validation-2016-09/`で品質検証済みの最古月）。2016-01〜2016-08分のOANDA real tickは取得していない。文書と実データの矛盾のため、本決定では実際に取得済みの2016-09を開始点として採用する。

## 判断

* 開発・In-Sample: 2016-09〜2020-12
* OOS / Walk Forward評価: 2021-01〜2024-12
* Final Holdout: 2025-01〜2026-08

Walk Forwardは、過去期間で学習・最適化し、その直後の未来期間で検証するローリング方式（4年学習→1年検証、5 Fold）とする。

| Fold | 学習期間 | 検証期間 |
| --- | --- | --- |
| 1 | 2016-09〜2019-12 | 2020 |
| 2 | 2017-01〜2020-12 | 2021 |
| 3 | 2018-01〜2021-12 | 2022 |
| 4 | 2019-01〜2022-12 | 2023 |
| 5 | 2020-01〜2023-12 | 2024 |

Fold 1の学習期間は実データが2016-09からしか存在しないため、2016年分は9〜12月の4か月のみとなる（他Foldは各年フル12か月）。

Final Holdout（2025-01〜2026-08）は、EA・MLモデル・閾値・SL/TP等のパラメータをすべて固定した後に一度だけ評価する。開発・パラメータ調整・ML閾値調整には一切使用しない。評価結果（Profit Factor、Max Drawdown、Expectancy、Sharpe、Trade Count等）がWalk Forward結果から大きく崩れていないか確認する。

## 理由

* 最新期間（2025年以降）への過学習を避け、最後に完全未使用データで汎化性能を確認する必要がある
* Walk Forwardのローリング方式により、単一固定OOS期間よりも期間依存性・安定性を確認しやすい
* `USDJPY_HIST`の実データ開始（2016-09）に合わせて期間を補正することで、存在しないデータへの依存を避ける

## 影響

* `mt5/test-config/StrategyTester-USDJPY-H1.ini`の既定Symbolを`USDJPY_HIST`、既定期間をIn-Sample期間（2016-09-01〜2020-12-31）へ変更した
* `tools/run-strategy-tester.ps1`の既定`-FromDate`/`-ToDate`も同様に変更した（誤った引数省略実行でFinal Holdout期間を消費しないための安全策）
* 実際のIS/OOS/Walk Forward/Final Holdout各期間でのStrategy Tester実行・ML学習は別途実施する（未実施、`TASKS.md` 2.1参照）
* Final Holdoutを一度評価した後にパラメータを変更した場合、新しいFinal Holdout期間の確保が必要になる（本Decisionの期間では代替がないため、その時点で再検討する）

---

# DEC-025: In-Sample開始日を2017-09-01へ補正する（DEC-024の技術的制約による修正）

**状態:** 採用

## 背景

DEC-024で確定したIn-Sample開始日（2016-09）は`USDJPY_HIST`の実データ最古日（2016-08-31、DEC-023）にほぼ一致していた。この開始日でStrategy Testerを実行したところ、対象期間全体（2016-09〜2020-12、26,882本のH1確定足）で一度も取引が発生しない異常が判明した（`results/backtests/20260816-180519-USDJPY-H1/ANOMALY-zero-trades.md`）。

原因調査の結果、Strategy Tester起動時のD1/H4インジケーター（`InpSlowEmaPeriod=200`のD1 EMA等）のウォームアップに必要な事前バッファが不足していたことが原因と確定した。テスト実行中に指標が後から回復することはなく、開始時点のバッファ量のみで成否が決まる。2026-08-16、二分探索で必要バッファ量を検証した結果は以下の通り。

| 開始日 | バッファ | 結果 |
| --- | --- | --- |
| 2017-01-01 | 約4か月 | 失敗 |
| 2017-04-01 | 約7か月 | 失敗 |
| 2017-06-01 | 約9か月 | 失敗 |
| 2017-07-01 | 約10か月 | 成功 |
| 2018-01-01 | 約16か月 | 成功 |

閾値は9〜10か月の間で確定した。

## 判断

DEC-024のIn-Sample開始日を、2016-09から**2017-09-01**へ補正する（確認済み閾値2017-07-01に安全マージン2か月を加算）。

* 開発・In-Sample: **2017-09〜2020-12**（DEC-024の2016-09〜2020-12から補正、約3年4か月）
* OOS / Walk Forward評価: 2021-01〜2024-12（DEC-024から変更なし）
* Final Holdout: 2025-01〜2026-08（DEC-024から変更なし）

`USDJPY_HIST`の2016-09〜2017-08分（約12か月）は、Strategy Tester実行時の事前ウォームアップバッファとしてのみ使用し、正式な評価対象からは除外する。

## 注意点（未解決）

DEC-024のWalk Forward Fold 1（学習2016-09〜2019-12→検証2020）の学習期間開始日も、実データ最古日に近く同様の制約を受ける可能性がある。ただしWalk Forwardの学習ステップは将来のML学習パイプライン（Python側）向けであり、rule-based Strategy（現状のCoreEA）には学習ステップが存在しないため、本Decisionでは対象外とする。ML学習パイプラインでWalk Forwardを実装する時点で、同様のバッファ制約が再現するか改めて確認する必要がある。

## 影響

* `mt5/test-config/StrategyTester-USDJPY-H1.ini`の既定`FromDate`を2016-09-01から2017-09-01へ変更した
* `tools/run-strategy-tester.ps1`の既定`-FromDate`も同様に変更した
* `results/backtests/run-metadata.template.json`の`start_date`も同様に変更した
* `docs/backtesting.md`・`TASKS.md`・`HANDOFF.md`のIn-Sample期間記載を更新した

---

# DEC-026: 過学習疑い診断はスコア方式の複数指標総合判定とする

**状態:** 採用

## 背景

DEC-024/DEC-025でIS/OOS/Walk Forward期間が確定した。今後各期間でStrategy Testerを実行した際、In-Sampleだけ良好でOOS/Walk Forwardで大きく崩れる過学習を見逃さないための自動診断が必要になった。既存の`python/analysis/performance.py`は単一期間の指標算出のみで、期間間の比較機能がなかった。

## 判断

新規`python/analysis/overfitting.py`で、IS基準の劣化率をProfit Factor・Sharpe Ratio・Expectancy・Net Profit・Max Drawdownの5指標について算出し、各指標をLOW/MODERATE/HIGH/UNKNOWN（算出不能）へ区分した上で、severityをスコア化（LOW=0、MODERATE=1、HIGH=2）して合算する。合算スコアが閾値を超えた場合のみ総合判定をMODERATE/HIGHへ引き上げる。単一指標のHIGHのみ（スコア2点）ではMODERATE止まりとし、複数指標の劣化が揃って初めてHIGHへ到達する設計とした。

IS側またはOOS/Walk Forward側いずれかの取引数が最小閾値未満の場合、算出した劣化率にかかわらず総合判定を`INSUFFICIENT_DATA`へ上書きする。Walk Forwardは各Foldを個別に比較し、Foldごとのスコア平均で総合判定する（単一Foldの外れ値だけで判定しない）。劣化率・スコア・最小取引数等の閾値はすべて`OverfittingThresholds`データクラスの既定値とし、`--thresholds-json`で上書き可能にした。Final Holdout（2025-01〜2026-08）はパラメータ調整に使わないため、本診断の入力対象から明示的に除外する。

## 理由

* 「単一指標だけで断定せず、複数指標から総合判定する」という要件を、閾値のみのif分岐ではなくスコア加算方式で機械的に満たすため
* 既存の`analyze_performance()`が出力する`performance-summary.json`をそのまま入力に再利用でき、既存の指標定義（`docs/backtesting.md` Phase 10節）との重複定義を避けられる
* 閾値のハードコード禁止（`CLAUDE.md`）に従い、実運用で受入基準が固まった後に調整できるようにする

## 影響

* 新規`python/analysis/overfitting.py`・`python/tests/test_overfitting.py`・`contracts/overfitting-report.schema.json`を追加した
* `docs/backtesting.md`に使用方法を追記した
* 実際のIS/OOS/Walk Forward各期間のStrategy Tester実行結果を用いた診断はまだ実施していない（`TASKS.md` 3.3節、実データ取得後に実施）
* 本診断はEAの内部ロジックやRisk Managerの判断には一切影響しない。診断結果はレポート出力のみで、発注可否判定へは接続していない

# DEC-027: 段階的Entry判定パイプラインは既存方式に対する加算的なオプトイン層とする

**状態:** 採用

## 背景

In-Sample期間での閾値調整（`TASKS.md` 2.1節、ADX・RSI・SL/TP比等のスイープ）は、Profit Factor 0.88〜0.89、Sharpe -1.00〜-1.02付近で頭打ちになった。ユーザーから、単一条件の閾値判定ではなく「Market Regime→HTF Bias→Setup→Entry Trigger→Entry」という段階的な判定構造への見直し依頼があった。既存の`CTrendFollowingStrategy::Evaluate()`は、実質的に同じ順序（トレンド一致→ADX/ATR/RSIフィルタ→ブレイクアウト/プルバックパターン）で判定していたが、各段階が単一関数内の逐次`if`文に埋め込まれており、(a) 各段階の合否が個別にログへ残らず、(b) 既存の`CMarketRegimeClassifier`（分析専用、DEC未記載だが2026-08-17実装）がEntry判定に一切使われていなかった。

## 判断

新規input `InpEntryUseStagedPipeline`（既定値`false`）で既存方式と段階的方式を切り替える。`false`の間は、判定式・発注挙動ともに既存方式と完全に同一とする（`IsPullback`を`IsPullbackSetup && IsPullbackTrigger`へ内部分解したが、数式は変更前と等価）。`true`にした場合のみ、`CMarketRegimeClassifier`によるMarket Regime判定（Trend/Range）を、新規input `InpEntryRequireMarketRegimeTrend`（既定値`true`）に従いEntry棄却ゲートとして追加する。既存のHTF Bias（D1/H4トレンド一致）・ADX/ATR/RSIフィルタ・Setup/Trigger（ブレイクアウト/プルバック）の判定式自体は変更しない。

各段階の合否は、`CANDIDATE`イベント（Entry成立時のみ、既存・両方式共通）と、`InpEntryUseStagedPipeline=true`時のみ毎確定足で記録する新規イベント`ENTRY_PIPELINE`へ記録する。`InpEntryUseStagedPipeline=false`（既定値）では`ENTRY_PIPELINE`イベントを記録せず、既存の監査ログ量・スキーマへ影響しない。

Market Regimeの方向性（Up/Down）とHTF Biasの方向性が食い違う場合の追加棄却条件は、本Decisionでは導入しない。`InpRegimeTrendAdxMin`と既存の`InpMinimumAdx`が既定値でともに20.0のため、既定設定では新設のMarket Regimeゲートは既存のADX下限フィルタと完全に重複し、単独では受け入れ基準（Net Profit・Profit Factor等）を変化させない（`results/backtests/20260822-171814-USDJPY-H1/`で実測確認、`ENTRY_PIPELINE`ログ上はStage別棄却件数が可視化されるが、最終的な採用/棄却集合は`InpEntryUseStagedPipeline=false`の結果と一致した）。方向性一致条件や独立した閾値设定は、固定閾値の大量追加による過剰最適化を避けるため、必要性が実データで確認できるまで見送る。

## 理由

* CLAUDE.md「既存Entryロジックを即座に削除・置換しない」「新方式をON/OFF可能、または既存方式と比較可能な構造にする」という指示を満たすため
* 既存の`CMarketRegimeClassifier`・`CTrendFollowingRules`・監査ログ基盤（`CTradeLogger`）を再利用し、重複実装を避けるため
* Look-ahead biasを避けるため、新規ロジックも既存同様、確定足（shift>=1）のみを参照する。データ構造・参照バーは変更していない
* `InpEntryUseStagedPipeline=false`が既存の全In-Sample検証結果（`TASKS.md` 2.1節の最終状態）と完全一致することを、コード変更前後のStrategy Tester再実行（同一IS期間、`results/backtests/20260822-171514-USDJPY-H1/`が変更前コード、`results/backtests/20260822-170849-USDJPY-H1/`が変更後コード、両方とも総損益-48,223円・PF0.89・Sharpe-1.10・取引数209で一致）で実証した

## 影響

* `mt5/Include/Signal/SignalResult.mqh`・`mt5/Include/Strategy/TrendFollowingRules.mqh`・`mt5/Include/Strategy/TrendFollowingStrategy.mqh`・`mt5/Include/Core/Config.mqh`・`mt5/Include/Core/EAController.mqh`・`mt5/Include/Logging/TradeLogger.mqh`・`mt5/Experts/CoreEA.mq5`を変更した
* `python/analysis/trade_breakdown.py`へ`entry_pipeline_funnel_summary()`を追加し、`ENTRY_PIPELINE`ログから段階別棄却件数を集計できるようにした。`python/analysis/reports.py`の`SUPPORTED_AUDIT_EVENTS`へ`ENTRY_PIPELINE`を追加（追加しないと`ENTRY_PIPELINE`が監査ログに含まれる場合に既存の`load_analysis_inputs`が例外を送出する）
* `contracts/trade-breakdown-report.schema.json`へ任意項目`entry_pipeline_funnel`を追加した
* 副次的に、既存の`CTradeLogRules::SafeEventType`（`mt5/Include/Logging/TradeLogger.mqh`）に`TIME_STOP_EXIT`が含まれておらず、`InpEnableTimeStop=true`でTime Stop決済が発生しても対応する`TIME_STOP_EXIT`監査イベントが一度も書き込まれていなかった既存不具合を発見し、`ENTRY_PIPELINE`追加と同じ変更で修正した（Strategy Tester実行で、修正前0件→修正後1件以上のTIME_STOP_EXITイベント記録を確認）。Python側`python/analysis/reports.py`の`SUPPORTED_AUDIT_EVENTS`は当初から`TIME_STOP_EXIT`を含んでおり、Python側は対応済みだったがMQL5側だけが書き込みを常に拒否していた
* `InpEntryUseStagedPipeline=true`にした場合の実際の収益性改善効果（Market Regime方向性一致条件の要否を含む）は未検証。OOS期間（2021-01〜2024-12）での効果検証は、DEC-024/025のIS/OOS分離方針に従い、方針が固まった上で一度だけ行う

# DEC-028: Entry Timing比較分析はプルバックのみを対象とし、実注文を伴わないShadow Tradeとして既存戦略から完全に分離実装する

**状態:** 採用

## 背景

ユーザーから、同一のEntry Setupについて「Setup成立時に即Entry」「1本待ち」「2本待ち」「Trigger成立を待つ」の4方式を比較できる分析機能の依頼があった。目的は最適な待機本数の自動探索ではなく、Entryを早める/遅らせることによる成績・MFE/MAEの変化を分析し仮説を立てられるようにすることであり、過去データへ最も適合する待機時間を自動採用する処理は明示的に禁止されている。

既存の`CTrendFollowingStrategy`はSetup（`IsPullbackSetup`）とTrigger（`IsPullbackTrigger`）を同一の`Evaluate()`呼び出し内で、タッチ足（shift=2）と確認足（shift=1）という固定1本ギャップの関係として評価しており、「Setupは成立したが任意の本数だけEntryを遅らせる」という可変の待機概念を表現できない。また、ブレイクアウトパターンは価格がレンジを突破する事象そのものがSetupとTriggerを兼ねており、両者の間に待機できる中間状態が存在しない。

## 判断

新規`CEntryTimingAnalyzer`（`mt5/Include/Logging/EntryTimingAnalyzer.mqh`）を、既存Strategy/PositionManager/RiskManager/OrderManagerから独立した自己完結モジュールとして実装する。`InpEnableEntryTimingAnalysis`（既定値`false`）で有効化し、`false`の間はIndicatorハンドルさえ作成せずコスト0とする。

対象はプルバックパターンのみとする（ブレイクアウトはSetup/Trigger間に待機できる中間状態がないため対象外、上記背景参照）。Setup検出時、そのbar自身をタッチ足とみなし（既存Strategyのタッチ足=shift2・確認足=shift1という固定ギャップとは異なる、Entry Timing比較専用の再定義）、既存の`CTrendFollowingRules::IsPullbackSetup`/`IsPullbackTrigger`/`TrendDirection`/`MomentumAllowed`をそのまま再利用しつつ、独自のIndicatorハンドル（D1/H4/H1 EMA、H1 ATR/RSI/ADX、H4 ADX）でHTF Bias・ATR/ADX/RSIゲートを独立に再評価する。実際のStrategyの状態・結果は一切参照しない（意図的な重複、下記「理由」参照）。

4方式（IMMEDIATE/WAIT_1_BAR/WAIT_2_BARS/WAIT_TRIGGER）それぞれについて、実際のSL/TP幾何（`InpStopAtrMultiple`・`InpRiskRewardRatio`と同じ計算式）でShadow Position（`MqlTradeRequest`を一切生成しない、内部状態のみ）を生成し、tick粒度でSL/TP到達・MFE/MAE・Entry後1/2/3/5/10/20本時点の価格推移（R倍数）を追跡する。損益はR倍数（Shadow Trade自身の当初SL距離を1R）で記録し、口座通貨建て損益は算出しない（Position SizingはRisk Manager管轄であり、実ポジションを伴わないShadow Tradeには適用対象がないため）。Setup成立からEntry確定までの逆行・順行（`pre_entry_mae_r`・`pre_entry_mfe_r`、到達時刻付き）も記録する。

過去データへ最も適合する待機方式を自動選択・適用する処理は実装しない。4方式は常にすべて並行記録するのみで、優劣判断はユーザーが分析結果（`python.analysis.entry_timing`）を見て行う。

## 理由

* CLAUDE.md「必要最小限の変更」「既存設計を壊さない」の原則と、実注文を一切伴わない分析専用機能という要件を両立するには、既存Strategy/PositionManagerへの侵襲的な変更（Setup/Triggerの本数可変化、複数Entry候補の並行管理）よりも、読み取り専用・自己完結な別モジュールとして実装するほうが安全性への影響がゼロであることを保証しやすい
* 既存の`CTrendFollowingRules`を再利用することで、Entry Timing比較で使われるSetup/Trigger判定式が実際のStrategyと数式レベルで一致することを保証し、二重実装による定義の乖離リスクを避ける（Indicatorハンドルの重複自体はMQL5 Terminalが同一パラメータで自動的にデデュプリケートするため計算コストの二重化にはならない）
* R倍数で損益を表現するのは、Shadow Tradeが実ポジションのVolume（Risk Manager・Position Sizingの管轄）を持たないため。口座通貨建て損益を無理に算出すると誤った精度の印象を与える
* Max Drawdownは基準値10,000Rから開始する相対指標とし、既存`python/analysis/drawdown.py`の`build_drawdown_curve`/`summarize_drawdown`をそのまま再利用した（口座残高を模した恣意的な基準値だが、Variant間の相対比較という目的には十分。当初100Rとしていたが、正式なIS期間での検証時に不具合が判明し10,000Rへ修正した。下記「影響」参照）

## 影響

* 新規`mt5/Include/Logging/EntryTimingAnalyzer.mqh`・`mt5/Tests/TestEntryTimingAnalyzer.mq5`・`mt5/test-config/TestEntryTimingAnalyzer.ini`を追加した
* `mt5/Include/Core/Config.mqh`・`mt5/Include/Core/EAController.mqh`・`mt5/Include/Logging/TradeLogger.mqh`・`mt5/Experts/CoreEA.mq5`・`tools/compile-mql5.ps1`・`tools/run-mql5-tests.ps1`を変更した
* 新規`python/analysis/entry_timing.py`・`python/tests/test_entry_timing.py`・`contracts/entry-timing-report.schema.json`を追加し、`python/analysis/reports.py`の`SUPPORTED_AUDIT_EVENTS`へ`ENTRY_TIMING_SETUP`・`ENTRY_TIMING_TRADE`を追加した（DEC-027で発見した「新規イベント型を監査ログに混在させると既存`load_analysis_inputs`が例外を送出する」既知の落とし穴を踏まえ、実装時点で追加済み）
* 実装後、6か月間（2018-01〜2018-06、`USDJPY_HIST`）のStrategy Tester実行でEntry Timing比較が実際に機能することを検証し、その過程でSetup完了イベントの`trigger_wait_bars`が実際のWAIT_TRIGGER Shadow Tradeの`wait_bars`と食い違う実装バグ（完了イベント出力が後続バーへずれる場合に、Trigger成立時点ではなく出力時点の経過バー数を誤って使っていた）を発見・修正した
* `InpEnableEntryTimingAnalysis=true`にした場合の実際の分析結果（どのVariantが優れているか）はユーザーの仮説検証に委ねる。本Decisionでは待機方式の推奨・自動選択は一切行わない
* 実装の妥当性はサンプル期間（2018-01〜2018-06）の実データで検証済みだが、正式なIS期間（2017-09〜2020-12）・OOS期間での分析はまだ実施していない
* **2026-08-22、正式なIS期間（2017-09〜2020-12）で初めて実行し、`python/analysis/entry_timing.py`の`DRAWDOWN_BASELINE_R`（当時100R）を起点に累積損益（`pnl_r`の累計）がマイナスへ落ちるとequityが0以下になり`drawdown.build_drawdown_curve`が例外を送出する不具合を発見・修正した**。Shadow TradeはMaxOpenPositions等の並行数制限を受けないためSetup数が多く（本IS期間で1,101件）、IMMEDIATE/WAIT_1_BAR/WAIT_2_BARSの累積損失がそれぞれ-99R〜-118Rに達し100Rを超過していた。相対指標という設計意図は変えず、基準値を10,000Rへ引き上げて修正した（`python/tests/test_entry_timing.py`は基準値を直接検証しておらず、修正後も7件全PASS）。この修正を経て、正式なIS期間でのVariant比較を実施した。詳細な分析結果はTASKS.md参照

---

# DEC-029: MT5実行バックエンドはHost/VM共通の薄い抽象化とし、VM接続はVMware Workstation/Player付属vmrunを既定・優先とする（WinRM/PSRemotingも選択可能）

**状態:** 採用

## 背景

Strategy Tester・MQL5単体テスト実行はいずれもホストWindows上で`terminal64.exe`を直接`Start-Process`しており、実行中にMT5 GUIがホストの対話デスクトップへ一瞬でも表示され、ユーザーの他の作業・ゲームのフォーカスを奪う問題があった。恒久対策として、MT5を隔離VM内で実行できる方式を追加する依頼があった。当初はHypervisor非依存の汎用WinRM/PSRemotingのみを想定していたが、ユーザーが実際に使用するのはローカルPC上のVMware Workstation Pro/Playerであるため、その付属CLIである`vmrun`を優先する方針へ変更した。

## 判断

`tools/run-strategy-tester.ps1`・`tools/run-mql5-tests.ps1`のどちらからも使う共通モジュール`tools/lib/Mt5ExecutionBackend.psm1`を新設し、「MT5起動・待機・タイムアウト検出・終了コード取得・VM実行時の結果ファイル同期」だけをこのモジュールへ委譲する。Report/Audit検索、CaseFile処理、PASSマーカー判定など各スクリプト固有の業務ロジックは変更しない。

`-ExecutionMode Host|VM`（既定`Host`）で切り替える。VM実行時の接続方式はVM設定ファイルの`connectionType`でさらに選択する：

* `Vmrun`（既定）— VMware Workstation/Player付属の`vmrun`コマンドラインツールを使い、VMware Tools経由でゲストOS内のプログラムを直接実行する。IPアドレスやゲスト側WinRM設定は不要で、`.vmx`パスとゲストOSのユーザー名・パスワードのみで動作する。
* `WinRm`— 汎用WinRM/PSRemoting（`New-PSSession -ComputerName`）。Hypervisor製品を問わないが、ゲスト側で事前にWinRMを有効化する必要がある。

VM接続設定は`tools/config/mt5-vm.settings.json`（`.gitignore`対象、テンプレートは`tools/config/mt5-vm.settings.example.json`）で保持し、パスワード等の秘密情報は設定ファイルへ書かず、対話入力（`Get-Credential`）または環境変数経由のみ許可する。`-ExecutionMode VM`指定時にVM設定が不足・不正な場合（`connectionType`に応じた必須フィールド不足を含む）はHostへ暗黙フォールバックせず、明確な例外で終了する。

Vmrun方式では、vmrunが`runProgramInGuest`経由でゲスト内プログラムの終了コードを直接返さないため、ゲスト内で`<exe> <args> & echo %ERRORLEVEL%><ファイル>`を実行させ、そのファイルを`copyFileFromGuestToHost`でホストへ回収する方式でExitCodeを取得する。vmrunにディレクトリ再帰コピー機能が無いため、TerminalData/InstallPath等のディレクトリ同期はゲスト内で`Compress-Archive`により圧縮したうえで単一ファイルとしてホストへ回収し展開する。タイムアウト時は`listProcessesInGuest`/`killProcessInGuest`でゲスト内プロセスを明示的に強制終了する。WinRm方式は既存どおり`Copy-Item -ToSession`/`-FromSession`でファイル転送する。

VMware VM暗号化（Encryption）が有効な場合、ゲストOSログインパスワード（`-gu`/`-gp`）とは別に、VM自体を復号するための暗号化パスワード（vmrunの`-vp`）が必要になる。この2つは全く別のパスワードであるため、VM設定ファイルへ`vmEncrypted`（既定`false`）と、それが`true`の場合の`encryptionCredentialSource`（`Prompt`/`EnvironmentVariable`、ゲスト認証の`credentialSource`と同じ考え方だがユーザー名の概念はない）を独立して追加した。`vmEncrypted=true`かつ`encryptionCredentialSource`が不足・不正な場合も、他の必須項目と同様に明確な例外で終了する。

いずれの方式でも、既存のreport/audit検索ロジック（`$searchRoots`）は変更せず、VM実行時のみステージングディレクトリを検索対象へ追加する形で対応する。

## 理由

* ユーザーが実際に使用する環境がローカルPC上のVMware Workstation Pro/Playerであるため、そのVM専用のゲスト内直接実行手段である`vmrun`を既定・優先とした。IPアドレス割当やゲスト側WinRM設定が不要になり、個人利用のローカルVM構成に適する
* 一方で「VM製品をコードへ強く固定しない」という当初要求も維持するため、`connectionType`で接続方式を選べる設計とし、WinRM/PSRemoting実装は削除せず残した。将来的に別の隔離実行方式（別Hypervisor、コンテナ等）を追加する場合も、共通モジュールへ新しい接続実装を追加し`connectionType`の選択肢を増やすだけで済む
* Strategy Tester/MQL5単体テストのどちらも「起動・待機・タイムアウト・終了コード取得」というMT5起動処理自体は同一であり、これを共通化することで重複実装を避けつつ、各スクリプト固有の業務ロジック（report/audit検索、CaseFile、PASSマーカー判定）には触れない設計とした
* VM設定不備時にHostへ自動フォールバックさせると、ユーザーが意図せずホストGUIで実行してしまう（今回解決したい問題が再発する）ため、明確なエラーで停止する設計とした
* 秘密情報をリポジトリ・設定ファイルへ保存しないというCLAUDE.md/DECISIONS.mdの既存方針を維持するため、資格情報は対話入力または環境変数経由のみとした。ただしvmrunの`-gp`（ゲストパスワード）・`-vp`（VM暗号化パスワード）オプションはコマンドライン引数として渡す必要があり、実行中は同一ホスト上の他プロセスから一時的にプロセスの起動コマンドラインとして見える可能性がある。これはvmrun自体の仕様上の制約であり、ログ・例外メッセージへの出力はマスキングして防いでいるが、完全な排除はできないためユーザーへ明示する
* VM暗号化パスワードをWindows資格情報マネージャーから直接読み出すコードは実装しなかった。ユーザー自身の環境であっても、資格情報ストアから認証情報を復号・抽出する処理は認証情報窃取ツールと外形的に区別しづらく、安全側に倒して見送った。ユーザーには代わりにVMware Workstation自身のGUI機能（暗号化パスワードの変更）で、自分が管理できる値へ設定し直すことを案内した

## 影響

* 新規`tools/lib/Mt5ExecutionBackend.psm1`・`tools/config/mt5-vm.settings.example.json`・`tools/test-mt5-execution-backend.ps1`を追加した
* `tools/run-strategy-tester.ps1`・`tools/run-mql5-tests.ps1`・`.gitignore`・`docs/mt5-development.md`・`TASKS.md`を変更した
* `-ExecutionMode`省略時（既定`Host`）は既存呼び出しと完全互換に動作することを、Hostモードでの単体実行・CaseFile複数ケース実行・MQL5単体テスト実行で確認済み
* **2026-09-06、実VMware VM（VMware Workstation Pro、Windows 11ゲスト）で実機検証を行い、Vmrun方式の実装に3件の不具合を発見・修正した：**
  1. `runProgramInGuest`で`cmd.exe`を**引数付きで**実行すると、ゲストプログラム自身は正常終了しているにもかかわらずvmrunが一律`exit code 1`を報告する既知の問題を確認した（`cmd.exe /c dir`単体でも再現、引数なしの`cmd.exe`単体や`ipconfig.exe`等の直接実行は成功する）。回避策として、MT5起動・ExitCode取得ロジックをcmd.exe経由から`powershell.exe -NoProfile -Command`経由（`Start-Process -PassThru` + `WaitForExit`でタイムアウト制御し、ExitCodeまたは`"TIMEOUT"`をファイルへ書き出す方式）へ全面的に置き換えた
  2. `copyFileFromGuestToHost`が`..`を含む相対パス要素を解決できず失敗することを確認した（Compress-Archive自体は成功していたが、その結果ファイルの回収が失敗していた）。同期対象ディレクトリの親パスを`Split-Path -Parent`で事前に正規化してから使うよう修正した
  3. ゲスト内で実行するPowerShellコマンド文字列で`if (...) { A } else { B } | Set-Content ...`という構文を使うと、パイプがif式全体ではなく最後の分岐にのみ適用され機能しないことを確認した（`Get-Mt5VmRemoteLineCount`）。`$(if (...) {...} else {...}) | Set-Content ...`とサブ式化して修正した
* 上記修正後、実VM上で以下を実機確認済み: VM暗号化パスワード付きVM起動、ゲスト認証（vmrun `-gu`/`-gp`/`-vp`）、`Invoke-Mt5Execution`のVM実行によるExitCode取得（0・非0いずれも）、タイムアウト時のゲストプロセス強制終了、`Compress-Archive`方式によるディレクトリ同期、リモートファイルの行数取得
* 実機検証はMT5未インストールのVM上で、`vmExecutablePath`を`cmd.exe`等の汎用コマンドに差し替えて実施した（共通実行バックエンドの起動・待機・ExitCode取得・タイムアウト・同期ロジックの検証が目的）
* **2026-09-06、VM内にOANDA証券MT5をインストール後、実際のMT5（MQL5単体テスト・Strategy Tester）でのフル動作確認を実施し、さらに4件の不具合を発見・修正した：**
  1. `Start-Process -RedirectStandardOutput/-RedirectStandardError`経由で`$process.ExitCode`を読み取ると、引数が長い・複雑なvmrun呼び出しで不定に空文字列/nullになる不具合を確認した（Windows PowerShell 5.1、.NET Frameworkでの既知の癖）。`System.Diagnostics.Process`を直接使い、`BeginOutputReadLine`/`BeginErrorReadLine`による非同期イベント読み取り（.NET推奨パターン）へ`Invoke-VmrunCommand`を全面書き換えた
  2. その書き換えで`ProcessStartInfo.ArgumentList`を使ったところ、実際の運用環境（Windows PowerShell 5.1、.NET Framework）には同プロパティが存在しない（.NET Core専用）ことが判明した（このセッションの対話環境がPowerShell 7/.NET Coreだったため当初のテストでは検出できなかった）。Win32の`CommandLineToArgvW`互換エスケープを自前実装し、Framework/Core双方で確実に動く`Arguments`（単一文字列）方式に統一した
  3. `Copy-Mt5VmrunPathsToStaging`が要素数1の配列を`return`する際、PowerShellがスカラーへ自動アンラップし、呼び出し側の`$stagingRoots[0]`が文字列の先頭1文字になる不具合を確認した。`return , $stagingRoots`と`,`演算子で配列化を強制して修正した
  4. VM内のTerminalDataフォルダ全体（実測761MB、うち`bases`＝tickヒストリカルデータが709MB）を無条件に同期しようとして`Compress-Archive`/`copyFileFromGuestToHost`がタイムアウトする問題を確認した。Strategy Testerのreport/audit生成物はTerminalData直下やTester配下に留まりヒストリカルデータは不要なため、同期時に除外するトップレベル名（VM設定`vmSyncExcludeNames`、既定`@("bases")`）とタイムアウト秒数（`vmSyncTimeoutSeconds`、既定300秒）を設定可能にした
* また、VM側の電源設定（ディスプレイ・スタンバイのタイムアウト）を無効化する必要があることが分かった。有効なままだと実行中にVMがスリープし、vmrunコマンドが原因不明のエラーで間欠的に失敗する（`docs/mt5-development.md`に事前準備手順として追記）
* 上記修正後、VM内にコンパイル済みEA・テストスクリプトを配置した状態で、`run-mql5-tests.ps1 -ExecutionMode VM`（全12テストPASS、Hostモードと同一結果）・`run-strategy-tester.ps1 -ExecutionMode VM`（`exit=0`、report/pngが正しくホスト側へ回収される）の両方が実機で成功することを確認した。Hostモードの回帰（単体実行・MQL5単体テスト）も再確認済み
* WinRm方式は今回未検証のまま（ユーザー環境がVMware Workstationのため）

---

# DEC-030: 監査JSONLはFILE_COMMON・Run ID単位のファイル名で保存する（Strategy Tester Agentサンドボックスのcleanupに影響されないようにする）

**状態:** 採用

## 背景

DEC-029でVM/vmrun実行のフル動作確認を行った際、`InpAuditFileEnabled`を有効にした監査JSONL回収は未検証のまま残っていた（TASKS.md 8.1節）。検証にあたり原因を調査したところ、次の設計上の問題が判明した。

* `CTradeLogger`（`mt5/Include/Logging/TradeLogger.mqh`）は通常の`FileOpen()`（`FILE_COMMON`なし）を使っており、監査JSONLはサンドボックス化された`<data folder>\MQL5\Files\EaTradingSystem\Audit`（Strategy Tester実行時はTester Agent固有のサンドボックス配下）に保存される。
* `tools/run-strategy-tester.ps1`のVM実行モードは、MT5終了後にTerminalData等をディレクトリごとzip化してホストへ回収する設計（DEC-029）だが、Tester Agentのサンドボックスは（ローカルAgentの実装上）MT5終了後にcleanupされるため、回収時点では既に監査JSONLが消えている。HTM reportはTerminalData直下（サンドボックスの外）に生成されるため正常に回収できており、この非対称性がHostモードでは表面化しにくく気づかれていなかった。
* 加えて、従来のファイル名は日付単位（`audit-YYYYMMDD.jsonl`）で複数実行が同一ファイルへ追記される設計だったため、`run-strategy-tester.ps1`は各実行前に既存の`audit-*.jsonl`を削除する事前クリーンアップを行っていた（2026-08-22追加）。この削除ロジックは日付単位の共有ファイルを前提にしており、後述のFILE_COMMON化で複数ターミナル・複数実行がCommonフォルダを共有するようになると、他の実行のログを誤って削除するリスクが生じる。

## 判断

1. **監査JSONLの保存先を`FILE_COMMON`へ変更する。** `TradeLogger.mqh`の`FileOpen()`・`FolderCreate()`へ`FILE_COMMON`フラグを追加し、`Terminal\Common\Files\<InpAuditLogDirectory>`（Strategy Tester Agentのサンドボックスの外）へ保存する。Host/VM/Strategy Tester/MQL5単体テストいずれで実行しても同じ実装を使う。
2. **ファイル名をRun ID単位にする。** `SEaConfig`・EA input（`InpAuditRunId`、既定空文字）を追加し、`CTradeLogger::FileName()`は`audit_run_id`が非空なら`audit-<run_id>.jsonl`、空（既定値、通常運用）なら従来どおり`audit-YYYYMMDD.jsonl`にフォールバックする。Run IDには新しいID生成基盤を追加せず、`tools/run-strategy-tester.ps1`が既に生成している実行単位の識別子（単体実行・CaseFileいずれもReport名`$ReportName`と同一の値）をそのまま`InpAuditRunId`として渡す。ファイル名がWindowsのファイル名として安全な文字集合（英数字・`.`・`_`・`-`）であることを`ValidateConfig`で検証し、`:`（ドライブ区切りとの混同を避ける）や`/`\`\`は許可しない。
3. **VM実行時、Common配下のAuditディレクトリだけを追加で同期する。** `tools/lib/Mt5ExecutionBackend.psm1`へ`Get-Mt5VmCommonAuditPath`を追加し、VM設定`vmCommonDataPath`（省略時は`vmTerminalData`の兄弟フォルダ`Terminal\Common`を自動導出）から同期元パスを算出する。既存の汎用ディレクトリ同期関数（`Copy-Mt5VmrunPathsToStaging`/`Copy-Mt5VmPathsToStaging`、vmrun/WinRm共通）へ同期元パスとして追加するだけで、vmrun/WinRmいずれでも動作する。Commonフォルダ全体ではなくAuditディレクトリのみを同期対象にする（Commonフォルダは他の用途のデータも置かれ得るため）。
4. **実行前の`audit-*.jsonl`削除処理は廃止する。** ファイル名がRun ID単位で一意になったため、日付単位の共有ファイルを前提にした事前削除は不要になった。むしろFILE_COMMON化後に残すと、Commonフォルダを共有する他の実行・他ターミナルのログを誤って削除するリスクがあるため、廃止した。
5. **監査JSONLの検索をワイルドカードから完全一致へ変更する。** `tools/run-strategy-tester.ps1`は、report検索と同様に`audit-*.jsonl`＋パス部分一致でファイルを探していたが、ファイル名がRun ID単位で一意になったことを利用し、`audit-<ReportName>.jsonl`という完全一致（拡張子込み、ワイルドカードなし）で検索するよう変更した。VM同期後のステージングフォルダ名はソースパスをスラッシュ置換した名前になり元のディレクトリ構造（`\EaTradingSystem\Audit\`）を保持しないため、パス部分一致方式のままではVM同期後のファイルを発見できない問題も同時に解消した。
6. **既存のベストエフォート仕様は維持する。** 監査JSONLが見つからない場合でもStrategy Tester自体の成功判定には影響させない（従来どおり）。ただしVM実行時は`STRATEGY_TESTER_AUDIT_COPIED`/`STRATEGY_TESTER_AUDIT_NOT_FOUND`ログへ`mode=VM`を含めて明示する。

## 理由

* FILE_COMMONはMQL5標準機能であり、Tester Agentのサンドボックスという「MT5終了時にcleanupされ得る一時領域」の外にあるため、根本原因（サンドボックスの外へ出す）を修正できる。回避策（VM終了前に非同期でファイルを吸い出す等）は複雑さの割に確実性が低いため採用しなかった
* Run ID単位のファイル名は、既存のreport命名（`ReportName`）をそのまま再利用でき、新しいID生成基盤を追加する必要がない。Report名は既に実行・ケースごとに一意であることが保証されている（`run-strategy-tester.ps1`が生成時に重複チェック済み）
* ファイル名を実行単位で一意にすることで、「実行前に削除」という前提の脆いクリーンアップ処理が不要になり、FILE_COMMON化で顕在化する「他の実行のログを誤って削除するリスク」も同時に解消できる
* 監査JSONL検索を完全一致にすることで、VM同期後のステージングディレクトリ名がパス構造を保持しない問題を、新たな特殊ケース分岐を追加せずに解消できる
* Common領域は同一Windowsユーザーの全MT5ターミナルで共有されるため、複数ブローカーのターミナルを併用する環境では監査ディレクトリが混在し得るが、ファイル名がRun ID単位で一意なため実害はない
* 通常運用（Live/Demo、`InpAuditRunId`未設定）ではファイル名を従来どおり日付単位のままとし、既存の運用・分析手順（日別JSONLの複数ファイル読み込み）に影響を与えない設計とした

## 影響

* 変更: `mt5/Include/Core/Config.mqh`（`audit_run_id`フィールド追加・検証）、`mt5/Experts/CoreEA.mq5`（`InpAuditRunId`追加）、`mt5/Include/Logging/TradeLogger.mqh`（`FILE_COMMON`・Run ID単位ファイル名）、`mt5/Tests/TestProductionSafetyRules.mq5`（`audit_run_id`検証のテスト追加）、`tools/lib/Mt5ExecutionBackend.psm1`（`Get-Mt5VmCommonAuditPath`追加）、`tools/run-strategy-tester.ps1`（`InpAuditRunId`設定、Common Audit同期、検索を完全一致へ変更、事前削除処理の廃止）、`tools/config/mt5-vm.settings.example.json`（`vmCommonDataPath`追加）、`tools/test-mt5-execution-backend.ps1`（`Get-Mt5VmCommonAuditPath`のユニットテスト追加）
* `run-mql5-tests.ps1`は監査ログを扱わないため変更なし
* **2026-09-07、Hostモードで実機確認した。** `.\tools\compile-mql5.ps1`（全対象0 errors, 0 warnings）、`.\tools\run-mql5-tests.ps1`（全12テストPASS、`TestProductionSafetyRules`の新規`audit_run_id`検証を含む）、`.\tools\run-strategy-tester.ps1`（1ヶ月分の短期間実行、`exit=0`、`STRATEGY_TESTER_AUDIT_COPIED`で`Terminal\Common\Files\EaTradingSystem\Audit\audit-<ReportName>.jsonl`が`results/backtests/<run>/audit/`へ正しく複製されることを確認）、複製したJSONLを`python.analysis.reports`へ渡して正常に分析できることを確認した
* **2026-09-07、実VM（`D:\VMware\MT5-Tester\MT5-Tester.vmx`、vmrun経由）でVM/vmrun側も実機確認した。** VM側の`mt5`ソースコピーが本セッションの変更前のままだったため、変更した4ファイルを`copyFileFromHostToGuest`で転送し全13ターゲットを再コンパイル（0 errors, 0 warnings）した上で、`run-mql5-tests.ps1 -ExecutionMode VM`（全12テストPASS）・`run-strategy-tester.ps1 -ExecutionMode VM`（`exit=0`、`STRATEGY_TESTER_AUDIT_COPIED mode=VM`）を実行し、`Get-Mt5VmCommonAuditPath`が導出した同期先から監査JSONLが正しく回収され`results/backtests/<run>/audit/`へ複製されること、`python.analysis.reports`で正常に分析できることを確認した。TASKS.md 8.1節の該当項目は完了とした。`connectionType: "WinRm"`側は今回も未検証のまま
* **上記VM実機確認の過程で新たな制約を発見した。** VMゲストのPowerShell実行ポリシーが`Restricted`の場合、`runProgramInGuest`経由での`.ps1`スクリプトファイル実行（`-File`・`&`によるスクリプト呼び出し・`.`によるdot-source）はいずれもサイレントに失敗し、vmrunは具体的な原因を示さない汎用的な`exit=1`のみを返す（原因特定に切り分けの手間を要した）。一方、`-Command`のインラインcmdlet呼び出しや`Start-Process`によるプロセス起動（本モジュールの既存実装が使っている方式）は制約を受けない。この制約は今回の一時的な検証用スクリプト実行（VMへのソース転送・再コンパイル）でのみ踏んだものであり、`tools/lib/Mt5ExecutionBackend.psm1`の既存実装（`Invoke-Mt5ExecutionVmrun`等）は元々`-Command`＋`Start-Process`方式のみを使っているため影響を受けない。今後ゲスト側で`.ps1`ファイルを直接実行する処理を追加する場合は`-ExecutionPolicy Bypass`が必要になる点を`docs/mt5-development.md`に記録した
* 通常運用（Live/Demo）の監査ログ保存先が`MQL5\Files`から`Common\Files`へ変わる。Demo/実口座運用時にAudit JSONLを手動で確認する際は保存先の変更に注意が必要（`docs/configuration.md`参照）

---


# DEC-031: Host実行はterminal64.exeを非表示デスクトップ（CreateDesktopEx）経由で起動し、画面表示・フォーカス奪取を防止する

**状態:** 採用（旧DEC-031〜041を統合・置き換え）

## 背景

`-WindowStyle Hidden`はterminal64.exe（GUIサブシステムアプリ）には効かず、Host実行時に画面表示・フォーカス奪取が発生する（`STARTUPINFO.wShowWindow`は表示状態の「ヒント」に過ぎず、アプリ側が独自の表示ロジックで無視できるため）。対策として次の3方式を段階的に試行した。

1. **CreateDesktop（標準API）による非表示デスクトップ経由起動。** 実行のたびにデスクトップを作り捨てる実装では、80ケースバッチの4ケース目からterminal64.exeがGUI初期化の初期段階でハングした。デスクトップの使い回し（プロセス生存期間中1つを再利用）で緩和を試みたが、Windows再起動直後（デスクトップヒープが確実にリセットされた状態）の1回目の実行から同じ症状が再現し、蓄積型のリソース枯渇ではなく構造的な相性問題があると判断してこの方式は放棄した。
2. **タスクスケジューラ（S4Uログオン）経由の非対話セッション実行。** CreateDesktop方式の代替として、terminal64.exeを非対話セッションで起動する方式へ切り替えた。タスクの新規登録には管理者権限が必要だが既存タスクの起動は通常権限で可能という非対称性を利用し、固定タスクを事前登録して日常実行から管理者権限を排除した。実機の80ケースバッチで運用したところ、次の問題が段階的に見つかった。
   - タイムアウト時、別ログオンセッションで起動された子プロセスを直接終了できず、後続ケースが「起動中のMetaTrader 5を終了してください」で連鎖的に失敗する（ランナー自身に協調的に子プロセスを終了させるキャンセルファイル方式で対処）
   - `ShutdownTerminal=1`のまま実行するとreport（.htm/.png）・監査JSONLの生成処理が完了する前にterminal64.exeの自動終了処理が先に完了してしまうレースコンディションがあり、reportが生成されない失敗が散発する（ShutdownTerminalを無効化し、ランナーがreport出現を検知してから能動的に終了させる方式で対処）
   - 上記対処後も、後処理段階（"cannot open tester chart"エラーを伴う）でハングし900秒タイムアウトする別の失敗が80件中13件（16.25%）残った

   P/Invoke（`GetProcessWindowStation`・`GetUserObjectInformation`）でterminal64.exeのウィンドウステーション情報を直接取得したところ、S4Uログオンは常にSession 0（Windowsサービス専用の隔離セッション、Microsoftが公式にGUIアプリの実行には適さないと明言する環境）で動作しており、上記いずれの失敗もこの構造的制約に起因すると判明した。
3. **CreateDesktopEx（ヒープサイズ明示指定）による再評価。** 対話セッション（Session 1、WinSta0）内で動作するCreateDesktop方式はSession 0の制約を受けないはずだが、実機のレジストリ確認（`HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\SubSystems\Windows`の`SharedSection`パラメータ、実機値`1024,20480,768`）で、標準の`CreateDesktop` APIが対話的なウィンドウステーション内であっても既定では非対話用の小さいデスクトップヒープサイズ（768KB、対話デスクトップ用20480KB=20MBの約1/27）しか割り当てないというWindowsの既知の仕様が判明した。これはterminal64.exeのような大規模GUIアプリには明らかに容量不足であり、1.の「再起動直後の初回実行から一貫して失敗する」という観察と正確に整合する。拡張版の`CreateDesktopEx`（`ulHeapSize`パラメータでヒープサイズを明示指定できる）へ置き換え、対話デスクトップと同等以上の32768KB(32MB)を指定したところ、単体実行・連続実行（9回）・80ケースバッチスイープ（`succeeded=80 failed=0`）のいずれも安定して完走することを実機確認した。

## 判断

Host実行（`Invoke-Mt5ExecutionHost`、既定`UseIsolatedSession=true`）は、対話セッション（Session 1）内にCreateDesktopEx（`ulHeapSize=32768`KB）で非表示デスクトップを作成し、その上でCreateProcessする方式に統一する。

1. `tools/lib/Mt5ExecutionBackend.psm1`にP/Invokeラッパー（`Mt5ExecutionBackend.HiddenDesktopLauncher`、`CreateDesktopEx`/`CloseDesktop`/`CreateProcess`/`WaitForSingleObject`/`GetExitCodeProcess`/`TerminateProcess`）を実装した。コマンドライン文字列の構築には既存の`ConvertTo-Mt5Win32CommandLine`（Vmrun経路で使用していたWin32互換エスケープ関数）を再利用する。
2. 非表示デスクトップはモジュールインポート時から1つを使い回し（実行のたびに作り捨てない）、`Get-Mt5HiddenDesktopName`でキャッシュする。同一セッション内実行のため、タイムアウト時は別セッション協調機構を必要とせず、直接`TerminateProcess`で終了できる。
3. `UseIsolatedSession=false`を指定した場合のみ、非表示デスクトップを使わず従来の`-WindowStyle Hidden`方式にフォールバックできる（画面表示は発生するが動作実績のある退避手段として維持する）。
4. タスクスケジューラ経由の非対話セッション実行（試行2.の実装一式：`Invoke-Mt5ExecutionHostViaScheduledTask`、`tools/lib/Mt5ScheduledTaskRunner.ps1`、`tools/setup-mt5-scheduled-task.ps1`、関連する方式選択パラメータ`HostIsolationMode`等）は、Session 0というGUIアプリに構造的に不適な環境で動作しており、発見した2種類の不具合（report未生成のレースコンディション、後処理段階のハング）の根本原因だったため、コードごと削除した。選択肢が実質CreateDesktopEx方式のみになった時点で、方式選択用のパラメータを残す理由もないため併せて削除した。
5. `ShutdownTerminal`の動的無効化（試行2.でのみ必要だったレースコンディション対策）は不要になったため削除し、テンプレートの設定値（`ShutdownTerminal=1`）のまま実行する。

## 理由

* 対話セッション内での実行はSession 0の構造的制約を受けないため、タスクスケジューラ方式で発見した2種類の不具合（report未生成・後処理ハング）をヒープサイズの問題さえ解消すれば回避できる
* 同一セッション内実行により、別セッションのプロセスを直接終了できないための複雑な協調機構（キャンセルファイル方式）が不要になり、実装がシンプルになる
* 管理者権限や事前セットアップ（タスク登録）が不要になり、運用上の手間が減る
* ネイティブハンドルに対して直接`WaitForSingleObject`/`GetExitCodeProcess`を使うことで、.NET`Process.GetProcessById`のPID再利用によるレースコンディションを避けられる
* 選択肢が実質1つになった時点で方式選択用のパラメータ・不要になった対策コードを残す理由がなく、削除する方がコードの見通しが良い

## 影響

* 追加: `tools/lib/Mt5ExecutionBackend.psm1`（`HiddenDesktopLauncher`のC#実装、`Get-Mt5HiddenDesktopName`、`Invoke-Mt5ExecutionHostViaHiddenDesktop`）
* 削除: `tools/lib/Mt5ScheduledTaskRunner.ps1`、`tools/setup-mt5-scheduled-task.ps1`、タスクスケジューラ経由実行の関連コード一式（`Invoke-Mt5ExecutionHostViaScheduledTask`と付随する`$script:`変数・ヘルパー関数）
* 変更: `Invoke-Mt5ExecutionHost`・`Invoke-Mt5Execution`（方式選択パラメータを削除し常にCreateDesktopEx方式を使用）、`tools/run-strategy-tester.ps1`・`tools/run-mql5-tests.ps1`（`-HostIsolationMode`パラメータ削除、ShutdownTerminal動的無効化ロジック削除）、`tools/test-mt5-execution-backend.ps1`（タスク登録確認によるスキップ分岐を削除し常時実行するテストへ変更）、`docs/mt5-development.md`（初回セットアップ手順の削除）
* 実機検証: 単体実行・連続実行（9回）・80ケースバッチスイープ（`STRATEGY_TESTER_BATCH_COMPLETED total=80 succeeded=80 failed=0`、エラー・例外ログ0件）のいずれも、画面表示・フォーカス奪取・タイムアウト・report未生成のいずれも発生せず完走することを確認した（2026-09-08〜12）
* `HostUseIsolatedSession=$false`（従来の`-WindowStyle Hidden`方式へのフォールバック）は変更せず維持している
* 既存のタスクスケジューラ上に登録済みの固定タスク`Mt5HostIsolatedRunner`はコードから参照されなくなったが、削除は本対応の範囲外とした（不要になったタスクの削除はユーザー判断で行う）

---

# DEC-032: トレンド継続反転Exitは既存Exitと独立した状態・判断ロジックを持つ加算的なオプトイン層とする

**状態:** 採用

## 背景

OOS分析（`python.analysis.trade_breakdown`、TASKS.md 2.1.3節）で、トレンド戦略の負けトレードの90〜100%が一度含み益（MFE>0）に達してからSLへ到達しており、Peak後の逆行幅（中央値-1.1R）がPeak到達時の含み益（中央値0.18R）自体より常に大きいことが判明した。既存のExit機構（建値ストップ・ATRトレーリングストップ）はいずれもSLを「動かす」方式であり、Fold1-5・4銘柄の再検証でも反転発生率自体（94〜95%）はパラメータを変えても解消できないことが確認済みだった（TASKS.md 2.1.3節）。2026-09-06時点で「Peakでの早期利確・建値ストップの早期化が有効な対策候補」と示唆されていたが未検証のまま残っていた。

## 判断

1. **既存のCTimeStopTracker・CRangeExitGraceTrackerを拡張・流用せず、独立した`CTrendReversalTracker`・`CTrendReversalExitRules`を新設する**（`mt5/Include/Trading/PositionManager.mqh`）。CTimeStopTrackerは`enable_time_stop`のライフサイクルに結び付いており、Trend Reversal Exitを独立した`enable_trend_reversal_exit`で有効・無効化する設計（既存Exitと組み合わせを自由に選べる）とは相容れない。CMeanReversionStrategyが独自の`CRangeExitGraceTracker`を持つのと同じ理由（目的も判定基準も異なる状態を、既存トラッカーへの追記ではなく別クラスとして分離する）を踏襲した。
2. **反転検知の継続確認はTick数（`InpTrendReversalConfirmationTicks`）とし、実時間秒数（レンジ戦略の`InpMeanReversionBreakConfirmSeconds`と同じ方式）は採用しない。** 建値ストップ・ATRトレーリング・Time Stop（MFEピーク追跡）がいずれも「価格ベースのPeak追跡」を採用しており、Tick数はこれらと同じ粒度で統一でき、実装・テストの両面でシンプルになる。反転検知自体は「Peakから何R逆行したか」という価格ベースの条件であり、継続確認だけを秒数にする理由はないと判断した。
3. **Activation判定（`IsActivated`）はCTimeStopRules::HasReachedMinMfeRをそのまま再利用する。** 「建値〜当初SL距離＝初期リスク」をR単位の基準とする計算はTime Stopの最低MFE判定と完全に同一の数式であり、重複実装を避けた。
4. **トレンド判定は`CMarketRegimeClassifier`の現在値をライブに問い合わせる新規メソッド`CTrendFollowingStrategy::CurrentMarketRegimeTrend()`を追加し、既存の`CANDIDATE`イベント記録用の判定（Evaluate()内、Entry時点固定）とは別に評価する。** 保有中ポジションの継続監視には毎Tickでの最新レジーム判定が必要であり、Entry時点で固定されるCANDIDATEの`market_regime_trend`を使い回すことはできない。既存のH1 ADX/EMA(Fast)ハンドルとregime_*設定をそのまま再利用し、新規Indicatorは追加しない。
5. **SLは動かさず、市場成行での早期決済のみとする。** 既存のSL/TP・Risk Manager・Position Managerとの責務境界を変えず、`CloseOnTrendReversal`を`CloseOnTimeStop`/`CloseOnSignalInvalidation`と同じ冪等性パターン（専用GlobalVariableキー接頭辞）で独立したメカニズムとして追加した。
6. **既定値はOFF（`InpEnableTrendReversalExit=false`）とし、Activation/Retrace/Confirmationのいずれも「最適値」を決め打ちしない。** Baseline（false）とON（true）のバックテスト結果を比較する運用を前提とし、Strategy Testerによる比較検証は本Decisionの実装範囲に含めない（TASKS.md 2.1.3節に次の一手として記録）。

## 理由

* 独立したトラッカーにすることで、既存Exit（Time Stop・建値ストップ・ATRトレーリング・シグナル失効Exit）のON/OFF状態に関わらず、Trend Reversal Exit単体の効果をBaseline比較で切り分けられる。
* Tick単位の継続確認は、既存のPeak追跡（CTimeStopTracker、TradeAnalyticsTracker）と同じ「毎Tick更新」の粒度に統一され、実装・単体テストの一貫性を保てる。
* ライブなレジーム再問い合わせにより、レジームがRange/Unknownへ変わった保有ポジションでは自動的に監視状態を破棄でき（false-safe）、Range相場でのトレンド戦略ポジション（信号失効Exit等の既存機構が対応する既存ケース）への誤発動を避けられる。
* SLを動かさない設計により、Risk Manager・既存のSL/TP契約・Position Managerの責務境界を一切変更せずに済み、レビュー・ロールバックの範囲を最小化できる。

## 影響

* 追加: `mt5/Include/Trading/PositionManager.mqh`（`CTrendReversalExitRules`・`CTrendReversalTracker`・`CloseOnTrendReversal`）、`mt5/Include/Trading/PositionExitEvaluator.mqh`（`EvaluateTrendReversalExits`）、`mt5/Include/Strategy/TrendFollowingStrategy.mqh`（`CurrentMarketRegimeTrend`）
* 変更: `mt5/Include/Core/Config.mqh`・`mt5/Experts/CoreEA.mq5`（設定4件）、`mt5/Include/Core/EAController.mqh`（OnTick呼び出し追加）、`mt5/Include/Logging/TradeLogger.mqh`・`python/analysis/reports.py`（新規イベント`TREND_REVERSAL_EXIT`許可リスト追加）、`python/analysis/trade_breakdown.py`（`trend_reversal_exit_summary`）、`contracts/trade-breakdown-report.schema.json`
* MQL5コンパイル（13ターゲット、0 errors/0 warnings）・全12 Script Test PASS、Pythonテスト70件PASS確認済み（2026-09-12）。Strategy TesterによるBaseline/ON比較・OOS/Final Holdoutでの効果検証は未実施（NOT VERIFIED、TASKS.md 2.1.3節参照）。


# DEC-033: 非FX資産のCustom Symbolは実Symbolを複製せず手動で仕様を設定し、証拠金計算はCFDモードを使う

**状態:** 採用（JP225_HIST・US30_HIST・XAUUSD_HISTの3銘柄とも適用・EA動作確認済み、2026-09-19）

## 背景

DEC-023のCustom Symbol方式を、他資産クラス（JP225・US30・XAUUSD）の追加測定へ流用した（TASKS.md 2.1.4節 追加分析3）。現行EAを同一パラメータのまま実行しても取引が1件も成立しなかった。切り分けの結果（2026-09-19）、EA側の不具合ではなく、Custom Symbolの仕様が未設定であることが原因と確定した。

* 接続先Broker（OANDA-Japan MT5 Demo）の全51銘柄はFXのみで、JP225・US30・XAUUSDの実Symbolが存在しない。複製元がないままCustom Symbolを作成したため、仕様が初期値のままになっていた（Digits=4、Point=0.0001、契約サイズ=100000、Volume Min/Max/Step=1e-8/1e-7/1e-8、利益通貨が銘柄名の切れ端`25_`等）。複製元に指定した銘柄名は、当時のログが残っておらず未確認。
* JP225・US30の`TICK_VALUE_UNAVAILABLE`: 利益通貨が不正で`OrderCalcProfit`が損益0を返し、フォールバックもTickValue=0のため。
* XAUUSDの`RISK_STATE_UNAVAILABLE`（reasonは`INVALID_EXPOSURE_INPUT`、`RiskManager.mqh:176`経由の`ExposureGuard.mqh:51`）: 契約サイズ100000のまま1ロット損失が約3.1億円となり、ロットがVolume Max（1e-7）に張り付いた。`PositionSizer::VolumeDigits(1e-8)`が0桁を返し、`NormalizeDouble`で0になったまま`Calculate()`がtrueを返すためと推定（コード解析による推定、volume=0だったことは監査ログのreasonで確認）。
* `SPREAD_TOO_WIDE`: 実スプレッドの超過ではなく、Point定義の誤り（実際のスプレッドはJP225約6円、XAUUSD約0.3〜5ドル程度）。

## 判断

1. **非FX資産のCustom Symbolは、OANDA証券の公開仕様（`https://www.oanda.jp/indices/lineup`、`https://www.oanda.jp/commodity/lineup`）に基づき、`mt5/Tools/ApplyCfdSymbolSpec.mq5`で明示的に仕様を設定する。** 設定項目はDigits、Tick Size、契約サイズ、Volume Min/Step/Max、通貨、CalcMode、証拠金率。Tick Valueは設定せず、Testerの自動計算に任せる（実Symbol複製で正常動作している`EURUSD_HIST`等と同じ扱い）。
2. **CalcModeはCFD（`SYMBOL_CALC_MODE_CFD`）とする。** 実験（`mt5/Tools/MarginExperimentSymbols.mq5`で作成した複製銘柄）で、Tester内の証拠金計算が次のとおりであることを確認した（JP225、価格約39,834、口座通貨JPY、レバレッジ100）。CFDINDEX（3）とFUTURES（1）は`SYMBOL_MARGIN_INITIAL`（固定額）×証拠金率で計算され、固定額が0のままだと証拠金が0になる。CFDLEVERAGE（4）は口座レバレッジでも割られ40円になる。CFD（2）は数量×契約サイズ×価格×証拠金率で3,983円となり期待どおりだった。
3. **仕様値（OANDA公開ページ。2026-09-19に原ページの原文で照合し、US30のVolume Maxを250から100へ訂正した。照合結果は下の「原ページとの照合結果」）:**

| 項目 | JP225_HIST | US30_HIST | XAUUSD_HIST |
| --- | --- | --- | --- |
| Digits / Point・Tick Size | 1 / 0.1 | 1 / 0.1 | 3 / 0.001（データは小数2桁） |
| 契約サイズ | 1 | 1 | 100 |
| Volume Min / Step / Max | 1 / 1 / 10000 | 0.1 / 0.1 / 100 | 0.01 / 0.01（原ページに記載なし）/ 20 |
| 利益・証拠金通貨 | JPY | USD | USD |
| 証拠金率 | 10% | 10% | 5% |

4. **Digitsの変更は、MT5がバー履歴（`bases\Custom\history\<symbol>\*.hcc`）を消去する（2026-09-19実測）。** tick履歴（`bases\Custom\ticks\`）は消えない。適用前にtickフォルダとバー履歴（`.hcc`）の両方をバックアップする。バーの再生成には`mt5/Tools/RebuildBarsFromTicks.mq5`（保持tickを`CustomTicksReplace`で同内容のまま書き戻す）を使えるが、**直近月ではterminalのtick読み取りAPIが実データの約1%しか返さず、そのまま書き戻すとtickが欠落する**（JP225 2026-02〜08、US30 2026-05〜08、XAUUSD 2026-08で発生、tickはバックアップから復元済み）。バー再生成は、実行前に`apply=false`で件数を確認し、tickの`.tkc`サイズを実行前後で比較すること。この件は、tickをバックアップから復元し、バー履歴を修復して解消した。tick欠落の原因は、terminalのtick読み取りAPI（`CopyTicksRange`/`CopyTicks`）が直近月で実データの約1%しか返す元からの仕様を知らずに書き戻したこと、Testerのtick数の残差の原因は、その結果から作り直した誤りのバー履歴（tickのない分足にもバーがあり、Testerが合成tickで補う）であることを、未使用のUS500_HISTでの対照実験で確定した（Digits変更自体は原因ではない）。修復は、Digits変更前のバー履歴のバックアップを戻す方法（US30・XAUUSD、Testerのtick数・候補がSep 17と完全一致）、またはバックアップがない場合に、影響月のバーを`BarsFileTool`（削除モード）で削除し、Testerに全tickから生成させて（`mt5/Experts/ExportM1BarsEA.mq5`）ティックのある分足のバーだけを取り込む方法（JP225、候補97/97一致）による。**以後、Custom SymbolのDigitsを変える場合は、事前にtickフォルダとバー履歴（`.hcc`）の両方をバックアップし、`RebuildBarsFromTicks`は使わないこと**（このスクリプトは、terminalのAPI仕様のため直近月のtickを欠落させる。ヘッダーに警告済み）。詳細はTASKS.md 追加分析3の続き参照。

## 理由

* 仕様が初期値のCustom Symbolでは、Point・契約サイズ・Volume・通貨を前提とするEAのリスク計算・スプレッド判定・証拠金計算が成立しない。EA側にフォールバックを足すと、4銘柄（USDJPY/EURJPY/EURUSD/GBPJPY）の売買ロジックへ影響し得るため、Custom Symbol側を修正する。
* 複製元がない資産では、Broker実仕様を読み取れないため、公開仕様を明示的に記録する。

## 原ページとの照合結果（2026-09-19、公式ページの原文を確認）

出典: [株価指数CFD取扱銘柄](https://www.oanda.jp/indices/lineup)、[商品CFD取扱銘柄](https://www.oanda.jp/commodity/lineup)、[株価指数CFDの取引数量（Lab）](https://www.oanda.jp/lab-education/beginners/aboutcfd/volume/)、[最小取引単位の引き下げのお知らせ（2021-05-26）](https://www.oanda.jp/info/787)。

| 項目 | JP225 | US30 | XAUUSD |
|---|---|---|---|
| 呼値（Tick Size） | 0.1 一致 | 0.1 一致 | 0.001 一致 |
| 通貨 | JPY 一致 | USD 一致 | USD 一致 |
| 証拠金率（MT5） | 10% 一致 | 10% 一致 | 5% 一致 |
| 契約サイズ | 1 一致（数量1＝指数×1。Labページ） | 1 一致（価格が1動くと1ドル） | 100 一致（1ロット＝100） |
| 最小取引単位 | 1 一致 | 0.1 一致 | 0.01 一致 |
| 取引数量の刻み | 1.00 一致（お知らせ） | 0.10 一致（お知らせ） | 原ページに記載なし（**未確認**、最小0.01から0.01と仮定） |
| 最大取引数量 | 10,000 一致 | **100（設定は250で不一致→訂正）** | 20ロット 一致 |
| 最大建玉数量（Custom Symbolへ未設定） | 25,000 | 250 | 30ロット |

* **US30のVolume Max**: 当初の暫定値250は、最大建玉数量（250）を最大取引数量と取り違えた誤りだった。原ページの最大取引数量は100。`mt5/Tools/ApplyCfdSymbolSpec.mq5`を100へ訂正した。US30_HISTの実Symbolは2026-09-19に再適用し、Volume Maxを100へ変更した（下記）。承認されたvolumeの最大は0.7ロット（`20260919-132411`・`20260919-162553`のUS30実行）で上限に達しておらず、既存の実行結果は影響を受けない。
* **US30_HISTの再適用（2026-09-19、実施済み）**: 適用前にtickとバー履歴（.hcc）と`symbols.custom.dat`をバックアップ（87ファイル・994,171,918バイト、元と一致）し、`ApplyCfdSymbolSpec`（`InpApply=true`、バー再生成なし）を実行した。変更はVolume Maxの250→100のみ（適用前後の仕様出力の差分はこの1行だけ。Tester内の診断でも100を確認）。バー履歴の全7ファイルはバックアップとSHA-256が一致（同じ値のDigits設定ではバー履歴は消えなかった）、tickの全79ファイルも適用前とSHA-256が一致した。再実行（US30 2021-04〜12、`20260919-200204-cases`）は、RISK_DECISION 33件が全項目（volume・risk_budget・required_margin含む）で適用前（`20260919-162553-cases`）と完全一致した。
* **時期による仕様の違い（限界）**: US30の最小取引単位は、2021-05-31取引開始より前は1.00だった（同日に0.10へ引き下げ。刻みも0.10単位へ）。Custom Symbolは全期間で0.1のため、2021年5月以前のバックテストの0.1〜0.7ロット（US30 2021-04〜12の実行の一部）は、当時の実Brokerでは発注できなかった数量になる。JP225は同日の変更対象外（従前から最小・刻みとも1.00）。**扱い（2026-09-19決定）**: (1) Custom Symbolは変更しない（1銘柄に1つの仕様しか持てず、時期で切り替えるにはEA本体の変更が必要なため）。(2) US30（およびUS100。同日に最小取引単位が1.00から0.10へ変わった）の動作確認は、2021-06-01以降で行う（DEC-025のウォームアップは満たす）。US30 2021-06-01〜12-31の確認では、承認16件（volume 0.1〜0.7）で、2021-04開始の実行の同期間とRISK_DECISIONの採否・理由が全25件一致した（volumeの差は1件、2021-07-21の0.3と0.2。4〜5月の取引がなく口座残高が異なるためと推定。未検証）。(3) 2021-05-31以前を含む結果は、「当時は発注できなかった数量を含む」と注記する（US30 2021-04〜12の承認19件のうち3件が該当）。他の過去時点の仕様（最大取引数量、証拠金率、契約サイズ）は公開情報で確認できず、**未確認**（照合したのは2026-09-19時点の現行ページ）。
* **未確認のまま残る項目**: XAUUSDの取引数量の刻み（原ページに記載なし）、最大建玉数量のCustom Symbolへの設定（`SYMBOL_VOLUME_LIMIT`。EAは使用していないため未設定）、スワップ・スプレッド（原ページに記載なし）。

## 影響

* 追加（すべて新規ファイル）: `mt5/Tools/ApplyCfdSymbolSpec.mq5`、`mt5/Tools/RebuildBarsFromTicks.mq5`、`mt5/Tools/DiagnoseSymbolSpec.mq5`、`mt5/Experts/DiagnoseSymbolSpecEA.mq5`、`mt5/Include/Diagnostics/SymbolSpecDump.mqh`、`mt5/Include/Diagnostics/SymbolBarRebuild.mqh`、`mt5/Tools/CheckSymbolHistory.mq5`、`mt5/Tools/MarginExperimentSymbols.mq5`。EA本体（`mt5/Include`の売買・リスク・戦略コード）と、4銘柄の設定・テンプレートは変更していない。
* JP225_HISTのバックテスト（2021-04〜12、現行パラメータ）で、RISK_DECISIONが承認10件・POSITION_LIMIT拒否15件となり、`TICK_VALUE_UNAVAILABLE`・`SPREAD_TOO_WIDE`・`RISK_STATE_UNAVAILABLE`が解消したことを確認した（`results/backtests/20260919-131018-JP225_HIST-H1`）。承認時の`required_margin`は約13.5万円、保有中の証拠金維持率は約1,140%。US30_HIST（2021-04〜12、`results/backtests/20260919-132411-US30_HIST-H1`）は承認19件・POSITION_LIMIT拒否14件、`required_margin`約18.5万円、保有中の証拠金維持率約543%。XAUUSD_HIST（2023-07〜12、`results/backtests/20260919-132447-XAUUSD_HIST-H1`）は承認10件・POSITION_LIMIT拒否4件、`required_margin`約5.5万円、保有中の証拠金維持率約2,423%。Tester内の`OrderCalcProfit`/`OrderCalcMargin`は、契約サイズ・通貨換算（USDJPY約150円）と整合する値（US30 1ロットSL幅390.6ドルで-58,618円、XAUUSD 1ロットSL幅20.8ドルで-312,568円）だった。これらは動作確認であり、成績評価・採用判断には使わない。
* **未確認**: 各値のOANDA公式原ページとの照合、JP225のVolume Step（1か0.1か）、US30の契約サイズ／数量の意味、RebuildBarsFromTicks後のtick内容の全期間一致（2024-03のみ件数一致を確認）、`PositionSizer::VolumeDigits`の推定原因。
* 実験用の複製銘柄（`JP225_XMCFD`・`JP225_XMLEV`・`JP225_XMFUT`・`JP225_XMIDX`）は実験後に削除済み（2026-09-19、`MarginExperimentSymbols`の`InpDelete=true`）。
* **既知の残課題**: EAは`InpMaxSpreadPoints`（Point単位）を使うため、Pointが正しくなった非FX資産でも既定値30では全候補が拒否される。専用テンプレートで値を決める必要がある（決め方は未決定）。
* Rollback: `symbols.custom.dat`（`bases\`直下）のバックアップをMT5停止中に戻し、tickバックアップを戻したうえで`RebuildBarsFromTicks`でバーを再生成する。


# DEC-034: 非FX資産のInpMaxSpreadPointsは「FXの30 pointsと同じ価格比」で事前に決め、PositionSizerのVolume正規化にゼロ拒否の防御を入れる

**状態:** 採用（2026-09-19）

## 背景

DEC-033でJP225・US30・XAUUSDのCustom Symbolに正しいPointを設定した結果、`InpMaxSpreadPoints`（既定30、Point単位）が非FX資産では合わなくなった（Pointが0.1のJP225で30 points＝3円は、通常のスプレッド5〜10円より狭く、全候補が拒否される）。それまでのテンプレートは、Pointが誤っていた状態で実測値を見て緩めた値（JP225 500000、US30 200000、XAUUSD 60000）で、事実上フィルターを無効化していた。また、`PositionSizer::VolumeDigits`は刻みが1e-8以下だと0桁を返し、`NormalizeDouble`でvolumeが0になったまま`Calculate()`がtrueを返す（初期値のCustom Symbolで実際に発生）。

## 判断

### 1. InpMaxSpreadPointsの決め方

**「FX4銘柄の30 pointsが価格に占める割合の中央値（0.0227%）を、非FX資産の基準価格へ適用し、Point単位へ換算して10 points単位に丸める」とする。** 閾値は、事前にルールで決め、バックテストの結果（損益・勝率・スプレッド超過率）を見て調整しない。

* FX4銘柄の実測: 30 pointsは価格の0.0186〜0.0266%（USDJPY 0.0232%、EURJPY 0.0222%、EURUSD 0.0266%、GBPJPY 0.0186%、中央値0.0227%）で、候補の93.6〜98.3%が通過する。
* 基準価格は、各資産の候補時の中央値価格を丸めた値（JP225 48,000、US30 49,000、XAUUSD 3,400）。価格水準だけを使い、スプレッドの分布や成績は使わない。
* 結果: **JP225 110 points（約11円）、US30 110 points（約11ポイント）、XAUUSD 770 points（約0.77ドル）**。`mt5/test-config/StrategyTester-Generic-{JP225,US30,XAUUSD}-H1.ini`へ反映した。
* 参考（判断には使っていない）: 反映後の短期間実行（JP225 2021-04〜12、US30 2021-04〜12、XAUUSD 2023-07〜12）で、`SPREAD_TOO_WIDE`はJP225 8%（2/25件）、US30 0%、XAUUSD 0%。FX4銘柄の2〜6%と同水準で、閾値は調整しない。

### 2. PositionSizer::VolumeDigitsの防御

**防御を入れる（必要）。** 正規化後のvolumeが0以下なら、`Calculate()`は`SIZE_BELOW_MIN`で拒否する（新しい理由コードは追加せず、既存のコードを使う）。

* `VolumeDigits`と、正規化を行う`NormalizeVolume`を`CPositionSizerRules`のstaticとして純粋関数に切り出した（ロジックは元のまま）。`Calculate()`は`NormalizeVolume`の結果が0以下なら拒否する。
* 危険性: volume=0のまま成功でも、後段のExposureGuardが拒否する（fail-safe）ため、誤発注には至らない。ただし理由コードが`RISK_STATE_UNAVAILABLE`（リスク状態不明）となり、原因の切り分けを誤らせるため、Risk Managerの最終権限・原因の明確さの観点で入れる。
* 4銘柄への無影響: 正常なBroker仕様（刻み0.01・0.1・1・0.001）では、正規化の前後でvolumeは変わらない（単体テストで確認）。Final Holdout 4銘柄（181トレード）をコード変更後に再実行し、取引数・純損益・PF・全335件のRISK_DECISION（volume・risk_budget含む）が修正前と完全に一致した（`results/backtests/20260919-133712-cases`と`20260919-161758-cases`）。

## 理由

* 価格比で揃えれば、FXで検証済みのフィルターの厳しさを非FX資産へ、実データの分布や成績を見ずに移せる。データを見て閾値を決めるより、過学習を避けられる。
* コードの変更は最小（関数の切り出しと、0以下の拒否1か所）にとどめ、既存の売買・リスクロジックへ影響しない形にした。

## 影響

* 変更: `mt5/Include/Risk/PositionSizer.mqh`、`mt5/Tests/TestPositionSizer.mq5`（アサーション9件追加）、`mt5/test-config/StrategyTester-Generic-{JP225,US30,XAUUSD}-H1.ini`（`InpMaxSpreadPoints`）。
* 検証: MQL5コンパイル13ターゲットが0 errors/0 warnings、全12 Script Test PASS、Final Holdout 4銘柄の再実行で完全一致（2026-09-19）。
* 限界: 閾値はPoint単位の固定値のため、価格水準が大きく動くと（JP225は約3.3万〜6.9万）価格比が変わる。価格比で指定できるEAパラメータの追加は、設計変更のため今回は行わない。基準価格は、最初の追加測定で見えた価格水準に依存する（成績には依存しない）。
* 未確認: OANDA公式のスプレッド水準との照合。
* 価格水準・スプレッド水準が変わった場合の妥当性は、下の「追加確認」で全期間のtickを集計して確認した。

## 追加確認: 全期間での閾値の妥当性（2026-09-19、読み取り専用、閾値は変更しない）

`mt5/Tools/SpreadProfile.mq5`で、Custom Symbolのtickから月別のスプレッド（(ask-bid)/Point）と価格水準を集計した。各時間の最初のtick（H1候補の評価時点に近い）の年別結果は次のとおり（over_fixedは現行の固定値を超えた割合、over_ratioは「その年の価格×0.0227%」を超えた割合）。

| 銘柄 | 年 | 平均価格 | スプレッド中央値(points) | 固定値/価格比換算 | over_fixed | over_ratio |
|---|---|---|---|---|---|---|
| JP225 | 2021 | 28,855 | 60 | 1.69 | 4.1% | 5.9% |
| JP225 | 2023 | 30,657 | 60 | 1.58 | 3.3% | 5.7% |
| JP225 | 2024 | 38,343 | 100 | 1.27 | 15.1% | 56.0% |
| JP225 | 2025 | 41,790 | 100 | 1.16 | 10.1% | 40.2% |
| JP225 | 2026 | 60,289 | 100 | 0.80 | 30.7% | 23.3% |
| US30 | 2021 | 34,051 | 20 | 1.43 | 0.1% | 0.4% |
| US30 | 2024 | 40,321 | 25 | 1.20 | 0.4% | 0.5% |
| US30 | 2026 | 49,446 | 32 | 0.98 | 1.4% | 1.4% |
| XAUUSD | 2022 | 1,731 | 260 | 1.96 | 0.6% | 4.3% |
| XAUUSD | 2024 | 2,389 | 390 | 1.42 | 1.6% | 5.0% |
| XAUUSD | 2025 | 3,442 | 765 | 0.98 | 43.1% | 38.2% |
| XAUUSD | 2026 | 4,588 | 690 | 0.74 | 41.6% | 12.7% |

* **US30**: 全期間で超過率2%以下。固定値110 pointsは、価格が2.5万〜5.3万に動いても問題ない。
* **JP225**: 価格の上昇より、**Broker側のスプレッド水準の変化が支配的**。中央値が2024年前半に約5円から10円へ倍増し、以後の超過率は10〜31%になる。2026年は価格上昇（6万超）で価格比換算より固定値が厳しくなる（0.80倍）。
* **XAUUSD**: 中央値が2024年の約0.39ドルから2025年の約0.77ドルへ倍増し、固定値770 pointsは2025年以降で候補の約4割を拒否する。
* **価格比の方式でも解決しない**: 価格比換算（over_ratio）でもJP225 2024年は56%、XAUUSD 2025年は38%が超過する。スプレッドが価格に比例して動かず、価格水準よりスプレッド水準の変化が大きいため。固定値のままで問題ないのは、US30の全期間と、スプレッドが安定していた期間（JP225〜2023年、XAUUSD〜2024年）に限られる。
* 先の短期間実行（JP225 2021-04〜12、US30 2021-04〜12、XAUUSD 2023-07〜12）が低い超過率だったのは、スプレッドが安定した期間だったため。全期間へ外挿できない。

**判断:** 閾値は変更しない。データの分布を見て閾値を調整すれば、DEC-034の「事前固定」の原則を崩し、初見資産のパラメータ探索になるため。代わりに、次を運用ルールとする。

* 非FX資産の結果を報告するときは、必ず`SPREAD_TOO_WIDE`の割合を併記する。2024年以降のJP225と2025年以降のXAUUSDは、スプレッドフィルターの拒否が結果を左右する期間として扱い、他の期間と単純に比較しない。
* 価格比で閾値を指定するEAパラメータや、期間ごとの閾値は、設計変更となるため導入しない（必要なら別のDECで判断する）。

**限界:** 直近月（JP225 2026年2月以降、US30 2026年5月以降、XAUUSD 2026年8月）は、terminalのtick読み取りAPIが約1%しか返さない（DEC-033）ため標本が間引かれている。JP225の2020年前半はtickが疎（2020年4月は7,624件）で、統計として弱い。各時間の最初のtickはAPI経由の値で、Testerが評価する最初のtickと厳密には一致しない場合がある。OANDAの公式スプレッドとの照合は未実施。
* Rollback: `git checkout -- mt5/Include/Risk/PositionSizer.mqh mt5/Tests/TestPositionSizer.mq5`でコードを戻し、テンプレートの`InpMaxSpreadPoints`は元の値（500000/200000/60000）へ戻す。

---

# DEC-035: 投入済みのUS100・US500・US2000のCustom Symbolへ仕様を設定し、InpMaxSpreadPointsはDEC-034の方式で事前固定する

**状態:** 採用（2026-09-19）

## 背景

`bases\Custom\ticks\`に、tick投入済みで仕様適用の記録がない`US100_HIST`・`US500_HIST`・`US2000_HIST`（2020-04〜2026-09）があった。DEC-033のJP225・US30・XAUUSDと同じ状況の可能性が高く、確認して修正した。対象は投入済みのSymbolのみで、新しいtickの投入は行っていない。

## 確認結果（適用前、読み取りのみ）

* **仕様は3銘柄とも初期値のまま**（Strategy Tester内の診断`DiagnoseSymbolSpecEA`）: Digits 4、Point 0.0001、契約サイズ100000、Volume Min/Step/Max 1e-8/1e-8/1e-7、CalcMode 0（FOREX）、証拠金率1.0、利益通貨は銘柄名の切れ端（US100=`00_`、US500=`00_`、US2000=`000`）、tick価値0。
* **現行EA（Genericテンプレートの現在値、2021-04-01〜12-31、`20260919-192241-cases`）は3銘柄とも取引0件**。候補のRISK_DECISIONは全件`SPREAD_TOO_WIDE`（US100 37件、US500 66件、US2000 25件。Pointが0.0001のためスプレッドが数万pointsになる）。`TICK_VALUE_UNAVAILABLE`・`RISK_STATE_UNAVAILABLE`は、最初の関門で拒否されたため未観測。
* **tickの価格水準は、対応する株価指数の水準と矛盾しない**（2024-03: US100 18,317、US500 5,136、US2000 2,077。2022年10月の安値: US100 10,801、US500 3,564、US2000 1,659）。**投入元CSVの記録はリポジトリになく、由来は価格水準の照合のみ（未確認）**。

## OANDA公式ページとの照合（2026-09-19、原文で確認）

出典: [株価指数CFD取扱銘柄](https://www.oanda.jp/indices/lineup)、[最小取引単位のお知らせ（2021-05-26）](https://www.oanda.jp/info/787)。3銘柄ともOANDA証券の取扱銘柄。

| 項目 | US100 | US500 | US2000 |
|---|---|---|---|
| 呼値（Tick Size） | 0.1 | 0.1 | 0.001 |
| 通貨 | USD | USD | USD |
| 証拠金率（MT5） | 10% | 10% | 10% |
| 契約サイズ | 1（取引例: 29,701×0.1×157＝¥466,306が公式値と一致） | 1（7,669×1×157＝¥1,204,033が一致） | 1（2,862×1×157＝¥449,334が一致） |
| 最小取引単位 | 0.1 | 1 | 1 |
| 取引数量の刻み | 0.10（2021-05-31〜） | 1.00 | 1.00 |
| 最大取引数量 | 200 | 1,000 | 200 |
| 最大建玉数量（Custom Symbolへ未設定） | 1,000 | 2,500 | 3,000 |

* **時期による仕様の違い（限界）**: US100の最小取引単位は2021-05-31より前は1.00だった（DEC-033のUS30と同じ扱い。動作確認は2021-06-01以降で行う）。US2000の最大取引数量は同日に500から200へ下がった。過去時点の他の仕様は公開情報で確認できず**未確認**（照合したのは2026-09-19時点の現行ページ）。
* スプレッド、スワップは原ページに記載なし（**未確認**）。

## 判断

1. **仕様の設定**: `mt5/Tools/ApplyCfdSymbolSpec.mq5`へ3銘柄を追加し（`LoadSpec`のみの最小変更）、DEC-033の判断2（CalcModeはCFD）に従って設定した。刻みは、3銘柄ともお知らせ（US100は0.10、US500・US2000は1.00）から確定している。

| 項目 | US100_HIST | US500_HIST | US2000_HIST |
|---|---|---|---|
| Digits / Point・Tick Size | 1 / 0.1 | 1 / 0.1 | 3 / 0.001 |
| 契約サイズ | 1 | 1 | 1 |
| Volume Min / Step / Max | 0.1 / 0.1 / 200 | 1 / 1 / 1000 | 1 / 1 / 200 |
| 通貨（Base・Profit・Margin） | USD | USD | USD |
| CalcMode / 証拠金率 | CFD / 10% | CFD / 10% | CFD / 10% |

2. **InpMaxSpreadPointsはDEC-034の方式で事前に固定した**（結果を見て調整しない）。基準価格は、2025-01〜2026-08の全候補の`entry_price`中央値を有効数字2桁に丸めた値（JP225の48,098→48,000、US30の49,326→49,000、XAUUSDの3,359→3,400と同じ方式）。使ったのは価格だけで、スプレッド・成績は使っていない。

| 銘柄 | 中央値（候補数） | 基準価格 | 0.0227%換算 | 決定値 |
|---|---|---|---|---|
| US100 | 25,012（131） | 25,000 | 56.7 | **60** |
| US500 | 6,717（114） | 6,700 | 15.2 | **20** |
| US2000 | 2,447（83） | 2,400 | 544.8 | **540** |

   US500は、10 points単位への丸めで換算値15.2が20になる（実質0.0298%、約1.3倍）。事前規則の粗さによる歪みだが、規則どおりとした。専用テンプレート`mt5/test-config/StrategyTester-Generic-{US100,US500,US2000}-H1.ini`は、Genericテンプレートに`InpMaxSpreadPoints`を足しただけの構成（Leverage 1:25）。
3. **適用手順はDEC-033の判断4に従った**: 適用前にtick・バー履歴（.hcc）・`symbols.custom.dat`をバックアップ（US100 2,344,818,980バイト、US500 685,816,837バイト、US2000 944,971,211バイト、元と一致）し、`InpRebuildFromMonth`を空で適用した。Digits変更（4→1／1／3）で.hccが空（15,144バイト）になったため、バックアップから戻した。`RebuildBarsFromTicks`は使っていない。

## 検証

* **tick**: 適用前後で3銘柄とも全79ファイルのSHA-256が一致（欠落なし）。バー履歴は復元後、全7ファイルがバックアップとSHA-256一致。
* **仕様**: Tester内の診断で、Digits・Point・契約サイズ・Volume・CalcMode・通貨・証拠金率が上表どおり。tick価値がTester内で自動計算され（USDJPYから約15円）、`OrderCalcProfit`・`OrderCalcMargin`が成立。
* **取引の成立**（動作確認のみ。成績の評価・採用判断には使わない。`20260919-201210-cases`）:

| ケース | トレード数 | RISK_DECISION | 承認時のvolume | required_margin |
|---|---:|---|---|---|
| US100 2021-06-01〜12-31 | 14 | 承認14・`POSITION_LIMIT`14 | 0.3〜1.4 | 約5.4万〜24.2万円 |
| US100 2021-04-01〜12-31 | 19 | 承認19・`POSITION_LIMIT`18 | 0.3〜1.4 | 同上 |
| US500 2021-04-01〜12-31 | 34 | 承認34・`POSITION_LIMIT`32 | 1.0〜5.0 | 約4.5万〜25.0万円 |
| US2000 2021-04-01〜12-31 | 17 | 承認17・`POSITION_LIMIT`8 | 1.0〜7.0 | 約2.4万〜18.0万円 |

  `SPREAD_TOO_WIDE`・`TICK_VALUE_UNAVAILABLE`・`RISK_STATE_UNAVAILABLE`・`SIZE_BELOW_MIN`は0件（この期間のみ。DEC-034のとおり、スプレッド水準は期間で変わるため他の期間へ外挿しない）。
* **候補の一致**: 仕様適用前後で、3銘柄の候補（US100 37・US500 66・US2000 25件）のtimestamp・entry_price・ATRが完全一致した（バー履歴が復元前と変わっていないことの確認）。
* **4銘柄への無影響**: Final Holdout 4銘柄（181トレード）を適用後に再実行し、`summary.csv`（取引数・純損益・PF・勝率・期待値）と全335件のRISK_DECISIONが、適用前（`20260919-161758-cases`）と完全一致した（`20260919-201501-cases`）。EA本体（`mt5/Include`・`CoreEA.mq5`）は変更していない。MQL5コンパイル13ターゲットは0 errors/0 warnings（Script Testは、EA本体を変更していないため再実行していない）。

## 限界・未確認

* 初見資産のため、動作確認以外（パラメータ探索・採用判断・Final Holdoutの代替）の根拠にしない。
* 投入tickの由来（投入元CSV）は未確認。価格水準のみで照合した。
* 原ページとの照合は現行ページ（2026-09-19）のみ。過去時点の仕様、スプレッド、スワップは未確認。
* `InpMaxSpreadPoints`は、DEC-034の限界と同様、期間によるスプレッド水準の変化により、期間ごとの拒否割合が変わりうる。3銘柄の全期間のスプレッド分布は未確認（JP225・US30・XAUUSDのDEC-034「追加確認」に相当する集計は未実施）。
* 直近月のtick（DEC-033の約1%制約）について、適用前後のSHA-256一致までは確認したが、Testerのtick数・全期間の候補一致は未確認。

## 影響

* 変更: `mt5/Tools/ApplyCfdSymbolSpec.mq5`（`LoadSpec`に3銘柄）、`mt5/test-config/StrategyTester-Generic-{US100,US500,US2000}-H1.ini`（新規）。Custom Symbolの実体: `US100_HIST`・`US500_HIST`・`US2000_HIST`の仕様。
* Rollback: バックアップ（`backup-before-us3-spec`）から`symbols.custom.dat`・.hcc・tickを戻す。コードは`git checkout -- mt5/Tools/ApplyCfdSymbolSpec.mq5`、テンプレート3件は削除。


# DEC-036: ヒストリカルtickの取得・変換はProvider交換式のPythonパイプラインとし、MT5投入は既存Importerを再利用する

**状態:** 採用（2026-09-21）。実Dukascopy・MT5実機での確認結果は下の「確認結果」を参照。

## 背景

長期バックテストのtickは、OANDAのWeb版ダウンロード（手動、DEC-023）に依存していた。別データソース（Dukascopy等）を、手作業なしに再現可能な手順で取得し、Strategy Testerで使える形にする必要があった。

## 決定

1. **処理本体は`python/tickdata/`（Python）に置き、Node.js（dukascopy-node）は1チャンク分を取得する薄いAdapter（`tools/tick-data/dukascopy-download.mjs`）に限る。** chunk分割・retry・resume・checksum・検証・変換を2言語で二重実装しない。
2. **Providerは`TickProvider`（`download_chunk`・`iter_rows`）で交換可能にし、後段は共通tick（UTCエポックms＋bid/ask/volume）だけを扱う。** symbol・provider・期間は行ではなくmanifestで持つ。
3. **MT5投入は既存`ImportOandaTicks.mq5`を再利用し（tick欠落の修正はDEC-037）、MT5標準のタブCSVへ変換して渡す。** Providerごとの別Importerは作らない。実Symbolは変更せず、既存`*_HIST`とは別名のCustom Symbolへ投入する。既存symbolへの追記・再投入は既定で拒否し、`-AllowExistingSymbol`で明示した場合のみ行う（完全にやり直す場合は`-ResetCustomSymbol`で削除して再作成）。
4. **MT5サーバー時刻への変換規則（`server_time`）は必須の明示設定とする。** D1・H4の境界が変わるため、既定値は置かない。OANDA-Japan MT5は`ny_close`（NY現地時刻+7時間）であることを既存OANDA tickで確認した。
5. **検証をconvertの前提にする。** 検証がFAILの、または検証後に変わったデータは変換しない。取込は`complete`/`complete_with_skips`/`incomplete`、品質確認はtick数0を成功にしない。
6. **Tickstoryはパイプラインに組み込まない。** GUI自動操作を避け、Tickstoryが出力したCSVは`csvfile` Providerで取り込む方針とする（CSV形式は未確認）。

## 確認結果（2026-09-21）

* **Locally Tested**: Python単体・結合テスト60件（`python/tests/test_tickdata_*.py`）。既存のPython/Lambda/infraテスト194件（新規60件を含む）、既存MQL5 Script Test 12件（`run-mql5-tests.ps1`）は全て成功。
* **実Dukascopy（USDJPY、2020-03-02〜03-06、5日、894,250 tick）**: 取得（dukascopy-node 1.50.0）→正規化→検証（PASS）→MT5形式変換（サーバー時刻`ny_close`）が成功。既存ImportOandaTicks.mq5で試験用Custom Symbolへ取込し、Strategy Testerで「100%リアルティック」を確認した。初回の取込では、MT5から取得できたtickが888,490件（5,760件・0.64%少ない）だった。原因はImporterの`CustomTicksAdd()`（DEC-037）で、修正後は894,250件が一致した。
* **サーバー時刻**: `ny_close`がOANDA-Japan MT5の時刻に一致することを、既存OANDA tick（2017-03の週明けが米国DST前後とも月曜00:00台）で確認した。Dukascopy由来tickの最終tickが`2020.03.06 23:59:56`（OANDAの週末終了`23:59:59`と同型）になることとも整合する。
* **mock（合成tick）**: 取込・件数照合・Strategy Testerまで、MT5実機で確認（tick数一致）。試験用Custom Symbol・Junction・プリセットは削除済み。
* **既存OANDA取込のImporter**: DEC-037で修正した。修正後のImporterでの、OANDA形式CSVそのものの取込は未実施（元CSVが圧縮ファイルのまま。Dukascopy由来・mockのMT5形式CSVでは確認済み）。
* **未実施**: Dukascopy全期間（2016-09〜2020-12）の取得・投入、Dukascopyのライセンス確認、Dukascopy由来tickでのIS/OOS再検証、Tickstory連携、CoreEAでの実行（ウォームアップに長い履歴が必要なため5日では不可）。
## 影響

* 追加: `python/tickdata/`、`python/tests/test_tickdata_*.py`、`tools/tick-data.ps1`、`tools/tick-data/`、`mt5/Tools/VerifyCustomSymbolTicks.mq5`、`docs/tick-data-pipeline.md`。既存のEAロジック、`run-strategy-tester.ps1`、OANDA tick運用（既存Custom Symbol）は変更していない。`ImportOandaTicks.mq5`はDEC-037で修正した。
* Node.js依存（`dukascopy-node` 1.50.0、`tools/tick-data/package-lock.json`で固定）が加わる。使うのはDukascopy取得時のみ。
* Rollback: 上記の追加ファイルを削除し、`.gitignore`の`tools/tick-data/node_modules/`を戻す。作成したCustom Symbolは別名のため既存の履歴に影響しない。

# DEC-037: ImportOandaTicks.mq5はCustomTicksReplace()で投入する（CustomTicksAdd()はバッチ末尾128 tickを永続化しない）

**状態:** 採用（2026-09-21）。修正後のImporterで、Dukascopyサンプル・複数ファイル・同一ms・再投入を実機確認済み。既存10銘柄の再投入は2026-09-22に完了。

## 背景

DEC-036のパイプラインで、取込後のtick数照合が0.64%（バッチごとに128件）不足した。既存`USDJPY_HIST`（DEC-023、OANDA由来）でも、2016-08-31の1日で66,878件中384件が欠けていた（同じImporterで投入したため）。

## 調査結果（実機）

* `CustomTicksAdd()`は、呼び出し直後は全件を返す（`CopyTicksRange`）が、端末終了・再起動後は各呼び出しの末尾128件が取得できない。256件以下の呼び出しは何も永続化されない。待機、`TerminalClose`、通常のウィンドウ終了では変わらない。
* 時刻が複数の日にまたがる疎なtickでは欠けなかった。発生条件の全体は特定していない。
* `CustomTicksReplace()`で各バッチの時刻範囲を置換すると、全件が永続化された（894,250件、時刻・bid・askの順序付きchecksumが元ファイルと一致）。

## 決定

1. **`InpUseReplace`（既定true）を追加し、各バッチを`CustomTicksReplace()`で投入する。** `false`で従来の`CustomTicksAdd()`に戻せる。入力形式・他のパラメータ・出力マーカーは変更しない。
2. **同一msのtickの途中でバッチを分割しない**（ファイルをまたぐ場合は持ち越す）。置換範囲が隣のバッチのtickを消さないため。
3. **入力が時刻順でなく範囲が重なる場合は、従来の`CustomTicksAdd()`へ切り替える**（`REPLACE_FALLBACK_ADD`を出力）。既に投入したtickを消さないため。
4. **既存の`*_HIST`（OANDA由来の10銘柄）は、元のzipから修正済みImporterで再投入して補修する（ユーザー指示、2026-09-21）。** Custom Symbolの仕様・履歴は削除せず（`InpResetSymbol=false`）、範囲置換で欠けたtickだけを補う。事前にバックアップを取る。手順・結果は`docs/tick-data-pipeline.md`、道具は`tools/reimport-oanda-ticks.ps1`。

## 影響

* 変更: `mt5/Tools/ImportOandaTicks.mq5`・`.ex5`（再コンパイル）。追加: `mt5/Tools/CountCustomSymbolTicks.mq5`（読み取り専用）、`tools/reimport-oanda-ticks.ps1`、`python/tickdata/oanda_zip.py`。EA本体・Strategy Testerは無変更。既存10銘柄のtick・バーは再投入で更新した。
* 同じデータの再投入は範囲置換のため重複せず、件数も変わらない（従来は重複・不一致）。別データの範囲は上書きされる。
* **再投入の結果（2026-09-21〜22）**: 10銘柄（52億tick、全月ファイル）を再投入し、約3,359万tick（0.641%）を補った。欠落量は、バッチ数×128で予測どおり（20ファイル中19ファイルで1件も違わず一致、残り1件は30件多い）。Importerの受理数は全銘柄で元データの行数と一致（skip 0、パース失敗0）。全ファイルがMT5上の件数、または（直近月でCopyTicksRangeが過少になるため）Strategy Testerのtick数で、元データと完全一致した。JP225の1日分の（時刻・bid・ask）checksumも元CSVと一致し、10銘柄でStrategy Testerが100%リアルティックで完走した。バックアップ: `D:\Backup\mt5-custom-before-tickfix-20260921`（bases\Custom＝tick・バー約26GBと`symbols.custom.dat`）。
* **バーは再生成される**（USDJPY 2016-09のH1バーが再投入前後で微小に変化）。
* **`CopyTicksRange`は直近数か月（2025-12以降）で実データの一部しか返さない**（DEC-033と同じ現象）。データ自体は完全で、Testerのtick数で照合した。
* **主要な検証への影響を確認した（2026-09-22、ユーザー指示、`TASKS.md` 3.1節参照）**: EA・パラメータ一式は無変更のまま、IS期間の一部（2017-09〜2019-12）・Walk Forward（2020-2024）・Final Holdout（2025-01〜2026-08）を再実行し、旧結果と比較した。IS期間は取引数がケース単位で完全一致し純利益差も+0.6%とごく小さかったが、Walk Forward（取引数520→521、純利益+7.8%）・Final Holdout（取引数181→182、純利益-28,991円→-18,349円、損失37%縮小）では無視できない幅の変化があった。原因は未検証の仮説だが、Entry/Exit確認ロジックが連続tick数（`InpTrendReversalConfirmationTicks`等）を使うため、復元tickが確認タイミング・約定価格を変えうることが考えられる。ただし、年次expectancyのトレンド形状・Final Holdoutでの符号反転・NO-GO判定という中核的な結論は維持された。詳細は`docs/production-readiness-report.md` 7.5節、`TASKS.md` 3.1節を参照。
* **未確認**: バーの微小な変化・tick確認ロジックが個々のトレードへ与える影響の詳細な機序（仮説段階）、非FX資産・cross-asset確認（3資産・6資産）への影響（今回は再実行せず）、OANDA形式CSVを修正後のImporterで取り込む際の全月ファイル以外の条件、`CustomTicksAdd()`が欠落する条件の全容。
* Rollback: コードは`git checkout -- mt5/Tools/ImportOandaTicks.mq5 mt5/Tools/ImportOandaTicks.ex5`（または`InpUseReplace=false`）。データはMT5停止中に、バックアップの`Custom\ticks`・`Custom\history`・`symbols.custom.dat`を`bases\`へ戻す。

# DEC-038: Dukascopy取得は、休場が確定している時間帯（土曜終日・金曜夜間・日曜早朝）を既定でスキップする（既定true）

**状態:** 採用（2026-09-23、ユーザー依頼の速度調査の結果。当初は土曜のみ・既定falseだったが、同日中に金曜・日曜の部分休場帯へ範囲を広げ、さらに既定をtrueへ変更した。経緯は本文参照）。稼働中の取得ジョブには影響させていない（コード変更のみで、稼働中プロセスの挙動は変えない）。

## 背景

AUDUSD（2020-01-01〜2026-08-31、2,435日）の取得に約50〜65時間を要する見積りとなり、短縮できないか調査した。稼働中ジョブに影響を与えないよう、追加のDukascopyリクエストを発生させない範囲（ライブラリのローカルソース調査、GitHub Issue確認、既に完了済みのローカルデータの集計）で調査した。

## 調査結果

* 稼働中ジョブの実測ペースは約97秒/日（849日で22時間53分）。
* `batchSize=1`（現行実装）は、dukascopy-node作者自身が429対策として推奨する設定であり（[#124](https://github.com/Leo4815162342/dukascopy-node/issues/124)）、これより緩めることは推奨されない。
* `batch_pause_ms`を3,000msから下げられるかは、稼働中ジョブと同じDukascopyサーバー・同じIPを使うため今回は検証しなかった（過去の実測では1,500msで429が再発した記録がある）。
* **土曜（UTC終日）は市場休場でtickが常に0件であることを、稼働中ジョブの完了済み122件の土曜チャンク全件（例外0件）で確認した。**
* **金曜の最終tick・日曜の最初のtickの時刻を、すでにダウンロード済みの生CSV（2020-01〜2022-05、金曜123件・日曜122件、追加のDukascopyリクエストなしでローカル読み取りのみ）から集計した。** 金曜は全件が21:59:59以前に終了し（分布: 20時台76件・21時台42件・例外的に早い休日2件）、日曜は全件が21:00:00以降に開始した（分布: 21時台75件・22時台46件・23時台1件、最早は21:00:00.066）。いずれも境界を超える例は0件だった。
* 従来の実装は、これら空とわかっている時間帯も律儀に1時間ごとのリクエスト・待機（1時間あたり約3〜4秒）を行っていた。

## 決定

1. **`DukascopyProvider.download_chunk()`に、休場が確定している範囲を検出して要求を縮める分岐を追加する。**
   * 土曜（1日チャンクかつ曜日が土曜）: リクエストを送らず空ファイルを直接書く。
   * 金曜（1日チャンクかつ曜日が金曜）: 取得範囲の終端を22:00 UTCに縮める（22:00〜24:00は要求しない）。
   * 日曜（1日チャンクかつ曜日が日曜）: 取得範囲の始端を21:00 UTCに縮める（00:00〜21:00は要求しない）。
2. **既定は`true`（2026-09-23、ユーザー指示により変更。当初はfalseだった）。** 変更理由: 本プロジェクトの本番ブローカーはOANDA証券のみ（DEC-023）であり、OANDA証券がMT5で提供する銘柄は全てFXで、週末取引される銘柄（暗号資産等）は一切ないことを、公式サイト（取引全コース比較ページ・株価指数/商品CFD取引時間ページ）とデモ口座での`SymbolInfoSessionTrade`直接照会の両方で確認した（東京サーバーMT5は裁量プラン37／スタンダードプラン40通貨ペアのみ。デモで照会した40件と一致）。**このため、既定でスキップしても本プロジェクトの実用上は安全と判断した。**
3. **一般のMT5ブローカーには週末も取引される銘柄（暗号資産CFD等）を提供するところがある。** 本Providerを他ブローカー・他銘柄（OANDA証券のFX以外）に転用する場合は、`provider_options.skip_weekend_closed_hours: false`を明示指定すること。既定trueのまま使うと、該当銘柄の週末tickが欠落する。
4. **金曜・日曜の境界値は、2020-01〜2022-05（AUDUSDジョブの完了済み範囲）の実データから求めた値であり、未取得の2022-06〜2026-08について同じ境界が成り立つ保証はない**（未確認。ただし外国為替市場の週次休場慣行はNY時間17時で数十年変わっておらず、変動は考えにくいと判断した）。また、この境界値はFX（AUDUSD）固有であり、OANDA証券の商品CFD（北海ブレント原油は土曜5:59 JST終了・月曜7:01 JST再開など）を含む他の資産クラスにはそのまま適用できない（確認済み）。
5. **既定変更時点で稼働中のAUDUSDジョブは停止していた**（ユーザーによる停止か異常終了かは未確認）ため、この変更が稼働中プロセスに影響することはなかった。再開・新規ジョブでは、既存プロファイル（`skip_weekend_closed_hours`を明示していないもの）も含めて次回実行から既定trueが適用される。

## 影響

* 変更: `python/tickdata/chunks.py`（`Chunk.is_friday_only`・`is_sunday_only`プロパティ追加）、`python/tickdata/providers/dukascopy.py`（`skip_weekend_closed_hours`オプション追加、既定true）。`tools/tick-data/dukascopy-download.mjs`（稼働中ジョブが都度呼び出すNode.jsスクリプト）は変更していない。
* 期待短縮効果: 週168時間のうち、休場としてスキップ可能な時間は土曜24h＋金曜2h＋日曜21h＝47h（週の約28%）。2,435日規模のジョブでは理論上**約18時間**（65時間ベース）の短縮見込み。**未実測**。
* **既定変更（2026-09-23）の範囲**: 既定trueのため、既存の`tools/tick-data/profiles/*.json`（`skip_weekend_closed_hours`を明示していないもの）も含め、次回実行分から自動的に有効になる。プロファイル側の追記は不要。
* テスト: `python/tests/test_tickdata_core.py`に、既定（true）で土曜が空ファイル直書き・金曜終端22:00・日曜始端21:00に縮まること、`skip_weekend_closed_hours=false`明示時は週末も取引される銘柄向けに終日取得すること、平日は影響しないことを確認するテストを追加・更新した。
* **`batch_pause_ms`の短縮は別途検証済み（DEC-039）。** `batchSize`引き上げ・チャンク並列実行は未検証のまま。
* Rollback: `git checkout -- python/tickdata/chunks.py python/tickdata/providers/dukascopy.py python/tests/test_tickdata_core.py`。データへの影響はない（コード変更のみ）。既定を元のfalseへ戻す場合は`dukascopy.py`の`self.options.get("skip_weekend_closed_hours", True)`を`False`に戻す。

# DEC-039: Dukascopy取得の`batch_pause_ms`既定値を3,000msから500msへ引き下げる

**状態:** 500msとしては採用したが、その後DEC-040により既定値は0msへ更新済み。稼働中の取得ジョブがない（停止済みであることを確認済み）状態で、実際にDukascopyへリクエストを送る検証を行った。

## 背景

DEC-038の速度調査時点で、`batch_pause_ms`（1時間ごとの待機）の短縮余地は「稼働中ジョブと同じレート制限を共有するため検証しなかった」として保留していた。AUDUSDジョブが（ユーザーによる停止か異常終了かは未確認のまま）停止していることを確認したうえで、改めてユーザーから安全域の検証を依頼された。

## 検証内容・結果

* USDJPY・2020年3〜4月の実データで、1日分（24リクエスト）を`batch_pause_ms`=2000/1500/1000/500/0msの各値で個別に試したところ、**いずれも429なしで成功した**。特に1500msは、過去のセッションで「1日を通すと429が再発した」と記録されていたが、今回は問題なく成功した（原因は未特定。当時の同時実行や別要因の可能性がある）。
* 実運用に近い持続負荷を確認するため、間隔ゼロで日をまたいで連続実行する試験も行った: `batch_pause_ms`=500msで15日連続（360リクエスト）、0msで20日連続（480リクエスト）。いずれも429・失敗0件だった。
* 本検証で発生させたDukascopyへのリクエストは合計約960件（単発試験120件＋持続試験840件）。

## 決定

1. **`batch_pause_ms`の既定値を3,000msから500msへ引き下げる。** 変更箇所は`tools/tick-data/dukascopy-download.mjs`の内部既定値と、`tools/tick-data/profiles/*.json`（USDJPY・AUDUSD・NZDUSD・USDCADの本編・sample、計9ファイル）の明示値の両方。全プロファイルが`batch_pause_ms`を明示指定していたため、コード側の既定値だけを変えても既存プロファイルには反映されない。
2. **0msではなく500msを採用する。** 0msの方が持続試験のリクエスト数は多かった（480件 vs 360件）が、無料の公開サービスへの配慮と、サーバー負荷変動・時間帯による差異への余裕を残すため、明示的な間隔が残る値を選んだ。
3. **検証の限界を明記する。** 実施した持続試験は最大でも連続480リクエスト（20日相当）で、実際のジョブが行う数千日規模・数十時間にわたる連続実行と同等かは未検証。検証はUSDJPY・特定の日時のみで、他銘柄・他の時間帯・サーバー高負荷時の挙動は未確認。429が発生した場合は既存の`retry_pause_ms`（既定30000、倍々）による再試行で吸収される設計だが、保証ではない。
4. **`batchSize`の引き上げ・チャンクの並列実行は今回検証していない。** 単一リクエストの間隔ではなく同時接続数に関わる別のリスクがあり得るため、別途の検証が必要。

## 影響

* 変更: `tools/tick-data/dukascopy-download.mjs`（内部既定値）、`tools/tick-data/profiles/dukascopy-{USDJPY,AUDUSD,NZDUSD,USDCAD}.json`・同`-sample.json`（明示値、計9ファイル）。
* 期待効果: 1時間ごとの待機が3,000ms→500msになるため、1日24時間の待機時間だけで23×2.5秒＝約57.5秒/日の短縮（DEC-038の休場スキップとは独立に効く）。実運用での複合効果は未実測。
* 稼働中のAUDUSDジョブは変更時点で停止していたため、この変更が稼働中プロセスに影響することはなかった。再開時は新しい既定値（プロファイルの明示値500ms）が次回実行分から適用される。
* Rollback: `git checkout -- tools/tick-data/dukascopy-download.mjs tools/tick-data/profiles/`。データへの影響はない（設定変更のみ）。

# DEC-040: Dukascopy取得の`batch_pause_ms`既定値を500msから0msへ引き下げる

**状態:** 採用（2026-09-23、ユーザー依頼の追加検証・ユーザーの明示的な採用指示による）。稼働中の取得ジョブがない状態を確認したうえで、実際にDukascopyへリクエストを送る追加検証を行った。

## 背景

DEC-039で500msを採用した際、0msも429なしで成功していたが、「無料公開サービスへの配慮」を理由にあえて間隔を残していた。ユーザーから、0〜500msの中間値の安全性を追加で検証するよう依頼された。

## 検証内容・結果

* USDJPY・2020年5〜6月の実データ（DEC-039とは重複しない日付）で、1日分（24リクエスト）を`batch_pause_ms`=100/200/300/400msの各値で個別に試したところ、いずれも429なしで成功した。
* 持続負荷試験: 100msで15日連続（360リクエスト、55.4秒）、200msで15日連続（360リクエスト、89.8秒）、いずれも429・失敗0件。
* 0msについても追加で15日連続（360リクエスト、16.9秒）の持続試験を行い、429・失敗0件。DEC-039分と合わせ、0msの累計検証は35日分・840リクエストとなった。
* 本検証で追加発生させたDukascopyへのリクエストは合計816件（単発試験96件＋持続試験720件）。DEC-039分と合わせ、累計約1,780件のリクエストで429・失敗は1件も発生していない。

## リスク評価の訂正

検証過程で「極端な短縮（0ms等）はDukascopy側のIPブロックを招くリスクがある」との懸念を提示したが、公開情報で改めて確認したところ、この懸念は具体的な根拠を伴わない推測だった。dukascopy-node公式リポジトリのissueを調査した結果、次のことが分かった。

* メンテナー自身が「DukascopyはIPによってURLをブロックしたり、レート制限したりすることがある」とコメントした事例（issue #191、https://github.com/Leo4815162342/dukascopy-node/issues/191 ）はあるが、これは特定の国・ISP起因の恒常的な接続不能の報告であり、リクエスト頻度が引き金になった事例ではない（報告者はVPN使用で解決）。
* 別の接続障害報告（issue #180、https://github.com/Leo4815162342/dukascopy-node/issues/180 ）でも当初レート制限が疑われたが、最終的には報告者側ISPのブロックが原因と判明した。
* 公式ドキュメント（dukascopy-node.app/errors-and-empty-data）に、IPブロックやレート制限の閾値・ポリシーの具体的な記載はない。
* 結論として、「短時間の連続大量リクエストがIPブロックを引き起こす」という具体的な事例や閾値は公開情報から確認できなかった。Dukascopy側に何らかのレート制限機構（429・503）が存在すること自体は確かだが、内部仕様は非公開であり、不確実性そのものが残存リスクである。

## 決定

1. **`batch_pause_ms`の既定値を500msから0msへ引き下げる。** 変更箇所は`tools/tick-data/dukascopy-download.mjs`の内部既定値と、`tools/tick-data/profiles/*.json`の明示値の両方（DEC-039と同様、全プロファイルが明示指定のため、コード側の既定値だけでは反映されない）。
2. **0msを採用する。** DEC-039は「無料公開サービスへの配慮」を理由に、429が出ないと分かっていた0msをあえて避け、間隔の残る値（500ms）を選んでいた。今回、その判断を補強していた「極端な短縮はIPブロックを招く」という懸念が具体的根拠を欠くと判明したこと、および0〜500msの中間値を含めても429・失敗が一貫して0件だったことを踏まえ、**ユーザーが0msを既定値として採用するよう明示的に指示した**。技術的な安全性の実測結果自体はDEC-039時点から変わっていない。
3. **検証の限界は引き続き残る。** 検証規模は最大840リクエスト（35日相当、0ms）で、実際のジョブ（数千日規模）とは桁が異なる。サーバー高負荷時間帯、他銘柄との同時実行、`batchSize`引き上げとの組み合わせ、Dukascopy側のレート制限の内部仕様（閾値・エスカレーション条件）は未検証・非公開のまま。「無料公開サービスへの配慮」という定性的な安全マージンを手放す判断であることを明記する。

## 影響

* 変更: `tools/tick-data/dukascopy-download.mjs`（内部既定値）、`tools/tick-data/profiles/dukascopy-{USDJPY,AUDUSD,NZDUSD,USDCAD}.json`・同`-sample.json`（明示値、計9ファイル）。
* 期待効果: 1時間ごとの待機が500ms→0msになるため、1日24時間の待機時間だけで23×0.5秒＝約11.5秒/日のさらなる短縮。DEC-038以前（3,000ms）比では23×3.0秒＝約69秒/日相当の短縮になる。
* 稼働中のジョブは変更時点で存在しないため、この変更が稼働中プロセスに影響することはなかった。
* Rollback: `git checkout -- tools/tick-data/dukascopy-download.mjs tools/tick-data/profiles/`。データへの影響はない（設定変更のみ）。

# DEC-041: Release Gateへベンチマーク受入基準（MSCI ACWI比、税引き後CAGRとSharpe比）を追加する

**状態:** 採用（2026-09-23、ユーザー指示）。

## 背景

EAの運用資金は、NISA非課税枠（1,800万円）を超えた資産を想定している。EAを使わない場合、この資金は課税口座でインデックス投資へ回すことになるため、EAはその代替案を税引き後・リスク調整後で上回らない限り使う意義がない。既存の必須ゲートは「事前固定した受入基準を満たす」とだけ定めており、何と比べてどれだけ上回ればよいかは未定義だった。

## 決定

1. **ベンチマークはMSCI ACWI（全世界株式、配当込み、円換算）とする。** ユーザーが選択した（候補: 全世界株式・S&P500・TOPIX）。
2. **合格条件は、税引き後CAGRとSharpe比の両方がベンチマークを上回ることとする。** ユーザーが選択した（候補: 両方・税引き後リターンのみ・Sharpe比のみ）。Walk Forward（全Fold合算）とFinal Holdoutのそれぞれで満たす必要がある。
3. **税は非対称に扱う。** OANDA証券は国内業者であり、EAの損益は申告分離課税20.315%が暦年ごとに課税される（損失は3年間繰越可能）。一方、ベンチマークは売却まで課税が繰り延べられるため、期間終了時に一括課税する。税率は同じでも、課税時期の違いによって複利の面でEAが不利になる点を、比較に反映する。
4. **機械的に強制する。** `contracts/production-release-evidence.schema.json`へ`benchmark_comparison_report`（レポートへの相対path）と`benchmark_criteria_met`（`const: true`）を必須項目として追加し、`tools/release-gate.ps1 -Mode Production`で検証する。

詳細な計算方法は`docs/release-gate.md`「ベンチマーク受入基準」を正本とする。

## 影響

* production証跡の必須項目が2つ増える。schema_versionは据え置いた（production証跡はまだ一度も作成されておらず、互換性を保つべき既存証跡が存在しないため）。
* Developmentモードの挙動は変わらない。
* 比較レポートの計算処理は`python/analysis/benchmark_comparison.py`として実装した（2026-09-23、出力契約は`contracts/benchmark-comparison-report.schema.json`）。ベンチマークの月末値はネットワークから自動取得せず、利用者が用意したCSVを入力とする（データ提供元のライセンス条件に依存し、取得元とデータを固定して再現性を保つため）。既存のWalk Forward・Final Holdout結果での合否は、ベンチマークデータ未取得のため未判定。
* 実装時に次の計算上の仮定を固定した。(1) 月・暦年はAsia/Tokyoで区切る（課税年度と円建て月末値に合わせる）。(2) 複数ケース（銘柄×年）の取引は、ケースごとの口座通貨建て損益をそのまま1口座（`--initial-balance`）へ合算する（1口座で複数銘柄を運用する実際の配置に近いが、ケース間で`InpMaxOpenRiskPercent`等の口座全体の制約が効かない近似である）。(3) EAの税は年末に資産から差し引き、翌年以降の収益率はその資産へ掛ける（EAのLotは有効証拠金に比例するため）。(4) 期間末の途中年も、その時点までの利益へ課税する。繰越控除しきれなかった損失は価値ゼロとして扱う（ベンチマーク側も期間末の損失に価値を認めない）。(5) Sharpe比が算出不能な場合は「上回った」と判断できないため不合格とする。
* Rollback: `git checkout -- docs/release-gate.md docs/operations.md docs/production-readiness-checklist.md contracts/production-release-evidence.schema.json tools/release-gate.ps1`、および本DECと`TASKS.md`の追加項目を削除する。

# DEC-042: Dukascopy tick取得のライセンス上のリスクを認識の上で継続する

**状態:** 採用（2026-09-26、ユーザーの明示的な判断）。

## 背景

TASKS.md 3.1節「データ利用条件とライセンスを確認する」の一環で、Dukascopy Bank SAの公式サイト（`https://www.dukascopy.com/swiss/english/legal-pages/terms-of-use/`）のTerms of Use（TCU）を確認した結果、既に投入済みのDukascopy由来tick（EURUSD検証サンプル、AUDUSD/USDCAD/NZDUSD/GBPUSD/AUDJPY/CADJPYの全期間、`docs/tick-data-pipeline.md`・DEC-036〜040）の取得・保存方法が、TCUの複数の条項に文言上抵触する可能性が判明した。

## 確認したTCUの抵触点

1. **自動化ツールでの取得の禁止**: 「You shall not use or attempt to use any 'scraper,' 'robot,' 'bot,' 'spider,' 'data mining,' 'computer code,' or any other automate device, program, tool, algorithm, process or methodology to access, acquire, copy, or monitor any portion of the WEBSITE ... without the prior express written consent of DUKASCOPY.」——`tools/tick-data/dukascopy-download.mjs`（`dukascopy-node`経由）による自動取得は、この条項に該当する可能性が高い。
2. **非商用利用限定**: 「you agree to use the WEBSITE solely for your own non-commercial use and benefit」「Such download is licensed to you by DUKASCOPY ONLY for your own personal, non-commercial use」——本プロジェクトは将来的な実取引（商用）を目的とするため、この制約に抵触する可能性がある。
3. **データベース構築の禁止**: 「The WEBSITE and the information contained therein may not be used to construct a database of any kind. Nor may the WEBSITE be stored (in its entirety or in any part) in databases」——`tick/pipeline/`への永続的な保存、MT5 Custom Symbolへの投入は、この条項が禁じる「データベース構築」に該当する可能性が高い。

## 留保（断定していない点）

* これは`dukascopy.com`という一般公開ウェブサイトに対するTCUであり、実際に`dukascopy-node`がアクセスする配信エンドポイント（historydata系サブドメイン等）がこのTCUの適用範囲に技術的に含まれるかは、公式文書のみからは確定できない（**未確認**）。
* 同種のツール（`dukascopy-node`等）は広く使われている実績があるが、これはDukascopyが明示的に許可していることを意味しない。
* Dukascopyへの直接の問い合わせ・許諾確認は行っていない。

## 決定

上記のリスクを認識した上で、ユーザーの明示的な判断により、既存のDukascopy由来tickの利用（分析・検証目的）を継続する。追加のDukascopy取得を行う場合も、本DECに記録したリスクが解消されたわけではないことを前提とする。

## 影響

* 既存のDukascopy由来tick（EURUSD検証サンプル、AUDUSD/USDCAD/NZDUSD/GBPUSD/AUDJPY/CADJPYの全期間データ）はそのまま保持し、削除・巻き戻しは行わない。
* 将来、本プロジェクトが実際に商用・本番運用へ進む場合（Production Release Gate通過後の実口座運用等）は、Dukascopy由来tickを使った検証結果の位置づけ（あくまで参考・探索目的であり、production判定の直接根拠にはしていないこと、`TASKS.md`各エントリに明記済み）を再確認し、必要であれば正規のライセンス確認・許諾取得を検討すべきである。
* Rollback: 本DEC自体は事実の記録であり、取り消すべき変更（コード・データ）はない。方針を変更する場合は本DECの上書きで対応する。
