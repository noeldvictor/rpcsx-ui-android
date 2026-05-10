# 2026-05-10 Markdown And Thor Variant Audit

## What Was Checked

Project-owned markdown:

- `README.md`
- `AGENTS.md`
- `report/2026-05-10-aps3e-rpcsx-thor-ppu-compile.md`
- `report/2026-05-10-snapdragon-8-gen-2-thor-target.md`

Vendored dependency markdown under `app/src/main/cpp/libadrenotools` was scanned but left untouched. Those files describe the upstream AdrenoTools dependency and should not be rewritten as fork documentation.

## Obsolete Or Confusing Info Fixed

- Old SSH remote in `AGENTS.md` pointed to `git@github.com:noeldvictor/rpcsx-ui-android.git`; updated to `git@github.com:noeldvictor/rpcsx-ui-android-thor.git`.
- README now says the performance target is AYN Thor Base/Pro/Max, not generic Thor.
- README no longer carries the stale Star Fox screenshot note.
- Reports now distinguish Base/Pro/Max from Lite.
- Reports now state that Base/Pro/Max share the same CPU/GPU target and differ mainly by RAM/storage.
- Reports now include the Android-side performance cleanup already completed in this fork.

## Thor Variant Truth

Base, Pro, and Max should share the same emulator CPU/GPU presets:

| Variant | CPU/GPU | RAM | Internal storage | Meaning for this fork |
| --- | --- | ---: | ---: | --- |
| Base | Snapdragon 8 Gen 2 / Adreno 740 | 8 GB LPDDR5X | 128 GB UFS 4.0 | Same speed target, smaller cache budget. |
| Pro | Snapdragon 8 Gen 2 / Adreno 740 | 12 GB LPDDR5X | 256 GB UFS 4.0 | Default test target. |
| Max | Snapdragon 8 Gen 2 / Adreno 740 | 16 GB LPDDR5X | 1 TB UFS 4.0 | More cache and RAM headroom, not a faster CPU/GPU class. |
| Lite | Snapdragon 865 / Adreno 650 | 8 GB LPDDR4X | 128 GB UFS 3.1 | Compatibility-only; do not apply 8 Gen 2 masks. |

## Optimization Implications

- Use one Thor Base/Pro/Max CPU/GPU preset first.
- Vary cache retention and background indexing by RAM/storage, not CPU/GPU.
- Keep Base conservative: lazy global cheat expansion, smaller cache budget, strong stale-cache cleanup.
- Let Max keep more internal cache, but do not promise faster PPU LLVM compilation.
- Keep Lite separate if supported later.

## Sources

- AYN Thor official listing: <https://www.ayntec.com/>
- AYN Thor system-parameters sheet: <https://manuals.plus/m/7e96f29e93e4e571eb4e2ee5f2220a98db9ab0a295678d69157e99ddfc948028.pdf>
- Time Extension Thor SKU recap: <https://www.timeextension.com/news/2025/08/ayn-reveals-release-date-colours-and-specs-for-its-pocket-ds-rival>
- Notebookcheck Thor shipping recap: <https://www.notebookcheck.net/AYN-Thor-dual-screen-handheld-begins-shipping-but-only-the-Snapdragon-8-Gen-2-version.1138344.0.html>
