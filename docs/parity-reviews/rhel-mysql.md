# Pre-admission parity review: `rhel/mysql`

## Scope and status

- Evidence key: `rhel/mysql`
- Tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`
- Container evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), aggregate artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`
- Verification report: `docs/evidence-verification/rhel-mysql.json`
- Parity level on admission: `intent`
- Admission status: **pending disposable-VM/systemd attestation**. No existing
  database, credentials, SELinux policy, or repository configuration is changed.

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome |
| --- | --- | --- |
| `rhel-almalinux-8-029-mysql` | `legacy/rhel-family/AlmaLinux-8/scripts/29-Mysql.sh#script` | Removed MySQL packages/streams, selected distribution or MySQL Community versions, wrote repository definitions, and often started/enabled `mysqld`. |
| `rhel-centos-7-040-mysql` | `legacy/rhel-family/Centos-7/scripts/40-Mysql.sh#script` | Removed installed MySQL packages, added versioned Community repositories, installed a selected server, then started/enabled `mysqld`. |
| `rhel-red-hat-enterprise-linux-8-018-mysql` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/18-Mysql.sh#script` | Selected distribution or obsolete Community versions, rewrote repository state, removed alternatives, and included custom SELinux-policy generation. |
| `rhel-red-hat-enterprise-linux-9-009-mysql` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-9/scripts/9-Mysql.sh#script` | Selected distribution or obsolete Community versions, rewrote repository state, removed alternatives, and started/enabled selected server routes. |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Packages: `mysql-server`, `mysql`
- Package source: each target's configured signed distribution DNF repositories
- Verified binaries: `mysqld`, `mysql`
- Service contract: `mysqld`; default install has no explicit activation and `--enable-services` is separately evidenced
- State contract: no database initialization, data deletion, credential change, repository mutation, or SELinux policy generation

## Behavioral comparison

| Concern | Legacy behavior | Active behavior | Decision and rationale |
| --- | --- | --- | --- |
| Repository and version selection | Added Community repositories, disabled streams, and selected EOL versions. | Uses the maintained distribution stream. | Preserves the current MySQL-server outcome without persistent third-party trust or unsupported version pinning. |
| Existing packages and data | Removed packages and, in some routes, prompted around destructive replacement. | Does not remove packages, initialize a database, or delete data. | Database migration and rollback remain explicit administrator work. |
| Service lifecycle | Commonly started and enabled `mysqld`. | No default start or enable; explicit activation is opt-in. | Prevents unexpected database exposure and needs VM proof. |
| Security policy | Included a generated SELinux module in one route. | Does not write SELinux, firewall, user, password, or listener policy. | Mandatory-access control and credential decisions require workload-specific review. |

## Pending admission condition

Before any covered row can become `implemented`, accepted single-use VM evidence
must prove the default and explicit `mysqld` service states without collateral
system or firewall changes. The database state and policy exclusions above must
remain intact under the attested workflow in
[`SYSTEMD_EVIDENCE.md`](../SYSTEMD_EVIDENCE.md).
