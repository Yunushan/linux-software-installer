# Pre-admission parity review: `debian/nginx`

## Scope and status

- Evidence key: `debian/nginx`
- Container evidence: `docs/evidence-verification/debian-nginx.json`
- Parity level on admission: `intent`
- Admission status: **pending disposable-VM/systemd attestation**.

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome |
| --- | --- | --- |
| `ubuntu-002` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#choice-2` | Added the Nginx PPA, refreshed APT metadata, and installed `nginx`. |

## Active replacement contract and boundary

- Target cells: `ubuntu-24-04`, `ubuntu-26-04`, `debian-12`; package and binary `nginx`; service `nginx`.
- The active module uses configured distribution repositories. It does not add a PPA, replace OpenSSL, create server configuration, open ports, or change firewall rules.
- The PPA and automatic service implication are intentionally not retained. Promotion requires accepted default and `--enable-services` VM evidence with preserved firewall state.
