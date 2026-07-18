# Parity review: `debian/liferea`

- Evidence key: `debian/liferea`; tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`.
- Verification report: `docs/evidence-verification/debian-liferea.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-111` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:111` | Added the Ubuntu Handbook PPA, refreshed APT, and installed `liferea`. | `implemented` |

The active module repeatedly installs and verifies Liferea on Debian 12, Ubuntu
24.04, and Ubuntu 26.04 x86_64. It deliberately omits the legacy PPA and retains
only the feed-reader installation intent. `intent` parity is accurate.
