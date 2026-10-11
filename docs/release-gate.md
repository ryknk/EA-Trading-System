# リリースゲート

## 結論

Phase 12完了は「ソフトウェア構造と開発検証手順が完成した」ことを意味し、実口座運用の承認を意味しない。本番移行の対象は製品ビルド `ProductEA`（外部連携なし、DEC-046・DEC-047）であり、本番証跡はschema 2.0（DEC-049）で判定する。

2026-10-12時点で、productionゲートは不合格である。次が未完了のため、本番証跡を作成できない。

* 製品ビルドで、事前に固定した合否基準ファイルと `validation_layer` を指定したCaseFileによるWalk Forward・Final Holdoutの実行（Final Holdout期間 2025-01〜2026-08 は2026-09-17に消費済みで、新しい期間の確保方法は未決定。合否基準の数値も未決定）
* ベンチマーク受入基準の判定
* Demo口座・小額実口座での試験運用、MQL5 VPS上でのプッシュ通知の受信確認、Kill Switch・Rollbackの演習

`InpEnableTradeMutations` はfalseを維持する。研究ビルドの外部連携入力（`InpDecisionApiEnabled`、`InpTelemetryEnabled`、`InpHeartbeatEnabled`）もfalseを維持する（研究ビルドのAWS連携は、AWS未配備・実データMLモデル未配備・LLM実疎通未実施のまま）。

## 開発ゲート

次を実行すると、必須文書、製品submodule（`product/`）が開発基盤に記録したcommitと一致すること、安全なMQL5初期値（`InpHeartbeatEnabled=false`を含む。製品の `EAEntryPoint.mqh` を検査）、製品EAが研究ビルドのマクロを定義しないこと、既存ポジション監視が外部判断API・Risk Managerの新規注文評価より先に実行されHeartbeatが`OnTick`から分離されていることの静的検査、CaseFile・検証識別情報の単体テスト（`tools/test-validation-manifest.ps1`）、本番証跡検証の回帰テスト（`tools/test-release-gate-evidence.ps1`）、基本的な秘密情報混入、JSON契約、Python・Lambda・CDK全テスト、CDK synth、MetaEditor実コンパイル（製品・研究ビルドと両リポジトリのテスト）、MT5 script testを順に検証する。MT5端末は事前に閉じる。

```powershell
.\tools\release-gate.ps1 -Mode Development
```

このコマンドはAWS deploy、外部API呼出し、発注を行わない。成功時だけ `RELEASE_GATE_PASS mode=Development` を表示する。

## 本番ゲート

productionでは、開発ゲートに加えて `production-release-evidence.schema.json`（schema 2.0、製品ビルド `ProductEA` 用、2026-10-12改訂、`DECISIONS.md` DEC-049）に従う証跡JSONと、同じディレクトリに置いたレポート・Strategy Testerの `manifest.json` を要求する。検証は `tools/lib/ReleaseEvidence.psm1` が行い、回帰テスト `tools/test-release-gate-evidence.ps1` は開発ゲートで毎回実行する。

```powershell
.\tools\release-gate.ps1 `
  -Mode Production `
  -EvidenceFile release-evidence\production-release.json
```

証跡に記録する項目（秘密値・口座番号は含めない。パスはすべて証跡JSONと同じディレクトリ配下の相対パス）:

| 項目 | 内容 | ゲートの照合 |
| --- | --- | --- |
| `product` | `repository`（`ryknk/EA-Product`）、`commit`、`expert`（`EaTradingSystemProduct\ProductEA`）、`ea_version`、`ex5_sha256`（リリースするex5） | `commit` が開発基盤の製品submoduleのcommit（ゲートが静的検査・コンパイル・テストした対象）と一致すること |
| `validation_manifests` | Strategy Testerの `manifest.json`（schema 1.1）の写し | 全件で製品commit一致・`dirty=false`、全ケースが `Succeeded`・製品ビルド・同じex5・`expert_ex5_older_than_source=false`・同じEAバージョン、`acceptance_criteria` が記録され基準ファイル（開発基盤のパス）のSHA-256が実行時から変わっていないこと。全体で `validation_layer` に `walk_forward` と `final_holdout` を含むこと |
| `oos_report`・`walk_forward_report`・`final_holdout_report`・`demo_report`・`small_real_report`・`benchmark_comparison_report` | 各レポート | 実在すること |
| `demo_ex5_sha256`・`small_real_ex5_sha256` | 試験運用で使ったex5のSHA-256 | `product.ex5_sha256` と一致すること |
| `push_notification_verified` | MQL5 VPS上のEAから起動通知・日次稼働報告が届くことを確認した | `true` |
| `kill_switch_drill_verified` | 緊急停止・戦略停止で新規注文が止まり、既存ポジション管理が継続することを実ポジション保有中に確認した | `true` |
| `rollback_drill_verified` | 前の製品commitのex5へ戻す手順を演習した | `true` |
| `risk_limits_reviewed` | 1取引0.5%・日次2%・最大DD10%・最大ポジション・証拠金余力の設定を確認した | `true` |
| `benchmark_criteria_met` | 下記「ベンチマーク受入基準」を満たした | `true` |
| `approver`・`approved_at` | 承認者、承認UTC時刻 | `approved_at` は `Z` または `+00:00` のUTC |

ex5のSHA-256は大文字・小文字を区別しない（manifestは大文字で記録する）。詳細レポートは暗号化して保管し、ローカル `release-evidence/` はGit管理外とする。

旧schema 1.0（ML model・LLM・AWS account・SNS・Budgets・VPS秘密ファイル）は研究ビルドのAWS連携を前提としていたため廃止した。研究ビルド `CoreEA` は本番運用の対象ではない（DEC-046・DEC-047）。

## 必須ゲート

製品ビルド `ProductEA` の本番移行で満たすこと（証跡の各項目に対応する）:

- Strategy Tester、OOS、Walk Forward、Final Holdoutを、リリースする製品commit・ex5で、事前に固定した合否基準（`acceptance_criteria`）のもとで実行し、基準を満たす
- Demoで切断、spread拡大、Risk Lock、Kill Switchを試験する
- 小額実口座で十分な取引数と期間を確保し、バックテストとの差異をレビューする（Demo・小額実口座は検証と同じex5で行う）
- 1取引0.5%、日次2%、最大DD10%、最大position、証拠金余力を再確認する
- ナンピン・マーチンゲール・ロット増加ロジックがないことをレビューする
- MQL5 VPS上のEAから起動通知・日次稼働報告が届くことを確認する（`docs/operations.md`「稼働監視」）
- 緊急停止、手動決済、前の製品commitのex5への切戻しを演習する
- 変更内容、設定差分、テスト結果、承認者、承認時刻を保全する
- 下記「ベンチマーク受入基準」を満たす

研究ビルド `CoreEA` でAWS連携（Decision API・ML/LLM・Telemetry・Heartbeat）を本番運用する場合は、AWS account・region・PITR・RETAIN・ログ保持・SNS・Budgets、MQL5 VPSでの共有鍵ファイル読込、WebRequest許可リストとHMAC疎通、Heartbeat欠損Alarmの通知到達、認証失効・モデル切戻し・CDK rollbackの演習が別途必要になる。現在この運用は対象外であり、本番証跡schema 2.0も対応していない。

## ベンチマーク受入基準

EAの運用資金は、NISA非課税枠を超えた資産を想定する。EAを使わない場合、この資金は課税口座でインデックス投資へ回すことになるため、EAはその代替案を上回らない限り使う意義がない（`DECISIONS.md` DEC-041）。この基準は結果を見る前に固定したものであり、結果を見た後に緩和しない。変更する場合は `DECISIONS.md` へ理由を記録し、既に評価済みの期間は合否判定へ使わない。

### 比較対象

- ベンチマーク: MSCI ACWI（全世界株式、配当込み、円換算）。代表的な連動インデックスファンドの信託報酬（年率）を控除し、採用した値をレポートへ記録する。
- 比較期間: EAの評価期間と同一の期間とする。
- 投入資金: EAの割当資金（Strategy Testerの `Deposit`）と同額を、期間の開始時にベンチマークへ一括投資したものとする。

### 税の扱い

- EA: 国内FX・CFDの申告分離課税20.315%を、暦年ごとの純損益へ適用する。損失は翌年以降3年間の繰越控除を適用する。
- ベンチマーク: 期間中は課税せず、期間の終了時に全額を売却したものとして、譲渡益へ20.315%を適用する（課税繰延の効果を反映する）。
- EAの損益には、spread、手数料、swapを含める。

### 合格条件

次の2つを、**Walk Forward（全Fold合算）とFinal Holdoutのそれぞれで**満たすこと。どちらか一方でも満たさない場合、他のゲートの結果に関わらずproductionゲートは不合格とする。

1. **税引き後の年率リターン**: EAの税引き後の年率リターン（CAGR）が、ベンチマークの税引き後の年率リターンを上回る。
2. **Sharpe比**: 月次リターン（税引き前、リスクフリーレート0、年率換算）から計算したEAのSharpe比が、ベンチマークのSharpe比を上回る。

Demo口座と小額実口座は期間が短いため、この基準の合否には使わず、バックテストとの差異のレビューにだけ使う。

### 証跡

比較結果は `python.analysis.benchmark_comparison` で作成し（使い方は `docs/backtesting.md`「ベンチマーク比較」節）、出力の `benchmark-comparison.json` を `benchmark_comparison_report` として本番証跡へ添付し、合格条件をすべて満たした場合だけ `benchmark_criteria_met` を `true` とする。`true` でない証跡は `release-gate.ps1 -Mode Production` が拒否する。レポートには、ベンチマークのデータ源と取得日、控除した信託報酬、各期間の税引き前・税引き後のCAGRとSharpe比、年次損益と繰越控除の計算過程を記録する。

## 検証結果・合否基準・対象commitの関連づけ（2026-10-10追加）

Strategy Tester系の検証結果は、`tools/run-strategy-tester.ps1 -CaseFile` が出力する `manifest.json`（schema 1.1）で次を相互に関連づける（`docs/backtesting.md`「検証メタデータ」、`docs/product-separation.md`）。

* 検証対象: 製品EAソースのcommit・未コミット変更の有無・ソースハッシュ、EAバージョン、実行したex5のSHA-256、MT5端末バージョン
* 検証条件: CaseFile・Template・実効tester.iniのSHA-256、データセットmanifestのSHA-256（指定時）
* 合否基準: CaseFileの `acceptance_criteria` で指定した基準ファイルのパスとSHA-256（実行前に実在を確認する）
* 検証レイヤーと合否区分: `validation_layer` と、そこから導出する `gate_category`（performance / safety）

運用ルール:

* 合否基準ファイルは、評価対象の結果を得る前にコミットする。結果を見た後に変更した場合は、変更後の基準でその期間を合否判定に使わない（ベンチマーク受入基準と同じ扱い）。
* `provenance.product.dirty=true` の結果、`expert_ex5_older_than_source=true` の結果は本番証跡に使わない。
* 性能（performance）と安全機能（safety）の合否は別々に判定する。Profit Factorだけで合否を決めない。
* 数値基準そのものは未決定である（本書のベンチマーク受入基準を除く）。
* 本番証跡（schema 2.0）は、添付したmanifestについて上記の識別情報と合否基準の不変性をゲートで照合する（「本番ゲート」節）。

## フラグ有効化順序

試験運用（Demo・小額実口座）は製品ビルド `ProductEA` で行う（2026-10-11、`DECISIONS.md` DEC-046）。`ProductEA` には `InpDecisionApiEnabled`・`InpTelemetryEnabled`・`InpHeartbeatEnabled` が存在しないため、製品の試験運用では `InpEnableTradeMutations=false` での観測 → 障害・Kill Switch試験 → 明示的な許可後の `InpEnableTradeMutations=true` の順とし、手順は `docs/operations.md`「製品ビルドによる試験運用」に従う。

本番証跡は製品ビルド用のschema 2.0に改訂した（2026-10-12、DEC-049、「本番ゲート」節）。

以下は研究ビルド `CoreEA` でAWS連携を検証する場合の順序である。

1. devでAWSをdeployし、モデル・LLM・監視を検証する。
2. demoで `InpHeartbeatEnabled=true`、`InpDecisionApiEnabled=true`、`InpTelemetryEnabled=true`、`InpEnableTradeMutations=false` とし、稼働監視・判断・監査だけを確認する。
3. demoで全障害試験後に `InpEnableTradeMutations=true` とする。
4. 小額実口座で同じ順序を繰り返す。
5. production証跡が揃った後にだけproduction設定を承認する。

いずれかの検証が失敗した場合は前段へ戻す。外部ALLOWを保存して後から再発注したり、障害復旧時に古い候補を再利用したりしない。
