# Verified full-catalog evidence runs

This log records independent local verification of immutable GitHub Actions
aggregate artifacts. It does not itself admit a legacy row: row-level parity
reviews and any required systemd attestations remain mandatory.

## 2026-07-18: current full matrix

- Tested commit: `f59c5765b5e68ba4e074331a1b494a1bfdbcb125`
- Workflow run: [29648435978](https://github.com/Yunushan/linux-software-installer/actions/runs/29648435978)
- Artifact: `module-evidence-aggregate-f59c5765b5e68ba4e074331a1b494a1bfdbcb125` ([artifact 8431224522](https://github.com/Yunushan/linux-software-installer/actions/runs/29648435978/artifacts/8431224522))
- GitHub-published ZIP digest: `sha256:e9b7e22c95106d4e99fe8bff465e69c78afbb70b3025458fa4380dd5937bca64`
- Observed downloaded ZIP digest: `sha256:e9b7e22c95106d4e99fe8bff465e69c78afbb70b3025458fa4380dd5937bca64`
- Matrix result: 105 successful jobs; no failed jobs
- Independent verifier result: all 93 tracked `family/module` report keys and
  all 370 indexed cells verified cleanly.

The verifier checked the ZIP and internal checksum records, aggregate index,
summary and expected-cell tables, tested-commit marker and every indexed cell
result digest. This receipt now rebinds the accepted-evidence registry.

## Earlier 2026-07-18 full matrix

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

## Historical artifact record

Run [29640717432](https://github.com/Yunushan/linux-software-installer/actions/runs/29640717432)
at commit `f7b772a72fa8c543cb84f79db0473cf5ad05daf5` remains recorded as
historical provenance only. The `*.json` reports in this directory and all
accepted-evidence admissions are now rebound to the fresh f59 artifact
documented above.
