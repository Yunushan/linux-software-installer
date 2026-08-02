# Parity review: `debian/python`

- Evidence key: `debian/python`; tested commit: `4feb21e1ae162f5d9dbdd98df2a05aad4ed3c632`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 30744748151](https://github.com/Yunushan/linux-software-installer/actions/runs/30744748151), artifact digest `sha256:9b19da4e4779dd10071a94fd5f137f153fadbe335074b5a59e48de18028b82d5`.
- Verification report: `docs/evidence-verification/debian-python.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-067` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:067` | Downloaded and compiled a mutable latest Python 2, Python 3, or both into unmanaged paths. | `implemented` |

The active module repeatedly installs and verifies supported Python 3, pip, and virtual-environment support on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64. Python 2, source compilation, and global unmanaged installs are intentionally rejected. The maintained Python runtime and package-management intent is preserved; `intent` parity is accurate and does not claim Python 2 compatibility.
