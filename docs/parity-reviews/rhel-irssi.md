# Parity review: `rhel/irssi`

## Scope and decision

- Evidence key: `rhel/irssi`
- Tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`
- Verification report: `docs/evidence-verification/rhel-irssi.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `rhel-almalinux-8-012-irssi` | `legacy/rhel-family/AlmaLinux-8/scripts/12-Irssi.sh` | Offered official DNF or Snap Irssi. | `implemented` |
| `rhel-centos-7-012-irssi` | `legacy/rhel-family/Centos-7/scripts/12-Irssi.sh` | Installed Irssi with YUM. | `implemented` |
| `rhel-red-hat-enterprise-linux-8-031-irssi` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/31-Irssi.sh` | Offered DNF or Snap Irssi and removed the alternate choice. | `implemented` |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Module and packages: `irssi`; distribution package `irssi`
- Package source and release channel: configured signed DNF repositories; no Snap store is added
- Verification binaries: `irssi`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Used YUM/DNF package installs, sometimes offering Snap. | Installs distribution `irssi`. | Preserves the client without Snap-store dependency. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | No configuration written. | No configuration written. | None. |
| Firewall/network exposure | No firewall or listener action. | No firewall or listener action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Optional Snap path and switching/removal of alternatives. | Does not add Snap or remove alternatives. | The active package contract is deterministic and non-destructive. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies Irssi on both
supported RHEL-family targets. It safely replaces the useful client outcome of
all three legacy scripts; `intent` parity is accurate.
