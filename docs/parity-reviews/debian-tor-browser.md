# Parity review: `debian/tor-browser`

## Scope and decision

- Evidence key: `debian/tor-browser`
- Tested commit: `6f653cacfba0ee08ee4ecbf4b6e09c4cc2be5360`
- Decision: `implemented`
- Parity level: `intent`
- Accepted module evidence: [run 29693350772](https://github.com/Yunushan/linux-software-installer/actions/runs/29693350772), aggregate artifact digest `sha256:b6c0c2e1dbeb2e4a64ea2f13698b1134cf4a6f41bea6d444d808c3db83818fe5`
- First-run payload evidence: [artifact 8444684378](https://github.com/Yunushan/linux-software-installer/actions/runs/29693351535/artifacts/8444684378), digest `sha256:8f747b53a0955601b3f09c3b85bbb84ea959ce8d8db120f3f6469837a5ac3c14`; its recorded archive signature chains to Tor Browser's primary fingerprint `EF6E286DDA85EA2A4BA7DE684E2C6E8793298290`
- Verification report: `docs/evidence-verification/debian-tor-browser.json`

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-020` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:020` | Scraped a mutable Tor Browser download URL, downloaded and extracted an architecture-specific archive, and optionally wrote a user Desktop launcher. | `implemented` |

## Active replacement contract

- Supported target cell: `ubuntu-24-04` x86_64
- Module and package: `tor-browser`; Ubuntu's signed `torbrowser-launcher` package
- Package source and release channel: Ubuntu 24.04's configured signed APT repositories; the launcher obtains the browser payload
- Verification binary: `torbrowser-launcher`
- First-run proof: a disposable unprivileged user downloaded the browser, the launcher verified its release signature, extracted it, and handed off to `start-tor-browser.desktop`. The captured proof was independently verified against the Tor Browser primary signing fingerprint above.
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Scraped mutable directory listings and downloaded an unsigned-at-install-time archive with `wget`. | Installs Ubuntu's signed launcher package; its first run downloads the current Tor Browser archive and signature, verifies the signature, then extracts it. | Preserves the browser-installation intent while adding an authenticated payload boundary. |
| Architecture and target | Had separate x86_64 and 32-bit branches for Ubuntu 16.04. | Supports only the evidence-backed Ubuntu 24.04 x86_64 cell. | No unsupported legacy release or architecture is claimed. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Could write a hand-made Desktop launcher into the invoking user's home directory. | Uses the launcher's per-user application data and package-managed desktop integration. | Avoids a brittle user-specific Desktop-file mutation. |
| Firewall/network exposure | Downloaded an archive during installation; later browser use was user-controlled. | The evidence run downloads and verifies the browser payload; no listener or firewall change is made. | The proof does not claim a Tor network connection, browsing session, or anonymity outcome. |
| Credentials and secrets | None in the script. | None in the installer or evidence. | No user credentials, accounts, or Tor identity are supplied or logged. |
| Data creation, migration, or deletion | Created a temporary archive and extracted browser directory under a user Downloads path. | Creates launcher-managed per-user browser data at first run; the evidence job deletes its disposable home and retains only sanitized metadata, checksums, logs, and the start-entrypoint copy. | No user profile migration or deletion is claimed. |
| Unsupported or unsafe legacy side effects | Mutable URL scraping, unauthenticated extraction, and a hand-written Desktop file. | None of those side effects are retained. | The active path fails closed on missing signature verification and keeps browser execution under the user's control. |

## Reviewer conclusion

The verified exact-cell contract repeatedly installs the Ubuntu launcher package.
The independently inspected first-run artifact proves that the launcher retrieved a
Tor Browser release, verified its signature against the expected primary signing
key, extracted the browser, and reached its launch entrypoint under a disposable
unprivileged user. It intentionally does not claim Tor-network connectivity,
browser use, or legacy Ubuntu 16.04/32-bit support. `intent` parity is therefore
accurate for Ubuntu 24.04 x86_64.
