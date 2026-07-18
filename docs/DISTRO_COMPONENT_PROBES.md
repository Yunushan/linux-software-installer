# Distribution-component probe record

This is a **provisional engineering record**, not accepted replacement or
release evidence. On 2026-07-15, the five `distro-component` backlog outcomes
were checked in fresh x86_64 containers using only repositories enabled by the
distribution images. No PPA, vendor repository, remote setup script or
signature bypass was added.

## Immutable probe images

| Target | Resolved image |
| --- | --- |
| Ubuntu 24.04 | `ubuntu@sha256:4fbb8e6a8395de5a7550b33509421a2bafbc0aab6c06ba2cef9ebffbc7092d90` |
| Debian 12 | `debian@sha256:9344f8b8992482f80cba753f323adeaf17690076c095ccff6cc9536be98185dc` |

## Results

| Outcome | Ubuntu 24.04 | Debian 12 | Current decision |
| --- | --- | --- | --- |
| Tor Browser | `torbrowser-launcher` `0.3.7-1ubuntu1` resolved, installed, exposed `/usr/bin/torbrowser-launcher`, and repeated without package-state drift | No package candidate | Keep pending: the package-level launcher evidence is now independently verified, but its separate first-run browser download needs end-to-end evidence before it can replace the legacy direct browser install. |
| PlayOnLinux | `playonlinux` `4.3.4-3` resolved, installed, exposed `/usr/bin/playonlinux`, and repeated without package-state drift | No package candidate | Admitted as `debian/playonlinux`, restricted to `ubuntu:24.04:x86_64`, after immutable GitHub artifact and parity review verification. Applications selected later may download additional content. |
| Telegram Desktop | No package candidate | `telegram-desktop` `4.6.5+ds-2+b1` resolved, installed, exposed `/usr/bin/telegram-desktop`, and repeated without package-state drift | Admitted as `debian/telegram`, restricted to `debian:12:x86_64`, after immutable GitHub artifact and parity review verification. |
| Steam | `steam-installer` `1:1.0.0.79~ds-2` was visible, but the solver rejected the transaction because `steam-libs-i386` was unavailable under the default amd64-only architecture configuration | No package candidate | An Ubuntu 24.04 x86_64 candidate now has an explicit, acknowledged i386 multiarch contract; keep blocked until the fresh full evidence artifact verifies real install and repeat state. |
| MakeHuman | No package candidate | No package candidate | Keep blocked; do not create a speculative module. |

Official package indexes corroborate the package identities: [Ubuntu Tor
Browser Launcher](https://packages.ubuntu.com/noble/torbrowser-launcher),
[Ubuntu PlayOnLinux](https://packages.ubuntu.com/noble/playonlinux), [Ubuntu
Steam Installer](https://packages.ubuntu.com/noble/steam-installer), and
[Debian Telegram Desktop](https://packages.debian.org/bookworm/telegram-desktop).

The successful candidates were exercised through `tests/install-smoke.sh` in
their matching fresh image. That path performs a real noninteractive install,
checks every declared verification binary, repeats the installation with no
metadata refresh, and requires the sorted package/version snapshot to remain
unchanged. The evidence matrix was also checked to emit exactly one declared
cell per module and to omit the inverse same-family target.

## Acceptance boundary

This record preserves the investigated versions, immutable image identities and
decisions. The later full-catalog GitHub artifact supplied independent evidence
for PlayOnLinux and Telegram, which are now admitted with exact target-cell
contracts. [Tor Browser Launcher package evidence](evidence-verification/debian-tor-browser.json)
is independently verified but remains unadmitted because its separate first-run
browser download was not included in the evidence contract. Steam has an
implementation candidate but remains unadmitted pending fresh evidence;
MakeHuman remains an implementation gap.
