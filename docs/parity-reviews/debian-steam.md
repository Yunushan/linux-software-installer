# Parity review: `debian/steam`

## Scope and decision

- Evidence key: `debian/steam`
- Tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`
- Verification report: `docs/evidence-verification/debian-steam.json`

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-014` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:014` | Downloaded a mutable `steam.deb` with `wget`, installed it with `dpkg -i`, and optionally wrote a desktop entry for `/usr/bin/steam`. | `implemented` |

## Active replacement contract

- Supported target cell: `ubuntu-24-04`
- Module and package: `steam`; Ubuntu distribution package `steam-installer`
- Package source and release channel: Ubuntu 24.04's configured signed APT repositories; no vendor repository, raw package URL, or setup script is added
- Verification binary: `steam`, resolved from the package-managed `/usr/games/steam` launcher when it is not on the non-interactive PATH
- Service behavior: none
- Deliberate prerequisite: the caller must explicitly acknowledge `i386` multiarch with `--allow-foreign-architecture i386`; the module then uses `dpkg --add-architecture i386` before its single metadata refresh

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Downloaded an unpinned mutable `steam.deb` directly from a CDN and installed it outside APT's dependency solver. | Installs Ubuntu's signed `steam-installer` package after explicit i386 acknowledgement. | Preserves the Steam client-installation intent while using the target distribution's signed repository and dependency solver. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Could write a hand-made desktop entry under the invoking user's Desktop and assumed `/usr/bin/steam`. | Does not write user files; package-managed desktop integration and the actual `/usr/games/steam` launcher are retained. | Avoids unsafe per-user mutation and validates the real launcher path. |
| Firewall/network exposure | No listener configuration; later Steam use contacts Steam services. | No listener configuration; later Steam sign-in, client bootstrap and game downloads remain user-controlled Steam activity. | The installer does not silently initiate account or game-content actions. |
| Credentials and secrets | None in the script. | None. | Steam account sign-in is never supplied to or logged by this installer. |
| Data creation, migration, or deletion | Downloaded a local package file and could create a desktop entry; Steam data was managed after launch. | Performs only package-manager state changes and Debian multiarch configuration. | No user Steam library, account data, or game content is created, migrated, or deleted by the installer. |
| Unsupported or unsafe legacy side effects | Mutable unauthenticated-at-install-time package URL, raw `dpkg` installation, and hand-written launcher. | None of those are retained. | The active contract is deterministic, explicitly multiarch-gated, and non-destructive beyond the reviewed package-manager configuration. |

## Reviewer conclusion

The verified Ubuntu 24.04 x86_64 contract installs and repeats the package
transaction successfully with explicit i386 acknowledgment, preserves the
Steam client-installation outcome, and verifies the real package-managed
launcher. It does not claim game execution, account sign-in, or content
downloads. `intent` parity is therefore accurate for the exact supported cell.
