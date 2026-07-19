# Parity review: `debian/krita`

## Scope and decision

- Evidence key: `debian/krita`
- Tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`
- Verification report: `docs/evidence-verification/debian-krita.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-043` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:043` | On x86_64, scraped a latest Krita AppImage URL, downloaded it and an icon into a user home directory, then optionally wrote a launcher. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `krita`; distribution package `krita`
- Package source and release channel: each target's configured signed distribution APT repositories; no mutable AppImage download is performed
- Verification binaries: `krita`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Scraped and downloaded a current x86_64 AppImage. | Installs distribution `krita`. | Retains digital-painting capability through a reviewed package channel instead of a mutable scrape-and-download flow. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Downloaded an icon and could write a user desktop entry. | Does not write user files. | Desktop integration remains package-managed. |
| Firewall/network exposure | Downloaded upstream assets. | Uses configured package repositories. | No listening service or firewall mutation. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | Created mutable AppImage and icon files under a user's Downloads tree. | No user data is created or migrated. | Prevents user-home artifacts outside package management. |
| Unsupported or unsafe legacy side effects | Relied on scraped links and unpinned binary/icon downloads. | Does not perform those downloads. | Removes unverifiable mutable-download behavior. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies Krita on every
declared current Debian-family target. `intent` parity is accurate.
