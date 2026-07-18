# Parity review: `debian/monitoring-tools`

## Scope and decision

- Evidence key: `debian/monitoring-tools`
- Tested commit: `93f4a37923d32f1aa67f71f2f7f22140be0d77a5`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 29652229194](https://github.com/Yunushan/linux-software-installer/actions/runs/29652229194), artifact digest `sha256:756df89ebcc27889612281bd46caa05bde73d6268e3db045019b69a9a8dd71d3`
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
