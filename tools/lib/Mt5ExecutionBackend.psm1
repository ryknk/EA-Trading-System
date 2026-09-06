# MT5実行（Strategy Tester・MQL5単体テスト共通）のHost/VM実行バックエンド。
#
# 呼び出し側（run-strategy-tester.ps1 / run-mql5-tests.ps1）は、MT5の起動・待機・
# タイムアウト検出・終了コード取得・VM実行時の結果ファイル同期だけをこのモジュールへ委譲し、
# report/audit検索やCaseFile処理、PASSマーカー判定などの業務ロジックは呼び出し側が保持する。
#
# ExecutionMode:
#   Host - 従来どおりホストWindows上でterminal64.exeをStart-Processで直接起動する。
#   VM   - VM上のterminal64.exeを起動する。接続方式はVM設定ファイルのconnectionTypeで選択する
#          （Vmrun: VMware Workstation/Player付属vmrun、既定。WinRm: 汎用WinRM/PSRemoting）。
#
# VM接続設定は tools/config/mt5-vm.settings.json（.gitignore対象、実体は各環境で用意）を使用する。
# テンプレートは tools/config/mt5-vm.settings.example.json を参照。

Set-StrictMode -Version Latest

function Test-Mt5VmSettings {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "VM設定ファイルが見つかりません: $Path (ExecutionMode=VMを使用する場合は tools/config/mt5-vm.settings.example.json をコピーして作成してください)"
    }
    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    try {
        $settings = $raw | ConvertFrom-Json
    } catch {
        throw "VM設定ファイルのJSON解析に失敗しました: $Path ($($_.Exception.Message))"
    }

    $connectionType = "Vmrun"
    if (($settings.PSObject.Properties.Name -contains "connectionType") -and -not [string]::IsNullOrWhiteSpace([string]$settings.connectionType)) {
        $connectionType = [string]$settings.connectionType
    }
    if (@("Vmrun", "WinRm") -notcontains $connectionType) {
        throw "VM設定ファイルのconnectionTypeが不正です: $connectionType (Vmrun または WinRm を指定してください、設定ファイル: $Path)"
    }
    # 既定値を明示化して以降の処理へ渡す（設定ファイル側でconnectionType省略時はVmrun扱いにする）。
    if ($settings.PSObject.Properties.Name -contains "connectionType") {
        $settings.connectionType = $connectionType
    } else {
        $settings | Add-Member -NotePropertyName "connectionType" -NotePropertyValue $connectionType
    }

    $missing = @()
    $commonRequired = @("userName", "credentialSource", "vmExecutablePath", "vmSharedConfigPath")
    foreach ($field in $commonRequired) {
        if (-not ($settings.PSObject.Properties.Name -contains $field) -or [string]::IsNullOrWhiteSpace([string]$settings.$field)) {
            $missing += $field
        }
    }
    if ($connectionType -eq "Vmrun") {
        if (-not ($settings.PSObject.Properties.Name -contains "vmxPath") -or [string]::IsNullOrWhiteSpace([string]$settings.vmxPath)) {
            $missing += "vmxPath"
        }
    } else {
        if (-not ($settings.PSObject.Properties.Name -contains "computerName") -or [string]::IsNullOrWhiteSpace([string]$settings.computerName)) {
            $missing += "computerName"
        }
    }
    if (($settings.PSObject.Properties.Name -contains "credentialSource") -and $settings.credentialSource -eq "EnvironmentVariable") {
        if (-not ($settings.PSObject.Properties.Name -contains "credentialEnvVarName") -or [string]::IsNullOrWhiteSpace([string]$settings.credentialEnvVarName)) {
            $missing += "credentialEnvVarName"
        }
    }

    # vmEncrypted=true（VMware VM暗号化が有効）の場合、暗号化パスワード（vmrunの-vp）の取得方法が別途必要。
    # ゲストOSログインパスワードとは別物のため、credentialSourceとは独立した設定として扱う。
    $vmEncrypted = ($connectionType -eq "Vmrun") -and ($settings.PSObject.Properties.Name -contains "vmEncrypted") -and [bool]$settings.vmEncrypted
    if ($vmEncrypted) {
        if (-not ($settings.PSObject.Properties.Name -contains "encryptionCredentialSource") -or [string]::IsNullOrWhiteSpace([string]$settings.encryptionCredentialSource)) {
            $missing += "encryptionCredentialSource"
        } elseif (@("Prompt", "EnvironmentVariable") -notcontains $settings.encryptionCredentialSource) {
            throw "VM設定ファイルのencryptionCredentialSourceが不正です: $($settings.encryptionCredentialSource) (Prompt または EnvironmentVariable を指定してください、設定ファイル: $Path)"
        } elseif ($settings.encryptionCredentialSource -eq "EnvironmentVariable") {
            if (-not ($settings.PSObject.Properties.Name -contains "encryptionCredentialEnvVarName") -or [string]::IsNullOrWhiteSpace([string]$settings.encryptionCredentialEnvVarName)) {
                $missing += "encryptionCredentialEnvVarName"
            }
        }
    }

    if ($missing.Count -gt 0) {
        throw "VM設定ファイルに必須項目が不足しています: $($missing -join ', ') (connectionType=$connectionType, vmEncrypted=$vmEncrypted, 設定ファイル: $Path)"
    }
    if (@("Prompt", "EnvironmentVariable") -notcontains $settings.credentialSource) {
        throw "VM設定ファイルのcredentialSourceが不正です: $($settings.credentialSource) (Prompt または EnvironmentVariable を指定してください、設定ファイル: $Path)"
    }

    return $settings
}

# VM側ゲストOS（Vmrun）またはリモートホスト（WinRm）へログインするための資格情報を取得する。
function Get-Mt5VmCredential {
    param([Parameter(Mandatory)]$Settings)

    $target = if ($Settings.connectionType -eq "Vmrun") { $Settings.vmxPath } else { $Settings.computerName }
    switch ($Settings.credentialSource) {
        "Prompt" {
            $cred = Get-Credential -UserName $Settings.userName -Message "MT5 VM ($target) の資格情報を入力してください"
            if (-not $cred) { throw "MT5 VM用の資格情報が入力されませんでした。" }
            return $cred
        }
        "EnvironmentVariable" {
            $varName = $Settings.credentialEnvVarName
            $plain = [Environment]::GetEnvironmentVariable($varName)
            if ([string]::IsNullOrEmpty($plain)) {
                throw "環境変数 $varName にMT5 VM用パスワードが設定されていません。"
            }
            $secure = ConvertTo-SecureString -String $plain -AsPlainText -Force
            return New-Object System.Management.Automation.PSCredential($Settings.userName, $secure)
        }
        default {
            throw "不正なcredentialSourceです: $($Settings.credentialSource)"
        }
    }
}

# VMware VM暗号化パスワード（vmrunの-vp）を取得する。ゲストOSログインパスワードとは別物。
# ユーザー名の概念が無いためGet-Credentialではなく Read-Host -AsSecureString を使う。
function Get-Mt5VmEncryptionPassword {
    param([Parameter(Mandatory)]$Settings)

    switch ($Settings.encryptionCredentialSource) {
        "Prompt" {
            $secure = Read-Host -AsSecureString -Prompt "MT5 VM ($($Settings.vmxPath)) の暗号化パスワードを入力してください"
            if (-not $secure -or $secure.Length -eq 0) { throw "VM暗号化パスワードが入力されませんでした。" }
            return $secure
        }
        "EnvironmentVariable" {
            $varName = $Settings.encryptionCredentialEnvVarName
            $plain = [Environment]::GetEnvironmentVariable($varName)
            if ([string]::IsNullOrEmpty($plain)) {
                throw "環境変数 $varName にVM暗号化パスワードが設定されていません。"
            }
            return (ConvertTo-SecureString -String $plain -AsPlainText -Force)
        }
        default {
            throw "不正なencryptionCredentialSourceです: $($Settings.encryptionCredentialSource)"
        }
    }
}

function Get-SafeStagingName {
    param([Parameter(Mandatory)][string]$Value)
    $slug = ($Value -replace '[^A-Za-z0-9._-]', '_')
    if ([string]::IsNullOrEmpty($slug)) { $slug = "path" }
    return $slug
}

function ConvertFrom-Mt5SecureStringPlain {
    param([Parameter(Mandatory)][System.Security.SecureString]$SecureString)
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

# ホスト上でterminal64.exeを起動し、待機・タイムアウト・終了コード取得を行う。
function Invoke-Mt5ExecutionHost {
    param(
        [Parameter(Mandatory)][string]$ExecutablePath,
        [string[]]$ExecutableArguments = @(),
        [Parameter(Mandatory)][int]$TimeoutSeconds
    )

    if (-not (Test-Path -LiteralPath $ExecutablePath)) { throw "実行ファイルが見つかりません: $ExecutablePath" }

    $process = Start-Process -FilePath $ExecutablePath -ArgumentList $ExecutableArguments -PassThru -WindowStyle Hidden
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        throw "MT5実行がタイムアウトしました（Host, $TimeoutSeconds 秒）: $ExecutablePath"
    }

    return [PSCustomObject]@{
        ExecutionMode = "Host"
        ExitCode      = $process.ExitCode
        Success       = $true
        StagingRoots  = @()
    }
}

# ============================================================
# Vmrun（VMware Workstation/Player付属CLI）バックエンド
# ============================================================
#
# 注意: vmrunの-gp（ゲストパスワード）・-vp（VM暗号化パスワード）オプションはコマンドライン引数として
# 渡す必要があり、実行中は同一ホスト上の他プロセスからプロセスの起動コマンドラインとして一時的に
# 見える可能性がある（vmrun自体の仕様上の制約であり、この実装固有の問題ではない）。ログ・例外メッセージへは
# ConvertTo-Mt5VmrunSafeArgsStringでマスクした文字列のみを出力する。

function Get-Mt5VmrunExecutablePath {
    param([Parameter(Mandatory)]$Settings)
    if (($Settings.PSObject.Properties.Name -contains "vmrunPath") -and -not [string]::IsNullOrWhiteSpace($Settings.vmrunPath)) {
        return $Settings.vmrunPath
    }
    # VMware Workstation 17系以降は64bit専用となり、既定インストール先が
    # 'Program Files'（x86ではない）側になっているため、そちらを優先して探す。
    $programFiles = [Environment]::GetEnvironmentVariable("ProgramFiles")
    if (-not [string]::IsNullOrWhiteSpace($programFiles)) {
        $candidate = Join-Path $programFiles "VMware\VMware Workstation\vmrun.exe"
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    $programFilesX86 = [Environment]::GetEnvironmentVariable("ProgramFiles(x86)")
    if ([string]::IsNullOrWhiteSpace($programFilesX86)) { $programFilesX86 = "C:\Program Files (x86)" }
    return Join-Path $programFilesX86 "VMware\VMware Workstation\vmrun.exe"
}

# Win32のCommandLineToArgvW互換ルールで1引数をエスケープする。
# .NET Coreの ProcessStartInfo.ArgumentList はWindows PowerShell 5.1（.NET Framework、実運用環境）には
# 存在しない（実機検証で判明）ため、Framework/Core双方で確実に動くArguments（単一文字列）方式に統一する。
function ConvertTo-Mt5Win32EscapedArgument {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Argument)
    if ($Argument.Length -gt 0 -and $Argument -notmatch '[\s"]') { return $Argument }
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('"')
    $i = 0
    while ($i -lt $Argument.Length) {
        $backslashCount = 0
        while ($i -lt $Argument.Length -and $Argument[$i] -eq '\') {
            $backslashCount++
            $i++
        }
        if ($i -eq $Argument.Length) {
            [void]$sb.Append('\' * ($backslashCount * 2))
            break
        } elseif ($Argument[$i] -eq '"') {
            [void]$sb.Append('\' * ($backslashCount * 2 + 1))
            [void]$sb.Append('"')
            $i++
        } else {
            [void]$sb.Append('\' * $backslashCount)
            [void]$sb.Append($Argument[$i])
            $i++
        }
    }
    [void]$sb.Append('"')
    return $sb.ToString()
}

function ConvertTo-Mt5Win32CommandLine {
    param([string[]]$Arguments)
    return (($Arguments | ForEach-Object { ConvertTo-Mt5Win32EscapedArgument -Argument $_ }) -join ' ')
}

function ConvertTo-Mt5VmrunSafeArgsString {
    param([string[]]$Arguments)
    $maskAfter = @("-gp", "-vp")
    $masked = for ($i = 0; $i -lt $Arguments.Count; $i++) {
        if ($i -gt 0 -and $maskAfter -contains $Arguments[$i - 1]) { "****" } else { $Arguments[$i] }
    }
    return ($masked -join ' ')
}

# ディレクトリ同期時に除外するトップレベル名（既定はMT5のtickヒストリカルデータ"bases"のみ除外）。
# report/audit生成物には不要かつ数百MB～GBに達し、転送時間の大半を占めるため既定で除外する。
function Get-Mt5VmSyncExcludeNames {
    param([Parameter(Mandatory)]$Settings)
    if (($Settings.PSObject.Properties.Name -contains "vmSyncExcludeNames") -and $Settings.vmSyncExcludeNames) {
        return @($Settings.vmSyncExcludeNames)
    }
    return @("bases")
}

# ディレクトリ同期（Compress-Archive+コピー）のタイムアウト秒数（既定300秒）。
function Get-Mt5VmSyncTimeoutSeconds {
    param([Parameter(Mandatory)]$Settings)
    if (($Settings.PSObject.Properties.Name -contains "vmSyncTimeoutSeconds") -and $Settings.vmSyncTimeoutSeconds) {
        return [int]$Settings.vmSyncTimeoutSeconds
    }
    return 300
}

# vmrun呼び出し共通の認証引数（-gu/-gp、vmEncrypted時は-vpも）を構築する。
function Get-Mt5VmrunAuthArgs {
    param(
        [Parameter(Mandatory)]$Settings,
        [Parameter(Mandatory)][System.Management.Automation.PSCredential]$GuestCredential
    )
    $guestPasswordPlain = ConvertFrom-Mt5SecureStringPlain -SecureString $GuestCredential.Password
    $authArgs = @("-gu", $GuestCredential.UserName, "-gp", $guestPasswordPlain)
    $vmEncrypted = ($Settings.PSObject.Properties.Name -contains "vmEncrypted") -and [bool]$Settings.vmEncrypted
    if ($vmEncrypted) {
        $encryptionSecure = Get-Mt5VmEncryptionPassword -Settings $Settings
        $encryptionPlain = ConvertFrom-Mt5SecureStringPlain -SecureString $encryptionSecure
        $authArgs += @("-vp", $encryptionPlain)
    }
    return $authArgs
}

# vmrun.exeを実行し標準出力を返す。タイムアウト時・非0終了時は例外を投げる（メッセージはパスワードをマスクする）。
function Invoke-VmrunCommand {
    param(
        [Parameter(Mandatory)][string]$VmrunPath,
        [Parameter(Mandatory)][string[]]$Arguments,
        [int]$TimeoutSeconds = 60
    )
    if (-not (Test-Path -LiteralPath $VmrunPath)) { throw "vmrun.exeが見つかりません: $VmrunPath" }
    $safeArgsString = ConvertTo-Mt5VmrunSafeArgsString -Arguments $Arguments

    # PowerShellのStart-Process -RedirectStandardOutput/-RedirectStandardErrorは、引数が長い・複雑な場合に
    # ExitCode取得が不安定になる既知の癖が実機検証で確認されたため、System.Diagnostics.Processを直接使い、
    # BeginOutputReadLine/BeginErrorReadLineによる非同期イベント読み取り（.NET推奨パターン）で回避する。
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $VmrunPath
    $psi.Arguments = ConvertTo-Mt5Win32CommandLine -Arguments $Arguments
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $stdoutBuilder = New-Object System.Text.StringBuilder
    $stderrBuilder = New-Object System.Text.StringBuilder
    $stdoutAction = { if ($null -ne $EventArgs.Data) { $Event.MessageData.AppendLine($EventArgs.Data) | Out-Null } }
    $stderrAction = { if ($null -ne $EventArgs.Data) { $Event.MessageData.AppendLine($EventArgs.Data) | Out-Null } }
    $stdoutSub = $null
    $stderrSub = $null

    try {
        $stdoutSub = Register-ObjectEvent -InputObject $proc -EventName OutputDataReceived -Action $stdoutAction -MessageData $stdoutBuilder
        $stderrSub = Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived -Action $stderrAction -MessageData $stderrBuilder

        $proc.Start() | Out-Null
        $proc.BeginOutputReadLine()
        $proc.BeginErrorReadLine()

        if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
            $proc.Kill()
            throw "vmrunコマンドがタイムアウトしました（$TimeoutSeconds 秒）: vmrun $safeArgsString"
        }
        # 非同期出力読み取りの完了を保証するため引数なしのWaitForExit()も呼ぶ（.NET公式推奨パターン）。
        $proc.WaitForExit()

        $exitCode = $proc.ExitCode
        $stdout = $stdoutBuilder.ToString()
        $stderr = $stderrBuilder.ToString()
        if ($exitCode -ne 0) {
            throw "vmrunコマンドが失敗しました（exit=$exitCode）: vmrun $safeArgsString ($stderr)"
        }
        return $stdout
    } finally {
        if ($stdoutSub) { Unregister-Event -SourceIdentifier $stdoutSub.Name -ErrorAction SilentlyContinue }
        if ($stderrSub) { Unregister-Event -SourceIdentifier $stderrSub.Name -ErrorAction SilentlyContinue }
        $proc.Dispose()
    }
}

# ゲスト内で名前一致するプロセスをlistProcessesInGuest/killProcessInGuestで強制終了する（タイムアウト時の後始末用、ベストエフォート）。
function Stop-Mt5VmrunGuestProcessByName {
    param(
        [Parameter(Mandatory)][string]$VmrunPath,
        [Parameter(Mandatory)][string]$VmxPath,
        [Parameter(Mandatory)][string[]]$AuthArgs,
        [Parameter(Mandatory)][string]$ProcessName
    )
    try {
        $output = Invoke-VmrunCommand -VmrunPath $VmrunPath -Arguments (@("-T", "ws") + $AuthArgs + @("listProcessesInGuest", $VmxPath)) -TimeoutSeconds 30
        foreach ($line in ($output -split "`r?`n")) {
            if ($line -match [regex]::Escape($ProcessName) -and $line -match 'pid=(\d+)') {
                $guestPid = $Matches[1]
                Invoke-VmrunCommand -VmrunPath $VmrunPath -Arguments (@("-T", "ws") + $AuthArgs + @("killProcessInGuest", $VmxPath, $guestPid)) -TimeoutSeconds 30 | Out-Null
            }
        }
    } catch {
        Write-Host "MT5_VMRUN_KILL_GUEST_PROCESS_FAILED processName=$ProcessName error=$($_.Exception.Message)"
    }
}

# ゲスト側ディレクトリ群をCompress-Archiveで圧縮し、copyFileFromGuestToHostでホストへ取得・展開する
# （vmrunにディレクトリ再帰コピーが無いための代替。ゲスト側にPowerShellが必要）。
# ExcludeNamesに指定したトップレベル名（フォルダ・ファイル名）は圧縮対象から除外する
# （MT5のTerminalData直下の"bases"＝tickヒストリカルデータは数百MB～GBに達し、report/audit生成物には
# 不要なため、既定で除外して転送時間を短縮する。実機検証でTerminalData全体761MBのうち709MBがbasesだった）。
function Copy-Mt5VmrunPathsToStaging {
    param(
        [Parameter(Mandatory)][string]$VmrunPath,
        [Parameter(Mandatory)][string]$VmxPath,
        [Parameter(Mandatory)][string[]]$AuthArgs,
        [Parameter(Mandatory)][string[]]$SourcePaths,
        [Parameter(Mandatory)][string]$StagingRoot,
        [string[]]$ExcludeNames = @(),
        [int]$TimeoutSeconds = 300
    )

    New-Item -ItemType Directory -Path $StagingRoot -Force | Out-Null
    $guestPowerShell = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $stagingRoots = @()
    foreach ($sourcePath in $SourcePaths) {
        if ([string]::IsNullOrWhiteSpace($sourcePath)) { continue }
        try {
            # vmrunのcopyFileFromGuestToHostは".."を含む相対パス要素を正しく解決できない（実機で確認済み）ため、
            # 親ディレクトリを事前に解決した正規化済み絶対パスを使う。
            $parentDir = Split-Path -Parent ($sourcePath.TrimEnd('\'))
            $vmZipPath = Join-Path $parentDir ("_mt5-sync-" + [Guid]::NewGuid().ToString("N") + ".zip")
            $excludeList = ($ExcludeNames | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }) -join ','
            $compressCommand = "`$exclude = @($excludeList); `$items = Get-ChildItem -LiteralPath '$($sourcePath.TrimEnd('\'))' -Force | Where-Object { `$exclude -notcontains `$_.Name } | Select-Object -ExpandProperty FullName; if (`$items) { Compress-Archive -Path `$items -DestinationPath '$vmZipPath' -Force } else { Compress-Archive -Path '$($sourcePath.TrimEnd('\'))' -DestinationPath '$vmZipPath' -Force -Update }"
            Invoke-VmrunCommand -VmrunPath $VmrunPath -Arguments (@("-T", "ws") + $AuthArgs + @("runProgramInGuest", $VmxPath, "-activeWindow", $guestPowerShell, "-NoProfile", "-Command", $compressCommand)) -TimeoutSeconds $TimeoutSeconds | Out-Null

            $hostZipPath = Join-Path $StagingRoot ((Get-SafeStagingName $sourcePath) + ".zip")
            Invoke-VmrunCommand -VmrunPath $VmrunPath -Arguments (@("-T", "ws") + $AuthArgs + @("copyFileFromGuestToHost", $VmxPath, $vmZipPath, $hostZipPath)) -TimeoutSeconds $TimeoutSeconds | Out-Null

            $dest = Join-Path $StagingRoot (Get-SafeStagingName $sourcePath)
            if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
            Expand-Archive -LiteralPath $hostZipPath -DestinationPath $dest -Force
            Remove-Item -LiteralPath $hostZipPath -Force -ErrorAction SilentlyContinue
            $stagingRoots += $dest

            try {
                $cleanupCommand = "Remove-Item -LiteralPath '$vmZipPath' -Force -ErrorAction SilentlyContinue"
                Invoke-VmrunCommand -VmrunPath $VmrunPath -Arguments (@("-T", "ws") + $AuthArgs + @("runProgramInGuest", $VmxPath, "-activeWindow", $guestPowerShell, "-NoProfile", "-Command", $cleanupCommand)) -TimeoutSeconds 30 | Out-Null
            } catch { }
        } catch {
            Write-Host "MT5_VM_SYNC_FAILED source=$sourcePath error=$($_.Exception.Message)"
        }
    }
    # 要素数1の配列をreturnするとPowerShellがスカラーへ自動アンラップすることがあるため
    # （呼び出し側の$stagingRoots[0]が文字列の先頭1文字になる不具合が実機で発生）、,演算子で配列を強制する。
    return , $stagingRoots
}

# vmrun経由でVM上のterminal64.exeを起動し、待機・タイムアウト・終了コード取得・結果ファイル同期を行う。
# ゲスト内でPowerShellのStart-Process経由で実行し、ExitCode（またはタイムアウト時は"TIMEOUT"）を
# ファイルへ書き出し、そのファイルをホストへ回収することでvmrun自体がゲストプログラムの終了コードを
# 返さない制約を回避する。cmd.exeを経由すると（引数付き実行時に）vmrun経由では失敗する既知の問題が
# 実機検証で判明したため、ゲスト内の実行はcmd.exeではなくpowershell.exe経由に統一している。
function Invoke-Mt5ExecutionVmrun {
    param(
        [Parameter(Mandatory)]$Settings,
        [Parameter(Mandatory)][System.Management.Automation.PSCredential]$GuestCredential,
        [string]$ConfigFilePath,
        [string[]]$ExecutableArguments = @(),
        [Parameter(Mandatory)][int]$TimeoutSeconds,
        [string[]]$SyncSourcePaths = @(),
        [string]$StagingRoot
    )

    $vmrunPath = Get-Mt5VmrunExecutablePath -Settings $Settings
    $vmxPath = $Settings.vmxPath
    $authArgs = Get-Mt5VmrunAuthArgs -Settings $Settings -GuestCredential $GuestCredential

    try {
        try {
            Invoke-VmrunCommand -VmrunPath $vmrunPath -Arguments (@("-T", "ws") + $authArgs + @("createDirectoryInGuest", $vmxPath, $Settings.vmSharedConfigPath)) -TimeoutSeconds 30 | Out-Null
        } catch {
            # 既存ディレクトリの場合等はエラーになり得るためベストエフォート扱いとする。
        }

        $remoteArgs = $ExecutableArguments
        if (-not [string]::IsNullOrWhiteSpace($ConfigFilePath)) {
            if (-not (Test-Path -LiteralPath $ConfigFilePath)) { throw "Configファイルが見つかりません: $ConfigFilePath" }
            $vmConfigDest = Join-Path $Settings.vmSharedConfigPath (Split-Path -Leaf $ConfigFilePath)
            Invoke-VmrunCommand -VmrunPath $vmrunPath -Arguments (@("-T", "ws") + $authArgs + @("copyFileFromHostToGuest", $vmxPath, $ConfigFilePath, $vmConfigDest)) -TimeoutSeconds 60 | Out-Null
            $remoteArgs = @("/config:$vmConfigDest")
        }

        $vmExitCodeFile = Join-Path $Settings.vmSharedConfigPath ("mt5-exitcode-" + [Guid]::NewGuid().ToString("N") + ".txt")
        $guestPowerShell = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
        $escapedExePath = $Settings.vmExecutablePath -replace "'", "''"
        $escapedExitCodeFile = $vmExitCodeFile -replace "'", "''"
        $psArgList = if ($remoteArgs.Count -gt 0) { ($remoteArgs | ForEach-Object { "'" + ($_ -replace "'", "''") + "'" }) -join ',' } else { "" }
        $timeoutMs = $TimeoutSeconds * 1000
        $psCommand = "`$proc = Start-Process -FilePath '$escapedExePath' -ArgumentList @($psArgList) -PassThru -WindowStyle Hidden; " +
            "if (-not `$proc.WaitForExit($timeoutMs)) { Stop-Process -Id `$proc.Id -Force -ErrorAction SilentlyContinue; 'TIMEOUT' | Set-Content -LiteralPath '$escapedExitCodeFile' } " +
            "else { `$proc.ExitCode | Set-Content -LiteralPath '$escapedExitCodeFile' }"
        $runArgs = @("-T", "ws") + $authArgs + @("runProgramInGuest", $vmxPath, "-activeWindow", $guestPowerShell, "-NoProfile", "-Command", $psCommand)

        $bufferSeconds = 60
        if (($Settings.PSObject.Properties.Name -contains "operationTimeoutBufferSeconds") -and $Settings.operationTimeoutBufferSeconds) {
            $bufferSeconds = [int]$Settings.operationTimeoutBufferSeconds
        }
        try {
            Invoke-VmrunCommand -VmrunPath $vmrunPath -Arguments $runArgs -TimeoutSeconds ($TimeoutSeconds + $bufferSeconds) | Out-Null
        } catch {
            # ゲスト内PowerShell自身のWaitForExitでタイムアウト処理は完結しているため、ここに到達するのは
            # ゲスト内処理がバッファ込みの外側タイムアウトすら超過した異常系。念のためゲストプロセスを後始末する。
            Stop-Mt5VmrunGuestProcessByName -VmrunPath $vmrunPath -VmxPath $vmxPath -AuthArgs $authArgs -ProcessName (Split-Path -Leaf $Settings.vmExecutablePath)
            throw "MT5実行がタイムアウトしました（VM/vmrun, $TimeoutSeconds 秒, $vmxPath）: $($_.Exception.Message)"
        }

        $hostExitCodeFile = Join-Path ([System.IO.Path]::GetTempPath()) ("mt5-exitcode-" + [Guid]::NewGuid().ToString("N") + ".txt")
        $exitCode = $null
        try {
            Invoke-VmrunCommand -VmrunPath $vmrunPath -Arguments (@("-T", "ws") + $authArgs + @("copyFileFromGuestToHost", $vmxPath, $vmExitCodeFile, $hostExitCodeFile)) -TimeoutSeconds 30 | Out-Null
            $exitCodeText = Get-Content -LiteralPath $hostExitCodeFile -Raw -ErrorAction SilentlyContinue
            if ($exitCodeText -and $exitCodeText.Trim() -eq "TIMEOUT") {
                throw "MT5実行がタイムアウトしました（VM/vmrun, $TimeoutSeconds 秒, $vmxPath）"
            }
            if ($exitCodeText -and ($exitCodeText.Trim() -match '^-?\d+$')) { $exitCode = [int]$exitCodeText.Trim() }
        } finally {
            Remove-Item -LiteralPath $hostExitCodeFile -Force -ErrorAction SilentlyContinue
        }
        if ($null -eq $exitCode) { throw "VM側から終了コードを取得できませんでした（$vmExitCodeFile）。" }

        $stagingRoots = @()
        if (-not [string]::IsNullOrWhiteSpace($StagingRoot) -and $SyncSourcePaths.Count -gt 0) {
            $stagingRoots = Copy-Mt5VmrunPathsToStaging -VmrunPath $vmrunPath -VmxPath $vmxPath -AuthArgs $authArgs -SourcePaths $SyncSourcePaths -StagingRoot $StagingRoot `
                -ExcludeNames (Get-Mt5VmSyncExcludeNames -Settings $Settings) -TimeoutSeconds (Get-Mt5VmSyncTimeoutSeconds -Settings $Settings)
        }

        return [PSCustomObject]@{
            ExecutionMode = "VM"
            ExitCode      = $exitCode
            Success       = $true
            StagingRoots  = $stagingRoots
        }
    } finally {
        $authArgs = $null
    }
}

# VMの実行を伴わず、指定パス群だけをホスト側StagingRootへ同期する（ログ取得等に使用）。
function Sync-Mt5VmrunPaths {
    param(
        [Parameter(Mandatory)]$Settings,
        [Parameter(Mandatory)][System.Management.Automation.PSCredential]$GuestCredential,
        [Parameter(Mandatory)][string[]]$SourcePaths,
        [Parameter(Mandatory)][string]$StagingRoot
    )
    $vmrunPath = Get-Mt5VmrunExecutablePath -Settings $Settings
    $authArgs = Get-Mt5VmrunAuthArgs -Settings $Settings -GuestCredential $GuestCredential
    try {
        return Copy-Mt5VmrunPathsToStaging -VmrunPath $vmrunPath -VmxPath $Settings.vmxPath -AuthArgs $authArgs -SourcePaths $SourcePaths -StagingRoot $StagingRoot `
            -ExcludeNames (Get-Mt5VmSyncExcludeNames -Settings $Settings) -TimeoutSeconds (Get-Mt5VmSyncTimeoutSeconds -Settings $Settings)
    } finally {
        $authArgs = $null
    }
}

# VM側の指定ファイルの現在の行数を取得する（実行前のログ行数記録に使用）。
function Get-Mt5VmrunRemoteLineCount {
    param(
        [Parameter(Mandatory)]$Settings,
        [Parameter(Mandatory)][System.Management.Automation.PSCredential]$GuestCredential,
        [Parameter(Mandatory)][string]$RemotePath
    )
    $vmrunPath = Get-Mt5VmrunExecutablePath -Settings $Settings
    $authArgs = Get-Mt5VmrunAuthArgs -Settings $Settings -GuestCredential $GuestCredential
    try {
        $countFile = Join-Path $Settings.vmSharedConfigPath ("mt5-linecount-" + [Guid]::NewGuid().ToString("N") + ".txt")
        # if文の出力を直接パイプへ渡すことはできないため $(...) で式全体をサブ式化する。
        $command = "`$(if (Test-Path -LiteralPath '$RemotePath') { (Get-Content -LiteralPath '$RemotePath' -Encoding Unicode).Count } else { 0 }) | Set-Content -LiteralPath '$countFile'"
        $guestPowerShell = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
        Invoke-VmrunCommand -VmrunPath $vmrunPath -Arguments (@("-T", "ws") + $authArgs + @("runProgramInGuest", $Settings.vmxPath, "-activeWindow", $guestPowerShell, "-NoProfile", "-Command", $command)) -TimeoutSeconds 60 | Out-Null

        $hostCountFile = Join-Path ([System.IO.Path]::GetTempPath()) ("mt5-linecount-" + [Guid]::NewGuid().ToString("N") + ".txt")
        try {
            Invoke-VmrunCommand -VmrunPath $vmrunPath -Arguments (@("-T", "ws") + $authArgs + @("copyFileFromGuestToHost", $Settings.vmxPath, $countFile, $hostCountFile)) -TimeoutSeconds 30 | Out-Null
            $text = Get-Content -LiteralPath $hostCountFile -Raw -ErrorAction SilentlyContinue
            if ($text -and ($text.Trim() -match '^\d+$')) { return [int]$text.Trim() }
            return 0
        } finally {
            Remove-Item -LiteralPath $hostCountFile -Force -ErrorAction SilentlyContinue
        }
    } finally {
        $authArgs = $null
    }
}

# ============================================================
# WinRm（汎用WinRM/PSRemoting）バックエンド
# ============================================================

# VM側の指定パス群を、開いているPSSession経由でホスト側StagingRootへコピーする。
function Copy-Mt5VmPathsToStaging {
    param(
        [Parameter(Mandatory)]$Session,
        [Parameter(Mandatory)][string[]]$SourcePaths,
        [Parameter(Mandatory)][string]$StagingRoot
    )

    New-Item -ItemType Directory -Path $StagingRoot -Force | Out-Null
    $stagingRoots = @()
    foreach ($sourcePath in $SourcePaths) {
        if ([string]::IsNullOrWhiteSpace($sourcePath)) { continue }
        $dest = Join-Path $StagingRoot (Get-SafeStagingName $sourcePath)
        try {
            Copy-Item -FromSession $Session -Path $sourcePath -Destination $dest -Recurse -Force -ErrorAction Stop
            $stagingRoots += $dest
        } catch {
            Write-Host "MT5_VM_SYNC_FAILED source=$sourcePath error=$($_.Exception.Message)"
        }
    }
    # 要素数1の配列をreturnするとPowerShellがスカラーへ自動アンラップすることがあるため
    # （呼び出し側の$stagingRoots[0]が文字列の先頭1文字になる不具合が実機で発生）、,演算子で配列を強制する。
    return , $stagingRoots
}

# VM設定に基づきPSSessionを確立する。呼び出し側はfinallyでRemove-PSSessionすること。
function New-Mt5VmSession {
    param([Parameter(Mandatory)]$Settings, [Parameter(Mandatory)][int]$TimeoutSeconds)

    $credential = Get-Mt5VmCredential -Settings $Settings
    $bufferSeconds = 60
    if (($Settings.PSObject.Properties.Name -contains "operationTimeoutBufferSeconds") -and $Settings.operationTimeoutBufferSeconds) {
        $bufferSeconds = [int]$Settings.operationTimeoutBufferSeconds
    }
    $sessionOption = New-PSSessionOption -OperationTimeout (($TimeoutSeconds + $bufferSeconds) * 1000)
    try {
        return New-PSSession -ComputerName $Settings.computerName -Credential $credential -SessionOption $sessionOption -ErrorAction Stop
    } catch {
        throw "MT5 VM ($($Settings.computerName)) へのPSRemoting接続に失敗しました: $($_.Exception.Message)"
    }
}

# WinRM/PSRemoting経由でVM上のterminal64.exeを起動し、待機・タイムアウト・終了コード取得・
# 結果ファイル同期を行う。
function Invoke-Mt5ExecutionVmWinRm {
    param(
        [Parameter(Mandatory)]$Settings,
        [string]$ConfigFilePath,
        [string[]]$ExecutableArguments = @(),
        [Parameter(Mandatory)][int]$TimeoutSeconds,
        [string[]]$SyncSourcePaths = @(),
        [string]$StagingRoot
    )

    $session = New-Mt5VmSession -Settings $Settings -TimeoutSeconds $TimeoutSeconds

    try {
        $remoteArgs = $ExecutableArguments
        if (-not [string]::IsNullOrWhiteSpace($ConfigFilePath)) {
            if (-not (Test-Path -LiteralPath $ConfigFilePath)) { throw "Configファイルが見つかりません: $ConfigFilePath" }
            Invoke-Command -Session $session -ArgumentList $Settings.vmSharedConfigPath -ScriptBlock {
                param($Dir)
                if (-not (Test-Path -LiteralPath $Dir)) { New-Item -ItemType Directory -Path $Dir -Force | Out-Null }
            }
            $vmConfigDest = Join-Path $Settings.vmSharedConfigPath (Split-Path -Leaf $ConfigFilePath)
            Copy-Item -ToSession $session -Path $ConfigFilePath -Destination $vmConfigDest -Force
            $remoteArgs = @("/config:$vmConfigDest")
        }

        $remoteResult = Invoke-Command -Session $session -ArgumentList $Settings.vmExecutablePath, $remoteArgs, $TimeoutSeconds -ScriptBlock {
            param($ExePath, $Args, $TimeoutSec)
            if (-not (Test-Path -LiteralPath $ExePath)) { throw "VM側に実行ファイルが見つかりません: $ExePath" }
            $proc = Start-Process -FilePath $ExePath -ArgumentList $Args -PassThru -WindowStyle Hidden
            $exited = $proc.WaitForExit($TimeoutSec * 1000)
            if (-not $exited) {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
                return [PSCustomObject]@{ TimedOut = $true; ExitCode = $null }
            }
            return [PSCustomObject]@{ TimedOut = $false; ExitCode = $proc.ExitCode }
        }

        if ($remoteResult.TimedOut) {
            throw "MT5実行がタイムアウトしました（VM/WinRm, $TimeoutSeconds 秒, $($Settings.computerName)）"
        }

        $stagingRoots = @()
        if (-not [string]::IsNullOrWhiteSpace($StagingRoot) -and $SyncSourcePaths.Count -gt 0) {
            $stagingRoots = Copy-Mt5VmPathsToStaging -Session $session -SourcePaths $SyncSourcePaths -StagingRoot $StagingRoot
        }

        return [PSCustomObject]@{
            ExecutionMode = "VM"
            ExitCode      = $remoteResult.ExitCode
            Success       = $true
            StagingRoots  = $stagingRoots
        }
    } finally {
        if ($session) { Remove-PSSession -Session $session -ErrorAction SilentlyContinue }
    }
}

# ============================================================
# 共通ディスパッチャ
# ============================================================

# VM設定のconnectionTypeにより Vmrun/WinRm へ振り分ける。VM設定不備時はHostへフォールバックせず例外を投げる。
function Invoke-Mt5ExecutionVm {
    param(
        [Parameter(Mandatory)][string]$VmSettingsPath,
        [string]$ConfigFilePath,
        [string[]]$ExecutableArguments = @(),
        [Parameter(Mandatory)][int]$TimeoutSeconds,
        [string[]]$SyncSourcePaths = @(),
        [string]$StagingRoot
    )

    $settings = Test-Mt5VmSettings -Path $VmSettingsPath
    if ($settings.connectionType -eq "Vmrun") {
        $credential = Get-Mt5VmCredential -Settings $settings
        return Invoke-Mt5ExecutionVmrun -Settings $settings -GuestCredential $credential -ConfigFilePath $ConfigFilePath `
            -ExecutableArguments $ExecutableArguments -TimeoutSeconds $TimeoutSeconds `
            -SyncSourcePaths $SyncSourcePaths -StagingRoot $StagingRoot
    }
    return Invoke-Mt5ExecutionVmWinRm -Settings $settings -ConfigFilePath $ConfigFilePath `
        -ExecutableArguments $ExecutableArguments -TimeoutSeconds $TimeoutSeconds `
        -SyncSourcePaths $SyncSourcePaths -StagingRoot $StagingRoot
}

# VMの実行を伴わず、指定パス群だけをホスト側StagingRootへ同期する（ログ取得等に使用）。
function Sync-Mt5VmPaths {
    param(
        [Parameter(Mandatory)][string]$VmSettingsPath,
        [Parameter(Mandatory)][string[]]$SourcePaths,
        [Parameter(Mandatory)][string]$StagingRoot
    )

    $settings = Test-Mt5VmSettings -Path $VmSettingsPath
    if ($settings.connectionType -eq "Vmrun") {
        $credential = Get-Mt5VmCredential -Settings $settings
        return Sync-Mt5VmrunPaths -Settings $settings -GuestCredential $credential -SourcePaths $SourcePaths -StagingRoot $StagingRoot
    }
    $session = New-Mt5VmSession -Settings $settings -TimeoutSeconds 60
    try {
        return Copy-Mt5VmPathsToStaging -Session $session -SourcePaths $SourcePaths -StagingRoot $StagingRoot
    } finally {
        if ($session) { Remove-PSSession -Session $session -ErrorAction SilentlyContinue }
    }
}

# VM側の指定ファイルの現在の行数を取得する（実行前のログ行数記録に使用）。
function Get-Mt5VmRemoteLineCount {
    param(
        [Parameter(Mandatory)][string]$VmSettingsPath,
        [Parameter(Mandatory)][string]$RemotePath
    )

    $settings = Test-Mt5VmSettings -Path $VmSettingsPath
    if ($settings.connectionType -eq "Vmrun") {
        $credential = Get-Mt5VmCredential -Settings $settings
        return Get-Mt5VmrunRemoteLineCount -Settings $settings -GuestCredential $credential -RemotePath $RemotePath
    }
    $session = New-Mt5VmSession -Settings $settings -TimeoutSeconds 60
    try {
        return Invoke-Command -Session $session -ArgumentList $RemotePath -ScriptBlock {
            param($Path)
            if (Test-Path -LiteralPath $Path) { @(Get-Content -LiteralPath $Path -Encoding Unicode).Count } else { 0 }
        }
    } finally {
        if ($session) { Remove-PSSession -Session $session -ErrorAction SilentlyContinue }
    }
}

# 共通エントリポイント。ExecutionModeにより Host/VM のMT5実行へ振り分ける。
# ConfigFilePathを指定すると "/config:<パス>" 引数を自動生成する（Host/VM共通、VMは転送後のVM側パスを使用）。
# ConfigFilePathを指定しない場合はExecutableArgumentsをそのまま使用する（汎用実行・テスト用）。
function Invoke-Mt5Execution {
    param(
        [ValidateSet("Host", "VM")][string]$ExecutionMode = "Host",
        [string]$ExecutablePath,
        [string]$ConfigFilePath,
        [string[]]$ExecutableArguments = @(),
        [Parameter(Mandatory)][int]$TimeoutSeconds,
        [string]$VmSettingsPath,
        [string[]]$SyncSourcePaths = @(),
        [string]$StagingRoot
    )

    if ($ExecutionMode -eq "Host") {
        if ([string]::IsNullOrWhiteSpace($ExecutablePath)) { throw "ExecutionMode=Hostの場合はExecutablePathが必須です。" }
        $args = if (-not [string]::IsNullOrWhiteSpace($ConfigFilePath)) { @("/config:$ConfigFilePath") } else { $ExecutableArguments }
        return Invoke-Mt5ExecutionHost -ExecutablePath $ExecutablePath -ExecutableArguments $args -TimeoutSeconds $TimeoutSeconds
    }

    if ([string]::IsNullOrWhiteSpace($VmSettingsPath)) { throw "ExecutionMode=VMの場合はVmSettingsPathが必須です。" }
    return Invoke-Mt5ExecutionVm -VmSettingsPath $VmSettingsPath -ConfigFilePath $ConfigFilePath `
        -ExecutableArguments $ExecutableArguments -TimeoutSeconds $TimeoutSeconds `
        -SyncSourcePaths $SyncSourcePaths -StagingRoot $StagingRoot
}

Export-ModuleMember -Function @(
    "Invoke-Mt5Execution",
    "Invoke-Mt5ExecutionHost",
    "Invoke-Mt5ExecutionVm",
    "Invoke-Mt5ExecutionVmrun",
    "Invoke-Mt5ExecutionVmWinRm",
    "Test-Mt5VmSettings",
    "Get-Mt5VmCredential",
    "Get-Mt5VmEncryptionPassword",
    "Sync-Mt5VmPaths",
    "Get-Mt5VmRemoteLineCount"
)
