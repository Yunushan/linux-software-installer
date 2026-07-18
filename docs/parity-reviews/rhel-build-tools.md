# Parity review: `rhel/build-tools`

## Scope and decision

- Evidence key: `rhel/build-tools`
- Tested commit: `f59c5765b5e68ba4e074331a1b494a1bfdbcb125`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29648435978](https://github.com/Yunushan/linux-software-installer/actions/runs/29648435978), artifact digest `sha256:e9b7e22c95106d4e99fe8bff465e69c78afbb70b3025458fa4380dd5937bca64`
- Verification report: `docs/evidence-verification/rhel-build-tools.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `rhel-almalinux-8-004-gcc` | `legacy/rhel-family/AlmaLinux-8/scripts/4-Gcc.sh` | Offered DNF GCC 8.5 or a mutable upstream source build. | `implemented` |
| `rhel-almalinux-8-005-gplusplus` | `legacy/rhel-family/AlmaLinux-8/scripts/5-G++.sh` | Installed `gcc-c++` with DNF. | `implemented` |
| `rhel-almalinux-8-006-cmake` | `legacy/rhel-family/AlmaLinux-8/scripts/6-Cmake.sh` | Offered DNF CMake or classic Snap CMake. | `implemented` |
| `rhel-centos-6-004-gcc` | `legacy/rhel-family/Centos-6/scripts/4-Gcc.sh` | Installed GCC with YUM. | `implemented` |
| `rhel-centos-6-005-gplusplus` | `legacy/rhel-family/Centos-6/scripts/5-G++.sh` | Installed `gcc-c++` with YUM. | `implemented` |
| `rhel-centos-6-006-cmake` | `legacy/rhel-family/Centos-6/scripts/6-Cmake.sh` | Installed CMake with YUM. | `implemented` |
| `rhel-centos-7-004-gcc` | `legacy/rhel-family/Centos-7/scripts/4-Gcc.sh` | Offered Development Tools/GCC 4.8 or a mutable upstream source build. | `implemented` |
| `rhel-centos-7-005-gplusplus` | `legacy/rhel-family/Centos-7/scripts/5-G++.sh` | Installed `gcc-c++` with YUM. | `implemented` |
| `rhel-centos-7-006-cmake` | `legacy/rhel-family/Centos-7/scripts/6-Cmake.sh` | Offered YUM CMake or Snap after package and service mutations. | `implemented` |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Module and packages: `build-tools`; `gcc`, `gcc-c++`, `make`, `cmake`, and `pkgconf-pkg-config`
- Package source and release channel: configured signed DNF repositories; no source download, EPEL, or Snap store is added
- Verification binaries: `gcc`, `g++`, `make`, `cmake`, and `pkg-config`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Used YUM/DNF, and some scripts offered scraped upstream source builds, EPEL, or Snap. | Installs the package-managed toolchain from configured signed DNF repositories. | Preserves the supported compiler and CMake outcomes without mutable upstream URLs or third-party package channels. |
| Service lifecycle | The CentOS 7 Snap route enabled `snapd.socket`. | No service is enabled. | Build tools do not require a running service. |
| Configuration files/defaults | The CentOS 7 Snap route wrote profile-path and symlink changes. | No configuration files are written. | Avoids global shell-path mutation. |
| Firewall/network exposure | No firewall or listener action; optional source and Snap routes downloaded from external channels. | Package-manager network access only during installation. | No extra listener or package-channel exposure. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | Some routes removed packages before switching channels. | Does not remove alternatives. | Avoids destructive package switching. |
| Unsupported or unsafe legacy side effects | Mutable source compilation, Snap installation, EPEL enablement, package removal, `snapd.socket`, and profile/symlink changes. | None of those are retained. | The active contract is deterministic, repeatable, and non-destructive. |

## Reviewer conclusion

The active module cleanly and repeatedly installs the complete distribution build
toolchain on both supported RHEL-family targets. It safely replaces the useful
compiler, C++ compiler, Make, CMake, and pkg-config outcomes for all nine legacy
rows; `intent` parity is accurate.
