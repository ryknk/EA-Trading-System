param([string]$Python = ".\.venv\Scripts\python.exe")

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    if (-not (Test-Path -LiteralPath $Python)) { throw "Python仮想環境が見つかりません: $Python" }
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        $bundledNode = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe"
        if (-not (Test-Path -LiteralPath $bundledNode)) { throw "CDKに必要なNode.jsが見つかりません。" }
        $env:PATH = (Split-Path -Parent $bundledNode) + [IO.Path]::PathSeparator + $env:PATH
    }
    $env:PYTHONPATH = ".;services/decision_api/src;services/decision_api/tests;infra"
    & $Python -m pytest services/decision_api/tests python/tests infra/tests -q
    if ($LASTEXITCODE -ne 0) { throw "Phase 10テストが失敗しました。" }
    Push-Location infra
    try {
        & (Join-Path $root $Python) app.py
        if ($LASTEXITCODE -ne 0) { throw "CDK synthが失敗しました。" }
    }
    finally { Pop-Location }
    Write-Host "PHASE10_TEST_PASS"
}
finally { Pop-Location }
