# Parity review: `debian/irssi`

## Scope and decision

- Evidence key: `debian/irssi`
- Tested commit: `739dd664383221912ab00c18e32e762743c8748f`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30838575507](https://github.com/Yunushan/linux-software-installer/actions/runs/30838575507), artifact digest `sha256:f8120aa9eb93ba6878a0e732b29b17218cef6ae1a78bcb981563dc59c9f91852`
- Verification report: `docs/evidence-verification/debian-irssi.json`

## Legacy row covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision |
| --- | --- | --- | --- |
| `ubuntu-047` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#menu:047` | Downloaded and globally trusted a third-party key, added an obsolete openSUSE repository, installed `irssi`, and could create a desktop file with a downloaded icon. | `implemented` |

## Active replacement contract

- Exact target cells: Debian 12, Ubuntu 24.04, and Ubuntu 26.04 x86_64.
- Package and verification binary: `irssi` / `irssi` from the configured signed distribution repositories.
- Service behavior: none.

## Reviewer conclusion

The active module repeatedly installs and verifies the Irssi client on every
declared target. It preserves the client-installation intent while intentionally
rejecting the unsafe legacy key, obsolete repository, downloaded icon, and
user desktop-file side effects. `intent` parity is accurate.
