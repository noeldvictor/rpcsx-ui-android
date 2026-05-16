---
name: thor-rsx-vulkan-audit
description: Audit and optimize RPCSX/RPCS3 RSX-to-Vulkan performance for Eternal Sonata on AYN Thor Adreno 740. Use for Vulkan barriers, render-pass breaks, texture flush/readback, Write Color Buffers cost, shader/pipeline churn, RenderDoc/AGI traces, RSX auditor counters, and gated Vulkan code experiments.
---

# Thor RSX Vulkan Audit

## Scope

Use this repo-only skill for RSX/Vulkan diagnosis and narrowly gated code experiments. Do not use it for SPU/PPU hot loops, scene routing, or result bookkeeping except to hand off to the matching focused skill.

## Workflow

1. Start from a visually proven scene route.
2. Enable only the needed probe:
   - `.\tools\set_thor_logging.ps1 -Mode RsxAuditor`
   - `.\tools\set_thor_logging.ps1 -Mode RsxDmaHostFence` only for the experimental DMA fence mode.
3. Capture a short scene, then inspect logcat for `Thor RSX Auditor`.
4. If changing code, make the path off by default or property-gated.
5. Build and push with:

```powershell
$env:JAVA_HOME="$HOME\.codex\jdks\jdk-17"
$env:ANDROID_HOME="$env:LOCALAPPDATA\Android\Sdk"
.\gradlew.bat ':app:buildCMakeDebug[arm64-v8a]'
.\tools\build_push_thor_core.ps1 -NoBuild -Label LABEL -NoLaunch -NoStream
```

## Probe Map

Read `references/counters.md` before interpreting auditor output or touching RSX/Vulkan files.

Key files currently in scope:

- `app/src/main/cpp/rpcsx/rpcs3/Emu/RSX/VK/VKTextureCache.cpp`
- `app/src/main/cpp/rpcsx/rpcs3/Emu/RSX/VK/vkutils/barriers.cpp`
- `app/src/main/cpp/rpcsx/rpcs3/Emu/RSX/VK/vkutils/thor_rsx_auditor.h`
- `app/src/main/cpp/rpcsx/rpcs3/Emu/RSX/VK/VKRenderPass.cpp`
- `app/src/main/cpp/rpcsx/rpcs3/Emu/RSX/VK/VKPipelineCompiler.cpp`

## Acceptance

Do not count an RSX/Vulkan speed win unless field, first battle, and menu render correctly. Note black spots, missing textures, flicker, lighting changes, menu corruption, driver version, cache state, WCB state, and rollback property.
