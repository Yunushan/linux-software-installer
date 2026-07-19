# Legacy replacement and retirement contract

This document defines what must be true before the two historical installer
repositories can be treated as fully replaced and archived. It is a release
governance contract, not a claim that every legacy command should be
reproduced. Some old behavior is obsolete, unsafe or dependent on an external
vendor repository and must instead receive an explicit, evidence-backed
disposition.

## Immutable source baseline

The replacement denominator is fixed by the snapshots documented in
[`LEGACY.md`](LEGACY.md):

| Source | Snapshot commit | Raw replacement units |
|---|---|---:|
| Ubuntu 16.04 menu | `7de4b1d01f9372b3245dea31ee1e5307a650aadb` | 159 choices |
| RHEL-family scripts | `f23009ad10f9719bf09ec0c1a87679e0e2653a5c` | 196 scripts |
| **Total** | | **355 entries** |

The 196 RHEL-family script instances contain 87 distinct filename-derived
capability names. Both numbers matter: canonical capabilities help product
planning, while all 196 distro-specific instances must remain traceable
because their package sources and behavior can differ.

[`legacy-inventory.tsv`](legacy-inventory.tsv) is the canonical raw inventory.
Run the standalone validator after changing it:

```bash
bash tests/validate-legacy-inventory.sh
bash tests/validate-legacy-quarantine.sh
bash tests/validate-provider-backlog.sh
```

The validator reconciles the inventory with all 159 source menu choices and
all 196 source scripts. It also checks unique IDs, source references, allowed
states and the 355-entry total. The immutable launcher mistakes that affect
the interpretation of nine rows are recorded separately in
[`legacy-source-defects.tsv`](legacy-source-defects.tsv) and validated against
their exact preserved source lines.

The TSV schema is deliberately reviewable without a database:

| Column | Purpose |
|---|---|
| `legacy_id` | Stable unique identifier for the raw replacement unit |
| `source_set`, `source_path`, `source_item` | Immutable source locator |
| `display_name`, `normalized_capability` | Original label and canonical planning key |
| `target_family` | Maintained successor family, not permission to run on the legacy OS |
| `disposition` | Decision state defined below |
| `replacement` | Active module, profile or supported workflow, or `-` while unresolved |
| `parity_level` | Accepted scope of equivalence, or `unassessed` |
| `evidence` | Durable evidence reference, or `-` while unresolved |
| `rationale` | Human-reviewed explanation of the decision and intentional differences |

## Current coverage truth

The current inventory snapshot has 192 terminal rows: 107 `implemented`, one
`superseded`, 20 `blocked-safety`, 25 `retired` and 39 `out-of-scope`. The
remaining 163 rows are non-terminal: 37 `planned` active-module candidates and
126 `blocked-third-party` provider gaps. No legacy row is called replaced
merely because a similarly named package module exists. The active catalog
contains 103 low-risk package modules plus one explicit medium-risk multiarch
module; 108 active-replacement rows now carry accepted evidence and completed
their row-by-row terminal parity admission.
parity and installation evidence.

A mechanical comparison after the current package-only migration batches finds:

- 4 planned Ubuntu rows with an explicit Debian-family active-module candidate
  and 53 `blocked-third-party` provider/repository rows;
- 33 planned RHEL rows with an explicit RHEL-family active-module candidate and
  74 `blocked-third-party` provider/repository rows;
- 37 candidate rows in total and 126 provider/repository rows in total, all
  still non-terminal pending their applicable evidence or reviewed handoff.

These are discovery numbers, not accepted parity. For example, current modules
deliberately do not reproduce pinned PHP, Python 2, GCC 8, JDK 8/11 selection,
source builds, automatic vendor repositories or legacy configuration changes.
The exact proposed route for all 126 third-party rows is recorded in
[`provider-backlog.tsv`](provider-backlog.tsv) and explained in
[`PROVIDER_BACKLOG.md`](PROVIDER_BACKLOG.md): 109 provider/module candidates
and 17 conditional authenticated-artifact candidates. Thirty additional
handoff rows and one upstream-retired product have already moved through the
reviewed terminal-disposition gate. Backlog rows remain planning decisions
only; their inventory states do not change until the normal evidence gates
pass.

PlayOnLinux, Debian Telegram, and Steam have accepted exact-target evidence and
are terminal `implemented` rows. Steam is restricted to Ubuntu 24.04 x86_64
with explicit i386 multiarch acknowledgement. The two remaining
`distro-component` outcomes—Tor Browser and MakeHuman—remain blocked because
their required package/first-run evidence is not yet accepted. The exact image
and package probe record is
[`DISTRO_COMPONENT_PROBES.md`](DISTRO_COMPONENT_PROBES.md).

The push/PR GitHub Actions workflow is configured to run detection, catalog and
read-only plan smoke tests plus a separate enabled-repository resolution matrix.
A scheduled/manual real-install workflow is configured to install every
supported catalog module in bounded catalog batches, check post-install binary
presence and compare package/version state across a repeat install. Batch
success is not standalone parity evidence for each module. A separate manual
standalone workflow is configured
as a 105-module matrix; each module job sequentially runs its applicable images
in separate fresh containers, preserving all 374 independent module-image
cells without exceeding the workflow matrix limit. It emits structured
pre/install/repeat evidence and an aggregate coverage/checksum bundle. A prior
externally hashed aggregate admitted 79 module-family keys and 108 active rows,
including the Steam multiarch contract and thirty-four additional non-service
Debian-family replacements.
A separate manual self-hosted `Systemd VM
evidence` workflow can validate one exact systemd plan row on one externally
provisioned disposable VM; it remains provisional until an independent
provision/create/destroy attestation verifier is implemented.
Bundle-internal hashes provide corruption checks, not an independent trust
anchor. Durable promotion must additionally record an externally published
GitHub artifact digest, signed release hash or attestation.

The dependency-free operational suite now exercises the locally deterministic
parts of G5: root and confirmation gates, fail-closed lock contention,
no-clobber protected logs and sensitive-argument redaction, package and binary
verification failures, stop-on-error, refresh-once behavior, and explicit
service activation. These are unit-level safety checks, not a substitute for
the 64 exact systemd VM executions and host-state comparisons identified
below.

The container jobs receive a credential-free `git archive` export of the
tested commit. Their writable raw evidence trees are never artifact upload
paths: the container is removed first, then a no-follow sanitizer copies only
directories and single-link regular files to a host-controlled tree. Links,
special files, hard links and destination collisions are rejected; cleanup or
sanitization failure never falls back to uploading raw content.

Consequently, no distro is yet
`release-verified` under this contract, even when its current CI jobs are green.

The repository therefore does **not** currently satisfy the retirement gate.
It replaces the duplicated execution path, but it must not claim complete
legacy feature replacement yet.

### Planned-row promotion readiness

[`legacy-promotion-readiness.tsv`](legacy-promotion-readiness.tsv) is the
derived, machine-checked promotion ledger for active replacement rows. It has
145 rows: 107 currently `implemented`, one `superseded` and 37 still `planned`.
An admitted row remains in the ledger after moving to `implemented` or
`superseded`. Validate it against the live inventory, target matrix and module
contracts with:

```bash
bash tests/validate-legacy-promotion-readiness.sh
```

For a reviewed inventory or contract change, regenerate the deterministic TSV
and review its diff before committing it:

```bash
bash tests/validate-legacy-promotion-readiness.sh --emit \
  > docs/legacy-promotion-readiness.tsv
```

The current ledger has 108 Debian-family and 72 RHEL-family active-replacement
rows. One hundred eight rows have accepted evidence and promotion readiness `yes`;
37 remain at evidence class `none` and readiness `no`. Their mappings collapse
to 83 unique modules and 93 module-family evidence keys, so duplicate legacy
entries can share evidence. Those keys require 250 standalone module-image
cells. A full-catalog standalone run emits 374 cells; its coverage includes
every active-replacement evidence key.

The ledger labels 140 rows as `implemented-candidate` and five as
`superseded-candidate`; these are review routes rather than a substitute for
the inventory disposition. The five explicit supersession rationales are
`ubuntu-024`, `ubuntu-038`, `ubuntu-121`, `ubuntu-122`, and
`rhel-red-hat-enterprise-linux-8-039-ufw`. A reviewer must still confirm each
row's retained outcome and intentional differences before changing the source
inventory.

Thirty-two rows share 11 service-bearing module-family contracts across nine
modules. Their normal standalone footprint is 25 module-image cells. G5 also
requires each of those 14 contracts on every exact family target, with and without
`--enable-services`, for 64 disposable systemd
executions. Evidence may be reused by every row with the same `evidence_key`.
[`SYSTEMD_EVIDENCE.md`](SYSTEMD_EVIDENCE.md) defines the executable 64-row
plan, single-use fresh-VM runner, captured host-state contract and structural
validator. No accepted VM execution exists: all local runner bundles remain
provisional until an external provisioning attestation and durable trust
anchor are implemented.

Repository-solver output and locally generated standalone bundles may be linked
as `provisional` in the readiness ledger when the reference is a checked-in
report or durable HTTPS URL. They do not make a row promotion-ready. The current
repository-resolution job is a useful G3 signal, but its console-only result and
mutable image tags are not accepted per-module evidence tied to exact image
digests. A local standalone bundle has stronger G4 integrity metadata, but its
self-contained hashes are not an external authenticity anchor.

### Accepted-evidence admission

[`accepted-evidence.tsv`](accepted-evidence.tsv) currently contains 79
accepted module-family admissions, covering 108 active ledger and terminal
inventory rows. Each
record was created only after an external bundle was downloaded, verified with
the offline verifier below, revalidated and reviewed. A future record per
module-family evidence key
must bind its tested commit to its GitHub Actions run, artifact URL and digest,
aggregate-index hash, exact target cells and a parity review. Service contracts
also require externally hosted systemd-run and artifact attestations with a
digest. It must also reference a checked-in verification report that binds the
downloaded artifact to the exact module and target-cell IDs. The readiness
validator derives `accepted` and `promotion_ready` only from records that
satisfy those exact checks; adding a registry row never changes inventory
status by itself.

The evidence commit is normally the checked-out commit. A documentation-only
admission commit may instead reference an ancestor tested commit, because the
report and registry cannot exist before the artifact is independently verified.
In that case the validator requires the tested commit to be an ancestor and
allows only the admission registry, derived readiness ledger, inventory
disposition/evidence fields, this contract, files below
`docs/evidence-verification/` or `docs/parity-reviews/`, and the two explicit
legacy-ledger accounting validators to have changed. Any intervening installer,
module, provider, workflow, evidence capture or verification, legacy-source,
or other test path change fails the admission. This exception does not let
evidence survive a runtime or evidence-behavior change: a new full evidence
run is required first.

To promote a row, the same review must change its inventory disposition to
`implemented` or `superseded` and set its `evidence` field to the exact
admitted run URL and artifact-digest reference. The migration reader invokes
the readiness validator whenever an active terminal replacement exists and
rejects a missing admission, stale derived ledger, mismatched module-family
contract, or differing inventory evidence reference. This is deliberately a
two-part action: a valid admission makes promotion possible, not automatic.

The downloaded artifact ZIP must match the GitHub Actions `artifact-digest`
displayed by the aggregate job. Revalidate it before considering a registry
row:

```bash
python3 tests/verify-accepted-evidence-artifact.py \
  --artifact-zip module-evidence-aggregate.zip \
  --artifact-digest sha256:FROM_GITHUB_ARTIFACT_DIGEST \
  --commit TESTED_COMMIT_SHA \
  --run-url https://github.com/Yunushan/linux-software-installer/actions/runs/RUN_ID \
  --module MODULE \
  --target-cell TARGET_ID \
  --target-cell TARGET_ID \
  --output verified-evidence-artifact.json
```

The verifier rejects a mismatched ZIP digest, unsafe ZIP/TAR entries, checksum
drift, an aggregate that is not a clean pass, source/run/commit disagreement,
coverage or summary disagreement, or a requested module whose target cells are
not exactly present in the artifact. It also verifies every indexed result hash
against that cell's actual `result.json` in the imported bundle. A successful
report is still not an admission: parity review, any service attestation and a
reviewed registry row remain separate requirements.

For a full-catalog artifact, batch mode validates the archive once and writes
one report for each requested `family/module` key to a new output directory:

```bash
python3 tests/verify-accepted-evidence-artifact.py \
  --artifact-zip module-evidence-aggregate.zip \
  --artifact-digest sha256:FROM_GITHUB_ARTIFACT_DIGEST \
  --commit TESTED_COMMIT_SHA \
  --run-url https://github.com/Yunushan/linux-software-installer/actions/runs/RUN_ID \
  --evidence-key debian/nginx \
  --evidence-key rhel/nginx \
  --output-dir docs/evidence-verification
```

The output directory must not already exist. This only creates verification
reports; it never writes an admission registry row or promotes inventory.

The smallest safe path to close the remaining 37 planned rows is:

1. Publish repository-resolution evidence for the tested commit, exact image
   digests and all 14 remaining module-family contracts (or a reviewed stronger
   run that demonstrably satisfies the same G3 conditions).
2. Complete one green full-catalog standalone run, import its validated
   aggregate, and record the GitHub artifact digest/ID/URL or an equivalent
   signed trust anchor. Reuse its relevant cells by `evidence_key`.
3. Produce the 64 systemd executions for the 14 service contracts.
4. Check in a row-parity report covering package source/channel, service,
   configuration, firewall, credential and data differences; then change each
   row's disposition and durable `evidence` link together in one review.

Closing these 72 rows still leaves the separately tracked 126
`blocked-third-party` provider gaps; both sets must reach reviewed terminal
states before the old repositories satisfy the retirement gate.

## Disposition states

Every raw inventory entry must eventually receive one reviewed state:

| State | Terminal | Required meaning |
|---|---:|---|
| `planned` | No | The entry is inventoried but its decision or evidence is incomplete. |
| `implemented` | Yes | A supported active replacement meets its declared parity level and evidence gates. |
| `superseded` | Yes | Another active module or workflow intentionally replaces the useful outcome. |
| `retired` | Yes | The product, release or behavior is obsolete and has a documented modern alternative or rationale. |
| `blocked-safety` | Yes | Reproduction is permanently rejected because it would violate the active safety boundary. |
| `blocked-third-party` | No | A signed repository/provider design is still required; this remains unfinished until implemented or explicitly moved out of scope. |
| `out-of-scope` | Yes | Maintainers explicitly reject product ownership and document the supported handoff or alternative. |

Terminal does not always mean feature parity. Retirement reporting must publish
both of these metrics:

1. **Disposition closure:** terminal rows divided by 355.
2. **Implemented coverage:** `implemented` and `superseded` rows divided by
   rows whose useful outcome remains in product scope.

Only disposition closure may reach 100% through safety rejection or retirement.
It must never be presented as 100% installable feature parity.

## Parity contract for a replacement row

An `implemented` or `superseded` row is accepted only when the inventory and
linked evidence identify:

- the active module or supported workflow;
- the target distro, version and architecture;
- the intended outcome and parity level;
- package source and release channel;
- package, service, configuration, firewall, credential and data behavior;
- intentional differences from the legacy implementation;
- a verification-binary declaration and durable evidence reference.

The allowed parity levels are:

| Level | Meaning |
|---|---|
| `unassessed` | Inventory only; cannot be terminal as implemented or superseded. |
| `intent` | Delivers the useful high-level outcome with documented implementation differences. |
| `package` | Also matches the declared package/provider and release-channel contract. |
| `behavioral` | Also matches the explicitly retained service and configuration behavior. |

No row is required to preserve insecure side effects. OpenSSL/OpenSSH/kernel
replacement, bootloader mutation, security-policy weakening, destructive data
handling, unsigned downloads and embedded credentials must be removed from the
replacement behavior and normally classified `blocked-safety` or replaced by
a narrower safe intent.

## Support tiers

Support must be based on exact evidence rather than family detection alone.

| Tier | Meaning | Current members |
|---|---|---|
| Candidate Tier 1 | Exact releases in the blocking CI distro matrix; not install-verified yet | Ubuntu 24.04, Ubuntu 26.04, Debian 12, Rocky Linux 9.8, AlmaLinux 9.8 on the CI runner architecture |
| Release-verified Tier 1 | Candidate releases that pass every applicable gate below | None yet |
| Detection/best effort | Normalized by `/etc/os-release` but without the complete release evidence | Other maintained Debian/Ubuntu and RHEL-compatible releases |
| Legacy blocked | Historical source targets retained only for provenance | Ubuntu 16.04 and CentOS 6/7 |

A module-level `debian` or `rhel` declaration does not by itself prove package
availability on every distro in that family. Either every Tier-1 distro cell
must pass or `MODULE_TARGET_CELLS` must express narrower exact
`ID:VERSION_ID:architecture` support. Runtime and evidence generation share
that fail-closed matcher.
Architecture support must likewise be explicit; detecting an architecture is
not evidence that every mapped package exists for it.

## Evidence gates

The gates are cumulative.

### G0 — Inventory integrity

- The immutable source baseline reconciles to 159 Ubuntu choices, 196 RHEL
  scripts and 355 raw entries.
- Every source unit appears exactly once in the inventory.
- IDs and source locators are unique, and every referenced source exists.
- Quarantined source stays non-executable and outside the active path.

### G1 — Disposition closure

- Every row has a reviewed rationale, canonical capability and target family.
- Every terminal row satisfies the requirements of its state.
- Retirement requires zero `planned` and zero `blocked-third-party` rows.
- Known broken legacy launcher mappings are recorded as source defects, not
  silently treated as working features.

### G2 — Module and plan contract

- Every replacement module has effective `stable`/`low` metadata after the
  documented manifest defaults are applied and passes schema validation.
- Every declared family has a non-empty package mapping and
  verification-binary declaration.
- Exact target restrictions, when present, are unique, known, family-consistent
  and enforced by plan, install and evidence generation.
- Conflicts are symmetric, profiles resolve, and package/service values cannot
  inject command-line options.
- Every supported module-family pair generates the expected plan. The current
  catalog has 139 such pairs: 101 Debian and 38 RHEL mappings.

### G3 — Repository resolution

- Fresh Tier-1 images refresh enabled repository metadata.
- Every declared package set resolves through the distro dependency solver
  without adding an undeclared repository or bypassing signature checks.
- The 101 family-wide modules contribute 370 candidate module-image cells.
  Four distro-component modules contribute one declared exact cell each, for
  374 total cells: 298 Debian-family and 76 RHEL-family. Totals are derived
  after exact-cell filtering.

### G4 — Real installation and verification

- Every in-scope module installs successfully on every claimed Tier-1 image in
  a disposable mutable environment.
- Declared verification binaries are present after installation. Executing a
  product-specific health check requires separately reviewed safe commands.
- Repeating the same installation succeeds without changing the installed
  package/version snapshot.
- Failure evidence is attributable to a specific module and image rather than
  hidden inside a large unreported batch.

### G5 — Service, operational and safety behavior

- Service-bearing modules are tested in disposable systemd VMs both with and
  without `--enable-services`.
- Evidence distinguishes explicit installer activation from service starts
  caused by distribution package maintainer scripts.
- Tests cover confirmation, root enforcement, refresh-once behavior, lock
  contention, protected log permissions, package failure, verification
  failure, stop-on-error behavior and secret-free logs.
- Before/after checks cover SSH policy, SELinux/firewall state, critical system
  components and protected application data where relevant.

### G6 — Release and retirement

- G0 through G5 are green with evidence tied to the release commit and exact
  image digests.
- Imported evidence is bound to an external artifact digest, signed release
  hash or attestation rather than relying only on self-contained checksums.
- Disposition closure is 355/355 with no non-terminal rows.
- Documentation states implemented coverage separately and matches the tested
  distro/architecture tier.
- A migration guide points users from each old repository to the supported
  replacement or documented disposition.
- The old repositories may then be archived read-only. Their source snapshots
  remain in `legacy/` for provenance and must not become active code.

## Evidence and link strategy

This document is the canonical retirement contract. Related documents have
separate responsibilities:

- [`LEGACY.md`](LEGACY.md) records provenance, hazards and migration concepts.
- [`MIGRATION.md`](MIGRATION.md) documents the fail-closed, read-only lookup
  from each legacy source entry to its candidate, unresolved route or terminal
  handoff.
- [`SUPPORT.md`](SUPPORT.md) records the public runtime support policy.
- [`ARCHITECTURE.md`](ARCHITECTURE.md) records implementation boundaries.
- [`PROVIDERS.md`](PROVIDERS.md) records the read-only provider schema and the
  security gates required before any third-party repository can become live.
- [`LEGACY_DISPOSITIONS.md`](LEGACY_DISPOSITIONS.md) records reviewed official
  evidence for terminal retirement and safety decisions.
- [`legacy/README.md`](../legacy/README.md) is the quarantine warning.
- [`legacy-inventory.tsv`](legacy-inventory.tsv) is the machine-readable source
  of truth for row status and traceability.
- [`legacy-promotion-readiness.tsv`](legacy-promotion-readiness.tsv) derives the
  shared evidence keys and still-missing acceptance gates for every planned row;
  it cannot promote or override the source inventory.
- [`accepted-evidence.tsv`](accepted-evidence.tsv) is the reviewed external
  evidence admission registry; it is currently empty and cannot promote or
  override the source inventory.
- [`legacy-source-defects.tsv`](legacy-source-defects.tsv) records preserved
  launcher/menu defects that replacements must not reproduce.
- [`provider-backlog.tsv`](provider-backlog.tsv) maps every unresolved
  third-party row to a machine-checked provider, artifact or handoff strategy.

The root README and both archived repositories should link here when making a
replacement or retirement statement. They should not copy a percentage that
can drift from the inventory.

Inventory `replacement` values should be active module IDs, profile IDs or a
stable documented workflow reference. `evidence` values should point to a
checked-in report or a durable CI/release URL tied to a commit and image digest;
an ephemeral local log is not sufficient. Status changes and evidence links
must be reviewed together in one pull request.
