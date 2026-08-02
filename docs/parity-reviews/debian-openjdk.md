# Parity review: `debian/openjdk`

- Evidence key: `debian/openjdk`; tested commit: `4feb21e1ae162f5d9dbdd98df2a05aad4ed3c632`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 30744748151](https://github.com/Yunushan/linux-software-installer/actions/runs/30744748151), artifact digest `sha256:9b19da4e4779dd10071a94fd5f137f153fadbe335074b5a59e48de18028b82d5`.
- Verification report: `docs/evidence-verification/debian-openjdk.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-121` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:121` | Added the WebUpd8 PPA and installed Oracle Java 8. | `implemented` |
| `ubuntu-122` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:122` | Added the Linux Uprising PPA and installed Oracle Java 11. | `implemented` |

The active module repeatedly installs and verifies the distribution-supported default OpenJDK on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64. It deliberately omits both obsolete PPAs and fixed Oracle JDK pins. The maintained Java/Javac development-kit intent is preserved; `intent` parity is accurate and does not claim Java 8 or Java 11 compatibility.
