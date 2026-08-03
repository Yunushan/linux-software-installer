# Pre-admission parity review: `rhel/firewalld`

## Scope and status

- Evidence key: `rhel/firewalld`
- Tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`
- Container evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), aggregate artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`
- Verification report: `docs/evidence-verification/rhel-firewalld.json`
- Parity level on admission: `intent`
- Admission status: **pending disposable-VM/systemd attestation**. This review is
  not an accepted-evidence record and does not change firewall policy.

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome |
| --- | --- | --- |
| `rhel-red-hat-enterprise-linux-8-039-ufw` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/39-Ufw.sh#script` | Offered a DNF or Snap UFW route; the DNF branch removed Snap UFW, installed `ufw`, then started and enabled `ufw`. It did not declare any firewall rules. |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Package: `firewalld`
- Package source: each target's configured signed distribution DNF repositories
- Verified binary: `firewall-cmd`
- Service contract: `firewalld`; the default install does not explicitly start
  or enable the service, and `--enable-services` is the separately evidenced
  opt-in path
- Rule contract: no ports, services, zones, or rich rules are added

## Behavioral comparison

| Concern | Legacy behavior | Active behavior | Decision and rationale |
| --- | --- | --- | --- |
| Package source and tool | Offered RHEL UFW through DNF or an incomplete `snap ufw` branch. | Installs RHEL-family `firewalld` from configured signed repositories. | `firewalld` is the maintained RHEL-family firewall-management implementation; the legacy Debian-oriented frontend is not retained. |
| Service lifecycle | The DNF branch started and enabled `ufw` automatically. | Declares `firewalld`, but performs no default service mutation; explicit activation is an opt-in service action. | Avoids silently changing boot-time security state. The VM evidence must prove both default and explicit states. |
| Firewall rules and network exposure | The script did not create rules, zones, or allowed ports. | Does not create rules, zones, services, or allowed ports. | Rule and exposure policy remain operator-owned; package parity must not become an implicit network-policy change. |
| Configuration files and defaults | Did not write UFW policy files directly. | Does not write firewall configuration or alter the current firewall backend. | Existing host policy is preserved pending observed service behavior. |
| Credentials, secrets, and data | None. | None. | No credential or user-data migration is part of this replacement. |
| Unsupported legacy side effects | Removed one alternative package and attempted a nonstandard Snap command before auto-enabling a firewall service. | Does not remove alternatives or auto-enable a service. | The active route keeps the firewall-management intent without destructive package switching or unreviewed service activation. |

## Pending admission condition

The referenced aggregate artifact verifies clean and repeat installation on
AlmaLinux 9.8 and Rocky Linux 9.8, but it cannot prove service lifecycle or
preservation of host firewall state. Before the covered row can be marked
`superseded`, an external single-use VM run must provide accepted default-state
and explicit-action evidence for `firewalld`, including the reviewed
provisioning and destruction attestation required by
[`SYSTEMD_EVIDENCE.md`](../SYSTEMD_EVIDENCE.md).
