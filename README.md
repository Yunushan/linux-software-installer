# Linux Software Installer

[![CI](https://github.com/Yunushan/linux-software-installer/actions/workflows/ci.yml/badge.svg)](https://github.com/Yunushan/linux-software-installer/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/Bash-4.3%2B-4EAA25.svg)](https://www.gnu.org/software/bash/)

A modular, distro-aware Bash installer for Debian/Ubuntu and RHEL-compatible
Linux systems. It consolidates two earlier installer projects into one safer,
testable interface while preserving their original source under `legacy/` for
historical reference.

The active installer uses only packages already available from enabled
operating-system repositories. It does **not** execute the legacy scripts.

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
- does not start services unless `--enable-services` is explicitly supplied;
- prevents concurrent installation runs with `flock` when available;
- logs real installations under `/var/log/linux-software-installer/` with
  mode `0600`.

The scripts in `legacy/` predate these guarantees. They are non-executable,
unsupported and must be treated as source material only.

## Requirements

- Bash 4.3 or newer
- Linux with `/etc/os-release`
- `apt-get` on Debian-family systems or `dnf` on RHEL-family systems
- root privileges for the `install` command

`list`, `profiles`, `info`, `doctor` and `plan` work without root.

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
| `./install.sh doctor` | Check distro detection and prerequisites | No |
| `./install.sh plan nginx git` | Print the exact package commands | No |
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
| `developer` | Build tools, Python, Node.js and OpenJDK |
| `web` | Nginx and PHP |
| `lamp` | Apache, MariaDB and PHP |
| `lemp` | Nginx, MariaDB and PHP |
| `database` | PostgreSQL, MariaDB, Redis and SQLite |
| `containers` | Podman from the OS repository |
| `security` | Family-appropriate firewall, banning and scanning tools |
| `diagnostics` | DNS, route, port and process diagnostics |
| `desktop` | Curated Debian-family desktop/media applications |

## Active modules

The authoritative catalog is always available with `./install.sh list`.
Version 1.0 includes 43 low-risk package modules.

| Category | Modules |
|---|---|
| Base and diagnostics | `base-tools`, `bind-utils`, `chrony`, `curl`, `htop`, `jq`, `lsof`, `net-tools`, `nmap`, `rsync`, `tmux`, `traceroute`, `wget` |
| Editors and development | `ansible`, `build-tools`, `emacs`, `git`, `nano`, `neovim`, `nodejs`, `openjdk`, `python`, `vim` |
| Web and databases | `apache`, `mariadb`, `nginx`, `php`, `postgresql`, `redis`, `samba`, `sqlite` |
| Containers and security | `clamav`, `docker`, `fail2ban`, `firewalld`, `podman`, `ufw` |
| Desktop and media | `ffmpeg`, `gimp`, `qbittorrent`, `remmina`, `transmission`, `vlc` |

Some modules intentionally support only one family. For example, the active
RHEL repositories do not normally contain FFmpeg or VLC, and this project does
not silently add RPM Fusion or EPEL. Run `./install.sh info MODULE` to see the
exact package mapping and notes.

## Distribution support

Support is capability-based:

| Family | Detection examples | Package tool | Status |
|---|---|---|---|
| Debian | Debian, Ubuntu, Linux Mint | `apt-get` | Active on maintained releases |
| RHEL | RHEL, Rocky Linux, AlmaLinux, CentOS Stream, Fedora, Oracle Linux | `dnf` | Active on maintained releases |
| Legacy | Ubuntu 16.04, CentOS 6/7 | historical scripts | Quarantined and blocked |

The initial CI smoke matrix covers Ubuntu 24.04, Debian 12, Rocky Linux 9 and
AlmaLinux 9. Other maintained releases are best effort until added to CI. See
[`docs/SUPPORT.md`](docs/SUPPORT.md) for the policy and known differences.

## Service behavior

Package installation and service activation are separate decisions. By
default, a module installs packages without enabling or starting its service.

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
tests/                       Dependency-free unit and smoke tests
docs/                        Architecture, support and migration documentation
legacy/                      Non-executable snapshots of the original projects
.github/                     CI and contribution templates
```

Module authoring is documented in
[`docs/MODULE_AUTHORING.md`](docs/MODULE_AUTHORING.md).

## Testing

The local test suite has no third-party test dependency:

```bash
make test
make check
```

`make check` performs Bash syntax validation, runs ShellCheck and shfmt when
they are installed, then executes the test suite. CI additionally runs
read-only container smoke tests against the supported family matrix.

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
[`docs/LEGACY.md`](docs/LEGACY.md).

## Contributing

Contributions are welcome. Read [`CONTRIBUTING.md`](CONTRIBUTING.md) and run
`make check` before opening a pull request. New active modules must use enabled
OS repositories, declare their supported families and include a dry-run test.

Do not add remote-script execution, unsigned repositories, forced package
replacement, automatic firewall changes, embedded secrets or destructive
configuration changes.

## Security

Please report vulnerabilities privately as described in
[`SECURITY.md`](SECURITY.md). Do not include secrets or sensitive host output
in a public issue.

## License

The installer code is available under the [MIT License](LICENSE), with the
copyright range consolidated from both original projects.

Software installed by this project remains subject to its own license and
distribution terms. The MIT license for this repository does not relicense
third-party packages.
