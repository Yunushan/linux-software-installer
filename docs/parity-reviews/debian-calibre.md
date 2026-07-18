# Parity review: `debian/calibre`

## Scope and decision

- Evidence key: `debian/calibre`
- Tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`
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
