# Parity review: `debian/remmina`

- Evidence key: `debian/remmina`; tested commit: `4feb21e1ae162f5d9dbdd98df2a05aad4ed3c632`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 30744748151](https://github.com/Yunushan/linux-software-installer/actions/runs/30744748151), artifact digest `sha256:9b19da4e4779dd10071a94fd5f137f153fadbe335074b5a59e48de18028b82d5`.
- Verification report: `docs/evidence-verification/debian-remmina.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-154` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:154` | Added the Remmina PPA, installed Remmina plus selected plugins, and optionally created a desktop entry. | `implemented` |

The active module repeatedly installs and verifies Remmina on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64 from signed distribution repositories. It deliberately omits the legacy PPA, selected plugin set, and desktop-file mutation. The remote-desktop-client intent is preserved; `intent` parity is accurate.
