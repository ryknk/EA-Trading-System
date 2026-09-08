# Windowsタスクスケジューラ経由で非対話セッション上で実行される、terminal64.exe起動用の
# 固定ランナースクリプト。tools/setup-mt5-scheduled-task.ps1で事前登録したタスクのActionから
# 呼ばれる。タスクのActionは固定（本スクリプトを呼ぶだけ）のため、実行対象の情報（実行ファイル
# パス・引数）はリクエストファイル経由で受け渡す（DECISIONS.md DEC-035参照）。
#
# リクエストファイル（%TEMP%\Mt5ScheduledTaskRequest.json）:
#   { "ExecutablePath": "...", "Arguments": ["...", "..."] }
# 結果ファイル（%TEMP%\Mt5ScheduledTaskResult.json）:
#   成功時: { "ExitCode": 0, "Error": null }
#   失敗時: { "ExitCode": null, "Error": "エラーメッセージ" }
# キャンセルファイル（%TEMP%\Mt5ScheduledTaskCancel.json、呼び出し側がタイムアウト時に作成）:
#   存在を検知したら自身が起動した子プロセスをStop-Processし、Error="Cancelled"で結果を書く。
#   呼び出し側（別ログオンセッション）は子プロセスを直接Stop-Process/taskkillできない
#   （アクセス拒否、実機検証で確認）ため、同一セッション内の本スクリプトが代わりに終了させる
#   （DECISIONS.md DEC-036参照）。

$ErrorActionPreference = "Stop"
$requestFilePath = Join-Path $env:TEMP "Mt5ScheduledTaskRequest.json"
$resultFilePath = Join-Path $env:TEMP "Mt5ScheduledTaskResult.json"
$cancelFilePath = Join-Path $env:TEMP "Mt5ScheduledTaskCancel.json"

Remove-Item -LiteralPath $cancelFilePath -Force -ErrorAction SilentlyContinue

try {
    if (-not (Test-Path -LiteralPath $requestFilePath)) {
        throw "リクエストファイルが見つかりません: $requestFilePath"
    }
    $request = Get-Content -LiteralPath $requestFilePath -Raw -Encoding UTF8 | ConvertFrom-Json
    # PowerShellはJSON配列の要素数が0または1の場合にスカラー/$nullへ自動アンラップすることがあるため、
    # 配列であることを明示的に強制する。
    $arguments = @($request.Arguments)

    # -Waitは指定しない（キャンセルファイルを定期確認しながら待つため、プロセスオブジェクトを
    # 即座に受け取れる非ブロッキング起動にする）。
    if ($arguments.Count -gt 0) {
        $process = Start-Process -FilePath $request.ExecutablePath -ArgumentList $arguments -PassThru -WindowStyle Hidden
    } else {
        $process = Start-Process -FilePath $request.ExecutablePath -PassThru -WindowStyle Hidden
    }

    $cancelled = $false
    while (-not $process.HasExited) {
        if (Test-Path -LiteralPath $cancelFilePath) {
            $cancelled = $true
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            $process.WaitForExit(5000) | Out-Null
            break
        }
        Start-Sleep -Milliseconds 250
    }

    Remove-Item -LiteralPath $cancelFilePath -Force -ErrorAction SilentlyContinue
    if ($cancelled) {
        [PSCustomObject]@{ ExitCode = $null; Error = "Cancelled" } | ConvertTo-Json | Set-Content -LiteralPath $resultFilePath -Encoding UTF8
    } else {
        [PSCustomObject]@{ ExitCode = $process.ExitCode; Error = $null } | ConvertTo-Json | Set-Content -LiteralPath $resultFilePath -Encoding UTF8
    }
} catch {
    [PSCustomObject]@{ ExitCode = $null; Error = $_.Exception.Message } | ConvertTo-Json | Set-Content -LiteralPath $resultFilePath -Encoding UTF8
}
