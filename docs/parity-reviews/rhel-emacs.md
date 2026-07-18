# Parity review: `rhel/emacs`

## Scope and decision

- Evidence key: `rhel/emacs`
- Tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`
- Verification report: `docs/evidence-verification/rhel-emacs.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `rhel-almalinux-8-019-gnu-emacs` | `legacy/rhel-family/AlmaLinux-8/scripts/19-Gnu-Emacs.sh` | Installed Emacs through DNF. | `implemented` |
| `rhel-centos-7-019-gnu-emacs` | `legacy/rhel-family/Centos-7/scripts/19-Gnu-Emacs.sh` | Enabled EPEL, then installed Emacs through YUM. | `implemented` |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Module and packages: `emacs`; distribution package `emacs`
- Package source and release channel: configured signed DNF repositories; no EPEL enablement is added
- Verification binaries: `emacs`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Used DNF directly on Alma; enabled EPEL on CentOS 7. | Installs distribution `emacs`. | Retains the editor without adding EPEL or carrying the EOL CentOS baseline forward. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | No configuration written. | No configuration written. | None. |
| Firewall/network exposure | No firewall or listener action. | No firewall or listener action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Enabled an external repository on CentOS 7. | Does not add EPEL. | The supported target baseline uses its configured distribution repositories. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies Emacs on both
supported RHEL-family targets. It replaces the useful editor outcome of both
legacy scripts; `intent` parity is accurate.
