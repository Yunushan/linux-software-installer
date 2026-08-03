# Pre-admission parity review: `rhel/samba`

## Scope and status

- Evidence key: `rhel/samba`
- Tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`
- Container evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), aggregate artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`
- Verification report: `docs/evidence-verification/rhel-samba.json`
- Parity level on admission: `intent`
- Admission status: **pending disposable-VM/systemd attestation**. This review
  does not create shares, users, or network exposure.

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome |
| --- | --- | --- |
| `rhel-almalinux-8-028-samba` | `legacy/rhel-family/AlmaLinux-8/scripts/28-Samba.sh#script` | Installed Samba or compiled a mutable upstream source tree, then enabled and started SMB on the distribution route. |
| `rhel-centos-7-039-samba` | `legacy/rhel-family/Centos-7/scripts/39-Samba.sh#script` | Installed Samba, permanently allowed the Samba firewall service, then enabled and started SMB. |
| `rhel-red-hat-enterprise-linux-8-017-samba` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/17-Samba.sh#script` | Installed Samba or compiled a mutable upstream source tree and created a systemd-unit link for the source route. |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Packages: `samba`, `samba-client`
- Package source: each target's configured signed distribution DNF repositories
- Verified binary: `smbclient`
- Service contract: `smb`; default install has no explicit activation and `--enable-services` is separately evidenced
- Share policy: no shares, users, firewall rules, or SELinux policies are changed

## Behavioral comparison

| Concern | Legacy behavior | Active behavior | Decision and rationale |
| --- | --- | --- | --- |
| Package source | Offered distribution packages or a mutable upstream source build. | Installs maintained distribution packages. | Keeps SMB tooling without unmanaged source trees or custom unit links. |
| Service lifecycle | Enabled and started SMB on the distribution route. | Performs no default service mutation. | Server activation is opt-in and needs the attested VM observation. |
| Shares, users, and data | Did not define a safe share/user contract; source route wrote unmanaged files. | Does not create shares, accounts, credentials, or data paths. | Share ACLs and identity mapping are administrator-owned deployment policy. |
| Network and security policy | CentOS 7 permanently opened the Samba firewall service. | Does not alter firewall or SELinux policy. | Network exposure must be explicitly reviewed, not implied by package installation. |

## Pending admission condition

Before these rows can become `implemented`, accepted single-use VM evidence
must prove default and `--enable-services` behavior for `smb` while preserving
existing firewall and SELinux state. The provisioner attestation requirements
are defined in [`SYSTEMD_EVIDENCE.md`](../SYSTEMD_EVIDENCE.md).
