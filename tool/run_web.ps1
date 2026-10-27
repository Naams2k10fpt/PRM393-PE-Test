param([ValidateRange(1,65535)][int]$Port = 8085)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $taskRoot
try {
    if (!(Test-Path -LiteralPath '.dart_tool\package_config.json')) {
        flutter pub get
        if ($LASTEXITCODE -ne 0) { throw 'Could not restore Flutter dependencies.' }
    }
    Write-Output "Open http://127.0.0.1:$Port in your browser. Press Ctrl+C to stop."
    flutter run -d web-server --web-hostname=127.0.0.1 --web-port=$Port --no-pub
} finally {
    Pop-Location
}
