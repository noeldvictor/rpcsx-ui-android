---
name: windows-powershell-operator
description: "Use for safe, repeatable Windows PowerShell work in this repo: running commands with a fixed working directory, capturing stdout/stderr, checking git state before and after, avoiding fragile shell chaining, and handling Windows path quoting during build, test, ADB, and emulator debugging workflows."
---

# Windows PowerShell Operator

## Scope

Use this skill when PowerShell behavior itself matters: quoting paths with spaces, command output capture, git dirtiness checks, long build/test commands, Windows-native file operations, or normalizing local environment reports.

Use direct `shell_command` calls for simple one-liners. Use the helper script when a command should leave durable logs or when repo state must be compared before and after.

## Guardrails

- Prefer native PowerShell cmdlets for Windows file operations.
- Resolve and verify absolute paths before recursive delete or move operations.
- Do not mix PowerShell path enumeration with `cmd /c` deletion or move commands.
- Use `rg`/`rg --files` for search when available.
- Avoid noisy chained commands with separators when parallel reads would be clearer.
- For dirty worktrees, stage only intended files and never revert unrelated user changes.

## Checked Command Runner

Run a command with stdout/stderr and git state captured under ignored `debug-captures/powershell-runs/`:

```powershell
.\.agents\skills\windows-powershell-operator\scripts\run_checked.ps1 -Command "git status --short"
```

Use `-Label` for meaningful experiment names:

```powershell
.\.agents\skills\windows-powershell-operator\scripts\run_checked.ps1 -Label build-thor-apk -Command ".\gradlew.bat assembleDebug"
```

## Workflow

1. Set `-WorkingDirectory` explicitly for repo commands when not already in the repo root.
2. Capture dirty state before risky commands.
3. Run the command once, preserving raw stdout/stderr.
4. Inspect the exit code and after-state before making claims.
5. Summarize important output in the user response because command output is not visible to the user.
