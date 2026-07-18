# Parity review: `debian/gimp`

## Scope and decision

- Evidence key: `debian/gimp`
- Tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`
- Verification report: `docs/evidence-verification/debian-gimp.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-011` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:011` | Added the Flatpak PPA, installed Flatpak, downloaded a GIMP reference, and installed it from Flathub. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `gimp`; distribution package `gimp`
- Package source and release channel: each target's configured signed distribution APT repositories; no PPA, Flatpak, or Flathub route is added
- Verification binaries: `gimp`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Added a Flatpak PPA and downloaded a Flathub `.flatpakref`. | Installs GIMP from the supported distribution package channel. | Intent parity without external PPA or downloaded Flatpak-reference trust. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Could write a desktop entry whose command and icon point to NetBeans rather than GIMP. | Does not write user desktop files. | The preserved source defect is intentionally not retained; desktop integration is package-managed. |
| Firewall/network exposure | No firewall or listening-service action. | No firewall or listening-service action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Added a PPA and installed an externally downloaded Flatpak reference. | Does not add either external route. | The active contract removes unsupported source and launcher side effects. |

## Reviewer conclusion

The requested outcome is GIMP, which the active module installs and verifies
cleanly and repeatedly on every declared current Debian-family target. The
legacy Flatpak route and its mispointed optional launcher are neither required
for that capability nor safe to preserve. No service, firewall, credential, or
data behavior is lost, making `intent` parity accurate.
