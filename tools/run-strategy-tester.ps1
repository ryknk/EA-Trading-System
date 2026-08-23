# 既定ではOANDA証券MT5端末を対象とする（2026-08-16以降の本番運用Broker、DECISIONS.md DEC-023）。
# XMTrading-MT5（C:\Program Files\MetaTrader 5、Terminal Data: D0E8209F77C8CF37AD8BF550E51FF075）は
# 参考用として残しており、対象にする場合は-InstallPath/-TerminalDataを明示指定すること。
param(
    [string]$InstallPath = "C:\Program Files\OANDA MetaTrader 5",
    [string]$TerminalData = "$env:APPDATA\MetaQuotes\Terminal\EE0304F13905552AE0B5EAEFB04866EB",
    [int]$TimeoutSeconds = 900,
    [string]$FromDate = "2017.09.01",
    [string]$ToDate = "2020.12.31",
    [string]$Template = "mt5\test-config\StrategyTester-USDJPY-H1.ini"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$terminal = Join-Path $InstallPath "terminal64.exe"
$template = if ([System.IO.Path]::IsPathRooted($Template)) { $Template } else { Join-Path $root $Template }
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

$searchRoots = @($root, $TerminalData, $InstallPath, (Join-Path $env:APPDATA "MetaQuotes")) | Select-Object -Unique

# 監査JSONL（audit-*.jsonl）はEA側がFILE_WRITE|FILE_SHARE_READでSEEK_END追記するため、
# Tester Agentフォルダ（単一Agentが実行間で使い回される）に残っていると前回以前の実行分が
# 累積したまま残る。今回の実行結果とは無関係な過去データが後段のコピー対象へ混入し、
# python.analysis.trade_breakdown等の分析が別実行のデータで汚染される（2026-08-22発見）。
# 実行前に既存の監査JSONLを削除し、今回の実行分のみが書き込まれる状態にする。
$staleAuditFiles = foreach ($searchRoot in $searchRoots) {
    if (Test-Path -LiteralPath $searchRoot) {
        Get-ChildItem -LiteralPath $searchRoot -Recurse -File -Filter "audit-*.jsonl" -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match '\\EaTradingSystem\\Audit\\' }
    }
}
if ($staleAuditFiles) {
    foreach ($stale in $staleAuditFiles) { Remove-Item -LiteralPath $stale.FullName -Force }
    Write-Host "STRATEGY_TESTER_STALE_AUDIT_CLEARED count=$($staleAuditFiles.Count)"
}

$process = Start-Process -FilePath $terminal -ArgumentList @("/config:$config") -PassThru -WindowStyle Hidden
if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
    Stop-Process -Id $process.Id -Force
    throw "Strategy Tester timeout: $TimeoutSeconds seconds"
}
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

# InpAuditFileEnabled=trueの場合、EaTradingSystem\Audit配下に監査JSONLが出力される（Tester Agentのサンドボックス配下を含む）。
# 分析（python.analysis.trade_breakdown等）用に、生成されていればresult配下へ複製する。ベストエフォートであり、
# 見つからなくてもStrategy Tester自体の成功判定には影響させない。
$auditFiles = foreach ($searchRoot in $searchRoots) {
    if (Test-Path -LiteralPath $searchRoot) {
        Get-ChildItem -LiteralPath $searchRoot -Recurse -File -Filter "audit-*.jsonl" -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match '\\EaTradingSystem\\Audit\\' }
    }
}
if ($auditFiles) {
    $auditDir = Join-Path $resultDir "audit"
    New-Item -ItemType Directory -Path $auditDir -Force | Out-Null
    foreach ($generated in $auditFiles) {
        Copy-Item -LiteralPath $generated.FullName -Destination (Join-Path $auditDir $generated.Name) -Force
    }
    Write-Host "STRATEGY_TESTER_AUDIT_COPIED count=$($auditFiles.Count) dir=$auditDir"
} else {
    Write-Host "STRATEGY_TESTER_AUDIT_NOT_FOUND note=InpAuditFileEnabledの設定を確認してください"
}

Write-Host "STRATEGY_TESTER_COMPLETED exit=$($process.ExitCode) result=$resultDir"
