# Parity review: `debian/python`

- Evidence key: `debian/python`; tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`.
- Verification report: `docs/evidence-verification/debian-python.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-067` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:067` | Downloaded and compiled a mutable latest Python 2, Python 3, or both into unmanaged paths. | `implemented` |

The active module repeatedly installs and verifies supported Python 3, pip, and virtual-environment support on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64. Python 2, source compilation, and global unmanaged installs are intentionally rejected. The maintained Python runtime and package-management intent is preserved; `intent` parity is accurate and does not claim Python 2 compatibility.
