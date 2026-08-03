# Parity review: `debian/kdenlive`

## Scope and decision

- Evidence key: `debian/kdenlive`
- Tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`
- Verification report: `docs/evidence-verification/debian-kdenlive.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-044` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:044` | On x86_64, scraped a latest Kdenlive AppImage URL, downloaded it and an icon into a user home directory, then optionally wrote a launcher. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `kdenlive`; distribution package `kdenlive`
- Package source and release channel: each target's configured signed distribution APT repositories; no mutable AppImage download is performed
- Verification binaries: `kdenlive`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Scraped and downloaded a current x86_64 AppImage. | Installs distribution `kdenlive`. | Retains non-linear video-editing capability through a reviewed package channel instead of a mutable scrape-and-download flow. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Downloaded an icon and could write a user desktop entry. | Does not write user files. | Desktop integration remains package-managed. |
| Firewall/network exposure | Downloaded upstream assets. | Uses configured package repositories. | No listening service or firewall mutation. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | Created mutable AppImage and icon files under a user's Downloads tree. | No user data is created or migrated. | Prevents user-home artifacts outside package management. |
| Unsupported or unsafe legacy side effects | Relied on scraped links and unpinned binary/icon downloads. | Does not perform those downloads. | Removes unverifiable mutable-download behavior. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies Kdenlive on every
declared current Debian-family target. `intent` parity is accurate.
