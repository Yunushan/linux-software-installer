# Parity review: `debian/python`

- Evidence key: `debian/python`; tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`.
- Verification report: `docs/evidence-verification/debian-python.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-067` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:067` | Downloaded and compiled a mutable latest Python 2, Python 3, or both into unmanaged paths. | `implemented` |

The active module repeatedly installs and verifies supported Python 3, pip, and virtual-environment support on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64. Python 2, source compilation, and global unmanaged installs are intentionally rejected. The maintained Python runtime and package-management intent is preserved; `intent` parity is accurate and does not claim Python 2 compatibility.
