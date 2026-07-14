# Support policy

## Active runtime support

The project supports maintained Linux releases that provide:

- Bash 4.3 or newer;
- `/etc/os-release`;
- `apt-get` for Debian-family systems or `dnf` for RHEL-family systems;
- the selected module packages in already enabled repositories.

The initial CI smoke matrix is:

| Image | Family | CI behavior |
|---|---|---|
| Ubuntu 24.04 | Debian | Detection, catalog and dry-run plan |
| Debian 12 | Debian | Detection, catalog and dry-run plan |
| Rocky Linux 9 | RHEL | Detection, catalog and dry-run plan |
| AlmaLinux 9 | RHEL | Detection, catalog and dry-run plan |

The matrix validates command generation without modifying the container.
Package installation and systemd service behavior should be acceptance-tested
in disposable VMs before production use.

## Package availability

An active module uses only enabled OS repositories. A package can therefore be
unavailable when an administrator has disabled a standard component or when a
vendor does not ship that package.

This project intentionally does not enable EPEL, RPM Fusion, PPAs or vendor
repositories automatically. Modules requiring one of those sources are either
family-limited or remain in the migration backlog.

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
