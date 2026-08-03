# Parity review: `debian/monitoring-tools`

## Scope and decision

- Evidence key: `debian/monitoring-tools`
- Tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`
- Verification report: `docs/evidence-verification/debian-monitoring-tools.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `ubuntu-007` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:007` | Installed `htop`, `iftop`, `atop`, `glances`, `monit`, `powertop`, `iotop`, and `apachetop`. | `implemented` |

## Active replacement contract

- Supported target cells: `debian-12`, `ubuntu-24-04`, `ubuntu-26-04`
- Module and packages: `monitoring-tools`; `htop`, `iftop`, `atop`, `glances`, `monit`, `powertop`, `iotop`, `apachetop`
- Package source and release channel: each target's configured signed distribution APT repositories
- Verification binaries: `htop`, `iftop`, `atop`, `glances`, `monit`, `powertop`, `iotop`, `apachetop`
- Service behavior: no services are enabled or started; Monit is installed as a command only

## Behavioral comparison and intentional differences

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | Installed the eight packages through APT. | Installs the same eight distribution packages through the target's configured APT sources. | Package-set parity across supported current targets. |
| Service lifecycle | Did not enable or start a service. | Does not configure, enable, or start Monit or any other service. | None. |
| Configuration files/defaults | No configuration files were written. | No configuration files are written. | None. |
| Firewall/network exposure | No firewall or listening-service action. | No firewall or listening-service action. | None. |
| Credentials and secrets | None. | None. | None. |
| Data creation, migration, or deletion | No data migration or deletion. | No data migration or deletion. | None. |
| Unsupported or unsafe legacy side effects | None identified in the selected action. | None. | None. |

## Reviewer conclusion

The active module preserves the full legacy command bundle and verifies every
declared binary on each supported target. The legacy action did not establish a
monitoring service contract, and the active module deliberately retains that
non-service behavior. The artifact proves clean and repeat installation on all
three target cells, so `intent` parity is sufficient and accurate.
