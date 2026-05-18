# Eternal Sonata RSX GPU Residency Plan

- Status: `tooling-ready`
- Game: Eternal Sonata `BLUS30161`
- Device target: AYN Thor Max first
- Created: 2026-05-18

## Working Definition

`RSX on GPU` should not mean moving the RSX command processor to a compute
shader. In this emulator, RSX command decoding, state tracking, sync, and queue
submission should stay CPU-side.

The useful target is RSX GPU residency:

- fewer CPU/GPU drain points;
- fewer render-pass breaks on Adreno;
- narrower barriers and fences;
- less host-visible transfer ping-pong;
- more texture/vertex/render-target data staying in Vulkan resources;
- pipeline warmup separated from steady-state FPS analysis.

## New Tool

Added:

```powershell
.\tools\summarize_eternal_sonata_rsx_auditor.ps1 -RunDir RUN_DIR
```

The script reads `Thor RSX Auditor:` log lines from a run folder or explicit
log file and writes:

- `eternal-sonata-rsx-auditor-summary.md`
- `eternal-sonata-rsx-auditor-records.csv`

It parses both old and newer auditor formats, including:

- queue submits, waits, signals, flush requests, and hard syncs;
- render-pass begin/end and barrier breaks;
- global/buffer/image/texture/all-command barriers;
- barrier-tracked MB;
- texture barrier color/depth/skips when present;
- DMA transfer fences to `ALL_COMMANDS` or `HOST`;
- pipeline graphics/compute/slow creation counts and total creation time;
- detile and simple-upload bytes.

## Old Capture Re-Read

Input:

```powershell
.\tools\summarize_eternal_sonata_rsx_auditor.ps1 `
  -RunDir debug-captures\android-speed-sprint\20260516-101045-eternal-sonata-field-stock-qualcomm-scene `
  -Top 8
```

Output:

- `debug-captures/android-speed-sprint/20260516-101045-eternal-sonata-field-stock-qualcomm-scene/eternal-sonata-rsx-auditor-summary.md`
- `debug-captures/android-speed-sprint/20260516-101045-eternal-sonata-field-stock-qualcomm-scene/eternal-sonata-rsx-auditor-records.csv`

Totals across 106 auditor intervals / 6360 frames:

- Queue submits: `11717`, about `110.54` per 60 frames.
- Hard sync flushes: `695`, about `6.56` per 60 frames.
- Render-pass barrier breaks: `2576`, about `24.30` per 60 frames.
- Barrier-tracked buffer range: about `51583.86 MB`.
- DMA transfer fences: `4652` to `ALL_COMMANDS`, `0` to `HOST`, about
  `7086.80 MB`.
- Pipeline creates: `157` graphics, `1` compute, `158` slow, about
  `89257.93 ms` total creation time.
- Detile jobs: `0`.
- Simple upload: `1`, about `3.51 MB`.

Pressure mix:

| Class | Records | Frames | Reading |
| --- | ---: | ---: | --- |
| `dma-fence-bandwidth` | 55 | 3300 | The main old-capture RSX signal is transfer fences and bytes. |
| `low` | 34 | 2040 | Many intervals are quiet after warmup/transition. |
| `cpu-gpu-drain` | 11 | 660 | Hard syncs are present but not the largest byte path. |
| `pipeline-stutter` | 3 | 180 | Pipeline creation is ugly early warmup, separate from steady field. |
| `buffer-barrier-bandwidth` | 3 | 180 | Large buffer ranges are touched by barriers. |

Important caveat: this was the old `rsx-auditor` dev core field capture at about
`15.11 FPS`, before the RelWithDebInfo build-type correction and before current
u4 reduced-loop low-overhead baselines. Use it to choose the next measurement,
not as the current FPS truth.

## Current Read

The best RSX/GPU hypothesis is:

1. The steady field path is paying too much for `VKTextureCache` DMA transfer
   fencing and broad buffer barrier ranges.
2. Render-pass breaks still matter on Adreno, especially texture/image barriers,
   but the old capture's newer break-source split was not yet available.
3. Pipeline creation is a separate warmup/stutter lane.
4. Detile/simple upload was not the field bottleneck in this capture.

This points at GPU-residency and synchronization-narrowing work before any new
compute shader.

## Next Measurement

Re-run on the current optimized baseline:

```powershell
.\tools\set_thor_logging.ps1 -Mode RsxAuditor
.\tools\eternal_sonata_speed_sprint.ps1 `
  -Action AndroidScene `
  -Scene field `
  -Driver stock-qualcomm `
  -Core relwithdebinfo-u4-rsx-auditor `
  -AndroidLogMode RsxAuditor
.\tools\set_thor_logging.ps1 -Mode Quiet
.\tools\summarize_eternal_sonata_rsx_auditor.ps1 -RunDir RUN_DIR
```

If field still shows high `dma_transfer_all` / `dma_mb`, test only the existing
host-read fence mode as a narrow A/B:

```powershell
.\tools\set_thor_logging.ps1 -Mode RsxDmaHostFence
.\tools\eternal_sonata_speed_sprint.ps1 `
  -Action AndroidScene `
  -Scene field `
  -Driver stock-qualcomm `
  -Core relwithdebinfo-u4-rsx-host-fence `
  -AndroidLogMode RsxDmaHostFence
.\tools\set_thor_logging.ps1 -Mode Quiet
```

Do not compare against any capture where `debug.rpcsx.thor.rsx_dma_fence` was
accidentally left on; use captured props to prove the mode.

## Implementation Ladder

1. `measurement`: current RelWithDebInfo + reduced-loop u4 + `RsxAuditor`.
2. `existing-gate-ab`: `RsxDmaHostFence` versus clean off on matched field.
3. `callsite-labels`: if still hot, split DMA transfer/fence counters by
   texture cache source and command-buffer flush path.
4. `barrier-scope`: narrow the `VKTextureCache.cpp` post-transfer fence only if
   field, first battle, and menu verify clean.
5. `tile-locality`: if newer logs show texture/image `rp_break` dominance,
   continue depth/texture barrier experiments, but keep WCB correctness on.
6. `gpu-resident-prep`: only after the above, consider persistent texture/vertex
   prep buffers or GPU-side conversion.

## Guardrails

- Keep RSX command decoding and synchronization semantics CPU-side.
- Do not mix pipeline warmup with steady-field FPS.
- Do not count WCB-off as a correctness win without visual A/B proof.
- Do not promote `RsxDmaHostFence` unless field, first battle, and menu survive.
- Reset to `Quiet` after RSX logging or fence tests.
- Treat Turnip/A7xx as a separate driver lane because the last Android Turnip
  field result was worse than stock Qualcomm.

## Decision

Continue RSX/GPU work through residency and synchronization:

1. summarize current optimized RSX auditor capture;
2. if DMA fences still dominate, A/B host-read fence mode;
3. if render-pass breaks dominate, target texture/image barrier locality;
4. only build GPU compute for RSX-adjacent data after a capture proves real
   texture/vertex/render-prep bandwidth that can stay on GPU.
