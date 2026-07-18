# Parity review: `debian/build-tools`

## Scope and decision

- Evidence key: `debian/build-tools`
- Tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`
- Verification report: `docs/evidence-verification/debian-build-tools.json`

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision |
| --- | --- | --- | --- |
| `ubuntu-106` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:106` | Added the Ubuntu toolchain PPA and installed the pinned `gcc-8` and `g++-8` packages. | `implemented` |
| `ubuntu-107` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:107` | Upgraded system Python 2 `pip` and installed CMake through it. | `implemented` |

## Active replacement contract

- Exact target cells: Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64.
- Packages and verified tools: distribution `build-essential`, `cmake`, and `pkg-config`; `gcc`, `g++`, `make`, `cmake`, and `pkg-config`.
- Service behavior: none.

## Reviewer conclusion

The active module repeatedly installs a complete supported native build
toolchain. It deliberately does not reproduce the obsolete GCC 8 version pin,
PPA, or unsafe system-wide pip path; current distribution tools are the safe
successor. `intent` parity is accurate.
