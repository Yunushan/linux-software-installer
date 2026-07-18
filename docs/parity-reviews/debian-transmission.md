# Pre-admission parity review: `debian/transmission`

## Scope and status

- Evidence key: `debian/transmission`
- Tested commit: `0273ed24bd25e4a182c5755ac48a5d515d285439`
- Real-install evidence: [run 29656979377](https://github.com/Yunushan/linux-software-installer/actions/runs/29656979377), aggregate artifact digest `sha256:02659dc185102d018d091288acc41c24955a2d446f995a627fde93edaf792d32`
- Verification report: `docs/evidence-verification/debian-transmission.json`
- Parity level on admission: `intent`
- Admission status: **pending disposable-VM/systemd attestation**. This review is not an accepted-evidence record.

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome |
| --- | --- | --- |
| `ubuntu-026` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:026` | Added `ppa:transmissionbt/ppa`, installed Transmission packages including the daemon, and could write a user-specific CLI desktop entry. |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Packages: `transmission-gtk`, `transmission-cli`, `transmission-daemon`
- Package source: each target's configured signed distribution APT repositories; no PPA is added
- Verified binaries: `transmission-gtk`, `transmission-daemon`
- Service contract: `transmission-daemon`; the active installer does not start or enable it by default

## Behavioral comparison

| Concern | Legacy behavior | Active behavior | Decision and rationale |
| --- | --- | --- | --- |
| Package source | Added the Transmission PPA. | Uses distribution packages only. | Preserves the client-and-daemon capability without permanently changing APT trust. |
| Client and daemon | Installed a client, CLI, common package, and daemon. | Installs GTK client, CLI, and daemon packages. | Retains the maintained package-managed outcome. |
| Service lifecycle | Package installation could leave daemon behavior to package defaults. | Declares the daemon but performs no start or enable action. | Admission requires independent VM evidence for default and explicit service behavior. |
| RPC, downloads, and torrents | The menu installer did not configure an operator-owned workload. | Does not create torrents, change download directories, or expose/configure RPC. | Network exposure and workload configuration remain administrator-owned. |
| Desktop entry | Could write `/home/$superuser/Desktop/transmission.desktop`. | Does not create a user desktop file. | Avoids assuming a user home or mutating user-specific launcher state. |

## Pending admission condition

The clean-install artifact proves the declared package and binary contract on
all three current Debian-family targets. It does **not** prove service behavior.
Before `ubuntu-026` can be marked implemented, an external single-use VM run
must provide accepted evidence for `transmission-daemon`'s default state and
the explicit requested systemd action on each target, including the required
provisioning and destruction attestation.
