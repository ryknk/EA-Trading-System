param([string]$Python = ".\.venv\Scripts\python.exe")

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    & .\tools\secret-scan.ps1
    & .\tools\compile-mql5.ps1
    & .\tools\run-mql5-tests.ps1
    & .\tools\test-phase12.ps1 -Python $Python
    Write-Host "PHASE13_AUTOMATED_VALIDATION_PASS"
}
finally { Pop-Location }
