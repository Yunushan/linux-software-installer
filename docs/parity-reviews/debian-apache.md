# Pre-admission parity review: `debian/apache`

## Scope and status

- Evidence key: `debian/apache`
- Container evidence: `docs/evidence-verification/debian-apache.json`
- Parity level on admission: `intent`
- Admission status: **pending disposable-VM/systemd attestation**.

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome |
| --- | --- | --- |
| `ubuntu-003` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#choice-3` | Added the Ondřej Apache PPA, refreshed APT metadata, and installed `apache2`. |

## Active replacement contract and boundary

- Target cells: `ubuntu-24-04`, `ubuntu-26-04`, `debian-12`; package `apache2`; verified binary `apache2ctl`; service `apache2`.
- The active module uses configured distribution repositories, does not add a PPA, does not change site configuration or firewall rules, and activates the service only through the separately evidenced `--enable-services` path.
- The legacy PPA is intentionally not retained. Default and explicit service state, plus preservation of firewall state, require accepted VM evidence before promotion.
