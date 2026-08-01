# Pre-admission parity review: `debian/docker`

## Scope and status

- Evidence key: `debian/docker`
- Container evidence: `docs/evidence-verification/debian-docker.json`
- Parity level on admission: `intent`
- Admission status: **pending disposable-VM/systemd attestation**.

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome |
| --- | --- | --- |
| `ubuntu-066` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#choice-66` | Removed existing Docker components, imported Docker's APT key, added its repository, and installed Docker CE. |

## Active replacement contract and boundary

- Target cells: `ubuntu-24-04`, `ubuntu-26-04`, `debian-12`; package `docker.io`; verified binary `docker`; service `docker`.
- The active module uses the distribution package only. It does not remove existing alternatives, add Docker's third-party repository, change daemon configuration, expose sockets, or explicitly activate the service by default.
- The legacy Docker CE channel is intentionally not retained. Accepted VM evidence must prove default and opt-in service lifecycle before promotion.
