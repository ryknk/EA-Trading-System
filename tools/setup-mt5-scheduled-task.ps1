# Host実行（tools/run-strategy-tester.ps1・tools/run-mql5-tests.ps1のExecutionMode=Host、
# 既定のHostUseIsolatedSession=$true）が使うタスクスケジューラ上の固定タスクを登録する。
# 管理者権限のPowerShellから、環境ごとに1回だけ実行すること。
#
# S4Uログオン（パスワード不要）でのタスク登録(Register-ScheduledTask)・Action変更
# (Set-ScheduledTask)には管理者権限が必要である一方、既存タスクの起動(Start-ScheduledTask)は
# 通常権限でも可能なことを実機検証で確認した。そのため、タスクのActionを固定（ランナースクリプト
# tools/lib/Mt5ScheduledTaskRunner.ps1を呼ぶだけ）にして事前登録しておき、実行対象の情報
# （実行ファイルパス・引数）は都度リクエストファイル経由で受け渡す設計にすることで、日常の
# Host実行から管理者権限を排除している（DECISIONS.md DEC-035参照）。
#
# 実行例:
#   .\tools\setup-mt5-scheduled-task.ps1

$ErrorActionPreference = "Stop"

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "このスクリプトは管理者権限のPowerShellから実行してください（タスクスケジューラへのタスク登録に管理者権限が必要なため）。"
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$runnerScript = Join-Path $repoRoot "tools\lib\Mt5ScheduledTaskRunner.ps1"
if (-not (Test-Path -LiteralPath $runnerScript)) { throw "ランナースクリプトが見つかりません: $runnerScript" }

$taskName = "Mt5HostIsolatedRunner"

# 既存タスクがあれば一旦削除してから再登録する（設定変更後の再実行でも冪等に動作させるため）。
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$runnerScript`""
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType S4U -RunLevel Limited
# ExecutionTimeLimitは、呼び出しごとに異なる実際のタイムアウト秒数（TimeoutSeconds）の検知を
# 呼び出し側（Invoke-Mt5ExecutionHostViaScheduledTask）のポーリングに委ねるための最終防衛ラインで
# あり、想定される最長のStrategy Tester実行時間より十分大きい固定値（12時間）にする。
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
    -ExecutionTimeLimit ([TimeSpan]::FromHours(12)) -MultipleInstances IgnoreNew

Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Settings $settings -Force | Out-Null

Write-Host "タスク '$taskName' を登録しました。以降は通常権限のPowerShellから run-strategy-tester.ps1 / run-mql5-tests.ps1 を実行できます。"
