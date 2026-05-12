param(
    [switch]$StopApp,
    [switch]$LaunchApp
)

$ErrorActionPreference = "Stop"

$adb = Join-Path $env:ANDROID_HOME "platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
    $adb = "adb"
}

$packageName = "net.rpcsx.easy"
$remoteDir = "/storage/emulated/0/Android/data/$packageName/files/config/custom_configs"
$remoteConfig = "$remoteDir/config_BLUS30161.yml"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$remoteBackup = "$remoteDir/config_BLUS30161.pre-thor-spurs4-$timestamp.yml"

$profile = @"
# RPCSX_THOR_SAFE_BOOT_FALLBACK
# Source: local Thor rollback after SPURS 4 black-screen-alive load hang.
# Title ID: BLUS30161
# This intentionally does not use RPCSX_THOR_AUTO_SETTINGS, so the app will not rewrite it.
Core:
  Thread Scheduler Mode: Operating System
  SPU Reservation Busy Waiting Percentage: 0
  Max SPURS Threads: 6
  Accurate SPU Reservations: true
  SPU Verification: true
  Sleep Timers Accuracy: As Host
Video:
  Frame limit: 30
  Accurate ZCULL stats: true
  Relaxed ZCULL Sync: false
  Multithreaded RSX: false
"@

$tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "config_BLUS30161.thor.yml"
[System.IO.File]::WriteAllText(
    $tempFile,
    $profile,
    [System.Text.UTF8Encoding]::new($false)
)

& $adb shell "mkdir -p '$remoteDir'"
& $adb shell "if [ -f '$remoteConfig' ]; then cp '$remoteConfig' '$remoteBackup'; fi"
& $adb push $tempFile $remoteConfig
& $adb shell "chmod 664 '$remoteConfig'"

Remove-Item -LiteralPath $tempFile -Force

if ($StopApp) {
    & $adb shell am force-stop $packageName
}

if ($LaunchApp) {
    & $adb shell am start -n "$packageName/net.rpcsx.MainActivity"
}

"Pushed $remoteConfig"
"Backup: $remoteBackup"
if ($StopApp) {
    "Stopped $packageName so the next boot uses this profile."
}
if ($LaunchApp) {
    "Launched $packageName."
}
