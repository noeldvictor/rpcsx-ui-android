[CmdletBinding()]
param(
    [string]$Package = "net.rpcsx.easy",
    [string]$Serial = "",
    [string]$Label = "adb-report",
    [int]$LogcatLines = 0,
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

function Resolve-RepoRoot {
    $candidate = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..")).Path
    if (Test-Path (Join-Path $candidate ".git")) {
        return $candidate
    }

    return (Get-Location).Path
}

function Find-Adb {
    $candidates = @()
    if ($env:ANDROID_HOME) {
        $candidates += (Join-Path $env:ANDROID_HOME "platform-tools\adb.exe")
    }
    if ($env:ANDROID_SDK_ROOT) {
        $candidates += (Join-Path $env:ANDROID_SDK_ROOT "platform-tools\adb.exe")
    }

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            return $candidate
        }
    }

    return "adb"
}

function Invoke-Adb {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$AdbArgs,
        [switch]$AllowFail
    )

    $args = @()
    if (-not [string]::IsNullOrWhiteSpace($script:Serial)) {
        $args += @("-s", $script:Serial)
    }
    $args += $AdbArgs

    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $script:Adb @args 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldErrorActionPreference
    }

    if ($exitCode -ne 0 -and -not $AllowFail) {
        throw "adb $($args -join ' ') failed with exit code $exitCode.`n$output"
    }

    return $output
}

function Write-CommandOutput {
    param(
        [string]$FileName,
        [string[]]$AdbArgs,
        [switch]$AllowFail
    )

    Invoke-Adb -AdbArgs $AdbArgs -AllowFail:$AllowFail |
        Set-Content -Path (Join-Path $OutputDir $FileName) -Encoding UTF8
}

$script:Adb = Find-Adb
$script:Serial = $Serial
$repoRoot = Resolve-RepoRoot
$safeLabel = ($Label -replace "[^A-Za-z0-9_.-]+", "-").Trim("-")
if ([string]::IsNullOrWhiteSpace($safeLabel)) {
    $safeLabel = "adb-report"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $repoRoot "debug-captures\adb-reports\$timestamp-$safeLabel"
}
else {
    $OutputDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDir)
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$devices = & $script:Adb devices 2>&1
$devices | Set-Content -Path (Join-Path $OutputDir "adb-devices.txt") -Encoding UTF8

$authorizedDevices = @($devices | Where-Object { $_ -match "`tdevice$" })
if ([string]::IsNullOrWhiteSpace($Serial) -and $authorizedDevices.Count -ne 1) {
    throw "Expected exactly one authorized adb device or pass -Serial. Found $($authorizedDevices.Count)."
}

Write-CommandOutput -FileName "get-state.txt" -AdbArgs @("get-state") -AllowFail
Write-CommandOutput -FileName "serialno.txt" -AdbArgs @("get-serialno") -AllowFail
Write-CommandOutput -FileName "getprop.txt" -AdbArgs @("shell", "getprop") -AllowFail
Write-CommandOutput -FileName "package-pid.txt" -AdbArgs @("shell", "pidof", $Package) -AllowFail
Write-CommandOutput -FileName "package-dumpsys.txt" -AdbArgs @("shell", "dumpsys", "package", $Package) -AllowFail
Write-CommandOutput -FileName "activity-top.txt" -AdbArgs @("shell", "dumpsys", "activity", "top") -AllowFail
Write-CommandOutput -FileName "window-dump.txt" -AdbArgs @("shell", "dumpsys", "window", "windows") -AllowFail
Write-CommandOutput -FileName "meminfo-package.txt" -AdbArgs @("shell", "dumpsys", "meminfo", $Package) -AllowFail

if ($LogcatLines -gt 0) {
    Write-CommandOutput -FileName "logcat-tail.txt" -AdbArgs @("logcat", "-d", "-t", "$LogcatLines") -AllowFail
}

@(
    "# Thor ADB Report",
    "",
    "- started_local: $(Get-Date -Format o)",
    "- package: $Package",
    "- serial: $Serial",
    "- adb: $script:Adb",
    "- logcat_lines: $LogcatLines"
) | Set-Content -Path (Join-Path $OutputDir "run.md") -Encoding UTF8

Write-Host "Thor ADB report complete:"
Write-Host "  OutputDir: $OutputDir"
Write-Host "  Package: $Package"
Write-Host "  LogcatLines: $LogcatLines"
