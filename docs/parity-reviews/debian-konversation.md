# Parity review: `debian/konversation`

- Evidence key: `debian/konversation`; tested commit: `4feb21e1ae162f5d9dbdd98df2a05aad4ed3c632`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 30744748151](https://github.com/Yunushan/linux-software-installer/actions/runs/30744748151), artifact digest `sha256:9b19da4e4779dd10071a94fd5f137f153fadbe335074b5a59e48de18028b82d5`.
- Verification report: `docs/evidence-verification/debian-konversation.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-074` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:074` | Installed Snap and the Konversation Snap package, optionally creating a desktop file. | `implemented` |

The active module repeatedly installs and verifies Konversation on Debian 12,
Ubuntu 24.04, and Ubuntu 26.04 x86_64 from signed distribution repositories.
It removes the Snap and user-launcher side effects while preserving the
IRC-client intent. `intent` parity is accurate.
