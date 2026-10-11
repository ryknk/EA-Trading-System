# 既定ではOANDA証券MT5端末を対象とする（2026-08-16以降の本番運用Broker、DECISIONS.md DEC-023）。
# XMTrading-MT5（C:\Program Files\MetaTrader 5、Terminal Data: D0E8209F77C8CF37AD8BF550E51FF075）は
# 参考用として残しており、対象にする場合は-InstallPath/-TerminalDataを明示指定すること。
param(
    [string]$InstallPath = "C:\Program Files\OANDA MetaTrader 5",
    [string]$TerminalData = "$env:APPDATA\MetaQuotes\Terminal\EE0304F13905552AE0B5EAEFB04866EB",
    # MT5実行バックエンド（既定Host、従来どおりホスト上で直接terminal64.exeを起動する）。
    # VM指定時はホストのGUIフォーカスを奪わず、WinRM/PSRemoting経由でVM上のMT5を実行する。
    [ValidateSet("Host", "VM")][string]$ExecutionMode = "Host",
    [string]$VmSettingsPath = "tools\config\mt5-vm.settings.json",
    # ExecutionMode=Host専用。既定trueで画面表示・フォーカス奪取を避ける非表示デスクトップ方式
    # （CreateDesktopEx、DEC-031）を使う。管理者権限は不要。falseにすると従来の
    # -WindowStyle Hidden方式へフォールバックする。
    [bool]$HostUseIsolatedSession = $true
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $PSScriptRoot "lib\Mt5ExecutionBackend.psm1") -Force
$terminal = Join-Path $InstallPath "terminal64.exe"
$logRelativeName = "MQL5\logs\" + (Get-Date -Format "yyyyMMdd") + ".log"
$log = Join-Path $TerminalData $logRelativeName
# 製品テスト（submodule product/のmt5/test-config）と研究テスト（mt5/test-config）のTest*.iniを列挙する。
# 製品テストの一覧は製品リポジトリ側だけで管理し、開発基盤では二重管理しない（DECISIONS.md DEC-047）。
$testConfigs = [ordered]@{}
foreach ($configDir in @((Join-Path $repoRoot "product\mt5\test-config"), (Join-Path $repoRoot "mt5\test-config"))) {
    foreach ($configFile in @(Get-ChildItem -LiteralPath $configDir -Filter "Test*.ini" | Sort-Object Name)) {
        if ($testConfigs.Contains($configFile.BaseName)) { throw "テスト名が製品と研究で重複しています: $($configFile.BaseName)" }
        $testConfigs[$configFile.BaseName] = $configFile.FullName
    }
}
$tests = @($testConfigs.Keys)
if ($tests.Count -eq 0) { throw "No test configs found." }

$vmSettingsFullPath = ""
$vmTerminalDataPath = $null
if ($ExecutionMode -eq "VM") {
    $vmSettingsFullPath = if ([System.IO.Path]::IsPathRooted($VmSettingsPath)) { $VmSettingsPath } else { Join-Path $repoRoot $VmSettingsPath }
    $vmSettings = Test-Mt5VmSettings -Path $vmSettingsFullPath
    if ([string]::IsNullOrWhiteSpace($vmSettings.vmTerminalData)) {
        throw "VM設定ファイルにvmTerminalDataが必要です（ログ取得のため）: $vmSettingsFullPath"
    }
    $vmTerminalDataPath = $vmSettings.vmTerminalData
} else {
    if (-not (Test-Path -LiteralPath $terminal)) { throw "Terminal not found: $terminal" }
    if (Get-Process terminal64 -ErrorAction SilentlyContinue) {
        throw "Close the running MetaTrader 5 instance before automated script tests."
    }
}

# 全テスト実行前のログ行数を記録し、実行後に新規追記された行だけをPASS/FAIL判定に使う
# （既存Hostロジックと同じセマンティクス。VMの場合はリモートで行数のみ取得する）。
$beforeCount = if ($ExecutionMode -eq "VM") {
    Get-Mt5VmRemoteLineCount -VmSettingsPath $vmSettingsFullPath -RemotePath (Join-Path $vmTerminalDataPath $logRelativeName)
} else {
    if (Test-Path -LiteralPath $log) { (Get-Content -LiteralPath $log -Encoding Unicode).Count } else { 0 }
}

$exitCodes = @{}
foreach ($test in $tests) {
    $config = $testConfigs[$test]
    if ($ExecutionMode -eq "Host") {
        $execResult = Invoke-Mt5Execution -ExecutionMode Host -ExecutablePath $terminal -ConfigFilePath $config -TimeoutSeconds 30 -HostUseIsolatedSession $HostUseIsolatedSession
    } else {
        $execResult = Invoke-Mt5Execution -ExecutionMode VM -VmSettingsPath $vmSettingsFullPath -ConfigFilePath $config -TimeoutSeconds 30
    }
    $exitCodes[$test] = $execResult.ExitCode
}

if ($ExecutionMode -eq "VM") {
    $stagingRoot = Join-Path $repoRoot "results\mql5-tests\_vm-staging"
    $stagingRoots = Sync-Mt5VmPaths -VmSettingsPath $vmSettingsFullPath -SourcePaths @($vmTerminalDataPath) -StagingRoot $stagingRoot
    if ($stagingRoots.Count -eq 0) { throw "VMからのログ同期に失敗しました（vmTerminalData: $vmTerminalDataPath）。" }
    $localLogPath = Join-Path $stagingRoots[0] $logRelativeName
    if (-not (Test-Path -LiteralPath $localLogPath)) { throw "VMから同期したログが見つかりません: $localLogPath" }
    $logLines = Get-Content -LiteralPath $localLogPath -Encoding Unicode
} else {
    $logLines = Get-Content -LiteralPath $log -Encoding Unicode
}

$newLines = $logLines | Select-Object -Skip $beforeCount
foreach ($test in $tests) {
    if (-not ($newLines | Select-String -SimpleMatch "TEST_SUITE_PASS $test")) {
        $newLines | Select-Object -Last 80
        throw "PASS marker not found: $test"
    }
    Write-Host "PASS runtime $test (terminal exit $($exitCodes[$test]))"
}
if ($newLines | Select-String -Pattern "\tFAIL |TEST_SUITE_FAIL") {
    throw "One or more MQL5 assertions failed."
}
