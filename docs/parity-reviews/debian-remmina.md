# Parity review: `debian/remmina`

- Evidence key: `debian/remmina`; tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`.
- Verification report: `docs/evidence-verification/debian-remmina.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-154` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:154` | Added the Remmina PPA, installed Remmina plus selected plugins, and optionally created a desktop entry. | `implemented` |

The active module repeatedly installs and verifies Remmina on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64 from signed distribution repositories. It deliberately omits the legacy PPA, selected plugin set, and desktop-file mutation. The remote-desktop-client intent is preserved; `intent` parity is accurate.
