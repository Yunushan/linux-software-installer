# Parity review: `debian/geary`

## Scope and decision

- Evidence key: `debian/geary`
- Tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`
- Verification report: `docs/evidence-verification/debian-geary.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-053` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:053` | Added the Geary PPA, installed Geary, downloaded an icon into a user home directory, and optionally wrote a launcher. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `geary`; distribution package `geary`
- Package source and release channel: each target's configured signed distribution APT repositories; no PPA is added
- Verification binaries: `geary`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Added the Geary PPA. | Installs distribution `geary`. | Retains desktop email-client capability without persistent third-party APT trust. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Downloaded an icon and could write a user launcher. | Does not write user files. | Desktop integration remains package-managed. |
| Firewall/network exposure | Downloaded an icon; did not configure a listener. | Uses configured package repositories. | No firewall or listening-service action. |
| Credentials and secrets | Did not configure an email account. | Does not configure credentials. | User account setup remains outside the installer. |
| Data creation, migration, or deletion | Created a mutable icon under a user's Downloads tree. | No user data is created or migrated. | Prevents unowned user-home artifacts. |
| Unsupported or unsafe legacy side effects | Added a PPA and downloaded an unpinned icon. | Does not add either side effect. | Removes mutable external assets and trust changes. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies Geary on every
declared current Debian-family target. `intent` parity is accurate.
