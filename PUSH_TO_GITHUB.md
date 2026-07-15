# Publish and verify this repository on GitHub

The repository already has this remote:

```text
origin  https://github.com/Yunushan/linux-software-installer.git
```

Local changes should be reviewed and tested before they are committed or
pushed. This document is a checklist; it does not authorize an automated
commit, push or pull request.

## Pre-publish checks

```bash
make check
actionlint .github/workflows/ci.yml \
  .github/workflows/install-smoke.yml \
  .github/workflows/module-evidence.yml
git diff --check
git status --short
```

Review the complete diff, create a scoped branch/commit, then push through the
normal maintainer workflow. Do not commit generated local evidence, temporary
TLS roots, credentials or raw/container-writable installer logs. Sanitized CI
artifacts remain candidate evidence and follow the promotion process below.

## Required GitHub checks

Protect `main` and require the push/PR CI jobs appropriate to the repository:

- `Lint and test`;
- all four `Container smoke` cells;
- all four `Repository resolution` cells.

The scheduled/manual `Real install smoke` workflow is a drift and integration
check. The manual `Standalone module evidence` workflow is the higher-cost
candidate evidence path. Neither workflow becomes accepted release evidence
merely by existing in the repository.

## Evidence promotion

For a release candidate:

1. Run standalone evidence for the exact candidate commit.
2. Require its aggregate job to validate the complete expected cell set.
3. Record the immutable image references and GitHub artifact digest.
4. Confirm checkout credentials were not persisted or mounted; raw container
   paths were outside upload paths; container cleanup preceded sanitization;
   and sanitizer reports contain no rejected links, special files, hard links
   or collisions.
5. Review failures and package/service side effects; do not discard failed
   cells from the bundle.
6. Publish the reviewed bundle through a durable release record with an
   external signed hash or attestation.
7. Run systemd VM evidence separately before promoting service-behavior claims.

GitHub Actions artifacts are transport, not permanent provenance. The legacy
inventory may be promoted only when the evidence and disposition requirements
in [`docs/REPLACEMENT.md`](docs/REPLACEMENT.md) are met.

## Repository settings

Keep these enabled:

- branch protection and required reviews for `main`;
- private vulnerability reporting;
- Dependabot updates for pinned GitHub Actions;
- the shortest artifact/log retention compatible with the reviewed promotion
  process.
