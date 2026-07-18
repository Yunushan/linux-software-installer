# Parity review: `debian/vim`

## Scope and decision

- Evidence key: `debian/vim`
- Tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`
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
