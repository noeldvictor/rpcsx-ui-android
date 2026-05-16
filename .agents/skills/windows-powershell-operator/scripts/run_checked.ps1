[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Command,
    [string]$WorkingDirectory = "",
    [string]$Label = "powershell-run",
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

function Write-GitState {
    param(
        [string]$Name,
        [string]$Directory
    )

    $path = Join-Path $OutputDir $Name
    $oldLocation = Get-Location
    try {
        Set-Location -LiteralPath $Directory
        git status --short 2>&1 | Set-Content -Path $path -Encoding UTF8
    }
    catch {
        "git status failed: $($_.Exception.Message)" | Set-Content -Path $path -Encoding UTF8
    }
    finally {
        Set-Location -LiteralPath $oldLocation
    }
}

$repoRoot = Resolve-RepoRoot
if ([string]::IsNullOrWhiteSpace($WorkingDirectory)) {
    $WorkingDirectory = $repoRoot
}
else {
    $WorkingDirectory = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($WorkingDirectory)
}

$safeLabel = ($Label -replace "[^A-Za-z0-9_.-]+", "-").Trim("-")
if ([string]::IsNullOrWhiteSpace($safeLabel)) {
    $safeLabel = "powershell-run"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $repoRoot "debug-captures\powershell-runs\$timestamp-$safeLabel"
}
else {
    $OutputDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDir)
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

@(
    "# Checked PowerShell Run",
    "",
    "- started_local: $(Get-Date -Format o)",
    "- working_directory: $WorkingDirectory",
    "- command: $Command"
) | Set-Content -Path (Join-Path $OutputDir "run.md") -Encoding UTF8

Write-GitState -Name "git-status-before.txt" -Directory $WorkingDirectory

$stdoutPath = Join-Path $OutputDir "stdout.txt"
$stderrPath = Join-Path $OutputDir "stderr.txt"
$exitPath = Join-Path $OutputDir "exit-code.txt"

$oldLocation = Get-Location
try {
    Set-Location -LiteralPath $WorkingDirectory
    $process = Start-Process -FilePath "powershell.exe" `
        -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $Command) `
        -NoNewWindow `
        -Wait `
        -PassThru `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath
    $exitCode = $process.ExitCode
}
finally {
    Set-Location -LiteralPath $oldLocation
}

$exitCode | Set-Content -Path $exitPath -Encoding UTF8
Write-GitState -Name "git-status-after.txt" -Directory $WorkingDirectory

Write-Host "Checked PowerShell run complete:"
Write-Host "  OutputDir: $OutputDir"
Write-Host "  ExitCode: $exitCode"
Write-Host "  Stdout: $stdoutPath"
Write-Host "  Stderr: $stderrPath"

exit $exitCode
