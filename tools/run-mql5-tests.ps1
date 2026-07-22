param(
    [string]$InstallPath = "C:\Program Files\MetaTrader 5",
    [string]$TerminalData = "$env:APPDATA\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$terminal = Join-Path $InstallPath "terminal64.exe"
$configDir = Join-Path $repoRoot "mt5\test-config"
$log = Join-Path $TerminalData ("MQL5\logs\" + (Get-Date -Format "yyyyMMdd") + ".log")
$tests = @("TestTrendFollowingRules", "TestPositionSizer", "TestRiskGuards", "TestTradingRules", "TestDecisionApiRules", "TestAuditRules", "TestProductionSafetyRules")

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
