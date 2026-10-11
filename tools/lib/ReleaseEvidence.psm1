# 本番証跡（contracts/production-release-evidence.schema.json、schema 2.0＝製品ビルド用）の検証。
# release-gate.ps1 -Mode Production から使う。MT5・Pythonを使わずに単体テストできるよう分離している
# （tools/test-release-gate-evidence.ps1）。設計判断はDECISIONS.md DEC-049。
#
# 製品ビルド ProductEA（ryknk/EA-Product）は外部連携を持たないため（DEC-046）、ML・LLM・AWSの項目は持たない。
# 代わりに、検証結果（Strategy Testerのmanifest.json）・試験運用・リリース対象が同じ製品commitとex5であることを照合する。

$ErrorActionPreference = "Stop"

$script:ProductRepository = "ryknk/EA-Product"
$script:ProductExpert = "EaTradingSystemProduct\ProductEA"
$script:RequiredValidationLayers = @("walk_forward", "final_holdout")
$script:RequiredReports = @("oos_report", "walk_forward_report", "final_holdout_report", "demo_report", "small_real_report", "benchmark_comparison_report")
$script:RequiredConfirmations = @("push_notification_verified", "kill_switch_drill_verified", "rollback_drill_verified", "risk_limits_reviewed", "benchmark_criteria_met")

function Assert-Evidence([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

# PowerShell 7はISO 8601文字列をDateTimeへ自動変換しオフセット情報を失うため、
# -DateKind String（7.5以降）で元の文字列のまま読み込む。5.1は元々文字列のまま返す。
function Read-EvidenceJson([string]$Path) {
    $convertOptions = @{}
    if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey("DateKind")) { $convertOptions.DateKind = "String" }
    return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json @convertOptions)
}

# 証跡ファイルと同じディレクトリ配下の相対パスだけを受け付け、実在を確認して絶対パスを返す。
function Resolve-EvidenceFile([string]$EvidenceRoot, [string]$Relative, [string]$Field) {
    Assert-Evidence (-not [string]::IsNullOrWhiteSpace($Relative)) "証跡ファイルが指定されていません: $Field"
    Assert-Evidence (-not [IO.Path]::IsPathRooted($Relative) -and $Relative -notmatch '(^|[\\/])\.\.([\\/]|$)') "証跡pathは同じdirectory配下の相対pathにしてください: $Field"
    $path = Join-Path $EvidenceRoot $Relative
    Assert-Evidence (Test-Path -LiteralPath $path -PathType Leaf) "証跡ファイルが見つかりません: $Field"
    return $path
}

function Test-Sha256Text([object]$Value) {
    return ($Value -is [string] -and $Value -match '^[0-9A-Fa-f]{64}$')
}

# Strategy Testerのmanifest.json（schema 1.1）が、リリース対象の製品commit・ex5で取得した成功結果であり、
# 事前に固定した合否基準（実行後に内容が変わっていないこと）に紐づくことを確認する。
# 戻り値はmanifestに含まれる検証レイヤー。
function Assert-ValidationManifest([string]$Path, [string]$Field, $Product, [string]$PlatformRoot) {
    $manifest = Read-EvidenceJson $Path
    Assert-Evidence ($manifest.schema_version -eq "1.1") "${Field}: manifest.jsonのschema_versionは1.1が必要です（検証対象の識別情報を持たない結果は使えません）。"
    $productProvenance = $manifest.provenance.product
    Assert-Evidence ($null -ne $productProvenance -and $productProvenance.commit -eq $Product.commit) "${Field}: 製品commitがリリース対象と一致しません。"
    Assert-Evidence ($productProvenance.dirty -eq $false) "${Field}: 製品ソースに未コミット変更がある状態の結果は使えません。"

    $criteria = $manifest.acceptance_criteria
    Assert-Evidence ($null -ne $criteria -and -not [string]::IsNullOrWhiteSpace([string]$criteria.path) -and (Test-Sha256Text $criteria.sha256)) "${Field}: 事前に固定した合否基準（CaseFileのacceptance_criteria）が記録されていません。"
    $criteriaPath = Join-Path $PlatformRoot ([string]$criteria.path)
    Assert-Evidence (Test-Path -LiteralPath $criteriaPath -PathType Leaf) "${Field}: 合否基準ファイルが見つかりません: $($criteria.path)"
    $currentCriteriaHash = (Get-FileHash -LiteralPath $criteriaPath -Algorithm SHA256).Hash
    Assert-Evidence ($currentCriteriaHash -eq ([string]$criteria.sha256).ToUpperInvariant()) "${Field}: 合否基準ファイルが検証実行後に変更されています: $($criteria.path)"

    $cases = @($manifest.cases)
    Assert-Evidence ($cases.Count -gt 0) "${Field}: manifest.jsonにケースがありません。"
    $layers = @()
    foreach ($case in $cases) {
        $name = [string]$case.case_name
        Assert-Evidence ($case.status -eq "Succeeded") "${Field}: 失敗したケースを含みます: $name"
        Assert-Evidence ($case.expert -eq $script:ProductExpert) "${Field}: 製品ビルド（$script:ProductExpert）以外の結果を含みます: $name"
        Assert-Evidence ((Test-Sha256Text $case.expert_ex5_sha256) -and ([string]$case.expert_ex5_sha256).ToUpperInvariant() -eq ([string]$Product.ex5_sha256).ToUpperInvariant()) "${Field}: 実行したex5がリリース対象と一致しません: $name"
        Assert-Evidence ($case.expert_ex5_older_than_source -eq $false) "${Field}: ex5が製品ソースより古い（未コンパイルの変更の可能性がある）結果を含みます: $name"
        Assert-Evidence ($case.ea_version -eq $Product.ea_version) "${Field}: EAバージョンがリリース対象と一致しません: $name"
        if (-not [string]::IsNullOrEmpty([string]$case.validation_layer)) { $layers += [string]$case.validation_layer }
    }
    return $layers
}

# 本番証跡を検証する。不備があれば例外（メッセージは日本語）を投げる。
# ExpectedProductCommit: 開発基盤が固定している製品submoduleのcommit（ゲートの静的検査・コンパイル・テストの対象）。
function Test-ProductionReleaseEvidence {
    param(
        [string]$Path,
        [Parameter(Mandatory)][string]$PlatformRoot,
        [Parameter(Mandatory)][string]$ExpectedProductCommit
    )
    Assert-Evidence (-not [string]::IsNullOrWhiteSpace($Path)) "Productionでは-EvidenceFileが必須です。"
    $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    $evidence = Read-EvidenceJson $resolved
    $evidenceRoot = Split-Path -Parent $resolved

    Assert-Evidence ($evidence.schema_version -eq "2.0" -and $evidence.environment -eq "production") "本番証跡のschema/environmentが不正です（製品ビルド用のschema 2.0が必要です）。"

    $product = $evidence.product
    Assert-Evidence ($null -ne $product) "本番証跡にproductがありません。"
    Assert-Evidence ($product.repository -eq $script:ProductRepository) "productのrepositoryが不正です。"
    Assert-Evidence ($product.commit -is [string] -and $product.commit -match '^[0-9a-f]{40}$') "productのcommitが不正です。"
    Assert-Evidence ($product.commit -eq $ExpectedProductCommit) "productのcommitが、開発基盤が固定している製品submoduleのcommitと一致しません（ゲートの検査対象と異なります）。"
    Assert-Evidence ($product.expert -eq $script:ProductExpert) "productのexpertは製品ビルド（$script:ProductExpert）である必要があります。"
    Assert-Evidence ($product.ea_version -is [string] -and $product.ea_version -match '^[0-9]+\.[0-9]+$') "productのea_versionが不正です。"
    Assert-Evidence (Test-Sha256Text $product.ex5_sha256) "productのex5_sha256が不正です。"

    # 試験運用（Demo・小額実口座）は、検証したものと同じex5で行う。
    foreach ($field in @("demo_ex5_sha256", "small_real_ex5_sha256")) {
        Assert-Evidence ((Test-Sha256Text $evidence.$field) -and ([string]$evidence.$field).ToUpperInvariant() -eq ([string]$product.ex5_sha256).ToUpperInvariant()) "試験運用のex5がリリース対象と一致しません: $field"
    }

    foreach ($field in $script:RequiredConfirmations) {
        Assert-Evidence ($evidence.$field -eq $true) "本番ゲート未達: $field"
    }

    foreach ($field in $script:RequiredReports) {
        Resolve-EvidenceFile $evidenceRoot ([string]$evidence.$field) $field | Out-Null
    }

    $manifestPaths = @($evidence.validation_manifests)
    Assert-Evidence ($manifestPaths.Count -gt 0 -and $null -ne $evidence.validation_manifests) "validation_manifests（Strategy Testerのmanifest.json）がありません。"
    $layers = @()
    for ($index = 0; $index -lt $manifestPaths.Count; $index++) {
        $field = "validation_manifests[$index]"
        $manifestPath = Resolve-EvidenceFile $evidenceRoot ([string]$manifestPaths[$index]) $field
        $layers += Assert-ValidationManifest $manifestPath $field $product $PlatformRoot
    }
    foreach ($layer in $script:RequiredValidationLayers) {
        Assert-Evidence ($layers -contains $layer) "必要な検証レイヤーの結果がありません: $layer（validation_layerを指定したCaseFileで実行してください）"
    }

    Assert-Evidence ($evidence.approver -is [string] -and -not [string]::IsNullOrWhiteSpace($evidence.approver) -and $evidence.approver.Length -le 64) "approverが不正です。"
    # 文字列以外（-DateKind非対応の7.0〜7.4でDateTime化された値を含む）はUTCか判定できないため拒否する。
    $approvedText = $evidence.approved_at
    $approved = [DateTimeOffset]::MinValue
    $isUtcTimestamp = $approvedText -is [string] -and
        $approvedText -match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|\+00:00)$' -and
        [DateTimeOffset]::TryParse($approvedText, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$approved) -and
        $approved.Offset -eq [TimeSpan]::Zero
    Assert-Evidence $isUtcTimestamp "approved_atはUTCで指定してください。"
}

Export-ModuleMember -Function Test-ProductionReleaseEvidence
