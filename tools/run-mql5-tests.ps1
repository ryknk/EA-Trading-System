# 既定ではOANDA証券MT5端末を対象とする（2026-08-16以降の本番運用Broker、DECISIONS.md DEC-023）。
# XMTrading-MT5（C:\Program Files\MetaTrader 5、Terminal Data: D0E8209F77C8CF37AD8BF550E51FF075）は
# 参考用として残しており、対象にする場合は-InstallPath/-TerminalDataを明示指定すること。
param(
    [string]$InstallPath = "C:\Program Files\OANDA MetaTrader 5",
    [string]$TerminalData = "$env:APPDATA\MetaQuotes\Terminal\EE0304F13905552AE0B5EAEFB04866EB"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$terminal = Join-Path $InstallPath "terminal64.exe"
$configDir = Join-Path $repoRoot "mt5\test-config"
$log = Join-Path $TerminalData ("MQL5\logs\" + (Get-Date -Format "yyyyMMdd") + ".log")
$tests = @("TestTrendFollowingRules", "TestMarketRegimeClassifier", "TestPositionSizer", "TestRiskGuards", "TestTradingRules", "TestDecisionApiRules", "TestAuditRules", "TestProductionSafetyRules", "TestEntryTimingAnalyzer")

if (-not (Test-Path -LiteralPath $terminal)) { throw "Terminal not found: $terminal" }
if (Get-Process terminal64 -ErrorAction SilentlyContinue) {
    throw "Close the running MetaTrader 5 instance before automated script tests."
}

$beforeCount = if (Test-Path -LiteralPath $log) { (Get-Content -LiteralPath $log -Encoding Unicode).Count } else { 0 }
$exitCodes = @{}
foreach ($test in $tests) {
    $config = Join-Path $configDir ($test + ".ini")
    $process = Start-Process -FilePath $terminal -ArgumentList @("/config:$config") -PassThru -WindowStyle Hidden
    if (-not $process.WaitForExit(30000)) {
        Stop-Process -Id $process.Id -Force
        throw "MT5 test timed out: $test"
    }
    $exitCodes[$test] = $process.ExitCode
}

$newLines = Get-Content -LiteralPath $log -Encoding Unicode | Select-Object -Skip $beforeCount
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
