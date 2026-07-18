# Pre-admission parity review: `rhel/nfs-server`

## Scope and status

- Evidence key: `rhel/nfs-server`
- Tested commit: `e3e3be187b1c4b82d6a73e31be49e4852043bed8`
- Real-install evidence: [run 29657213775](https://github.com/Yunushan/linux-software-installer/actions/runs/29657213775), aggregate artifact digest `sha256:034859b6311d086dabf08f54d71d04140707a16c8be680de1172104c105bb5fe`
- Verification report: `docs/evidence-verification/rhel-nfs-server.json`
- Parity level on admission: `intent`
- Admission status: **pending disposable-VM/systemd attestation**. This review is not an accepted-evidence record.

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome |
| --- | --- | --- |
| `rhel-red-hat-enterprise-linux-8-044-nfs-server` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/44-Nfs-Server.sh#script` | Installed `nfs-utils` and `portmap`, overwrote `/etc/exports` with an all-client `no_root_squash` export, then restarted `nfs-server`. |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Package: `nfs-utils`
- Package source: each target's configured signed distribution DNF repositories
- Verified binary: `exportfs`
- Service contract: `nfs-server`; the installer does not create exports, alter firewall policy, or explicitly activate the service

## Behavioral comparison

| Concern | Legacy behavior | Active behavior | Decision and rationale |
| --- | --- | --- | --- |
| Package installation | Installed NFS utilities with the legacy `portmap` dependency. | Installs the maintained distribution `nfs-utils` package. | Retains NFS server tooling on current supported RHEL-family targets. |
| Export policy | Overwrote `/etc/exports` with `/nfsshare <ip-address>(rw,sync,no_root_squash)`. | Does not create or change exports. | Export paths, allowed clients, identity mapping, and root-squash policy are security-critical administrator decisions. |
| Service lifecycle | Explicitly restarted `nfs-server`. | Does not explicitly start, restart, or enable the service. | Package-maintainer defaults and explicit requested behavior must be proven by the required VM/systemd evidence. |
| Network exposure | Implied a remotely accessible export without firewall policy. | Does not change firewall rules or network exposure. | Network policy remains operator-owned. |

## Pending admission condition

The aggregate proof verifies clean and repeat installation on AlmaLinux 9.8 and
Rocky Linux 9.8. It does not prove service behavior. Before the covered legacy
row can be marked implemented, an external single-use VM run must supply the
accepted default-state and explicit-action evidence for `nfs-server`, including
the required provisioning and destruction attestation.
