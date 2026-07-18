# Parity review: `debian/qt`

- Evidence key: `debian/qt`; tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`.
- Verification report: `docs/evidence-verification/debian-qt.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-045` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:045` | Downloaded and executed Qt's unpinned HTTP online installer, then optionally created a per-user desktop entry. | `implemented` |

The active module repeatedly installs and verifies Qt Creator and Qt 6 base development tools on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64 from supported distribution repositories. It deliberately omits the legacy remote installer, unpinned Qt selection, and user desktop-file mutation. The maintained Qt development-tool intent is preserved; `intent` parity is accurate.
