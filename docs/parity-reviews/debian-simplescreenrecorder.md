# Parity review: `debian/simplescreenrecorder`

- Evidence key: `debian/simplescreenrecorder`; tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`.
- Verification report: `docs/evidence-verification/debian-simplescreenrecorder.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-080` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:080` | Added a PPA and installed SimpleScreenRecorder plus an i386 library, optionally creating a desktop entry. | `implemented` |

The active module repeatedly installs and verifies SimpleScreenRecorder on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64 from signed distribution repositories. It deliberately omits the legacy PPA, i386 library, and desktop-file mutation. The desktop screen-recording intent is preserved; `intent` parity is accurate.
