# tools/lib/ReleaseEvidence.psm1（本番証跡schema 2.0、製品ビルド用）の回帰テスト。MT5・Pythonは使わない。
#
# 正常な証跡が通ること、製品commit・ex5・検証レイヤー・合否基準・試験運用のex5・確認項目・パス・approved_atの
# いずれかが不正な場合に、期待するメッセージで拒否されることを確認する。approved_atのUTC判定は、
# PowerShell 7のConvertFrom-JsonがISO 8601文字列をDateTimeへ自動変換して正当なUTC値まで拒否していた
# 不具合（2026-09-23修正）の再発防止を兼ねる。

$ErrorActionPreference = "Stop"
Import-Module (Join-Path $PSScriptRoot "lib\ReleaseEvidence.psm1") -Force

$commit = "4ebbd4b7663f543d7f54caf78bdd82803596c532"
$ex5 = "A" * 64
$expert = "EaTradingSystemProduct\ProductEA"

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERTION_FAILED: $Message" }
}

function Write-Json([string]$Path, $Value) {
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
}

function New-ManifestObject([string]$Layer, [string]$CriteriaSha256) {
    return [ordered]@{
        schema_version      = "1.1"
        acceptance_criteria = [ordered]@{ path = "criteria/product-criteria.json"; sha256 = $CriteriaSha256 }
        provenance          = [ordered]@{ product = [ordered]@{ commit = $commit; dirty = $false } }
        cases               = @(
            [ordered]@{ case_name = "USDJPY-$Layer"; status = "Succeeded"; expert = $expert; validation_layer = $Layer
                        ea_version = "1.13"; expert_ex5_sha256 = $ex5; expert_ex5_older_than_source = $false }
        )
    }
}

function New-EvidenceObject {
    return [ordered]@{
        schema_version = "2.0"
        environment    = "production"
        product        = [ordered]@{ repository = "ryknk/EA-Product"; commit = $commit; expert = $expert; ea_version = "1.13"; ex5_sha256 = $ex5.ToLowerInvariant() }
        validation_manifests = @("manifest-wf.json", "manifest-fh.json")
        oos_report = "oos.json"; walk_forward_report = "walk-forward.json"; final_holdout_report = "final-holdout.json"
        demo_report = "demo.json"; small_real_report = "small-real.json"; benchmark_comparison_report = "benchmark-comparison.json"
        demo_ex5_sha256 = $ex5; small_real_ex5_sha256 = $ex5
        push_notification_verified = $true; kill_switch_drill_verified = $true; rollback_drill_verified = $true
        risk_limits_reviewed = $true; benchmark_criteria_met = $true
        approver = "release-owner"; approved_at = "2026-10-12T00:00:00Z"
    }
}

# 証跡・manifestを書き出して検証し、例外メッセージ（成功時は空文字）を返す。
function Invoke-Evidence([scriptblock]$Mutate = {}) {
    $evidence = New-EvidenceObject
    $manifests = [ordered]@{
        "manifest-wf.json" = New-ManifestObject "walk_forward" $script:criteriaSha256
        "manifest-fh.json" = New-ManifestObject "final_holdout" $script:criteriaSha256
    }
    & $Mutate $evidence $manifests
    foreach ($name in $manifests.Keys) { Write-Json (Join-Path $script:evidenceDir $name) $manifests[$name] }
    $evidencePath = Join-Path $script:evidenceDir "evidence.json"
    Write-Json $evidencePath $evidence
    try {
        Test-ProductionReleaseEvidence -Path $evidencePath -PlatformRoot $script:platformRoot -ExpectedProductCommit $commit
        return ""
    } catch {
        return $_.Exception.Message
    }
}

function Assert-Rejected([string]$Name, [string]$ExpectedPattern, [scriptblock]$Mutate) {
    $message = Invoke-Evidence $Mutate
    Assert-True ($message -ne "") "$Name は拒否されること"
    Assert-True ($message -match $ExpectedPattern) "$Name は期待するメッセージで拒否されること (期待: $ExpectedPattern, 実際: $message)"
    Write-Host "PASS reject $Name"
}

Write-Host "RELEASE_GATE_EVIDENCE_TEST_START"
$workDir = Join-Path ([IO.Path]::GetTempPath()) ("release-evidence-test-" + [guid]::NewGuid().ToString("N"))
$script:evidenceDir = Join-Path $workDir "release-evidence"
$script:platformRoot = Join-Path $workDir "platform"
New-Item -ItemType Directory -Path $script:evidenceDir, (Join-Path $script:platformRoot "criteria") -Force | Out-Null
try {
    $criteriaPath = Join-Path $script:platformRoot "criteria\product-criteria.json"
    [IO.File]::WriteAllText($criteriaPath, '{"min_trades": 100}', [Text.UTF8Encoding]::new($false))
    $script:criteriaSha256 = (Get-FileHash -LiteralPath $criteriaPath -Algorithm SHA256).Hash
    foreach ($report in @("oos.json", "walk-forward.json", "final-holdout.json", "demo.json", "small-real.json", "benchmark-comparison.json")) {
        [IO.File]::WriteAllText((Join-Path $script:evidenceDir $report), "{}", [Text.UTF8Encoding]::new($false))
    }

    # --- 正常系（ex5の大文字・小文字の違いは同一とみなす） ---
    $message = Invoke-Evidence
    Assert-True ($message -eq "") "正常な証跡は通過すること (エラー: $message)"
    Write-Host "PASS accept valid product evidence"

    # --- schema・製品の識別 ---
    Assert-Rejected "schema 1.0" "schema 2.0が必要" { param($e, $m) $e.schema_version = "1.0" }
    Assert-Rejected "other repository" "repositoryが不正" { param($e, $m) $e.product.repository = "ryknk/EA-Trading-System" }
    Assert-Rejected "commit differs from pinned submodule" "製品submoduleのcommitと一致しません" { param($e, $m) $e.product.commit = "0" * 40 }
    Assert-Rejected "research build expert" "製品ビルド" { param($e, $m) $e.product.expert = "EaTradingSystem\CoreEA" }
    Assert-Rejected "invalid ex5 hash" "ex5_sha256が不正" { param($e, $m) $e.product.ex5_sha256 = "not-a-hash" }

    # --- 試験運用は同じex5で行う ---
    Assert-Rejected "demo ex5 mismatch" "試験運用のex5.*demo_ex5_sha256" { param($e, $m) $e.demo_ex5_sha256 = "B" * 64 }
    Assert-Rejected "small real ex5 mismatch" "試験運用のex5.*small_real_ex5_sha256" { param($e, $m) $e.small_real_ex5_sha256 = "B" * 64 }

    # --- 確認項目・レポート ---
    foreach ($field in @("push_notification_verified", "kill_switch_drill_verified", "rollback_drill_verified", "risk_limits_reviewed", "benchmark_criteria_met")) {
        $mutate = [scriptblock]::Create("param(`$e, `$m) `$e.$field = `$false")
        Assert-Rejected "$field false" "本番ゲート未達: $field" $mutate
    }
    Assert-Rejected "missing final holdout report" "証跡ファイルが見つかりません: final_holdout_report" { param($e, $m) $e.final_holdout_report = "none.json" }
    Assert-Rejected "parent path traversal" "相対path" { param($e, $m) $e.demo_report = "..\demo.json" }
    Assert-Rejected "absolute path" "相対path" { param($e, $m) $e.demo_report = "C:\demo.json" }

    # --- 検証結果（manifest.json） ---
    Assert-Rejected "no validation manifests" "validation_manifests" { param($e, $m) $e.validation_manifests = @() }
    Assert-Rejected "manifest schema 1.0" "schema_versionは1.1" { param($e, $m) $m["manifest-wf.json"].schema_version = "1.0" }
    Assert-Rejected "manifest commit mismatch" "製品commitがリリース対象と一致しません" { param($e, $m) $m["manifest-wf.json"].provenance.product.commit = "0" * 40 }
    Assert-Rejected "manifest dirty source" "未コミット変更" { param($e, $m) $m["manifest-wf.json"].provenance.product.dirty = $true }
    Assert-Rejected "manifest without criteria" "合否基準" { param($e, $m) $m["manifest-fh.json"].acceptance_criteria = $null }
    Assert-Rejected "criteria changed after run" "検証実行後に変更" { param($e, $m) $m["manifest-fh.json"].acceptance_criteria.sha256 = "C" * 64 }
    Assert-Rejected "failed case" "失敗したケース" { param($e, $m) $m["manifest-wf.json"].cases[0].status = "Failed" }
    Assert-Rejected "research build case" "製品ビルド.*以外" { param($e, $m) $m["manifest-wf.json"].cases[0].expert = "EaTradingSystem\CoreEA" }
    Assert-Rejected "case ex5 mismatch" "実行したex5" { param($e, $m) $m["manifest-wf.json"].cases[0].expert_ex5_sha256 = "B" * 64 }
    Assert-Rejected "case ex5 older than source" "ex5が製品ソースより古い" { param($e, $m) $m["manifest-wf.json"].cases[0].expert_ex5_older_than_source = $true }
    Assert-Rejected "case ea version mismatch" "EAバージョン" { param($e, $m) $m["manifest-wf.json"].cases[0].ea_version = "1.12" }
    Assert-Rejected "missing final holdout layer" "final_holdout" { param($e, $m) $m["manifest-fh.json"].cases[0].validation_layer = "out_of_sample" }

    # --- 承認 ---
    Assert-Rejected "empty approver" "approver" { param($e, $m) $e.approver = "" }
    foreach ($value in @("2026-10-12T00:00:00+00:00", "2026-10-12T00:00:00.123Z")) {
        $mutate = [scriptblock]::Create("param(`$e, `$m) `$e.approved_at = '$value'")
        $message = Invoke-Evidence $mutate
        Assert-True ($message -eq "") "UTC値 $value は通過すること (エラー: $message)"
        Write-Host "PASS accept approved_at=$value"
    }
    $rejectApprovedAt = [ordered]@{
        "JST offset"      = { param($e, $m) $e.approved_at = "2026-10-12T09:00:00+09:00" }
        "no offset"       = { param($e, $m) $e.approved_at = "2026-10-12T00:00:00" }
        "minus zero"      = { param($e, $m) $e.approved_at = "2026-10-12T00:00:00-00:00" }
        "space separator" = { param($e, $m) $e.approved_at = "2026-10-12 00:00:00Z" }
        "invalid month"   = { param($e, $m) $e.approved_at = "2026-13-01T00:00:00Z" }
        "empty string"    = { param($e, $m) $e.approved_at = "" }
        "number"          = { param($e, $m) $e.approved_at = 20261012 }
        "null"            = { param($e, $m) $e.approved_at = $null }
        "missing"         = { param($e, $m) $e.Remove("approved_at") }
    }
    foreach ($name in $rejectApprovedAt.Keys) {
        Assert-Rejected "approved_at ($name)" "approved_atはUTCで指定してください" $rejectApprovedAt[$name]
    }
}
finally {
    Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host "RELEASE_GATE_EVIDENCE_TEST_PASS"
