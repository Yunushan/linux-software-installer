# Parity review: `debian/liferea`

- Evidence key: `debian/liferea`; tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`.
- Verification report: `docs/evidence-verification/debian-liferea.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-111` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:111` | Added the Ubuntu Handbook PPA, refreshed APT, and installed `liferea`. | `implemented` |

The active module repeatedly installs and verifies Liferea on Debian 12, Ubuntu
24.04, and Ubuntu 26.04 x86_64. It deliberately omits the legacy PPA and retains
only the feed-reader installation intent. `intent` parity is accurate.
