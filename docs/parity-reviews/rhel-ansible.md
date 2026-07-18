# Parity review: `rhel/ansible`

## Scope and decision

- Evidence key: `rhel/ansible`
- Tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`
- Verification report: `docs/evidence-verification/rhel-ansible.json`

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `rhel-red-hat-enterprise-linux-8-035-ansible` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/35-Ansible.sh` | Offered Ansible through pip or DNF, removing the alternative installation first. | `implemented` |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Module and package: `ansible`; `ansible-core`
- Package source and release channel: configured signed DNF repositories; no PyPI installation is performed
- Verification binaries: `ansible`, `ansible-playbook`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Offered PyPI pip installation or the distribution package. | Installs distribution `ansible-core`. | Preserves supported automation tooling without an unpinned PyPI dependency. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | No configuration files were written. | No configuration files are written. | None. |
| Firewall/network exposure | No firewall or listener action; pip could fetch external packages. | Package-manager network access only during installation. | No added listener or unreviewed package index. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | Removed Ansible packages before pip installation, or uninstalled pip Ansible before DNF installation. | Does not remove an existing alternative. | Avoids destructive package switching. |
| Unsupported or unsafe legacy side effects | PyPI installation and package/pip removal. | None of those are retained. | The active contract is deterministic and non-destructive. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies Ansible Core on both
supported RHEL-family targets. It safely replaces the legacy automation-tooling intent;
`intent` parity is accurate.
