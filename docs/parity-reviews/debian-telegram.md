# Parity review: `debian/telegram`

## Scope and decision

- Evidence key: `debian/telegram`
- Tested commit: `f59c5765b5e68ba4e074331a1b494a1bfdbcb125`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29648435978](https://github.com/Yunushan/linux-software-installer/actions/runs/29648435978), artifact digest `sha256:e9b7e22c95106d4e99fe8bff465e69c78afbb70b3025458fa4380dd5937bca64`
- Verification report: `docs/evidence-verification/debian-telegram.json`

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-068` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:068` | Added the atareao Telegram PPA, installed Telegram, and optionally downloaded an HTTP icon and wrote a desktop entry. | `implemented` |

## Active replacement contract

- Supported target cell: `debian-12`
- Module and package: `telegram`; distribution package `telegram-desktop`
- Package source and release channel: Debian 12's configured signed APT repositories; no PPA is added
- Verification binary: `telegram-desktop`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Added a Telegram PPA. | Installs Debian's signed distribution package. | Preserves the desktop client without persistent third-party APT trust. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Could download an icon over HTTP and write a user desktop entry. | Does not write user desktop files. | Desktop integration and icons remain package-managed. |
| Firewall/network exposure | No firewall or listener action; optional icon download used HTTP. | No firewall or listener action. | No unauthenticated icon download. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | PPA addition, HTTP icon download, and hand-written launcher. | None of those are retained. | The active contract is deterministic and non-destructive. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies Telegram Desktop on
its exact supported Debian 12 target. It safely replaces the legacy client
installation intent; `intent` parity is accurate.
