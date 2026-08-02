# Parity review: `debian/caffeine`

## Scope and decision

- Evidence key: `debian/caffeine`
- Tested commit: `4feb21e1ae162f5d9dbdd98df2a05aad4ed3c632`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30744748151](https://github.com/Yunushan/linux-software-installer/actions/runs/30744748151), artifact digest `sha256:9b19da4e4779dd10071a94fd5f137f153fadbe335074b5a59e48de18028b82d5`
- Verification report: `docs/evidence-verification/debian-caffeine.json`

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision |
| --- | --- | --- | --- |
| `ubuntu-113` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:113` | Added the Caffeine PPA, refreshed APT, and installed `caffeine`. | `implemented` |

## Active replacement contract

- Exact target cells: Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64.
- Package and verification binary: `caffeine` / `caffeine` from configured signed distribution repositories.
- Service behavior: none.

## Reviewer conclusion

The active module repeatedly installs and verifies the desktop idle inhibitor.
It intentionally removes the legacy PPA and its global repository mutation.
`intent` parity is accurate.
