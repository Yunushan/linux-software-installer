# Parity review: `debian/vuze`

## Scope and decision

- Evidence key: `debian/vuze`
- Tested commit: `4feb21e1ae162f5d9dbdd98df2a05aad4ed3c632`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30744748151](https://github.com/Yunushan/linux-software-installer/actions/runs/30744748151), artifact digest `sha256:9b19da4e4779dd10071a94fd5f137f153fadbe335074b5a59e48de18028b82d5`
- Verification report: `docs/evidence-verification/debian-vuze.json`

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision |
| --- | --- | --- | --- |
| `ubuntu-023` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:023` | Installed the discontinued Vuze client from the `vuze-vs` Snap package. | `implemented` |

## Active replacement contract

- Exact target cells: Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64.
- Package and verification binary: `biglybt` / `biglybt` from the configured signed distribution repositories.
- Service behavior: none.

## Reviewer conclusion

BiglyBT is the maintained successor to the discontinued Vuze client. The
active module repeatedly installs and verifies that successor on every declared
target without requiring the legacy Snap route. This is a deliberate
application-successor substitution, so `intent`—not exact-package—parity is
the correct admission level.
