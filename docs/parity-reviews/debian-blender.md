# Parity review: `debian/blender`

## Scope and decision

- Evidence key: `debian/blender`
- Tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`
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
