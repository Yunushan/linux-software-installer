# Snap Store route audit

## Scope and outcome

This audit groups the 25 unresolved Snap-related legacy rows. It is a provider
architecture record only: it does not add `snapd`, register a Snap provider,
install a store application, or promote a legacy row.

The group must be split before implementation. Thirteen `snap-store` rows
are Debian-family candidates and may be investigated on the current Ubuntu
targets. Ten RHEL-family store rows and two `snap-bootstrap` rows do not have a
current route: their historical CentOS 7, EL 8, or EPEL-dependent contexts are
not active installer targets. The EPEL bootstrap trust issue remains separately
recorded in [`EPEL_AUDIT.md`](EPEL_AUDIT.md).

## Store-security boundary

Canonical's documentation states that ordinary Snap installs validate
assertions linking a snap to its publisher and store. It also states that
`--dangerous` installs without validation, and that developer mode can proceed
when validation cannot be confirmed. Neither option is acceptable here.

The provider design must therefore reject `--dangerous`, `--devmode`, local
snap files, sideloaded assertions, automatic authentication, and unreviewed
channels. It must request exactly one pre-reviewed public Snap Store object
and record, before mutation:

1. the exact snap name, Snap ID, publisher account identity, verified-publisher
   state, channel and selected revision;
2. the publisher's current confinement declaration and any required interfaces;
3. the assertion-validation result, downloaded object digest and source URL;
4. the target OS/version/architecture, exact installer commit and complete
   repeat-install state; and
5. whether the selected revision declares any background service.

The default must use an explicit stable channel. A non-default track/channel
is a separate reviewed input rather than a fallback. Snap channels are mutable,
so a package name or a stable-channel label is not an immutable lock by itself.

## Confinement and service rules

Strict confinement is the normal minimum. A classic-confinement application
must have an exact, application-specific acknowledgement; the system-wide
provider acknowledgement cannot imply it. The installer must not silently add
`--classic`, modify interfaces, or perform a refresh outside the reviewed
transaction.

Snap applications can also declare background services managed by systemd.
For any selected application with a service, evidence must use the existing
fresh-VM service contract and show the default, explicit activation, repeat,
and cleanup states. A container result is not service evidence.

## Ubuntu candidate scope

The following 13 rows are only the candidate investigation set. Every one
remains `blocked-third-party` until its individual publisher, channel,
confinement, package object, install behavior, and evidence are reviewed.

| Proposed outcomes | Legacy rows |
| --- | ---: |
| `android-studio`, `chromium`, `datagrip`, `dbeaver`, `insomnia`, `midori`, `opera`, `phpstorm`, `postman`, `powershell`, `pycharm-community`, `squirrel-sql`, `webstorm` | 13 |

## RHEL scope

The RHEL-family set has ten application rows plus two bootstrap rows. The
application rows must not use the Debian-family implementation by inference,
and no historical CentOS 7 or EL 8 script is reactivated. A future RHEL route
would first need an authenticated bootstrap provider that satisfies the EPEL
metadata policy, a supported exact current target, and separate service
evidence for `snapd`.

## Admission requirements

Before any row can change, a future implementation must add an opt-in provider
boundary, per-application reviewed records, deterministic noninteractive
handling, confinement/channel acknowledgement gates, and immutable external
evidence for every claimed cell. The resulting GitHub artifact must be
independently hash-checked before the immutable migration inventory or
retirement ledger changes.

Until then, all 25 Snap-related rows remain unresolved and the legacy
repositories are not eligible for removal.

## Sources

- [Snap install modes](https://snapcraft.io/docs/explanation/snap-development/install-modes/)
- [Snap channels and tracks](https://snapcraft.io/docs/explanation/how-snaps-work/channels-and-tracks/)
- [Snap confinement](https://snapcraft.io/docs/explanation/security/snap-confinement/)
- [Ubuntu Snap confinement and services](https://documentation.ubuntu.com/security/security-features/privilege-restriction/snap-confinement/)
