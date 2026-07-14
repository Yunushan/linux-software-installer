# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

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
