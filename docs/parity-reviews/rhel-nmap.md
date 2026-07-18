# Parity review: `rhel/nmap`

## Scope and decision

- Evidence key: `rhel/nmap`
- Tested commit: `f7b772a72fa8c543cb84f79db0473cf5ad05daf5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29640717432](https://github.com/Yunushan/linux-software-installer/actions/runs/29640717432), artifact digest `sha256:e744fab69651ad0d2adce755e7a65da1191822af6524d44b8b1d1d259140d477`
- Verification report: `docs/evidence-verification/rhel-nmap.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `rhel-almalinux-8-011-nmap` | `legacy/rhel-family/AlmaLinux-8/scripts/11-Nmap.sh#script` | Installed `nmap` through DNF. | `implemented` |
| `rhel-centos-7-011-nmap` | `legacy/rhel-family/Centos-7/scripts/11-Nmap.sh#script` | Offered a distribution package or a dynamically discovered latest RPM. | `implemented` |
| `rhel-red-hat-enterprise-linux-8-008-nmap` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/8-Nmap.sh#script` | Offered distribution package, downloaded RPM, source build, or Snap alternatives. | `implemented` |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Module and packages: `nmap`; distribution package `nmap`
- Package source and release channel: each target's configured signed distribution DNF repositories
- Verification binaries: `nmap`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Included distribution package choices alongside dynamic RPM, source-build, or Snap paths. | Installs the distribution `nmap` package only. | Retains the reviewed official-package outcome on supported current RHEL-family targets. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | No configuration files were written. | No configuration files are written. | None. |
| Firewall/network exposure | No firewall or listening-service action. | No firewall or listening-service action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Dynamic RPM download, source compilation, and Snap alternatives. | None. | Removed in favor of the signed distribution package channel. |

## Reviewer conclusion

Each preserved RHEL script included the distribution-package Nmap capability;
the active module provides that outcome with verified clean and repeat installs
on AlmaLinux 9.8 and Rocky Linux 9.8. Downloaded, compiled, and Snap variants
are intentionally outside the supported contract. `intent` parity is accurate.
