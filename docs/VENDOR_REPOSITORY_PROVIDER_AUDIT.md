# Remaining vendor-repository provider audit

Review date: **2026-08-01**

This planning-only review covers the vendor-repository backlog rows that are
not already scoped by the Jenkins, AnyDesk, Kubectl, or Visual Studio Code
audits. It neither adds a provider registry entry nor authorizes a repository
configuration on a user's machine.

| Legacy ID | Capability | Proposed provider class | Required admission work |
| --- | --- | --- | --- |
| `ubuntu-018` | Sublime Text 3 | Vendor APT | Record a maintained vendor repository, scoped signing key and primary-fingerprint provenance; pin exact package/version/architecture/digest and signed Release identity; prove solver, clean/repeat install, update and cleanup on each claimed target. |
| `ubuntu-019` | Brave | Vendor APT | Record the exact signed repository and key lifecycle/rotation policy; pin the browser artifact and origin; prove clean/repeat installation, update handling and default repository cleanup. |
| `ubuntu-058` | Vivaldi | Vendor APT | Record the exact vendor repository and independently authenticated signing key; lock package identity/digest and Release origin; prove clean/repeat installation and cleanup on reviewed target cells. |
| `ubuntu-146` | Google Chrome | Vendor APT | Record the exact Google repository/key provenance and rotation policy; lock package identity/digest and Release origin; prove clean/repeat installation, update behavior and cleanup on reviewed target cells. |
| `ubuntu-153` | pgAdmin | Vendor APT | Record the exact vendor repository/key provenance and package lock; prove clean/repeat installation and cleanup. Database endpoints, credentials, saved connections, browser exposure and server mode remain user or operator inputs, never provider inputs. |

## Shared fail-closed rules

Every future APT provider must use a checked-in, reviewed keyring through a
scoped `Signed-By` source; require signed Release metadata with the checked-in
identity; verify the exact local package SHA-256 and package identity before
installing it; and disable the repository afterward unless the caller grants
the existing explicit persistence acknowledgement. It must reject a changed
fingerprint, expired/revoked key, mutable lock, unexpected repository origin,
unauthenticated package, solver drift, unsupported target, or incomplete
cleanup evidence.

Vendor setup scripts, `apt-key`, globally trusted keys, unauthenticated APT,
and credentials or license acceptance supplied by the installer are prohibited.
No legacy row changes state until all normal provider, runtime, and accepted
external-evidence gates have been met.
