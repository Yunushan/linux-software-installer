# Systemd VM evidence contract

This repository has an executable plan and runner for the G5 service-state
checks, but it has **no accepted systemd VM run**. A locally produced bundle is
always `provisional`, even when every structural check passes. The
root-writable provisioning marker can bind one run to a claimed identity, but
it cannot independently prove that the VM was freshly created, that its image
digest is authentic or that the VM was destroyed afterward.

## Exact execution plan

The plan is derived from three reviewed sources: the service-bearing rows in
[`legacy-promotion-readiness.tsv`](legacy-promotion-readiness.tsv), each live
module contract and [`evidence-targets.tsv`](../tests/evidence-targets.tsv).
It fails if that derivation no longer yields 14 module-family contracts across
12 modules and exactly 64 unique executions:

```bash
bash tests/systemd-evidence-matrix.sh "$PWD" plan
bash tests/systemd-evidence-matrix.sh "$PWD" matrix
```

Each contract runs on both exact family targets in two modes: the default,
which must not contain an installer service-mutation command, and
`--enable-services`, which must leave every declared service exactly `enabled`
and `active`. The plan's `standalone_image_tag` is catalog context inherited
from the container evidence table. It is not VM provenance. Only the separate
`vm_image_ref` claim identifies the provisioned VM image.

## Fresh-VM requirements

One execution requires one newly provisioned VM and then VM destruction. The
runner refuses before consuming the marker unless all of these are true:

- it is root on the exact planned OS ID, version boundary and `x86_64`
  architecture;
- PID 1 is `systemd`, systemd is `running`, and there are no failed units;
- hardware VM detection succeeds while container, chroot and private-user
  namespace detection all fail;
- the checkout is at the full requested commit with no tracked, staged or
  untracked changes, both before and after installation;
- production command lookup and process-control environment variables are
  sanitized; and
- a root-owned, mode `0600`, single-link provisioning marker matches the
  execution, target, boot ID, commit and immutable VM image reference.

The provisioner creates
`/etc/linux-software-installer/systemd-evidence-vm.tsv` during the current boot
inside a canonical root-owned directory that is not group/world writable, with
this exact schema:

```text
field	value
schema	linux-software-installer/systemd-evidence-vm/v1
ephemeral	true
single_use	true
execution_id	ubuntu-24-04-apache-default
target_id	ubuntu-24-04
tested_commit	<FULL_40_OR_64_HEX_COMMIT>
vm_image_ref	<PROVIDER_IMAGE_NAME>@sha256:<64_HEX_DIGEST>
boot_id	<CURRENT_/proc/sys/kernel/random/boot_id>
nonce	<32_TO_64_LOWERCASE_HEX>
```

`--marker` is test-only. In production the fixed marker is atomically consumed
to a `.consumed` file before output is created, so the same VM cannot run a
second execution. The VM must still be destroyed by the external provisioner;
the repository deliberately does not self-attest that external action.

Run one selected plan row on that VM, using a new absolute canonical output
directory whose parent already exists:

```bash
sudo bash tests/run-systemd-evidence.sh \
  --root "$PWD" \
  --execution-id ubuntu-24-04-apache-default \
  --output /var/tmp/lsi-systemd/ubuntu-24-04-apache-default \
  --tested-commit "$TESTED_COMMIT" \
  --vm-image-ref "$IMMUTABLE_VM_IMAGE_REF"
```

The runner captures before/after module packages, critical and protected
kernel/OpenSSL/OpenSSH packages, declared service enabled/active state, SSH
configuration metadata and contents, SSH unit/listener state, SELinux state,
firewall backends, running kernel, overall systemd health and failed units. A
dedicated Bash execution trace distinguishes installer-issued service commands
from package-maintainer output. Every regular single-link output file is bound
by `files.sha256`; links, special files, extra entries and output reuse fail
closed.

## Validation and the signed trust gate

Structural validation re-derives the current plan and module contract, checks
the exact file set and hashes, parses every identity/state table, recomputes
service attribution and rejects test-mode evidence when `--require-real` is
used:

```bash
bash tests/validate-systemd-evidence.sh "$PWD" \
  --evidence /var/tmp/lsi-systemd/ubuntu-24-04-apache-default \
  --tested-commit "$TESTED_COMMIT" \
  --vm-image-ref "$IMMUTABLE_VM_IMAGE_REF" \
  --require-real
```

That command validates a real observation structurally; it does not accept it
for promotion. The stronger acceptance command additionally requires an
absolute canonical evidence directory, a GitHub-published artifact digest, a
post-destruction attestation and detached signature, and a matching public key
in [`systemd-provisioners.tsv`](systemd-provisioners.tsv):

```bash
bash tests/validate-systemd-evidence.sh "$PWD" \
  --evidence /absolute/path/to/downloaded/systemd-vm-evidence \
  --require-accepted \
  --artifact-digest sha256:<GITHUB_PUBLISHED_ARTIFACT_SHA256> \
  --attestation /absolute/path/to/provisioner-attestation.tsv \
  --attestation-signature /absolute/path/to/provisioner-attestation.tsv.asc \
  --provisioner-registry "$PWD/docs/systemd-provisioners.tsv"
```

The verifier requires an exact field set, verifies its detached OpenPGP
signature with the registry's single-link `keys/<provisioner_id>.gpg` key, and
binds the statement to the execution and target IDs, tested commit, VM-image
reference, boot ID, single-use marker nonce, captured `files.sha256` digest and
the published GitHub artifact digest. It also requires a destruction time after
the creation time. A signed statement cannot be reused for a different bundle
or artifact.

The checked-in registry is deliberately header-only: no provisioner public key
is trusted yet. Therefore every real bundle still fails `--require-accepted`,
and the promotion ledger remains `evidence_class=none` and
`promotion_ready=no`. Adding a provisioner requires separate review of its
identity, public-key fingerprint, VM-image policy and destruction controls; a
registry row alone never promotes a legacy route.

The checked-in [`Systemd VM evidence` workflow](../.github/workflows/systemd-vm-evidence.yml)
is intentionally **not** a generic GitHub-hosted workflow. It can run only on
the `self-hosted`, `linux`, `x64`, and `lsi-systemd-evidence` labels. The
external provisioner must assign that last label only after it has created one
fresh target VM, written the root-owned single-use marker, and recorded the
immutable image reference. It must remove the runner registration and destroy
the VM after that one workflow execution. Persistent runners and GitHub-hosted
container runners must never carry this label or be presented as systemd VM
evidence.

Dispatch one workflow run for one exact `execution_id`, an immutable VM-image
reference and a reviewed candidate provisioner ID. The job validates and uploads
only a **provisional** observation. After the runner has been deregistered and
the VM destroyed, the external provisioner must publish and sign the
attestation described above using the GitHub artifact digest that the completed
workflow published. This ordering prevents a capture-time claim from pretending
that future destruction already happened. Do not add any result to
`accepted-evidence.tsv` until an independent reviewer has downloaded the
artifact and passed the stronger verifier.

The deterministic and refusal paths are covered with mocks only:

```bash
bash tests/test-systemd-evidence.sh
```

Mocked output records `result=test-only` and `acceptance_eligible=false`; it can
never satisfy either real-observation or acceptance gates.
