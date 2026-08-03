# Parity review: `debian/vim`

## Scope and decision

- Evidence key: `debian/vim`
- Tested commit: `739dd664383221912ab00c18e32e762743c8748f`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30838575507](https://github.com/Yunushan/linux-software-installer/actions/runs/30838575507), artifact digest `sha256:f8120aa9eb93ba6878a0e732b29b17218cef6ae1a78bcb981563dc59c9f91852`
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
