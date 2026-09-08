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

# DEC-031: Host実行のterminal64.exe起動は非表示デスクトップ経由（CreateDesktop+CreateProcess）とし、`-WindowStyle Hidden`には依存しない

**状態:** 採用

## 背景

`Invoke-Mt5ExecutionHost`（`tools/lib/Mt5ExecutionBackend.psm1`）は従来`Start-Process -WindowStyle Hidden`でterminal64.exeを起動していたが、Hostで実行すると画面にウィンドウが表示されることが判明した。同一の`-WindowStyle Hidden`指定を使うVM側（vmrun経由のゲスト内`Start-Process`）では画面に何も表示されないことも実機確認済みだった。

原因を調査したところ、`-WindowStyle Hidden`は`CreateProcess`の`STARTUPINFO.wShowWindow`（`SW_HIDE`）という表示状態の「ヒント」に過ぎず、実際に尊重するかはプロセス側の実装次第であることが分かった。terminal64.exeはGUIサブシステムのアプリで、自身のメインウィンドウ表示を独自ロジックで制御するため、このヒントを無視して通常表示してしまう。Host実行は対話ログオン中のデスクトップ上で直接起動するため、この「無視された結果」がそのままユーザーに見える。一方VM側は`vmrun runProgramInGuest`を`-interactive`なしで呼んでいるため、そもそも対話デスクトップにアタッチされない非対話セッションでプロセスが生成されており、`-WindowStyle Hidden`の効果とは無関係にウィンドウが不可視になっていた（`-activeWindow`は`-interactive`を伴わない限りゲスト側の対話デスクトップへのアタッチを保証しない）。

対策として「起動後にウィンドウハンドルを取得しShowWindow(SW_HIDE)で隠す」方式も検討したが、ウィンドウ生成からHide呼び出しまでの間は必ず一瞬表示され、Windowsの既定挙動で新規ウィンドウがフォアグラウンド化されるためフォーカスも奪われる。これは目視でのちらつき・作業中の他ウィンドウからのフォーカス移動として実害があるため採用しなかった。

## 判断

Host実行を、現在の対話デスクトップとは別の非表示デスクトップ上でterminal64.exeを起動する方式へ変更する。

1. `tools/lib/Mt5ExecutionBackend.psm1`へ`Add-Type`でP/Invokeラッパー（`Mt5ExecutionBackend.HiddenDesktopLauncher`、`user32.dll`の`CreateDesktop`/`CloseDesktop`、`kernel32.dll`の`CreateProcess`/`WaitForSingleObject`/`GetExitCodeProcess`/`TerminateProcess`）を追加する。
2. `Invoke-Mt5ExecutionHost`は、実行のたびに一意な名前（GUIDベース）の非表示デスクトップを`CreateDesktop`で作成し、その`lpDesktop`を指定した`STARTUPINFO`で`CreateProcess`により起動する。コマンドライン文字列は既存の`ConvertTo-Mt5Win32CommandLine`（Vmrun経路で既に使っているWin32互換エスケープ関数）をそのまま再利用して構築する。
3. 待機・タイムアウト・終了コード取得は、.NETの`Process.GetProcessById`（PID再利用によるレースコンディションの余地がある）を経由せず、`CreateProcess`が返すネイティブの`hProcess`ハンドルに対して直接`WaitForSingleObject`・`GetExitCodeProcess`・`TerminateProcess`を呼ぶ形でC#側に閉じ込める。
4. `dwCreationFlags`に`CREATE_NO_WINDOW`を指定する（コンソールサブシステムの子プロセスが親のコンソールを共有し標準出力が漏れる問題への対処。GUIサブシステムのterminal64.exeには無関係）。
5. `Invoke-Mt5ExecutionHost`の関数シグネチャ・戻り値（`ExecutionMode`/`ExitCode`/`Success`/`StagingRoots`）・タイムアウト時の例外メッセージは変更しない。呼び出し側（`run-strategy-tester.ps1`・`run-mql5-tests.ps1`）は無変更で動作する。
6. VM側（`Invoke-Mt5ExecutionVmrun`・`Invoke-Mt5ExecutionVmWinRm`）の`Start-Process -WindowStyle Hidden`はそのまま維持する（非対話セッションで実行されるため実害がなく、変更の必要がない）。

## 理由

* 非表示デスクトップは対話デスクトップとは独立したウィンドウステーション内オブジェクトであり、その上で生成されたウィンドウは対話デスクトップへ一切描画されない。そのためウィンドウ生成の瞬間も含めて表示されず、フォーカスも奪わない（後からHideする方式の「一瞬表示される」問題を構造的に回避できる）
* VM側の`vmrun runProgramInGuest`（`-interactive`なし）が非対話セッションでプロセスを生成する仕組みと同じ原理であり、既存VM実装の観察結果と整合する
* ネイティブハンドルに対して直接`WaitForSingleObject`/`GetExitCodeProcess`を使うことで、.NET`Process.GetProcessById`のPID再利用によるレースコンディション（起動直後にプロセスが即終了しPIDが別プロセスへ再利用される可能性）を避けられる
* 既存の`ConvertTo-Mt5Win32CommandLine`を再利用することで、コマンドラインエスケープロジックの重複実装を避けた
* 関数シグネチャ・戻り値・例外メッセージを変更しないことで、呼び出し側・既存テストへの影響を最小化した

## 影響

* 変更: `tools/lib/Mt5ExecutionBackend.psm1`（`Add-Mt5HiddenDesktopType`・`Invoke-Mt5ExecutionHost`）、`tools/test-mt5-execution-backend.ps1`（冒頭コメント更新）
* `tools/test-mt5-execution-backend.ps1`の既存テスト（Host正常系・ExitCode伝播・タイムアウト・ConfigFilePath自動引数生成、他VM設定検証系）は全てPASSすることを確認した（2026-09-08、Host環境で実行）
* **terminal64.exeが実際に対話デスクトップへ描画されずフォーカス奪取も発生しないことは未確認。** 本テストはコンソールアプリ（`cmd.exe`・`PING.EXE`）でのプロセス起動・待機・終了コード取得の正常系のみを検証しており、GUIアプリでの画面非表示・フォーカス非奪取の実証は含まない。`.\tools\run-strategy-tester.ps1`（Hostモード）を実際に実行し、目視でterminal64.exeのウィンドウが表示されないこと・作業中の他ウィンドウのフォーカスが奪われないことを確認する必要がある
* `.\tools\compile-mql5.ps1`・`.\tools\run-mql5-tests.ps1`・Development Release Gateは未実行（PowerShellモジュールのみの変更でMQL5ソースに変更はないが、Host実行経路を通るため`run-mql5-tests.ps1`の実機確認は別途必要）

---

# DEC-032: DEC-031の非表示デスクトップ経由起動を`-HostUseHiddenDesktop`で無効化できるようにする（既定は有効のまま）

**状態:** 採用

## 背景

DEC-031でHost実行を非表示デスクトップ経由（`CreateDesktop`+`CreateProcess`）へ変更したが、`CreateDesktop`はウィンドウステーション内にオブジェクトを作成するAPIであり、環境によっては次のような理由で使えない可能性がある。

* グループポリシー等でウィンドウステーション操作が制限された特殊なユーザーアカウント
* 「別デスクトップでプロセスを起動する」挙動をマルウェアの隠蔽実行手法と誤認するEDR/アンチウイルス製品による検知・ブロック

DEC-031の変更は関数シグネチャ・戻り値・例外メッセージを変えていないため呼び出し側への影響は無いが、上記のような環境では新方式が失敗しHost実行そのものが止まってしまう。従来の`-WindowStyle Hidden`方式（GUIアプリには効かず画面表示されるが、動作自体は問題ない）へ切り替えられる退避手段が必要と判断した。

## 判断

1. `Invoke-Mt5ExecutionHost`（`tools/lib/Mt5ExecutionBackend.psm1`）に`[bool]$UseHiddenDesktop = $true`パラメータを追加する。`$true`（既定）ならDEC-031の非表示デスクトップ経由、`$false`なら従来の`Start-Process -WindowStyle Hidden`（`Process.WaitForExit`/`Stop-Process`によるタイムアウト処理を含む）にフォールバックする。
2. 共通エントリポイント`Invoke-Mt5Execution`に`[bool]$HostUseHiddenDesktop = $true`パラメータを追加する。`ExecutionMode=Host`の場合のみ`Invoke-Mt5ExecutionHost`へ引き渡し、`ExecutionMode=VM`の場合は無視する（VM側は元々非対話セッションで実行され実害がないため、DEC-031同様に対象外のまま）。
3. `tools/run-strategy-tester.ps1`（`Invoke-StrategyTesterCase`関数と単体実行・CaseFile実行の両呼び出し経路）・`tools/run-mql5-tests.ps1`に、同名の`-HostUseHiddenDesktop`（既定`$true`）パラメータを追加し、CLIから切替可能にする。
4. 既定値は`$true`（DEC-031の非表示デスクトップ経由）のまま変更しない。

## 理由

* 既定を変えずオプトアウト方式にすることで、DEC-031で解決したフォーカス奪取・画面表示問題を通常運用では引き続き回避しつつ、新方式が使えない環境でのみ明示的に無効化できる
* パラメータ名を`HostUseHiddenDesktop`とし、Host実行専用であることをVM設定（`VmSettingsPath`等）と紛れないよう明示した
* `Invoke-Mt5ExecutionHost`単体でも`UseHiddenDesktop`パラメータを持たせることで、`Invoke-Mt5Execution`を経由しない直接呼び出し（将来的なテスト・ツール追加時）でも切替できるようにした

## 影響

* 変更: `tools/lib/Mt5ExecutionBackend.psm1`（`Invoke-Mt5ExecutionHost`・`Invoke-Mt5Execution`）、`tools/run-strategy-tester.ps1`（トップレベルパラメータ・`Invoke-StrategyTesterCase`関数・2箇所の呼び出し）、`tools/run-mql5-tests.ps1`（トップレベルパラメータ・呼び出し）、`tools/test-mt5-execution-backend.ps1`（`HostUseHiddenDesktop=$false`の正常系・タイムアウトテスト追加）、`docs/mt5-development.md`（切替方法の説明・実行コマンド例追加）
* `tools/test-mt5-execution-backend.ps1`の全テスト（既存分＋今回追加した`HostUseHiddenDesktop=$false`の正常系・タイムアウト2件）がPASSすることを確認した（2026-09-08、Host環境で実行）。PowerShellパーサーによる構文チェックも実施し、3ファイルとも構文エラー無し
* `-HostUseHiddenDesktop $false`経路での実機Strategy Tester実行（terminal64.exeが画面表示されること・DEC-031の既定経路との差異）は未確認

---

# DEC-033: 非表示デスクトップは実行のたびに作り捨てず、PowerShellプロセスの生存期間中1つを使い回す

**状態:** 採用

## 背景

DEC-031導入後、80ケース（`USDJPY`/`EURJPY`/`EURUSD`/`GBPJPY` × 複数パラメータ × 複数年）のバッチスイープを実機実行したところ、**3ケース成功後、4ケース目でterminal64.exeが正常終了せず残留し、以降76ケース全てが「起動中のMetaTrader 5を終了してください」の事前チェック（[run-strategy-tester.ps1:131](../tools/run-strategy-tester.ps1)）で連鎖的に失敗した。**

ユーザーが提供したログ2種を確認した。

* `run-strategy-tester.ps1`の実行ログ：ケース1〜3は`STRATEGY_TESTER_COMPLETED exit=0`で正常完了。ケース4は`Strategy Testerは終了しましたがreportが生成されませんでした`で失敗（＝`Invoke-Mt5ExecutionHost`はタイムアウト例外を投げずに正常リターンしていた）。
* MT5 Tester Journal：ケース3終了（`21:57:11.891 connection closed`）を最後に、ケース4のJournal記録が一切存在しない（＝terminal64.exeはJournal書き込みが始まるごく初期段階、GUI初期化の途中でハングしたと推定される）。ケース3終了時点のログには`2920 Mb memory used ... 2560 Mb of cached tick data`という記述があり、Strategy Testerが大量のティックデータをメモリキャッシュすることも確認された。

この組み合わせ（3回までは正常、4回目で初期化段階から失敗、蓄積型のパターン）から、**Windowsの「デスクトップヒープ」枯渇**が原因と推定した。`CreateDesktop`は呼び出しのたびにウィンドウステーション内へ新しいデスクトップオブジェクト（ウィンドウ・GDIオブジェクト管理用の専用カーネルメモリを持つ）を作成する。DEC-031の実装は実行ごとに一意な名前で使い捨てのデスクトップを作成・破棄していたため、`CloseDesktop`を呼んでいても、terminal64.exeのような大量のGDIリソース（多数のウィンドウ・チャート描画・大量のティックデータキャッシュ）を扱う大規模GUIアプリが確保したリソースの解放が完全には追いつかず、数回の実行でウィンドウステーション全体のデスクトップヒープが枯渇し、新しいデスクトップ上でのGUI初期化自体が失敗するようになった、という仮説である。Windows Event Viewerでのクラッシュ記録確認までは行っておらず断定はできないが、状況証拠と整合する。

## 判断

非表示デスクトップを実行のたびに作り捨てず、モジュールをインポートしたPowerShellプロセスの生存期間中は1つだけを使い回す方式へ変更する。

1. `tools/lib/Mt5ExecutionBackend.psm1`の`HiddenDesktopLauncher`（C#）を、デスクトップの作成・破棄（`CreateHiddenDesktop`/`CloseHiddenDesktop`）とプロセス起動（`RunProcess`）に分離する。`RunProcess`は既存デスクトップ名を受け取って`CreateProcess`するだけになり、`CreateDesktop`/`CloseDesktop`は呼ばなくなった。
2. PowerShell側にモジュールスコープ変数（`$script:Mt5HiddenDesktopHandle`・`$script:Mt5HiddenDesktopName`）と、それを遅延生成・キャッシュする`Get-Mt5HiddenDesktopName`関数を追加する。`Invoke-Mt5ExecutionHost`は毎回このキャッシュされたデスクトップ名を使う。
3. デスクトップの明示的なクリーンアップ（`CloseHiddenDesktop`の呼び出し）は行わない。PowerShellプロセス終了時にOSが自動的にウィンドウステーション・デスクトップ関連のハンドル・カーネルオブジェクトを回収するため、実害はないと判断した。
4. `Get-Mt5HiddenDesktopName`を`Export-ModuleMember`へ追加し、テストから直接呼べるようにする。

## 理由

* デスクトップオブジェクトの生成・破棄の繰り返しがデスクトップヒープ枯渇の原因であるという仮説が正しければ、使い回しにより数回で1回しかデスクトップを生成しなくなるため、根本的に解消できる
* 複数ケースを順次実行する現在の呼び出しパターン（同時に2つのterminal64.exeが動くことはない）では、デスクトップを共有しても安全性上の問題は無い。各プロセスが確保したウィンドウ・GDIオブジェクトはそのプロセスの終了時にOSが自動的に解放するため、次のプロセスに残留リソースが影響することは無い
* 明示的なクリーンアップ関数を追加しない設計にすることで、実装をシンプルに保った（プロセス終了時の自動回収に委ねる）

## 影響

* 変更: `tools/lib/Mt5ExecutionBackend.psm1`（`HiddenDesktopLauncher.CreateHiddenDesktop`/`CloseHiddenDesktop`追加、`RunProcess`からデスクトップ管理を分離、`Get-Mt5HiddenDesktopName`追加、`Invoke-Mt5ExecutionHost`更新、`Export-ModuleMember`更新）、`tools/test-mt5-execution-backend.ps1`（20回連続実行して同一デスクトップ名が使われ続けることを検証するテスト追加）
* `tools/test-mt5-execution-backend.ps1`の全テスト（既存分＋新規追加分）がPASSすることを確認した（2026-09-08、Host環境で実行）。PowerShellパーサーによる構文チェックも実施し構文エラー無し
* **80ケースの実機バッチスイープでの再検証は未実施。** 今回のテストは「デスクトップが使い回されること」「`cmd.exe`のような軽量プロセスを20回連続実行しても正常終了すること」の確認に留まり、terminal64.exe自体を使った連続実行での改善効果（デスクトップヒープ枯渇仮説が正しいかどうか）は実証できていない。ユーザーに実機で同一のCaseFileを再実行してもらい、80ケース全てが成功することの確認が必要
* 仮に本対応でも4回目以降の失敗が再現する場合、デスクトップヒープ枯渇以外の原因（Strategy Tester自体のメモリ管理、非表示デスクトップとGDI/Direct2D初期化の相性等）を疑う必要がある。その場合はDEC-032の`-HostUseHiddenDesktop $false`で従来方式へ切り替えるか、DEC-031時点で検討した方法B（タスクスケジューラでの非対話セッション実行）への切替を再検討する

---

# DEC-034: Host実行はCreateDesktop方式を放棄し、タスクスケジューラ（S4Uログオン）経由の非対話セッション実行へ置き換える

**状態:** 採用（DEC-031〜033を置き換え）

## 背景

DEC-033（非表示デスクトップの使い回し）を適用した上で、ユーザーがWindows再起動直後（デスクトップヒープが確実にリセットされた状態）に80ケーススイープの1ケース目からterminal64.exeを実行したところ、**再起動直後の初回実行から同じ症状（Tester Journalに1行も記録されないままハング）が再現した。**

これはDEC-033時点の仮説（実行を繰り返すことによるデスクトップヒープの累積的な枯渇）と矛盾する。累積型のリソース枯渇が原因であれば、リソースがリセットされた直後の1回目は必ず成功するはずだが、実際には1回目から失敗した。この結果は、原因が蓄積型の問題ではなく、**`CreateDesktop`で作成した非表示デスクトップ上でterminal64.exeを起動すること自体に、より根本的な相性問題がある**ことを示している（DirectX/Direct2D初期化の失敗、ウィンドウステーションの権限継承の問題等が疑わしいが、Windows Event Viewerでのクラッシュ記録確認までは行っておらず具体的な原因は未特定）。

DEC-031〜033で試みた「対話デスクトップとは別の非表示デスクトップを作成し、そこでGUIアプリを起動する」というアプローチ自体が、terminal64.exeのような大規模GUIアプリに対しては構造的に信頼性を欠くと判断し、放棄した。

## 判断

Host実行を、Windowsタスクスケジューラ（S4Uログオン、パスワード不要）経由でterminal64.exeを非対話セッション上で起動する方式へ置き換える。これはVM実行（`vmrun runProgramInGuest`を`-interactive`なしで呼ぶ）が非対話セッションでプロセスを生成するためウィンドウが一切見えなくなるのと同じ原理をHost側でも再現するものであり、「後から隠す・別デスクトップに置く」のではなく「最初から対話セッションの外で実行する」点がCreateDesktop方式と根本的に異なる。

1. `tools/lib/Mt5ExecutionBackend.psm1`から`HiddenDesktopLauncher`（C#、CreateDesktop/CreateProcess）と関連コード（`Add-Mt5HiddenDesktopType`・`Get-Mt5HiddenDesktopName`・モジュールスコープ変数）を削除した。
2. 新規`Invoke-Mt5ExecutionHostViaScheduledTask`関数を追加した。実行のたびに一意な名前（GUID）のタスクを`Register-ScheduledTask`（`New-ScheduledTaskPrincipal -LogonType S4U -RunLevel Limited`）で登録し、`Start-ScheduledTask`で起動、`Get-ScheduledTask`の`State`をポーリングして完了・タイムアウトを検知し、`Get-ScheduledTaskInfo`の`LastTaskResult`から終了コードを取得、`finally`で`Unregister-ScheduledTask`により後始末する。
3. `Invoke-Mt5ExecutionHost`のパラメータ名を`UseHiddenDesktop`から`UseIsolatedSession`へ変更した（意味が変わったため）。`Invoke-Mt5Execution`側も`HostUseHiddenDesktop`から`HostUseIsolatedSession`へ変更した。既定値は`$true`のまま維持し、`$false`で従来の`-WindowStyle Hidden`方式へフォールバックできる点も維持した（DEC-032の設計を踏襲）。
4. `tools/run-strategy-tester.ps1`・`tools/run-mql5-tests.ps1`のCLIパラメータも同様に`HostUseIsolatedSession`へリネームした。
5. S4Uログオンタイプを選択した理由：パスワード不要で非対話的にタスクを実行できるため、資格情報をコード・設定へ保存する必要が無い（CLAUDE.mdのSecret管理方針に合致する）。ネットワークリソースへはアクセスできない制約があるが、Strategy Tester実行はローカルファイルシステムのみで完結するため影響しないと判断した（実機未検証）。

## 理由

* 「後から隠す」あらゆる方式（ShowWindow(SW_HIDE)、CreateDesktop）は、対話セッション内でプロセスを生成する以上、GUIサブシステム初期化時の何らかの相性問題を完全には排除できない。非対話セッションでの実行はVM実行と同じ実績のある原理であり、構造的に確実性が高い
* S4Uはパスワード不要なため、Secret管理の負担が無い（DEC-031〜033のCreateDesktop方式も元々パスワード不要だった点は維持される）
* 既定値・フォールバック機構の設計（DEC-032）は妥当だったため、パラメータの意味論はそのまま踏襲し、名前のみ実態に合わせて変更した

## 影響

* 変更: `tools/lib/Mt5ExecutionBackend.psm1`（`HiddenDesktopLauncher`関連コード全削除、`Invoke-Mt5ExecutionHostViaScheduledTask`追加、`Invoke-Mt5ExecutionHost`・`Invoke-Mt5Execution`のパラメータリネーム）、`tools/run-strategy-tester.ps1`・`tools/run-mql5-tests.ps1`（`HostUseHiddenDesktop`→`HostUseIsolatedSession`リネーム）、`tools/test-mt5-execution-backend.ps1`（非表示デスクトップ使い回しテスト削除、タスクスケジューラ登録可否の事前チェック追加、パラメータ名更新）、`docs/mt5-development.md`（説明更新）
* **重大な制約が判明した。** 本セッションの検証環境（Claude CodeのBash/PowerShellツール実行コンテキスト）では、`whoami /priv`で確認したところ非常に限定された特権のみが有効な制限付きトークンで動作しており、`Register-ScheduledTask`が「アクセスが拒否されました」で一貫して失敗した。このため、既定経路（`UseIsolatedSession=true`、タスクスケジューラ方式）の動作確認は本セッションでは一切できていない。`tools/test-mt5-execution-backend.ps1`は冒頭でタスク登録可否を事前確認し、不可の場合は該当テストをスキップする設計にした（実行結果に`SKIP_NOTE`として明示される）
* 確認できたのは、フォールバック経路（`-HostUseIsolatedSession $false`、従来の`-WindowStyle Hidden`方式）の正常系・タイムアウト・ConfigFilePath自動引数生成・VM設定検証系のみ（2026-09-08、Host環境で実行、全PASS）。PowerShellパーサーによる構文チェックも4ファイルで実施し構文エラー無し
* **タスクスケジューラ方式そのものが実際に動作するか（terminal64.exeが起動でき、画面表示・フォーカス奪取が無く、正常にreportを生成できるか）は完全に未検証。** ユーザーの実機（通常の対話ログオンセッション、UACの分割トークンではあるが管理者アカウントでの通常利用）で`Register-ScheduledTask`が成功するかどうかを含め、`run-strategy-tester.ps1`（Hostモード）を実際に実行して確認する必要がある
* もしユーザーの実機でも同様に`Register-ScheduledTask`がアクセス拒否になる場合、S4Uログオンには`SeBatchLogonRight`相当の権利が必要になるケースがあるため、ローカルセキュリティポリシーでの権利付与（要管理者権限、ユーザーへの事前確認が必要）を検討するか、`-HostUseIsolatedSession $false`（画面表示は発生するが動作実績のある方式）を実運用の既定として使うことを検討する

---

# DEC-035: タスクスケジューラのタスク登録・Action変更は管理者権限で1回だけ行い、日常実行は固定タスクの起動のみで完結させる

**状態:** 採用（DEC-034の実装詳細を修正）

## 背景

DEC-034で導入したタスクスケジューラ方式（`Invoke-Mt5ExecutionHostViaScheduledTask`、実行のたびに一意な名前のタスクを`Register-ScheduledTask`で作成）を実機検証したところ、次が判明した。

* 通常の（管理者として昇格していない）PowerShellセッションから`Register-ScheduledTask`（S4Uログオンでのタスク登録）を呼ぶと「アクセスが拒否されました」になる。これはこの検証環境固有の制約ではなく、ユーザーの実機でも再現した。UACの権限分割トークン（Administratorsグループのメンバーであっても、昇格していないセッションは制限されたトークンで動作する）が原因と考えられる。
* 管理者として昇格したPowerShellセッションからは`Register-ScheduledTask`が成功し、`run-strategy-tester.ps1`（Hostモード）の単発実行・5回連続実行いずれもterminal64.exeの起動からreport生成まで安定して成功した（`elapsedSeconds`が21.8〜22.1秒で安定）。
* 追加検証として、事前に登録済みのタスクに対して`Set-ScheduledTask`（Actionの更新）を非昇格セッションから呼んだところ、これも「アクセスが拒否されました」になった。一方、同じ非昇格セッションから`Start-ScheduledTask`（既存タスクの起動）を呼んだところ**成功した**。

この結果から、「タスクの新規作成・設定変更」には管理者権限が必要だが、「既存タスクを起動するだけ」なら通常権限で可能、という非対称な権限要件があることが分かった。DEC-034の実装は実行のたびに`Register-ScheduledTask`を呼ぶ設計だったため、日常のHost実行のたびに管理者権限が必要になってしまう欠点があった。

## 判断

タスクの作成・設定は初回セットアップ時に管理者権限で1回だけ行い、日常の実行は非昇格セッションからの`Start-ScheduledTask`のみで完結する設計に変更する。

1. 新規`tools/setup-mt5-scheduled-task.ps1`を追加した。管理者権限で実行することを強制し（`WindowsPrincipal.IsInRole(Administrator)`チェック）、固定名`Mt5HostIsolatedRunner`のタスクを登録する。Actionは固定（`powershell.exe -NoProfile -ExecutionPolicy Bypass -File "<repo>\tools\lib\Mt5ScheduledTaskRunner.ps1"`）にし、以降変更しない。既存タスクがあれば削除してから再登録する（再実行しても冪等）。`ExecutionTimeLimit`は呼び出しごとに異なる実際のタイムアウト秒数の検知を呼び出し側のポーリングに委ねるための最終防衛ラインとして、十分大きい固定値（12時間）にする。
2. 新規`tools/lib/Mt5ScheduledTaskRunner.ps1`を追加した。タスクから呼ばれる固定のランナースクリプトで、実行対象の情報（実行ファイルパス・引数）を`%TEMP%\Mt5ScheduledTaskRequest.json`から読み込み、`Start-Process -Wait`でterminal64.exeを起動し、終了コードを`%TEMP%\Mt5ScheduledTaskResult.json`へ書き出す。Actionが固定なため、動的な実行対象の受け渡しにはこのファイル経由の方式が必要（既存のVM/vmrun実行がExitCodeファイルを書き出して回収する設計と同じ思想）。
3. `Invoke-Mt5ExecutionHostViaScheduledTask`（`tools/lib/Mt5ExecutionBackend.psm1`）を書き換え、`Register-ScheduledTask`を呼ばなくなった。固定タスク`Mt5HostIsolatedRunner`が登録済みであることを確認し（未登録なら明確な例外）、リクエストファイルへ実行対象を書き込んでから`Start-ScheduledTask`を呼ぶ。待機・タイムアウト検知・結果ファイル回収のロジックはDEC-034のポーリング設計を踏襲する。
4. `tools/test-mt5-execution-backend.ps1`の事前チェックを、「一時タスクを試しに`Register-ScheduledTask`できるか」から「固定タスク`Mt5HostIsolatedRunner`が既に登録されているか」の確認に変更した。

## 理由

* 実機検証で「タスク作成・設定変更」と「タスク起動」の権限要件が異なることが判明したため、この非対称性を活かせば管理者権限を初回セットアップの1回に限定できる
* Actionを固定にしファイル経由で実行対象を受け渡す設計は、既存のVmrun実行（ExitCodeファイル書き出し・回収）と同じ思想であり、コードベース全体の一貫性を保てる
* リクエスト・結果ファイルは`%TEMP%`（現在のユーザー専用の一時フォルダ）に置くため、他ユーザーからはアクセスできず、Secretも含まれない（実行ファイルパスと引数のみ）

## 影響

* 追加: `tools/setup-mt5-scheduled-task.ps1`（管理者権限で1回だけ実行する初回セットアップスクリプト）、`tools/lib/Mt5ScheduledTaskRunner.ps1`（タスクから呼ばれる固定ランナー）
* 変更: `tools/lib/Mt5ExecutionBackend.psm1`（`Invoke-Mt5ExecutionHostViaScheduledTask`を固定タスク+リクエスト/結果ファイル方式へ書き換え）、`tools/test-mt5-execution-backend.ps1`（事前チェックを固定タスクの登録確認へ変更）、`docs/mt5-development.md`（初回セットアップ手順を追記）
* **実機検証で確認済み**: 管理者権限での`Register-ScheduledTask`成功、非昇格セッションからの`Start-ScheduledTask`成功、`Set-ScheduledTask`は非昇格セッションでアクセス拒否（2026-09-08、ユーザー実機）
* **本セッションでは新設計（固定タスク+リクエストファイル方式）自体の実機動作は未検証。** この開発環境ではタスクスケジューラへの登録権限が無いため、`tools/setup-mt5-scheduled-task.ps1`の実行、リクエスト/結果ファイル経由でのterminal64.exe起動、非昇格セッションでの日常実行が想定通り動作するかは、ユーザーの実機で確認する必要がある
* 構文チェックは3ファイル（新規2件・変更1件）で実施し、エラー無し。`test-mt5-execution-backend.ps1`は固定タスク未登録のため既定経路がスキップされる形で全PASSすることを確認した（2026-09-08、Host環境で実行）
