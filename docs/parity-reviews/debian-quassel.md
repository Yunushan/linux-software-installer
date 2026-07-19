# Parity review: `debian/quassel`

## Scope and decision

- Evidence key: `debian/quassel`
- Tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`
- Verification report: `docs/evidence-verification/debian-quassel.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-073` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:073` | Added the Quassel PPA, installed Quassel, and optionally wrote a user desktop entry. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `quassel`; distribution package `quassel-client`
- Package source and release channel: each target's configured signed distribution APT repositories; no PPA is added
- Verification binaries: `quasselclient`
- Service behavior: none; this contract is explicitly client-only

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Added the Quassel PPA. | Installs distribution `quassel-client`. | Retains IRC client capability without persistent third-party APT trust. |
| Service lifecycle | The legacy row did not configure or start a Quassel core. | Client-only; no service is installed or started. | No unverified service behavior is introduced. |
| Configuration files/defaults | Could write a user desktop entry. | Does not write user desktop files. | Desktop integration remains package-managed. |
| Firewall/network exposure | No firewall or listening-service action. | No firewall or listening-service action. | None. |
| Credentials and secrets | Did not configure IRC credentials. | Does not configure credentials. | Account setup remains outside the installer. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Added a PPA and a hand-written launcher. | Does not add either side effect. | Removes persistent trust and user-specific launcher mutation. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies the Quassel
client on every declared current Debian-family target. `intent` parity is
accurate for the legacy client-side outcome.
