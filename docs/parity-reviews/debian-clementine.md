# Parity review: `debian/clementine`

## Scope and decision

- Evidence key: `debian/clementine`
- Tested commit: `f59c5765b5e68ba4e074331a1b494a1bfdbcb125`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29648435978](https://github.com/Yunushan/linux-software-installer/actions/runs/29648435978), artifact digest `sha256:e9b7e22c95106d4e99fe8bff465e69c78afbb70b3025458fa4380dd5937bca64`
- Verification report: `docs/evidence-verification/debian-clementine.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-048` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:048` | Added the Clementine PPA, installed Clementine, and optionally wrote a user desktop entry. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `clementine`; distribution package `clementine`
- Package source and release channel: each target's configured signed distribution APT repositories; no PPA is added
- Verification binaries: `clementine`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Added the Clementine PPA. | Installs distribution `clementine`. | Retains music-library capability without persistent third-party APT trust. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Could write a user desktop entry. | Does not write user desktop files. | Desktop integration remains package-managed. |
| Firewall/network exposure | No firewall or listening-service action. | No firewall or listening-service action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Added a PPA and a hand-written launcher. | Does not add either side effect. | Removes persistent trust and user-specific launcher mutation. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies Clementine on
every declared current Debian-family target. `intent` parity is accurate.
