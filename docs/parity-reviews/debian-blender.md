# Parity review: `debian/blender`

## Scope and decision

- Evidence key: `debian/blender`
- Tested commit: `4feb21e1ae162f5d9dbdd98df2a05aad4ed3c632`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30744748151](https://github.com/Yunushan/linux-software-installer/actions/runs/30744748151), artifact digest `sha256:9b19da4e4779dd10071a94fd5f137f153fadbe335074b5a59e48de18028b82d5`
- Verification report: `docs/evidence-verification/debian-blender.json`

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision |
| --- | --- | --- | --- |
| `ubuntu-129` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:129` | Installed Snap and then classic-confinement Blender, optionally creating a desktop file. | `implemented` |

## Active replacement contract

- Exact target cells: Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64.
- Package and verification binary: `blender` / `blender` from configured signed distribution repositories.
- Service behavior: none.

## Reviewer conclusion

The active module repeatedly installs and verifies Blender without adding the
Snap runtime, classic confinement, or a user desktop-file side effect. The
3D-creation application intent is preserved; `intent` parity is accurate.
