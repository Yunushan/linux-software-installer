# Legacy snapshots — do not execute

This directory preserves the complete source of the two projects consolidated
into Linux Software Installer. The files are intentionally non-executable and
are excluded from the active catalog, tests and CI linting.

They are historical reference material, not supported installers. Several
scripts can weaken SSH, replace critical cryptographic packages, bypass package
verification, open firewall ports or destroy existing database data.

Use only the root [`install.sh`](../install.sh) entrypoint. See
[`docs/LEGACY.md`](../docs/LEGACY.md) for exact commits, known risks and the
migration policy.
