param(
    [ValidateSet("Development", "Production")]
    [string]$Mode = "Development",
    [string]$EvidenceFile = "",
    [string]$Python = ".\.venv\Scripts\python.exe",
    [string]$InstallPath = "C:\Program Files\MetaTrader 5",
    [string]$TerminalData = "$env:APPDATA\MetaQuotes\Terminal\D0E8209F77C8CF37AD8BF550E51FF075"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Assert-ProductionEvidence([string]$Path) {
    Assert-True (-not [string]::IsNullOrWhiteSpace($Path)) "Productionでは-EvidenceFileが必須です。"
    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction Stop
    $evidence = Get-Content -LiteralPath $resolved -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-True ($evidence.schema_version -eq "1.0" -and $evidence.environment -eq "production") "本番証跡のschema/environmentが不正です。"
    Assert-True ($evidence.aws_account_id -match '^[0-9]{12}$') "AWS account IDが不正です。"
    Assert-True ($evidence.aws_region -match '^[a-z]{2}-[a-z]+-[0-9]$') "AWS regionが不正です。"
    Assert-True ($evidence.ml_model_sha256 -match '^[0-9a-f]{64}$') "ML checksumが不正です。"
    foreach ($field in @("ml_model_version", "llm_provider", "llm_model", "prompt_version")) {
        Assert-True ($evidence.$field -match '^[A-Za-z0-9._-]+$') "本番証跡の$fieldが不正です。"
    }
    foreach ($field in @("vps_secret_file_verified", "sns_notification_verified", "budgets_verified", "rollback_drill_verified")) {
        Assert-True ($evidence.$field -eq $true) "本番ゲート未達: $field"
    }
    $evidenceRoot = Split-Path -Parent $resolved
    foreach ($field in @("oos_report", "walk_forward_report", "demo_report", "small_real_report")) {
        $relative = [string]$evidence.$field
        Assert-True (-not [IO.Path]::IsPathRooted($relative) -and $relative -notmatch '(^|[\\/])\.\.([\\/]|$)') "証跡pathは同じdirectory配下の相対pathにしてください: $field"
        $report = Join-Path $evidenceRoot $relative
        Assert-True (Test-Path -LiteralPath $report -PathType Leaf) "証跡ファイルが見つかりません: $field"
    }
    $approved = [DateTimeOffset]::Parse($evidence.approved_at)
    Assert-True ($approved.Offset -eq [TimeSpan]::Zero) "approved_atはUTCで指定してください。"
}

Push-Location $root
try {
    Write-Host "RELEASE_GATE_START mode=$Mode"
    $requiredDocs = @(
        "architecture.md", "strategy.md", "risk-management.md", "ml-design.md", "llm-design.md",
        "aws-infrastructure.md", "security.md", "backtesting.md", "operations.md",
        "configuration.md", "release-gate.md", "phase-12-implementation.md"
    )
    foreach ($name in $requiredDocs) {
        $path = Join-Path $root ("docs\" + $name)
        Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "必須文書がありません: $name"
        Assert-True ((Get-Item -LiteralPath $path).Length -gt 200) "必須文書が空または短すぎます: $name"
    }
    Write-Host "PASS required Japanese documents"

    $coreEa = Get-Content -LiteralPath (Join-Path $root "mt5\Experts\CoreEA.mq5") -Raw
    foreach ($setting in @("InpEnableTradeMutations", "InpDecisionApiEnabled", "InpTelemetryEnabled")) {
        Assert-True ($coreEa -match "input bool\s+$setting=false;") "危険な設定の初期値がfalseではありません: $setting"
    }
    Assert-True ($coreEa -match 'input bool\s+InpAuditFileEnabled=true;') "監査ログの初期値がtrueではありません。"
    Write-Host "PASS fail-safe MQL5 defaults"

    $sourceRoots = @("mt5", "services", "python", "infra", "contracts", "docs")
    $forbidden = Get-ChildItem -LiteralPath $sourceRoots -Recurse -File -ErrorAction Stop |
        Where-Object { $_.Name -in @("decision-api-secret.txt", ".env") }
    Assert-True ($null -eq $forbidden) "秘密情報ファイルがソースツリーに存在します。"
    $accessKeys = & rg -n -g '!infra/cdk.out/**' 'AKIA[0-9A-Z]{16}' README.md docs contracts mt5 services python infra tools
    Assert-True ($LASTEXITCODE -eq 1) "AWS access keyらしき文字列が見つかりました: $accessKeys"
    Write-Host "PASS basic secret scan"

    Get-ChildItem -LiteralPath "contracts" -Filter "*.json" | ForEach-Object {
        Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null
    }
    Write-Host "PASS JSON contracts"

    if ($Mode -eq "Production") { Assert-ProductionEvidence $EvidenceFile }
    if ($Mode -eq "Production") { Write-Host "PASS production evidence" }

    & ".\tools\test-phase12.ps1" -Python $Python
    if ($LASTEXITCODE -ne 0) { throw "Phase 12総合テストが失敗しました。" }
    & ".\tools\compile-mql5.ps1" -InstallPath $InstallPath -TerminalData $TerminalData
    if ($LASTEXITCODE -ne 0) { throw "MQL5コンパイルが失敗しました。" }
    & ".\tools\run-mql5-tests.ps1" -InstallPath $InstallPath -TerminalData $TerminalData
    if ($LASTEXITCODE -ne 0) { throw "MQL5実行テストが失敗しました。" }

    Write-Host "RELEASE_GATE_PASS mode=$Mode"
}
finally {
    Pop-Location
}
