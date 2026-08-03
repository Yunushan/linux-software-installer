# Parity review: `debian/vuze`

## Scope and decision

- Evidence key: `debian/vuze`
- Tested commit: `739dd664383221912ab00c18e32e762743c8748f`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30838575507](https://github.com/Yunushan/linux-software-installer/actions/runs/30838575507), artifact digest `sha256:f8120aa9eb93ba6878a0e732b29b17218cef6ae1a78bcb981563dc59c9f91852`
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
