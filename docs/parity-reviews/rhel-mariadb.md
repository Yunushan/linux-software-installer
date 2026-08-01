# Pre-admission parity review: `rhel/mariadb`

## Scope and status

- Evidence key: `rhel/mariadb`
- Container evidence: `docs/evidence-verification/rhel-mariadb.json`
- Parity level on admission: `intent`
- Admission status: **pending disposable-VM/systemd attestation**.

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome |
| --- | --- | --- |
| `rhel-almalinux-8-030-mariadb` | `legacy/rhel-family/AlmaLinux-8/scripts/30-Mariadb.sh#script` | Downloaded and executed MariaDB's repository setup, selected 10.3–10.6, reset streams, and enabled/started MariaDB. |
| `rhel-centos-7-041-mariadb` | `legacy/rhel-family/Centos-7/scripts/41-Mariadb.sh#script` | Selected MariaDB 10.3–10.6, removed packages and `/var/lib/mysql`, then enabled/started MariaDB. |
| `rhel-red-hat-enterprise-linux-8-024-mariadb` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/24-Mariadb.sh#script` | Downloaded and executed MariaDB's repository setup, selected 10.3–10.6, reset streams, and enabled/started MariaDB. |

## Active replacement contract and boundary

- Target cells: `alma-9-8`, `rocky-9-8`; packages `mariadb-server`, `mariadb`; verified binary `mariadb`; service `mariadb`.
- The active module uses configured signed DNF repositories. It does not execute a repository script, reset streams, remove alternatives or databases, initialize data, change credentials, or activate the service by default.
- Data migration and server exposure remain explicit. Accepted VM evidence must prove default and opt-in `mariadb` behavior before promotion.
