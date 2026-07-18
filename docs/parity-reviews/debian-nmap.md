# Parity review: `debian/nmap`

## Scope and decision

- Evidence key: `debian/nmap`
- Tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`
- Verification report: `docs/evidence-verification/debian-nmap.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-012` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:012` | Downloaded a current Nmap RPM discovered from nmap.org, converted it with `alien`, and optionally wrote a desktop entry. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `nmap`; distribution package `nmap`
- Package source and release channel: each target's configured signed distribution APT repositories
- Verification binaries: `nmap`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Scraped an RPM download and converted it into a Debian package. | Installs the distribution `nmap` package. | Preserves Nmap while removing unpinned cross-format conversion. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Could write a user desktop entry and download an icon. | Does not write user desktop files or download icons. | Package-managed integration replaces the optional side effect. |
| Firewall/network exposure | No firewall or listening-service action. | No firewall or listening-service action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Dynamic RPM discovery and `alien` conversion. | None. | Removed as unsupported package provenance. |

## Reviewer conclusion

The active module provides and verifies Nmap on every declared current
Debian-family target without the legacy download-and-convert path. `intent`
parity is accurate because no service or persistent data contract existed.
