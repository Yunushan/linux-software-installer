# Parity review: `debian/playonlinux`

## Scope and decision

- Evidence key: `debian/playonlinux`
- Tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`
- Verification report: `docs/evidence-verification/debian-playonlinux.json`

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-031` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:031` | Added an HTTP key with `apt-key`, added the PlayOnLinux Xenial repository, installed PlayOnLinux, and optionally wrote a desktop entry. | `implemented` |

## Active replacement contract

- Supported target cell: `ubuntu-24-04`
- Module and package: `playonlinux`; distribution package `playonlinux`
- Package source and release channel: Ubuntu 24.04's configured signed APT repositories; no third-party repository or key is added
- Verification binary: `playonlinux`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Added an HTTP-fetched key with deprecated `apt-key` and a Xenial repository. | Installs Ubuntu's signed distribution package. | Preserves the application without persistent third-party APT trust. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Could write a user desktop entry. | Does not write user desktop files. | Desktop integration remains package-managed. |
| Firewall/network exposure | No firewall or listener action. | No firewall or listener action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | HTTP key download, deprecated global keyring mutation, obsolete repository, and hand-written launcher. | None of those are retained. | The active contract is deterministic and non-destructive. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies PlayOnLinux on its
exact supported Ubuntu 24.04 target. It safely replaces the legacy application
installation intent; `intent` parity is accurate.
