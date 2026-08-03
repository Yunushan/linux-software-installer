# Parity review: `debian/blender`

## Scope and decision

- Evidence key: `debian/blender`
- Tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`
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
