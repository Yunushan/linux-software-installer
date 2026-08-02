# Parity review: `debian/stacer`

- Evidence key: `debian/stacer`; tested commit: `4feb21e1ae162f5d9dbdd98df2a05aad4ed3c632`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 30744748151](https://github.com/Yunushan/linux-software-installer/actions/runs/30744748151), artifact digest `sha256:9b19da4e4779dd10071a94fd5f137f153fadbe335074b5a59e48de18028b82d5`.
- Verification report: `docs/evidence-verification/debian-stacer.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-064` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:064` | Added the Stacer PPA, installed `stacer`, and optionally created a per-user desktop entry. | `implemented` |

The active module repeatedly installs and verifies Stacer on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64 from signed distribution repositories. It deliberately omits the legacy PPA and desktop-file mutation, and does not run cleanup or change services. The graphical maintenance-tool intent is preserved; `intent` parity is accurate.
