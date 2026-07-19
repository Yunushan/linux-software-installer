# Parity review: `rhel/openjdk`

## Scope and decision

- Evidence key: `rhel/openjdk`
- Tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`
- Verification report: `docs/evidence-verification/rhel-openjdk.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `rhel-almalinux-8-023-openjdk` | `legacy/rhel-family/AlmaLinux-8/scripts/23-Openjdk.sh` | Selected OpenJDK 8, 11, or 17 after removing other JDK packages. | `implemented` |
| `rhel-centos-7-023-openjdk` | `legacy/rhel-family/Centos-7/scripts/23-Openjdk.sh` | Selected OpenJDK 6–11 or downloaded an Oracle JDK 17 RPM after removing Java packages. | `implemented` |
| `rhel-red-hat-enterprise-linux-8-014-openjdk` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/14-Openjdk.sh` | Selected OpenJDK 8, 11, or 17 after removing other JDK packages. | `implemented` |
| `rhel-red-hat-enterprise-linux-9-010-openjdk` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-9/scripts/10-Openjdk.sh` | Selected OpenJDK 8, 11, or 17 after removing other JDK packages. | `implemented` |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Module and package: `openjdk`; `java-17-openjdk-devel`
- Package source and release channel: configured signed DNF repositories; no Oracle RPM or external repository is added
- Verification binaries: `java`, `javac`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Installed selected historical OpenJDK releases; CentOS 7 could download an Oracle RPM. | Installs supported distribution OpenJDK 17. | Preserves a maintained Java development-kit outcome without an unpinned external RPM. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | No configuration files were written. | No configuration files are written. | None. |
| Firewall/network exposure | No firewall or listener action; the Oracle route fetched an external RPM. | Package-manager network access only during installation. | No added listener or arbitrary external RPM download. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | Removed alternative Java packages, and CentOS 7 used broad `java*` removal. | Does not remove existing JDK packages. | Avoids destructive runtime switching. |
| Unsupported or unsafe legacy side effects | EOL version selection, wholesale Java removal, and unverified Oracle RPM installation. | None of those are retained. | The active contract is deterministic and non-destructive. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies OpenJDK 17 on both
supported RHEL-family targets. It safely replaces the useful Java/Javac development
kit outcome of all four legacy scripts; `intent` parity is accurate.
