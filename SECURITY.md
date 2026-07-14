# Security policy

## Supported versions

Security fixes are applied to the latest release on the `main` branch. Legacy
snapshots under `legacy/` are preserved for historical reference and do not
receive security fixes.

| Version | Security support |
|---|---|
| Latest `1.x` | Yes |
| Earlier releases | Upgrade to the latest release |
| `legacy/` scripts | No; never use on production systems |

## Reporting a vulnerability

Use GitHub's **Report a vulnerability** option in the repository Security tab
to create a private security advisory. Please do not open a public issue for a
suspected vulnerability.

Include:

- the affected command, module and distribution;
- the expected and observed behavior;
- a minimal reproduction using `plan` or a disposable VM/container;
- potential impact;
- a suggested fix, if available.

Do not include real passwords, tokens, private keys, customer data, internal
hostnames or production logs. Redact package-manager output where necessary.

## Security boundaries

The active installer is designed to:

- use only enabled OS package repositories;
- validate module names against the local catalog;
- separate read-only planning from privileged installation;
- avoid logging secrets;
- stop on command failure;
- avoid implicit OS upgrades and destructive configuration changes.

Installing packages still changes the operating system and carries the normal
risk of the configured package repositories. Always review `plan` output,
maintain tested backups and validate changes on a disposable system first.

The project does not promise transaction rollback. Package managers may leave
partial state when an upstream package script fails.
