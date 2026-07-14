# Contributing

Thank you for helping improve Linux Software Installer.

## Development workflow

1. Fork the repository and create a focused branch from `main`.
2. Keep active code separate from the historical files in `legacy/`.
3. Add or update tests for every behavior change.
4. Run `make check`.
5. Open a pull request describing supported distributions, package sources,
   safety implications and test evidence.

Use small commits with imperative subjects, for example:

```text
Add Debian package mapping for chrony
Reject conflicting web-server modules
Document PostgreSQL initialization behavior
```

## Module rules

An active module must:

- use a lowercase kebab-case ID;
- live at `modules/<id>/module.sh`;
- declare the exact Debian and/or RHEL package names;
- use only enabled OS repositories;
- be idempotent through the package manager;
- declare services and conflicts explicitly;
- avoid configuration changes unless the module contract and tests make them
  visible;
- add a test or extend a profile validation test.

Active modules must not:

- pipe network downloads into a shell;
- disable GPG verification or use plain HTTP;
- use `--force`, `--nodeps` or destructive removal commands;
- embed passwords, API keys or private URLs;
- disable SELinux or alter firewall/SSH policy automatically;
- replace the system kernel, OpenSSL or OpenSSH;
- add a third-party repository without an explicit, separately reviewed safety
  design.

See [`docs/MODULE_AUTHORING.md`](docs/MODULE_AUTHORING.md) for the manifest
contract.

## Tests

```bash
make syntax
make test
make lint
```

`make lint` uses ShellCheck and shfmt when installed. CI is authoritative.

Do not run install-mode tests on a workstation. Use `plan`, a disposable
container or an isolated VM.

## Documentation

Update the README and support policy when adding a module, profile,
distribution family or behavior that changes administrator expectations.
