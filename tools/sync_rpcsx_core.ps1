param(
    [string]$Ref = "master",
    [string]$Remote = "git@github.com:RPCSX/rpcsx.git",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$target = Join-Path $repoRoot "app\src\main\cpp\rpcsx"
$tmpRoot = Join-Path $env:TEMP "rpcsx-core-vendor"
$archive = Join-Path $env:TEMP "rpcsx-core-vendor.tar"

if ((Test-Path $target) -and -not $Force) {
    $dirty = git -C $repoRoot status --short -- app/src/main/cpp/rpcsx
    if ($dirty) {
        throw "Core vendor tree has local changes. Commit/stash them or rerun with -Force."
    }
}

if (Test-Path $tmpRoot) {
    git -C $tmpRoot fetch --depth 1 origin $Ref
    git -C $tmpRoot checkout FETCH_HEAD
} else {
    git clone --depth 1 --branch $Ref $Remote $tmpRoot
}

$commit = git -C $tmpRoot rev-parse HEAD
$summary = git -C $tmpRoot log -1 --pretty=%s

if (Test-Path $archive) {
    Remove-Item -LiteralPath $archive -Force
}

git -C $tmpRoot archive --format=tar --output=$archive HEAD

if (Test-Path $target) {
    $resolvedTarget = Resolve-Path $target
    if (-not $resolvedTarget.Path.StartsWith($repoRoot.Path)) {
        throw "Refusing to remove unsafe path: $resolvedTarget"
    }
    Remove-Item -LiteralPath $resolvedTarget.Path -Recurse -Force
}

New-Item -ItemType Directory -Path $target | Out-Null
tar -xf $archive -C $target

$upstreamNote = @"
# Vendored RPCSX Core Source

This directory is a plain-file vendor copy of the RPCSX core source, not a Git
submodule.

- Upstream: ``$Remote``
- Vendored commit: ``$commit``
- Upstream summary: ``$summary``

Use ``tools/sync_rpcsx_core.ps1`` from the Android repo root to refresh this
tree from upstream. Keep local Thor experiment changes in this repo.

The upstream core still references large third-party dependencies through its
own ``.gitmodules``. Do not blindly vendor those dependency trees into this repo
unless the project explicitly decides to absorb that size.
"@

Set-Content -Path (Join-Path $target "UPSTREAM.md") -Value $upstreamNote -NoNewline

Write-Host "Vendored RPCSX core $commit into $target"
