# Visual Studio Code provider route audit (planning only)

This record captures a 2026-07-16 investigation of a possible Microsoft
Visual Studio Code provider for the two unresolved `visual-studio-code`
backlog rows. It is a planning record, not a provider-admission decision,
module-support claim, replacement-evidence artifact or instruction to change a
system repository. No provider is registered and this project has no provider
apply operation.

## Legacy scope and proposed route

| Legacy row | Successor family | Proposed route | Proposed package |
| --- | --- | --- | --- |
| `ubuntu-005` | Debian family | Microsoft signed APT repository | `code` |
| `rhel-almalinux-8-035-visual-studio-code` | RHEL family | Microsoft signed RPM repository | `code` |

The route is deliberately constrained to maintained, exact target cells that
are still to be selected and evidenced. It does not claim that an Ubuntu 16.04
or AlmaLinux 8 legacy script can be replayed unchanged, nor does it claim
support for every current derivative or CPU architecture.

## Vendor-published repository coordinates

Microsoft's current Linux installation guide publishes the following manual
configuration inputs. The guide is the source for these coordinates; it is not
by itself sufficient evidence to admit a key or provider.

| Manager | Repository URI | Layout / policy | Package |
| --- | --- | --- | --- |
| APT | `https://packages.microsoft.com/repos/code` | `suite=stable`, `components=main`, scoped `Signed-By` keyring | `code` or `code-insiders` |
| DNF | `https://packages.microsoft.com/yumrepos/vscode` | RPM-MD repository with `gpgcheck=1` | `code` or `code-insiders` |

The official guide refers both routes to
`https://packages.microsoft.com/keys/microsoft.asc`. It also says the APT and
YUM repositories can lag a release, so a future provider must select and
record a reviewed package object rather than assuming that the newest upstream
release is immediately resolver-visible. See the [official VS Code Linux
guide](https://code.visualstudio.com/docs/setup/linux).

## Dated observation, not a catalog lock

During the initial 2026-07-16 APT index inspection, the public key object at
the published key URL had SHA-256
`2FA9C05D591A1582A9ABA276272478C262E95AD00ACF60EAEE1644D93941E3C6` and the
parsed OpenPGP primary fingerprint was
`BC528686B50D79E339D3721CEB3E94ADBE1229CF`. The `stable` package index exposed
an amd64 `code` package object with version `1.85.0-1701902998` and SHA-256
`915b82483992df127d3c03835cbec37cc88724508d2e2a1fd93ec034e77ec26e`.

These are untrusted, dated observations only. In particular, index ordering is
not a freshness guarantee, the document does not independently publish the
full key fingerprint, and this record does not establish a clean transport or
publisher-provenance chain. They must not be copied to a provider fixture or
registry row without a reviewed acquisition and rotation policy.

## Admission blockers

The proposed route remains planning-only because all of these independent
requirements are unsatisfied:

1. **No mutation boundary exists.** The installer can validate and render a
   read-only provider plan, but cannot safely install a scoped keyring, write a
   repository file, update metadata, install an exact package or clean up.
2. **Key provenance and lifecycle are unproved.** A checked-in key must be
   independently bound to a publisher identity, primary fingerprint, expiry,
   revocation and reviewed rotation process. A URL and a self-recorded hash are
   not sufficient.
3. **Exact target cells and locks are unproved.** The route needs separately
   reviewed OS/version/architecture/package-manager tuples and exact `code`
   package versions, architectures, digests and expected origins. The two
   historical rows cannot be covered by family-wide inference.
4. **APT and DNF trust checks are incomplete.** The future APT path must
   authenticate Release metadata, enforce its expected identity and freshness,
   and bind the selected package to the approved origin. The RPM path must
   authenticate both repository metadata and packages; `gpgcheck=1` alone does
   not meet this project's DNF policy.
5. **Accepted evidence is absent.** There is no commit-bound,
   immutable-image-bound, externally authenticated solver/install/repeat-install
   bundle, and no update/cleanup evidence, for any target cell.

Until every blocker is resolved in reviewed code and accepted evidence, both
legacy rows remain `blocked-third-party`, the provider registry remains empty,
and users should follow Microsoft's current installation guidance rather than
treating this audit as an installer command.
