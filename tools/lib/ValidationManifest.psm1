# Strategy Tester検証のCaseFile読込・検証と、検証対象（製品ソース・MT5・設定・データ）の識別情報取得。
# run-strategy-tester.ps1から使う。MT5端末を起動せずに単体テストできるよう、Runner本体から分離している
# （tools/test-validation-manifest.ps1）。設計判断はDECISIONS.md DEC-044、CaseFile仕様はdocs/backtesting.md。

$ErrorActionPreference = "Stop"

# 検証レイヤー。operational_faultだけを安全機能（safety）の合否として扱い、それ以外は性能評価（performance）とする。
$script:ValidationLayerGateCategory = [ordered]@{
    strategy_test     = "performance"
    in_sample         = "performance"
    out_of_sample     = "performance"
    walk_forward      = "performance"
    final_holdout     = "performance"
    multi_symbol      = "performance"
    cost_stress       = "performance"
    operational_fault = "safety"
    forward_test      = "performance"
}

$script:RequiredCaseFields = @("case_name", "symbol", "from_date", "to_date", "template")

function Get-ValidationLayerNames {
    return @($script:ValidationLayerGateCategory.Keys)
}

function Get-ValidationGateCategory {
    param([string]$ValidationLayer)
    if ([string]::IsNullOrEmpty($ValidationLayer)) { return $null }
    return $script:ValidationLayerGateCategory[$ValidationLayer]
}

function Resolve-RepoPath {
    param([Parameter(Mandatory)][string]$Root, [Parameter(Mandatory)][string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }
    return (Join-Path $Root $Path)
}

function Get-FileSha256OrNull {
    param([string]$Path)
    if ([string]::IsNullOrEmpty($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $null }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-OptionalStringProperty {
    param($Object, [string]$Name)
    if ($null -eq $Object -or -not ($Object.PSObject.Properties.Name -contains $Name)) { return $null }
    $value = [string]$Object.$Name
    if ([string]::IsNullOrWhiteSpace($value)) { return $null }
    return $value
}

function Assert-ValidationLayer {
    param([string]$Value, [string]$Context)
    if (-not [string]::IsNullOrEmpty($Value) -and -not $script:ValidationLayerGateCategory.Contains($Value)) {
        throw "validation_layerが不正です（$Context）: $Value。許可値: $((Get-ValidationLayerNames) -join ', ')"
    }
}

# CaseFileを読み込み、必須項目・case_name重複・任意メタデータ（validation_layer、acceptance_criteria、
# data_manifest）を検証する。不正な場合はMT5を起動する前に例外にする。
# 任意メタデータが無い既存CaseFileは従来どおり受け付ける（後方互換）。
function Read-ValidationCaseFile {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Root)

    if (-not (Test-Path -LiteralPath $Path)) { throw "CaseFile not found: $Path" }
    $parsed = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    # ConvertFrom-Jsonは要素数1のJSON配列をスカラーへ展開してしまうため、@()で強制的に配列化する。
    # casesキーを持つオブジェクト形式でなければ、配列（要素数1でスカラー化されている場合を含む）とみなす。
    $isObjectForm = $parsed.PSObject.Properties.Name -contains 'cases'
    $cases = if ($isObjectForm) { @($parsed.cases) } else { @($parsed) }
    if (-not $cases -or $cases.Count -eq 0) { throw "CaseFileにケースが1件もありません。" }

    $batchLayer = $null
    $criteriaPath = $null
    if ($isObjectForm) {
        $batchLayer = Get-OptionalStringProperty $parsed "validation_layer"
        Assert-ValidationLayer -Value $batchLayer -Context "CaseFile"
        $criteriaPath = Get-OptionalStringProperty $parsed "acceptance_criteria"
    }
    $criteria = $null
    if ($criteriaPath) {
        $criteriaFullPath = Resolve-RepoPath -Root $Root -Path $criteriaPath
        if (-not (Test-Path -LiteralPath $criteriaFullPath -PathType Leaf)) {
            throw "acceptance_criteriaが見つかりません: $criteriaFullPath"
        }
        $criteria = [ordered]@{
            path   = $criteriaPath
            sha256 = Get-FileSha256OrNull $criteriaFullPath
        }
    }

    $seenNames = @{}
    $normalized = @()
    foreach ($case in $cases) {
        foreach ($field in $script:RequiredCaseFields) {
            if (-not ($case.PSObject.Properties.Name -contains $field) -or [string]::IsNullOrWhiteSpace([string]$case.$field)) {
                throw "CaseFileの各ケースには $field が必須です（case_name=$($case.case_name)）。"
            }
        }
        if ($seenNames.ContainsKey($case.case_name)) { throw "case_nameが重複しています: $($case.case_name)" }
        $seenNames[$case.case_name] = $true

        $caseLayer = Get-OptionalStringProperty $case "validation_layer"
        Assert-ValidationLayer -Value $caseLayer -Context "case_name=$($case.case_name)"
        $layer = if ($caseLayer) { $caseLayer } else { $batchLayer }

        $dataManifest = Get-OptionalStringProperty $case "data_manifest"
        $dataManifestSha256 = $null
        if ($dataManifest) {
            $dataManifestFullPath = Resolve-RepoPath -Root $Root -Path $dataManifest
            if (-not (Test-Path -LiteralPath $dataManifestFullPath -PathType Leaf)) {
                throw "data_manifestが見つかりません（case_name=$($case.case_name)）: $dataManifestFullPath"
            }
            $dataManifestSha256 = Get-FileSha256OrNull $dataManifestFullPath
        }

        $normalized += [PSCustomObject]@{
            case_name            = [string]$case.case_name
            symbol               = [string]$case.symbol
            from_date            = [string]$case.from_date
            to_date              = [string]$case.to_date
            template             = [string]$case.template
            validation_layer     = $layer
            gate_category        = Get-ValidationGateCategory $layer
            data_manifest        = $dataManifest
            data_manifest_sha256 = $dataManifestSha256
        }
    }

    return [PSCustomObject]@{
        Cases               = $normalized
        ValidationLayer     = $batchLayer
        AcceptanceCriteria  = $criteria
    }
}

# 認証情報を含むremote URL（https://user:token@host/...）から資格情報部分を除去する。
function Get-SanitizedRemoteUrl {
    param([string]$Url)
    if ([string]::IsNullOrWhiteSpace($Url)) { return $null }
    return ($Url -replace '^([A-Za-z][A-Za-z0-9+.-]*://)[^/@]+@', '$1')
}

# 指定パスを含むGitリポジトリのcommit・branch・未コミット変更の有無を返す。Git外・git未導入時はnull項目で返す。
function Get-GitSourceInfo {
    param([Parameter(Mandatory)][string]$Path)
    $info = [ordered]@{
        path       = $Path
        repository = $null
        remote_url = $null
        commit     = $null
        branch     = $null
        dirty      = $null
    }
    if (-not (Test-Path -LiteralPath $Path) -or -not (Get-Command git -ErrorAction SilentlyContinue)) { return $info }

    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $topLevel = & git -C $Path rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($topLevel)) { return $info }
        $info.repository = ([string]$topLevel).Trim()
        $commit = & git -C $Path rev-parse HEAD 2>$null
        if ($LASTEXITCODE -eq 0) { $info.commit = ([string]$commit).Trim() }
        $branch = & git -C $Path rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0) { $info.branch = ([string]$branch).Trim() }
        $remote = & git -C $Path remote get-url origin 2>$null
        if ($LASTEXITCODE -eq 0) { $info.remote_url = Get-SanitizedRemoteUrl ([string]$remote).Trim() }
        # 対象パス配下だけの未コミット変更（未追跡ファイルを含む）。dirty=trueの結果は特定commitの再現とみなさない。
        $status = & git -C $Path status --porcelain --untracked-files=normal -- . 2>$null
        if ($LASTEXITCODE -eq 0) { $info.dirty = (@($status | Where-Object { $_ }).Count -gt 0) }
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    return $info
}

# 製品ソース（Experts・Include配下の.mq5/.mqh）の内容ハッシュ。相対パスとファイルSHA-256を整列して連結し、
# そのSHA-256を返す。未コミット変更があってもソース内容そのものを識別できる。
function Get-SourceTreeSha256 {
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [string[]]$SubDirectories = @("Experts", "Include"),
        [string[]]$Extensions = @(".mq5", ".mqh")
    )
    $rootFull = (Resolve-Path -LiteralPath $SourceRoot).Path.TrimEnd('\', '/')
    $entries = New-Object System.Collections.Generic.List[string]
    foreach ($sub in $SubDirectories) {
        $dir = Join-Path $rootFull $sub
        if (-not (Test-Path -LiteralPath $dir)) { continue }
        Get-ChildItem -LiteralPath $dir -Recurse -File | Where-Object { $Extensions -contains $_.Extension.ToLowerInvariant() } | ForEach-Object {
            $relative = $_.FullName.Substring($rootFull.Length + 1).Replace('\', '/')
            $entries.Add("$relative`t$((Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash)")
        }
    }
    if ($entries.Count -eq 0) { return $null }
    $sorted = $entries.ToArray()
    [Array]::Sort($sorted, [StringComparer]::Ordinal)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($sorted -join "`n"))
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '') } finally { $sha.Dispose() }
}

function Get-MqlPropertyVersion {
    param([string]$SourcePath)
    if ([string]::IsNullOrEmpty($SourcePath) -or -not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) { return $null }
    $line = Get-Content -LiteralPath $SourcePath | Where-Object { $_ -match '^\s*#property\s+version\s+"([^"]+)"' } | Select-Object -First 1
    if ($line -match '^\s*#property\s+version\s+"([^"]+)"') { return $Matches[1] }
    return $null
}

function Get-Mt5TerminalBuild {
    param([string]$InstallPath)
    if ([string]::IsNullOrEmpty($InstallPath)) { return $null }
    $terminal = Join-Path $InstallPath "terminal64.exe"
    if (-not (Test-Path -LiteralPath $terminal -PathType Leaf)) { return $null }
    $version = (Get-Item -LiteralPath $terminal).VersionInfo
    if ([string]::IsNullOrWhiteSpace($version.FileVersion)) { return $null }
    return $version.FileVersion
}

# CaseFile実行全体で共通の検証対象識別情報（検証基盤・製品ソース・MT5端末）。
# 取得失敗は実行を止めずnullで記録する（Strategy Tester自体の成否判定へ影響させない）。
function Get-ValidationProvenance {
    param(
        [Parameter(Mandatory)][string]$PlatformRoot,
        [Parameter(Mandatory)][string]$ProductSourceRoot,
        [string]$InstallPath = ""
    )
    $productSourceSha256 = $null
    if (Test-Path -LiteralPath $ProductSourceRoot) {
        $productSourceSha256 = Get-SourceTreeSha256 -SourceRoot $ProductSourceRoot
    }
    $product = Get-GitSourceInfo -Path $ProductSourceRoot
    $product.source_tree_sha256 = $productSourceSha256
    return [ordered]@{
        platform = Get-GitSourceInfo -Path $PlatformRoot
        product  = $product
        mt5      = [ordered]@{ terminal_file_version = Get-Mt5TerminalBuild $InstallPath }
    }
}

# Expert（例: EaTradingSystem\CoreEA）の製品ソース上のバージョンと、端末が実行するex5のSHA-256。
# ex5が製品ソースより古い場合は、未コンパイルの変更がある可能性を示す（mtime比較のため参考情報）。
function Get-ExpertIdentity {
    param(
        [string]$Expert,
        [Parameter(Mandatory)][string]$ProductSourceRoot,
        [string]$TerminalData = ""
    )
    $identity = [ordered]@{
        ea_version                   = $null
        expert_ex5_sha256            = $null
        expert_ex5_older_than_source = $null
    }
    if ([string]::IsNullOrWhiteSpace($Expert)) { return $identity }
    $expertLeaf = Split-Path -Leaf $Expert
    $identity.ea_version = Get-MqlPropertyVersion (Join-Path $ProductSourceRoot "Experts\$expertLeaf.mq5")
    if ([string]::IsNullOrEmpty($TerminalData)) { return $identity }

    $ex5 = Join-Path $TerminalData "MQL5\Experts\$Expert.ex5"
    $identity.expert_ex5_sha256 = Get-FileSha256OrNull $ex5
    if ($identity.expert_ex5_sha256) {
        $newestSource = Get-ChildItem -LiteralPath @((Join-Path $ProductSourceRoot "Experts"), (Join-Path $ProductSourceRoot "Include")) -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -in @(".mq5", ".mqh") } |
            Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
        if ($newestSource) {
            $identity.expert_ex5_older_than_source = ((Get-Item -LiteralPath $ex5).LastWriteTimeUtc -lt $newestSource.LastWriteTimeUtc)
        }
    }
    return $identity
}

# Windows PowerShell 5.1では該当1件のときWhere-Objectが単一のPSCustomObjectを返し.Countが$nullになるため、@()で配列化する。
function Get-CaseStatusCount {
    param([object[]]$Cases, [Parameter(Mandatory)][string]$Status)
    return @($Cases | Where-Object { $_.status -eq $Status }).Count
}

Export-ModuleMember -Function Get-ValidationLayerNames, Get-ValidationGateCategory, Get-FileSha256OrNull, Get-CaseStatusCount, `
    Read-ValidationCaseFile, Get-SanitizedRemoteUrl, Get-GitSourceInfo, Get-SourceTreeSha256, Get-MqlPropertyVersion, `
    Get-Mt5TerminalBuild, Get-ValidationProvenance, Get-ExpertIdentity
