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

## Strategy Tester / MQL5単体テストのVM実行（2026-09-06追加）

Strategy Tester・MQL5単体テスト実行中はMT5 GUIがホストの対話デスクトップへ一瞬表示されるため、ホスト側の作業・ゲームのフォーカスが奪われることがある。これを避けたい場合、MT5を隔離VM内で実行できる（詳細な設計判断は`DECISIONS.md` DEC-029を参照）。

`tools/run-strategy-tester.ps1`・`tools/run-mql5-tests.ps1`はいずれも`-ExecutionMode Host|VM`を受け付ける（既定`Host`、省略時は従来どおりホスト上で直接実行する）。実際のMT5起動・待機・タイムアウト・終了コード取得・VM実行時の結果ファイル同期は、共通モジュール`tools/lib/Mt5ExecutionBackend.psm1`が担う。

VM実行時の接続方式はVM設定ファイルの`connectionType`で選択する（詳細な設計判断は`DECISIONS.md` DEC-029を参照）。

* `Vmrun`（既定・優先） — VMware Workstation/Player付属の`vmrun`コマンドラインツールでゲストOS内のMT5を直接実行する。ゲスト側のIPアドレス管理やWinRM設定は不要。
* `WinRm` — 汎用WinRM/PSRemoting。Hypervisor製品を問わないが、ゲスト側で事前にWinRMを有効化する必要がある。

### VMware Workstation/Player（vmrun、既定）を使う場合の事前準備（ユーザー作業）

1. VMware Workstation ProまたはPlayerで、MT5専用のWindows VMを作成する。
2. VM側にVMware Toolsをインストールする（`vmrun runProgramInGuest`等のゲスト操作にVMware Toolsが必須）。
3. VM上へMT5端末をインストールし、`tools/link-mt5.ps1`相当のジャンクション設定・EAコンパイルをVM上でも実施する（Python・Web Server・AWS SDK・学習ModelはVMへ置かない。MQL5 VPS移行時の注意点と同様）。
4. VM上にホストからConfigファイルを受け取るための作業フォルダ（例: `C:\Mt5Exchange\config`、`vmSharedConfigPath`）を用意する。
5. `tools/config/mt5-vm.settings.example.json`をコピーして`tools/config/mt5-vm.settings.json`を作成し、`connectionType: "Vmrun"`のまま`vmxPath`（VMの`.vmx`ファイルへのホスト側パス）・`userName`（ゲストOSのユーザー名）・`vmExecutablePath`・`vmSharedConfigPath`・`vmTerminalData`・（Strategy Testerで使うなら）`vmInstallPath`を設定する。`vmrunPath`は既定（`C:\Program Files (x86)\VMware\VMware Workstation\vmrun.exe`）と異なる場合のみ指定する。このファイルは`.gitignore`対象でありコミットしない。
6. 資格情報（ゲストOSのログインパスワード）はファイルへ書かない。既定の`credentialSource: "Prompt"`では実行のたびに`Get-Credential`で対話入力する。非対話実行が必要な場合のみ`credentialSource: "EnvironmentVariable"`とし、`credentialEnvVarName`で指定した環境変数（値はセッション内でのみ設定し、リポジトリ・ログへ残さない）からパスワードを読む。
7. **VM暗号化（Encryption）を有効にしている場合**: これはゲストOSログインパスワードとは別物の、VM自体を復号するための独立したパスワードで、vmrunの`-vp`オプションに渡す必要がある。設定ファイルで`vmEncrypted: true`とし、`encryptionCredentialSource`（`Prompt`または`EnvironmentVariable`、`credentialSource`と同じ考え方だがユーザー名は不要）を設定する。
   - VM暗号化パスワードをWindows資格情報マネージャーへ自動生成・保存済みで値を控えていない場合、本ツールはその値を資格情報ストアから読み出す機能を持たない（認証情報窃取ツールと区別しづらい処理のため実装していない）。VMware Workstationのメニューから対象VMの暗号化パスワードを、自分で管理できる値へ変更するか、暗号化自体が不要であれば解除（Decrypt）してから利用すること。
   - **VM暗号化パスワードを紛失すると、VMware Workstation自体に復旧手段はない**（VM内のデータへ二度とアクセスできなくなる）。パスワードを変更・設定した際は必ず別途安全な場所に控えておくこと。
8. **既知の制約**: `vmrun`の`-gp`（ゲストパスワード）・`-vp`（VM暗号化パスワード）オプションはいずれもコマンドライン引数として渡される仕様のため、実行中は同一ホスト上の他プロセスから一時的にプロセスの起動コマンドラインとして見える可能性がある。ログ・例外メッセージへはマスキングして出力しないが、完全な排除はできない（vmrun自体の制約）。
9. VMは実行前に起動しておく（本実装はVMの自動起動は行わない）。

### WinRM/PSRemotingを使う場合の事前準備（ユーザー作業）

1. MT5専用のWindows VMを用意する（Hyper-V、VirtualBox等、VMware以外でも可）。
2. VM上でWinRMを有効化する（VM内の管理者PowerShellで`Enable-PSRemoting -Force`。ホストとVMが別ドメイン・ワークグループの場合は`TrustedHosts`設定が別途必要になる場合がある）。
3. VM上へMT5端末をインストールし、`tools/link-mt5.ps1`相当のジャンクション設定・EAコンパイルをVM上でも実施する。
4. VM上にホストからConfigファイルを受け取るための共有フォルダ（例: `C:\Mt5Exchange\config`）を用意する。
5. `tools/config/mt5-vm.settings.example.json`をコピーして`tools/config/mt5-vm.settings.json`を作成し、`connectionType: "WinRm"`にした上で`computerName`・`userName`・`vmExecutablePath`・`vmSharedConfigPath`・`vmTerminalData`・（Strategy Testerで使うなら）`vmInstallPath`を設定する。
6. 資格情報の扱いはVmrun方式と同様（対話入力または環境変数経由のみ、ファイルへ書かない）。

### 実行コマンド例

```powershell
# Host実行（既定、従来どおり）
.\tools\run-strategy-tester.ps1 -Symbol USDJPY -FromDate 2017.09.01 -ToDate 2020.12.31 -Template mt5\test-config\StrategyTester-USDJPY-H1.ini

# VM実行（VM設定ファイルのconnectionTypeで接続方式を選択）
.\tools\run-strategy-tester.ps1 -ExecutionMode VM -Symbol USDJPY -FromDate 2017.09.01 -ToDate 2020.12.31 -Template mt5\test-config\StrategyTester-USDJPY-H1.ini

# MQL5単体テスト（Host/VM共通）
.\tools\run-mql5-tests.ps1
.\tools\run-mql5-tests.ps1 -ExecutionMode VM
```

`-ExecutionMode VM`指定時にVM設定ファイルが存在しない、または`connectionType`に応じた必須項目が不足している場合はHostへ自動フォールバックせず、明確なエラーで終了する。

### Vmrun方式の既知の制約（2026-09-06実機検証で判明）

実際のVMware Workstation VM（Windows 11ゲスト）で検証した結果、以下の制約が判明した。いずれも`tools/lib/Mt5ExecutionBackend.psm1`側で対応済みだが、VM環境やVMware Toolsのバージョンによって再発する可能性があるため記録する。

* **`runProgramInGuest`で`cmd.exe`を引数付きで実行すると失敗する。** ゲストプログラム自体は正常終了していても、vmrunが一律`Guest program exited with non-zero exit code: 1`を報告する（`cmd.exe /c dir`のような単純な例でも再現。引数なしの`cmd.exe`単体や、`cmd.exe`を介さない`ipconfig.exe`等の直接実行は問題ない）。このため、MT5起動時のExitCode取得は`cmd.exe`ではなく`powershell.exe -NoProfile -Command`経由（ゲスト内で`Start-Process -PassThru`+`WaitForExit`しExitCodeをファイルへ書き出す方式）で行っている。
* **`copyFileFromGuestToHost`は`..`を含む相対パス要素を解決できない。** 同期対象ディレクトリの一時zipファイルパスを組み立てる際、`Split-Path -Parent`で親ディレクトリを事前に正規化してから使う必要がある。
* **ゲスト内で実行するPowerShellコマンド文字列で`if (...) {A} else {B} | Set-Content ...`という構文は機能しない。** パイプがif式全体ではなく最後の分岐にのみ適用されてしまう。`$(if (...) {A} else {B}) | Set-Content ...`とサブ式化する必要がある。
* **`Start-Process -RedirectStandardOutput/-RedirectStandardError`経由の`$process.ExitCode`取得が、引数が長い・複雑なvmrun呼び出しで不定に失敗する。** Windows PowerShell 5.1（.NET Framework）での既知の癖。`System.Diagnostics.Process`を直接使い、`BeginOutputReadLine`/`BeginErrorReadLine`による非同期イベント読み取りへ置き換えて対応した。
* **`System.Diagnostics.ProcessStartInfo.ArgumentList`はWindows PowerShell 5.1（.NET Framework）に存在しない。** .NET Core専用のプロパティのため、Framework/Core両方で動くWin32互換の手動エスケープ＋`Arguments`（単一文字列）方式で実装している。対話的なPowerShell 7セッションで動作確認しても、実運用のWindows PowerShell 5.1では動かないことがある点に注意（このモジュールの動作確認は必ず`powershell.exe`＝5.1で行うこと）。
* **要素数1の配列を`return`すると、PowerShellがスカラーへ自動アンラップすることがある。** ディレクトリ同期結果（`StagingRoots`）で発生し、呼び出し側の`$stagingRoots[0]`が文字列の先頭1文字になる不具合があった。`return , $array`と`,`演算子で配列化を強制する必要がある。
* **VM内のTerminalDataフォルダ全体を無条件に同期すると、tickヒストリカルデータ（`bases`フォルダ）で数百MB〜GBに膨らみタイムアウトする。** report生成物はTerminalData直下に留まるため、VM設定`vmSyncExcludeNames`（既定`@("bases")`）で除外する。同期タイムアウトは`vmSyncTimeoutSeconds`（既定300秒）で調整できる。
* **監査JSONLはStrategy Tester Agentのサンドボックス配下に保存され、MT5終了後にサンドボックスがcleanupされると消失する（2026-09-07発見）。** VM実行はMT5終了後にTerminalData等をzip化して回収するため、HTM reportは回収できるのに監査JSONLだけ消失していた。監査JSONLを`FILE_COMMON`（`Terminal\Common\Files`配下、サンドボックスの外）で保存するよう変更し、VM設定へ`vmCommonDataPath`（省略時は`vmTerminalData`の兄弟フォルダ`Terminal\Common`を自動使用）を追加して、Common配下のAuditディレクトリだけを別途同期するようにした（詳細はDECISIONS.md DEC-030を参照）。
* VMware Toolsの`runProgramInGuest`を使う前に、対象VMがVMware Workstationのウィンドウ上で実際に起動し、ゲストOSへサインイン済み（ログイン画面のままではない）状態にしておくこと。
* **VM側の電源設定でスリープ・ディスプレイタイムアウトを無効化しておくこと。** 有効なままだと自動実行中にVMがスリープし、vmrunコマンドが原因不明のエラー（認証エラー等）で間欠的に失敗する。ゲスト内管理者PowerShellで次を実行する。
  ```powershell
  powercfg /change standby-timeout-ac 0
  powercfg /change standby-timeout-dc 0
  powercfg /change monitor-timeout-ac 0
  powercfg /change monitor-timeout-dc 0
  ```

### 検証済み事項

2026-09-06、VMware Workstation VM（Windows 11ゲスト、VM暗号化有効）へOANDA証券MT5をインストールし、`tools/link-mt5.ps1`・`tools/compile-mql5.ps1`相当のセットアップ（ソース転送、ジャンクション作成、EA・テストスクリプトのコンパイル）をvmrun経由で実施した上で、以下を実機確認した。

* `run-mql5-tests.ps1 -ExecutionMode VM` — 全12テストPASS（Hostモードと同一結果）
* `run-strategy-tester.ps1 -ExecutionMode VM`（単体実行） — `exit=0`、report（htm/png）が正しくホスト側の結果フォルダへ回収される
* Hostモードの単体実行・MQL5単体テストは、上記VM検証と並行して回帰なしを再確認済み

`connectionType: "WinRm"`側は未検証（ユーザー環境がVMware Workstationのため）。CaseFileによる複数ケース実行のVMモードは未検証。

**2026-09-07、監査JSONLのFILE_COMMON化をHost・VM/vmrun両方で実機確認した。** Hostモードで`InpAuditFileEnabled=true`のままStrategy Testerを実行し、`Terminal\Common\Files\EaTradingSystem\Audit\audit-<ReportName>.jsonl`が生成され、`results/backtests/<run>/audit/`へ従来どおり複製されること、複製したJSONLが`python.analysis.reports`で正常に分析できることを確認した。

続けて実VM（`D:\VMware\MT5-Tester\MT5-Tester.vmx`）でも実機確認した。まずVM側の`mt5`ソースコピーが本セッションの変更前（2026-09-06セットアップ時点）のままだったため、`Config.mqh`・`TradeLogger.mqh`・`CoreEA.mq5`・`TestProductionSafetyRules.mq5`をvmrunの`copyFileFromHostToGuest`で既存ジャンクション先へ転送し、VM上でMetaEditor64.exeにより全13ターゲットを再コンパイル（0 errors, 0 warnings）した後、`run-mql5-tests.ps1 -ExecutionMode VM`（全12テストPASS）・`run-strategy-tester.ps1 -ExecutionMode VM`（`exit=0`、`STRATEGY_TESTER_AUDIT_COPIED mode=VM`）を実行し、`Get-Mt5VmCommonAuditPath`が導出した`vmTerminalData`の兄弟フォルダ`Terminal\Common`配下からAuditディレクトリが正しく同期され、`results/backtests/<run>/audit/`へ複製されることを確認した。複製したJSONLは`python.analysis.reports`で正常に分析できた。これによりTASKS.md 8.1節の「audit JSONL VM実行時回収の実機確認」は完了した。

この過程で新たに以下を発見した（`tools/lib/Mt5ExecutionBackend.psm1`は未修正のツール操作手順上の注意点であり、恒久対応が必要な場合は次回以降検討する）。

* **VMゲストのPowerShell実行ポリシーが`Restricted`の場合、`runProgramInGuest`経由での`.ps1`スクリプトファイル実行（`-File`、`&`によるスクリプト呼び出し、`.`によるdot-source）はいずれもサイレントに失敗する。** vmrunは`Guest program exited with non-zero exit code: 1`のような具体的なメッセージを返さず、単に`vmrunコマンドが失敗しました（exit=1）`という汎用エラーのみを返すため原因の特定が難しい。一方、`-Command`に渡すインラインのcmdlet呼び出し（`Get-Content`・`Test-Path`・`Write-Output`等）や、`Start-Process`によるプロセス起動（本モジュールがMT5起動に使っている方式）は実行ポリシーの制約を受けず問題なく動作する。ゲスト側で`.ps1`ファイルを直接実行する必要がある場合は、`powershell.exe`の引数へ`-ExecutionPolicy Bypass`を追加すること。
