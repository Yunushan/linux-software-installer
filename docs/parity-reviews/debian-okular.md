# Parity review: `debian/okular`

## Scope and decision

- Evidence key: `debian/okular`
- Tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`
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
