# Third-party provider backlog

The machine-readable [provider backlog](provider-backlog.tsv) turns every current
`blocked-third-party` row in `legacy-inventory.tsv` into a proposed next action.
It is a planning ledger, not replacement evidence: all 127 source inventory rows
remain `blocked-third-party`, with `replacement=-` and `parity_level=unassessed`,
until their normal evidence and disposition gates are independently satisfied.

The dated [`EPEL_AUDIT.md`](EPEL_AUDIT.md) investigation covers all 35
`epel-package` rows and both EPEL-dependent `snap-bootstrap` rows. It found 14
solver-resolvable outcomes on the two pinned EL 9.8 images, but also confirmed
that EPEL has no detached `repomd.xml` signature. The exploratory probes needed
a TLS-verification bypass because of local interception, so they are not
evidence and do not make a live provider admissible.

The dated [`KUBECTL_PROVIDER_AUDIT.md`](KUBECTL_PROVIDER_AUDIT.md) investigation
records a planning-only `kubernetes-v1-36` preview candidate for four exact
modern cells. Its exact repository coordinates and package locks are planning
inputs only: the digest-bound apply/deactivate primitives exist, but no
provider is admitted for this candidate; key provenance/expiry, APT replay,
TLS-clean EL probes and accepted evidence remain explicit blockers.

The dated [`VSCODE_PROVIDER_AUDIT.md`](VSCODE_PROVIDER_AUDIT.md) investigation
records a planning-only Microsoft repository route for the two Visual Studio
Code rows. The vendor's published APT and RPM coordinates are useful planning
inputs only: no provider is admitted for this route, and key provenance and
lifecycle controls, exact-cell locks, authenticated metadata/origin checks and
accepted evidence remain explicit blockers.

Run `bash tests/validate-provider-backlog.sh` after changing either ledger. The
validator requires an exact one-to-one join by `legacy_id`, rejects duplicate or
extra rows, checks capability identity, and freezes both the action and strategy
totals below.

## Schema

| Column | Meaning |
| --- | --- |
| `legacy_id` | Exact key from the blocked third-party inventory row. |
| `normalized_capability` | Cross-check value copied from that inventory row. |
| `strategy` | Provider or handoff route to investigate. |
| `recommended_action` | One of `implement`, `conditional-artifact`, or `terminal-handoff`. |
| `replacement_outcome` | Proposed module slug or documented handoff/migration outcome; it is not a current replacement claim. |
| `rationale` | Concise acceptance boundary for the proposed route. |

## Frozen action totals

| Recommended action | Rows | Meaning |
| --- | ---: | --- |
| `implement` | 110 | Build and verify a provider/module candidate. |
| `conditional-artifact` | 17 | Automate only when immutable, authenticated upstream artifacts can be proved. |
| `terminal-handoff` | 0 | No reviewed handoff remains unresolved in the active backlog. |
| **Total** | **127** | Exact current `blocked-third-party` coverage. |

`implement` is an instruction to begin provider work, not a claim that the
capability is already supported. `terminal-handoff` likewise does not make a
legacy row terminal; official evidence and the ordinary inventory review are
still required before changing its disposition.

## Completed terminal review

The 31 rows previously recommended for terminal review now have durable official
evidence in [`LEGACY_DISPOSITIONS.md`](LEGACY_DISPOSITIONS.md): 30 are reviewed
`out-of-scope` handoffs and Elastic Enterprise Search alone is `retired` based
on explicit upstream discontinuation. Those terminal rows are intentionally
absent from this TSV because it covers only current `blocked-third-party` rows.

## Strategy ledger

| Strategy | Action | Rows | Acceptance boundary |
| --- | --- | ---: | --- |
| `authenticated-download` | `terminal-handoff` | 0 | Keep credentials, license acceptance, entitlements, and vendor kernel integration in the vendor workflow. |
| `community-client-handoff` | `terminal-handoff` | 0 | Prefer the service's supported client or web surface over owning an unofficial client. |
| `distro-component` | `implement` | 3 | Verify maintained Debian-family packages on every claimed image. |
| `epel-package` | `implement` | 35 | Current admission is blocked; review a metalink-hash-and-package trust mode before producing authenticated solver/install evidence. |
| `infrastructure-handoff` | `terminal-handoff` | 0 | Leave topology, secrets, certificates, databases, and enrollment to the upstream deployment workflow. |
| `maintenance-handoff` | `terminal-handoff` | 0 | Leave privileged cleanup policy to distribution-supported administration and recovery tools. |
| `public-artifact` | `conditional-artifact` | 17 | Require an immutable version plus a trusted upstream signature or digest; otherwise hand off. |
| `retired-review` | `terminal-handoff` | 0 | Record official discontinuation and migration evidence before closing scope. |
| `rpm-fusion` | `implement` | 10 | Add an explicit signed RPM Fusion provider and prove package resolution and real installation. |
| `snap-bootstrap` | `implement` | 2 | Resolve the EPEL metadata-trust blocker, then require explicit opt-in and real-systemd service evidence. |
| `snap-store` | `implement` | 32 | Review publisher, channel, confinement, and repeat-install behavior before admitting a snap. |
| `vendor-apt` | `implement` | 12 | Use a scoped keyring and verify signed repository, solver, install, and update behavior. |
| `vendor-rpm` | `implement` | 16 | Pin the vendor key identity and verify signed repository, solver, install, and update behavior. |

## Machine-checked closure shape

The validator also cross-checks every proposed `replacement_outcome` against
the active module catalog. The 127 rows represent 82 normalized capabilities
and 80 canonical outcomes. Of those rows, 47 point to 20 existing modules:
`clamav`, `composer`, `deluge`, `dvblast`, `fail2ban`, `ffmpeg`, `htop`,
`magic-wormhole`, `monitoring-tools`, `neovim`, `quassel`, `timeshift`,
`steam`, `tinc`, `transmission`, `vlc`, `weechat`, `wine`, `telegram`, and
`tor-browser`.

That is implementation reuse, not current coverage. Forty-five rows are
RHEL-family gaps while their 18 matching modules declare Debian-family support
only; that includes the RHEL Telegram row whose matching module is Debian
12-only. Tor Browser Launcher remains one Debian distro-component candidate
restricted to one exact Tier-1 cell.
Therefore the number of family-wide ready reuse rows remains **zero**, with two
target-restricted reuse rows. A row remains blocked until its applicable target
coverage and durable solver/install/repeat-install evidence are accepted. The
other 80 rows cover 60 outcomes for which no active module exists yet.

Three rows can investigate distribution components without adding an external
trust root: MakeHuman, Steam, and Tor Browser. PlayOnLinux and Telegram are
now accepted on their exact verified target cells. The probe history and Tor
Browser's remaining boundary are recorded in
[`DISTRO_COMPONENT_PROBES.md`](DISTRO_COMPONENT_PROBES.md). The other 124 rows
require an external signed repository/store or an immutable, authenticated
upstream artifact. Their shared implementation leverage is:

| Closure group | Rows | Canonical outcomes in group | Existing-module reuse | Required work |
| --- | ---: | ---: | ---: | --- |
| Distribution components | 3 | 3 | 2 rows / 2 outcomes | Tor Browser needs first-run browser evidence; Steam needs accepted fresh multiarch evidence and MakeHuman remains unavailable. |
| EPEL | 35 | 16 | 34 rows / 15 outcomes | Resolve the metadata-trust blocker in `EPEL_AUDIT.md`; only then re-probe exact packages and consider RHEL mappings or a new `links` module. |
| RPM Fusion | 10 | 2 | 10 rows / 2 outcomes | One signed RPM Fusion provider plus RHEL mappings for existing `ffmpeg` and `vlc`. |
| Vendor APT and RPM | 28 | 16 | 0 rows / 0 outcomes | Family-specific repository adapters and new modules; five outcomes span both families. |
| Snap bootstrap and store | 34 | 26 | 0 rows / 0 outcomes | Resolve the EPEL-dependent bootstrap trust blocker before designing an opt-in snap subsystem, application outcomes and service/confinement evidence. |
| Public artifacts | 17 | 17 | 0 rows / 0 outcomes | One fail-closed version/signature-or-digest contract per artifact. |

The outcome column is not additive because Telegram appears in both the
distribution-component and Snap groups. Across the complete backlog there are
81 unique outcomes, including the Snap provider bootstrap outcome.

This gives a concrete closure order: finish the three distribution components;
resolve the EPEL trust-model blocker before any EPEL implementation, investigate
RPM Fusion separately, consolidate vendor APT/RPM work by product, and defer the
opt-in Snap subsystem until its EPEL bootstrap is admissible. Individual public
artifacts remain last. No current row has been moved to a terminal disposition
by this analysis: a terminal change still needs the durable official evidence
described in `LEGACY_DISPOSITIONS.md`.

## Promotion rules

A proposed implementation should not be promoted into the legacy inventory
until the provider has deterministic noninteractive behavior, authenticated
metadata or artifacts, supported target-family guards, solver preflight,
idempotent repeat-install behavior, actionable failure diagnostics, and real
installation evidence on every claimed image. Public-artifact candidates must
also have a stable version-discovery policy and fail closed when signature or
digest verification is unavailable.

Work should be grouped by provider so one hardened implementation can serve all
matching rows: distribution components first; then EPEL trust-model review and
a separate RPM Fusion investigation; then vendor APT/RPM; then Snap only after
its bootstrap trust and systemd contracts exist; and finally individual public
artifacts. Handoff recommendations must remain in the backlog until the
repository's terminal-evidence rules are met; the completed 31-row review
demonstrates that promotion path without weakening the evidence requirement.
