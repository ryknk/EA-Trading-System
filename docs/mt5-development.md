# MT5ローカル開発

## 現在のインストール環境

- インストール先: `C:\Program Files\MetaTrader 5`
- データフォルダ: `C:\Users\hunda\AppData\Roaming\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075`

次のディレクトリジャンクションにより、リポジトリのソースとMT5ナビゲーターツリーが同じファイルを参照する。

- `MQL5\Include\EaTradingSystem` → `repo\mt5\Include`
- `MQL5\Experts\EaTradingSystem` → `repo\mt5\Experts`
- `MQL5\Scripts\EaTradingSystemTests` → `repo\mt5\Tests`

これらのパスへファイルを上書きコピーしたり、標準の `MQL5\Include` ディレクトリを置き換えたりしてはならない。MT5を再インストールした後は、次のコマンドでリンクを再作成または検証する。

```powershell
.\tools\link-mt5.ps1
```

ソースの変更は両方の場所へ即時反映される。MT5が実行するのはEX5バイナリであるため、ソース変更後は次のコマンドでコンパイルする。

```powershell
.\tools\compile-mql5.ps1
```

ライブ取引を無効にした一時的なターミナルセッションで、純粋ルールテストをすべて実行する。

```powershell
.\tools\run-mql5-tests.ps1
```

自動実行時は通常のMT5ターミナルを閉じておく必要がある。各テストは `AllowLiveTrading=0` と `ShutdownTerminal=1` を指定した読み取り専用の起動設定を使用する。コンパイラ出力は `build/metaeditor` に保存され、生成されたEX5ファイルはジャンクションを通じてソースと同じ場所へ配置される。どちらもGitの管理対象外である。

## 2026年7月21日の検証結果

- MetaTrader 5 x64 ビルド6034
- CoreEAおよび6本のテストスクリプト: エラー0件、警告0件
- TestTrendFollowingRules: 成功（11項目）
- TestPositionSizer: 成功（5項目）
- TestRiskGuards: 成功（12項目）
- TestTradingRules: 成功（18項目）
- TestDecisionApiRules: 成功（18項目）
- TestAuditRules: 成功（7項目）
- 合計: 71項目、失敗0件

Phase 12時点でAWS実装は存在するが、AWS accountへのdeploy、実モデル、LLM実疎通は未実施である。CoreEAは実コンパイル済みだが、実口座の取引変更には使用していない。テストスクリプトに取引操作は含まれず、ライブ取引を無効にして実行している。

## MQL5 VPS移行

1. ローカル端末でCoreEAをコンパイルし、`InpEnableTradeMutations=false`、`InpDecisionApiEnabled=false`、`InpTelemetryEnabled=false` のままチャートへ適用する。
2. chart symbol、timeframe、EA input、magic number、AutoTrading、アルゴリズム取引許可を確認する。
3. Decision APIとTelemetry APIのHTTPS URLをMT5のWebRequest許可リストへ登録する。URLのpath末尾を取り違えない。
4. `MQL5\Files\EaTradingSystem\decision-api-secret.txt` をローカルで読み込めることを確認し、秘密値や署名がJournalへ出ないことを確認する。
5. チャートとEA環境をMQL5 VPSへ同期する。Python、Web server、AWS SDK、学習modelをVPSへ置かない。
6. VPS JournalでEA初期化、symbol仕様、UTC時刻、WebRequest、監査ファイルを確認する。
7. MQL5 VPSへの同期で任意の秘密ファイルが確実に移行される保証はない。VPS上で共有鍵ファイル読込を実機確認できない場合、Decision APIと取引変更を有効化しない。
8. demoでは最初にDecision・Telemetryだけを有効化し、`InpEnableTradeMutations=false` のまま候補、VETO、監査を確認する。
9. timeout、不正JSON、AWS停止、LLM停止、spread超過、Daily Loss、Drawdown lockを試験した後にだけdemoの取引変更を有効化する。

同期後にローカル側のチャート・設定を変更しても、自動的にVPSへ反映されるとは限らない。変更ごとに再同期し、VPS Journalの再起動・初期化記録を確認する。

## ロールバック

異常時は `InpEmergencyStop=true` またはAutoTrading停止で新規注文を止め、未決済ポジションと保護SLを確認する。必要な既存ポジション管理まで無条件に停止しない。前版EX5と設定へ戻す場合も、古い外部ALLOWや候補IDを再利用しない。共有鍵漏えい時はAWS側Parameter Store値を更新し、旧key IDを失効させてからVPSへ再配布する。
