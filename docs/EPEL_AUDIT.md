# EPEL route audit (planning only)

This record captures a 2026-07-15 investigation of the 35 `epel-package`
backlog rows and the two EPEL-dependent `snap-bootstrap` rows. It is a route
audit, not repository admission, module support, solver evidence or replacement
evidence. Every affected legacy inventory row remains `blocked-third-party`.

## Exact audit targets

| Target | Immutable image reference | Detected cell |
| --- | --- | --- |
| Rocky Linux 9.8 | `rockylinux/rockylinux:9.8@sha256:8101994123cf3d0a8fee517bee7f39e555c7d92bd2d9eb3303cc988a0eeed00f` | `rocky:9.8:x86_64` |
| AlmaLinux 9.8 | `almalinux:9.8@sha256:d2515c769e7b73f95c4fde38c0a505336ff38f14990c0b7253b77060a049a743` | `almalinux:9.8:x86_64` |

The legacy row IDs also include AlmaLinux 8, CentOS 7 and RHEL 8/9 targets.
Those historical or subscription-bound cells were not probed. The two modern
EL 9.8 images test only whether a shared current route is worth further work;
they cannot establish coverage for the original target rows.

The EPEL 9 signing key observed by the audit has primary fingerprint
`FF8AD1344597106ECE813B918A3872BF3228467C`. The pinned Rocky image's Extras
repository offered `epel-release-9-10`; the pinned Alma image's Extras
repository offered `epel-release-9-9`; the upstream EPEL package index exposed
`epel-release-9-11`. Those versions describe this dated observation and are
not pins or approval to install any of them.

## Trust-model blocker

The current provider schema accepts DNF cells only with
`rpm-repodata-and-package`: authenticated repository metadata and authenticated
packages are both mandatory. EPEL publishes signed RPM packages, but the audit
did not find a detached `repodata/repomd.xml.asc` signature. Installing
`epel-release`, importing its key and setting `gpgcheck=1` therefore does not
satisfy the current metadata-authentication contract. A package-signature-only
interpretation would weaken that contract and is deliberately rejected.

EPEL metalinks advertise cryptographic hashes for `repomd.xml`. That is a
different trust construction, and the current provider parser and schema do
not implement it. Consequently there is no live EPEL provider, and the
backlog's `recommended_action=implement` remains a planning category rather
than a claim that implementation is currently admissible.

Any future `rpm-metalink-hash-and-package` mode must be proposed and reviewed as
an explicit new trust mode. At minimum it must:

1. bind each exact OS/version/architecture cell to an allowlisted HTTPS
   metalink origin and accept only HTTPS mirrors enumerated by the validated
   metalink, with no TLS-disable or ambient-repository fallback;
2. parse the metalink fail closed and verify `repomd.xml` against a strong hash
   advertised by that metalink before parsing any repository metadata;
3. verify every referenced metadata object against its `repomd.xml` checksum
   and reject missing objects, checksum downgrade, mirrors not enumerated by
   the metalink, stale/mismatched repository identity and mixed unplanned
   origins;
4. verify every RPM in the complete solver dependency closure against pinned
   full primary-key fingerprints, including EPEL's
   `FF8AD1344597106ECE813B918A3872BF3228467C`, without trusting ambient RPM key
   state;
5. record exact NEVRA, package digests, dependency origin, metalink and metadata
   hashes, image digest, tested commit and the immutable plan-body digest before
   any repository or package mutation;
6. make any required CRB enablement explicit and reversible, then prove solver,
   real install and repeat-state behavior on every claimed image; and
7. use the real-systemd VM evidence contract for service-bearing outcomes such
   as `fail2ban` and `snapd` rather than treating a container install as service
   evidence.

Until all of those requirements exist in reviewed code and accepted evidence,
the safe result is a fail-closed refusal, not an EPEL mutation path.

## Audited package outcomes

The 37 backlog rows reduce to 17 proposed outcomes. Fourteen outcomes were
solver-resolvable on both pinned images during the exploratory probe. Two were
absent and Wine was indexed but had an unsatisfied dependency.

| Outcome | Backlog rows | Exploratory result on both images | Real-install boundary |
| --- | ---: | --- | --- |
| `clamav` | 1 | `clamav` and `clamd` `1.4.5-1.el9` resolved. | Exploratory install completed. |
| `composer` | 1 | `composer-2.10.2-1.el9` resolved. | Exploratory install completed. |
| `deluge` | 1 | No EPEL 9 package candidate was found. | Not attempted. |
| `dvblast` | 4 | `dvblast-3.4-7.el9` resolved. | Exploratory install completed. |
| `fail2ban` | 2 | `fail2ban-1.1.0-6.el9` resolved. | Package resolution is insufficient; service behavior requires real-systemd VM evidence. |
| `htop` | 1 | `htop-3.3.0-1.el9` resolved. | Exploratory install completed. |
| `links` | 1 | `links-1:2.20.2-8.el9` resolved. | Solver-only in this audit. |
| `magic-wormhole` | 2 | No EPEL 9 package candidate was found. | Not attempted. |
| `monitoring-tools` | 2 | EPEL supplied `htop`, `iftop`, `atop`, `glances`, `monit` and `apachetop`; AppStream supplied `powertop`; BaseOS supplied `iotop`. | The mixed-origin bundle installed exploratorily; a future plan must authenticate and record every origin. |
| `neovim` | 2 | `neovim-0.8.0-0.el9` resolved. | Exploratory install completed. |
| `quassel` | 2 | `quassel-client-0.14.0-10.el9` resolved. | Exploratory install completed. |
| `snap-provider` | 2 | `snapd-2.76-0.el9` resolved from EPEL. | Package resolution is insufficient; bootstrap and service behavior require real-systemd VM evidence. |
| `timeshift` | 2 | `timeshift-22.11.2-1.el9` resolved. | Exploratory install completed. |
| `tinc` | 4 | `tinc-1.0.36-13.el9` resolved. | Exploratory install completed. |
| `transmission` | 3 | `transmission-gtk-4.0.6-1.el9` resolved. | Exploratory install completed. |
| `weechat` | 2 | `weechat-4.9.3-1.el9` resolved. | Exploratory install completed; Rocky emitted a `nodocs`/Guile 3.0 post-install warning that still needs investigation. |
| `wine` | 5 | `wine-8.0-1.el9` was indexed, but dependency solving failed because `mesa-libOSMesa` was unavailable; this matches Fedora bug 2490961. | Not installable through the audited route. |

The exploratory real-install set was therefore `transmission-gtk`, `timeshift`,
`quassel-client`, `nvim`, `dvblast`, `tinc`, `htop`, `composer`, the mixed-origin
monitoring bundle, `clamav` plus `clamd`, and `weechat`. This list records what
the audit exercised; it is not a support list.

## Why these results are not evidence

Normal DNF access in the audit environment failed certificate validation
because of local TLS interception. Availability and install investigation could
continue only by disabling TLS verification. That bypass removes repository
transport authentication, so none of the solver or install results above are
accepted evidence, even where package signatures were available. The probe did
not produce commit-bound, immutable-metadata evidence and did not validate
service behavior.

The exact package versions are useful for backlog triage only. They must be
re-probed without TLS bypass under the future reviewed trust mode and the
ordinary evidence gates before any inventory disposition or support statement
can change.
