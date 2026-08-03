# Parity review: `debian/python`

- Evidence key: `debian/python`; tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`.
- Verification report: `docs/evidence-verification/debian-python.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-067` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:067` | Downloaded and compiled a mutable latest Python 2, Python 3, or both into unmanaged paths. | `implemented` |

The active module repeatedly installs and verifies supported Python 3, pip, and virtual-environment support on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64. Python 2, source compilation, and global unmanaged installs are intentionally rejected. The maintained Python runtime and package-management intent is preserved; `intent` parity is accurate and does not claim Python 2 compatibility.
