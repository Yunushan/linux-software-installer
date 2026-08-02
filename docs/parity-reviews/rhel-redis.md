# Pre-admission parity review: `rhel/redis`

## Scope and status

- Evidence key: `rhel/redis`
- Tested commit: `4feb21e1ae162f5d9dbdd98df2a05aad4ed3c632`
- Container evidence: [run 30744748151](https://github.com/Yunushan/linux-software-installer/actions/runs/30744748151), aggregate artifact digest `sha256:9b19da4e4779dd10071a94fd5f137f153fadbe335074b5a59e48de18028b82d5`
- Verification report: `docs/evidence-verification/rhel-redis.json`
- Parity level on admission: `intent`
- Admission status: **pending disposable-VM/systemd attestation**. This review
  does not authorize a Redis listener or firewall opening.

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome |
| --- | --- | --- |
| `rhel-red-hat-enterprise-linux-8-010-redis` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/10-Redis.sh#script` | Offered distribution, Snap, source, and local-RPM routes. The distribution route removed alternatives, enabled and started Redis, and attempted to permit TCP port 6379 permanently. |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Packages: `redis`
- Package source: each target's configured signed distribution DNF repositories
- Verified binaries: `redis-server`, `redis-cli`
- Service contract: `redis`; default installation does not explicitly enable or start it, while `--enable-services` is separately evidenced
- Network contract: no port or firewall policy is changed

## Behavioral comparison

| Concern | Legacy behavior | Active behavior | Decision and rationale |
| --- | --- | --- | --- |
| Source and versions | Offered mutable source/RPM/Snap paths and removed alternatives. | Installs the supported distribution package only. | Retains the Redis-server capability without mutable downloads or destructive switching. |
| Service lifecycle | Enabled and started Redis automatically. | Default install has no explicit service action. | A database listener must not become persistent without an operator request; VM evidence must prove default and opt-in state. |
| Network and firewall | Attempted a permanent `6379/tcp` firewall opening. | Does not modify firewall rules or exposure. | Listener reachability is deployment policy, not package-install policy. |
| Configuration and data | Source/RPM routes could create unmanaged runtime state. | Does not create data, credentials, or Redis configuration. | Persistence, authentication, bind address, and data location remain operator-owned. |

## Pending admission condition

Before this row can become `implemented`, accepted single-use VM evidence must
prove default and `--enable-services` lifecycle behavior and that no unrelated
firewall state changes. The required reviewed provisioning and destruction
attestation is defined in [`SYSTEMD_EVIDENCE.md`](../SYSTEMD_EVIDENCE.md).
