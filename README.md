# RPCSX for AYN Thor Experiment

<p align="center">
  <img src="docs/images/rpcsx-thor-experiment-banner.png" alt="RPCSX for AYN Thor Experiment">
</p>

<p align="center">
  <a href="https://github.com/noeldvictor/rpcsx-ui-android-thor/fork">
    <img src="docs/images/fork-it-button.png" alt="Fork and build yourself - no APK support queue" width="620">
  </a>
</p>

This is a personal-use Android fork of RPCSX-UI-Android aimed at the AYN Thor Base, Pro, and Max. Those Snapdragon 8 Gen 2 / Adreno 740 models are the main target. It is an experiment, it is vibe-coded with AI assistance, and it will move fast in whatever direction makes this handheld easier to use.

No stability guarantee. No support guarantee. Do not open issues expecting upstream-style triage. If the experiment annoys you, fork it and make your own version.

## Vibe-Coded With AI

This fork is openly AI-assisted and vibe-coded. That means rough edges, fast experiments, blunt tradeoffs, and code that may change because it makes the AYN Thor experience better for personal use. If that bothers you, this is not the repo to depend on.

## Fork Path

This repo is source-first. Fork it, build it, and change what you need for your own AYN Thor.

Build artifacts may exist in GitHub Actions, but this README intentionally does not present a big public download button. No store release, no support queue, no stability promise.

## Thor Variants

This fork treats **AYN Thor Base, Pro, and Max** as one CPU/GPU target. They share the Snapdragon 8 Gen 2 and Adreno 740 performance ceiling; the practical differences are RAM and internal storage.

| Variant | CPU/GPU target | RAM | Internal storage | Fork posture |
| --- | --- | ---: | ---: | --- |
| Thor Base | Snapdragon 8 Gen 2 / Adreno 740 | 8 GB LPDDR5X | 128 GB UFS 4.0 | Same emulation speed target, tighter cache/storage budget. |
| Thor Pro | Snapdragon 8 Gen 2 / Adreno 740 | 12 GB LPDDR5X | 256 GB UFS 4.0 | Default comfort target. |
| Thor Max | Snapdragon 8 Gen 2 / Adreno 740 | 16 GB LPDDR5X | 1 TB UFS 4.0 | Best cache headroom; not a different CPU/GPU speed class. |

Thor Lite is a Snapdragon 865 / Adreno 650 device. It may run the app, but it is not the performance target for PS3 work in this fork.

## What This Fork Is

- A Thor-first Android UI experiment for RPCSX.
- Built around simple library use, external storage game discovery, covers, cheat visibility, and trimming experiments.
- Tuned around the real connected target device: `AYN Thor`, board/platform `kalama`, Android package `net.rpcsx.easy`.
- Still GPLv2, still based on the upstream Android UI, and still dependent on the RPCSX core behavior underneath it.

## What This Fork Is Not

- Not an official RPCSX project.
- Not an AYN project.
- Not a promise that every PS3 game will boot, run fast, or survive every update.
- Not a place to ask for games, firmware, system files, keys, or piracy help.

Use legally owned dumps and legally obtained firmware. Personal use only.

## Screenshots

Captured from the connected AYN Thor test device.

![Thor library](docs/screenshots/rpcsx-thor-library.png)

![Thor menu](docs/screenshots/rpcsx-thor-menu.png)

![Overlay editor](docs/screenshots/rpcsx-thor-overlay-editor.png)

## How This Differs From Upstream

Upstream RPCSX-UI-Android is the general Android app. This fork is the opinionated AYN Thor experiment: fewer generic choices, more "make this handheld less annoying" choices.

### Easier For Thor Users

These are the differences regular users should notice first:

| Area | Upstream style | This Thor fork |
| --- | --- | --- |
| Device target | General Android devices. | AYN Thor Base, Pro, and Max are the main target. |
| Updates | Upstream-style update prompts can appear. | Fork update nags are disabled, because this is meant to be built/forked directly. |
| Game folders | More generic import behavior. | External ISO folders can be added as library entries, including SD-card PS3 folders. |
| Game names and covers | Depends more on existing library metadata. | Reads `PARAM.SFO` and `ICON0.PNG` from PS3 game folders/ISOs when possible. |
| Cheats | Not a central Android UI feature. | Cheat badges, per-game cheat lists, bundled cheat database work, and simple toggles are first-class goals. |
| In-game menu | Generic emulator menu behavior. | Thor-friendly menu with Cheats, Fast Forward 2x, Show FPS, Save State, and Load State. |
| Physical controls | Touch controls are normal by default. | Thor devices default to hidden on-screen controls because the handheld has real controls. |
| Hotkeys | Less Thor-specific. | `Select + R1` toggles Fast Forward 2x, `Select + right stick down` saves, `Select + right stick up` loads. |
| Back button | Generic Android behavior. | Android Back opens the in-game menu during gameplay and pauses the game. |
| Gyro / Sixaxis | Not tailored to Thor. | Thor motion sensors are wired for PS3 Sixaxis when the bundled core exposes the motion bridge. |
| Per-game settings | More manual emulator configuration. | Recommended per-game settings are exposed as a simple per-game switch using a bundled/local RPCS3 config snapshot. |
| Compile/cache visibility | Cache behavior is easy to miss. | Game detail shows compiled-cache size and PPU/SPU/shader counts. |
| Cache storage | Less obvious to nontechnical users. | Settings has `Compiled Cache Storage` for choosing internal storage or app-owned SD-card storage when Android exposes it. |
| Trimming | Not presented as a major Android flow. | `Trim / Optimize` is visible as an experimental personal-use tool path. |
| GPU drivers | More generic. | Custom driver screen is Thor-guided, with Adreno 740 notes and curated Turnip-style sources. |

### Current User-Facing Features

- Rebranded as `RPCSX for AYN Thor Experiment` with custom icon/banner art.
- Fork updater prompts are disabled; this repo is source-first, not a public support release.
- External PS3 folders and ISOs are handled with Thor/SD-card use in mind.
- Covers and titles are pulled from PS3 metadata where possible.
- Games with available cheats can show cheat visibility in the library/detail flow.
- Cheats are shown per game so users can toggle individual cheats instead of digging through patch files.
- The in-game Home Menu includes quick toggles for cheats, fast forward, FPS display, and save/load state paths.
- Recommended settings can be enabled per game without making users learn the whole advanced settings tree.
- PPU, SPU, and shader cache are grouped as "compiled cache" so users understand what is taking space and what is warming up.
- Internal storage is recommended for compiled cache speed; SD-card cache is offered as a space-saving option with warnings.
- Thor physical controls are treated as the normal way to play.
- Debug capture tools exist so a Thor play session can produce logs/screenshots that are easier to inspect later.

### Technical / Experimental Differences

These are mostly for builders, contributors, and future-me:

- RPCSX core source is vendored directly under `app/src/main/cpp/rpcsx` as plain files, so Thor native experiments can live in this one repo.
- The default Gradle APK bundles this fork's source-built RPCSX core unless `-PbuildBundledRpcsxCore=false` is passed.
- Automatic upstream UI/core update prompts are disabled through `BuildConfig.FORK_BUILD=true`.
- External ISO folder import avoids blindly extracting loose ISO contents.
- Cheat work includes bundled database assets, Artemis/Aldos conversion experiments, RPCS3 patch imports, and patch-hash learning.
- Recommended settings use a bundled RPCS3 config database snapshot plus a writable local cache.
- Per-game compiled-cache status reads `cache/cache/TITLEID` and counts PPU, SPU, and RSX shader cache entries.
- RSX shader cache lives under the same PPU cache tree (`.../ppu-*/shaders_cache/`), so the selected compiled-cache storage covers CPU and shader cache together.
- Thor startup defaults cap LLVM compile workers, disable full first-boot PPU precompile, enable SPU cache, enable on-disk shader cache, and use a Thor-safe `cortex-a78` LLVM target.
- The old Android `cortex-a34` startup override is removed because it silently downgrades Thor JIT codegen.
- The process is pinned to Thor performance cores where Android permits it.
- Fast Forward 2x uses RPCSX/RPCS3 `Clocks scale`, not a raw uncapped renderer mode. It is experimental and may break timer-sensitive games.
- System Info includes a first `Thor Feature Doctor` readout: configured LLVM CPU, fallback CPU, AArch64 core names, and Android HWCAP/HWCAP2 feature flags.
- AYN Thor motion input is wired on the Android side and depends on the core exporting `_rpcsx_overlayPadMotionData`.
- Android-side performance cleanup has started: less main-thread file probing, faster folder scan queues, safer large-file copy, cached patch status reads, and debounced library saves.
- Thor-specific performance research lives under `report/`.

## AYN Thor Target Notes

The connected Thor reports `kalama` hardware and this CPU layout from `/proc/cpuinfo`:

| CPU | Part | Interpreted core |
| ---: | --- | --- |
| 0 | `0xd46` | Cortex-A510 |
| 1 | `0xd46` | Cortex-A510 |
| 2 | `0xd46` | Cortex-A510 |
| 3 | `0xd4d` | Cortex-A715 |
| 4 | `0xd4d` | Cortex-A715 |
| 5 | `0xd47` | Cortex-A710 |
| 6 | `0xd47` | Cortex-A710 |
| 7 | `0xd4e` | Cortex-X3 |

Useful masks for future native/core work:

| Group | CPUs | Mask |
| --- | --- | --- |
| Efficiency only | `0-2` | `0x07` |
| A715 only | `3-4` | `0x18` |
| A710 only | `5-6` | `0x60` |
| Prime X3 only | `7` | `0x80` |
| Performance plus prime | `3-7` | `0xF8` |
| A715 plus prime | `3-4,7` | `0x98` |

The practical performance direction is boring but important: keep PPU/SPU/shader caches on internal storage, cap LLVM compile workers before they heat-soak the handheld, detect actual CPU topology, and expose obvious Thor/cache controls instead of making people decode advanced settings.

Base/Pro/Max should use the same CPU and GPU presets. Pro/Max mostly let us keep more internal cache, larger game libraries, and more cheat/database state without memory or storage pressure.

## Reports

- [APS3E, RPCSX, and Thor PPU compile notes](report/2026-05-10-aps3e-rpcsx-thor-ppu-compile.md)
- [RPCS3 automatic game settings notes](report/2026-05-10-rpcs3-auto-game-settings.md)
- [AYN Thor Base/Pro/Max Snapdragon 8 Gen 2 target notes](report/2026-05-10-snapdragon-8-gen-2-thor-target.md)
- [Markdown and Thor variant audit](report/2026-05-10-markdown-and-thor-variant-audit.md)
- [Thor black screen debug pipeline](report/2026-05-11-thor-black-screen-debug-pipeline.md)

## Building

Requirements:

- Android 10+
- JDK 17
- Android SDK

Debug APK output:

```powershell
.\gradlew.bat :app:assembleDebug
```

The default Gradle app build builds the Android JNI wrapper and bundles this fork's source-built RPCSX core into the APK. The vendored upstream core source is available at `app/src/main/cpp/rpcsx`, with its Android CMake entry at `app/src/main/cpp/rpcsx/android/CMakeLists.txt`.

Source-core packaging uses pinned RPCSX third-party submodules. Hydrate them once before the first build:

```powershell
.\tools\hydrate_rpcsx_core_deps.ps1
```

For faster app/UI-only iteration without rebuilding or packaging the core, opt out explicitly:

```powershell
.\gradlew.bat :app:assembleDebug -PbuildBundledRpcsxCore=false
```

Expected debug APK name:

```text
app\build\outputs\apk\debug\rpcsx-thor-experiment-debug.apk
```

## Thor Debug Capture

For a live debug session while playing on the handheld:

```powershell
.\tools\start_thor_debug_stream.ps1 -ClearLogcat -Launch -Label game-name
.\tools\summarize_thor_debug_stream.ps1 -Latest
.\tools\stop_thor_debug_stream.ps1 -Latest
```

For a one-shot capture after a problem is visible:

```powershell
.\tools\collect_thor_debug.ps1 -Label game-name
```

Debug streams and captures are written to ignored `debug-captures/` folders for local analysis.

Thor defaults currently favor boot survival over all-at-once cache building: first-boot full PPU precompilation is disabled and LLVM compile-thread pressure is kept low because live testing caught memory-heavy titles aborting inside LLVM during precompile.

## License

This fork keeps the upstream GPLv2 license unless a directory or file contains its own license.
