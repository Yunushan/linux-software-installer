# Pre-admission parity review: `rhel/apache`

## Scope and status

- Evidence key: `rhel/apache`
- Container evidence: `docs/evidence-verification/rhel-apache.json`
- Parity level on admission: `intent`
- Admission status: **pending disposable-VM/systemd attestation**.

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome |
| --- | --- | --- |
| `rhel-almalinux-8-008-apache` | `legacy/rhel-family/AlmaLinux-8/scripts/8-Apache.sh#script` | Offered package or mutable source build, then enabled/started `httpd`. |
| `rhel-centos-6-008-apache` | `legacy/rhel-family/Centos-6/scripts/8-Apache.sh#script` | Installed `httpd`. |
| `rhel-centos-7-008-apache` | `legacy/rhel-family/Centos-7/scripts/8-Apache.sh#script` | Offered package or mutable source build, wrote a unit, then enabled/started `httpd`. |
| `rhel-red-hat-enterprise-linux-8-006-apache` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/6-Apache.sh#script` | Offered package, source, and local-RPM builds, then enabled/started `httpd`. |
| `rhel-red-hat-enterprise-linux-9-003-apache` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-9/scripts/3-Apache.sh#script` | Offered package, source, and local-RPM builds, then enabled/started `httpd`. |

## Active replacement contract and boundary

- Target cells: `alma-9-8`, `rocky-9-8`; package and binary `httpd`; service `httpd`.
- The active module uses configured signed DNF repositories, does not compile source, overwrite a unit, alter OpenSSL, add a repository, open firewall ports, or activate the service by default.
- Custom builds and automatic listener activation are intentionally excluded. Promotion needs accepted VM evidence for default and opt-in `httpd` states and unchanged firewall state.
