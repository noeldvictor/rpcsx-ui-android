---
name: thor-adb-operator
description: "Use for safe Android Debug Bridge work against AYN Thor during RPCSX/RPCS3 testing: finding adb, checking connected devices, collecting device/app metadata, launching or stopping emulator packages, grabbing focused activity/window state, and taking logcat slices without wiping data or touching game content."
---

# Thor ADB Operator

## Scope

Use this skill for ADB device and app operations only. Use `$thor-screenshot-burst` for screenshot evidence and `$thor-game-controller` for gameplay input.

Default package for this repo is `net.rpcsx.easy`. Prefer read-only inspection first, then launch/stop/log capture only when needed.

## Guardrails

- Never run `adb uninstall`, `pm clear`, factory reset, partition writes, bootloader commands, or broad remote deletes unless the user explicitly requests that exact destructive action.
- Restrict cleanup deletes to temp folders created by the current helper script.
- Save reports under ignored `debug-captures/adb-reports/`.
- Include device/package metadata in performance notes so Thor runs can be reproduced.

## Quick Commands

```powershell
.\.agents\skills\thor-adb-operator\scripts\adb_device_report.ps1
.\.agents\skills\thor-adb-operator\scripts\adb_device_report.ps1 -Package net.rpcsx.easy -LogcatLines 300
.\.agents\skills\thor-adb-operator\scripts\adb_app_control.ps1 -Action Status
.\.agents\skills\thor-adb-operator\scripts\adb_app_control.ps1 -Action Launch
```

Useful direct ADB checks:

```powershell
adb devices
adb shell pidof net.rpcsx.easy
adb shell monkey -p net.rpcsx.easy 1
adb shell am force-stop net.rpcsx.easy
adb shell dumpsys activity top
adb shell dumpsys window windows
adb logcat -d -t 200
```

## Workflow

1. Confirm exactly one authorized Thor is connected, or pass `-Serial` to helper scripts.
2. Collect a baseline report before changing emulator settings, drivers, or APKs.
3. For app state, record `pidof`, focused activity, top activity, and window state.
4. For crashes or popups, collect a short logcat tail immediately after the event.
5. Put only summarized results and local report paths in ledgers; do not commit raw logs if they may contain personal device data.
