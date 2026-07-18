# Parity review: `debian/dvblast`

- Evidence key: `debian/dvblast`; tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`.
- Verification report: `docs/evidence-verification/debian-dvblast.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-157` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:157` | Scraped a current DVBlast source archive, downloaded and built it locally, then printed its version. | `implemented` |

The active module repeatedly installs and verifies DVBlast on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64 from signed distribution repositories. It deliberately omits remote archive scraping and source compilation. The transport-stream processing-tool intent is preserved; `intent` parity is accurate.
