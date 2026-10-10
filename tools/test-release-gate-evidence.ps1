# tools/release-gate.ps1 -Mode Production の本番証跡検証（approved_at のUTC判定）の回帰テスト。
#
# PowerShell 7のConvertFrom-JsonがISO 8601文字列をDateTimeへ自動変換し、"Z"付きの正当なUTC値まで
# 「approved_atはUTCで指定してください。」で拒否していた不具合（2026-09-23修正）の再発を防ぐ。
# 証跡検証の通過後に続く総合テストを走らせないよう、存在しない-Pythonを渡して直後で停止させる。

$ErrorActionPreference = "Stop"
$gate = Join-Path $PSScriptRoot "release-gate.ps1"
$missingPython = Join-Path $env:TEMP "release-gate-evidence-test-missing-python.exe"
$workDir = Join-Path $env:TEMP ("release-gate-evidence-test-" + [guid]::NewGuid().ToString("N"))
$utcError = "approved_atはUTCで指定してください。"
$evidencePass = "PASS production evidence"

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERTION_FAILED: $Message" }
}

function Invoke-GateWithApprovedAt {
    param([string]$ApprovedAtJson)
    $evidenceJson = @"
{
  "schema_version": "1.0",
  "environment": "production",
  "aws_account_id": "123456789012",
  "aws_region": "ap-northeast-1",
  "ml_model_version": "test-model-1",
  "ml_model_sha256": "$("0" * 64)",
  "llm_provider": "test-provider",
  "llm_model": "test-model",
  "prompt_version": "test-prompt-1",
  "oos_report": "oos.json",
  "walk_forward_report": "walk-forward.json",
  "demo_report": "demo.json",
  "small_real_report": "small-real.json",
  "benchmark_comparison_report": "benchmark-comparison.json",
  "vps_secret_file_verified": true,
  "sns_notification_verified": true,
  "budgets_verified": true,
  "rollback_drill_verified": true,
  "benchmark_criteria_met": true$ApprovedAtJson
}
"@
    $evidencePath = Join-Path $workDir "evidence.json"
    [IO.File]::WriteAllText($evidencePath, $evidenceJson, [Text.UTF8Encoding]::new($false))
    $lines = [System.Collections.Generic.List[string]]::new()
    $errorMessage = ""
    try {
        & $gate -Mode Production -EvidenceFile $evidencePath -Python $missingPython 6>&1 | ForEach-Object { $lines.Add([string]$_) }
    } catch {
        $errorMessage = $_.Exception.Message
    }
    return [pscustomobject]@{ EvidencePassed = ($lines -contains $evidencePass); ErrorMessage = $errorMessage }
}

Write-Host "RELEASE_GATE_EVIDENCE_TEST_START"
New-Item -ItemType Directory -Path $workDir | Out-Null
try {
    foreach ($report in @("oos.json", "walk-forward.json", "demo.json", "small-real.json", "benchmark-comparison.json")) {
        Set-Content -LiteralPath (Join-Path $workDir $report) -Value "{}" -Encoding UTF8
    }

    foreach ($value in @("2026-09-23T00:00:00Z", "2026-09-23T00:00:00+00:00", "2026-09-23T00:00:00.123Z")) {
        $result = Invoke-GateWithApprovedAt ",`n  `"approved_at`": `"$value`""
        Assert-True $result.EvidencePassed "UTC値 $value は証跡検証を通過すること (エラー: $($result.ErrorMessage))"
        Assert-True ($result.ErrorMessage -notmatch [regex]::Escape($utcError)) "UTC値 $value がUTCエラーにならないこと"
        Write-Host "PASS accept approved_at=$value"
    }

    $rejectCases = [ordered]@{
        "JST offset"     = ",`n  `"approved_at`": `"2026-09-23T09:00:00+09:00`""
        "no offset"      = ",`n  `"approved_at`": `"2026-09-23T00:00:00`""
        "minus zero"     = ",`n  `"approved_at`": `"2026-09-23T00:00:00-00:00`""
        "space separator"= ",`n  `"approved_at`": `"2026-09-23 00:00:00Z`""
        "invalid month"  = ",`n  `"approved_at`": `"2026-13-01T00:00:00Z`""
        "empty string"   = ",`n  `"approved_at`": `"`""
        "number"         = ",`n  `"approved_at`": 20260923"
        "null"           = ",`n  `"approved_at`": null"
        "missing"        = ""
    }
    foreach ($name in $rejectCases.Keys) {
        $result = Invoke-GateWithApprovedAt $rejectCases[$name]
        Assert-True (-not $result.EvidencePassed) "非UTC値($name)は証跡検証を通過しないこと"
        Assert-True ($result.ErrorMessage -eq $utcError) "非UTC値($name)はUTCエラーで拒否されること (エラー: $($result.ErrorMessage))"
        Write-Host "PASS reject approved_at ($name)"
    }
}
finally {
    Remove-Item -LiteralPath $workDir -Recurse -Force
}
Write-Host "RELEASE_GATE_EVIDENCE_TEST_PASS"
