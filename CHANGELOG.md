# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Expanded the package-only catalog from 43 to 103 low-risk modules, with 100
  Debian-family and 38 RHEL-family mappings.
- Added exact-cell distro-package candidates for PlayOnLinux and Tor Browser
  Launcher on Ubuntu 24.04 x86_64 and Telegram Desktop on Debian 12 x86_64;
  unsupported same-family cells remain blocked.
- Added repository-solver, real-install and standalone per-module evidence
  workflows for Ubuntu 24.04, Debian 12, Rocky Linux 9.8 and AlmaLinux 9.8.
- Added a machine-checked 355-row legacy replacement inventory, immutable
  quarantine validation, source-defect records and evidence-backed terminal
  disposition documentation.
- Added a machine-checked provider backlog that assigns every unresolved
  third-party capability to a provider, authenticated-artifact or documented
  handoff route.
- Added clean-environment `migrations` and `migrate LEGACY_ID` commands that
  expose fail-closed, read-only guidance for all 355 legacy entries without
  executing quarantined source or treating proposed routes as support claims.
- Added an intentionally empty, read-only provider registry as the sole
  admission source, binding each provider ID and catalog revision to an exact
  provider-tree SHA-256; repository mutation remains disabled.
- Added a non-mutating provider transaction planner with explicit per-provider
  revision-bound authorization, dependency closure, exact
  preview/license/authentication and persistence gates, immutable cached
  rendering, a plan SHA-256, and locked
  package/version/architecture/digest output.

### Fixed

- Accepted both `dnf install` and `dnf -y install` in container plan smoke
  assertions, fixing the Rocky/Alma false failure in Actions run 29365966229.
- Corrected the Ubuntu `tinc` verification command and replaced the obsolete
  Vuze package/command alias with its maintained BiglyBT successor.
- Made RHEL package transactions handle the base-image `curl-minimal` conflict
  without disabling signature checks or using broad package erasure.
- Replaced the frozen Rocky 9.3 library image with immutable vendor Rocky 9.8
  and AlmaLinux 9.8 targets, and changed evidence validation from major-prefix
  matching to literal observed `VERSION_ID` equality.

### Security

- Block Ubuntu 16.04 and CentOS 6/7 by default while keeping their preserved
  installers outside the active execution path.
- Require exact, non-mutating plans and explicit unsupported-version opt-in;
  legacy quarantine checks pin the historical tree and reject active execution
  references.
- Isolated container-writable evidence from upload paths, removed containers
  before no-follow sanitization, and supplied containers from credential-free
  `git archive` exports instead of persisted checkout credentials.
- Bound promoted evidence to checked-out manifests, contracts and target
  identities, and require an external artifact digest, signed hash or
  attestation before authenticity can be accepted.
- Bind every provider key declaration to the exact primary fingerprints parsed
  from its provider-local OpenPGP public-key material in an isolated GnuPG
  home, while explicitly treating that local binding and catalog/tree hashes
  as integrity rather than publisher or live-repository authenticity; DNF
  declarations require both signed metadata and signed packages, and repository
  mutation remains disabled.
- Validate flat APT provider coordinates as an exact-path suite (`/`) with no
  components and a trailing-slash repository URI; ambiguous suite/component
  omissions remain rejected.
- Reject path-bearing normal APT suites/components and byte-differential
  provider metadata containing NUL data or a missing final newline before any
  parsed registry, manifest, cell or lock state is accepted.
- Constrain migration evidence to valid HTTPS authorities or physical,
  repository-local, single-link documentation paths; reject linked module
  directories, hardlinked manifests and traversal-shaped RHEL provenance.
- Refuse `implemented` and `superseded` migration claims until a reviewed
  machine-readable accepted-evidence admission registry exists.
- Make concurrent-run locking fail closed, create installer logs with
  no-clobber ownership/link/mode checks, and redact sensitive command
  arguments before display or logging.

## [1.0.0] - 2026-07-14

### Added

- Unified `install.sh` entrypoint with automatic `/etc/os-release` detection.
- Debian/Ubuntu and RHEL/Rocky/Alma package-family support.
- 43 repository-backed, low-risk package modules.
- Interactive, profile, plan, doctor and non-interactive installation modes.
- Explicit service activation, repository refresh and legacy-version controls.
- Module conflict detection and path-traversal rejection.
- Local tests plus GitHub Actions syntax, lint and container smoke checks.
- Complete snapshots of both original repositories under `legacy/`.
- MIT license, security policy, contribution guide and architecture docs.

### Security

- Quarantined legacy OpenSSL/OpenSSH/kernel replacement and destructive
  database scripts from the active execution path.
- Removed remote-script execution and unsigned third-party repositories from
  supported modules.

[Unreleased]: https://github.com/Yunushan/linux-software-installer/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Yunushan/linux-software-installer/releases/tag/v1.0.0
