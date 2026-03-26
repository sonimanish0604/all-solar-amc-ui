$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")

function Write-RequiredBase64File {
  param(
    [Parameter(Mandatory = $true)]
    [string]$EnvVar,
    [Parameter(Mandatory = $true)]
    [string]$RelativePath
  )

  $value = [Environment]::GetEnvironmentVariable($EnvVar)
  if ([string]::IsNullOrWhiteSpace($value)) {
    throw "Missing required environment variable: $EnvVar"
  }

  $targetPath = Join-Path $repoRoot $RelativePath
  $targetDir = Split-Path -Parent $targetPath
  New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

  $bytes = [Convert]::FromBase64String($value)
  [IO.File]::WriteAllBytes($targetPath, $bytes)
  Write-Host "Wrote $RelativePath"
}

Write-RequiredBase64File -EnvVar "ANDROID_GOOGLE_SERVICES_JSON_B64" -RelativePath "apps/mobile_app/android/app/google-services.json"
Write-RequiredBase64File -EnvVar "IOS_GOOGLE_SERVICE_INFO_PLIST_B64" -RelativePath "apps/mobile_app/ios/Runner/GoogleService-Info.plist"
Write-RequiredBase64File -EnvVar "FIREBASE_OPTIONS_DART_B64" -RelativePath "apps/mobile_app/lib/firebase_options.dart"
Write-RequiredBase64File -EnvVar "FIREBASE_JSON_B64" -RelativePath "apps/mobile_app/firebase.json"
