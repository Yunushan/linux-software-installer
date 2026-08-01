# Public-artifact provider audit

Review date: **2026-08-01**

This is a planning ledger for every remaining `public-artifact` row. It is not
an install guide and it does not authorize downloading any vendor binary. A
route can be promoted only when the normal provider contract has an exact
version, immutable artifact identity, vendor-authenticated signature or digest,
license/authentication boundary, supported-target guard, clean install, repeat
install, origin check and accepted external evidence.

| Legacy ID | Capability | Legacy artifact class | Required evidence before any provider work |
| --- | --- | --- | --- |
| `ubuntu-022` | Eclipse IDE | IDE archive/installer | Exact maintained Linux artifact, publisher signature or vendor digest, license/update behavior, and clean/repeat evidence. |
| `ubuntu-037` | WPS Office | Proprietary office-suite artifact | Exact vendor artifact and verification material, user-license/account boundary, update behavior, and clean/repeat evidence. |
| `ubuntu-057` | balenaEtcher | Desktop imaging utility artifact | Exact vendor artifact and verification material, privilege/device-write safety contract, and clean/repeat evidence. |
| `ubuntu-097` | MakeHuman | Upstream PPA/source route | The upstream recommends a PPA or source build rather than a maintained distribution package. Require a current immutable upstream artifact with publisher-authenticated verification material and clean/repeat evidence; do not automate the PPA or source build. |
| `ubuntu-099` | 4K Video Downloader | Proprietary media utility artifact | See [`4KDOWNLOAD_PROVIDER_AUDIT.md`](4KDOWNLOAD_PROVIDER_AUDIT.md); never transfer a user license or account authorization. |
| `ubuntu-100` | 4K YouTube to MP3 | Proprietary media utility artifact | See [`4KDOWNLOAD_PROVIDER_AUDIT.md`](4KDOWNLOAD_PROVIDER_AUDIT.md); require exact artifact verification and target evidence. |
| `ubuntu-102` | 4K Slideshow Maker | Proprietary media utility artifact | See [`4KDOWNLOAD_PROVIDER_AUDIT.md`](4KDOWNLOAD_PROVIDER_AUDIT.md); establish current vendor verification material first. |
| `ubuntu-103` | 4K Video to MP3 | Proprietary media utility artifact | See [`4KDOWNLOAD_PROVIDER_AUDIT.md`](4KDOWNLOAD_PROVIDER_AUDIT.md); preserve license, account and content authority outside the installer. |
| `ubuntu-108` | Textadept | Editor archive | Exact maintained Linux artifact, upstream signature or digest, package identity and clean/repeat evidence. |
| `ubuntu-109` | Tixati | P2P client artifact | Exact maintained Linux artifact, upstream signature or digest, application security/update boundary and clean/repeat evidence. |
| `ubuntu-114` | XnConvert | Proprietary graphics utility artifact | Exact vendor artifact and verification material, license/update behavior and clean/repeat evidence. |
| `ubuntu-133` | Pale Moon | Browser archive | Exact maintained Linux artifact, browser publisher signature or digest, update channel policy and clean/repeat evidence. |
| `ubuntu-149` | Valentina Studio | Database-client artifact | Exact vendor artifact and verification material, license/database-credential boundary and clean/repeat evidence. |
| `ubuntu-151` | DbVisualizer | Database-client artifact | Exact vendor artifact and verification material, user-license/database-credential boundary and clean/repeat evidence. |
| `rhel-centos-7-029-screenfetch` | screenFetch | Script/archive | The legacy script used a mutable unauthenticated `git://` clone and copied `screenfetch-dev` into `/usr/bin`. The project has a current upstream release, but an admitted route needs an exact immutable release artifact, publisher-authenticated signature or digest, a current EL target/runtime contract, and clean/repeat evidence. |

## Trust rule

An HTTPS download page, a convenience installer, a copied checksum without an
authenticating trust path, or a hash observed by an exploratory probe is not
enough. The provider must fail closed if its version, artifact identity,
signature/digest verification, signer identity, target guard, or evidence
reference is missing or changes. User credentials, license keys, paid-plan
choices, database secrets, private links, and storage/device-write choices are
not installer inputs.

All fifteen rows remain `blocked-third-party` with `replacement=-` and
`parity_level=unassessed`. This review captures the exact work still needed; it
does not reduce the retirement denominator or create a supported module.
