# Experiment Entry Template

```markdown
### YYYY-MM-DD - short-id

- Status: proposed | windows-pass | android-pass | failed | parked
- Scope: scene-route | rsx-vulkan | spu-codegen | windows-android-ab | config-driver
- Hypothesis:
- Changed files/settings:
- Rollback:
- Windows result:
- Thor result:
- Visual correctness:
- FPS/frame-time:
- Capture paths:
- Decision:
- Next:
```

## Status Meanings

- `proposed`: no proof yet.
- `windows-pass`: Windows route/correctness/instrumentation worked, Thor proof pending.
- `android-pass`: Thor proof passed enough for the stated claim.
- `failed`: route, crash, visual regression, no speed, or bad measurement.
- `parked`: valid but not current priority or not a default win.

## Commit Hygiene

Stage only files for the current slice. Do not stage raw captures, saves, ISO/game data, firmware, APKs, `.cxx`, Gradle caches, or runtime shader/SPU/PPU caches.
