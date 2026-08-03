# Parity review: `debian/vim`

## Scope and decision

- Evidence key: `debian/vim`
- Tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`
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
