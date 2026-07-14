# Legacy source and migration status

## Source snapshots

| Snapshot | Upstream | Commit | Last upstream change |
|---|---|---|---|
| `legacy/ubuntu-16.04/` | `Yunushan/Ubuntu16.04-Auto-Software-Installation-Script` | `7de4b1d01f9372b3245dea31ee1e5307a650aadb` | 2019-05-15 |
| `legacy/rhel-family/` | `Yunushan/Centos-Red-Hat-Rocky-Alma-Software-Installer` | `f23009ad10f9719bf09ec0c1a87679e0e2653a5c` | 2023-06-08 |

Both upstream projects were MIT-licensed by Yunus ÇOĞAL. Their copyright
notices are consolidated in the root license and their original license files
remain beside the snapshots.

## Inventory

- Ubuntu 16.04: one 4,401-line launcher containing 159 installer choices.
- RHEL family: six distro/version launchers and 196 module scripts for CentOS
  6/7, AlmaLinux 8/9, and RHEL 8/9.
- The earlier repository name mentioned Rocky Linux but included no
  Rocky-specific implementation.

## Why the files are quarantined

The snapshots contain patterns that are unsuitable for a modern supported
installer, including:

- obsolete release repositories and fixed 2019-era download URLs;
- unchecked or plain-HTTP downloads and remote script execution;
- forced system OpenSSL/OpenSSH replacement;
- SSH root/password-login enablement;
- `--nodeps`, `--force` and GPG bypasses;
- hard-coded example credentials;
- firewall, SELinux, kernel and bootloader changes;
- destructive MariaDB logic that can remove `/var/lib/mysql`;
- five known launcher-to-module filename mistakes;
- no OS guard, strict error handling, automated tests or rollback boundary.

Removing executable bits reduces accidental use but is not a security sandbox.
Opening a legacy file and running it manually remains dangerous.

## Migration model

Migration means reimplementing the useful intent as a small active module that
uses enabled OS repositories and passes current tests. Copying a legacy script
into `modules/` is not migration.

| State | Meaning |
|---|---|
| `stable` | Active package-only module in the catalog |
| `planned` | Useful legacy feature awaiting safe design |
| `blocked-third-party` | Requires an explicit signed repository design |
| `blocked-safety` | Replaces critical system components or changes security policy |
| `retired` | Product or distribution is obsolete |

The active catalog begins with common editors, runtimes, diagnostics, web
servers, databases, containers and Debian-family desktop packages. Kernel,
OpenSSL and OpenSSH replacement are permanently blocked from normal modules.
