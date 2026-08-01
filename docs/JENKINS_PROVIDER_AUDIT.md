# Jenkins provider audit

## Scope and outcome

This audit evaluates the official Jenkins LTS Debian and RPM repositories for
the five blocked `jenkins` legacy entries. It is planning evidence only. It
does not register a provider, add a `jenkins` module, or change any legacy row
from `blocked-third-party`.

| Legacy ID | Immutable source locator | Current-target conclusion |
| --- | --- | --- |
| `ubuntu-065` | `legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#choice-65` | A future Debian provider may be evaluated only on an explicitly reviewed modern Debian-family target. |
| `rhel-almalinux-8-014-jenkins` | `legacy/rhel-family/AlmaLinux-8/scripts/14-Jenkins.sh#script` | The legacy EL 8 script is not a current-target provider contract. |
| `rhel-centos-7-014-jenkins` | `legacy/rhel-family/Centos-7/scripts/14-Jenkins.sh#script` | CentOS 7 remains outside the active installer. |
| `rhel-red-hat-enterprise-linux-8-028-jenkins` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-8/scripts/28-Jenkins.sh#script` | The legacy EL 8 script is not a current-target provider contract. |
| `rhel-red-hat-enterprise-linux-9-027-jenkins` | `legacy/rhel-family/Red-Hat-Enterprise-Linux-9/scripts/27-Jenkins.sh#script` | A future EL 9 route additionally needs the reviewed signer-origin design, exact locks, and service evidence. |

Unlike the current RPM Fusion route, Jenkins provides signed APT and RPM
repository metadata that verifies with its current published key. Its Debian
route is therefore a viable candidate for a future provider implementation.
Its RHEL route remains blocked from admission, but the package-origin contract
can now represent its empty `Vendor` safely through an exact isolated signer
identity. That is only a contract prerequisite: no Jenkins provider, package
lock, target evidence, or legacy admission has been added.

## Reproducible observation — 2026-08-01

The following official Jenkins HTTPS resources were retrieved with certificate
validation enabled and no non-HTTPS redirect accepted.

| Item | URL | Observed result |
| --- | --- | --- |
| Current signing key | `https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key` | OpenPGP primary fingerprint `5E386EADB55F01504CAE8BCF7198F4B714ABFC68`; SHA-256 `d3b7e4096fed593eebdba3a2554c8cb9aafebe736910584e69e924b143e7b3d4` |
| Debian stable Release | `https://pkg.jenkins.io/debian-stable/binary/Release` | SHA-256 `2295ecbece5f9958aa40a878c8f3e3ba177863affb45e0f97f653498e8e74e9f` |
| Debian stable Release signature | `https://pkg.jenkins.io/debian-stable/binary/Release.gpg` | Detached signature verified with the pinned primary fingerprint; SHA-256 `4a9829ad41866b9f645ba23f3a9c88cc405f7829121f394f655e9fe77ea2ddd1` |
| RPM stable repository file | `https://pkg.jenkins.io/rpm-stable/jenkins.repo` | Declares `gpgcheck=1` and `repo_gpgcheck=1`; SHA-256 `e0c5dfddcb06856e319b2e4c78a6997a2edf7a8bf87554075105e35bc49e6859` |
| RPM stable metadata | `https://pkg.jenkins.io/rpm-stable/repodata/repomd.xml` | SHA-256 `d82dd1d791eee7bdcea9f074b8af0dc0e80021066fd098b81fd08cf2f7c495eb` |
| RPM stable metadata signature | `https://pkg.jenkins.io/rpm-stable/repodata/repomd.xml.asc` | Detached signature verified with the pinned primary fingerprint; SHA-256 `7c71ee1e8bd01cedc4389ac4b27e3d4b1a3d3d718af60a981ca70304aab50a22` |

The key identifies itself as `Jenkins Project
<jenkinsci-board@googlegroups.com>`. A good signature proves that the observed
metadata is consistent with this pinned key; it does not by itself establish
the publisher identity or promote an installation result.

The signed RPM primary metadata records the current `jenkins` RPM as
`2.568.1-1.noarch` with SHA-256
`bec392b7f7a4aa68b5bf46516a6ea802a05a3b2fec9a28ae5eb4757436db4d13`, but
its `<rpm:vendor>` element is empty. This remains a real source property, not
an acceptable value to invent in a lockfile. The DNF contract now supports a
separate `signer:<full-primary-fingerprint>` origin form, but only when the
cell declares precisely that one primary key and the RPM verifies in an
isolated RPM database containing no other provider key.

## Candidate design

Any future Debian provider must use only the exact official endpoints above, a
scoped APT `Signed-By` keyring and the fingerprint shown above. It must not run
Jenkins' convenience scripts, use `apt-key`, weaken APT authentication, or
leave the repository enabled without the existing explicit persistence
acknowledgement.

The current RHEL provider must remain blocked. The reviewed signer-identity
mode is deliberately not an empty-`Vendor` exception: it accepts only the
cell's one exact checked-in primary key in an isolated verification database.
It still needs a provider tree, package lock, runtime evidence and the
service-evidence gate below.

Jenkins is a service-bearing capability. A future `jenkins` module therefore
needs the package contract plus a declared `jenkins` systemd service. Its
default mode must not change service state; the explicit service-activation
mode must be included in the existing disposable-VM evidence plan. Modern
target policy must be explicit: legacy CentOS 7 and EL 8 source scripts cannot
be reactivated merely because a current provider exists.

## Remaining admission requirements

Before any inventory row can change, all of the following must be completed:

1. add a reviewed, digest-bound provider tree with exact Debian target cells, a
   checked-in public key, and exact package locks;
2. prove the locked package SHA-256, APT `Origin`, RPM `Vendor`, or the exact
   isolated primary-signing identity, plus package signatures, solver behavior,
   clean install, repeat install and cleanup on
   every claimed target;
3. add target-restricted module and parity reviews that distinguish the legacy
   operating systems from supported current distributions; RHEL scope remains
   blocked unless a separately reviewed signer-identity design is completed;
4. capture the corresponding fresh-VM service-state observations and have them
   accepted through the signed post-destruction attestation gate; and
5. independently verify the resulting GitHub artifact digest before updating
   the immutable inventory and retirement ledger.

Until then, all five rows remain `blocked-third-party` and neither old
repository is eligible for removal.
