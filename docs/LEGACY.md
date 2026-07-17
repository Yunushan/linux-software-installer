# Legacy source and migration status

## Source snapshots

| Snapshot | Upstream | Commit | Last upstream change |
|---|---|---|---|
| `legacy/ubuntu-16.04/` | `Yunushan/Ubuntu16.04-Auto-Software-Installation-Script` | `7de4b1d01f9372b3245dea31ee1e5307a650aadb` | 2019-05-15 |
| `legacy/rhel-family/` | `Yunushan/Centos-Red-Hat-Rocky-Alma-Software-Installer` | `f23009ad10f9719bf09ec0c1a87679e0e2653a5c` | 2023-06-08 |

Both upstream projects were MIT-licensed by Yunus ÇOĞAL. Their copyright
notices are consolidated in the root license and their original license files
remain beside the snapshots.

The pinned `legacy/README.md` phrase “excluded from tests” means excluded from
active functional execution tests and shell linting. Maintained inventory and
quarantine validators still inspect names, modes, hashes and locators to prove
the snapshot remains immutable without executing its scripts.

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
- nine known launcher/menu-to-module mapping mistakes;
- no OS guard, strict error handling, automated tests or rollback boundary.

Removing executable bits reduces accidental use but is not a security sandbox.
Opening a legacy file and running it manually remains dangerous.

## Migration model

Package-only migration means reimplementing the useful intent as a small active
module that uses already enabled repositories and passes current tests. A
third-party capability instead requires the explicit trust boundary in
[`PROVIDERS.md`](PROVIDERS.md), or a reviewed handoff. Copying a legacy script
into `modules/` is not migration.

Module manifests use `stable` for active catalog entries. The legacy ledger
uses a separate disposition taxonomy:

| Disposition | Meaning |
|---|---|
| `planned` | Decision or evidence is incomplete |
| `implemented` | An active replacement meets its declared parity and evidence gates |
| `superseded` | Another active workflow intentionally replaces the useful outcome |
| `retired` | The exact product, release or behavior is obsolete |
| `blocked-safety` | Reproduction is permanently rejected by the safety boundary |
| `blocked-third-party` | A signed external-provider design is still unresolved and non-terminal |
| `out-of-scope` | Ownership is explicitly rejected with a documented handoff |

The active catalog begins with common editors, runtimes, diagnostics, web
servers, databases, containers and Debian-family desktop packages. Kernel,
OpenSSL and OpenSSH replacement are permanently blocked from normal modules.

The complete 355-entry source ledger and the evidence gates required before
the historical repositories can be archived are maintained in
[`REPLACEMENT.md`](REPLACEMENT.md) and
[`legacy-inventory.tsv`](legacy-inventory.tsv). Proposed routes for every
remaining third-party gap are machine-checked in
[`PROVIDER_BACKLOG.md`](PROVIDER_BACKLOG.md). The read-only
[`MIGRATION.md`](MIGRATION.md) lookup exposes those dispositions without
executing any quarantined source. Until every ledger row has a terminal,
evidence-backed disposition, this project replaces the active execution path
but does not claim complete legacy feature parity.

The two preserved trees have also been independently compared, blob by blob,
with their exact upstream commit trees; see
[`ORIGIN_VERIFICATION.md`](ORIGIN_VERIFICATION.md). This proves the migration
denominator is intact, not that the retirement gate has been met.
