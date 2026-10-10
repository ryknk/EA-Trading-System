# 既定ではOANDA証券MT5端末を対象とする（2026-08-16以降の本番運用Broker、DECISIONS.md DEC-023）。
# XMTrading-MT5（Terminal Data: D0E8209F77C8CF37AD8BF550E51FF075）は参考用として残しており、
# 対象にする場合は-TerminalDataを明示指定すること。
#
# 製品EAの正本はsubmodule product/（ryknk/EA-Product）にあり、開発基盤のmt5/は研究ビルド・研究用Include・
# 研究テスト・診断ツールだけを持つ（DECISIONS.md DEC-047）。MT5上の名前は次のとおり。
#   Include\EaTradingSystem             -> product\mt5\Include（製品EA本体）
#   Include\EaTradingSystemResearch     -> mt5\Include（研究計測・外部連携・診断）
#   Experts\EaTradingSystem             -> mt5\Experts（研究ビルドCoreEA、診断EA）
#   Experts\EaTradingSystemProduct      -> product\mt5\Experts（製品ビルドProductEA）
#   Scripts\EaTradingSystemTests        -> mt5\Tests（研究テスト）
#   Scripts\EaTradingSystemProductTests -> product\mt5\Tests（製品テスト）
#   Scripts\EaTradingSystemTools        -> mt5\Tools
# 既存パスが別の場所を指す場合は既定で停止する。-Relinkを指定すると、既存パスがジャンクションの場合に限り
# リンクだけを削除して張り替える（リンク先の内容は削除しない。実体のフォルダは置き換えない）。
param(
    [string]$TerminalData = "$env:APPDATA\MetaQuotes\Terminal\EE0304F13905552AE0B5EAEFB04866EB",
    [switch]$Relink
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$repoMt5 = Join-Path $repoRoot "mt5"
$productMt5 = Join-Path $repoRoot "product\mt5"
$mql5 = Join-Path $TerminalData "MQL5"

if (-not (Test-Path -LiteralPath $mql5)) {
    throw "MQL5 data directory not found: $mql5"
}
if (-not (Test-Path -LiteralPath (Join-Path $productMt5 "Include"))) {
    throw "製品submoduleが見つかりません: $productMt5（git submodule update --init を実行してください）"
}

$links = @(
    @{ Path = Join-Path $mql5 "Include\EaTradingSystem"; Target = Join-Path $productMt5 "Include" },
    @{ Path = Join-Path $mql5 "Include\EaTradingSystemResearch"; Target = Join-Path $repoMt5 "Include" },
    @{ Path = Join-Path $mql5 "Experts\EaTradingSystem"; Target = Join-Path $repoMt5 "Experts" },
    @{ Path = Join-Path $mql5 "Experts\EaTradingSystemProduct"; Target = Join-Path $productMt5 "Experts" },
    @{ Path = Join-Path $mql5 "Scripts\EaTradingSystemTests"; Target = Join-Path $repoMt5 "Tests" },
    @{ Path = Join-Path $mql5 "Scripts\EaTradingSystemProductTests"; Target = Join-Path $productMt5 "Tests" },
    @{ Path = Join-Path $mql5 "Scripts\EaTradingSystemTools"; Target = Join-Path $repoMt5 "Tools" }
)

foreach ($link in $links) {
    $expected = (Resolve-Path -LiteralPath $link.Target).Path
    if (Test-Path -LiteralPath $link.Path) {
        $item = Get-Item -LiteralPath $link.Path -Force
        $actual = ($item.Target | Select-Object -First 1)
        if ($item.LinkType -eq "Junction" -and $actual -eq $expected) {
            Write-Host "OK existing junction: $($link.Path)"
            continue
        }
        if (-not $Relink -or $item.LinkType -ne "Junction") {
            throw "Refusing to replace existing path: $($link.Path) (current target: $actual)"
        }
        # ジャンクションに対するDirectory.Delete（非再帰）はリンクだけを削除し、リンク先の内容は残る。
        [System.IO.Directory]::Delete($link.Path, $false)
        Write-Host "Removed junction: $($link.Path) (previous target: $actual)"
    }
    New-Item -ItemType Junction -Path $link.Path -Target $expected | Out-Null
    Write-Host "Created junction: $($link.Path) -> $expected"
}
