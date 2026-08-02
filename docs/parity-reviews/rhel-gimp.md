# Parity review: `rhel/gimp`

## Scope and decision

- Evidence key: `rhel/gimp`
- Tested commit: `4feb21e1ae162f5d9dbdd98df2a05aad4ed3c632`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30744748151](https://github.com/Yunushan/linux-software-installer/actions/runs/30744748151), artifact digest `sha256:9b19da4e4779dd10071a94fd5f137f153fadbe335074b5a59e48de18028b82d5`
- Verification report: `docs/evidence-verification/rhel-gimp.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `rhel-almalinux-8-026-gimp` | `legacy/rhel-family/AlmaLinux-8/scripts/26-Gimp.sh` | Enabled EPEL, installed Snapd, then installed GIMP from Snap. | `implemented` |
| `rhel-centos-7-037-gimp` | `legacy/rhel-family/Centos-7/scripts/37-Gimp.sh` | Installed Flatpak, downloaded a Flathub reference into `/root/Downloads`, then installed GIMP. | `implemented` |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Module and packages: `gimp`; distribution package `gimp`
- Package source and release channel: configured signed DNF repositories; no EPEL, Snap, Flatpak, or remote ref download is added
- Verification binaries: `gimp`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Used EPEL/Snap or a downloaded Flathub ref. | Installs distribution `gimp`. | Retains image-editing capability through the supported package channel. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | No configuration written. | No configuration written. | None. |
| Firewall/network exposure | Downloaded a Flatpak ref in the CentOS script. | Uses configured package repositories. | No listener or firewall mutation. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | CentOS wrote a ref under `/root/Downloads`. | No user/root data is created or migrated. | Removes unmanaged download artifacts. |
| Unsupported or unsafe legacy side effects | Added EPEL/Snap or installed unpinned Flatpak content. | Does not add those side effects. | Removes external-store and mutable-download behavior. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies GIMP on both
supported RHEL-family targets. It safely replaces both legacy outcomes;
`intent` parity is accurate.
