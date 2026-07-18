# Parity review: `debian/calibre`

## Scope and decision

- Evidence key: `debian/calibre`
- Tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`
- Verification report: `docs/evidence-verification/debian-calibre.json`

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision |
| --- | --- | --- | --- |
| `ubuntu-119` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:119` | Piped the upstream Calibre installer script to a privileged shell and could create a desktop file. | `implemented` |

## Active replacement contract

- Exact target cells: Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64.
- Package and verification binary: `calibre` / `calibre` from configured signed distribution repositories.
- Service behavior: none.

## Reviewer conclusion

The active module repeatedly installs and verifies Calibre without executing a
remote installer script or writing user desktop files. It preserves the e-book
library and conversion-suite intent; `intent` parity is accurate.
