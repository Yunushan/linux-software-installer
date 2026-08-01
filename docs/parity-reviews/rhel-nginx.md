# Pre-admission parity review: `rhel/nginx`

## Scope and status

- Evidence key: `rhel/nginx`
- Container evidence: `docs/evidence-verification/rhel-nginx.json`
- Parity level on admission: `intent`
- Admission status: **pending disposable-VM/systemd attestation**.

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome |
| --- | --- | --- |
| `rhel-almalinux-8-002-nginx` | `legacy/rhel-family/AlmaLinux-8/scripts/2-Nginx.sh#script` | Offered package/source Nginx and OpenSSL routes, then enabled/started Nginx. |
| `rhel-almalinux-9-008-nginx` | `legacy/rhel-family/AlmaLinux-9/scripts/8-Nginx.sh#script` | Offered package/source/RPM/repository Nginx routes and enabled/started Nginx. |
| `rhel-centos-6-002-nginx` | `legacy/rhel-family/Centos-6/scripts/2-Nginx.sh#script` | Installed Nginx. |
| `rhel-centos-7-002-nginx` | `legacy/rhel-family/Centos-7/scripts/2-Nginx.sh#script` | Offered package/source/RPM/repository Nginx routes and enabled/started Nginx. |
| `rhel-red-hat-enterprise-linux-8-009-nginx` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/9-Nginx.sh#script` | Offered package/source/RPM/repository Nginx routes and enabled/started Nginx. |
| `rhel-red-hat-enterprise-linux-9-002-nginx` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-9/scripts/2-Nginx.sh#script` | Offered package/source/RPM/repository Nginx routes and enabled/started Nginx. |

## Active replacement contract and boundary

- Target cells: `alma-9-8`, `rocky-9-8`; package and binary `nginx`; service `nginx`.
- The active module uses configured signed DNF repositories and does not modify OpenSSL, add a repository, write a custom unit, change configuration, open ports, or change firewall rules.
- The unsafe system-library and repository modifications are intentionally not retained. Accepted VM evidence must prove the default and opt-in service states before promotion.
