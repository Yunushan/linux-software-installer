# AnyDesk provider audit

## Scope and outcome

This audit evaluates the official AnyDesk Debian and RPM repositories for the
two blocked `anydesk` legacy entries. It is planning evidence only. It does
not register a provider, add an `anydesk` module, or change either legacy row
from `blocked-third-party`.

| Legacy ID | Immutable source locator | Current-target conclusion |
| --- | --- | --- |
| `ubuntu-155` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#choice-155` | A future Debian provider may be evaluated only on an explicitly supported modern Debian-family target. |
| `rhel-centos-7-032-anydesk` | `legacy/rhel-family/Centos-7/scripts/32-Anydesk.sh#script` | CentOS 7 remains outside the active installer; the vendor's published support policy does not establish an EL 9 route. |

The observed APT and RPM metadata are signed by the same published AnyDesk key.
That makes a future Debian-family provider a possible candidate, but it does
not establish package locks, target-cell compatibility, a service contract, or
installation evidence. The vendor's current Linux support article lists RHEL 8,
not the active EL 9 evidence targets, so the historical CentOS 7 RPM row has
no current RHEL promotion route.

## Reproducible observation — 2026-08-01

Public HTTPS resources were retrieved with certificate verification enabled
and without accepting a non-HTTPS redirect.

| Item | URL | Observed result |
| --- | --- | --- |
| Published repository key | `https://keys.anydesk.com/repos/DEB-GPG-KEY` and `https://keys.anydesk.com/repos/RPM-GPG-KEY` | Identical objects; SHA-256 `94a83c7e40d5919e897041e7c8b07ed46bd830114a6e4bcf1607675ec4bcecd5`; primary fingerprints `06B5EA2FAE208E7CDA9761DCA2FB21D5A8772835` and `AB719E5705B25C8F2380289E64F25B0EBA3F0A7C` |
| Debian signed metadata | `https://deb.anydesk.com/dists/all/InRelease` | Signature verified with primary key `06B5EA2FAE208E7CDA9761DCA2FB21D5A8772835`; signed identity `Origin: philandro Software GmbH`, `Label: AnyDesk`, `Suite: all`, `Codename: all`; SHA-256 `b731be8978f823d7249066e6c8b96a923cab8087a2bc0509b2f21e422f352dc1` |
| RPM signed metadata | `https://rpm.anydesk.com/x86_64/repodata/repomd.xml` and `.asc` | Detached signature verified with the same primary key; `repomd.xml` SHA-256 `bc260f89436346d99edbfd5fa29a6f28021933fa10576fc3c61e77e9cea4880d`; signature SHA-256 `bb1fb2e719293f53cd294d2408bd6f69b385a7ed1c2c811424121fd5789cdbd6` |

The verified signing identity was `AnyDesk Software GmbH <ops@anydesk.com>`.
This proves the observed metadata was signed by the pinned key; it does not
alone prove publisher identity or make a mutable repository state a package
lock.

The vendor's current [Debian repository guide](https://deb.anydesk.com/howto.html)
publishes `https://deb.anydesk.com` with `suite=all`, `components=main`, and a
scoped `Signed-By` keyring. Its [RPM repository guide](https://rpm.anydesk.com/howto.html)
publishes `https://rpm.anydesk.com/$basearch/` with `gpgcheck=1` and
`repo_gpgcheck=1`. The vendor's [Linux support policy](https://support.anydesk.com/anydesk-for-linux-raspberry-pi)
lists Ubuntu 18.04+, Debian 9+, and RHEL 8; it does not claim support for
CentOS 7 or current EL 9 derivatives.

## Candidate boundaries

Any future Debian provider must use a checked-in copy of the reviewed key, the
`all/main` layout, APT `Signed-By`, signed Release metadata, and the exact
`Origin` above. It must not run vendor setup scripts, use `apt-key`, permit
unauthenticated packages, or leave the repository active without the existing
explicit persistence acknowledgement.

The old RHEL-family AnyDesk row remains blocked. A current RPM signature is
not a supported-target claim: the vendor policy does not cover the active EL 9
cells, and CentOS 7 is deliberately unavailable in this installer. AnyDesk
also installs an `anydesk` systemd service, so a future module needs a declared
service contract and fresh-VM service-state evidence.

## Remaining admission requirements

Before either inventory row can change, all of the following must be complete:

1. select vendor-supported exact target cells and add a reviewed, digest-bound
   provider tree with the pinned key and immutable package locks;
2. prove signed metadata, package signatures, package identity/digest, origin,
   solver behavior, clean install, repeat install, update behavior and cleanup
   on every claimed target;
3. prove the service contract in fresh disposable VMs; and
4. independently verify the external artifact digest before changing the
   immutable inventory or retirement ledger.

Until then, both AnyDesk rows remain `blocked-third-party`, the provider
registry remains empty, and neither old repository is eligible for removal.
