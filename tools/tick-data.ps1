# tickデータ取得・MT5変換パイプラインの統一入口（設計: docs/tick-data-pipeline.md）。
#
# 各工程は独立して実行できる。run は download -> normalize -> validate -> convert -> import -> verify を連続実行する。
# データ処理（取得・正規化・検証・変換・manifest）は python/tickdata が担い、このスクリプトはPython CLIの呼び出しと
# MT5端末の操作（既存Importer・検証スクリプトの起動、Journal回収）だけを行う。
#
# 例:
#   .\tools\tick-data.ps1 run -Config tools\tick-data\profiles\dukascopy-USDJPY.json
#   .\tools\tick-data.ps1 download -Provider dukascopy -Symbol USDJPY -FromDate 2016.09.01 -ToDate 2020.12.31 -ServerTime ny_close
#
# 既存のUSDJPY_HIST等（OANDA tick由来）のCustom Symbolは、既定では追記・削除されない
# （-AllowExistingSymbol / -ResetCustomSymbol を明示した場合のみ）。
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet("download", "normalize", "validate", "convert", "import", "verify", "status", "diff", "run")]
    [string]$Command,
    [string]$Config = "",
    [string]$Provider = "",
    [string]$Symbol = "",
    [string]$FromDate = "",
    [string]$ToDate = "",
    [string]$StorageRoot = "",
    [ValidateSet("", "day", "month")][string]$ChunkUnit = "",
    [string]$ServerTime = "",
    [string]$SourceSymbol = "",
    [string]$CustomSymbol = "",
    [switch]$Force,
    [string]$Other = "",
    # run の到達点。MT5=import・verifyまで、Normalized=validateまで（MT5端末を使わない）
    [ValidateSet("MT5", "Normalized")][string]$Target = "MT5",
    [string]$InstallPath = "C:\Program Files\OANDA MetaTrader 5",
    [string]$TerminalData = "$env:APPDATA\MetaQuotes\Terminal\EE0304F13905552AE0B5EAEFB04866EB",
    [int]$ImportTimeoutSeconds = 21600,
    [int]$ImportBatchSize = 20000,
    [switch]$AllowExistingSymbol,
    [switch]$ResetCustomSymbol,
    # verify で、短いStrategy Testerを実行して「ヒストリー品質」を確認する
    [switch]$HistoryQuality,
    [string]$QualityFromDate = "",
    [string]$QualityToDate = "",
    # 既定はCoreEAのウォームアップ制約を受けない軽量EA（MT5標準のMACD Sample）。ヒストリー品質とtick数だけを見るため
    [string]$QualityTemplate = "mt5\test-config\StrategyTester-TickQuality-M1.ini",
    [string]$Python = ".\.venv\Scripts\python.exe",
    # 既定trueで画面表示・フォーカス奪取を避ける非表示デスクトップ方式（CreateDesktopEx、DEC-031、
    # run-strategy-tester.ps1・run-mql5-tests.ps1と同じ）を使う。管理者権限は不要。falseで
    # 従来の-WindowStyle Hidden方式へフォールバックする。
    [bool]$HostUseIsolatedSession = $true
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $PSScriptRoot "lib\Mt5ExecutionBackend.psm1") -Force

$ExitMt5Failed = 5

function Get-DatasetArguments {
    $arguments = @()
    if ($Config) { $arguments += @("--config", $Config) }
    if ($Provider) { $arguments += @("--provider", $Provider) }
    if ($Symbol) { $arguments += @("--symbol", $Symbol) }
    if ($FromDate) { $arguments += @("--from", $FromDate) }
    if ($ToDate) { $arguments += @("--to", $ToDate) }
    if ($StorageRoot) { $arguments += @("--storage-root", $StorageRoot) }
    if ($ChunkUnit) { $arguments += @("--chunk-unit", $ChunkUnit) }
    if ($ServerTime) { $arguments += @("--server-time", $ServerTime) }
    if ($SourceSymbol) { $arguments += @("--source-symbol", $SourceSymbol) }
    if ($CustomSymbol) { $arguments += @("--custom-symbol", $CustomSymbol) }
    if ($Force) { $arguments += "--force" }
    return $arguments
}

# Python CLIを実行して終了コードを返す（標準出力はそのまま表示する）
function Invoke-TickDataCli {
    param([Parameter(Mandatory)][string]$CliCommand, [string[]]$ExtraArguments = @())
    $env:PYTHONPATH = "."
    # 標準出力は表示のみに使い、関数の戻り値（終了コード）へ混ぜない
    & $Python -m python.tickdata $CliCommand @(Get-DatasetArguments) @ExtraArguments | Out-Host
    return $LASTEXITCODE
}

function Get-DatasetStatus {
    $env:PYTHONPATH = "."
    $json = & $Python -m python.tickdata status @(Get-DatasetArguments) --json
    if ($LASTEXITCODE -ne 0) { throw "tick-data statusが失敗しました（exit=$LASTEXITCODE）。" }
    return $json | ConvertFrom-Json
}

function Assert-TerminalClosed {
    if (Get-Process terminal64 -ErrorAction SilentlyContinue) {
        throw "実行中のMetaTrader 5を終了してから実行してください。"
    }
}

function Get-TerminalLogPath { Join-Path $TerminalData ("MQL5\logs\" + (Get-Date -Format "yyyyMMdd") + ".log") }

# MT5のStartUp設定でスクリプトを1回実行し、その間にJournalへ追記された行を返す。
function Invoke-Mt5Script {
    param(
        [Parameter(Mandatory)][string]$ScriptName,
        [Parameter(Mandatory)][string]$ChartSymbol,
        [Parameter(Mandatory)][hashtable]$Inputs,
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][int]$TimeoutSeconds
    )
    $terminal = Join-Path $InstallPath "terminal64.exe"
    if (-not (Test-Path -LiteralPath $terminal)) { throw "Terminal not found: $terminal" }
    Assert-TerminalClosed

    $presetName = "tick-data-$Label.set"
    $presetDir = Join-Path $TerminalData "MQL5\Presets"
    New-Item -ItemType Directory -Path $presetDir -Force | Out-Null
    $presetLines = $Inputs.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }
    # MT5標準のプリセットと同じUTF-16 LE（BOM付き）で保存する
    [System.IO.File]::WriteAllText((Join-Path $presetDir $presetName), (($presetLines -join "`r`n") + "`r`n"), [System.Text.Encoding]::Unicode)

    $configDir = Join-Path $root "build\tick-data"
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    $configPath = Join-Path $configDir "$Label.ini"
    $ini = @(
        "[Experts]", "Enabled=1", "AllowLiveTrading=0", "AllowDllImport=0", "",
        "[StartUp]", "Script=EaTradingSystemTools\$ScriptName", "ScriptParameters=$presetName",
        "Symbol=$ChartSymbol", "Period=M1", "ShutdownTerminal=1"
    )
    Set-Content -LiteralPath $configPath -Value $ini -Encoding ASCII

    $log = Get-TerminalLogPath
    $beforeCount = if (Test-Path -LiteralPath $log) { (Get-Content -LiteralPath $log -Encoding Unicode).Count } else { 0 }
    $execResult = Invoke-Mt5Execution -ExecutionMode Host -ExecutablePath $terminal -ConfigFilePath $configPath `
        -TimeoutSeconds $TimeoutSeconds -HostUseIsolatedSession $HostUseIsolatedSession
    Write-Host "MT5_SCRIPT_FINISHED script=$ScriptName exit=$($execResult.ExitCode)"
    if (-not (Test-Path -LiteralPath $log)) { return @() }
    return @(Get-Content -LiteralPath $log -Encoding Unicode | Select-Object -Skip $beforeCount)
}

function Invoke-Import {
    $status = Get-DatasetStatus
    if ($status.convert -ne "complete") { throw "変換が完了していません。先に convert（または run）を実行してください。" }
    if (-not $status.custom_symbol) { throw "Custom Symbol名が未指定です（設定の mt5.custom_symbol または -CustomSymbol）。" }
    if ($status.custom_symbol -eq $status.source_symbol) { throw "Custom Symbol名が複製元の実Symbolと同じです: $($status.custom_symbol)" }
    if ($ResetCustomSymbol -and -not $AllowExistingSymbol) { throw "-ResetCustomSymbol は -AllowExistingSymbol と併用してください（既存履歴を削除します）。" }

    $existingTicks = Join-Path $TerminalData "bases\Custom\ticks\$($status.custom_symbol)"
    if ((Test-Path -LiteralPath $existingTicks) -and -not $AllowExistingSymbol) {
        throw "Custom Symbol '$($status.custom_symbol)' は既にtick履歴を持っています。既存データ保護のため中止しました。別名を指定するか、追記する場合のみ -AllowExistingSymbol を指定してください。"
    }
    Assert-TerminalClosed

    # MQL5\Files配下へ、変換済みフォルダへのJunctionを作る（数GBのコピーを避ける。既存のOANDA取込と同じ方式）
    $importRoot = Join-Path $TerminalData "MQL5\Files\EaTradingSystem\TickImport"
    New-Item -ItemType Directory -Path $importRoot -Force | Out-Null
    $link = Join-Path $importRoot $status.dataset_id
    if (Test-Path -LiteralPath $link) {
        $item = Get-Item -LiteralPath $link -Force
        if ($item.LinkType -ne "Junction" -or ($item.Target | Select-Object -First 1) -ne $status.mt5_dir) {
            throw "既存パスを置き換えません: $link"
        }
    } else {
        New-Item -ItemType Junction -Path $link -Target $status.mt5_dir | Out-Null
    }

    Write-Host "TICK_IMPORT_START dataset=$($status.dataset_id) custom_symbol=$($status.custom_symbol) files=$($status.convert_files) ticks=$($status.convert_tick_count)"
    $lines = Invoke-Mt5Script -ScriptName "ImportOandaTicks" -ChartSymbol $status.source_symbol -Label "import" -TimeoutSeconds $ImportTimeoutSeconds -Inputs @{
        InpSourceSymbol = $status.source_symbol
        InpCustomSymbol = $status.custom_symbol
        InpCustomPath   = $status.custom_path
        InpDataFolder   = "EaTradingSystem\TickImport\$($status.dataset_id)"
        InpSingleFile   = ""
        InpBatchSize    = $ImportBatchSize
        InpResetSymbol  = $(if ($ResetCustomSymbol) { "true" } else { "false" })
    }
    $markers = $lines | Where-Object { $_ -match "IMPORT_|FILE_IMPORTED|CUSTOM_SYMBOL_|CUSTOM_TICKS_ADD_SKIPPED|FILE_OPEN_FAILED|NO_FILES_FOUND|SOURCE_SYMBOL" }
    $logFile = Join-Path $status.dataset_dir ("import-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
    Set-Content -LiteralPath $logFile -Value $markers -Encoding UTF8
    return Invoke-TickDataCli -CliCommand "record-import" -ExtraArguments @("--log", $logFile)
}

function Invoke-Verify {
    $status = Get-DatasetStatus
    if ($status.import -notin @("complete", "complete_with_skips")) { throw "取込が完了していません。先に import を実行してください（status.import=$($status.import)）。" }
    $format = "yyyy.MM.dd HH:mm:ss.fff"
    $first = [datetime]::ParseExact($status.convert_first_server_time, $format, [Globalization.CultureInfo]::InvariantCulture)
    $last = [datetime]::ParseExact($status.convert_last_server_time, $format, [Globalization.CultureInfo]::InvariantCulture)
    $lines = Invoke-Mt5Script -ScriptName "VerifyCustomSymbolTicks" -ChartSymbol $status.source_symbol -Label "verify" -TimeoutSeconds $ImportTimeoutSeconds -Inputs @{
        InpSymbol      = $status.custom_symbol
        InpFromDate    = $first.Date.ToString("yyyy.MM.dd")
        InpToDate      = $last.Date.AddDays(1).ToString("yyyy.MM.dd")
        InpWindowHours = 24
    }
    $logFile = Join-Path $status.dataset_dir ("verify-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
    Set-Content -LiteralPath $logFile -Value ($lines | Where-Object { $_ -match "TICKVERIFY_" }) -Encoding UTF8
    $verifyExit = Invoke-TickDataCli -CliCommand "record-verify" -ExtraArguments @("--log", $logFile)
    if (-not $HistoryQuality) { return $verifyExit }
    # 照合が不一致でも、品質確認は独立した証拠として実行する。終了コードは失敗を優先する

    # 既存のStrategy Tester Runner（-CaseFile）を再利用し、短い期間でヒストリー品質を確認する
    $to = if ($QualityToDate) { $QualityToDate } else { $last.Date.ToString("yyyy.MM.dd") }
    $from = if ($QualityFromDate) { $QualityFromDate } else { $last.Date.AddDays(-4).ToString("yyyy.MM.dd") }
    $caseFile = Join-Path $root "build\tick-data\quality-$($status.dataset_id).json"
    $caseJson = @(@{
        case_name = "tick-quality"; symbol = $status.custom_symbol; from_date = $from; to_date = $to
        template  = $QualityTemplate
    }) | ConvertTo-Json -AsArray
    Set-Content -LiteralPath $caseFile -Value $caseJson -Encoding UTF8
    $startedAt = Get-Date
    & (Join-Path $PSScriptRoot "run-strategy-tester.ps1") -CaseFile $caseFile -InstallPath $InstallPath -TerminalData $TerminalData `
        -HostUseIsolatedSession $HostUseIsolatedSession | Out-Host
    $batch = Get-ChildItem (Join-Path $root "results\backtests") -Directory -Filter "*-cases" |
        Where-Object { $_.LastWriteTime -ge $startedAt } | Sort-Object LastWriteTime | Select-Object -Last 1
    if (-not $batch) { Write-Error "Strategy Testerの結果フォルダが見つかりません。"; return $ExitMt5Failed }
    $manifest = Get-Content -LiteralPath (Join-Path $batch.FullName "manifest.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $case = $manifest.cases | Select-Object -First 1
    if ($case.status -ne "Succeeded") { Write-Error "Strategy Testerケースが失敗しました: $($case.error)"; return $ExitMt5Failed }
    $report = Get-ChildItem $case.result_dir -Filter "*.htm*" -File | Select-Object -First 1
    if (-not $report) { Write-Error "Strategy Testerのレポートが見つかりません。"; return $ExitMt5Failed }
    $qualityExit = Invoke-TickDataCli -CliCommand "record-quality" -ExtraArguments @("--report", $report.FullName, "--case", "$($batch.Name)/$($case.case_name)")
    if ($verifyExit -ne 0) { return $verifyExit }
    return $qualityExit
}

Push-Location $root
try {
    if (-not (Test-Path -LiteralPath $Python)) { throw "Python仮想環境が見つかりません: $Python" }
    $exitCode = 0
    switch ($Command) {
        "diff" {
            if (-not $Other) { throw "diff には -Other <比較対象のdataset.json> が必要です。" }
            $exitCode = Invoke-TickDataCli -CliCommand "diff" -ExtraArguments @("--other", $Other)
        }
        "status" { $exitCode = Invoke-TickDataCli -CliCommand "status" }
        "import" { $exitCode = Invoke-Import }
        "verify" { $exitCode = Invoke-Verify }
        "run" {
            if ($Target -eq "Normalized") {
                foreach ($step in "download", "normalize", "validate") {
                    $exitCode = Invoke-TickDataCli -CliCommand $step
                    if ($exitCode -ne 0) { break }
                }
            } else {
                $exitCode = Invoke-TickDataCli -CliCommand "run"
                if ($exitCode -eq 0) { $exitCode = Invoke-Import }
                if ($exitCode -eq 0) { $exitCode = Invoke-Verify }
            }
        }
        default { $exitCode = Invoke-TickDataCli -CliCommand $Command }
    }
    exit $exitCode
}
finally { Pop-Location }
