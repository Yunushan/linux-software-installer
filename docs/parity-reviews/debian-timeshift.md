# Parity review: `debian/timeshift`

- Evidence key: `debian/timeshift`; tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`.
- Verification report: `docs/evidence-verification/debian-timeshift.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-062` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:062` | Added the Teejee PPA, installed `timeshift`, and optionally created a per-user desktop entry. | `implemented` |

The active module repeatedly installs and verifies Timeshift on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64 from signed distribution repositories. It deliberately omits the legacy PPA and desktop-file mutation, and does not create, schedule, or restore snapshots. The tool-installation intent is preserved; `intent` parity is accurate.
