# Parity review: `debian/shotcut`

## Scope and decision

- Evidence key: `debian/shotcut`
- Tested commit: `4feb21e1ae162f5d9dbdd98df2a05aad4ed3c632`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30744748151](https://github.com/Yunushan/linux-software-installer/actions/runs/30744748151), artifact digest `sha256:9b19da4e4779dd10071a94fd5f137f153fadbe335074b5a59e48de18028b82d5`
- Verification report: `docs/evidence-verification/debian-shotcut.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-070` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:070` | Installed Snapd, installed Shotcut from Snap with `--classic`, and optionally wrote a user launcher. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `shotcut`; distribution package `shotcut`
- Package source and release channel: each target's configured signed distribution APT repositories; no Snap store is added
- Verification binaries: `shotcut`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Installed Snapd and classic-confinement Shotcut. | Installs distribution `shotcut`. | Retains video-editing capability without a Snap-store dependency. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Could write a user desktop entry using a discovered logo path. | Does not write user desktop files. | Desktop integration remains package-managed. |
| Firewall/network exposure | No firewall or listening-service action. | No firewall or listening-service action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Added Snapd, Snap store trust, and a hand-written launcher. | Does not add those side effects. | Removes external-store and user-specific launcher behavior. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies Shotcut on every
declared current Debian-family target. `intent` parity is accurate.
