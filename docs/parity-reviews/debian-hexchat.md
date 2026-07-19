# Parity review: `debian/hexchat`

- Evidence key: `debian/hexchat`; tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`.
- Verification report: `docs/evidence-verification/debian-hexchat.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-095` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:095` | Installed Snap and then the HexChat Snap package, optionally creating a desktop file. | `implemented` |

The active module repeatedly installs and verifies HexChat on Debian 12,
Ubuntu 24.04, and Ubuntu 26.04 x86_64 without the Snap runtime or user desktop
file. It retains the graphical IRC-client intent; `intent` parity is accurate.
