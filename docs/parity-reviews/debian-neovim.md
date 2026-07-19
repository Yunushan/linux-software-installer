# Parity review: `debian/neovim`

## Scope and decision

- Evidence key: `debian/neovim`
- Tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`
- Verification report: `docs/evidence-verification/debian-neovim.json`

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision |
| --- | --- | --- | --- |
| `ubuntu-104` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:104` | Added the Neovim stable PPA, refreshed APT, and installed `neovim`. | `implemented` |

## Active replacement contract

- Exact target cells: Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64.
- Package and verification binary: `neovim` / `nvim` from the configured signed distribution repositories.
- Service behavior: none.

## Reviewer conclusion

The current module repeatedly installs and verifies Neovim on its three
supported Debian-family cells. It replaces the application-installation intent
without retaining the legacy PPA or repository refresh side effect. `intent`
parity is accurate.
