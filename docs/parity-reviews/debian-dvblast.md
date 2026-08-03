# Parity review: `debian/dvblast`

- Evidence key: `debian/dvblast`; tested commit: `739dd664383221912ab00c18e32e762743c8748f`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 30838575507](https://github.com/Yunushan/linux-software-installer/actions/runs/30838575507), artifact digest `sha256:f8120aa9eb93ba6878a0e732b29b17218cef6ae1a78bcb981563dc59c9f91852`.
- Verification report: `docs/evidence-verification/debian-dvblast.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-157` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:157` | Scraped a current DVBlast source archive, downloaded and built it locally, then printed its version. | `implemented` |

The active module repeatedly installs and verifies DVBlast on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64 from signed distribution repositories. It deliberately omits remote archive scraping and source compilation. The transport-stream processing-tool intent is preserved; `intent` parity is accurate.
