# Parity review: `debian/irssi`

## Scope and decision

- Evidence key: `debian/irssi`
- Tested commit: `3e19212041ce9707c7c457fa2e2f29c7c0afa9b1`
- Decision: `implemented`
- Parity level: `intent`
- Accepted evidence: [run 30830718610](https://github.com/Yunushan/linux-software-installer/actions/runs/30830718610), artifact digest `sha256:f382d63596e5376ed179fd5f577d3dc8c10b6d000408c656d6081b02e7a815f3`
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
