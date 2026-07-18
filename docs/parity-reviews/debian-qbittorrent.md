# Parity review: `debian/qbittorrent`

## Scope and decision

- Evidence key: `debian/qbittorrent`
- Tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`
- Decision: `implemented` for `ubuntu-009`; `superseded` for `ubuntu-024`
- Parity level: `intent`
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`
- Verification report: `docs/evidence-verification/debian-qbittorrent.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-009` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:009` | Added the qBittorrent PPA, installed `qbittorrent`, and optionally wrote a desktop entry. | `implemented` |
| `ubuntu-024` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:024` | Installed the `utorrent` Snap package. | `superseded` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `qbittorrent`; distribution package `qbittorrent`
- Package source and release channel: each target's configured signed distribution APT repositories; no PPA or Snap store is added
- Verification binaries: `qbittorrent`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | qBittorrent used an external PPA; uTorrent used Snap. | Installs qBittorrent from the maintained distribution package channel. | The qBittorrent capability is retained without either external PPA or Snap-store dependency. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | The qBittorrent action could write a user desktop entry. | Does not write user desktop files. | Desktop integration is package-managed rather than installer-authored. |
| Firewall/network exposure | No firewall or listening-service action. | No firewall or listening-service action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | Added a PPA or depended on the Snap store. | Does not add either third-party channel. | The active contract intentionally removes unreviewed repository/store side effects. |

## Reviewer conclusion

The active qBittorrent module is an exact capability replacement for the
legacy qBittorrent action and a reviewed supported BitTorrent-client
supersession for the legacy uTorrent Snap action. The accepted artifact proves
clean and repeat installation on every declared target. No service, firewall,
credential, or data contract exists in either preserved action; package-managed
desktop integration replaces the optional hand-written desktop file. `intent`
parity accurately records both decisions.
