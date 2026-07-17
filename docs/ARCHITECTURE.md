# Architecture

## Execution flow

```text
install.sh
  -> clean read-only migration dispatch (`migrations`, `migrate`)
  -> provider catalog dispatch (`providers`, `provider-info`, `provider-plan`,
     `provider-config`, `provider-apply`, `provider-deactivate`)
  -> bin/linux-software-installer
     -> CLI parsing
     -> /etc/os-release detection
     -> module/profile resolution
     -> conflict and support checks
     -> plan display and confirmation
     -> one package metadata refresh
     -> package installation
     -> optional service activation
     -> binary verification
```

The active execution path never enters `legacy/`.

The migration dispatch starts the normal CLI in a clean child environment.
`lib/migration.sh` parses the fixed inventory and provider-backlog TSV schemas
without sourcing or evaluating ledger content. It rejects linked, oversized,
binary, malformed or incompletely joined ledgers, validates real inventory
module mappings against their recorded family, and clears partial state on any
failure. Backlog outcomes remain proposals and are never loaded as modules.
Legacy locators are displayed only as provenance and are never opened or
executed by the lookup. The canonical retirement contract still requires the
quarantined snapshots to remain read-only under `legacy/`; parser independence
does not authorize their removal. The command contract is documented in
[`MIGRATION.md`](MIGRATION.md).

`providers/registry.tsv` is the provider catalog's sole admission source and
binds each provider ID and catalog revision to an exact provider-tree SHA-256.
`lib/provider_catalog.sh` parses the fixed-column TSV, verifies the tree
before and after parsing, and rejects unregistered, missing or drifted trees.
`provider-plan` validates exact target cells, revision-bound provider
authorization, provider-specific policy acknowledgements, dependency closure
and package locks. It renders from the validated in-memory snapshot and prints
a plan digest without downloading or writing anything. `provider-config` is
also read-only. For an admitted provider only, `provider-apply` requires that
reviewed digest and atomically materializes just the checked-in keyring and
repository file; `provider-deactivate` removes only those verified files.
Neither command refreshes metadata or installs packages. No provider is live,
so the production registry cannot currently reach either mutation command. The
admission and mutation boundaries are documented in
[`PROVIDERS.md`](PROVIDERS.md).

## Trust boundaries

Module IDs are accepted only when they match `^[a-z0-9][a-z0-9-]*$` and an
exact `modules/<id>/module.sh` manifest exists. The module root and ID directory
must be physical, non-symlink directories, and the manifest must be a regular,
non-symlink, single-link file. Arbitrary paths and remote modules are not
supported.

Manifests are trusted repository code. They contain package metadata rather
than user input and are sourced only after those path and link checks. Package
arrays are passed as quoted arguments; the runtime does not use `eval`.

`MODULE_FAMILIES` selects package mappings. An optional `MODULE_TARGET_CELLS`
array narrows a module to exact `ID:VERSION_ID:uname-m` tuples. Catalog loading
rejects malformed, duplicate, unknown or cross-family cells; plan, install,
repository smoke and standalone evidence paths all use the same exact matcher.
An absent array preserves the existing family-wide best-effort behavior.

Install runs fail closed when `flock` is unavailable. Logging remains disabled
until a new direct regular file has been created without clobbering inside the
installer-owned `0750` log directory; the file must be single-link,
installer-owned and `0600`. Command display and log output redact values whose
option or assignment names identify passwords, tokens, secrets, credentials or
private/access/API keys.

Provider manifests use a stricter boundary: they are untrusted data parsed as
fixed-column TSV and are never sourced or evaluated. The registry is the only
admission list; catalog revision and tree digest validation occurs before
metadata is displayed. Exact provider, target, package-lock and key-declaration
validation follows, and GnuPG must parse each provider-local public key and
return exactly the declared set of primary fingerprints. DNF declarations must
require both signed repository metadata and signed packages; package-only RPM
signature policy is rejected. Planning also requires revision-bound explicit
authorization for every dependency and exact preview, license, authentication
and persistence acknowledgements; the normal `--yes` flag is not accepted.
The validated plan is cached for rendering and receives its own SHA-256, so a
mid-plan reload cannot silently change its contents.

The tree digest, plan digest and local key/fingerprint comparison are integrity
controls, not publisher provenance. They do not authenticate the repository or
verify live metadata and packages. A future mutation path must bind execution
to the reviewed immutable plan, establish catalog provenance and perform the
declared live signature/origin checks. That mutation path does not exist today.

Evidence containers receive a credential-free `git archive` export of the
tested commit, not a checkout containing `.git`. Their writable raw evidence
and installer-log directories are outside artifact upload paths. The runner
must remove the container before invoking the no-follow sanitizer, which
accepts directories and single-link regular files, normalizes copied modes and
rejects symbolic links, FIFOs, sockets, devices, hard links and destination
collisions. Cleanup or sanitizer failure cannot fall back to uploading the raw
tree. Checksums inside the resulting bundle provide integrity only; accepting
evidence additionally requires an external GitHub artifact digest, signed hash
or attestation tied to the reviewed run. No accepted run is implied by this
infrastructure.

## Distribution normalization

`lib/os.sh` parses a configurable os-release file. Tests override it with
fixtures; production uses `/etc/os-release`.

- Debian, Ubuntu and compatible `ID_LIKE=debian` systems normalize to
  `debian` and `apt-get`.
- RHEL, Rocky, AlmaLinux, CentOS Stream, Fedora, Oracle Linux and compatible
  systems normalize to `rhel` and `dnf`.

The normalization layer lets a module declare two package mappings without
copying its entire implementation per distribution name. It does not override
an exact module target restriction: `ID_LIKE` can select a package family, but
only the literal detected `ID`, `VERSION_ID` and architecture can satisfy a
restricted cell.

## Privilege model

Planning and discovery never require root. The real `install` path confirms
the plan, checks `EUID`, acquires a lock, initializes a protected log and then
invokes the package manager. Modules contain no embedded `sudo` calls.

## Idempotency

Package managers provide package-level idempotency. The runtime deduplicates
module requests and refreshes repository metadata once. The active modules do
not rewrite configuration files, so rerunning the same plan is safe within the
normal guarantees of `apt-get` or `dnf`.

## Failure behavior

Strict mode stops the run on the first unhandled failure. Completed modules are
logged, but the project does not claim transaction rollback. Service startup
is opt-in to keep package installation usable in containers and chroots.
