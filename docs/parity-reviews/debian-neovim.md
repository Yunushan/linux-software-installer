# Parity review: `debian/neovim`

## Scope and decision

- Evidence key: `debian/neovim`
- Tested commit: `739dd664383221912ab00c18e32e762743c8748f`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30838575507](https://github.com/Yunushan/linux-software-installer/actions/runs/30838575507), artifact digest `sha256:f8120aa9eb93ba6878a0e732b29b17218cef6ae1a78bcb981563dc59c9f91852`
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
