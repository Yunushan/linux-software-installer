# Parity review: `debian/midnight-commander`

## Scope and decision

- Evidence key: `debian/midnight-commander`
- Tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`
- Verification report: `docs/evidence-verification/debian-midnight-commander.json`

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision |
| --- | --- | --- | --- |
| `ubuntu-136` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:136` | Installed the `mc` package. | `implemented` |

## Active replacement contract

- Exact target cells: Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64.
- Package and verification binary: `mc` / `mc` from the configured signed distribution repositories.
- Service behavior: none.

## Reviewer conclusion

The active module performs the same terminal file-manager installation intent,
with exact clean-install and repeat-install evidence on every declared target.
It has no legacy repository, user-file, service, or data-migration side
effect. `intent` parity is accurate.
