# Parity review: `debian/kazam`

## Scope and decision

- Evidence key: `debian/kazam`
- Tested commit: `f59c5765b5e68ba4e074331a1b494a1bfdbcb125`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29648435978](https://github.com/Yunushan/linux-software-installer/actions/runs/29648435978), artifact digest `sha256:e9b7e22c95106d4e99fe8bff465e69c78afbb70b3025458fa4380dd5937bca64`
- Verification report: `docs/evidence-verification/debian-kazam.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-029` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:029` | Added the Kazam PPA, installed Kazam plus explicit Python libraries, and optionally wrote a mislabeled user desktop entry. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `kazam`; distribution package `kazam`
- Package source and release channel: each target's configured signed distribution APT repositories; no third-party PPA is added
- Verification binaries: `kazam`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Added the Kazam PPA and explicitly installed `python3-cairo` and `python3-xlib`. | Installs the distribution `kazam` package and its packaged dependency closure. | Retains screen-recording capability without permanently changing APT trust or manually pinning internal dependencies. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Could write a user desktop entry whose name and comment incorrectly said SMPlayer. | Does not write user desktop files. | Desktop integration remains package-managed and the source defect is not retained. |
| Firewall/network exposure | No firewall or listening-service action. | No firewall or listening-service action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Added a third-party PPA and a hand-written user launcher. | Does not add either side effect. | The active contract removes persistent third-party trust and user-specific launcher behavior. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies Kazam on every
declared current Debian-family target. The requested screen-recording capability
is retained without the legacy PPA, manually specified dependencies, or the
mislabelled user desktop-file mutation. `intent` parity is therefore accurate.
