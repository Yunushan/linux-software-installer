# Parity review: `debian/blender`

## Scope and decision

- Evidence key: `debian/blender`
- Tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`
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
