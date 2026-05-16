[CmdletBinding()]
param(
    [ValidateSet("Status", "Launch", "Stop")]
    [string]$Action = "Status",
    [string]$Package = "net.rpcsx.easy",
    [string]$Serial = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

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
    if (-not [string]::IsNullOrWhiteSpace($Serial)) {
        $args += @("-s", $Serial)
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

function Write-Status {
    Write-Host "Package: $Package"
    Write-Host "PID:"
    Invoke-Adb -AdbArgs @("shell", "pidof", $Package) -AllowFail | Write-Host
    Write-Host ""
    Write-Host "Top activity:"
    Invoke-Adb -AdbArgs @("shell", "dumpsys", "activity", "top") -AllowFail |
        Select-String -Pattern "ACTIVITY|mResumedActivity|topResumedActivity|Hist" |
        Select-Object -First 20 |
        ForEach-Object { Write-Host $_.Line }
}

$script:Adb = Find-Adb

$devices = & $script:Adb devices 2>&1
$authorizedDevices = @($devices | Where-Object { $_ -match "`tdevice$" })
if ([string]::IsNullOrWhiteSpace($Serial) -and $authorizedDevices.Count -ne 1) {
    throw "Expected exactly one authorized adb device or pass -Serial. Found $($authorizedDevices.Count)."
}

switch ($Action) {
    "Launch" {
        Invoke-Adb -AdbArgs @("shell", "monkey", "-p", $Package, "1") | Out-Null
        Start-Sleep -Milliseconds 750
        Write-Status
    }
    "Stop" {
        Invoke-Adb -AdbArgs @("shell", "am", "force-stop", $Package) | Out-Null
        Start-Sleep -Milliseconds 300
        Write-Status
    }
    default {
        Write-Status
    }
}
