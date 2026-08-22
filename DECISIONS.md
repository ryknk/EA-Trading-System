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
