# Third-party provider architecture

The provider catalog is currently a **catalog-integrity and transaction-planning
foundation**. It can validate and display local provider metadata, resolve an
exact dependency closure, print a fully authorized package-lock plan and,
when a provider has been admitted, materialize only the reviewed keyring and
repository file. No live provider is registered, and it cannot refresh remote
metadata or install third-party packages. The ordinary package-only catalog
continues to use repositories already enabled by the administrator.

This separation is intentional. A provider must fail closed at metadata review
before privileged repository code exists.

## Provider commands

```bash
./install.sh providers
./install.sh provider-info PROVIDER
./install.sh provider-plan PROVIDER \
  --allow-provider PROVIDER@CATALOG_REVISION \
  [--allow-preview-provider PROVIDER] \
  [--accept-provider-license PROVIDER@REVISION] \
  [--ack-provider-auth PROVIDER] \
  [--persist-provider PROVIDER] \
  MODULE...
./install.sh provider-config PROVIDER \
  --allow-provider PROVIDER@CATALOG_REVISION \
  [ACKNOWLEDGEMENTS...] MODULE...
sudo ./install.sh provider-apply PROVIDER \
  --plan-sha256 PLAN_SHA256 \
  --allow-provider PROVIDER@CATALOG_REVISION \
  [ACKNOWLEDGEMENTS...] MODULE...
sudo ./install.sh provider-deactivate PROVIDER \
  --plan-sha256 PLAN_SHA256 \
  --allow-provider PROVIDER@CATALOG_REVISION \
  [ACKNOWLEDGEMENTS...] MODULE...
```

`providers` currently reports an empty live catalog. Tests use isolated fixture
providers to exercise validation without creating a production trust claim.
Only an exact row in `providers/registry.tsv` admits a provider. A directory
that is absent from the registry is rejected, and a registry row without its
matching directory is also rejected.

`provider-config` performs the same exact target, catalog revision, key and
package-lock validation as `provider-plan`, then renders the APT Deb822 or DNF
repository configuration that the reviewed provider cell specifies. It remains
read-only: it does not copy a key, create a repository file, refresh metadata
or install a package. Rendering a configuration is not provider admission or
installation evidence.

`provider-apply` repeats that validation and requires the exact body digest
printed by an immediately reviewed `provider-plan`. It requires root and only
atomically materializes the checked-in public key and exact APT/DNF repository
file into fixed system locations. Existing files must be the same single-link
regular file byte-for-byte; symlinks, hard links and drift are rejected instead
of overwritten. It does not refresh metadata, invoke a package manager or
install a package. Its files remain active until the matching
`provider-deactivate` command runs. The live registry is empty, so no real
provider can currently reach this operation.

`provider-deactivate` repeats the same digest-bound validation and removes only
the matching installer-managed key and repository file, in reverse dependency
order. It preflights both files before deletion and rejects drift, links or
foreign content without removing either file. It does not refresh metadata or
remove packages.

`provider-plan` is deliberately non-mutating. For the exact detected OS,
`VERSION_ID`, package architecture and package manager it validates every
provider in dependency order, requires a distinct revision-bound
`--allow-provider PROVIDER@CATALOG_REVISION` for each, rejects the ordinary
global `--yes` shortcut, and enforces the manifest's preview, revision-bound
license, authentication and persistence gates. It then prints the checked-in
repository identity, key fingerprints, expected origin, signature policy and
exact package version/architecture/digest locks. Missing, stale, duplicate or
unrelated acknowledgements fail closed.

Each provider tree is hashed before and after parsing and must match the
SHA-256 pinned by its registry row. The validated fields and primary package
locks are cached in one in-memory plan snapshot; rendering does not reload the
manifests. The displayed plan has its own SHA-256 so a reviewed plan can be
compared byte-for-byte. These hashes provide local integrity and change
detection only. They do not prove who published the catalog or authenticate a
live repository. The final plan is a review artifact only; it does not
download packages, verify remote metadata or write repository configuration.
The public entrypoint plans only for the real host: it does not inherit test OS
metadata, a package-manager override or the ordinary installer's
unsupported-legacy-OS escape hatch.

## Data model

Provider data is fixed-column TSV and is never sourced or evaluated as shell
code. [`providers/schema.tsv`](../providers/schema.tsv) is the exact schema.
The registry is the sole provider-admission source, and a future registered
provider directory will have this layout:

```text
providers/registry.tsv       provider ID, catalog revision and provider-tree SHA-256
providers/<provider-id>/
  provider.tsv   publisher, policy, license, authentication and dependencies
  cells.tsv      exact OS, version, architecture, package manager and channel
  locks.tsv      exact module package versions, architecture, digest and check
  keys/          checked-in public-key material referenced by cells.tsv
```

The parser rejects unknown or reordered columns, provider directories not
admitted by the registry, missing registered directories, registry/tree digest
drift, extra provider-tree entries, path traversal, symlinks or hard links at
catalog boundaries, embedded NUL bytes, missing terminating newlines,
non-HTTPS URLs, wildcard target versions, leading-option package tokens, short
fingerprint or digest declarations, duplicate exact target tuples,
self/duplicate dependencies and locks for unknown cells. An APT cell must
require signed Release metadata. Normal APT layouts require one exact,
non-path suite and one or more unique, non-path components. An exact-path flat
APT layout is represented only as `suite=/`, `components=-`, and a repository
URI ending in `/`; other suite/component omissions or path forms are rejected.
A DNF cell must declare both signed
repository metadata and signed packages; a package-only RPM signature policy
is not accepted.

The current key checks validate a safe, non-empty provider-local path and use
GnuPG in an isolated temporary home to parse both armored and binary OpenPGP
public-key material. The complete set of parsed primary-key fingerprints must
exactly match the unique full fingerprints declared by the target cell;
subkey fingerprints cannot satisfy that declaration. GnuPG is therefore
required when a non-empty provider is inspected. This proves only that the
local declaration is bound to the checked-in key material. It does not prove
publisher identity, catalog provenance, live repository metadata authenticity
or package signatures. No repository installation may be enabled until those
runtime checks and the remaining gates below exist.

## Required package-install boundary

The planner and configuration activation path require a separate explicit,
catalog-revision-bound allow flag for each provider. A future package installer
must preserve that contract and bind its work to the exact reviewed plan digest.
`--yes`, `--force-unsupported` and ordinary module selection must never imply
provider authorization, license acknowledgement, classic Snap confinement or
authentication consent.

Before any provider can become live, implementation and tests must prove:

- an exact `ID`, `VERSION_ID`, architecture and package-manager cell;
- package and repository-metadata signature verification with the already
  fingerprint-bound checked-in keys, including expiry and revocation policy;
- exact package-version and origin enforcement with fail-closed solver checks;
- locally generated, scoped repository configuration using APT `Signed-By` or
  DNF `gpgcheck=1` plus `repo_gpgcheck=1`, without `apt-key`, remote setup
  scripts or TLS bypasses;
- explicit dependency authorization rather than transitive trust;
- separate license/authentication gates and secret-free plans and logs;
- atomic writes that reject symlinks, foreign files and configuration drift;
- repository disablement after installation unless persistence is separately
  requested;
- real install, repeat, origin, signature and cleanup evidence on every exact
  claimed target cell.

The 129 unresolved third-party legacy rows and their recommended provider or
authenticated-artifact routes are tracked in
[`PROVIDER_BACKLOG.md`](PROVIDER_BACKLOG.md). A backlog entry is not a support
claim and must not be promoted merely because a provider manifest can be
parsed.

Future provider evidence remains subject to the release evidence trust
boundary in [`REPLACEMENT.md`](REPLACEMENT.md). Self-contained checksums can
show integrity but not authenticity; acceptance also requires an external
GitHub artifact digest, signed release hash or attestation. No provider or
provider evidence is accepted today, and the old installer repositories have
not yet met their retirement gate.
