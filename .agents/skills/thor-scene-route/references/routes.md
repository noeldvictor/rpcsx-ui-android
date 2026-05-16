# Eternal Sonata Thor Routes

## Stable

First controllable field:

```powershell
.\tools\thor_input_macro.ps1 -InputMode Direct -BootGame -ForceStop -Profile eternal-sonata-field-route -PostSnapshot
```

Expanded macro:

```text
wait:90000;cross;wait:20000;start;wait:3000;cross;wait:1000;cross;wait:100000;shot:field;stick:left:left:1000;wait:1000;shot:field-move;threads:field-route
```

Pause/menu from field:

```powershell
.\tools\thor_input_macro.ps1 -InputMode Direct -BootGame -ForceStop -Profile eternal-sonata-menu-route -PostSnapshot
```

## Battle Search Notes

- `stick:left:right:5000` from first field hit Polka boundary dialogue: "Let's go back to Tenuto." Do not use as battle proof.
- From field, `up_left` then farther `up_left` reaches the upper path/candle area.
- From the upper path, left movement reaches an open left-side area.
- The down-left exit from that open area produced a black transition and then returned to title in the 2026-05-16 search. Treat it as failed until a log explains it.

## Route Rules

- Keep shots granular: `shot:field`, `shot:upper1`, `shot:leftopen`, `shot:battle-candidate`.
- Add `threads:NAME` at suspected battle/loading states.
- If a route lands on title, boundary dialogue, black screen, or GUI, label it failed and record the capture path.
