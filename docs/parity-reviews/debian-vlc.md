# Parity review: `debian/vlc`

## Scope and decision

- Evidence key: `debian/vlc`
- Tested commit: `f7b772a72fa8c543cb84f79db0473cf5ad05daf5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29640717432](https://github.com/Yunushan/linux-software-installer/actions/runs/29640717432), artifact digest `sha256:e744fab69651ad0d2adce755e7a65da1191822af6524d44b8b1d1d259140d477`
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
