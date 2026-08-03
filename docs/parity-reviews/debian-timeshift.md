# Parity review: `debian/timeshift`

- Evidence key: `debian/timeshift`; tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`.
- Verification report: `docs/evidence-verification/debian-timeshift.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-062` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:062` | Added the Teejee PPA, installed `timeshift`, and optionally created a per-user desktop entry. | `implemented` |

The active module repeatedly installs and verifies Timeshift on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64 from signed distribution repositories. It deliberately omits the legacy PPA and desktop-file mutation, and does not create, schedule, or restore snapshots. The tool-installation intent is preserved; `intent` parity is accurate.
