# Parity review: `debian/handbrake`

## Scope and decision

- Evidence key: `debian/handbrake`
- Tested commit: `f59c5765b5e68ba4e074331a1b494a1bfdbcb125`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29648435978](https://github.com/Yunushan/linux-software-installer/actions/runs/29648435978), artifact digest `sha256:e9b7e22c95106d4e99fe8bff465e69c78afbb70b3025458fa4380dd5937bca64`
- Verification report: `docs/evidence-verification/debian-handbrake.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-033` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:033` | Added the HandBrake releases PPA, installed `handbrake-cli` and `handbrake-gtk`, and optionally wrote a user desktop entry. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `handbrake`; distribution packages `handbrake`, `handbrake-cli`
- Package source and release channel: each target's configured signed distribution APT repositories; no third-party PPA is added
- Verification binaries: `ghb`, `HandBrakeCLI`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Added the HandBrake releases PPA. | Installs distribution GUI and CLI packages. | Retains transcoding capability without permanently changing APT trust or sources. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Could write a user desktop entry under `/home/$superuser/Desktop`. | Does not write user desktop files. | Desktop integration remains package-managed. |
| Firewall/network exposure | No firewall or listening-service action. | No firewall or listening-service action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Added a third-party PPA and a hand-written user launcher. | Does not add either side effect. | The active contract removes persistent third-party trust and user-specific launcher behavior. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies both HandBrake
clients on every declared current Debian-family target. The requested video
transcoding capability is retained without the legacy PPA or user-specific
desktop-file mutation. `intent` parity is therefore accurate.
