# Vendored RPCSX Core Source

This directory is a plain-file vendor copy of the RPCSX core source, not a Git
submodule.

- Upstream: `git@github.com:RPCSX/rpcsx.git`
- Initial vendored commit: `e27926d6296e2ce4bd5b0775cb4e4423d9e7cdb6`
- Initial upstream summary: `ajm: rewrite using new ioctl handling api`

Use `tools/sync_rpcsx_core.ps1` from the Android repo root to refresh this
tree from upstream. Keep local Thor experiment changes in this repo.

The upstream core still references large third-party dependencies through its
own `.gitmodules`. Do not blindly vendor those dependency trees into this repo
unless the project explicitly decides to absorb that size.
