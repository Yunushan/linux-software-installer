# Parity review: `debian/vim`

## Scope and decision

- Evidence key: `debian/vim`
- Tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`
- Verification report: `docs/evidence-verification/debian-vim.json`

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision |
| --- | --- | --- | --- |
| `ubuntu-087` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:087` | Added the `ppa:jonathonf/vim` repository, refreshed APT, and installed `vim`. | `implemented` |

## Active replacement contract

- Exact target cells: Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64.
- Package and verification binary: `vim` / `vim` from the configured signed distribution repositories.
- Service behavior: none.

## Reviewer conclusion

The active contract repeatedly installs and verifies the Vim editor on every
declared Debian-family target. It preserves the editor-installation intent,
while deliberately removing the obsolete third-party PPA and its global
repository mutation. `intent` parity is accurate.
