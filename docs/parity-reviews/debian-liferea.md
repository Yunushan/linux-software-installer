# Parity review: `debian/liferea`

- Evidence key: `debian/liferea`; tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`.
- Verification report: `docs/evidence-verification/debian-liferea.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-111` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:111` | Added the Ubuntu Handbook PPA, refreshed APT, and installed `liferea`. | `implemented` |

The active module repeatedly installs and verifies Liferea on Debian 12, Ubuntu
24.04, and Ubuntu 26.04 x86_64. It deliberately omits the legacy PPA and retains
only the feed-reader installation intent. `intent` parity is accurate.
