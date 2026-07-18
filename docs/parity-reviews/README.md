# Legacy replacement parity-review format

This directory contains the review records required before an active legacy
row can become `implemented` or `superseded`. A successful container run or
accepted-evidence record alone is not a parity decision.

Create one review document for each admitted `family/module` evidence key. It
may cover several legacy rows only when every row is named explicitly and the
same active module provides the documented outcome. Do not use this template
to declare a blocked-third-party row complete: those rows require a reviewed
provider or an explicit terminal handoff first.

## Required record

Use the following headings in every review. Keep each source locator and
evidence reference exact; do not summarize a legacy action without identifying
the corresponding `legacy_id`.

```markdown
# Parity review: `family/module`

## Scope and decision

- Evidence key: `family/module`
- Tested commit: `<40-character commit SHA>`
- Decision: `implemented` or `superseded`
- Parity level: `intent`, `package`, or `behavioral`
- Accepted evidence: `<GitHub Actions run URL and artifact digest>`
- Verification report: `docs/evidence-verification/<family>-<module>.json`

## Legacy rows covered

| Legacy ID | Immutable source locator | Legacy outcome | Decision for this row |
| --- | --- | --- | --- |
| `legacy-id` | `legacy/path#source-item` | `<outcome>` | `implemented` or `superseded` |

## Active replacement contract

- Supported target cells: `<exact target IDs>`
- Module and packages: `<module ID and declared packages>`
- Package source and release channel: `<distribution/vendor source and channel>`
- Verification binaries: `<declared binaries>`
- Service behavior: `<none, or exact service enable/start behavior>`

## Behavioral comparison and intentional differences

Describe the legacy and active behavior for each of the following. State
`none` only after reviewing the preserved source.

| Concern | Legacy behavior | Active behavior | Difference and rationale |
| --- | --- | --- | --- |
| Package source/channel | | | |
| Service lifecycle | | | |
| Configuration files/defaults | | | |
| Firewall/network exposure | | | |
| Credentials and secrets | | | |
| Data creation, migration, or deletion | | | |
| Unsupported or unsafe legacy side effects | | | |

## Reviewer conclusion

Explain why the declared parity level is accurate for every listed legacy row,
including why any omitted legacy behavior is intentionally not preserved.
```

For a service contract, also cite the separately accepted disposable-VM
systemd evidence. The review cannot replace that execution evidence.

The linked inventory rows and `docs/accepted-evidence.tsv` must be changed in
the same reviewed admission, followed by regeneration of
`docs/legacy-promotion-readiness.tsv`.
