# Parity review: `rhel/ruby`

## Scope and decision

- Evidence key: `rhel/ruby`
- Tested commit: `4feb21e1ae162f5d9dbdd98df2a05aad4ed3c632`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30744748151](https://github.com/Yunushan/linux-software-installer/actions/runs/30744748151), artifact digest `sha256:9b19da4e4779dd10071a94fd5f137f153fadbe335074b5a59e48de18028b82d5`
- Verification report: `docs/evidence-verification/rhel-ruby.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `rhel-almalinux-8-042-ruby` | `legacy/rhel-family/AlmaLinux-8/scripts/42-Ruby.sh` | Offered official DNF Ruby or classic Snap Ruby. | `implemented` |
| `rhel-red-hat-enterprise-linux-8-020-ruby` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/20-Ruby.sh` | Offered DNF Ruby after Snap removal or classic Snap Ruby after DNF removal. | `implemented` |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Module and packages: `ruby`; distribution package `ruby`
- Package source and release channel: configured signed DNF repositories; no Snap store is added
- Verification binaries: `ruby`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Offered DNF or classic Snap Ruby. | Installs distribution `ruby`. | Preserves the official-package path without Snap-store dependency. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | No configuration written. | No configuration written. | None. |
| Firewall/network exposure | No firewall or listener action. | No firewall or listener action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | The RHEL script removed the alternative Ruby package. | Does not remove alternatives. | Avoids destructive package switching. |
| Unsupported or unsafe legacy side effects | Optional Snap and removal of existing packages. | Does not add Snap or remove packages. | The active contract is deterministic and non-destructive. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies Ruby on both
supported RHEL-family targets. It safely replaces the useful official-package
outcome of both legacy scripts; `intent` parity is accurate.
