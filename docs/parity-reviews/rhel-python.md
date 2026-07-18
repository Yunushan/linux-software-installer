# Parity review: `rhel/python`

## Scope and decision

- Evidence key: `rhel/python`
- Tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`
- Verification report: `docs/evidence-verification/rhel-python.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `rhel-almalinux-9-004-python` | `legacy/rhel-family/AlmaLinux-9/scripts/4-Python.sh` | Downloaded and compiled Python 2.7.18 into `/usr/local`. | `implemented` |
| `rhel-red-hat-enterprise-linux-8-003-python` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/3-Python.sh` | Selected Python 2, 3.6–3.9 packages or compiled Python 3.10.3. | `implemented` |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Module and packages: `python`; `python3`, `python3-pip`
- Package source and release channel: configured signed DNF repositories; no source tarball or external repository is added
- Verification binaries: `python3`, `pip3`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Downloaded a Python 2.7 tarball, or selected legacy DNF versions and a Python 3.10 source build. | Installs the maintained distribution Python 3 toolchain. | Preserves the supported interpreter and package-management outcome without mutable source downloads. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | No configuration files were written. | No configuration files are written. | None. |
| Firewall/network exposure | No firewall or listener action; source routes downloaded external tarballs. | Package-manager network access only during installation. | No added listener or arbitrary source download. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | Source routes wrote into `/root/Downloads` and `/usr/local`. | Installs package-managed files only. | Avoids unmanaged global installation paths. |
| Unsupported or unsafe legacy side effects | Python 2, obsolete version selection, mutable source compilation, and global `/usr/local` writes. | None of those are retained. | The active contract is deterministic and maintainable. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies a supported Python 3
interpreter and pip on both RHEL-family targets. It safely replaces the useful runtime
and package-management intent of both legacy scripts; `intent` parity is accurate.
