# リリースゲート

## 結論

Phase 12完了は「ソフトウェア構造と開発検証手順が完成した」ことを意味し、実口座運用の承認を意味しない。現時点ではAWS未配備、実データMLモデル未配備、LLM実疎通未実施、MQL5 VPS秘密ファイル未検証、OOS・Walk Forward・デモ・小額実口座の証跡未作成である。したがってproductionゲートは不合格であり、`InpEnableTradeMutations`、`InpDecisionApiEnabled`、`InpTelemetryEnabled` はfalseを維持する。

## 開発ゲート

次を実行すると、必須文書、安全なMQL5初期値、基本的な秘密情報混入、JSON契約、Python・Lambda・CDK全テスト、CDK synth、MetaEditor実コンパイル、MT5 script testを順に検証する。MT5端末は事前に閉じる。

```powershell
.\tools\release-gate.ps1 -Mode Development
```

このコマンドはAWS deploy、外部API呼出し、発注を行わない。成功時だけ `RELEASE_GATE_PASS mode=Development` を表示する。

## 本番ゲート

productionでは、開発ゲートに加えて `production-release-evidence.schema.json` に従う証跡JSONと、同じディレクトリに置いたOOS、Walk Forward、デモ、小額実口座のレポートを要求する。

```powershell
.\tools\release-gate.ps1 `
  -Mode Production `
  -EvidenceFile release-evidence\production-release.json
```

証跡には秘密値や口座番号を含めない。ML model versionとSHA-256、固定LLM provider/model、prompt version、AWS account・region、VPS秘密ファイル検証、SNS通知、予算通知、rollback drill、承認UTC時刻だけを記録する。詳細レポートは暗号化したS3等へ保管し、ローカル `release-evidence/` はGit管理外とする。

## 必須ゲート

- Strategy Tester、OOS、Walk Forwardが事前固定した受入基準を満たす
- DemoでAPI障害、ML・LLM障害、不正JSON、時刻ずれ、spread拡大、Risk lockを試験する
- 小額実口座で十分な取引数と期間を確保し、バックテストとの差異をレビューする
- 1取引0.5%、日次2%、最大DD10%、最大position、証拠金余力を再確認する
- ナンピン・マーチンゲール・ロット増加ロジックがないことをレビューする
- AWS account・region・environment、PITR、RETAIN、ログ保持、SNS、Budgetsを確認する
- MQL5 VPSで共有鍵ファイルが読めることを実機検証する。検証不能なら外部APIと発注を有効化しない
- Decision/Telemetry URLをWebRequest許可リストへ登録し、dev・demoでHMAC疎通する
- 緊急停止、手動決済、認証失効、モデル切戻し、CDK rollbackを演習する
- 変更内容、設定差分、テスト結果、承認者、承認時刻を保全する

## フラグ有効化順序

1. devでAWSをdeployし、モデル・LLM・監視を検証する。
2. demoで `InpDecisionApiEnabled=true`、`InpTelemetryEnabled=true`、`InpEnableTradeMutations=false` とし、判断と監査だけを確認する。
3. demoで全障害試験後に `InpEnableTradeMutations=true` とする。
4. 小額実口座で同じ順序を繰り返す。
5. production証跡が揃った後にだけproduction設定を承認する。

いずれかの検証が失敗した場合は前段へ戻す。外部ALLOWを保存して後から再発注したり、障害復旧時に古い候補を再利用したりしない。
