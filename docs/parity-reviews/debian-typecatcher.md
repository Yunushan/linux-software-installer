# Parity review: `debian/typecatcher`

- Evidence key: `debian/typecatcher`; tested commit: `739dd664383221912ab00c18e32e762743c8748f`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 30838575507](https://github.com/Yunushan/linux-software-installer/actions/runs/30838575507), artifact digest `sha256:f8120aa9eb93ba6878a0e732b29b17218cef6ae1a78bcb981563dc59c9f91852`.
- Verification report: `docs/evidence-verification/debian-typecatcher.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-112` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:112` | Added a PPA, installed TypeCatcher, and optionally created a desktop entry. | `implemented` |

The active module repeatedly installs and verifies TypeCatcher on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64 from signed distribution repositories. It deliberately omits the legacy PPA and desktop-file mutation. The desktop font-browser intent is preserved; `intent` parity is accurate.
