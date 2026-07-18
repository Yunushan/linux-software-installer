# Pre-admission parity review: `rhel/postgresql`

## Scope and status

- Evidence key: `rhel/postgresql`
- Tested commit: `e3e3be187b1c4b82d6a73e31be49e4852043bed8`
- Real-install evidence: [run 29657203174](https://github.com/Yunushan/linux-software-installer/actions/runs/29657203174), aggregate artifact digest `sha256:d229e175f0eecafcbd867eb999fe6c0e72c83a0945f182a354bdecbd14266959`
- Verification report: `docs/evidence-verification/rhel-postgresql.json`
- Parity level on admission: `intent`
- Admission status: **pending disposable-VM/systemd attestation**. This review is not an accepted-evidence record.

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome |
| --- | --- | --- |
| `rhel-almalinux-8-045-postgresql` | `legacy/rhel-family/AlmaLinux-8/scripts/45-Postgresql.sh#script` | Added the PGDG RPM, selected PostgreSQL 9.6–14, initialized a database, then enabled and started the chosen versioned service. |
| `rhel-red-hat-enterprise-linux-8-025-postgresql` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/25-Postgresql.sh#script` | Added the PGDG RPM, selected PostgreSQL 9.6–14, initialized a database, then enabled and started the chosen versioned service. |
| `rhel-red-hat-enterprise-linux-9-014-postgresql` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-9/scripts/14-Postgresql.sh#script` | Added the PGDG RPM, selected PostgreSQL 10–14, initialized a database, then enabled and started the chosen versioned service. |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Packages: `postgresql-server`, `postgresql-contrib`
- Package source: each target's configured signed distribution DNF repositories; no external PGDG RPM or module-stream mutation
- Verified binary: `psql`
- Service contract: `postgresql`; initialization, start, and enable actions remain explicit administrator choices

## Behavioral comparison

| Concern | Legacy behavior | Active behavior | Decision and rationale |
| --- | --- | --- | --- |
| Repository and version selection | Installed a remote PGDG repository RPM and offered obsolete version choices. | Uses the supported distribution server package. | Retains a maintained package-managed PostgreSQL server outcome without unreviewed repository trust or obsolete version pinning. |
| Database initialization | Ran version-specific `initdb` automatically. | Does not initialize a database cluster. | Cluster location, storage, ownership, locale, and recovery policy are administrator-owned state. |
| Service lifecycle | Enabled and started the selected versioned service. | Declares `postgresql` but performs no default start or enable. | The eventual VM evidence must prove both default and explicit lifecycle behavior without asserting deployment policy. |
| Credentials, network, and data | Could create a database cluster before the operator set policy. | Does not set passwords, authentication, listeners, databases, or network exposure. | Security and data lifecycle remain explicit deployment decisions. |

## Pending admission condition

The aggregate proof verifies clean and repeat installation on AlmaLinux 9.8 and
Rocky Linux 9.8. It does not verify systemd behavior. Before any covered legacy
row can be marked implemented, an external single-use VM run must supply the
accepted default-state and explicit-action evidence for `postgresql`, including
the required provisioning and destruction attestation.
