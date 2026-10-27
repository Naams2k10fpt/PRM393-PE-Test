param([Parameter(Mandatory = $true)][string]$ConfigPath)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskConfig = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
if ($taskConfig.type -eq 'service_account') {
    throw 'Use Android client google-services.json. Service-account keys are not supported.'
}
$taskClient = @($taskConfig.client | Where-Object {
    $_.client_info.android_client_info.package_name -eq 'com.prm393.bookshelf'
})
if ($taskClient.Count -ne 1) {
    throw 'The configuration must contain Android package com.prm393.bookshelf.'
}
$taskApiKey = $taskClient[0].api_key[0].current_key
$taskAppId = $taskClient[0].client_info.mobilesdk_app_id
$taskProject = $taskConfig.project_info.project_id
$taskSender = $taskConfig.project_info.project_number
$taskBucket = $taskConfig.project_info.storage_bucket
if (!$taskApiKey -or !$taskAppId -or !$taskProject -or !$taskSender) {
    throw 'The Android client configuration is incomplete.'
}
function ConvertTo-DartString([string]$Value) {
    return "'" + $Value.Replace('\', '\\').Replace("'", "\'").Replace('$', '\$') + "'"
}
$taskSource = @"
import 'package:firebase_core/firebase_core.dart';

// Firebase Android CLIENT configuration. No admin credentials.
class DefaultFirebaseOptions {
  static const currentPlatform = FirebaseOptions(
    apiKey: $(ConvertTo-DartString $taskApiKey),
    appId: $(ConvertTo-DartString $taskAppId),
    messagingSenderId: $(ConvertTo-DartString $taskSender),
    projectId: $(ConvertTo-DartString $taskProject),
    storageBucket: $(ConvertTo-DartString $taskBucket),
  );
  static bool get isConfigured => true;
}
"@
[IO.File]::WriteAllText((Join-Path $taskRoot 'lib\firebase_options.dart'), $taskSource, [Text.UTF8Encoding]::new($false))
$taskDestination = Join-Path $taskRoot 'android\app\google-services.json'
if ([IO.Path]::GetFullPath($ConfigPath) -ne [IO.Path]::GetFullPath($taskDestination)) {
    Copy-Item -LiteralPath $ConfigPath -Destination $taskDestination -Force
}
$taskAlias = @{ projects = @{ default = $taskProject } } | ConvertTo-Json
[IO.File]::WriteAllText((Join-Path $taskRoot '.firebaserc'), $taskAlias, [Text.UTF8Encoding]::new($false))
Write-Output "Configured Firebase project: $taskProject"
Write-Output 'The app initializes Firebase explicitly from firebase_options.dart.'
