param(
    [ValidateSet("Default", "TurnipA7xx", "TurnipA8xx")]
    [string] $Driver = "Default",
    [string] $Package = "net.rpcsx.easy",
    [switch] $StopApp
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$adb = if ($env:ANDROID_HOME -and (Test-Path -LiteralPath (Join-Path $env:ANDROID_HOME "platform-tools\adb.exe"))) {
    Join-Path $env:ANDROID_HOME "platform-tools\adb.exe"
} else {
    "adb"
}

$driverInfo = switch ($Driver) {
    "Default" {
        @{
            Selected = "Default"
            Path = ""
            Name = ""
        }
    }
    "TurnipA7xx" {
        @{
            Selected = "Mesa Turnip driver v26.0.0 - R8-v1"
            Path = "/data/data/$Package/files/gpu_drivers/Mesa Turnip driver v26.0.0 - R8-v1"
            Name = "vulkan.ad07xx.so"
        }
    }
    "TurnipA8xx" {
        @{
            Selected = "Turnip A8XX Draft-v1"
            Path = "/data/data/$Package/files/gpu_drivers/Turnip A8XX Draft-v1"
            Name = "vulkan.ad08xx.so"
        }
    }
}

function Set-StringPreference {
    param(
        [xml] $Xml,
        [string] $Name,
        [string] $Value
    )

    $node = $Xml.map.string | Where-Object { $_.name -eq $Name } | Select-Object -First 1
    if ($null -eq $node) {
        $node = $Xml.CreateElement("string")
        $attr = $Xml.CreateAttribute("name")
        $attr.Value = $Name
        $node.Attributes.Append($attr) | Out-Null
        $Xml.map.AppendChild($node) | Out-Null
    }
    $node.InnerText = $Value
}

if ($StopApp) {
    & $adb shell am force-stop $Package | Out-Null
}

$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "thor-gpu-driver"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
$localPrefs = Join-Path $tempDir "app_prefs.xml"
$remoteTemp = "/data/local/tmp/$Package.app_prefs.xml"

& $adb exec-out run-as $Package cat shared_prefs/app_prefs.xml > $localPrefs

[xml] $prefs = Get-Content -LiteralPath $localPrefs -Raw
Set-StringPreference -Xml $prefs -Name "selected_gpu_driver" -Value $driverInfo.Selected
Set-StringPreference -Xml $prefs -Name "gpu_driver_path" -Value $driverInfo.Path
Set-StringPreference -Xml $prefs -Name "gpu_driver_name" -Value $driverInfo.Name
$prefs.Save($localPrefs)

& $adb push $localPrefs $remoteTemp | Out-Null
& $adb shell chmod 644 $remoteTemp | Out-Null
& $adb shell run-as $Package cp $remoteTemp shared_prefs/app_prefs.xml | Out-Null
& $adb shell rm -f $remoteTemp | Out-Null

Write-Host "Selected GPU driver: $($driverInfo.Selected)"
Write-Host "Driver path: $($driverInfo.Path)"
Write-Host "Driver library: $($driverInfo.Name)"
if ($StopApp) {
    Write-Host "Stopped $Package so the next launch applies this driver."
}
