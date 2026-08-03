# Parity review: `debian/vlc`

## Scope and decision

- Evidence key: `debian/vlc`
- Tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`
- Verification report: `docs/evidence-verification/debian-vlc.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-004` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:004` | Installed VLC from Snap and optionally wrote a desktop entry pointing to `/snap/bin/vlc`. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `vlc`; distribution package `vlc`
- Package source and release channel: each target's configured signed distribution APT repositories; no Snap store is added
- Verification binaries: `vlc`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Installed VLC through Snap. | Installs the distribution `vlc` package. | Preserves VLC without a Snap-store dependency. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Could write a user desktop entry. | Does not write user desktop files. | Desktop integration is package-managed. |
| Firewall/network exposure | No firewall or listening-service action. | No firewall or listening-service action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Relied on the Snap store and a user-specific launcher. | Does not add either side effect. | The active contract removes external-store and hand-written-launcher behavior. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies VLC on every
declared current Debian-family target. The requested media-player capability is
retained without Snap or user-specific desktop-file behavior. `intent` parity
is therefore accurate.
