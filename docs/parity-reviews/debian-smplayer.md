# Parity review: `debian/smplayer`

## Scope and decision

- Evidence key: `debian/smplayer`
- Tested commit: `f59c5765b5e68ba4e074331a1b494a1bfdbcb125`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29648435978](https://github.com/Yunushan/linux-software-installer/actions/runs/29648435978), artifact digest `sha256:e9b7e22c95106d4e99fe8bff465e69c78afbb70b3025458fa4380dd5937bca64`
- Verification report: `docs/evidence-verification/debian-smplayer.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-028` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:028` | Added the `rvm/smplayer` PPA, installed SMPlayer with themes and skins, and optionally wrote a user desktop entry. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `smplayer`; distribution package `smplayer`
- Package source and release channel: each target's configured signed distribution APT repositories; no third-party PPA is added
- Verification binaries: `smplayer`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Added the SMPlayer PPA and installed themes and skins extras. | Installs the distribution `smplayer` package. | Retains the media-player frontend without permanently changing APT trust; optional appearance extras are not a supported installer contract. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Could write a user desktop entry under `/home/$superuser/Desktop`. | Does not write user desktop files. | Desktop integration remains package-managed. |
| Firewall/network exposure | No firewall or listening-service action. | No firewall or listening-service action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Added a third-party PPA and a hand-written user launcher. | Does not add either side effect. | The active contract removes persistent third-party trust and user-specific launcher behavior. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies SMPlayer on every
declared current Debian-family target. The requested media-player frontend is
retained without the legacy PPA, optional appearance extras, or user-specific
desktop-file mutation. `intent` parity is therefore accurate.
