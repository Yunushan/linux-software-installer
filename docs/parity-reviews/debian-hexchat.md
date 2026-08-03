# Parity review: `debian/hexchat`

- Evidence key: `debian/hexchat`; tested commit: `739dd664383221912ab00c18e32e762743c8748f`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 30838575507](https://github.com/Yunushan/linux-software-installer/actions/runs/30838575507), artifact digest `sha256:f8120aa9eb93ba6878a0e732b29b17218cef6ae1a78bcb981563dc59c9f91852`.
- Verification report: `docs/evidence-verification/debian-hexchat.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-095` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:095` | Installed Snap and then the HexChat Snap package, optionally creating a desktop file. | `implemented` |

The active module repeatedly installs and verifies HexChat on Debian 12,
Ubuntu 24.04, and Ubuntu 26.04 x86_64 without the Snap runtime or user desktop
file. It retains the graphical IRC-client intent; `intent` parity is accurate.
