# Verified full-catalog evidence runs

This log records independent local verification of immutable GitHub Actions
aggregate artifacts. It does not itself admit a legacy row: row-level parity
reviews and any required systemd attestations remain mandatory.

## 2026-07-18: current full matrix

- Tested commit: `0cde8908f059a298cd279c2b593f1a6e043e76de`
- Workflow run: [29643391040](https://github.com/Yunushan/linux-software-installer/actions/runs/29643391040)
- Artifact: `module-evidence-aggregate-0cde8908f059a298cd279c2b593f1a6e043e76de` ([artifact 8430119179](https://github.com/Yunushan/linux-software-installer/actions/runs/29643391040/artifacts/8430119179))
- GitHub-published ZIP digest: `sha256:b0f8fb40f6df24c75d33350a709e3585a78382815cf74bdf2a8f0567560d9c0b`
- Observed downloaded ZIP digest: `sha256:b0f8fb40f6df24c75d33350a709e3585a78382815cf74bdf2a8f0567560d9c0b`
- Matrix result: 105 successful jobs; no failed jobs
- Independent verifier result: 90 unique `family/module` keys from the active
  readiness ledger and all 370 indexed cells verified cleanly.

The verifier checked the ZIP and internal checksum records, aggregate index,
summary and expected-cell tables, tested-commit marker, every indexed cell
result digest, and the requested 90-key catalog coverage.

## Earlier full matrix

The `*.json` reports in this directory remain the original independently
verified reports from run
[29640717432](https://github.com/Yunushan/linux-software-installer/actions/runs/29640717432)
at commit `f7b772a72fa8c543cb84f79db0473cf5ad05daf5`. They continue to bind
each evidence key to its specific accepted artifact. The 2026-07-18 run above
is a newer full-catalog verification receipt, not a rewrite of those admission
bindings.
