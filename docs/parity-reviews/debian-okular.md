# Parity review: `debian/okular`

## Scope and decision

- Evidence key: `debian/okular`
- Tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`
- Verification report: `docs/evidence-verification/debian-okular.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-071` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:071` | Offered distribution APT or Snap installation, then optionally wrote a user launcher. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `okular`; distribution package `okular`
- Package source and release channel: each target's configured signed distribution APT repositories; no Snap store is added
- Verification binaries: `okular`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Allowed APT or Snap. | Installs the supported APT path. | Preserves the direct legacy APT option without Snap-store dependency. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Could write a user desktop entry. | Does not write user desktop files. | Desktop integration remains package-managed. |
| Firewall/network exposure | No firewall or listening-service action. | No firewall or listening-service action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Could add Snapd and a hand-written launcher. | Does not add either side effect. | Removes optional external-store and user-specific behavior. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies Okular on every
declared current Debian-family target. `intent` parity is accurate.
