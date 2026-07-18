# Parity review: `debian/midnight-commander`

## Scope and decision

- Evidence key: `debian/midnight-commander`
- Tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`
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
