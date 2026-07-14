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

The active catalog currently accepts only low-risk packages from enabled OS
repositories. A module that needs external downloads, repositories, config
rewrites or credentials requires a separate reviewed provider design and must
not be added as a simple manifest.

## Checklist

- Confirm exact package names on every declared family.
- Use a command installed by the package for verification.
- Declare services only when their names are stable and startup needs no
  initialization.
- Declare known conflicts in both modules.
- Add the module to a profile only when that bundle remains coherent.
- Extend `tests/run.sh` for new parsing, safety or family behavior.
- Run `make check`.
