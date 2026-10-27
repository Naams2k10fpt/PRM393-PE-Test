param(
    [Parameter(Mandatory = $true)][string]$ConfigPath,
    [string]$WebConfigPath
)
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
if (!$WebConfigPath) { $WebConfigPath = Join-Path $taskRoot 'firebase.web.json' }
$taskWeb = [pscustomobject]@{
    apiKey = ''; appId = ''; messagingSenderId = '';
    projectId = ''; storageBucket = ''; authDomain = ''
}
if (Test-Path -LiteralPath $WebConfigPath) {
    $taskWeb = Get-Content -Raw -LiteralPath $WebConfigPath | ConvertFrom-Json
    if ($taskWeb.projectId -ne $taskProject) {
        throw 'The Android and Web Firebase configurations must use the same project.'
    }
    if (!$taskWeb.apiKey -or !$taskWeb.appId -or !$taskWeb.messagingSenderId) {
        throw 'The Web client configuration is incomplete.'
    }
}
$taskSource = @"
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Firebase CLIENT configurations only. No admin credentials.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => kIsWeb ? web : android;

  static const android = FirebaseOptions(
    apiKey: $(ConvertTo-DartString $taskApiKey),
    appId: $(ConvertTo-DartString $taskAppId),
    messagingSenderId: $(ConvertTo-DartString $taskSender),
    projectId: $(ConvertTo-DartString $taskProject),
    storageBucket: $(ConvertTo-DartString $taskBucket),
  );
  static const web = FirebaseOptions(
    apiKey: $(ConvertTo-DartString $taskWeb.apiKey),
    appId: $(ConvertTo-DartString $taskWeb.appId),
    messagingSenderId: $(ConvertTo-DartString $taskWeb.messagingSenderId),
    projectId: $(ConvertTo-DartString $taskWeb.projectId),
    storageBucket: $(ConvertTo-DartString $taskWeb.storageBucket),
    authDomain: $(ConvertTo-DartString $taskWeb.authDomain),
  );

  static bool get isConfigured => currentPlatform.apiKey.isNotEmpty &&
      currentPlatform.appId.isNotEmpty && currentPlatform.projectId.isNotEmpty;
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
Write-Output 'The app initializes Firebase with the configuration for Android or Web.'
