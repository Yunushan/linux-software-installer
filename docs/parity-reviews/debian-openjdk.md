# Parity review: `debian/openjdk`

- Evidence key: `debian/openjdk`; tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`.
- Decision and parity: `implemented` / `intent`.
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`.
- Verification report: `docs/evidence-verification/debian-openjdk.json`.

| Legacy ID | Immutable source locator | Legacy outcome | Active decision |
| --- | --- | --- | --- |
| `ubuntu-121` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:121` | Added the WebUpd8 PPA and installed Oracle Java 8. | `implemented` |
| `ubuntu-122` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:122` | Added the Linux Uprising PPA and installed Oracle Java 11. | `implemented` |

The active module repeatedly installs and verifies the distribution-supported default OpenJDK on Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64. It deliberately omits both obsolete PPAs and fixed Oracle JDK pins. The maintained Java/Javac development-kit intent is preserved; `intent` parity is accurate and does not claim Java 8 or Java 11 compatibility.
