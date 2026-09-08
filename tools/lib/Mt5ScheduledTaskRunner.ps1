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

$ErrorActionPreference = "Stop"
$requestFilePath = Join-Path $env:TEMP "Mt5ScheduledTaskRequest.json"
$resultFilePath = Join-Path $env:TEMP "Mt5ScheduledTaskResult.json"

try {
    if (-not (Test-Path -LiteralPath $requestFilePath)) {
        throw "リクエストファイルが見つかりません: $requestFilePath"
    }
    $request = Get-Content -LiteralPath $requestFilePath -Raw -Encoding UTF8 | ConvertFrom-Json
    # PowerShellはJSON配列の要素数が0または1の場合にスカラー/$nullへ自動アンラップすることがあるため、
    # 配列であることを明示的に強制する。
    $arguments = @($request.Arguments)

    if ($arguments.Count -gt 0) {
        $process = Start-Process -FilePath $request.ExecutablePath -ArgumentList $arguments -PassThru -Wait -WindowStyle Hidden
    } else {
        $process = Start-Process -FilePath $request.ExecutablePath -PassThru -Wait -WindowStyle Hidden
    }
    [PSCustomObject]@{ ExitCode = $process.ExitCode; Error = $null } | ConvertTo-Json | Set-Content -LiteralPath $resultFilePath -Encoding UTF8
} catch {
    [PSCustomObject]@{ ExitCode = $null; Error = $_.Exception.Message } | ConvertTo-Json | Set-Content -LiteralPath $resultFilePath -Encoding UTF8
}
