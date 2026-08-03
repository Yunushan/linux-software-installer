# Parity review: `debian/uget`

## Scope and decision

- Evidence key: `debian/uget`
- Tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`
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
