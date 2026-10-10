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

# 製品EA・製品テストは製品リポジトリ（submodule product/）のスクリプトでコンパイルする。対象の一覧は製品側だけで
# 管理し、開発基盤では二重管理しない（DECISIONS.md DEC-047）。ログは従来どおり build/metaeditor へ出力する。
& (Join-Path $repoRoot "product\tools\compile-mql5.ps1") -InstallPath $InstallPath -TerminalData $TerminalData -LogDirectory $logDir

# 研究ビルドCoreEAと研究テスト（mt5/Tests配下を列挙）。
$targets = @(@{ Name = "CoreEA"; Path = Join-Path $mql5 "Experts\EaTradingSystem\CoreEA.mq5" })
foreach ($source in @(Get-ChildItem -LiteralPath (Join-Path $repoRoot "mt5\Tests") -Filter "*.mq5" | Sort-Object Name)) {
    $targets += @{ Name = $source.BaseName; Path = Join-Path $mql5 "Scripts\EaTradingSystemTests\$($source.Name)" }
}

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
