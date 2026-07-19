# Parity review: `rhel/vim`

## Scope and decision

- Evidence key: `rhel/vim`
- Tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`
- Verification report: `docs/evidence-verification/rhel-vim.json`

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `rhel-red-hat-enterprise-linux-9-025-vim` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-9/scripts/25-Vim.sh` | Installed `vim-enhanced` or cloned and compiled the latest Vim source. | `implemented` |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Module and package: `vim`; `vim-enhanced`
- Package source and release channel: configured signed DNF repositories; no source clone is performed
- Verification binary: `vim`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Offered the distribution package or an unpinned upstream Git clone and source build. | Installs `vim-enhanced` from configured signed DNF repositories. | Preserves the editor outcome without mutable source acquisition. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | No configuration files were written. | No configuration files are written. | None. |
| Firewall/network exposure | No firewall or listener action; the source route cloned from GitHub. | Package-manager network access only during installation. | No added listener or arbitrary source clone. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | The source route wrote a checkout under `/root/Downloads` and installed unmanaged binaries. | Installs package-managed files only. | Avoids unmanaged global installation paths. |
| Unsupported or unsafe legacy side effects | Mutable source clone and source compilation. | None of those are retained. | The active contract is deterministic and maintainable. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies Vim on both supported
RHEL-family targets. It safely replaces the legacy editor-installation intent; `intent`
parity is accurate.
