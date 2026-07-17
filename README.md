# Linux Software Installer

[![CI](https://github.com/Yunushan/linux-software-installer/actions/workflows/ci.yml/badge.svg)](https://github.com/Yunushan/linux-software-installer/actions/workflows/ci.yml)
[![License: 0BSD](https://img.shields.io/badge/License-0BSD-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Bash-4.3%2B-4EAA25.svg)](https://www.gnu.org/software/bash/)

A modular, distro-aware Bash installer for Debian/Ubuntu and RHEL-compatible
Linux systems. It consolidates two earlier installer projects into one safer,
testable interface while preserving their original source under `legacy/` for
historical reference.

The active installer does not add repositories. It requests named packages
from repositories already enabled by the administrator, and it does **not**
execute the legacy scripts.

## Why this repository exists

The original projects used two different designs:

- [Ubuntu16.04-Auto-Software-Installation-Script](https://github.com/Yunushan/Ubuntu16.04-Auto-Software-Installation-Script)
  was a single 4,401-line Ubuntu 16.04 script with 159 installation choices.
- [Centos-Red-Hat-Rocky-Alma-Software-Installer](https://github.com/Yunushan/Centos-Red-Hat-Rocky-Alma-Software-Installer)
  contained separate launchers and scripts for CentOS 6/7, AlmaLinux 8/9, and
  RHEL 8/9.

This project replaces the duplicated production path with one `/etc/os-release`
detector, one CLI, one module catalog and family-specific package mappings.

## Safety defaults

The supported installer:

- runs with Bash strict mode and validates all module names;
- provides a read-only `plan` command before installation;
- refreshes package metadata at most once per run;
- never performs a full OS upgrade;
- never uses `curl | bash`, `wget | sh`, `--nodeps`, `--force` or
  `--nogpgcheck`;
- never replaces system OpenSSL, OpenSSH or the kernel;
- never enables SSH root login or password authentication;
- never disables SELinux, opens firewall ports, deletes database directories,
  changes database passwords or reboots the host;
- does not explicitly enable or start services unless `--enable-services` is supplied;
- prevents concurrent installation runs with `flock` when available;
- logs real installations under `/var/log/linux-software-installer/` with
  mode `0600`.

The scripts in `legacy/` predate these guarantees. They are non-executable,
unsupported and must be treated as source material only.

Package-manager maintainer scripts can still start a service as part of package
installation. That behavior belongs to the distribution package and must be
acceptance-tested on the target release when a strict no-start policy matters.

## Requirements

- Bash 4.3 or newer
- Linux with `/etc/os-release`
- `apt-get` on Debian-family systems or `dnf` on RHEL-family systems
- root privileges for the `install` command

`list`, `profiles`, `info`, `doctor`, `plan`, `providers`, `provider-info` and
the non-mutating `provider-plan` work without root.

## Quick start

```bash
git clone https://github.com/Yunushan/linux-software-installer.git
cd linux-software-installer

./install.sh doctor
./install.sh list
./install.sh plan nginx git postgresql
sudo ./install.sh install nginx git postgresql
```

Review the plan before approving it. For automation, add `--yes` only after
you have validated the same plan on the target distribution.

```bash
sudo ./install.sh install nginx git --yes
```

### Interactive mode

Run the installer without a command from a terminal:

```bash
sudo ./install.sh
```

Select modules by number or by name. A non-interactive invocation with no
command prints usage and exits instead of guessing.

## Commands

| Command | Purpose | Root required |
|---|---|---:|
| `./install.sh list` | List active modules and supported families | No |
| `./install.sh profiles` | List predefined bundles | No |
| `./install.sh info nginx` | Show module packages and safety notes | No |
| `./install.sh migrations` | List read-only guidance for all 355 legacy entries | No |
| `./install.sh migrate ubuntu-002` | Show read-only guidance for one legacy entry | No |
| `./install.sh retirement-status` | Show the evidence-backed retirement decision for the old repositories | No |
| `./install.sh doctor` | Check distro detection and prerequisites | No |
| `./install.sh plan nginx git` | Print the exact package commands | No |
| `./install.sh providers` | List validated third-party provider metadata | No |
| `./install.sh provider-info ID` | Show a registered provider's local catalog contract and integrity fields | No |
| `./install.sh provider-plan ID --allow-provider ID@CATALOG_REVISION MODULE` | Validate revision-bound policy consent and print the locked, non-mutating provider plan | No |
| `./install.sh provider-config ID --allow-provider ID@CATALOG_REVISION MODULE` | Render the reviewed provider repository configuration without enabling it | No |
| `sudo ./install.sh provider-apply ID --plan-sha256 PLAN_SHA256 --allow-provider ID@CATALOG_REVISION MODULE` | Materialize only the reviewed keyring and repository file; it never refreshes metadata or installs packages | Yes |
| `sudo ./install.sh provider-deactivate ID --plan-sha256 PLAN_SHA256 --allow-provider ID@CATALOG_REVISION MODULE` | Remove only matching installer-managed provider files; it rejects drift and never removes packages | Yes |
| `sudo ./install.sh install nginx git` | Apply an approved plan | Yes |

Common options:

```text
--profile NAME        Add a predefined module profile
--yes, -y             Skip the normal confirmation prompt
--enable-services     Enable and start declared services
--no-refresh          Skip repository metadata refresh
--dry-run             Print commands without executing them
--force-unsupported   Explicitly bypass the legacy-version guard
--verbose             Print diagnostic details
--no-color            Disable colored output
```

`--force-unsupported` bypasses only the version guard. It does not enable
legacy modules or add missing package repositories.

## Profiles

Profiles are plain, auditable module lists under [`profiles/`](profiles/).
Unsupported entries are skipped with a warning, allowing family-specific
security profiles without installing two firewall managers on the same host.

```bash
./install.sh profiles
./install.sh plan --profile developer
sudo ./install.sh install --profile developer
```

| Profile | Includes |
|---|---|
| `base` | Common CLI tools, Git, editors and diagnostics |
| `developer` | Build tools, Python, Node.js, OpenJDK, Ruby and Composer where supported |
| `web` | Nginx and PHP |
| `lamp` | Apache, MariaDB and PHP |
| `lemp` | Nginx, MariaDB and PHP |
| `database` | PostgreSQL, MariaDB, Redis and SQLite |
| `containers` | Podman from the OS repository |
| `security` | Family-appropriate firewall, banning and scanning tools |
| `diagnostics` | DNS, route, port and process diagnostics |
| `desktop` | Curated Debian-family desktop/media applications |
| `creative` | Debian-family graphics, photography and 3D tools |
| `media` | Debian-family audio, video, streaming and playback tools |
| `communication` | Debian-family email, IRC and voice clients |

## Active modules

The authoritative catalog is always available with `./install.sh list`.
The current catalog includes 103 low-risk package modules.

| Category | Modules |
|---|---|
| Base and diagnostics | `base-tools`, `bind-utils`, `chrony`, `curl`, `htop`, `jq`, `lsof`, `midnight-commander`, `monitoring-tools`, `net-tools`, `nmap`, `rsync`, `tmux`, `traceroute`, `wget` |
| Editors and development | `ansible`, `bluefish`, `build-tools`, `composer`, `dotnet-sdk`, `emacs`, `geany`, `git`, `nano`, `neovim`, `nodejs`, `openjdk`, `python`, `qt`, `ruby`, `thonny`, `vim` |
| Web, databases and sharing | `apache`, `mariadb`, `mysql`, `nfs-server`, `nginx`, `php`, `postgresql`, `redis`, `samba`, `sqlite` |
| Containers and security | `clamav`, `docker`, `fail2ban`, `firewalld`, `podman`, `ufw` |
| Desktop, creative and media | `audacity`, `blender`, `caffeine`, `calibre`, `clementine`, `conky`, `darktable`, `deluge`, `dvblast`, `ffmpeg`, `geary`, `gimp`, `go-for-it`, `handbrake`, `inkscape`, `kazam`, `kdenlive`, `kodi`, `krita`, `libreoffice`, `liferea`, `mpv`, `musicbrainz-picard`, `obs-studio`, `okular`, `openshot`, `plank`, `playonlinux`, `qbittorrent`, `sayonara`, `remmina`, `shotcut`, `shutter`, `simplescreenrecorder`, `smplayer`, `stacer`, `timeshift`, `tor-browser`, `transmission`, `typecatcher`, `variety`, `vlc`, `wings3d` |
| Communication and networking | `hexchat`, `irssi`, `konversation`, `magic-wormhole`, `mumble`, `quassel`, `telegram`, `tinc`, `uget`, `vuze`, `weechat`, `wine` |

Some modules intentionally support only one family. For example, the active
RHEL repositories do not normally contain FFmpeg or VLC, and this project does
not silently add RPM Fusion or EPEL. Run `./install.sh info MODULE` to see the
exact package mapping, notes and target policy. A module can further restrict
support to literal `ID:VERSION_ID:architecture` cells; plan and install reject
same-family hosts outside those trusted manifest declarations.

The live provider catalog is intentionally empty. `providers/registry.tsv` is the sole admission source and
pins each admitted provider ID to a catalog revision and provider-tree SHA-256.
In addition to exact local GnuPG binding between declared primary fingerprints
and checked-in public keys, `provider-plan` validates an exact
target/dependency/package-lock contract, requires revision-bound provider
authorization plus provider-specific preview, license, authentication and
persistence consent, and emits a digest of its cached plan snapshot.
`provider-apply` requires that exact digest and atomically writes only the
checked-in keyring and rendered repository file; it rejects file drift and
never refreshes metadata or installs packages. Its files remain active until
the matching digest-bound `provider-deactivate` is run. Local
tree, key and plan hashes detect drift; they do not establish publisher or live
repository authenticity. The command rejects `--yes` and does not add or
enable a repository. See
[`docs/PROVIDERS.md`](docs/PROVIDERS.md).

## Distribution support

Support is capability-based:

| Tier | Distribution/version | Package tool | Evidence |
|---|---|---|---|
| Candidate Tier 1 | Ubuntu 24.04, Debian 12 | `apt-get` | CI is configured for detection, catalog, plan smoke and dependency-solver checks on x86_64; accepted release evidence is pending |
| Candidate Tier 1 | Rocky Linux 9.8, AlmaLinux 9.8 | `dnf` | CI is configured for detection, catalog, plan smoke and dependency-solver checks on x86_64; accepted release evidence is pending |
| Best effort | Other detected Debian/RHEL-compatible releases | `apt-get` or `dnf` | Detection and family mapping only; not a release-blocking claim |
| Legacy | Ubuntu 16.04, CentOS 6/7 | historical scripts | Quarantined and blocked by default |

The CI smoke matrix is configured for Ubuntu 24.04, Debian 12, Rocky Linux 9.8
and AlmaLinux 9.8 on GitHub-hosted x86_64 runners. These remain candidates until
an accepted run is tied to the tested commit and image digests. Other detected
releases are best effort until added to release-blocking evidence. See
[`docs/SUPPORT.md`](docs/SUPPORT.md) for the policy and known differences.

## Service behavior

Package installation and explicit service activation are separate decisions.
By default, the installer emits no `systemctl enable` or `systemctl start`
command. A distribution package's own maintainer scripts can still start a
service during installation.

```bash
sudo ./install.sh install nginx --enable-services
```

The PostgreSQL module intentionally does not initialize a RHEL-family database
cluster. Samba does not create shares or users. Firewall modules install their
management tool but add no rules. These actions remain visible administrator
decisions.

## Repository structure

```text
install.sh                   Stable entrypoint
bin/                         CLI executable
lib/                         OS detection, catalog, package and CLI logic
modules/<name>/module.sh     Auditable module metadata and package mappings
profiles/*.list              Predefined module bundles
providers/                    Read-only third-party catalog-contract schema
tests/                       Dependency-free unit and smoke tests
docs/                        Architecture, support and migration documentation
legacy/                      Non-executable snapshots of the original projects
.github/                     CI and contribution templates
```

Module authoring is documented in
[`docs/MODULE_AUTHORING.md`](docs/MODULE_AUTHORING.md).

## Testing

The local test suite has no third-party test dependency. Its evidence and
promotion validators use the Python standard library and POSIX no-follow file
protection, so run every check from Linux with Python 3.8 or newer. A host
without that runtime reports those checks as skipped rather than as test
failures:

```bash
make test
make check
```

`make check` performs Bash syntax validation, runs ShellCheck and shfmt when
they are installed, then executes the test suite. CI is additionally configured
to run read-only plan smoke tests and repository-resolution tests against the
four-image candidate matrix. Repository resolution refreshes enabled metadata,
checks package visibility and asks the distro solver to resolve each module
transaction without installing it; it does not validate service behavior.
The deterministic operational suite separately exercises root refusal,
confirmation, fail-closed locking, protected/redacted logs, failure
propagation, refresh-once behavior and explicit service activation without
making host changes. Actual service state still requires the VM evidence below.

The scheduled/manual `Real install smoke` workflow is configured to install
every applicable catalog module in disposable containers, check that declared
binaries are present and compare installed package/version snapshots before
and after a repeat installation. The catalog is deterministically partitioned
into two conflict-safe batches (currently separating Apache/Nginx and
MariaDB/MySQL). Accepted evidence requires a green run
tied to the commit and image digests. These are catalog-batch checks, not
standalone parity evidence for each module. Service-state testing uses the
separate manual disposable-systemd-VM workflow described below.

The manual `Standalone module evidence` workflow uses one matrix job per module
(103 jobs for the full catalog). Each job sequentially starts a separate fresh
container for every applicable target, so all 370 declared module-image cells
remain independent without exceeding GitHub's 256-job matrix limit. It records
pre-install, post-install and post-repeat package state, tested commit and image
digest, package sources, binary checks and structured failure details. A final
job validates exact coverage and checksums and builds a deterministic import
bundle. This remains candidate infrastructure until reviewed runs and durable
evidence are published. The bundle's internal hashes detect corruption but do
not authenticate themselves; an accepted import must also record an external
GitHub artifact digest, signed release hash or attestation.

Before considering an aggregate GitHub artifact for admission, download its ZIP
and run `tests/verify-accepted-evidence-artifact.py` with the aggregate job's
published artifact digest, tested commit and run URL. It rechecks the external
ZIP digest and aggregate/bundle contract, but does not replace the required
parity review or service attestation.

The 103 modules contribute 370 cells across Ubuntu 24.04, Ubuntu 26.04,
Debian 12, Rocky Linux 9.8 and AlmaLinux 9.8. Target restrictions are filtered
before matrix and contract generation, so totals are derived from manifest
policy rather than blindly multiplying family mappings.

The manual [`Systemd VM evidence`](.github/workflows/systemd-vm-evidence.yml)
workflow runs exactly one service-bearing plan row on one externally
provisioned, disposable self-hosted VM. It requires an immutable VM image
reference and external provision/create/destroy attestation, and remains
provisional until that external attestation is independently verified.

Container-based workflows disable persisted checkout credentials and export
the tested commit with `git archive`, so containers receive neither `.git` nor
checkout credentials. Container-writable evidence and installer-log trees stay
outside artifact upload paths. A container must be removed before those raw
trees are copied into the host-controlled upload tree; the no-follow sanitizer
accepts only directories and single-link regular files, rejects symbolic links,
FIFOs, sockets, devices, hard links and destination collisions, and normalizes
the copied modes. Raw container paths are never uploaded, including when
cleanup or sanitization fails.

Active code is tested separately from `legacy/`. The legacy files are kept as
historical snapshots and are not expected to satisfy current lint rules.

## Legacy catalog

The complete source from both original repositories is preserved under
[`legacy/`](legacy/README.md), including the 159-choice Ubuntu script and all
196 RHEL-family module scripts. Preserved does not mean supported.

Known legacy hazards include unchecked downloads, obsolete repositories,
forced OpenSSL/OpenSSH replacement, SSH security weakening, hard-coded sample
credentials, destructive database operations and incorrect launcher mappings.
Do not execute those files on a live system.

Migration status and the exact source commits are documented in
[`docs/LEGACY.md`](docs/LEGACY.md). The machine-checked 355-entry replacement
ledger and the gates for retiring the old repositories are documented in
[`docs/REPLACEMENT.md`](docs/REPLACEMENT.md). The exact next action for every
third-party gap is tracked separately in the machine-checked
[`docs/PROVIDER_BACKLOG.md`](docs/PROVIDER_BACKLOG.md). Use the fail-closed,
read-only lookup documented in [`docs/MIGRATION.md`](docs/MIGRATION.md) to find
the candidate, unresolved route or terminal handoff for any legacy entry
without executing the old repositories.

`./install.sh retirement-status` reports `READY TO RETIRE` only after every
legacy row is a validated terminal replacement or a documented terminal
handoff. Until then it reports `NOT READY`; do not archive or delete either
legacy repository.

## Contributing

Contributions are welcome. Read [`CONTRIBUTING.md`](CONTRIBUTING.md) and run
`make check` before opening a pull request. New active modules must not add
repositories, must declare their supported families and must include a dry-run
test.

Do not add remote-script execution, unsigned repositories, forced package
replacement, automatic firewall changes, embedded secrets or destructive
configuration changes.

## Security

Please report vulnerabilities privately as described in
[`SECURITY.md`](SECURITY.md). Do not include secrets or sensitive host output
in a public issue.

## License

The installer code is available under the [0BSD license](LICENSE), with the
copyright range consolidated from both original projects.

Software installed by this project remains subject to its own license and
distribution terms. The 0BSD license for this repository does not relicense
third-party packages.
