# Parity review: `debian/wings3d`

- Evidence key: `debian/wings3d`; tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`.
- Verification report: `docs/evidence-verification/debian-wings3d.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-096` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:096` | Downloaded and executed the unpinned Wings 3D HTTP installer, optionally creating a desktop entry. | `implemented` |

The active module repeatedly installs and verifies Wings 3D on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64 from signed distribution repositories. It deliberately omits the unpinned HTTP installer and desktop-file mutation. The 3D-modeling-tool intent is preserved; `intent` parity is accurate.
