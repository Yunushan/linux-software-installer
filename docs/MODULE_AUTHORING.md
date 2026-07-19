# Module authoring

Each active module is a metadata manifest at:

```text
modules/<module-id>/module.sh
```

Use lowercase kebab-case. The module ID must match its directory name.

## Minimal manifest

```bash
#!/usr/bin/env bash
MODULE_ID='example'
MODULE_NAME='Example package'
MODULE_DESCRIPTION='Short user-facing description'
MODULE_CATEGORY='utility'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(example)
MODULE_RHEL_PACKAGES=(example)
MODULE_VERIFY_BINARIES=(example)
```

Optional metadata:

```bash
MODULE_DEBIAN_SERVICES=(example)
MODULE_RHEL_SERVICES=(exampled)
MODULE_DEBIAN_VERIFY_BINARIES=(example-cli)
MODULE_RHEL_VERIFY_BINARIES=(example)
MODULE_CONFLICTS=(incompatible-module)
MODULE_STATUS='stable'
MODULE_RISK='low'
MODULE_NOTES='Important administrator-facing behavior.'
```

By default, a manifest supports every detected target in each declared package
family. When package availability is narrower, trusted manifest metadata can
restrict it to exact cells:

```bash
MODULE_TARGET_CELLS=(
  ubuntu:24.04:x86_64
  debian:12:x86_64
)
```

Each cell is `ID:VERSION_ID:ARCH`, using the literal lowercase `/etc/os-release`
`ID`, the literal `VERSION_ID`, and the literal `uname -m` architecture. Matching
is exact: `24.04` does not match `24.04.1`, and `x86_64` does not match `amd64`.
Supported IDs are `debian`, `ubuntu`, `linuxmint`, `almalinux`, `centos`,
`fedora`, `ol`, `rhel` and `rocky`; supported architecture names are
`x86_64`, `aarch64`, `armv7l`, `ppc64le`, `s390x` and `riscv64`. Every family
in `MODULE_FAMILIES` must have at least one exact cell when a restriction is
present. Duplicate, malformed, unknown and cross-family declarations fail
catalog loading.

Target restrictions are repository-trusted metadata, not a CLI override. The
runtime rechecks detected host identity for both planning and installation,
and evidence generation omits cells not listed by the module.

The active catalog ordinarily accepts only low-risk packages from enabled OS
repositories. A narrowly reviewed `medium`-risk manifest may declare
`MODULE_DEBIAN_FOREIGN_ARCHITECTURES=(i386)` only with exact x86_64 Debian
target cells. This is a global dpkg-state change, so installation requires one
matching `--allow-foreign-architecture i386` acknowledgement; `--yes` never
implies it. The evidence contract records and verifies the post-install and
post-repeat foreign architecture state. A module that needs external downloads,
repositories, config rewrites or credentials still requires a separate
reviewed provider design and must not be added as a simple manifest.

## Checklist

- Confirm exact package names on every declared family.
- Add exact target cells when a family-wide claim is too broad.
- Use a command installed by the package for verification.
- Declare services only when their names are stable and startup needs no
  initialization.
- Declare known conflicts in both modules.
- Add the module to a profile only when that bundle remains coherent.
- Extend `tests/run.sh` for new parsing, safety or family behavior.
- Run `make check`.
