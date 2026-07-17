# Legacy origin verification

This record verifies the provenance of the two quarantined source snapshots.
It is a source-baseline check only: it does **not** prove that the active
installer replaces any legacy capability and it does not permit the old
repositories to be archived or deleted.

## Verified 2026-07-17

| Upstream repository | Pinned commit | Commit time (UTC) | Upstream blobs | Preserved blobs | Mismatches |
|---|---|---|---:|---:|---:|
| `Yunushan/Ubuntu16.04-Auto-Software-Installation-Script` | `7de4b1d01f9372b3245dea31ee1e5307a650aadb` | 2019-05-15T14:48:42Z | 2 | 2 | 0 |
| `Yunushan/Centos-Red-Hat-Rocky-Alma-Software-Installer` | `f23009ad10f9719bf09ec0c1a87679e0e2653a5c` | 2023-06-08T13:03:02Z | 203 | 203 | 0 |

The verification compared every Git blob ID in each upstream commit tree with
the corresponding file under `legacy/ubuntu-16.04/` or `legacy/rhel-family/`.
Git blob IDs bind the exact file content, so a zero mismatch result proves the
preserved files are byte-for-byte identical to those upstream snapshots.

## Repeat the check

With authenticated GitHub CLI access, first confirm the two immutable commits:

```bash
gh api repos/Yunushan/Ubuntu16.04-Auto-Software-Installation-Script/commits/7de4b1d01f9372b3245dea31ee1e5307a650aadb
gh api repos/Yunushan/Centos-Red-Hat-Rocky-Alma-Software-Installer/commits/f23009ad10f9719bf09ec0c1a87679e0e2653a5c
```

Then compare each recursive upstream Git tree with `git ls-tree -r HEAD --
legacy/ubuntu-16.04` and `git ls-tree -r HEAD -- legacy/rhel-family`, removing
the local `legacy/.../` prefix before comparing path-to-blob-ID mappings.

Also run the repository-local quarantine gate:

```bash
bash tests/validate-legacy-quarantine.sh
```

It verifies that the pinned local legacy tree has not changed, contains only
non-executable files, and is never executed or sourced by the active
installer. The separate [replacement contract](REPLACEMENT.md) and
`./install.sh retirement-status` remain the only authority for an archive or
deletion decision.
