# Parity review: `debian/bluefish`

## Scope and decision

- Evidence key: `debian/bluefish`
- Tested commit: `4feb21e1ae162f5d9dbdd98df2a05aad4ed3c632`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30744748151](https://github.com/Yunushan/linux-software-installer/actions/runs/30744748151), artifact digest `sha256:9b19da4e4779dd10071a94fd5f137f153fadbe335074b5a59e48de18028b82d5`
- Verification report: `docs/evidence-verification/debian-bluefish.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-086` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:086` | Added the Bluefish PPA, installed Bluefish, and optionally wrote a user desktop entry. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `bluefish`; distribution package `bluefish`
- Package source and release channel: each target's configured signed distribution APT repositories; no PPA is added
- Verification binaries: `bluefish`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Added the Bluefish PPA. | Installs distribution `bluefish`. | Retains source/web editing without persistent third-party APT trust. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Could write a user desktop entry. | Does not write user desktop files. | Desktop integration remains package-managed. |
| Firewall/network exposure | No firewall or listening-service action. | No firewall or listening-service action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Added a PPA and a hand-written launcher. | Does not add either side effect. | Removes persistent trust and user-specific launcher mutation. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies Bluefish on every
declared current Debian-family target. `intent` parity is accurate.
