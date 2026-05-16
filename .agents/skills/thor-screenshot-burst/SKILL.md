---
name: thor-screenshot-burst
description: Capture AYN Thor screenshots for RPCSX/RPCS3 visual debugging, including optional burst captures for flicker, black spots, texture corruption, menu/battle/field visual regression, and before/after proof during Eternal Sonata speed tests.
---

# Thor Screenshot Burst

## Scope

Use this skill when Thor visual correctness matters: flicker, black spots, missing textures, menu corruption, battle/field before-after proof, driver comparisons, or any speed experiment that needs screenshot evidence.

Keep this skill focused on capture and evidence only. Use `$thor-game-controller` for input routing and `$thor-experiment-ledger` for recording experiment conclusions.

## Workflow

1. Confirm Thor is connected and the target scene is visible or about to be visible.
2. Run the helper script from the repo root.
3. For a still proof shot:

```powershell
.\.agents\skills\thor-screenshot-burst\scripts\thor_screenshot_burst.ps1 -Label field-check
```

4. For suspected flicker, take a short burst:

```powershell
.\.agents\skills\thor-screenshot-burst\scripts\thor_screenshot_burst.ps1 -Label field-flicker -Count 12 -IntervalMs 150
```

5. Inspect all burst frames before calling a rendering change correct. A single clean frame is not enough when flicker is the bug.
6. Record only summarized outcomes and local capture paths in experiment notes. Do not commit raw screenshots, saves, game content, traces, or personal device captures.

## Acceptance

- Captures land under `debug-captures/thor-screenshots/` by default.
- Every capture directory includes device/session metadata unless `-NoMetadata` is explicitly used.
- Burst captures preserve ordered filenames like `shot-0001.png`, `shot-0002.png`.
- For correctness-locked speed wins, capture at least one still or burst from field, battle, and menu when those scenes are in scope.
