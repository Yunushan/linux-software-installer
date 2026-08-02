# Parity review: `debian/magic-wormhole`

- Evidence key: `debian/magic-wormhole`; tested commit: `4feb21e1ae162f5d9dbdd98df2a05aad4ed3c632`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 30744748151](https://github.com/Yunushan/linux-software-installer/actions/runs/30744748151), artifact digest `sha256:9b19da4e4779dd10071a94fd5f137f153fadbe335074b5a59e48de18028b82d5`.
- Verification report: `docs/evidence-verification/debian-magic-wormhole.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-094` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:094` | Installed obsolete Python 2 build dependencies and used `pip` to install Magic Wormhole. | `implemented` |

The active module repeatedly installs and verifies Magic Wormhole on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64 from signed distribution repositories. It deliberately omits the obsolete Python 2 and unmanaged `pip` installation path. The authenticated peer-to-peer file-transfer tool intent is preserved; `intent` parity is accurate.
