# 既定ではOANDA証券MT5端末を対象とする（2026-08-16以降の本番運用Broker、DECISIONS.md DEC-023）。
# XMTrading-MT5（C:\Program Files\MetaTrader 5、Terminal Data: D0E8209F77C8CF37AD8BF550E51FF075）は
# 参考用として残しており、対象にする場合は-InstallPath/-TerminalDataを明示指定すること。
param(
    [string]$InstallPath = "C:\Program Files\OANDA MetaTrader 5",
    [string]$TerminalData = "$env:APPDATA\MetaQuotes\Terminal\EE0304F13905552AE0B5EAEFB04866EB"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$editor = Join-Path $InstallPath "MetaEditor64.exe"
$mql5 = Join-Path $TerminalData "MQL5"
$logDir = Join-Path $repoRoot "build\metaeditor"

if (-not (Test-Path -LiteralPath $editor)) { throw "MetaEditor not found: $editor" }
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$targets = @(
    @{ Name = "CoreEA"; Path = Join-Path $mql5 "Experts\EaTradingSystem\CoreEA.mq5" },
    @{ Name = "TestTrendFollowingRules"; Path = Join-Path $mql5 "Scripts\EaTradingSystemTests\TestTrendFollowingRules.mq5" },
    @{ Name = "TestMarketRegimeClassifier"; Path = Join-Path $mql5 "Scripts\EaTradingSystemTests\TestMarketRegimeClassifier.mq5" },
    @{ Name = "TestPositionSizer"; Path = Join-Path $mql5 "Scripts\EaTradingSystemTests\TestPositionSizer.mq5" },
    @{ Name = "TestRiskGuards"; Path = Join-Path $mql5 "Scripts\EaTradingSystemTests\TestRiskGuards.mq5" },
    @{ Name = "TestTradingRules"; Path = Join-Path $mql5 "Scripts\EaTradingSystemTests\TestTradingRules.mq5" },
    @{ Name = "TestDecisionApiRules"; Path = Join-Path $mql5 "Scripts\EaTradingSystemTests\TestDecisionApiRules.mq5" },
    @{ Name = "TestAuditRules"; Path = Join-Path $mql5 "Scripts\EaTradingSystemTests\TestAuditRules.mq5" },
    @{ Name = "TestAuditPayloadBuilder"; Path = Join-Path $mql5 "Scripts\EaTradingSystemTests\TestAuditPayloadBuilder.mq5" },
    @{ Name = "TestProductionSafetyRules"; Path = Join-Path $mql5 "Scripts\EaTradingSystemTests\TestProductionSafetyRules.mq5" },
    @{ Name = "TestEntryTimingAnalyzer"; Path = Join-Path $mql5 "Scripts\EaTradingSystemTests\TestEntryTimingAnalyzer.mq5" },
    @{ Name = "TestBreakoutTimingAnalyzer"; Path = Join-Path $mql5 "Scripts\EaTradingSystemTests\TestBreakoutTimingAnalyzer.mq5" }
)

foreach ($target in $targets) {
    if (-not (Test-Path -LiteralPath $target.Path)) { throw "Source not found: $($target.Path)" }
    $log = Join-Path $logDir ($target.Name + ".log")
    $arguments = @("/compile:$($target.Path)", "/log:$log")
    $process = Start-Process -FilePath $editor -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
    $result = Get-Content -LiteralPath $log | Select-String -Pattern "^Result:" | Select-Object -Last 1
    if ($null -eq $result -or $result.Line -notmatch "Result: 0 errors, 0 warnings") {
        Get-Content -LiteralPath $log | Select-Object -Last 30
        throw "MQL5 compilation failed or produced warnings: $($target.Name)"
    }
    Write-Host "PASS compile $($target.Name): $($result.Line)"
}
