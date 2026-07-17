# Kubectl provider route audit (planning only)

This record captures a 2026-07-15 audit of a possible
`kubernetes-v1-36` provider for the three unresolved `kubectl` backlog rows.
It is a fixture-candidate planning record, not an installed fixture, live provider, repository-admission
decision, module-support claim or replacement-evidence artifact. No provider
directory is registered. The installer does have a tightly scoped,
digest-authorized `provider-apply` operation, but the empty live registry means
this candidate cannot reach it.

The proposed catalog identity is deliberately version- and channel-specific:

| Field | Audited candidate value |
| --- | --- |
| Provider ID | `kubernetes-v1-36` |
| Catalog revision | `2026-07-15.v1.36.2.r1` |
| Backend/status | `repository` / `preview` |
| Default persistence | `disabled` |
| Authentication | `none` |
| License | notice for Apache License 2.0 |
| Package | `kubectl` |
| Verification binary | `kubectl` |

Preview authorization and disabled persistence would still be mandatory under
the read-only provider-planning contract. These values must not be copied into
the live registry until every blocker below is resolved.

## Exact candidate cells

The candidate is restricted to four exact x86-64 cells. It does not use a
family wildcard and does not claim the historical Ubuntu 16.04, AlmaLinux 8 or
CentOS 7 environments named by the old source rows.

| Candidate cell | Exact target tuple | Manager | Channel | Metadata policy |
| --- | --- | --- | --- | --- |
| `ubuntu-24-04-amd64` | `ubuntu:24.04:x86_64` | `apt-get` | `v1-36` | `apt-release` |
| `debian-12-amd64` | `debian:12:x86_64` | `apt-get` | `v1-36` | `apt-release` |
| `rocky-9-8-x86-64` | `rocky:9.8:x86_64` | `dnf` | `v1-36` | `rpm-repodata-and-package` |
| `almalinux-9-8-x86-64` | `almalinux:9.8:x86_64` | `dnf` | `v1-36` | `rpm-repodata-and-package` |

Both APT cells use the official flat repository coordinates exactly:

| Field | Value |
| --- | --- |
| Repository URI | `https://pkgs.k8s.io/core:/stable:/v1.36/deb/` |
| Suite | `/` |
| Components | `-` |
| Expected `Origin` | `obs://build.opensuse.org/isv:kubernetes:core:stable:v1.36/deb` |
| Observed `Label` | `isv:kubernetes:core:stable:v1.36` |

The trailing slash, `suite=/` and `components=-` are significant: this is a
flat APT repository, not a distribution-codename repository. A future runtime
check must enforce both the signed Release identity and the exact package
origin; adding the URL alone is insufficient.

Both DNF cells use:

| Field | Value |
| --- | --- |
| Repository URI | `https://pkgs.k8s.io/core:/stable:/v1.36/rpm/` |
| Suite/components | `-` / `-` |
| Expected RPM `Vendor` | `obs://build.opensuse.org/isv:kubernetes` |
| Expected RPM `Packager` | `Kubernetes Authors <dev@kubernetes.io>` |

The DNF policy requires authenticated `repomd.xml` metadata as well as signed
RPM packages. A package signature by itself cannot satisfy the candidate.

## Exact package locks

The following package-object locks were observed for the dated candidate. A
shared digest across two cells means the same upstream package object was
selected; it does not merge the exact-cell support claims.

| Cell | Package version | Package architecture | Package SHA-256 |
| --- | --- | --- | --- |
| `ubuntu-24-04-amd64` | `1.36.2-2.1` | `amd64` | `e678e88e6e65fb49f54985994eacaa5555574f0ceb01772208f328037878b58c` |
| `debian-12-amd64` | `1.36.2-2.1` | `amd64` | `e678e88e6e65fb49f54985994eacaa5555574f0ceb01772208f328037878b58c` |
| `rocky-9-8-x86-64` | `0:1.36.2-150500.2.1` | `x86_64` | `e4c6e7bff5a46d99e86b42dc2042d2c6b9374c46770bd83c22722a69ac25a0fb` |
| `almalinux-9-8-x86-64` | `0:1.36.2-150500.2.1` | `x86_64` | `e4c6e7bff5a46d99e86b42dc2042d2c6b9374c46770bd83c22722a69ac25a0fb` |

The RPM epoch `0:` is part of the exact lock. A future solver must reject a
different epoch, version, release, architecture, digest or repository origin,
even if it is a newer v1.36 build.

## Signing-key observation

The audit observed the public key served at
`https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key` with these properties:

| Property | Observed value |
| --- | --- |
| Primary fingerprint | `DE15B14486CD377B9E876E1A234654DA9A296436` |
| Observed key-file SHA-256 (untrusted transport) | `7627818cf7bae52f9008c93e8b1f961f53dea11d40891778de216fb1b43be54d` |
| Primary-key expiry | `2026-12-29` |

The official Kubernetes installation instructions identify the `Release.key`
URL and state that the same signing key serves the versioned repositories, but
they do not independently publish the full fingerprint or this file digest.
This environment did not acquire those bytes through a valid-TLS command path,
so the observation cannot populate even a test fixture. A future TLS-clean
acquisition could bind a candidate fixture to reviewed bytes, but would still
need an independently authenticated provenance chain and an explicit rotation
policy that rejects expired or revoked material and requires a reviewed catalog
revision before accepting a replacement key.

## Client compatibility boundary

Kubernetes documents a one-minor version-skew rule for `kubectl`: a v1.36
client is compatible with v1.35, v1.36 and v1.37 API servers. Consequently this
candidate cannot be an unqualified "install kubectl" route. The caller must
deliberately select the v1.36 channel only when that range matches the target
cluster; the provider must not silently follow a newer minor channel.

## Admission blockers

The route remains planning-only for all of the following independent reasons:

1. **No admitted provider route exists.** The installer has reviewed,
   digest-authorized apply and deactivate primitives for an admitted provider,
   including scoped keyring and repository-file handling plus drift-safe
   removal. This candidate has no registered provider tree, reviewed fixture or
   exact-cell policy that could safely use those primitives.
2. **The EL probes were TLS-disabled.** Local certificate interception made the
   exploratory Rocky Linux 9.8 and AlmaLinux 9.8 probes possible only with TLS
   verification disabled. Those results cannot authenticate transport and are
   not solver, signature or install evidence. Both cells need clean TLS probes.
3. **Key provenance and expiry are unresolved.** The observed fingerprint and
   file hash are not independently asserted by the official instructions, and
   the key expires on 2026-12-29. Provenance, revocation and rotation behavior
   must fail closed before the key can become a live trust root.
4. **APT replay protection is unproved.** A valid Release signature alone does
   not establish that the selected signed snapshot is the current authorized
   snapshot. The apply design needs a tested freshness or monotonic-version
   rule that rejects replayed v1.36 metadata without weakening exact locks.
5. **Accepted evidence is absent.** No commit-bound, immutable-image-bound,
   externally authenticated solver/install/repeat-install bundle has passed the
   repository's evidence gates for all four cells. Observed coordinates,
   versions and hashes are planning inputs only.

Until every item is resolved, the three legacy rows remain
`blocked-third-party`, their proposed `replacement_outcome=kubectl` remains
unassessed, and users should follow the upstream Kubernetes installation and
version-skew guidance rather than treating this audit as an installer command.
