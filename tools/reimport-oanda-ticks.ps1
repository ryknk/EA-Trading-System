# 既存Custom Symbol（OANDA証券のtick由来）へ、元のzipからtickを再投入して欠落を補う（DECISIONS.md DEC-037）。
#
# 旧Importerの`CustomTicksAdd()`は呼び出しごとに末尾128 tickを永続化しなかったため、既存のCustom Symbolは0.64%欠けている。
# 修正済みImporter（CustomTicksReplace）で同じ範囲を置換すると、欠けたtickだけが補われ、バーも再生成される。
# Custom Symbolの仕様・削除は行わない（InpResetSymbol=false固定）。置換は対象範囲のtickを書き換えるため、
# 事前に bases\Custom と bases\symbols.custom.dat をバックアップし、-BackupPath で場所を指定すること。
#
# 工程: Prepare（zip展開・行数集計）-> Import（Importer実行）-> Verify（月ファイルごとにMT5上のtick数を照合）-> Cleanup
#   .\tools\reimport-oanda-ticks.ps1 -CustomSymbol USDJPY_HIST -SourceSymbol USDJPY `
#     -ZipDir tick\OANDA\USDJPY_201609~ -BackupPath D:\Backup\mt5-custom-before-tickfix-20260921
# MT5端末を閉じてから実行する。バッチ1,000,000は、既存データの範囲置換が呼び出しごとに月ファイルを書き直すため
# 20,000より約23倍速い（USDJPY 2016-09の1か月で852秒 -> 36秒、実測）。
param(
    [Parameter(Mandatory)][string]$CustomSymbol,
    [Parameter(Mandatory)][string]$SourceSymbol,
    [Parameter(Mandatory)][string]$ZipDir,
    [Parameter(Mandatory)][string]$BackupPath,
    [ValidateSet("Prepare", "Import", "Verify", "TesterCheck", "Cleanup", "All")][string]$Phase = "All",
    [string]$WorkDir = "",
    [string]$Glob = "*.zip",
    [int]$BatchSize = 1000000,
    [int]$ImportTimeoutSeconds = 14400,
    [int]$VerifyTimeoutSeconds = 14400,
    [switch]$KeepCsv,
    [string]$InstallPath = "C:\Program Files\OANDA MetaTrader 5",
    [string]$TerminalData = "$env:APPDATA\MetaQuotes\Terminal\EE0304F13905552AE0B5EAEFB04866EB",
    [string]$Python = ".\.venv\Scripts\python.exe",
    # 既定trueで画面表示・フォーカス奪取を避ける非表示デスクトップ方式（CreateDesktopEx、DEC-031、
    # run-strategy-tester.ps1・run-mql5-tests.ps1と同じ）を使う。管理者権限は不要。falseで
    # 従来の-WindowStyle Hidden方式へフォールバックする。
    [bool]$HostUseIsolatedSession = $true
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $PSScriptRoot "lib\Mt5ExecutionBackend.psm1") -Force
if (-not $WorkDir) { $WorkDir = Join-Path $root "tick\reimport\$CustomSymbol" }
$csvDir = Join-Path $WorkDir "csv"
$scanPath = Join-Path $WorkDir "scan.json"
$filesRoot = Join-Path $TerminalData "MQL5\Files\EaTradingSystem\TickReimport"
$link = Join-Path $filesRoot $CustomSymbol
$importFolder = "EaTradingSystem\TickReimport\$CustomSymbol"
$ExitFailed = 5

function Assert-TerminalClosed {
    if (Get-Process terminal64 -ErrorAction SilentlyContinue) { throw "実行中のMetaTrader 5を終了してから実行してください。" }
}

function Invoke-Mt5Script {
    param([string]$ScriptName, [hashtable]$Inputs, [string]$Label, [int]$TimeoutSeconds)
    Assert-TerminalClosed
    $terminal = Join-Path $InstallPath "terminal64.exe"
    $presetName = "reimport-$CustomSymbol-$Label.set"
    $presetDir = Join-Path $TerminalData "MQL5\Presets"
    New-Item -ItemType Directory -Path $presetDir -Force | Out-Null
    $lines = $Inputs.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }
    [System.IO.File]::WriteAllText((Join-Path $presetDir $presetName), (($lines -join "`r`n") + "`r`n"), [System.Text.Encoding]::Unicode)
    New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
    $configPath = Join-Path $WorkDir "$Label.ini"
    Set-Content -LiteralPath $configPath -Encoding ASCII -Value @(
        "[Experts]", "Enabled=1", "AllowLiveTrading=0", "AllowDllImport=0", "",
        "[StartUp]", "Script=EaTradingSystemTools\$ScriptName", "ScriptParameters=$presetName",
        "Symbol=$SourceSymbol", "Period=M1", "ShutdownTerminal=1")
    $startedOn = Get-Date
    $log = Join-Path $TerminalData ("MQL5\logs\" + $startedOn.ToString("yyyyMMdd") + ".log")
    $before = if (Test-Path -LiteralPath $log) { (Get-Content -LiteralPath $log -Encoding Unicode).Count } else { 0 }
    $result = Invoke-Mt5Execution -ExecutionMode Host -ExecutablePath $terminal -ConfigFilePath $configPath `
        -TimeoutSeconds $TimeoutSeconds -HostUseIsolatedSession $HostUseIsolatedSession
    Write-Host "MT5_SCRIPT_FINISHED script=$ScriptName exit=$($result.ExitCode)"
    $collected = @(Get-Content -LiteralPath $log -Encoding Unicode | Select-Object -Skip $before)
    # Journalは日付ごとのファイルのため、実行が日付をまたいだ場合は翌日以降のファイルも全行読む（2026-09-22、GBPJPYで発生）
    for ($day = $startedOn.Date.AddDays(1); $day -le (Get-Date).Date; $day = $day.AddDays(1)) {
        $next = Join-Path $TerminalData ("MQL5\logs\" + $day.ToString("yyyyMMdd") + ".log")
        if (Test-Path -LiteralPath $next) { $collected += @(Get-Content -LiteralPath $next -Encoding Unicode) }
    }
    return $collected
}

function Invoke-Prepare {
    $env:PYTHONPATH = "."
    & $Python -m python.tickdata.oanda_zip prepare --zip-dir $ZipDir --out-dir $csvDir --scan-out $scanPath --glob $Glob
    if ($LASTEXITCODE -ne 0) { throw "zipの展開・集計に失敗しました（exit=$LASTEXITCODE）。" }
}

function Get-Scan { Get-Content -LiteralPath $scanPath -Raw -Encoding UTF8 | ConvertFrom-Json }

function Invoke-Import {
    if (-not (Test-Path -LiteralPath $scanPath)) { throw "先にPrepareを実行してください。" }
    if (-not (Test-Path -LiteralPath (Join-Path $TerminalData "bases\Custom\ticks\$CustomSymbol"))) {
        throw "Custom Symbol '$CustomSymbol' のtick履歴がありません（この道具は既存Symbolの補修専用です）。"
    }
    foreach ($needed in @("Custom\ticks\$CustomSymbol", "Custom\history\$CustomSymbol")) {
        if (-not (Test-Path -LiteralPath (Join-Path $BackupPath $needed))) { throw "バックアップが見つかりません: $(Join-Path $BackupPath $needed)" }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $BackupPath "symbols.custom.dat"))) { throw "バックアップにsymbols.custom.datがありません。" }
    Assert-TerminalClosed

    New-Item -ItemType Directory -Path $filesRoot -Force | Out-Null
    if (-not (Test-Path -LiteralPath $link)) { New-Item -ItemType Junction -Path $link -Target $csvDir | Out-Null }
    elseif (($item = Get-Item -LiteralPath $link -Force).LinkType -ne "Junction" -or ($item.Target | Select-Object -First 1) -ne $csvDir) { throw "既存パスを置き換えません: $link" }

    $scan = Get-Scan
    $expected = ($scan.PSObject.Properties.Value | Measure-Object lines -Sum).Sum
    Write-Host "REIMPORT_START symbol=$CustomSymbol files=$(@($scan.PSObject.Properties).Count) source_ticks=$expected batch=$BatchSize"
    $lines = Invoke-Mt5Script -ScriptName "ImportOandaTicks" -Label "import" -TimeoutSeconds $ImportTimeoutSeconds -Inputs @{
        InpSourceSymbol = $SourceSymbol; InpCustomSymbol = $CustomSymbol; InpCustomPath = "EaTradingSystem\History"
        InpDataFolder = $importFolder; InpSingleFile = ""; InpBatchSize = $BatchSize
        InpResetSymbol = "false"; InpUseReplace = "true"
    }
    $markers = $lines | Where-Object { $_ -match "IMPORT_|FILE_IMPORTED|CUSTOM_SYMBOL_|CUSTOM_TICKS_ADD_SKIPPED|REPLACE_FALLBACK|FILE_OPEN_FAILED|NO_FILES_FOUND" }
    Set-Content -LiteralPath (Join-Path $WorkDir ("import-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")) -Value $markers -Encoding UTF8

    $completed = $markers | Select-String -Pattern "IMPORT_COMPLETED symbol=(\S+) files=(\d+) total_ticks=(\d+) skipped_ticks=(\d+)" | Select-Object -Last 1
    if (-not $completed) { Write-Host "IMPORT_COMPLETEDを確認できません。"; return $ExitFailed }
    $files = [int]$completed.Matches[0].Groups[2].Value; $total = [long]$completed.Matches[0].Groups[3].Value; $skipped = [long]$completed.Matches[0].Groups[4].Value
    $parseFailures = 0L
    foreach ($m in ($markers | Select-String -Pattern "FILE_IMPORTED file=\S+ ticks=-?\d+ skipped=-?\d+ parse_failures=(\d+)")) { $parseFailures += [long]$m.Matches[0].Groups[1].Value }
    Write-Host "REIMPORT_RESULT files=$files total_ticks=$total skipped_ticks=$skipped parse_failures=$parseFailures source_ticks=$expected"
    if ($files -ne @($scan.PSObject.Properties).Count -or $skipped -ne 0 -or ($total + $skipped + $parseFailures) -ne $expected) {
        Write-Host "取込結果が元データと一致しません（ファイル数・skip・件数）。"; return $ExitFailed
    }
    return 0
}

# 不一致の各月について、月の中央付近の3日間をStrategy Testerで実行し、tick数を元CSVの行数と比べる。
# Strategy Testerは終了日時（ToDate 00:00）の直前1秒間のtickを含めない（実測: EURUSD 2026-05で4件、2026-08で2件）ため、期待値も終端の1秒前までで数える。
function Invoke-TesterCheck {
    param($Scan, $Rows)
    $format = "yyyy.MM.dd HH:mm:ss"
    $cases = @(); $expectedByCase = @{}; $index = 0
    foreach ($row in $Rows) {
        $entry = $Scan.PSObject.Properties.Value | Where-Object { $_.first_time.Substring(0, 19) -eq $row.from } | Select-Object -First 1
        $first = [datetime]::ParseExact($entry.first_time.Substring(0, 19), $format, [Globalization.CultureInfo]::InvariantCulture)
        $start = $first.Date.AddDays(10)
        $end = $start.AddDays(3)
        $index++
        $name = "check$index"
        $expected = & $Python -m python.tickdata.oanda_zip count --csv (Join-Path $csvDir $entry.csv) --from ($start.ToString("yyyy.MM.dd") + " 00:00:00.000") --to ($end.AddSeconds(-1).ToString("yyyy.MM.dd HH:mm:ss") + ".000")
        $cases += @{ case_name = $name; symbol = $CustomSymbol; from_date = $start.ToString("yyyy.MM.dd"); to_date = $end.ToString("yyyy.MM.dd"); template = "mt5\test-config\StrategyTester-Generic-H1.ini" }
        $expectedByCase[$name] = [pscustomobject]@{ window_from = $row.from; start = $start.ToString("yyyy.MM.dd"); expected = [long]$expected }
    }
    $caseFile = Join-Path $WorkDir "tester-check-cases.json"
    ConvertTo-Json -InputObject $cases -Depth 4 | Set-Content -LiteralPath $caseFile -Encoding UTF8
    $startedAt = Get-Date
    & (Join-Path $PSScriptRoot "run-strategy-tester.ps1") -CaseFile $caseFile -InstallPath $InstallPath -TerminalData $TerminalData `
        -HostUseIsolatedSession $HostUseIsolatedSession | Out-Host
    $batch = Get-ChildItem (Join-Path $root "results\backtests") -Directory -Filter "*-cases" | Where-Object { $_.LastWriteTime -ge $startedAt } | Sort-Object LastWriteTime | Select-Object -Last 1
    $manifest = if ($batch) { Get-Content -LiteralPath (Join-Path $batch.FullName "manifest.json") -Raw -Encoding UTF8 | ConvertFrom-Json }
    foreach ($case in @($manifest.cases)) {
        $info = $expectedByCase[$case.case_name]
        $ticks = -1L
        if ($case.status -eq "Succeeded") {
            $report = Get-ChildItem $case.result_dir -Filter "*.htm*" -File | Select-Object -First 1
            $env:PYTHONPATH = "."
            $parsed = & $Python -c "import sys,json; from pathlib import Path; from python.tickdata.mt5results import parse_tester_report; print(json.dumps(parse_tester_report(Path(sys.argv[1]))))" $report.FullName | ConvertFrom-Json
            if ($parsed.ticks) { $ticks = [long]$parsed.ticks }
        }
        [pscustomobject]@{ window_from = $info.window_from; sample_start = $info.start; expected = $info.expected; tester_ticks = $ticks; match = ($ticks -eq $info.expected) }
    }
}

function Invoke-Verify {
    if (-not (Test-Path -LiteralPath $scanPath)) { throw "先にPrepareを実行してください。" }
    $scan = Get-Scan
    $format = "yyyy.MM.dd HH:mm:ss"
    $windowLines = foreach ($entry in $scan.PSObject.Properties.Value) {
        $from = $entry.first_time.Substring(0, 19)
        $to = ([datetime]::ParseExact($entry.last_time.Substring(0, 19), $format, [Globalization.CultureInfo]::InvariantCulture)).AddSeconds(1).ToString($format)
        "$from|$to|$($entry.lines)"
    }
    New-Item -ItemType Directory -Path $filesRoot -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $filesRoot "windows-$CustomSymbol.txt") -Value $windowLines -Encoding ASCII
    $lines = Invoke-Mt5Script -ScriptName "CountCustomSymbolTicks" -Label "verify" -TimeoutSeconds $VerifyTimeoutSeconds -Inputs @{
        InpSymbol = $CustomSymbol; InpWindowsFile = "EaTradingSystem\TickReimport\windows-$CustomSymbol.txt"
    }
    $rows = foreach ($line in ($lines | Select-String -Pattern "TICKCOUNT symbol=\S+ from=(.+?) to=(.+?) ticks=(\d+) expected=(\d+) first_msc=(\d+) last_msc=(\d+) failed=(\d+)")) {
        $g = $line.Matches[0].Groups
        [pscustomobject]@{ from = $g[1].Value; to = $g[2].Value; stored = [long]$g[3].Value; expected = [long]$g[4].Value; failed = [int]$g[7].Value; match = ([long]$g[3].Value -eq [long]$g[4].Value -and [int]$g[7].Value -eq 0) }
    }
    $rows = @($rows)
    return Complete-Verify -Scan $scan -Rows $rows
}

# 件数照合の結果（rows）から報告書を作る。不一致の月はTesterで補完検証する。
function Complete-Verify {
    param($Scan, $Rows)
    $scan = $Scan; $rows = @($Rows)
    $bad = @($rows | Where-Object { -not $_.match })
    $report = [ordered]@{
        custom_symbol = $CustomSymbol; checked_at_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        windows = $rows.Count; expected_windows = @($scan.PSObject.Properties).Count
        stored_ticks = ($rows | Measure-Object stored -Sum).Sum; expected_ticks = ($rows | Measure-Object expected -Sum).Sum
        mismatches = $bad.Count; rows = $rows
    }
    # 直近月ではterminalのtick読み取りAPI（CopyTicksRange）が実データの一部しか返さない（DEC-033）ため、
    # 不一致の月は、Strategy Testerのtick数（実tickを使う）と元CSVの同範囲の行数で補完検証する。
    $testerChecks = @()
    if ($bad.Count -gt 0) { $testerChecks = @(Invoke-TesterCheck -Scan $scan -Rows $bad) }
    $testerBad = @($testerChecks | Where-Object { -not $_.match })
    $report.tester_checks = $testerChecks
    $report.unverified_windows = @($bad | Where-Object { $w = $_; -not ($testerChecks | Where-Object { $_.window_from -eq $w.from -and $_.match }) }).Count
    $reportPath = Join-Path $WorkDir "verify-report.json"
    $report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $reportPath -Encoding UTF8
    Write-Host "REIMPORT_VERIFY symbol=$CustomSymbol windows=$($rows.Count)/$($report.expected_windows) stored=$($report.stored_ticks) expected=$($report.expected_ticks) count_mismatches=$($bad.Count) tester_checked=$($testerChecks.Count) tester_mismatches=$($testerBad.Count) unverified=$($report.unverified_windows) report=$reportPath"
    $testerChecks | Format-Table | Out-Host
    if ($rows.Count -ne $report.expected_windows -or $report.unverified_windows -gt 0) { return $ExitFailed }
    return 0
}

function Invoke-TesterCheckPhase {
    $scan = Get-Scan
    $previous = Get-Content -LiteralPath (Join-Path $WorkDir "verify-report.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    return Complete-Verify -Scan $scan -Rows @($previous.rows)
}

function Invoke-Cleanup {
    if (Test-Path -LiteralPath $link) { [System.IO.Directory]::Delete($link) }
    if (-not $KeepCsv -and (Test-Path -LiteralPath $csvDir)) { Remove-Item -LiteralPath $csvDir -Recurse -Force }
}

Push-Location $root
try {
    if (-not (Test-Path -LiteralPath $Python)) { throw "Python仮想環境が見つかりません: $Python" }
    $exitCode = 0
    if ($Phase -in "Prepare", "All") { Invoke-Prepare }
    if ($Phase -in "Import", "All") { $exitCode = Invoke-Import }
    if ($exitCode -eq 0 -and $Phase -in "Verify", "All") { $exitCode = Invoke-Verify }
    if ($Phase -eq "TesterCheck") { $exitCode = Invoke-TesterCheckPhase }
    if ($exitCode -eq 0 -and $Phase -in "Cleanup", "All") { Invoke-Cleanup }
    exit $exitCode
}
finally { Pop-Location }
