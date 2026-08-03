# Parity review: `debian/python`

- Evidence key: `debian/python`; tested commit: `739dd664383221912ab00c18e32e762743c8748f`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 30838575507](https://github.com/Yunushan/linux-software-installer/actions/runs/30838575507), artifact digest `sha256:f8120aa9eb93ba6878a0e732b29b17218cef6ae1a78bcb981563dc59c9f91852`.
- Verification report: `docs/evidence-verification/debian-python.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-067` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:067` | Downloaded and compiled a mutable latest Python 2, Python 3, or both into unmanaged paths. | `implemented` |

The active module repeatedly installs and verifies supported Python 3, pip, and virtual-environment support on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64. Python 2, source compilation, and global unmanaged installs are intentionally rejected. The maintained Python runtime and package-management intent is preserved; `intent` parity is accurate and does not claim Python 2 compatibility.
