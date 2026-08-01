# RPM Fusion EL 9 provider audit

## Scope and outcome

This is a planning and trust-model audit for the ten `rpm-fusion` entries in
[`provider-backlog.tsv`](provider-backlog.tsv). It is **not** provider
admission, installation evidence, or a replacement claim for the corresponding
legacy rows.

The reviewed EL 9 Free repository currently exposes FFmpeg and VLC package
metadata, so it is a high-reuse candidate for the RHEL-family gaps. It cannot
be registered in the active provider catalog yet: the repository does not
publish a detached signature for `repodata/repomd.xml`, while the provider
contract requires signed repository metadata as well as signed packages.

## Reproducible observation — 2026-08-01

All endpoints below are official RPM Fusion HTTPS endpoints. The requests used
TLS verification, refused non-HTTPS redirects, and did not bypass certificate
validation.

| Item | URL | Observed result |
| --- | --- | --- |
| EL 9 Free public key | `https://download1.rpmfusion.org/free/el/RPM-GPG-KEY-rpmfusion-free-el-9` | OpenPGP public key; primary fingerprint `EDC00FE7418C9DF7EF4991A47403EA33296458F3`; SHA-256 `ec2c037f6014641cd12195121d97a871cadf385186a20ec3a7757dcd84907031` |
| EL 9 Free metadata | `https://download1.rpmfusion.org/free/el/updates/9/x86_64/repodata/repomd.xml` | Present; SHA-256 `636b248403c1b01d7029dddd6d5d963ea9588eedd0437ab97c310210f3812b41` |
| EL 9 Free metadata signature | `https://download1.rpmfusion.org/free/el/updates/9/x86_64/repodata/repomd.xml.asc` | HTTP 404 |

The key's declared identity was `RPM Fusion free repository for EL (9)
<rpmfusion-gpg-key-el9-free@rpmfusion.org>`. That self-declaration and the
downloaded key hash are useful review inputs, but neither independently proves
publisher control or authorizes a live provider.

## Why the current provider contract rejects it

[`PROVIDERS.md`](PROVIDERS.md) and `lib/provider_catalog.sh` require every DNF
cell to set `gpgcheck=1` and `repo_gpgcheck=1`; a package-only signature policy
is rejected. This prevents a signed package key from silently authenticating an
unsigned or substituted repository index. The missing detached `repomd.xml`
signature means a lockfile cannot truthfully bind a package choice to
authenticated repository metadata.

Do not weaken `repo_gpgcheck`, accept a TLS-only fallback, or add an RPM Fusion
registry row based on this audit. Those actions would turn a documented
third-party gap into an unverified trust claim.

## Reconsideration criteria

RPM Fusion can be evaluated again only when all of the following are available:

1. an official, signed repository-metadata path that DNF can verify with the
   reviewed EL 9 key or another independently reviewed metadata trust model;
2. exact lockable FFmpeg/VLC RPMs for Rocky and Alma 9.8, including SHA-256,
   NEVRA and signed `Vendor` values;
3. clean install, repeat install, origin and cleanup evidence on every claimed
   target; and
4. the separate 64-run systemd evidence plan for any service-bearing legacy
   replacement that depends on this provider.
