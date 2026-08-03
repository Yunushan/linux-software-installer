# Parity review: `debian/build-tools`

## Scope and decision

- Evidence key: `debian/build-tools`
- Tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`
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
