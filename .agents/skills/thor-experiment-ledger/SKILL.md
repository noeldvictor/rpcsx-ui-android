---
name: thor-experiment-ledger
description: Maintain repo-local Eternal Sonata and AYN Thor performance experiment records. Use when Codex needs to update debug-experiments notes, AGENTS.md status, capture paths, route status, speed/regression results, rollback switches, commit scope, or next-step ledgers after a Windows/Android run or code experiment.
---

# Thor Experiment Ledger

## Scope

Use this repo-only skill for durable notes and commit hygiene. It should not perform new profiling or route discovery by itself; pull results from the relevant focused skill.

## Workflow

1. Identify the experiment ID, scene, core label/SHA, driver, config, cache state, and logging mode.
2. Record both success and failure. A bad route, black screen, title reset, or neutral speed result is still evidence.
3. Update the narrowest durable file:
   - `debug-experiments/*.md` for experiment results;
   - `AGENTS.md` only for standing workflow rules or major current-state summaries;
   - `.gitignore` only for new local artifact classes.
4. Keep raw captures, saves, game data, firmware, APK/native build outputs, and personal data uncommitted.
5. Stage and commit only the repo-local files needed for the current slice.

## Template

Read `references/status-template.md` before writing a new experiment entry.

Minimum fields:

- hypothesis;
- changed files or settings;
- rollback switch;
- Windows result, if any;
- Thor result;
- visual correctness;
- FPS/frame-time note;
- status: `proposed`, `windows-pass`, `android-pass`, `failed`, or `parked`;
- next action.

## Acceptance

The ledger must make the next agent faster. Prefer one precise capture path and one conclusion over a long narrative with no decision.
