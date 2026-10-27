param([string]$OutputPath)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
if (!$OutputPath) {
    $taskOutputDirectory = [IO.Path]::GetFullPath((Join-Path $taskRoot '..\submission'))
    [IO.Directory]::CreateDirectory($taskOutputDirectory) | Out-Null
    $OutputPath = Join-Path $taskOutputDirectory 'QE190117.zip'
}
$taskChanges = git -C $taskRoot status --porcelain
if ($LASTEXITCODE -ne 0) { throw 'Run this script inside the Git checkout.' }
if ($taskChanges) { throw 'Commit your source changes before packaging so GitHub and ZIP match.' }
git -C $taskRoot archive --format=zip --output=$OutputPath HEAD
if ($LASTEXITCODE -ne 0) { throw 'Could not create the source ZIP.' }
Write-Output "Source ZIP: $OutputPath"
