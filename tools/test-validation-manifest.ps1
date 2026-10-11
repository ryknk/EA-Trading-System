# tools/lib/ValidationManifest.psm1 の単体テスト。MT5端末を起動せずに実行できる。
#
# 対象: CaseFileの読込・検証（既存CaseFile全件の後方互換を含む）、検証レイヤーと合否区分の対応、
# 合否基準・データmanifestのSHA-256記録、Git識別情報、製品ソースハッシュ、EAバージョン・ex5識別。
# Strategy Tester実行を伴うmanifest.json出力全体は本テストの対象外（run-strategy-tester.ps1 -CaseFileで確認する）。

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $PSScriptRoot "lib\ValidationManifest.psm1") -Force

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "ASSERTION_FAILED: $Message" }
}

function Assert-ThrowsMatching {
    param([scriptblock]$Action, [string]$Pattern, [string]$Message)
    $threw = $false
    try {
        & $Action
    } catch {
        $threw = $true
        if ($_.Exception.Message -notmatch $Pattern) {
            throw "ASSERTION_FAILED: $Message (期待パターン '$Pattern' に一致しないメッセージ: $($_.Exception.Message))"
        }
    }
    if (-not $threw) { throw "ASSERTION_FAILED: $Message (例外が発生しませんでした)" }
}

function Write-TestJson {
    param([string]$Path, [string]$Json)
    [System.IO.File]::WriteAllText($Path, $Json, [System.Text.UTF8Encoding]::new($false))
}

$work = Join-Path ([System.IO.Path]::GetTempPath()) ("ets-validation-manifest-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $work -Force | Out-Null
try {
    # --- 既存CaseFileは全件、任意メタデータなしのまま従来どおり読み込めること（後方互換） ---
    $caseFiles = @(Get-ChildItem -LiteralPath (Join-Path $root "mt5\test-config\cases") -Filter "*.json")
    Assert-True ($caseFiles.Count -gt 0) "既存CaseFileが見つかること"
    foreach ($file in $caseFiles) {
        $definition = Read-ValidationCaseFile -Path $file.FullName -Root $root
        Assert-True ($definition.Cases.Count -gt 0) "既存CaseFileにケースがあること: $($file.Name)"
        Assert-True ($null -eq $definition.ValidationLayer) "既存CaseFileはvalidation_layer未指定のままであること: $($file.Name)"
    }
    Write-Host "PASS Read-ValidationCaseFile 既存CaseFile全件 ($($caseFiles.Count)件)"

    $baseCase = '"symbol": "USDJPY_HIST", "from_date": "2020.01.01", "to_date": "2020.12.31", "template": "mt5\\test-config\\StrategyTester-Generic-H1.ini"'

    # --- 配列形式（要素数1）も従来どおり受け付けること ---
    $arrayPath = Join-Path $work "array.json"
    Write-TestJson $arrayPath "[ { `"case_name`": `"A`", $baseCase } ]"
    $arrayDefinition = Read-ValidationCaseFile -Path $arrayPath -Root $work
    Assert-True ($arrayDefinition.Cases.Count -eq 1 -and $arrayDefinition.Cases[0].case_name -eq "A") "要素数1の配列形式を1ケースとして読むこと"
    Write-Host "PASS Read-ValidationCaseFile 配列形式"

    # --- 必須項目欠落・case_name重複・ケース0件は従来と同じメッセージで拒否すること ---
    $missingPath = Join-Path $work "missing.json"
    Write-TestJson $missingPath '{ "cases": [ { "case_name": "A", "symbol": "USDJPY_HIST", "from_date": "2020.01.01", "to_date": "2020.12.31" } ] }'
    Assert-ThrowsMatching { Read-ValidationCaseFile -Path $missingPath -Root $work } "template が必須" "template欠落を拒否すること"
    $duplicatePath = Join-Path $work "duplicate.json"
    Write-TestJson $duplicatePath "{ `"cases`": [ { `"case_name`": `"A`", $baseCase }, { `"case_name`": `"A`", $baseCase } ] }"
    Assert-ThrowsMatching { Read-ValidationCaseFile -Path $duplicatePath -Root $work } "case_nameが重複" "case_name重複を拒否すること"
    $emptyPath = Join-Path $work "empty.json"
    Write-TestJson $emptyPath '{ "cases": [] }'
    Assert-ThrowsMatching { Read-ValidationCaseFile -Path $emptyPath -Root $work } "ケースが1件もありません" "ケース0件を拒否すること"
    Assert-ThrowsMatching { Read-ValidationCaseFile -Path (Join-Path $work "none.json") -Root $work } "CaseFile not found" "存在しないCaseFileを拒否すること"
    Write-Host "PASS Read-ValidationCaseFile 必須項目・重複・空"

    # --- validation_layer: CaseFile全体の値を継承し、ケース単位で上書きでき、合否区分を導出すること ---
    $layerPath = Join-Path $work "layer.json"
    Write-TestJson $layerPath "{ `"validation_layer`": `"walk_forward`", `"cases`": [ { `"case_name`": `"A`", $baseCase }, { `"case_name`": `"B`", `"validation_layer`": `"operational_fault`", $baseCase } ] }"
    $layerDefinition = Read-ValidationCaseFile -Path $layerPath -Root $work
    Assert-True ($layerDefinition.ValidationLayer -eq "walk_forward") "CaseFile全体のvalidation_layerを返すこと"
    Assert-True ($layerDefinition.Cases[0].validation_layer -eq "walk_forward" -and $layerDefinition.Cases[0].gate_category -eq "performance") "未指定ケースは全体の値を継承しperformanceになること"
    Assert-True ($layerDefinition.Cases[1].validation_layer -eq "operational_fault" -and $layerDefinition.Cases[1].gate_category -eq "safety") "operational_faultはsafetyになること"
    $badLayerPath = Join-Path $work "bad-layer.json"
    Write-TestJson $badLayerPath "{ `"cases`": [ { `"case_name`": `"A`", `"validation_layer`": `"oos`", $baseCase } ] }"
    Assert-ThrowsMatching { Read-ValidationCaseFile -Path $badLayerPath -Root $work } "validation_layerが不正" "未定義のvalidation_layerを拒否すること"
    Assert-True ((Get-ValidationLayerNames).Count -eq 9) "検証レイヤーは9種類であること"
    Write-Host "PASS Read-ValidationCaseFile validation_layer"

    # --- acceptance_criteria・data_manifest: 実在すればSHA-256を記録し、存在しなければ実行前に拒否すること ---
    $criteriaPath = Join-Path $work "criteria.json"
    Write-TestJson $criteriaPath '{ "note": "test" }'
    $dataPath = Join-Path $work "dataset.json"
    Write-TestJson $dataPath '{ "dataset_id": "mock-USDJPY" }'
    $linkedPath = Join-Path $work "linked.json"
    Write-TestJson $linkedPath "{ `"acceptance_criteria`": `"criteria.json`", `"cases`": [ { `"case_name`": `"A`", `"data_manifest`": `"dataset.json`", $baseCase } ] }"
    $linked = Read-ValidationCaseFile -Path $linkedPath -Root $work
    Assert-True ($linked.AcceptanceCriteria.path -eq "criteria.json") "acceptance_criteriaのパスを記録すること"
    Assert-True ($linked.AcceptanceCriteria.sha256 -eq (Get-FileHash -LiteralPath $criteriaPath -Algorithm SHA256).Hash) "acceptance_criteriaのSHA-256を記録すること"
    Assert-True ($linked.Cases[0].data_manifest_sha256 -eq (Get-FileHash -LiteralPath $dataPath -Algorithm SHA256).Hash) "data_manifestのSHA-256を記録すること"
    $missingCriteriaPath = Join-Path $work "missing-criteria.json"
    Write-TestJson $missingCriteriaPath "{ `"acceptance_criteria`": `"nothing.json`", `"cases`": [ { `"case_name`": `"A`", $baseCase } ] }"
    Assert-ThrowsMatching { Read-ValidationCaseFile -Path $missingCriteriaPath -Root $work } "acceptance_criteriaが見つかりません" "存在しない合否基準を拒否すること"
    $missingDataPath = Join-Path $work "missing-data.json"
    Write-TestJson $missingDataPath "{ `"cases`": [ { `"case_name`": `"A`", `"data_manifest`": `"nothing.json`", $baseCase } ] }"
    Assert-ThrowsMatching { Read-ValidationCaseFile -Path $missingDataPath -Root $work } "data_manifestが見つかりません" "存在しないデータmanifestを拒否すること"
    Write-Host "PASS Read-ValidationCaseFile acceptance_criteria・data_manifest"

    # --- ケース件数の集計: 該当1件・0件でも数値を返すこと（PowerShell 5.1で1件時に空欄になった不具合の回帰） ---
    $oneCase = @([PSCustomObject]@{ status = "Succeeded" })
    Assert-True ((Get-CaseStatusCount -Cases $oneCase -Status "Succeeded") -eq 1) "該当1件で1を返すこと"
    Assert-True ((Get-CaseStatusCount -Cases $oneCase -Status "Failed") -eq 0) "該当0件で0を返すこと"
    $mixedCases = @([PSCustomObject]@{ status = "Succeeded" }, [PSCustomObject]@{ status = "Failed" }, [PSCustomObject]@{ status = "Succeeded" })
    Assert-True ((Get-CaseStatusCount -Cases $mixedCases -Status "Succeeded") -eq 2) "複数件を数えること"
    Assert-True ((Get-CaseStatusCount -Cases @() -Status "Failed") -eq 0) "ケースなしで0を返すこと"
    Write-Host "PASS Get-CaseStatusCount"

    # --- remote URLから資格情報を除去すること ---
    Assert-True ((Get-SanitizedRemoteUrl "https://user:token@github.com/o/r.git") -eq "https://github.com/o/r.git") "https URLの資格情報を除去すること"
    Assert-True ((Get-SanitizedRemoteUrl "https://github.com/o/r.git") -eq "https://github.com/o/r.git") "資格情報のないURLは変更しないこと"
    Assert-True ((Get-SanitizedRemoteUrl "git@github.com:o/r.git") -eq "git@github.com:o/r.git") "SSH形式は変更しないこと"
    Write-Host "PASS Get-SanitizedRemoteUrl"

    # --- 製品ソースハッシュ: 対象拡張子だけを使い、内容変更で変わり、同一内容では一致すること ---
    $product = Join-Path $work "product"
    New-Item -ItemType Directory -Path (Join-Path $product "Experts"), (Join-Path $product "Include\Risk"), (Join-Path $product "Tests") -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $product "Experts\SampleEA.mq5") -Value @('#property strict', '#property version   "2.05"') -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $product "Include\Risk\Guard.mqh") -Value "// guard" -Encoding UTF8
    $hash1 = Get-SourceTreeSha256 -SourceRoot $product
    Set-Content -LiteralPath (Join-Path $product "Tests\TestGuard.mq5") -Value "// test" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $product "Experts\SampleEA.ex5") -Value "binary" -Encoding UTF8
    $hash2 = Get-SourceTreeSha256 -SourceRoot $product
    Assert-True ($hash1 -match '^[0-9A-F]{64}$') "ソースハッシュはSHA-256の16進64文字であること"
    Assert-True ($hash1 -eq $hash2) "Experts・Include外のファイルやex5はソースハッシュへ含めないこと"
    Set-Content -LiteralPath (Join-Path $product "Include\Risk\Guard.mqh") -Value "// guard changed" -Encoding UTF8
    Assert-True ((Get-SourceTreeSha256 -SourceRoot $product) -ne $hash1) "ソース変更でハッシュが変わること"
    Write-Host "PASS Get-SourceTreeSha256"

    # --- EAバージョン: 実在するCoreEA.mq5と、テスト用EAの#property versionを読むこと ---
    $coreVersion = Get-MqlPropertyVersion (Join-Path $root "mt5\Experts\CoreEA.mq5")
    Assert-True ($coreVersion -match '^[0-9]+\.[0-9]+$') "CoreEA.mq5の#property versionを読めること (実際: $coreVersion)"
    Assert-True ((Get-MqlPropertyVersion (Join-Path $product "Experts\SampleEA.mq5")) -eq "2.05") "テスト用EAのバージョンを読めること"
    Assert-True ($null -eq (Get-MqlPropertyVersion (Join-Path $product "Experts\None.mq5"))) "存在しないソースはnullであること"
    Write-Host "PASS Get-MqlPropertyVersion"

    # --- Expert識別: ex5のSHA-256を記録し、ソースより古いex5を検出すること ---
    $terminalData = Join-Path $work "terminal"
    $ex5Dir = Join-Path $terminalData "MQL5\Experts\Vendor"
    New-Item -ItemType Directory -Path $ex5Dir -Force | Out-Null
    $ex5 = Join-Path $ex5Dir "SampleEA.ex5"
    Set-Content -LiteralPath $ex5 -Value "compiled" -Encoding UTF8
    (Get-Item -LiteralPath $ex5).LastWriteTimeUtc = (Get-Date).ToUniversalTime().AddHours(-1)
    $identity = Get-ExpertIdentity -Expert "Vendor\SampleEA" -ProductSourceRoot $product -TerminalData $terminalData
    Assert-True ($identity.ea_version -eq "2.05") "Expertのソース上のバージョンを返すこと"
    Assert-True ($identity.expert_ex5_sha256 -eq (Get-FileHash -LiteralPath $ex5 -Algorithm SHA256).Hash) "ex5のSHA-256を返すこと"
    Assert-True ($identity.expert_ex5_older_than_source -eq $true) "ソースより古いex5を検出すること"
    (Get-Item -LiteralPath $ex5).LastWriteTimeUtc = (Get-Date).ToUniversalTime().AddHours(1)
    $fresh = Get-ExpertIdentity -Expert "Vendor\SampleEA" -ProductSourceRoot $product -TerminalData $terminalData
    Assert-True ($fresh.expert_ex5_older_than_source -eq $false) "ソースより新しいex5は検出しないこと"
    $noTerminal = Get-ExpertIdentity -Expert "Vendor\SampleEA" -ProductSourceRoot $product
    Assert-True ($null -eq $noTerminal.expert_ex5_sha256 -and $noTerminal.ea_version -eq "2.05") "TerminalData未指定（VM実行）はex5を記録しないこと"
    # 研究ビルドのように製品外（開発基盤側）にあるEAは、追加のソースルートからバージョンを解決すること。
    $platform = Join-Path $work "platform"
    New-Item -ItemType Directory -Path (Join-Path $platform "Experts") -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $platform "Experts\ResearchEA.mq5") -Value @('#property strict', '#property version   "3.01"') -Encoding UTF8
    $researchIdentity = Get-ExpertIdentity -Expert "Vendor\ResearchEA" -ProductSourceRoot $product -AdditionalSourceRoots @($platform)
    Assert-True ($researchIdentity.ea_version -eq "3.01") "追加のソースルートからEAバージョンを解決すること"
    Assert-True ($null -eq (Get-ExpertIdentity -Expert "Vendor\ResearchEA" -ProductSourceRoot $product).ea_version) "追加のソースルートがなければ製品外のEAはnullであること"
    Write-Host "PASS Get-ExpertIdentity"

    # --- Git識別情報: Git外はnull、Git内はcommitを返し、未コミット変更をdirtyとして検出すること ---
    $nonGit = Get-GitSourceInfo -Path $product
    Assert-True ($null -eq $nonGit.commit -and $null -eq $nonGit.dirty) "Git外のパスはcommit・dirtyがnullであること"
    if (Get-Command git -ErrorAction SilentlyContinue) {
        & git -C $product init --quiet
        & git -C $product -c user.name=test -c user.email=test@example.invalid add -A
        & git -C $product -c user.name=test -c user.email=test@example.invalid commit --quiet -m "init"
        $clean = Get-GitSourceInfo -Path $product
        $expectedCommit = (& git -C $product rev-parse HEAD).Trim()
        Assert-True ($clean.commit -eq $expectedCommit) "HEADのcommitを返すこと"
        Assert-True ($clean.dirty -eq $false) "未変更ならdirty=falseであること"
        Set-Content -LiteralPath (Join-Path $product "Include\Risk\Guard.mqh") -Value "// dirty" -Encoding UTF8
        Assert-True ((Get-GitSourceInfo -Path $product).dirty -eq $true) "未コミット変更をdirty=trueとして検出すること"
        $provenance = Get-ValidationProvenance -PlatformRoot $root -ProductSourceRoot $product -InstallPath (Join-Path $work "no-mt5")
        Assert-True ($provenance.product.commit -eq $expectedCommit) "provenance.productは製品ソースのcommitであること"
        Assert-True ($provenance.platform.repository -ne $provenance.product.repository) "検証基盤と製品のリポジトリを区別して記録すること"
        Assert-True ($provenance.product.source_tree_sha256 -match '^[0-9A-F]{64}$') "provenance.productにソースハッシュを含むこと"
        Assert-True ($null -eq $provenance.mt5.terminal_file_version) "MT5未導入パスでは端末バージョンがnullであること"
        Write-Host "PASS Get-GitSourceInfo・Get-ValidationProvenance"
    } else {
        Write-Host "SKIP Get-GitSourceInfo（gitコマンドが見つかりません）"
    }
} finally {
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "VALIDATION_MANIFEST_TEST_PASS"
