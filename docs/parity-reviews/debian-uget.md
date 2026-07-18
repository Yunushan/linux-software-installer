# Parity review: `debian/uget`

## Scope and decision

- Evidence key: `debian/uget`
- Tested commit: `f7b772a72fa8c543cb84f79db0473cf5ad05daf5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29640717432](https://github.com/Yunushan/linux-software-installer/actions/runs/29640717432), artifact digest `sha256:e744fab69651ad0d2adce755e7a65da1191822af6524d44b8b1d1d259140d477`
- Verification report: `docs/evidence-verification/debian-uget.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-054` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:054` | Downloaded an architecture-specific Xenial `.deb`, installed it with `dpkg`, repaired dependencies, and optionally wrote a user desktop entry. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `uget`; distribution package `uget`
- Package source and release channel: each target's configured signed distribution APT repositories; no external `.deb` download is performed
- Verification binaries: `uget-gtk`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Downloaded architecture-specific Xenial `.deb` files then ran `dpkg -i`. | Installs distribution `uget`. | Retains download-manager capability through a reviewed package channel. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Could write a user desktop entry. | Does not write user desktop files. | Desktop integration remains package-managed. |
| Firewall/network exposure | Downloaded package payloads; no listener was configured. | Uses configured package repositories. | No firewall or listening-service action. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | Stored a package file in a user's Downloads tree. | No user data is created or migrated. | Prevents unmanaged user-home artifacts. |
| Unsupported or unsafe legacy side effects | Used unpinned, obsolete Xenial packages and dependency repair. | Does not perform those operations. | Removes unsafe architecture-specific download/install behavior. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies uGet on every
declared current Debian-family target. `intent` parity is accurate.
