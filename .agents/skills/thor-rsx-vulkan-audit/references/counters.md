# RSX / Vulkan Counter Notes

## Current Auditor

Enable:

```powershell
.\tools\set_thor_logging.ps1 -Mode RsxAuditor
```

Experimental host-read DMA fence:

```powershell
.\tools\set_thor_logging.ps1 -Mode RsxDmaHostFence
```

Reset for FPS sweeps:

```powershell
.\tools\set_thor_logging.ps1 -Mode Quiet
```

## Fields To Read

- `submits`, `waits`, `signals`: queue pressure.
- `rp_begin`, `rp_end`, `rp_break`: render-pass churn.
- `rp_break(g/b/i/t)`: global, buffer, image, texture source split.
- `barriers(g/b/i/t/all)`: barrier type and `ALL_COMMANDS` count.
- `dma_transfer_all` / `dma_transfer_host`: DMA fence mode proof.
- `pipe(g/c/slow/us)`: graphics/compute pipeline creation and stutter.
- `detile`, `simple_upload`: texture movement clues.

## 2026-05-16 Field Reading

- All-fence control reached field at about `16.89 FPS` under auditor.
- Host-fence mode reached field at about `17.54 FPS` under auditor and moved DMA counts from `dma_transfer_all=60` to `dma_transfer_host=60` per 60-frame interval.
- Reduced-loop plus host-fence reached only about `17.60 FPS`, while reduced-loop plus all-fence retake reached about `19.10 FPS`.
- Decision: keep host-fence as a correctness-safe diagnostic experiment, not default speed mode.
- Steady field `rp_break(g/b/i/t)=0/0/0/60`; texture barriers, not DMA fence mode, are the next RSX render-pass-break suspect.

## Code Rules

- New behavior must be off by default or property-gated.
- Include the rollback property in the ledger.
- Never count speed if WCB visuals, menu text, lighting, or textures regress.
