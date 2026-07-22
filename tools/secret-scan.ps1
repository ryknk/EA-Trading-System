param()

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$patterns = @(
    'AKIA[0-9A-Z]{16}',
    'ASIA[0-9A-Z]{16}',
    'aws_secret_access_key\s*[:=]',
    'sk-[A-Za-z0-9_-]{20,}',
    'xox[baprs]-',
    'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY',
    'broker.{0,20}(password|passwd)\s*[:=]'
)

Push-Location $root
try {
    $matches = @()
    foreach ($pattern in $patterns) {
        $output = & rg -n -i --hidden --glob '!.venv/**' --glob '!.git/**' --glob '!build/**' `
            --glob '!*.ex5' --glob '!tools/secret-scan.ps1' $pattern . 2>$null
        if ($LASTEXITCODE -eq 0) { $matches += $output }
        elseif ($LASTEXITCODE -ne 1) { throw "rg failed while scanning pattern" }
    }
    if ($matches.Count -gt 0) {
        $matches | Write-Error
        throw "秘密情報候補が見つかりました。内容を確認し、必要なら直ちにローテーションしてください。"
    }
    Write-Host "SECRET_SCAN_PASS current-working-tree"
}
finally { Pop-Location }
