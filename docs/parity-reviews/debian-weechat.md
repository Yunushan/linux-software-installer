# Parity review: `debian/weechat`

- Evidence key: `debian/weechat`; tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`.
- Verification report: `docs/evidence-verification/debian-weechat.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-072` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:072` | Imported a key through the retired SKS keyserver network, added the Xenial WeeChat repository, and installed `weechat`. | `implemented` |

The active module repeatedly installs and verifies WeeChat on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64 from signed distribution repositories. It deliberately omits the legacy key import and version-pinned Xenial repository. The terminal IRC-client intent is preserved; `intent` parity is accurate.
