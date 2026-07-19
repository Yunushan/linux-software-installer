# Parity review: `debian/audacity`

## Scope and decision

- Evidence key: `debian/audacity`
- Tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`
- Verification report: `docs/evidence-verification/debian-audacity.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-030` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:030` | Added the `ubuntuhandbook1/audacity` PPA, installed Audacity, and optionally wrote a user desktop entry. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `audacity`; distribution package `audacity`
- Package source and release channel: each target's configured signed distribution APT repositories; no third-party PPA is added
- Verification binaries: `audacity`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Added the UbuntuHandbook PPA. | Installs the distribution `audacity` package. | Retains the audio-editing capability without permanently changing APT trust or sources. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Could write a user desktop entry under `/home/$superuser/Desktop`. | Does not write user desktop files. | Desktop integration remains package-managed and does not mutate an assumed user's home directory. |
| Firewall/network exposure | No firewall or listening-service action. | No firewall or listening-service action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Added a third-party PPA and a hand-written user launcher. | Does not add either side effect. | The active contract removes persistent third-party trust and user-specific launcher behavior. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies Audacity on every
declared current Debian-family target. The requested audio-recording and editing
capability is retained without the obsolete PPA or user-specific desktop-file
mutation. `intent` parity is therefore accurate.
