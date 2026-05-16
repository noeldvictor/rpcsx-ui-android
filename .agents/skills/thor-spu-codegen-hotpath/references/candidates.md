# SPU / Codegen Candidate Notes

## Current Positive Signal

Reduced-loop emission is controlled by:

```powershell
.\tools\set_thor_logging.ps1 -Mode ReducedLoopEmit
```

Manual quiet+emit pattern for FPS sweeps:

```powershell
.\tools\set_thor_logging.ps1 -Mode Quiet
adb shell setprop debug.rpcsx.thor.spu_reduced_loop_emit 1
```

Cache files:

- normal: `spu-safe-v1-tane.dat`
- reduced-loop: `spu-safe-thor-rl-v1-tane.dat`

Do not mix or rename these casually; cache pollution invalidates speed comparisons.

## 2026-05-16 Results

- Earlier reduced-loop field captures: about `19.6-19.9 FPS`, menu about `20.18 FPS`.
- Retake after RSX work: reduced-loop + all-fence field about `19.10 FPS`, clean visuals.
- Reduced-loop + host-fence field about `17.60 FPS`; do not combine by default.
- Battle validation remains missing.

## Hot SPU / DMA Map

- Hot image: `0x958dfe208b686622`.
- Hot PCs: `0x25cc` and `0x451c`.
- Android DMA profile showed roughly 4.29 GB sampled DMA in field and zero RSX-local bytes.
- Exact output replay cache had no mismatches but also no repeat hits; not the breakthrough.

## Candidate Priority

1. Broaden reduced-loop correctness and coverage.
2. Use Ghidra/disasm around hot PCs to find stable bulk loops.
3. Keep SPU/MFC fast paths verify-first.
4. Avoid broad GPU-offload of SPURS control loops; only batch large stable jobs.
