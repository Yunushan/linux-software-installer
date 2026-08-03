# Parity review: `debian/openjdk`

- Evidence key: `debian/openjdk`; tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`.
- Verification report: `docs/evidence-verification/debian-openjdk.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-121` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:121` | Added the WebUpd8 PPA and installed Oracle Java 8. | `implemented` |
| `ubuntu-122` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:122` | Added the Linux Uprising PPA and installed Oracle Java 11. | `implemented` |

The active module repeatedly installs and verifies the distribution-supported default OpenJDK on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64. It deliberately omits both obsolete PPAs and fixed Oracle JDK pins. The maintained Java/Javac development-kit intent is preserved; `intent` parity is accurate and does not claim Java 8 or Java 11 compatibility.
