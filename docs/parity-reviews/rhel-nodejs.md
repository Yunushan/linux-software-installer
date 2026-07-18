# Parity review: `rhel/nodejs`

## Scope and decision

- Evidence key: `rhel/nodejs`
- Tested commit: `27646bafef32bb78c3f5f97d3b9b41451ee96e2e`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29657467906](https://github.com/Yunushan/linux-software-installer/actions/runs/29657467906), artifact digest `sha256:5d84feef4344c29d39f8de5b713b55b3f12cb1b1378800fe68ca6b57c4cde30c`
- Verification report: `docs/evidence-verification/rhel-nodejs.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `rhel-almalinux-8-031-nodejs-npm` | `legacy/rhel-family/AlmaLinux-8/scripts/31-Nodejs-Npm.sh` | Selected Node.js 10, 12, 14, or 16 through DNF module streams. | `implemented` |
| `rhel-centos-7-042-nodejs-and-npm` | `legacy/rhel-family/Centos-7/scripts/42-Nodejs-And-Npm.sh` | Selected Node.js 10–16/current/LTS using NodeSource curl-to-shell setup scripts. | `implemented` |
| `rhel-red-hat-enterprise-linux-8-029-nodejs-and-npm` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/29-Nodejs-And-Npm.sh` | Selected Node.js 10, 12, 14, or 16 through DNF module streams. | `implemented` |
| `rhel-red-hat-enterprise-linux-9-015-nodejs-and-npm` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-9/scripts/15-Nodejs-And-Npm.sh` | Selected Node.js versioned module streams. | `implemented` |

## Active replacement contract

- Supported target cells: `alma-9-8`, `rocky-9-8`
- Module and packages: `nodejs`; `nodejs`, `npm`
- Package source and release channel: configured signed DNF repositories; no curl-to-shell installer or external repository is added
- Verification binaries: `node`, `npm`
- Service behavior: none

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Chose obsolete module streams; CentOS 7 used NodeSource curl-to-shell setup scripts. | Installs distribution Node.js and npm packages. | Preserves a supported runtime and package client without an arbitrary remote shell pipeline. |
| Service lifecycle | None. | None. | None. |
| Configuration files/defaults | Legacy module selection rewrote DNF stream state. | No stream override is made. | Avoids pinning an obsolete release channel. |
| Firewall/network exposure | No firewall or listener action; NodeSource setup was downloaded and executed. | Package-manager network access only during installation. | No added listener or arbitrary shell execution. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | Removed installed Node.js packages and deleted YUM cache files before switching versions. | Does not remove alternatives or delete package caches. | Avoids destructive package switching and cache mutation. |
| Unsupported or unsafe legacy side effects | Obsolete streams, curl-to-shell repository setup, package removal, and cache deletion. | None of those are retained. | The active contract is deterministic and non-destructive. |

## Reviewer conclusion

The active module cleanly and repeatedly installs and verifies Node.js and npm on both
supported RHEL-family targets. It safely replaces the runtime/package-client intent of
all four legacy scripts; `intent` parity is accurate.
