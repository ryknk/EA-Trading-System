# tools/lib/Mt5ExecutionBackend.psm1 の単体テスト。
#
# 実VMが無くても検証できる範囲（Host実行の正常系・タイムアウト、VM設定不備時の明確なエラー）
# のみを対象とする。実際のVmrun（VMware Workstation/Player）・WinRM/PSRemoting接続の
# 成功系は本スクリプトの対象外（実機でのVMware Workstation VM検証は別途
# run-mql5-tests.ps1 -ExecutionMode VM / run-strategy-tester.ps1 -ExecutionMode VM を
# 実際のVM設定で実行して確認する。2026-09-06に実機確認済み、DECISIONS.md DEC-029参照）。
#
# Host実行は既定でCreateDesktopEx（十分なヒープサイズを明示指定した非表示デスクトップ）経由の
# 対話セッション内実行を使う（DEC-031参照。標準CreateDesktop方式はヒープサイズ不足で放棄し、
# 一時検討したタスクスケジューラ方式もSession 0のGUI制約により廃止した経緯がある）。
# 対話セッション内での実行のため管理者権限や事前セットアップは不要で、既定経路
# （UseIsolatedSession=true）を環境に依らず常に検証できる。
# -HostUseIsolatedSession $falseで従来の-WindowStyle Hidden方式へ切替可能にしており、
# 本スクリプトではその経路（正常系・タイムアウト）も検証している。

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $PSScriptRoot "lib\Mt5ExecutionBackend.psm1") -Force

$pingExe = Join-Path $env:SystemRoot "System32\PING.EXE"
$cmdExe = $env:ComSpec

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

Write-Host "MT5_EXECUTION_BACKEND_TEST_START"

# --- Host正常系: exitコード0を返して正常終了すること ---
$result = Invoke-Mt5Execution -ExecutionMode Host -ExecutablePath $cmdExe -ExecutableArguments @("/c", "exit", "0") -TimeoutSeconds 10
Assert-True ($result.Success -eq $true) "Host正常系: Successがtrueであること"
Assert-True ($result.ExitCode -eq 0) "Host正常系: ExitCodeが0であること"
Assert-True ($result.ExecutionMode -eq "Host") "Host正常系: ExecutionModeがHostであること"
Write-Host "PASS Host正常系"

# --- Host正常系: 0以外のExitCodeもそのまま伝播すること ---
$result2 = Invoke-Mt5Execution -ExecutionMode Host -ExecutablePath $cmdExe -ExecutableArguments @("/c", "exit", "7") -TimeoutSeconds 10
Assert-True ($result2.ExitCode -eq 7) "Host ExitCode伝播: ExitCodeが7であること"
Write-Host "PASS Host ExitCode伝播"

# --- Hostタイムアウト: 長時間コマンドを短いタイムアウトで強制終了させ、例外になること ---
Assert-ThrowsMatching -Action {
    Invoke-Mt5Execution -ExecutionMode Host -ExecutablePath $pingExe -ExecutableArguments @("-n", "30", "127.0.0.1") -TimeoutSeconds 2
} -Pattern "タイムアウト" -Message "Hostタイムアウト: タイムアウト例外が発生すること"
Start-Sleep -Milliseconds 500
Assert-True (-not (Get-Process -Name "PING" -ErrorAction SilentlyContinue)) "Hostタイムアウト: タイムアウト後にpingプロセスが残っていないこと"
Write-Host "PASS Hostタイムアウト"

# --- HostUseIsolatedSession=$false: 従来の-WindowStyle Hidden方式（フォールバック）でも正常系が動くこと ---
# （タスクスケジューラの権限有無に関わらず常に検証できる経路）。
$resultFallback = Invoke-Mt5Execution -ExecutionMode Host -ExecutablePath $cmdExe -ExecutableArguments @("/c", "exit", "0") -TimeoutSeconds 10 -HostUseIsolatedSession $false
Assert-True ($resultFallback.Success -eq $true) "HostUseIsolatedSession=false正常系: Successがtrueであること"
Assert-True ($resultFallback.ExitCode -eq 0) "HostUseIsolatedSession=false正常系: ExitCodeが0であること"
Write-Host "PASS HostUseIsolatedSession=false正常系"

# --- HostUseIsolatedSession=$false: タイムアウトでも例外になり、プロセスが残らないこと ---
Assert-ThrowsMatching -Action {
    Invoke-Mt5Execution -ExecutionMode Host -ExecutablePath $pingExe -ExecutableArguments @("-n", "30", "127.0.0.1") -TimeoutSeconds 2 -HostUseIsolatedSession $false
} -Pattern "タイムアウト" -Message "HostUseIsolatedSession=falseタイムアウト: タイムアウト例外が発生すること"
Start-Sleep -Milliseconds 500
Assert-True (-not (Get-Process -Name "PING" -ErrorAction SilentlyContinue)) "HostUseIsolatedSession=falseタイムアウト: タイムアウト後にpingプロセスが残っていないこと"
Write-Host "PASS HostUseIsolatedSession=falseタイムアウト"

# --- ConfigFilePath指定時は /config:<パス> 引数が自動生成されること（バッチファイルで引数を捕捉して検証） ---
$echoArgsBat = Join-Path $env:TEMP "mt5-exec-backend-test-echo-args.cmd"
$echoArgsOut = Join-Path $env:TEMP "mt5-exec-backend-test-echo-args.out"
"@echo off`r`necho %1>`"$echoArgsOut`"" | Set-Content -LiteralPath $echoArgsBat -Encoding ASCII
$dummyConfig = Join-Path $env:TEMP "mt5-exec-backend-test-dummy.ini"
"dummy" | Set-Content -LiteralPath $dummyConfig -Encoding UTF8
try {
    Remove-Item -LiteralPath $echoArgsOut -Force -ErrorAction SilentlyContinue
    # ConfigFilePath指定時はExecutableArguments指定の有無に関わらず "/config:<dummyConfig>" のみが渡ることを確認する。
    # 引数生成ロジック自体の検証が目的でHost/Isolated Session経路の違いは無関係なため、
    # タスクスケジューラの権限有無に関わらず実行できるHostUseIsolatedSession=falseで検証する。
    Invoke-Mt5Execution -ExecutionMode Host -ExecutablePath $echoArgsBat -ConfigFilePath $dummyConfig -TimeoutSeconds 10 -HostUseIsolatedSession $false | Out-Null
    Assert-True (Test-Path -LiteralPath $echoArgsOut) "ConfigFilePath: echo-args出力ファイルが生成されること"
    $capturedArgs = (Get-Content -LiteralPath $echoArgsOut -Raw).Trim()
    Assert-True ($capturedArgs -eq "/config:$dummyConfig") "ConfigFilePath: 引数が /config:<パス> のみになること (実際: $capturedArgs)"
    Write-Host "PASS ConfigFilePath自動引数生成"
} finally {
    Remove-Item -LiteralPath $echoArgsBat, $echoArgsOut, $dummyConfig -Force -ErrorAction SilentlyContinue
}

# --- VM設定ファイル不存在: Hostへフォールバックせず明確な例外になること ---
Assert-ThrowsMatching -Action {
    Invoke-Mt5Execution -ExecutionMode VM -VmSettingsPath (Join-Path $env:TEMP "not-exist-mt5-vm-settings.json") -TimeoutSeconds 10
} -Pattern "見つかりません" -Message "VM設定ファイル不存在: 明確な例外になること"
Write-Host "PASS VM設定ファイル不存在"

# --- VM設定ファイルの必須フィールド欠落: 不足フィールド名を含む例外になること ---
$incompleteSettings = Join-Path $env:TEMP "mt5-exec-backend-test-incomplete-vm-settings.json"
'{"computerName": "dummy-vm"}' | Set-Content -LiteralPath $incompleteSettings -Encoding UTF8
try {
    Assert-ThrowsMatching -Action {
        Test-Mt5VmSettings -Path $incompleteSettings
    } -Pattern "userName" -Message "VM設定必須項目欠落: 不足フィールド名(userName)を含む例外になること"
    Write-Host "PASS VM設定必須項目欠落"
} finally {
    Remove-Item -LiteralPath $incompleteSettings -Force -ErrorAction SilentlyContinue
}

# --- connectionType省略時はVmrunが既定となり、vmxPath欠落が検出されること ---
$vmrunMissingVmxSettings = Join-Path $env:TEMP "mt5-exec-backend-test-vmrun-missing-vmx.json"
@{
    userName           = "dummy-user"
    credentialSource   = "Prompt"
    vmExecutablePath   = "C:\dummy\terminal64.exe"
    vmSharedConfigPath = "C:\dummy\config"
} | ConvertTo-Json | Set-Content -LiteralPath $vmrunMissingVmxSettings -Encoding UTF8
try {
    Assert-ThrowsMatching -Action {
        Test-Mt5VmSettings -Path $vmrunMissingVmxSettings
    } -Pattern "vmxPath" -Message "Vmrun既定時: vmxPath欠落を検出すること"
    Write-Host "PASS Vmrun既定時のvmxPath必須チェック"
} finally {
    Remove-Item -LiteralPath $vmrunMissingVmxSettings -Force -ErrorAction SilentlyContinue
}

# --- connectionType=WinRm指定時はcomputerName欠落が検出されること（vmxPathは不要） ---
$winrmMissingComputerNameSettings = Join-Path $env:TEMP "mt5-exec-backend-test-winrm-missing-computername.json"
@{
    connectionType     = "WinRm"
    userName           = "dummy-user"
    credentialSource   = "Prompt"
    vmExecutablePath   = "C:\dummy\terminal64.exe"
    vmSharedConfigPath = "C:\dummy\config"
} | ConvertTo-Json | Set-Content -LiteralPath $winrmMissingComputerNameSettings -Encoding UTF8
try {
    Assert-ThrowsMatching -Action {
        Test-Mt5VmSettings -Path $winrmMissingComputerNameSettings
    } -Pattern "computerName" -Message "WinRm指定時: computerName欠落を検出すること"
    Write-Host "PASS WinRm指定時のcomputerName必須チェック"
} finally {
    Remove-Item -LiteralPath $winrmMissingComputerNameSettings -Force -ErrorAction SilentlyContinue
}

# --- connectionTypeに不正な値を指定した場合、明確な例外になること ---
$invalidConnectionTypeSettings = Join-Path $env:TEMP "mt5-exec-backend-test-invalid-connectiontype.json"
@{
    connectionType     = "Hyperv"
    userName           = "dummy-user"
    credentialSource   = "Prompt"
    vmExecutablePath   = "C:\dummy\terminal64.exe"
    vmSharedConfigPath = "C:\dummy\config"
} | ConvertTo-Json | Set-Content -LiteralPath $invalidConnectionTypeSettings -Encoding UTF8
try {
    Assert-ThrowsMatching -Action {
        Test-Mt5VmSettings -Path $invalidConnectionTypeSettings
    } -Pattern "connectionType" -Message "不正なconnectionType: 明確な例外になること"
    Write-Host "PASS 不正connectionTypeチェック"
} finally {
    Remove-Item -LiteralPath $invalidConnectionTypeSettings -Force -ErrorAction SilentlyContinue
}

# --- Vmrun設定として必須項目が揃っていれば例外にならないこと ---
$vmrunCompleteSettings = Join-Path $env:TEMP "mt5-exec-backend-test-vmrun-complete.json"
@{
    connectionType     = "Vmrun"
    vmxPath            = "C:\VMs\Mt5Vm\Mt5Vm.vmx"
    userName           = "dummy-user"
    credentialSource   = "Prompt"
    vmExecutablePath   = "C:\dummy\terminal64.exe"
    vmSharedConfigPath = "C:\dummy\config"
} | ConvertTo-Json | Set-Content -LiteralPath $vmrunCompleteSettings -Encoding UTF8
try {
    $validated = Test-Mt5VmSettings -Path $vmrunCompleteSettings
    Assert-True ($validated.connectionType -eq "Vmrun") "Vmrun必須項目充足: connectionTypeがVmrunであること"
    Write-Host "PASS Vmrun必須項目充足チェック"
} finally {
    Remove-Item -LiteralPath $vmrunCompleteSettings -Force -ErrorAction SilentlyContinue
}

# --- vmEncrypted=trueの場合、encryptionCredentialSource欠落が検出されること ---
$vmEncryptedMissingSourceSettings = Join-Path $env:TEMP "mt5-exec-backend-test-vmencrypted-missing-source.json"
@{
    connectionType     = "Vmrun"
    vmxPath            = "C:\VMs\Mt5Vm\Mt5Vm.vmx"
    vmEncrypted        = $true
    userName           = "dummy-user"
    credentialSource   = "Prompt"
    vmExecutablePath   = "C:\dummy\terminal64.exe"
    vmSharedConfigPath = "C:\dummy\config"
} | ConvertTo-Json | Set-Content -LiteralPath $vmEncryptedMissingSourceSettings -Encoding UTF8
try {
    Assert-ThrowsMatching -Action {
        Test-Mt5VmSettings -Path $vmEncryptedMissingSourceSettings
    } -Pattern "encryptionCredentialSource" -Message "vmEncrypted=true: encryptionCredentialSource欠落を検出すること"
    Write-Host "PASS vmEncrypted時のencryptionCredentialSource必須チェック"
} finally {
    Remove-Item -LiteralPath $vmEncryptedMissingSourceSettings -Force -ErrorAction SilentlyContinue
}

# --- vmEncrypted=true かつ encryptionCredentialSource=EnvironmentVariableの場合、encryptionCredentialEnvVarName必須 ---
$vmEncryptedMissingEnvVarSettings = Join-Path $env:TEMP "mt5-exec-backend-test-vmencrypted-missing-envvar.json"
@{
    connectionType           = "Vmrun"
    vmxPath                  = "C:\VMs\Mt5Vm\Mt5Vm.vmx"
    vmEncrypted              = $true
    encryptionCredentialSource = "EnvironmentVariable"
    userName                 = "dummy-user"
    credentialSource         = "Prompt"
    vmExecutablePath         = "C:\dummy\terminal64.exe"
    vmSharedConfigPath       = "C:\dummy\config"
} | ConvertTo-Json | Set-Content -LiteralPath $vmEncryptedMissingEnvVarSettings -Encoding UTF8
try {
    Assert-ThrowsMatching -Action {
        Test-Mt5VmSettings -Path $vmEncryptedMissingEnvVarSettings
    } -Pattern "encryptionCredentialEnvVarName" -Message "vmEncrypted=true かつ EnvironmentVariable: encryptionCredentialEnvVarName欠落を検出すること"
    Write-Host "PASS vmEncrypted時のencryptionCredentialEnvVarName必須チェック"
} finally {
    Remove-Item -LiteralPath $vmEncryptedMissingEnvVarSettings -Force -ErrorAction SilentlyContinue
}

# --- vmEncrypted=true でも必須項目が揃っていれば例外にならないこと ---
$vmEncryptedCompleteSettings = Join-Path $env:TEMP "mt5-exec-backend-test-vmencrypted-complete.json"
@{
    connectionType             = "Vmrun"
    vmxPath                    = "C:\VMs\Mt5Vm\Mt5Vm.vmx"
    vmEncrypted                = $true
    encryptionCredentialSource = "EnvironmentVariable"
    encryptionCredentialEnvVarName = "MT5_VM_ENCRYPTION_PASSWORD_TEST"
    userName                   = "dummy-user"
    credentialSource           = "Prompt"
    vmExecutablePath           = "C:\dummy\terminal64.exe"
    vmSharedConfigPath         = "C:\dummy\config"
} | ConvertTo-Json | Set-Content -LiteralPath $vmEncryptedCompleteSettings -Encoding UTF8
try {
    $validated = Test-Mt5VmSettings -Path $vmEncryptedCompleteSettings
    Assert-True ($validated.vmEncrypted -eq $true) "vmEncrypted必須項目充足: vmEncryptedがtrueであること"
    Write-Host "PASS vmEncrypted必須項目充足チェック"
} finally {
    Remove-Item -LiteralPath $vmEncryptedCompleteSettings -Force -ErrorAction SilentlyContinue
}

# --- credentialSourceがEnvironmentVariableの場合、credentialEnvVarName必須 ---
$missingEnvVarSettings = Join-Path $env:TEMP "mt5-exec-backend-test-missing-envvar-vm-settings.json"
@{
    connectionType     = "WinRm"
    computerName       = "dummy-vm"
    userName           = "dummy-user"
    credentialSource   = "EnvironmentVariable"
    vmExecutablePath   = "C:\dummy\terminal64.exe"
    vmSharedConfigPath = "C:\dummy\config"
} | ConvertTo-Json | Set-Content -LiteralPath $missingEnvVarSettings -Encoding UTF8
try {
    Assert-ThrowsMatching -Action {
        Test-Mt5VmSettings -Path $missingEnvVarSettings
    } -Pattern "credentialEnvVarName" -Message "credentialEnvVarName欠落: 明確な例外になること"
    Write-Host "PASS credentialEnvVarName必須チェック"
} finally {
    Remove-Item -LiteralPath $missingEnvVarSettings -Force -ErrorAction SilentlyContinue
}

# --- Host実行時はVM設定ファイル未存在でもエラーにならないこと（VmSettingsPathは無視される） ---
# タスクスケジューラの権限有無に関わらず実行できるHostUseIsolatedSession=falseで検証する。
$resultHostNoVm = Invoke-Mt5Execution -ExecutionMode Host -ExecutablePath $cmdExe -ExecutableArguments @("/c", "exit", "0") `
    -TimeoutSeconds 10 -VmSettingsPath (Join-Path $env:TEMP "not-exist-mt5-vm-settings.json") -HostUseIsolatedSession $false
Assert-True ($resultHostNoVm.Success -eq $true) "Host実行時のVmSettingsPath無視: 正常終了すること"
Write-Host "PASS Host実行時VmSettingsPath無視"

# --- Get-Mt5VmCommonAuditPath: vmCommonDataPath未設定時はvmTerminalDataの兄弟Commonフォルダを既定値とすること ---
$derivedSettings = [PSCustomObject]@{ vmTerminalData = "C:\Users\mt5runner\AppData\Roaming\MetaQuotes\Terminal\REPLACE_ID" }
$derivedPath = Get-Mt5VmCommonAuditPath -Settings $derivedSettings -AuditLogDirectory "EaTradingSystem\Audit"
Assert-True ($derivedPath -eq "C:\Users\mt5runner\AppData\Roaming\MetaQuotes\Terminal\Common\Files\EaTradingSystem\Audit") `
    "Get-Mt5VmCommonAuditPath: vmTerminalDataから兄弟Commonフォルダを導出できること (実際: $derivedPath)"
Write-Host "PASS Get-Mt5VmCommonAuditPath 既定導出"

# --- Get-Mt5VmCommonAuditPath: vmCommonDataPath明示指定時はそちらを優先すること ---
$overrideSettings = [PSCustomObject]@{
    vmTerminalData  = "C:\Users\mt5runner\AppData\Roaming\MetaQuotes\Terminal\REPLACE_ID"
    vmCommonDataPath = "D:\CustomCommon"
}
$overridePath = Get-Mt5VmCommonAuditPath -Settings $overrideSettings -AuditLogDirectory "EaTradingSystem\Audit"
Assert-True ($overridePath -eq "D:\CustomCommon\Files\EaTradingSystem\Audit") `
    "Get-Mt5VmCommonAuditPath: vmCommonDataPath明示指定時はそちらを使うこと (実際: $overridePath)"
Write-Host "PASS Get-Mt5VmCommonAuditPath 明示指定優先"

# --- Get-Mt5VmCommonAuditPath: どちらの設定も無ければ$nullを返すこと（ベストエフォートでスキップできるように） ---
$noPathSettings = [PSCustomObject]@{ userName = "dummy-user" }
$noPath = Get-Mt5VmCommonAuditPath -Settings $noPathSettings -AuditLogDirectory "EaTradingSystem\Audit"
Assert-True ($null -eq $noPath) "Get-Mt5VmCommonAuditPath: 設定が無ければnullを返すこと"
Write-Host "PASS Get-Mt5VmCommonAuditPath 設定なし"

Write-Host "MT5_EXECUTION_BACKEND_TEST_PASS"
Write-Host "NOTE: 実VMへのVmrun接続・実行・ファイル同期の成功系は本テストでは検証していません（run-mql5-tests.ps1/run-strategy-tester.ps1を-ExecutionMode VMで実際のVMに対して実行することで別途確認する。2026-09-06に実機確認済み、DECISIONS.md DEC-029参照）。WinRM/PSRemoting接続は未検証。"
