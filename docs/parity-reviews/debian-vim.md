# Parity review: `debian/vim`

## Scope and decision

- Evidence key: `debian/vim`
- Tested commit: `4feb21e1ae162f5d9dbdd98df2a05aad4ed3c632`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30744748151](https://github.com/Yunushan/linux-software-installer/actions/runs/30744748151), artifact digest `sha256:9b19da4e4779dd10071a94fd5f137f153fadbe335074b5a59e48de18028b82d5`
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
