# Support policy

## Support tiers

Tier 1 is deliberately narrower than distro detection. A candidate Tier-1 claim
requires release-blocking evidence for the literal distribution `VERSION_ID`
and architecture. Every target also requires:

- Bash 4.3 or newer;
- `/etc/os-release`;
- `apt-get` for Debian-family systems or `dnf` for RHEL-family systems;
- the selected module packages in already enabled repositories.

The current candidate Tier-1 matrix is:

| Image | Family | Architecture | CI behavior |
|---|---|---|---|
| Ubuntu 24.04 | Debian | x86_64 | Configured for detection, catalog, base-tools/Git plan and dependency-solver checks |
| Debian 12 | Debian | x86_64 | Configured for detection, catalog, base-tools/Git plan and dependency-solver checks |
| Rocky Linux 9.8 | RHEL | x86_64 | Configured for detection, catalog, base-tools/Git plan and dependency-solver checks |
| AlmaLinux 9.8 | RHEL | x86_64 | Configured for detection, catalog, base-tools/Git plan and dependency-solver checks |

The read-only smoke matrix is configured to validate command generation without
modifying the container. A second matrix refreshes enabled repository metadata,
checks every mapped package for visibility and asks `apt` or `dnf` to solve
each module transaction without installing it. Real package transactions and
systemd behavior must still be acceptance-tested in disposable environments
before production use.

Local operational tests do cover the deterministic guardrails around those
transactions—root and confirmation checks, mandatory locking, protected and
redacted logs, failure propagation, refresh-once behavior and opt-in service
commands. They do not promote a release or prove actual systemd state.

The scheduled/manual `Real install smoke` workflow is configured to produce
disposable catalog-batch install evidence, binary-presence checks and
package-state comparison across a repeat installation. A release is not
promoted solely because that workflow exists: its exact commit and image
digests must have green runs, standalone parity remains a separate claim, and
service-state claims still require systemd VM evidence.

The manual `Standalone module evidence` workflow is separately configured for
all 273 declared module-image cells. Its 103-module matrix stays below the
GitHub workflow limit; each module job sequentially starts one clean container
for every applicable target. It records pre-install, post-install and
post-repeat state, the commit and immutable image reference, declared binaries,
package sources and structured failures. An aggregate job validates exact cell
coverage and checksums and creates a deterministic import bundle. These jobs
are evidence infrastructure, not accepted results until a reviewed run is
published and imported into a durable release record. Internal bundle hashes
are integrity metadata, not independent authenticity: promotion must also pin
an external GitHub artifact digest, signed release hash or attestation.

The 100 family-wide modules contribute 270 cells. PlayOnLinux and Tor Browser
Launcher are restricted to Ubuntu 24.04 x86_64, while Telegram Desktop is
restricted to Debian 12 x86_64, for a current total of 273. Exact
`ID:VERSION_ID:architecture` restrictions are shown by `list` and `info`,
enforced for plan/install, and removed from unsupported evidence cells; matrix
totals are therefore derived rather than assumed from family counts.

The container workflows use a credential-free `git archive` export rather
than mounting a checkout containing `.git`. Container-writable evidence stays
in raw runner-temporary directories that are never uploaded. After verified
container removal, a no-follow sanitizer copies only directories and
single-link regular files into the upload tree; links, FIFOs, sockets, devices,
destination collisions and other unsupported entries fail closed. A cleanup
failure prevents sanitization, and neither failure makes the raw tree
uploadable.

Without `--enable-services`, the installer does not explicitly invoke
`systemctl` to activate module services. Package-manager maintainer scripts are
outside that boundary and can start a service during package installation.
The 44-row disposable-VM contract and its current provisional-only trust
boundary are documented in [`SYSTEMD_EVIDENCE.md`](SYSTEMD_EVIDENCE.md). The
repository has no accepted systemd VM run and therefore makes no release-level
service-state claim.

Other releases recognized by `/etc/os-release` are best effort. That includes
Linux Mint, RHEL, CentOS Stream, Fedora and Oracle Linux until their exact
version and architecture are added to release-blocking CI. Detection means the
installer can select a package family; it is not proof that every mapped
package is available on that release.

## Package availability

The installer adds no repositories; an active module requests named packages
from repositories already enabled by the administrator. A package can therefore
be unavailable when a standard component is disabled, a vendor does not ship
it, or a third-party repository shadows distribution content.

This project intentionally does not enable EPEL, RPM Fusion, PPAs or vendor
repositories automatically. Modules requiring one of those sources are either
family-limited or remain in the migration backlog. Every current third-party
legacy gap has an explicit proposed provider, artifact or handoff route in
[`PROVIDER_BACKLOG.md`](PROVIDER_BACKLOG.md); those proposals are not support
claims until their implementation and evidence gates pass.

## Legacy systems

Ubuntu 16.04 and CentOS 6/7 are blocked by policy. Their historical installers
remain under `legacy/` but are not registered, tested or supported. The
`--force-unsupported` option bypasses only the version guard for active
repository modules; it never enables a legacy script.

## Rocky Linux

The earlier RHEL-family repository did not contain a Rocky-specific directory.
This project adds Rocky recognition through `/etc/os-release` and the common
RHEL package family. A module is supported on Rocky only when its DNF package
mapping is present in the enabled Rocky repositories.
