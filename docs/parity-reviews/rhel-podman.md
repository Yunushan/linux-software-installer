# Parity review: `rhel/podman`

## Scope and decision

- Evidence key: `rhel/podman`
- Tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`
- Verification report: `docs/evidence-verification/rhel-podman.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `rhel-almalinux-8-015-docker` | `legacy/rhel-family/AlmaLinux-8/scripts/15-Docker.sh` | Added Docker CE repository, installed a pinned `containerd.io` RPM, and enabled Docker. | `implemented` |
| `rhel-centos-7-015-docker` | `legacy/rhel-family/Centos-7/scripts/15-Docker.sh` | Added Docker CE repository, installed Docker, and enabled Docker. | `implemented` |
| `rhel-red-hat-enterprise-linux-8-027-docker` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/27-Docker.sh` | Added Docker CE repository, installed a pinned `containerd.io` RPM, and enabled Docker. | `implemented` |
| `rhel-red-hat-enterprise-linux-8-043-podman` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/43-Podman.sh` | Offered distribution Podman, source builds, Nix, or Ansible installation. | `implemented` |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Module and packages: `podman`; `podman`, `podman-docker`
- Package source and release channel: configured signed DNF repositories; no Docker CE repository, pinned RPM, source tree, Nix, or Ansible role is added
- Verification binaries: `podman`, `docker` compatibility command
- Service behavior: none; Podman is daemonless

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Docker routes added Docker CE repositories and pinned RPMs; Podman routes offered source, Nix, and Ansible. | Installs distribution Podman and the `docker` compatibility package. | Preserves OCI container-engine workflows without unreviewed installation channels. |
| Service lifecycle | Docker scripts started and enabled a long-running Docker daemon. | No service is started or enabled. | Deliberate daemonless supersession, reducing background-service and socket exposure. |
| Configuration files/defaults | Podman source route downloaded container registry and policy files. | Does not write container policy or registry configuration. | Avoids overriding local container trust policy. |
| Firewall/network exposure | No firewall rule, but Docker created a daemon/socket surface and external setup paths were used. | No listener or daemon is enabled. | Safer default operational posture. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | The source route created source trees and system configuration; Docker routes changed repository configuration. | Installs package-managed files only. | Avoids unmanaged build trees and persistent third-party repository changes. |
| Unsupported or unsafe legacy side effects | Pinned remote RPM, repository mutation, automatic daemon activation, source builds, Nix, and Ansible execution. | None of those are retained. | The active contract is reproducible and non-destructive. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies a daemonless OCI
container engine and Docker-compatible command on both supported RHEL-family targets.
It safely replaces the container-engine intent of all four legacy scripts; `intent`
parity is accurate.
