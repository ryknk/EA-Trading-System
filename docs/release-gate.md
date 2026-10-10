# リリースゲート

## 結論

Phase 12完了は「ソフトウェア構造と開発検証手順が完成した」ことを意味し、実口座運用の承認を意味しない。現時点ではAWS未配備、実データMLモデル未配備、LLM実疎通未実施、MQL5 VPS秘密ファイル未検証、OOS・Walk Forward・デモ・小額実口座の証跡未作成である。したがってproductionゲートは不合格であり、`InpEnableTradeMutations`、`InpDecisionApiEnabled`、`InpTelemetryEnabled`、`InpHeartbeatEnabled` はfalseを維持する。

## 開発ゲート

次を実行すると、必須文書、安全なMQL5初期値（`InpHeartbeatEnabled=false`を含む）、既存ポジション監視が外部判断APIより先に実行されHeartbeatが`OnTick`から分離されていることの静的検査、基本的な秘密情報混入、JSON契約、Python・Lambda・CDK全テスト、CDK synth、MetaEditor実コンパイル、MT5 script testを順に検証する。MT5端末は事前に閉じる。

```powershell
.\tools\release-gate.ps1 -Mode Development
```

このコマンドはAWS deploy、外部API呼出し、発注を行わない。成功時だけ `RELEASE_GATE_PASS mode=Development` を表示する。

## 本番ゲート

productionでは、開発ゲートに加えて `production-release-evidence.schema.json` に従う証跡JSONと、同じディレクトリに置いたOOS、Walk Forward、デモ、小額実口座、ベンチマーク比較のレポートを要求する。

```powershell
.\tools\release-gate.ps1 `
  -Mode Production `
  -EvidenceFile release-evidence\production-release.json
```

証跡には秘密値や口座番号を含めない。ML model versionとSHA-256、固定LLM provider/model、prompt version、AWS account・region、VPS秘密ファイル検証、SNS通知、予算通知、rollback drill、ベンチマーク受入基準の合否、承認UTC時刻だけを記録する。詳細レポートは暗号化したS3等へ保管し、ローカル `release-evidence/` はGit管理外とする。

## 必須ゲート

- Strategy Tester、OOS、Walk Forwardが事前固定した受入基準を満たす
- DemoでAPI障害、ML・LLM障害、不正JSON、時刻ずれ、spread拡大、Risk lockを試験する
- 小額実口座で十分な取引数と期間を確保し、バックテストとの差異をレビューする
- 1取引0.5%、日次2%、最大DD10%、最大position、証拠金余力を再確認する
- ナンピン・マーチンゲール・ロット増加ロジックがないことをレビューする
- AWS account・region・environment、PITR、RETAIN、ログ保持、SNS、Budgetsを確認する
- MQL5 VPSで共有鍵ファイルが読めることを実機検証する。検証不能なら外部APIと発注を有効化しない
- Decision/Telemetry/Heartbeat URLをWebRequest許可リストへ登録し、dev・demoでHMAC疎通する
- Heartbeat欠損AlarmのALARM・OK通知到達と、Heartbeat障害中も既存ポジション管理が継続することを確認する
- 緊急停止、手動決済、認証失効、モデル切戻し、CDK rollbackを演習する
- 変更内容、設定差分、テスト結果、承認者、承認時刻を保全する
- 下記「ベンチマーク受入基準」を満たす

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
* 数値基準そのものは未決定である（本書のベンチマーク受入基準を除く）。本番証跡JSON（`production-release-evidence.schema.json`）とmanifestの関連づけは未実装（`TASKS.md` 10章）。

## フラグ有効化順序

試験運用（Demo・小額実口座）は製品ビルド `ProductEA` で行う（2026-10-11、`DECISIONS.md` DEC-046）。`ProductEA` には `InpDecisionApiEnabled`・`InpTelemetryEnabled`・`InpHeartbeatEnabled` が存在しないため、製品の試験運用では `InpEnableTradeMutations=false` での観測 → 障害・Kill Switch試験 → 明示的な許可後の `InpEnableTradeMutations=true` の順とし、手順は `docs/operations.md`「製品ビルドによる試験運用」に従う。

本番証跡（`production-release-evidence.schema.json`、`release-gate.ps1 -Mode Production`）は、ML model・LLM・AWS account等の外部連携を前提とした項目を必須にしており、外部連携を持たない製品ビルドの証跡とは整合していない。製品ビルド用の本番証跡項目は未決定である（`TASKS.md` 11章）。

以下は研究ビルド `CoreEA` でAWS連携を検証する場合の順序である。

1. devでAWSをdeployし、モデル・LLM・監視を検証する。
2. demoで `InpHeartbeatEnabled=true`、`InpDecisionApiEnabled=true`、`InpTelemetryEnabled=true`、`InpEnableTradeMutations=false` とし、稼働監視・判断・監査だけを確認する。
3. demoで全障害試験後に `InpEnableTradeMutations=true` とする。
4. 小額実口座で同じ順序を繰り返す。
5. production証跡が揃った後にだけproduction設定を承認する。

いずれかの検証が失敗した場合は前段へ戻す。外部ALLOWを保存して後から再発注したり、障害復旧時に古い候補を再利用したりしない。
