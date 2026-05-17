[CmdletBinding()]
param(
    [string]$Label = "thor-shot",
    [ValidateRange(1, 300)]
    [int]$Count = 1,
    [ValidateRange(0, 60000)]
    [int]$IntervalMs = 250,
    [string]$OutputDir = "",
    [string]$Package = "net.rpcsx.easy",
    [ValidateSet("Pull", "ExecOut")]
    [string]$CaptureMode = "Pull",
    [switch]$KeepRemote,
    [switch]$NoMetadata
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

    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $script:Adb @AdbArgs 2>&1
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $oldErrorActionPreference
    }

    if ($exitCode -ne 0 -and -not $AllowFail) {
        throw "adb $($AdbArgs -join ' ') failed with exit code $exitCode.`n$output"
    }

    return $output
}

function Save-AdbExecOut {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LocalPath
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $script:Adb
    $psi.Arguments = "exec-out screencap -p"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    $fileStream = $null
    try {
        [void]$process.Start()
        $fileStream = [System.IO.File]::Open($LocalPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
        $process.StandardOutput.BaseStream.CopyTo($fileStream)
        $fileStream.Close()
        $fileStream = $null
        $stderr = $process.StandardError.ReadToEnd()
        $process.WaitForExit()

        if ($process.ExitCode -ne 0) {
            throw "adb exec-out screencap -p failed with exit code $($process.ExitCode).`n$stderr"
        }
    }
    finally {
        if ($fileStream) {
            $fileStream.Dispose()
        }
        if ($process) {
            $process.Dispose()
        }
    }
}

$script:Adb = Find-Adb
$repoRoot = Resolve-RepoRoot
$safeLabel = ($Label -replace "[^A-Za-z0-9_.-]+", "-").Trim("-")
if ([string]::IsNullOrWhiteSpace($safeLabel)) {
    $safeLabel = "thor-shot"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $repoRoot "debug-captures\thor-screenshots\$timestamp-$safeLabel"
}
else {
    $OutputDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDir)
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$devices = Invoke-Adb -AdbArgs @("devices")
$authorizedDevices = @($devices | Where-Object { $_ -match "`tdevice$" })
if ($authorizedDevices.Count -lt 1) {
    throw "No authorized adb device found. Unlock Thor, accept USB debugging, then run adb devices."
}

$remoteDir = "/sdcard/Download/codex-thor-screenshot-burst/$timestamp-$safeLabel"
Invoke-Adb -AdbArgs @("shell", "mkdir", "-p", $remoteDir) | Out-Null

if (-not $NoMetadata) {
    $runPath = Join-Path $OutputDir "run.md"
    $runLines = @(
        "# Thor Screenshot Burst",
        "",
        "- label: $Label",
        "- started_local: $(Get-Date -Format o)",
        "- count: $Count",
        "- interval_ms: $IntervalMs",
        "- capture_mode: $CaptureMode",
        "- package: $Package",
        "- adb: $script:Adb",
        "- remote_temp: $remoteDir",
        "- keep_remote: $($KeepRemote.IsPresent)"
    )
    $runLines | Set-Content -Path $runPath -Encoding UTF8

    $devices | Set-Content -Path (Join-Path $OutputDir "adb-devices.txt") -Encoding UTF8
    Invoke-Adb -AdbArgs @("shell", "getprop") -AllowFail |
        Set-Content -Path (Join-Path $OutputDir "android-getprop.txt") -Encoding UTF8
    Invoke-Adb -AdbArgs @("shell", "pidof", $Package) -AllowFail |
        Set-Content -Path (Join-Path $OutputDir "package-pid.txt") -Encoding UTF8
    Invoke-Adb -AdbArgs @("shell", "dumpsys", "activity", "top") -AllowFail |
        Set-Content -Path (Join-Path $OutputDir "activity-top.txt") -Encoding UTF8
    Invoke-Adb -AdbArgs @("shell", "dumpsys", "window", "windows") -AllowFail |
        Set-Content -Path (Join-Path $OutputDir "window-dump.txt") -Encoding UTF8
}

$index = New-Object System.Collections.Generic.List[object]

try {
    for ($i = 1; $i -le $Count; $i++) {
        $shotName = "shot-{0:D4}.png" -f $i
        $remoteShot = "$remoteDir/$shotName"
        $localShot = Join-Path $OutputDir $shotName
        $capturedAt = Get-Date -Format o

        if ($CaptureMode -eq "ExecOut") {
            Save-AdbExecOut -LocalPath $localShot
        }
        else {
            Invoke-Adb -AdbArgs @("shell", "screencap", "-p", $remoteShot) | Out-Null
            Invoke-Adb -AdbArgs @("pull", $remoteShot, $localShot) | Out-Null
        }

        if (-not (Test-Path $localShot)) {
            throw "Screenshot was not pulled: $localShot"
        }

        $size = (Get-Item $localShot).Length
        if ($size -lt 128) {
            throw "Screenshot looks empty or corrupt: $localShot ($size bytes)"
        }

        $index.Add([pscustomobject]@{
            index = $i
            file = $shotName
            captured_local = $capturedAt
            bytes = $size
            interval_ms = $IntervalMs
            capture_mode = $CaptureMode
        }) | Out-Null

        if ($i -lt $Count -and $IntervalMs -gt 0) {
            Start-Sleep -Milliseconds $IntervalMs
        }
    }
}
finally {
    if (-not $KeepRemote) {
        Invoke-Adb -AdbArgs @("shell", "rm", "-rf", $remoteDir) -AllowFail | Out-Null
    }
}

$index | Export-Csv -Path (Join-Path $OutputDir "capture-index.csv") -NoTypeInformation -Encoding UTF8

Write-Host "Thor screenshot capture complete:"
Write-Host "  OutputDir: $OutputDir"
Write-Host "  Count: $Count"
Write-Host "  IntervalMs: $IntervalMs"
