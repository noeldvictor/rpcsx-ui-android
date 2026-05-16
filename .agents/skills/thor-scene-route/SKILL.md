---
name: thor-scene-route
description: Route and validate Eternal Sonata BLUS30161 scenes on the connected AYN Thor using this repo's Android input/capture tools. Use when Codex needs to get into first playable field, first battle, pause/menu, automate controller input, recover from title/reset/black-screen transitions, or create/update route macros with screenshot proof.
---

# Thor Scene Route

## Scope

Use this repo-only skill for scene control, not emulator-core optimization. The job is to reach a reproducible state and prove it visually. Hand off to `thor-rsx-vulkan-audit` or `thor-spu-codegen-hotpath` when the next step is code/perf analysis.

## Workflow

1. Confirm the current device and profile before routing:
   - `adb devices`
   - `.\tools\push_eternal_sonata_thor_profile.ps1 -Mode NeutralCore -VramMb 3072 -ShaderCompilerThreads 2 -StopApp`
   - `.\tools\set_thor_logging.ps1 -Mode Quiet`
2. Use Direct input first. Prefer `tools/thor_input_macro.ps1 -InputMode Direct`; use virtual/raw input only as a fallback.
3. Capture route steps with named `shot:` tokens and `threads:` at the interesting state.
4. View each screenshot before declaring route success.
5. Record route results in `debug-experiments/` through `thor-experiment-ledger`.

## Known Routes

Read `references/routes.md` before editing route macros or when battle routing is uncertain.

Use the existing first-field route as the stable base:

```powershell
.\tools\thor_input_macro.ps1 -InputMode Direct -BootGame -ForceStop -Profile eternal-sonata-field-route -PostSnapshot
```

For fast scene captures after routing:

```powershell
.\tools\eternal_sonata_speed_sprint.ps1 -Action AndroidScene -Scene field -Driver stock-qualcomm -Core LABEL -AndroidSceneSeconds 12 -NoPerfetto
```

## Acceptance

A route is not valid until it has:

- screenshot proof under `debug-captures/android-speed-sprint/`;
- visible FPS overlay when possible;
- active config/core/logging identity noted;
- no fatal popup, title reset, stale GUI, or black-screen transition misclassified as success;
- field, battle, or menu label matching the actual visual state.
