# Parity review: `debian/konversation`

- Evidence key: `debian/konversation`; tested commit: `739dd664383221912ab00c18e32e762743c8748f`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 30838575507](https://github.com/Yunushan/linux-software-installer/actions/runs/30838575507), artifact digest `sha256:f8120aa9eb93ba6878a0e732b29b17218cef6ae1a78bcb981563dc59c9f91852`.
- Verification report: `docs/evidence-verification/debian-konversation.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-074` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:074` | Installed Snap and the Konversation Snap package, optionally creating a desktop file. | `implemented` |

The active module repeatedly installs and verifies Konversation on Debian 12,
Ubuntu 24.04, and Ubuntu 26.04 x86_64 from signed distribution repositories.
It removes the Snap and user-launcher side effects while preserving the
IRC-client intent. `intent` parity is accurate.
