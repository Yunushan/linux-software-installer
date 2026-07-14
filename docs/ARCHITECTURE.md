# Architecture

## Execution flow

```text
install.sh
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

## Trust boundaries

Module IDs are accepted only when they match `^[a-z0-9][a-z0-9-]*$` and an
exact `modules/<id>/module.sh` manifest exists. Arbitrary paths and remote
modules are not supported.

Manifests are trusted repository code. They contain package metadata rather
than user input and are sourced only after the path check. Package arrays are
passed as quoted arguments; the runtime does not use `eval`.

## Distribution normalization

`lib/os.sh` parses a configurable os-release file. Tests override it with
fixtures; production uses `/etc/os-release`.

- Debian, Ubuntu and compatible `ID_LIKE=debian` systems normalize to
  `debian` and `apt-get`.
- RHEL, Rocky, AlmaLinux, CentOS Stream, Fedora, Oracle Linux and compatible
  systems normalize to `rhel` and `dnf`.

The normalization layer lets a module declare two package mappings without
copying its entire implementation per distribution name.

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
