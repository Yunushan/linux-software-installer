# Parity review: `debian/kazam`

## Scope and decision

- Evidence key: `debian/kazam`
- Tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`
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
