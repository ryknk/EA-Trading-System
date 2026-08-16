# 既定ではOANDA証券MT5端末を対象とする（2026-08-16以降の本番運用Broker、DECISIONS.md DEC-023）。
# XMTrading-MT5（C:\Program Files\MetaTrader 5、Terminal Data: D0E8209F77C8CF37AD8BF550E51FF075）は
# 参考用として残しており、対象にする場合は-InstallPath/-TerminalDataを明示指定すること。
param(
    [string]$InstallPath = "C:\Program Files\OANDA MetaTrader 5",
    [string]$TerminalData = "$env:APPDATA\MetaQuotes\Terminal\EE0304F13905552AE0B5EAEFB04866EB",
    [int]$TimeoutSeconds = 900,
    [string]$FromDate = "2016.09.01",
    [string]$ToDate = "2020.12.31"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$terminal = Join-Path $InstallPath "terminal64.exe"
$template = Join-Path $root "mt5\test-config\StrategyTester-USDJPY-H1.ini"
$runId = Get-Date -Format "yyyyMMdd-HHmmss"
$resultDir = Join-Path $root "results\backtests\$runId-USDJPY-H1"
$config = Join-Path $resultDir "tester.ini"
$reportName = "ets-$runId-USDJPY-H1"

if (-not (Test-Path -LiteralPath $terminal)) { throw "Terminal not found: $terminal" }
if (Get-Process terminal64 -ErrorAction SilentlyContinue) { throw "自動実行前に起動中のMetaTrader 5を終了してください。" }
New-Item -ItemType Directory -Path $resultDir -Force | Out-Null
$content = Get-Content -LiteralPath $template
$content = $content -replace '^ReplaceReport=1$', ("Report=" + $reportName + "`r`nReplaceReport=1")
$content = $content -replace '^FromDate=.*$', ("FromDate=" + $FromDate)
$content = $content -replace '^ToDate=.*$', ("ToDate=" + $ToDate)
Set-Content -LiteralPath $config -Value $content -Encoding Unicode

$process = Start-Process -FilePath $terminal -ArgumentList @("/config:$config") -PassThru -WindowStyle Hidden
if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
    Stop-Process -Id $process.Id -Force
    throw "Strategy Tester timeout: $TimeoutSeconds seconds"
}
$searchRoots = @($root, $TerminalData, $InstallPath, (Join-Path $env:APPDATA "MetaQuotes")) | Select-Object -Unique
$reports = foreach ($searchRoot in $searchRoots) {
    if (Test-Path -LiteralPath $searchRoot) {
        Get-ChildItem -LiteralPath $searchRoot -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.BaseName -eq $reportName }
    }
}
if (-not $reports) { throw "Strategy Testerは終了しましたがreportが生成されませんでした。Tester logを確認してください。" }
foreach ($generated in $reports) {
    Copy-Item -LiteralPath $generated.FullName -Destination (Join-Path $resultDir $generated.Name) -Force
}
Write-Host "STRATEGY_TESTER_COMPLETED exit=$($process.ExitCode) result=$resultDir"
