# 既定ではOANDA証券MT5端末を対象とする（2026-08-16以降の本番運用Broker、DECISIONS.md DEC-023）。
# XMTrading-MT5（C:\Program Files\MetaTrader 5、Terminal Data: D0E8209F77C8CF37AD8BF550E51FF075）は
# 参考用として残しており、対象にする場合は-InstallPath/-TerminalDataを明示指定すること。
#
# 単体実行（従来どおり）:
#   .\tools\run-strategy-tester.ps1 -Symbol USDJPY -FromDate 2017.09.01 -ToDate 2020.12.31 -Template mt5\test-config\StrategyTester-USDJPY-H1.ini
#
# 複数ケース実行（Cross-Asset Validation、OOS、Walk Forward、Stress Test等で共用）:
#   .\tools\run-strategy-tester.ps1 -CaseFile mt5\test-config\cases\cross-symbol-2020-2024.json
#
# CaseFileはJSON配列（またはcasesキーを持つオブジェクト）で、各ケースへ最低限
# case_name / symbol / from_date / to_date / template を指定する。
param(
    [string]$InstallPath = "C:\Program Files\OANDA MetaTrader 5",
    [string]$TerminalData = "$env:APPDATA\MetaQuotes\Terminal\EE0304F13905552AE0B5EAEFB04866EB",
    [int]$TimeoutSeconds = 900,
    [string]$Symbol = "USDJPY",
    [string]$FromDate = "2017.09.01",
    [string]$ToDate = "2020.12.31",
    [string]$Template = "mt5\test-config\StrategyTester-USDJPY-H1.ini",
    [string]$CaseFile = "",
    [string]$Python = ".\.venv\Scripts\python.exe",
    [double]$AnnualRiskFreeRate = 0.0,
    # MT5実行バックエンド（既定Host、従来どおりホスト上で直接terminal64.exeを起動する）。
    # VM指定時はホストのGUIフォーカスを奪わず、WinRM/PSRemoting経由でVM上のMT5を実行する。
    [ValidateSet("Host", "VM")][string]$ExecutionMode = "Host",
    [string]$VmSettingsPath = "tools\config\mt5-vm.settings.json",
    # ExecutionMode=Host専用。既定trueで画面表示・フォーカス奪取を避ける非表示デスクトップ方式
    # （CreateDesktopEx、DEC-031）を使う。管理者権限は不要。falseにすると従来の
    # -WindowStyle Hidden方式へフォールバックする。
    [bool]$HostUseIsolatedSession = $true
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $PSScriptRoot "lib\Mt5ExecutionBackend.psm1") -Force

function Read-IniValue {
    param([string]$Path, [string]$Key)
    $line = Get-Content -LiteralPath $Path | Where-Object { $_ -match "^$Key=(.*)$" } | Select-Object -First 1
    if ($line -match "^$Key=(.*)$") { return $Matches[1] }
    return $null
}

function Get-SafeSlug {
    param([string]$Value)
    $slug = ($Value -replace '[^A-Za-z0-9._-]', '_')
    if ([string]::IsNullOrEmpty($slug)) { $slug = "case" }
    return $slug
}

function Get-CompactDate {
    param([string]$DotDate)
    return ($DotDate -replace '\.', '')
}

# [TesterInputs]セクションのEA input行（Inp<Key>=<Value>）を設定する。既に同名の行があれば値を置き換え、
# なければ[TesterInputs]セクションへ新規行として追加する（テンプレートが当該inputを持たない場合に対応）。
function Set-IniTesterInput {
    param([string[]]$Content, [Parameter(Mandatory)][string]$Key, [Parameter(Mandatory)][string]$Value)
    $pattern = "^$Key=.*$"
    if ($Content -match $pattern) {
        return $Content -replace $pattern, ("$Key=" + $Value)
    }
    $result = New-Object System.Collections.Generic.List[string]
    $inserted = $false
    foreach ($line in $Content) {
        $result.Add($line)
        if (-not $inserted -and $line -eq "[TesterInputs]") {
            $result.Add("$Key=$Value")
            $inserted = $true
        }
    }
    if (-not $inserted) {
        $result.Add("[TesterInputs]")
        $result.Add("$Key=$Value")
    }
    return , $result.ToArray()
}

# 1ケース分のStrategy Tester実行を共通化した処理。単体実行・複数ケース実行の両方から呼び出す。
function Invoke-StrategyTesterCase {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$InstallPath,
        [Parameter(Mandatory)][string]$TerminalData,
        [Parameter(Mandatory)][int]$TimeoutSeconds,
        [Parameter(Mandatory)][string]$Template,
        [Parameter(Mandatory)][string]$FromDate,
        [Parameter(Mandatory)][string]$ToDate,
        [string]$Symbol = "",
        [Parameter(Mandatory)][string]$ResultDir,
        [Parameter(Mandatory)][string]$ReportName,
        [ValidateSet("Host", "VM")][string]$ExecutionMode = "Host",
        [string]$VmSettingsPath = "",
        [bool]$HostUseIsolatedSession = $true
    )

    $terminal = Join-Path $InstallPath "terminal64.exe"

    $templatePath = if ([System.IO.Path]::IsPathRooted($Template)) { $Template } else { Join-Path $Root $Template }
    if (-not (Test-Path -LiteralPath $templatePath)) { throw "Template not found: $templatePath" }
    $templateSha256 = (Get-FileHash -LiteralPath $templatePath -Algorithm SHA256).Hash

    # 監査JSONLはFILE_COMMON（Terminal\Common\Files配下）で保存されるため、そのディレクトリ名は
    # テンプレートのInpAuditLogDirectory（未指定時はEA既定値と同じEaTradingSystem\Audit）に従う。
    $auditLogDirectory = Read-IniValue $templatePath "InpAuditLogDirectory"
    if ([string]::IsNullOrWhiteSpace($auditLogDirectory)) { $auditLogDirectory = "EaTradingSystem\Audit" }

    $vmSettingsFullPath = ""
    $vmSyncSourcePaths = @()
    if ($ExecutionMode -eq "VM") {
        $vmSettingsFullPath = if ([System.IO.Path]::IsPathRooted($VmSettingsPath)) { $VmSettingsPath } else { Join-Path $Root $VmSettingsPath }
        $vmSettings = Test-Mt5VmSettings -Path $vmSettingsFullPath
        if ($vmSettings.vmTerminalData) { $vmSyncSourcePaths += $vmSettings.vmTerminalData }
        if ($vmSettings.vmInstallPath) { $vmSyncSourcePaths += $vmSettings.vmInstallPath }
        if ($vmSyncSourcePaths.Count -eq 0) {
            throw "VM設定ファイルにvmTerminalDataまたはvmInstallPathが必要です（report/audit取得のため）: $vmSettingsFullPath"
        }
        # 監査JSONLはFILE_COMMON（Strategy Tester Agentのサンドボックスの外）へ保存されるため、
        # TerminalData/InstallPathの同期とは別にCommon配下のAuditディレクトリだけを同期対象へ追加する
        # （Commonフォルダ全体は同期しない）。vmCommonDataPath/vmTerminalDataのいずれからも算出できない
        # 場合はベストエフォートとして同期をスキップする（既存の成功判定には影響させない）。
        $vmCommonAuditPath = Get-Mt5VmCommonAuditPath -Settings $vmSettings -AuditLogDirectory $auditLogDirectory
        if ($vmCommonAuditPath) {
            $vmSyncSourcePaths += $vmCommonAuditPath
        } else {
            Write-Host "STRATEGY_TESTER_VM_COMMON_AUDIT_PATH_UNKNOWN note=vmCommonDataPathまたはvmTerminalDataからAudit同期先を算出できませんでした"
        }
    } else {
        if (-not (Test-Path -LiteralPath $terminal)) { throw "Terminal not found: $terminal" }
        if (Get-Process terminal64 -ErrorAction SilentlyContinue) { throw "自動実行前に起動中のMetaTrader 5を終了してください。" }
    }

    New-Item -ItemType Directory -Path $ResultDir -Force | Out-Null
    $config = Join-Path $ResultDir "tester.ini"
    $content = Get-Content -LiteralPath $templatePath
    $content = $content -replace '^ReplaceReport=1$', ("Report=" + $ReportName + "`r`nReplaceReport=1")
    $content = $content -replace '^FromDate=.*$', ("FromDate=" + $FromDate)
    $content = $content -replace '^ToDate=.*$', ("ToDate=" + $ToDate)
    if (-not [string]::IsNullOrEmpty($Symbol)) {
        # CaseFileまたは-Symbol明示指定時のみSymbol/InpSymbolを上書きする。
        # 未指定時（既定の単体実行）はTemplateが宣言するSymbolをそのまま使う＝従来と同じ挙動。
        $content = $content -replace '^Symbol=.*$', ("Symbol=" + $Symbol)
        $content = $content -replace '^InpSymbol=.*$', ("InpSymbol=" + $Symbol)
    }
    # 監査JSONLのファイル名をRun ID単位（audit-<ReportName>.jsonl）にする。Reportと同じ識別子を再利用し、
    # 実行間・ケース間でのログ混入を防ぐ（重複するID生成基盤は追加しない）。
    $content = Set-IniTesterInput -Content $content -Key "InpAuditRunId" -Value $ReportName
    Set-Content -LiteralPath $config -Value $content -Encoding Unicode

    $expert = Read-IniValue $config "Expert"
    $depositRaw = Read-IniValue $config "Deposit"
    $deposit = if ($depositRaw) { [double]$depositRaw } else { $null }
    $effectiveSymbol = Read-IniValue $config "Symbol"
    $period = Read-IniValue $config "Period"
    if ([string]::IsNullOrEmpty($period)) { $period = "H1" }

    $searchRoots = @($Root, $TerminalData, $InstallPath, (Join-Path $env:APPDATA "MetaQuotes")) | Select-Object -Unique
    # $Rootはリポジトリ全体（results/backtests配下に蓄積される過去の全実行結果を含む）を再帰検索
    # するため重く（実測で30万ファイル超・約2.5秒、実行を重ねるほど遅くなる）。後段のreport検索
    # リトライでは、高頻度なポーリングに$Rootを除いた軽量なパス（実測で計0.2秒未満）を使う。
    $fastSearchRoots = $searchRoots | Where-Object { $_ -ne $Root }

    # 監査JSONLはRun ID単位のファイル名（audit-<ReportName>.jsonl、上記Set-IniTesterInput参照）で
    # 保存されるため、実行前に前回分のaudit-*.jsonlを削除する処理は不要になった。かつてはEA側が
    # 日付単位のファイル名（audit-YYYYMMDD.jsonl）へSEEK_END追記する設計だったため、Tester Agent
    # フォルダに残る前回実行分との混入を避けるための事前削除が必要だったが（2026-08-22発見）、
    # FILE_COMMON化・Run ID単位のファイル名化により実行ごとに別ファイルへ分離されたため解消した。
    # なお、FILE_COMMON化後のCommonフォルダは複数ターミナル・複数実行で共有されるため、もし削除処理を
    # 残すと他の実行のaudit-*.jsonlを誤って削除するリスクがある。

    $execResult = Invoke-Mt5Execution -ExecutionMode $ExecutionMode -ExecutablePath $terminal `
        -ConfigFilePath $config -TimeoutSeconds $TimeoutSeconds `
        -VmSettingsPath $vmSettingsFullPath -SyncSourcePaths $vmSyncSourcePaths `
        -StagingRoot (Join-Path $ResultDir "_vm-staging") -HostUseIsolatedSession $HostUseIsolatedSession
    $exitCode = $execResult.ExitCode
    # VM実行時は、共通実行バックエンドがVM側TerminalData/InstallPathをホスト側へ同期した結果を
    # 検索対象へ追加する。以降のreport/audit検索ロジックはHost/VMで変更しない。
    if ($ExecutionMode -eq "VM") { $searchRoots += $execResult.StagingRoots }

    # terminal64.exeプロセスの終了検知（ExitCode確定）と、実際のreportファイルがディスク上に
    # 出現するタイミングとの間にわずかな遅延が生じる可能性があるため、保険として即座に1回だけ
    # 試すのではなく、一定時間・短い間隔でリトライする。
    $reportSearchTimeoutSeconds = 10
    $reportSearchIntervalMilliseconds = 250
    $reportSearchDeadline = (Get-Date).AddSeconds($reportSearchTimeoutSeconds)
    $reportSearchAttempts = 0
    $reports = @()
    while ($true) {
        $reportSearchAttempts++
        $reports = foreach ($searchRoot in $fastSearchRoots) {
            if (Test-Path -LiteralPath $searchRoot) {
                Get-ChildItem -LiteralPath $searchRoot -Recurse -File -ErrorAction SilentlyContinue |
                    Where-Object { $_.BaseName -eq $ReportName }
            }
        }
        if ($reports) { break }
        if ((Get-Date) -gt $reportSearchDeadline) { break }
        Start-Sleep -Milliseconds $reportSearchIntervalMilliseconds
    }
    if (-not $reports) {
        # 軽量パスで見つからなかった場合の最終フォールバック（$Rootを含めた全パスを1回だけ検索）。
        $reports = foreach ($searchRoot in $searchRoots) {
            if (Test-Path -LiteralPath $searchRoot) {
                Get-ChildItem -LiteralPath $searchRoot -Recurse -File -ErrorAction SilentlyContinue |
                    Where-Object { $_.BaseName -eq $ReportName }
            }
        }
        $reportSearchAttempts++
    }
    if ($reportSearchAttempts -gt 1) {
        Write-Host "STRATEGY_TESTER_REPORT_SEARCH_RETRIED attempts=$reportSearchAttempts found=$([bool]$reports)"
    }
    if (-not $reports) { throw "Strategy Testerは終了しましたがreportが生成されませんでした。Tester logを確認してください。" }
    $reportFiles = @()
    foreach ($generated in $reports) {
        Copy-Item -LiteralPath $generated.FullName -Destination (Join-Path $ResultDir $generated.Name) -Force
        $reportFiles += $generated.Name
    }

    # InpAuditFileEnabled=trueの場合、FILE_COMMON配下（Terminal\Common\Files\<AuditLogDirectory>、
    # Strategy Tester Agentのサンドボックスの外）へ audit-<ReportName>.jsonl が出力される。ファイル名が
    # 本実行のReportNameで一意なため、検索は拡張子付きの完全一致（ワイルドカードなし）で行い、
    # 他の実行・他ターミナルのaudit-*.jsonlを誤って回収しない。分析（python.analysis.trade_breakdown等）
    # 用に、生成されていればresult配下へ複製する。ベストエフォートであり、見つからなくてもStrategy
    # Tester自体の成功判定には影響させない（VM実行時は回収結果を明示的にログ出力する）。
    $auditFileName = "audit-$ReportName.jsonl"
    $auditFiles = foreach ($searchRoot in $searchRoots) {
        if (Test-Path -LiteralPath $searchRoot) {
            Get-ChildItem -LiteralPath $searchRoot -Recurse -File -Filter $auditFileName -ErrorAction SilentlyContinue
        }
    }
    $auditFiles = @($auditFiles | Sort-Object -Property FullName -Unique)
    $auditDir = $null
    $auditFileNames = @()
    if ($auditFiles.Count -gt 0) {
        $auditDir = Join-Path $ResultDir "audit"
        New-Item -ItemType Directory -Path $auditDir -Force | Out-Null
        foreach ($generated in $auditFiles) {
            Copy-Item -LiteralPath $generated.FullName -Destination (Join-Path $auditDir $generated.Name) -Force
            $auditFileNames += $generated.Name
        }
        Write-Host "STRATEGY_TESTER_AUDIT_COPIED count=$($auditFiles.Count) dir=$auditDir mode=$ExecutionMode"
    } else {
        Write-Host "STRATEGY_TESTER_AUDIT_NOT_FOUND note=InpAuditFileEnabledの設定を確認してください mode=$ExecutionMode expected=$auditFileName"
    }

    Write-Host "STRATEGY_TESTER_COMPLETED exit=$exitCode result=$ResultDir"

    return [PSCustomObject]@{
        ResultDir      = $ResultDir
        ConfigPath     = $config
        ReportName     = $ReportName
        ReportFiles    = $reportFiles
        ExitCode       = $exitCode
        Symbol         = $effectiveSymbol
        Period         = $period
        Expert         = $expert
        Deposit        = $deposit
        TemplatePath   = $templatePath
        TemplateSha256 = $templateSha256
        AuditDir       = $auditDir
        AuditFiles     = $auditFileNames
    }
}

if ([string]::IsNullOrEmpty($CaseFile)) {
    # ---- 単体実行モード（従来どおりSymbol/FromDate/ToDate/Templateを指定して1ケース実行） ----
    $templatePath = if ([System.IO.Path]::IsPathRooted($Template)) { $Template } else { Join-Path $root $Template }
    if (-not (Test-Path -LiteralPath $templatePath)) { throw "Template not found: $templatePath" }

    $symbolOverride = if ($PSBoundParameters.ContainsKey('Symbol')) { $Symbol } else { "" }
    $namingSymbol = if ($symbolOverride) { $symbolOverride } else { Read-IniValue $templatePath "Symbol" }
    if ([string]::IsNullOrEmpty($namingSymbol)) { $namingSymbol = $Symbol }
    $namingPeriod = Read-IniValue $templatePath "Period"
    if ([string]::IsNullOrEmpty($namingPeriod)) { $namingPeriod = "H1" }

    $runId = Get-Date -Format "yyyyMMdd-HHmmss"
    $resultDir = Join-Path $root "results\backtests\$runId-$namingSymbol-$namingPeriod"
    $reportName = "ets-$runId-$namingSymbol-$namingPeriod"

    Invoke-StrategyTesterCase -Root $root -InstallPath $InstallPath -TerminalData $TerminalData `
        -TimeoutSeconds $TimeoutSeconds -Template $Template -FromDate $FromDate -ToDate $ToDate `
        -Symbol $symbolOverride -ResultDir $resultDir -ReportName $reportName `
        -ExecutionMode $ExecutionMode -VmSettingsPath $VmSettingsPath -HostUseIsolatedSession $HostUseIsolatedSession | Out-Null
    return
}

# ---- 複数ケース実行モード（CaseFileから複数テストケースを読み込み、同じ1ケース実行処理を順番に実行） ----
$caseFilePath = if ([System.IO.Path]::IsPathRooted($CaseFile)) { $CaseFile } else { Join-Path $root $CaseFile }
if (-not (Test-Path -LiteralPath $caseFilePath)) { throw "CaseFile not found: $caseFilePath" }
$caseFileRaw = Get-Content -LiteralPath $caseFilePath -Raw -Encoding UTF8
$parsed = $caseFileRaw | ConvertFrom-Json
# ConvertFrom-Jsonは要素数1のJSON配列をスカラーへ展開してしまうため、@()で強制的に配列化する。
# casesキーを持つオブジェクト形式でなければ、配列（要素数1でスカラー化されている場合を含む）とみなす。
$cases = if ($parsed.PSObject.Properties.Name -contains 'cases') { @($parsed.cases) } else { @($parsed) }
if (-not $cases -or $cases.Count -eq 0) { throw "CaseFileにケースが1件もありません。" }

$requiredFields = @("case_name", "symbol", "from_date", "to_date", "template")
$seenNames = @{}
foreach ($case in $cases) {
    foreach ($field in $requiredFields) {
        if (-not ($case.PSObject.Properties.Name -contains $field) -or [string]::IsNullOrWhiteSpace([string]$case.$field)) {
            throw "CaseFileの各ケースには $field が必須です（case_name=$($case.case_name)）。"
        }
    }
    if ($seenNames.ContainsKey($case.case_name)) { throw "case_nameが重複しています: $($case.case_name)" }
    $seenNames[$case.case_name] = $true
}

$runId = Get-Date -Format "yyyyMMdd-HHmmss"
$batchDir = Join-Path $root "results\backtests\$runId-cases"
New-Item -ItemType Directory -Path $batchDir -Force | Out-Null
$caseFileHash = (Get-FileHash -LiteralPath $caseFilePath -Algorithm SHA256).Hash

$manifest = [ordered]@{
    schema_version   = "1.0"
    run_id           = $runId
    created_at_utc   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    install_path     = $InstallPath
    terminal_data    = $TerminalData
    timeout_seconds  = $TimeoutSeconds
    case_file        = $caseFilePath
    case_file_sha256 = $caseFileHash
    cases            = @()
}
$manifestPath = Join-Path $batchDir "manifest.json"
$summaryRows = @()

foreach ($case in $cases) {
    $caseName = [string]$case.case_name
    $symbol = [string]$case.symbol
    $fromDate = [string]$case.from_date
    $toDate = [string]$case.to_date
    $template = [string]$case.template

    $slug = Get-SafeSlug $caseName
    $caseDirName = "$slug-$(Get-SafeSlug $symbol)-$(Get-CompactDate $fromDate)_$(Get-CompactDate $toDate)"
    $caseResultDir = Join-Path $batchDir $caseDirName
    $reportName = "ets-$runId-$slug"

    Write-Host "STRATEGY_TESTER_CASE_START case=$caseName symbol=$symbol from=$fromDate to=$toDate"

    $caseRecord = [ordered]@{
        case_name           = $caseName
        symbol              = $symbol
        from_date           = $fromDate
        to_date             = $toDate
        template            = $template
        result_dir          = $caseResultDir
        report_name         = $reportName
        status              = "Failed"
        error               = $null
        exit_code           = $null
        expert              = $null
        deposit             = $null
        template_sha256     = $null
        audit_dir           = $null
        performance_summary = $null
    }

    $performanceSummary = $null
    $execResult = $null
    try {
        $execResult = Invoke-StrategyTesterCase -Root $root -InstallPath $InstallPath -TerminalData $TerminalData `
            -TimeoutSeconds $TimeoutSeconds -Template $template -FromDate $fromDate -ToDate $toDate `
            -Symbol $symbol -ResultDir $caseResultDir -ReportName $reportName `
            -ExecutionMode $ExecutionMode -VmSettingsPath $VmSettingsPath -HostUseIsolatedSession $HostUseIsolatedSession

        $caseRecord.status = "Succeeded"
        $caseRecord.exit_code = $execResult.ExitCode
        $caseRecord.expert = $execResult.Expert
        $caseRecord.deposit = $execResult.Deposit
        $caseRecord.template_sha256 = $execResult.TemplateSha256
        $caseRecord.audit_dir = $execResult.AuditDir
    } catch {
        $caseRecord.status = "Failed"
        $caseRecord.error = $_.Exception.Message
        Write-Host "STRATEGY_TESTER_CASE_FAILED case=$caseName error=$($_.Exception.Message)"
    }

    # 分析（python.analysis.reports）の失敗は、Strategy Tester自体の成功/失敗判定に影響させない
    # （既存の分析基盤への影響を避ける要件）。Strategy Testerが成功したケースのみ、別のtry/catchで実行する。
    if ($caseRecord.status -eq "Succeeded") {
        try {
            if ($execResult.AuditDir -and $execResult.AuditFiles.Count -gt 0) {
                # 既存のpython.analysis.reportsをそのまま再利用してケース単位の成績を集計する。
                # 監査JSONLは日次ファイルのため年間バックテストでは数百件になり、ファイルごとに
                # --inputを渡すとWindowsのコマンドライン長上限（約32,767文字）を超えて
                # 「ファイル名または拡張子が長すぎます」で失敗する。事前に1ファイルへ結合してから渡す。
                $analysisOutput = Join-Path $caseResultDir "performance-report"
                $mergedAuditPath = Join-Path $execResult.AuditDir "_merged-for-analysis.jsonl"
                $writer = [System.IO.StreamWriter]::new($mergedAuditPath, $false, [System.Text.UTF8Encoding]::new($false))
                try {
                    foreach ($auditFileName in $execResult.AuditFiles) {
                        foreach ($jsonLine in (Get-Content -LiteralPath (Join-Path $execResult.AuditDir $auditFileName) -Encoding UTF8)) {
                            $writer.WriteLine($jsonLine)
                        }
                    }
                } finally { $writer.Close() }
                $inputArgs = @("--input", $mergedAuditPath)
                $deposit = if ($execResult.Deposit) { $execResult.Deposit } else { 1000000 }
                Push-Location $root
                try {
                    $env:PYTHONPATH = "."
                    & $Python -m python.analysis.reports @inputArgs --initial-balance $deposit --annual-risk-free-rate $AnnualRiskFreeRate --output $analysisOutput
                    $analysisExit = $LASTEXITCODE
                } finally { Pop-Location }
                if ($analysisExit -eq 0) {
                    $summaryJsonPath = Join-Path $analysisOutput "performance-summary.json"
                    if (Test-Path -LiteralPath $summaryJsonPath) {
                        # performance-summary.jsonはBOMなしUTF-8でPythonが出力するため、-Encodingを明示しないと
                        # Windows PowerShell 5.1でANSI/CP932として誤読され、definitions内の日本語説明文が
                        # 文字化けしてConvertFrom-Jsonが失敗する（2026-09-02発見）。
                        $performanceSummary = Get-Content -LiteralPath $summaryJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
                        $caseRecord.performance_summary = (Join-Path $analysisOutput "performance-summary.json")
                    }
                } else {
                    Write-Host "STRATEGY_TESTER_ANALYSIS_FAILED case=$caseName exit=$analysisExit"
                    $caseRecord.error = "分析コマンドが失敗しました（Strategy Tester自体は成功、analysis exit=$analysisExit）"
                }
            } else {
                Write-Host "STRATEGY_TESTER_ANALYSIS_SKIPPED case=$caseName note=監査JSONLが見つかりません"
            }
        } catch {
            Write-Host "STRATEGY_TESTER_ANALYSIS_FAILED case=$caseName error=$($_.Exception.Message)"
            $caseRecord.error = "分析コマンドが例外で失敗しました（Strategy Tester自体は成功）: $($_.Exception.Message)"
        }
    }

    if ($caseRecord.status -eq "Succeeded") {
        $summaryRows += [PSCustomObject]@{
            CaseName             = $caseName
            Symbol               = $symbol
            FromDate             = $fromDate
            ToDate               = $toDate
            NetProfit            = if ($performanceSummary) { $performanceSummary.metrics.net_profit } else { $null }
            CAGR                 = if ($performanceSummary) { $performanceSummary.metrics.cagr } else { $null }
            MaxDrawdown          = if ($performanceSummary) { $performanceSummary.metrics.max_drawdown_rate } else { $null }
            ProfitFactor         = if ($performanceSummary) { $performanceSummary.metrics.profit_factor } else { $null }
            SharpeRatio          = if ($performanceSummary) { $performanceSummary.metrics.sharpe_ratio } else { $null }
            WinRate              = if ($performanceSummary) { $performanceSummary.metrics.win_rate } else { $null }
            AverageWin           = if ($performanceSummary) { $performanceSummary.metrics.average_win } else { $null }
            AverageLoss          = if ($performanceSummary) { $performanceSummary.metrics.average_loss } else { $null }
            Expectancy           = if ($performanceSummary) { $performanceSummary.metrics.expectancy } else { $null }
            MaxConsecutiveLosses = if ($performanceSummary) { $performanceSummary.metrics.maximum_consecutive_losses } else { $null }
            Trades               = if ($performanceSummary) { $performanceSummary.metrics.number_of_trades } else { $null }
            Status               = "Succeeded"
            ResultPath           = $caseResultDir
        }
    } else {
        $summaryRows += [PSCustomObject]@{
            CaseName = $caseName; Symbol = $symbol; FromDate = $fromDate; ToDate = $toDate
            NetProfit = $null; CAGR = $null; MaxDrawdown = $null; ProfitFactor = $null; SharpeRatio = $null
            WinRate = $null; AverageWin = $null; AverageLoss = $null; Expectancy = $null
            MaxConsecutiveLosses = $null; Trades = $null; Status = "Failed: $($caseRecord.error)"
            ResultPath = $caseResultDir
        }
    }

    $manifest.cases += [PSCustomObject]$caseRecord
    ($manifest | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath $manifestPath -Encoding UTF8
}

$summaryCsvPath = Join-Path $batchDir "summary.csv"
$summaryRows | Export-Csv -LiteralPath $summaryCsvPath -NoTypeInformation -Encoding UTF8

$summaryMdPath = Join-Path $batchDir "summary.md"
$mdLines = @(
    "# Backtest Case Summary",
    "",
    "Run ID: $runId",
    "",
    "| CaseName | Symbol | FromDate | ToDate | NetProfit | CAGR | MaxDD | PF | Sharpe | WinRate | AvgWin | AvgLoss | Expectancy | MaxConsecLosses | Trades | Status | ResultPath |",
    "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"
)
foreach ($row in $summaryRows) {
    $mdLines += "| $($row.CaseName) | $($row.Symbol) | $($row.FromDate) | $($row.ToDate) | $($row.NetProfit) | $($row.CAGR) | $($row.MaxDrawdown) | $($row.ProfitFactor) | $($row.SharpeRatio) | $($row.WinRate) | $($row.AverageWin) | $($row.AverageLoss) | $($row.Expectancy) | $($row.MaxConsecutiveLosses) | $($row.Trades) | $($row.Status) | $($row.ResultPath) |"
}
Set-Content -LiteralPath $summaryMdPath -Value ($mdLines -join "`n") -Encoding UTF8

$succeeded = ($manifest.cases | Where-Object { $_.status -eq "Succeeded" }).Count
$failed = ($manifest.cases | Where-Object { $_.status -eq "Failed" }).Count
Write-Host "STRATEGY_TESTER_BATCH_COMPLETED total=$($cases.Count) succeeded=$succeeded failed=$failed manifest=$manifestPath summary=$summaryCsvPath"
