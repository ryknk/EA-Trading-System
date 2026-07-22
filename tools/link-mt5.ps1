param(
    [string]$TerminalData = "$env:APPDATA\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075"
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$repoMt5 = Join-Path $repoRoot "mt5"
$mql5 = Join-Path $TerminalData "MQL5"

if (-not (Test-Path -LiteralPath $mql5)) {
    throw "MQL5 data directory not found: $mql5"
}

$links = @(
    @{ Path = Join-Path $mql5 "Include\EaTradingSystem"; Target = Join-Path $repoMt5 "Include" },
    @{ Path = Join-Path $mql5 "Experts\EaTradingSystem"; Target = Join-Path $repoMt5 "Experts" },
    @{ Path = Join-Path $mql5 "Scripts\EaTradingSystemTests"; Target = Join-Path $repoMt5 "Tests" }
)

foreach ($link in $links) {
    $expected = (Resolve-Path -LiteralPath $link.Target).Path
    if (Test-Path -LiteralPath $link.Path) {
        $item = Get-Item -LiteralPath $link.Path -Force
        $actual = ($item.Target | Select-Object -First 1)
        if ($item.LinkType -ne "Junction" -or $actual -ne $expected) {
            throw "Refusing to replace existing path: $($link.Path)"
        }
        Write-Host "OK existing junction: $($link.Path)"
        continue
    }
    New-Item -ItemType Junction -Path $link.Path -Target $expected | Out-Null
    Write-Host "Created junction: $($link.Path) -> $expected"
}
