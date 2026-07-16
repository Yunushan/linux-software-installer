# Legacy migration lookup

The active installer provides a read-only lookup for every entry captured from
the quarantined Ubuntu 16.04 and RHEL-family installer repositories:

```bash
./install.sh migrations
./install.sh migrate ubuntu-002
```

These commands do not detect the host, require root, contact a repository, run
a package manager or execute anything under `legacy/`. A displayed legacy
source locator is provenance only and must never be executed.

## What the statuses mean

| Disposition | Meaning | User action |
|---|---|---|
| `planned` | An active module is a candidate, but accepted replacement evidence is still missing. | Review the module with `./install.sh info MODULE`; do not treat the mapping as full parity. |
| `blocked-third-party` | No supported automated replacement exists. The displayed strategy and outcome are engineering proposals only. | Follow the rationale; do not turn the proposed outcome into an install command. |
| `implemented` / `superseded` | A terminal replacement with assessed parity and evidence has been recorded. | Review the referenced module and evidence. |
| `retired` | The pinned or discontinued legacy behavior should not be reproduced. | Follow the evidence-backed retirement guidance. |
| `blocked-safety` | Automation was rejected because it changes a critical component or violates the safety contract. | Use the documented specialist or platform workflow. |
| `out-of-scope` | Ownership belongs to a vendor, deployment system or other explicit handoff. | Follow the recorded handoff instead of the legacy script. |

The current immutable denominator is 355 entries: 142 provisional candidates,
129 unresolved third-party routes and 84 terminal dispositions. Those numbers
describe migration accounting, not the public support level of a module.

`./install.sh retirement-status` also reports the read-only counts of accepted
external-evidence admissions and registered live providers. Those counts make
future publication progress visible, but neither count independently changes a
legacy disposition or proves retirement readiness.

## Fail-closed data contract

The lookup parses [`legacy-inventory.tsv`](legacy-inventory.tsv) and, for every
unresolved third-party row, [`provider-backlog.tsv`](provider-backlog.tsv). It
accepts only the exact schemas and the fixed 355-row denominator. It rejects
duplicate or malformed IDs, empty fields, unsafe locators, control or binary
data, oversized files, symlinks, hardlinks, dangling module mappings,
unsupported module-family mappings, and an incomplete or inconsistent backlog
join. A failed reload clears all partial state before returning an error.

The public launcher starts lookup parsing in a clean child environment. Ledger
text is printed only as data; it is never evaluated or sourced. Replacement
modules recorded by the inventory must exist and support the stated family.
Backlog outcomes are only proposals and are deliberately never loaded as
modules.

The lookup intentionally validates locator syntax without opening or executing
the quarantined source file. This parser independence is a safety boundary, not
permission to delete the snapshots: the G0 and G6 gates in
[`REPLACEMENT.md`](REPLACEMENT.md) require them to remain read-only under
`legacy/` for provenance.

## Evidence boundary

A `planned` result remains provisional even when its candidate module exists or
has passed local container probes. Promotion requires the accepted,
commit-bound, image-bound evidence defined in [`REPLACEMENT.md`](REPLACEMENT.md)
and summarized by [`legacy-promotion-readiness.tsv`](legacy-promotion-readiness.tsv).
Repository and artifact proposals remain subject to the trust contract in
[`PROVIDERS.md`](PROVIDERS.md). Real service behavior requires the external VM
contract in [`SYSTEMD_EVIDENCE.md`](SYSTEMD_EVIDENCE.md).

The runtime parser currently rejects every `implemented` or `superseded` row
until its promotion can join the reviewed acceptance process. The header-only
[`accepted-evidence.tsv`](accepted-evidence.tsv) registry records the required
external-artifact admission data for planned rows, but it does not change the
inventory. A terminal row must instead carry the exact admitted run URL and
artifact-digest reference, and the derived readiness ledger must still match
its module-family contract. Its admission also requires a checked-in artifact
verification report for the exact module and target cells. Pointing a row at an
arbitrary document cannot create a terminal replacement.
