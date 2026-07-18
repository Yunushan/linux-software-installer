#!/usr/bin/env python3
"""Validate the derived readiness ledger for planned legacy replacements."""

from __future__ import annotations

import argparse
import csv
import io
import json
import os
import re
import stat
import subprocess
import sys
import unicodedata
from collections import Counter
from pathlib import Path, PurePosixPath


READINESS_HEADER = [
    "legacy_id",
    "target_family",
    "replacement",
    "evidence_key",
    "review_route",
    "parity_level",
    "required_standalone_cells",
    "service_contract",
    "shared_systemd_executions",
    "evidence_class",
    "evidence_reference",
    "promotion_ready",
    "missing_acceptance",
]
TARGET_HEADER = [
    "target_id",
    "ref_env",
    "display_name",
    "family",
    "image",
    "platform",
    "expected_os_id",
    "expected_version_id",
    "expected_arch",
]
ADMISSION_HEADER = [
    "evidence_key",
    "commit_sha",
    "run_url",
    "artifact_url",
    "artifact_digest",
    "index_sha256",
    "target_cells",
    "parity_report",
    "systemd_run_url",
    "systemd_artifact_url",
    "systemd_artifact_digest",
    "verification_report",
]
COMMIT_PATTERN = re.compile(r"^[0-9a-f]{40}$")
SHA256_PATTERN = re.compile(r"^[0-9a-f]{64}$")
GITHUB_RUN_URL_PATTERN = re.compile(
    r"^https://github\.com/Yunushan/linux-software-installer/actions/runs/[1-9][0-9]*$"
)
HTTPS_URL_PATTERN = re.compile(r"^https://[^\s]+$")
VERIFICATION_SCHEMA = "linux-software-installer/accepted-evidence-verification/v2"
BASE_MISSING = (
    "G3-repository-resolution+G4-standalone-install+"
    "row-parity-review+durable-trust-anchor"
)
SERVICE_MISSING = (
    "G3-repository-resolution+G4-standalone-install+G5-systemd-behavior+"
    "row-parity-review+durable-trust-anchor"
)
# These are catalog-shape invariants.  Lifecycle counters such as
# ``planned_rows`` deliberately do not belong here: they must change when a
# verified replacement is promoted from planned to implemented or superseded.
EXPECTED_CATALOG_INVARIANTS = {
    "active_rows": 145,
    "debian_rows": 73,
    "rhel_rows": 72,
    "modules": 83,
    "module_family_pairs": 93,
    "standalone_cells": 250,
    "service_rows": 36,
    "service_modules": 11,
    "service_pairs": 13,
    "systemd_executions": 58,
}


class ReadinessError(Exception):
    """A deterministic readiness-contract failure."""


def read_tsv(path: Path, expected_header: list[str], label: str) -> list[dict[str, str]]:
    try:
        with path.open("r", encoding="utf-8", newline="") as stream:
            reader = csv.DictReader(stream, delimiter="\t", quoting=csv.QUOTE_NONE)
            if reader.fieldnames != expected_header:
                raise ReadinessError(f"{label} has an unexpected header")
            rows: list[dict[str, str]] = []
            for line_number, row in enumerate(reader, 2):
                if None in row or any(value is None for value in row.values()):
                    raise ReadinessError(
                        f"{label} line {line_number} has an unexpected field count"
                    )
                if any(
                    unicodedata.category(character) in {"Cc", "Cf", "Cs"}
                    for value in row.values()
                    for character in value
                ):
                    raise ReadinessError(f"{label} line {line_number} contains control text")
                rows.append(dict(row))
            return rows
    except (OSError, UnicodeDecodeError, csv.Error) as error:
        raise ReadinessError(f"cannot read {label}: {error}") from None


def review_route(row: dict[str, str]) -> str:
    rationale = row["rationale"].lower()
    return (
        "superseded-candidate"
        if "supersed" in rationale or "supersession" in rationale
        else "implemented-candidate"
    )


def valid_reference(root: Path, reference: str) -> bool:
    if HTTPS_URL_PATTERN.fullmatch(reference):
        return True
    if not reference.startswith("docs/"):
        return False
    path_text = reference.split("#", 1)[0]
    pure = PurePosixPath(path_text)
    if (
        pure.is_absolute()
        or ".." in pure.parts
        or path_text != pure.as_posix()
        or not pure.parts
        or pure.parts[0] != "docs"
    ):
        return False
    return (root / path_text).is_file()


def checked_out_commit(root: Path) -> str | None:
    try:
        completed = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=root,
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=10,
        )
    except (OSError, UnicodeDecodeError, subprocess.TimeoutExpired):
        completed = None
    if completed is not None:
        candidate = completed.stdout.strip()
        if completed.returncode == 0 and COMMIT_PATTERN.fullmatch(candidate):
            return candidate
    for candidate in (os.environ.get("GITHUB_SHA", ""), os.environ.get("LSI_TESTED_COMMIT", "")):
        if COMMIT_PATTERN.fullmatch(candidate):
            return candidate
    return None


ADMISSION_ONLY_PATHS = {
    "docs/accepted-evidence.tsv",
    "docs/legacy-inventory.tsv",
    "docs/legacy-promotion-readiness.tsv",
    "docs/REPLACEMENT.md",
    "docs/MIGRATION.md",
    "docs/LEGACY_DISPOSITIONS.md",
    "docs/PROVIDERS.md",
    "docs/DISTRO_COMPONENT_PROBES.md",
    "docs/PROVIDER_BACKLOG.md",
    "docs/provider-backlog.tsv",
    # These validators govern the admission ledger's lifecycle accounting.
    # They neither select packages nor participate in container execution,
    # capture, sanitization, aggregate validation, or artifact verification.
    # Keeping this list explicit lets a fully verified installer artifact be
    # carried forward after an admission-only accounting correction, while any
    # change to installer or evidence behavior still requires a fresh run.
    "tests/validate-legacy-inventory.sh",
    "tests/migration-unit.sh",
    "tests/validate-legacy-promotion-readiness.py",
    "tests/test-accepted-evidence.py",
    "tests/validate-provider-backlog.sh",
}
ADMISSION_ONLY_PREFIXES = (
    "docs/evidence-verification/",
    "docs/parity-reviews/",
)


def is_admission_only_path(path: str) -> bool:
    """Return whether a commit-range path may accompany evidence admission.

    Evidence reports and their registry necessarily change *after* the tested
    commit has been produced.  This narrow allowlist makes that documentation
    step possible without letting an untested installer, catalog, workflow,
    evidence-capture or evidence-verification change inherit earlier evidence.
    The named ledger validators and provider-backlog documents are also
    permitted because they are admission bookkeeping only; this is deliberately
    not a blanket docs/ or tests/ allowlist.
    """

    return path in ADMISSION_ONLY_PATHS or path.startswith(ADMISSION_ONLY_PREFIXES)


def validate_evidence_commit(root: Path, evidence_commit: str, current_commit: str) -> None:
    """Require evidence to be current or separated only by admission documents."""

    if evidence_commit == current_commit:
        return
    try:
        ancestor = subprocess.run(
            ["git", "merge-base", "--is-ancestor", evidence_commit, current_commit],
            cwd=root,
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=10,
        )
        changed = subprocess.run(
            ["git", "diff", "--name-only", f"{evidence_commit}..{current_commit}"],
            cwd=root,
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=10,
        )
    except (OSError, UnicodeDecodeError, subprocess.TimeoutExpired) as error:
        raise ReadinessError(
            f"cannot verify whether evidence commit {evidence_commit} is admissible: {error}"
        ) from None
    if ancestor.returncode != 0:
        raise ReadinessError(
            f"evidence commit {evidence_commit} is not an ancestor of checked-out commit "
            f"{current_commit}"
        )
    if changed.returncode != 0:
        raise ReadinessError(
            f"cannot inspect changes since evidence commit {evidence_commit}"
        )
    changed_paths = [path for path in changed.stdout.splitlines() if path]
    disallowed = [path for path in changed_paths if not is_admission_only_path(path)]
    if disallowed:
        raise ReadinessError(
            f"evidence commit {evidence_commit} predates checked-out commit {current_commit} "
            "and intervening changes are not admission-only: "
            + ", ".join(disallowed)
        )


def validate_admission_registry_file(path: Path) -> None:
    try:
        metadata = path.lstat()
        if not stat.S_ISREG(metadata.st_mode) or metadata.st_nlink != 1:
            raise ReadinessError(
                "accepted-evidence admission registry must be a single-link regular file"
            )
        if metadata.st_size > 1024 * 1024:
            raise ReadinessError("accepted-evidence admission registry exceeds 1 MiB")
        contents = path.read_bytes()
    except OSError as error:
        raise ReadinessError(f"cannot read accepted-evidence admission registry: {error}") from None
    if b"\0" in contents or not contents.endswith(b"\n"):
        raise ReadinessError(
            "accepted-evidence admission registry must be NUL-free and end with a newline"
        )


def comma_tokens(value: str) -> tuple[str, ...] | None:
    if not value or value == "-" or value.startswith(",") or value.endswith(","):
        return None
    values = tuple(value.split(","))
    if any(not token or not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", token) for token in values):
        return None
    return values if len(values) == len(set(values)) else None


def local_docs_file(root: Path, reference: str, label: str) -> Path:
    if "#" in reference or not reference.startswith("docs/"):
        raise ReadinessError(f"{label} must be a repository-local docs/ file")
    pure = PurePosixPath(reference)
    if pure.is_absolute() or ".." in pure.parts or reference != pure.as_posix():
        raise ReadinessError(f"{label} has an unsafe path")
    path = root / reference
    try:
        metadata = path.lstat()
    except OSError as error:
        raise ReadinessError(f"cannot inspect {label}: {error}") from None
    if not stat.S_ISREG(metadata.st_mode) or metadata.st_nlink != 1:
        raise ReadinessError(f"{label} must be a single-link regular file")
    return path


def validate_verification_report(
    report_root: Path,
    report_reference: str,
    admission: dict[str, str],
    module: str,
    target_cells: tuple[str, ...],
) -> None:
    path = local_docs_file(report_root, report_reference, "verification report")
    try:
        raw = path.read_bytes()
    except OSError as error:
        raise ReadinessError(f"cannot read verification report: {error}") from None
    if not raw or len(raw) > 1024 * 1024 or b"\0" in raw or not raw.endswith(b"\n"):
        raise ReadinessError("verification report has unsafe bytes or size")
    try:
        report = json.loads(raw.decode("utf-8", errors="strict"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ReadinessError(f"verification report is not strict JSON: {error}") from None
    expected_keys = {
        "schema",
        "artifact_sha256",
        "index_sha256",
        "commit_sha",
        "run_url",
        "expected_cells",
        "module",
        "target_cells",
        "cell_ids",
        "result",
    }
    if not isinstance(report, dict) or set(report) != expected_keys:
        raise ReadinessError("verification report has an unexpected schema")
    expected_cell_ids = [f"{target}/{module}" for target in target_cells]
    if (
        report["schema"] != VERIFICATION_SCHEMA
        or report["artifact_sha256"] != admission["artifact_digest"].removeprefix("sha256:")
        or report["index_sha256"] != admission["index_sha256"]
        or report["commit_sha"] != admission["commit_sha"]
        or report["run_url"] != admission["run_url"]
        or report["module"] != module
        or report["target_cells"] != list(target_cells)
        or report["cell_ids"] != expected_cell_ids
        or type(report["expected_cells"]) is not int
        or report["expected_cells"] <= 0
        or report["result"] != "verified-awaiting-parity-review-and-systemd-attestation"
    ):
        raise ReadinessError("verification report does not match its accepted-evidence admission")


def load_accepted_admissions(
    root: Path,
    expected: list[dict[str, str]],
    commit: str | None = None,
    registry_path: Path | None = None,
    report_root: Path | None = None,
) -> dict[str, dict[str, str]]:
    registry_path = registry_path or root / "docs" / "accepted-evidence.tsv"
    validate_admission_registry_file(registry_path)
    rows = read_tsv(
        registry_path,
        ADMISSION_HEADER,
        "accepted-evidence admission registry",
    )
    if not rows:
        return {}

    supplied_commit = commit is not None
    commit = commit or checked_out_commit(root)
    if commit is None:
        raise ReadinessError(
            "accepted evidence requires a checked-out or explicitly supplied full commit ID"
        )
    checked_out = checked_out_commit(root)
    if not supplied_commit and checked_out is None:
        raise ReadinessError("accepted evidence requires a checked-out full commit ID")
    targets = read_tsv(
        root / "tests" / "evidence-targets.tsv", TARGET_HEADER, "evidence target table"
    )
    targets_by_family = {
        family: tuple(
            sorted(row["target_id"] for row in targets if row["family"] == family)
        )
        for family in {"debian", "rhel"}
    }
    report_root = report_root or root
    expected_by_key = {row["evidence_key"]: row for row in expected}
    admissions: dict[str, dict[str, str]] = {}

    for row in rows:
        evidence_key = row["evidence_key"]
        derived = expected_by_key.get(evidence_key)
        if derived is None:
            raise ReadinessError(
                f"accepted-evidence registry references unknown or stale evidence key {evidence_key}"
            )
        if evidence_key in admissions:
            raise ReadinessError(
                f"accepted-evidence registry repeats evidence key {evidence_key}"
            )
        if supplied_commit:
            if row["commit_sha"] != commit:
                raise ReadinessError(
                    f"{evidence_key} is bound to {row['commit_sha']}, not requested commit {commit}"
                )
        else:
            validate_evidence_commit(root, row["commit_sha"], checked_out)
        run_url = row["run_url"]
        artifact_url = row["artifact_url"]
        if not GITHUB_RUN_URL_PATTERN.fullmatch(run_url):
            raise ReadinessError(f"{evidence_key} has an invalid GitHub Actions run URL")
        if not artifact_url.startswith(run_url + "/artifacts/") or not re.fullmatch(
            re.escape(run_url) + r"/artifacts/[1-9][0-9]*", artifact_url
        ):
            raise ReadinessError(f"{evidence_key} artifact URL is not bound to its run URL")
        if not SHA256_PATTERN.fullmatch(row["artifact_digest"].removeprefix("sha256:")):
            raise ReadinessError(f"{evidence_key} has an invalid external artifact digest")
        if not SHA256_PATTERN.fullmatch(row["index_sha256"]):
            raise ReadinessError(f"{evidence_key} has an invalid aggregate index digest")
        target_cells = comma_tokens(row["target_cells"])
        expected_cells = tuple(
            derived.get(
                "evidence_target_cells", targets_by_family[derived["target_family"]]
            )
        )
        if target_cells != expected_cells:
            raise ReadinessError(
                f"{evidence_key} target cells do not exactly match its supported module contract"
            )
        if not valid_reference(root, row["parity_report"]):
            raise ReadinessError(f"{evidence_key} has an invalid parity review reference")
        validate_verification_report(
            report_root,
            row["verification_report"],
            row,
            derived["replacement"],
            expected_cells,
        )

        systemd_fields = (
            row["systemd_run_url"],
            row["systemd_artifact_url"],
            row["systemd_artifact_digest"],
        )
        if derived["service_contract"] == "yes":
            if (
                not HTTPS_URL_PATTERN.fullmatch(systemd_fields[0])
                or not HTTPS_URL_PATTERN.fullmatch(systemd_fields[1])
                or not SHA256_PATTERN.fullmatch(systemd_fields[2].removeprefix("sha256:"))
            ):
                raise ReadinessError(
                    f"{evidence_key} lacks a valid external systemd evidence attestation"
                )
        elif systemd_fields != ("-", "-", "-"):
            raise ReadinessError(
                f"{evidence_key} declares systemd evidence for a non-service contract"
            )
        admissions[evidence_key] = row
    return admissions


def admission_reference(admission: dict[str, str]) -> str:
    return (
        f"{admission['run_url']}#artifact-digest="
        f"{admission['artifact_digest'].removeprefix('sha256:')}"
    )


def derive_contract(
    root: Path, module: str, family: str, target: dict[str, str] | None = None
) -> tuple[str, ...]:
    command = [
        "bash",
        str(root / "tests" / "evidence-contract.sh"),
        str(root),
        module,
        family,
    ]
    if target is not None:
        command.extend(
            [
                target["expected_os_id"],
                target["expected_version_id"],
                target["expected_arch"],
            ]
        )
    try:
        completed = subprocess.run(
            command,
            cwd=root,
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=30,
        )
    except (OSError, UnicodeDecodeError, subprocess.TimeoutExpired) as error:
        raise ReadinessError(
            f"cannot derive evidence contract for {family}/{module}: {error}"
        ) from None
    if completed.returncode != 0:
        raise ReadinessError(
            f"catalog rejected evidence contract for {family}/{module}: "
            f"{completed.stderr.strip() or 'unknown error'}"
        )
    reader = csv.DictReader(io.StringIO(completed.stdout), delimiter="\t")
    if reader.fieldnames != ["type", "value"]:
        raise ReadinessError(f"evidence contract for {family}/{module} has a bad header")
    rows = list(reader)
    if any(
        row.get("type")
        not in {"package", "verification_binary", "service", "foreign_architecture"}
        or not row.get("value")
        for row in rows
    ):
        raise ReadinessError(f"evidence contract for {family}/{module} has an invalid row")
    if not any(row["type"] == "package" for row in rows) or not any(
        row["type"] == "verification_binary" for row in rows
    ):
        raise ReadinessError(
            f"evidence contract for {family}/{module} lacks package or binary coverage"
        )
    return tuple(row["value"] for row in rows if row["type"] == "service")


def derive_supported_target_contract(
    root: Path, module: str, family: str, targets: tuple[dict[str, str], ...]
) -> tuple[tuple[str, ...], tuple[str, ...]]:
    """Derive the exact evidence targets accepted by a module-family contract.

    Family-wide modules accept every catalog target; target-restricted modules
    must be invoked with each exact OS/version/architecture tuple, so a
    supported single cell cannot accidentally be promoted as whole-family
    evidence.
    """

    supported: list[tuple[str, tuple[str, ...]]] = []
    for target in targets:
        try:
            services = derive_contract(root, module, family, target)
        except ReadinessError as error:
            if "does not support target" in str(error):
                continue
            raise
        supported.append((target["target_id"], services))
    if not supported:
        raise ReadinessError(
            f"evidence contract for {family}/{module} supports no catalog target cell"
        )
    service_sets = {services for _, services in supported}
    if len(service_sets) != 1:
        raise ReadinessError(
            f"evidence contract for {family}/{module} has inconsistent service declarations"
        )
    return tuple(target_id for target_id, _ in supported), supported[0][1]


def expected_rows_and_summary(
    root: Path,
    inventory_path: Path | None = None,
    admission_path: Path | None = None,
    report_root: Path | None = None,
) -> tuple[list[dict[str, str]], dict[str, int]]:
    inventory_path = inventory_path or root / "docs" / "legacy-inventory.tsv"
    try:
        with inventory_path.open("r", encoding="utf-8", newline="") as stream:
            inventory = list(csv.DictReader(stream, delimiter="\t"))
    except (OSError, UnicodeDecodeError, csv.Error) as error:
        raise ReadinessError(f"cannot read legacy inventory: {error}") from None
    expected_inventory_header = [
        "legacy_id",
        "source_set",
        "source_path",
        "source_item",
        "display_name",
        "normalized_capability",
        "target_family",
        "disposition",
        "replacement",
        "parity_level",
        "evidence",
        "rationale",
    ]
    if not inventory or list(inventory[0]) != expected_inventory_header:
        raise ReadinessError("legacy inventory has an unexpected header or no rows")
    active = [
        row
        for row in inventory
        if row["disposition"] in {"planned", "implemented", "superseded"}
    ]
    claimed_inventory_evidence = [
        row["legacy_id"]
        for row in active
        if row["disposition"] == "planned" and row["evidence"] != "-"
    ]
    if claimed_inventory_evidence:
        raise ReadinessError(
            "planned inventory rows must keep evidence '-' and record provisional "
            "references only in the readiness ledger: "
            + ", ".join(claimed_inventory_evidence)
        )

    targets = read_tsv(
        root / "tests" / "evidence-targets.tsv", TARGET_HEADER, "evidence target table"
    )
    target_ids = [row["target_id"] for row in targets]
    if len(target_ids) != len(set(target_ids)):
        raise ReadinessError("evidence target table contains duplicate target IDs")
    target_counts = Counter(row["family"] for row in targets)
    if target_counts != {"debian": 3, "rhel": 2}:
        raise ReadinessError(
            f"evidence target family counts drifted: {dict(sorted(target_counts.items()))}"
        )

    targets_by_family = {
        family: tuple(
            sorted(
                (row for row in targets if row["family"] == family),
                key=lambda row: row["target_id"],
            )
        )
        for family in {"debian", "rhel"}
    }
    pairs = sorted({(row["replacement"], row["target_family"]) for row in active})
    contracts = {
        (module, family): derive_supported_target_contract(
            root, module, family, targets_by_family[family]
        )
        for module, family in pairs
    }
    services = {key: contract[1] for key, contract in contracts.items()}
    expected: list[dict[str, str]] = []
    for row in active:
        module = row["replacement"]
        family = row["target_family"]
        key = (module, family)
        evidence_target_cells = contracts[key][0]
        has_services = bool(services[key])
        expected.append(
            {
                "legacy_id": row["legacy_id"],
                "target_family": family,
                "replacement": module,
                "evidence_key": f"{family}/{module}",
                "review_route": review_route(row),
                "parity_level": row["parity_level"],
                "required_standalone_cells": str(len(evidence_target_cells)),
                "service_contract": "yes" if has_services else "no",
                "shared_systemd_executions": (
                    str(len(evidence_target_cells) * 2) if has_services else "0"
                ),
                "evidence_target_cells": evidence_target_cells,
                "evidence_class": "none",
                "evidence_reference": "-",
                "promotion_ready": "no",
                "missing_acceptance": SERVICE_MISSING if has_services else BASE_MISSING,
            }
        )

    admissions = load_accepted_admissions(
        root, expected, registry_path=admission_path, report_root=report_root
    )
    for row, inventory_row in zip(expected, active):
        admission = admissions.get(row["evidence_key"])
        if admission is None:
            if inventory_row["disposition"] in {"implemented", "superseded"}:
                raise ReadinessError(
                    f"{inventory_row['legacy_id']} is terminal without accepted evidence for "
                    f"{row['evidence_key']}"
                )
            continue
        row["evidence_class"] = "accepted"
        row["evidence_reference"] = admission_reference(admission)
        row["promotion_ready"] = "yes"
        row["missing_acceptance"] = "-"
        if inventory_row["disposition"] in {"implemented", "superseded"} and (
            inventory_row["evidence"] != row["evidence_reference"]
        ):
            raise ReadinessError(
                f"{inventory_row['legacy_id']} terminal evidence does not match its "
                "accepted-evidence admission"
            )

    service_pairs = {key for key, values in services.items() if values}
    routes = Counter(row["review_route"] for row in expected)
    families = Counter(row["target_family"] for row in expected)
    summary = {
        "active_rows": len(expected),
        "planned_rows": sum(row["disposition"] == "planned" for row in active),
        "debian_rows": families["debian"],
        "rhel_rows": families["rhel"],
        "implemented_candidates": routes["implemented-candidate"],
        "superseded_candidates": routes["superseded-candidate"],
        "modules": len({row["replacement"] for row in expected}),
        "module_family_pairs": len(pairs),
        "standalone_cells": sum(len(contracts[key][0]) for key in pairs),
        "service_rows": sum(
            (row["replacement"], row["target_family"]) in service_pairs
            for row in active
        ),
        "service_modules": len({module for module, _ in service_pairs}),
        "service_pairs": len(service_pairs),
        "systemd_executions": sum(
            len(contracts[key][0]) * 2 for key in service_pairs
        ),
    }
    return expected, summary


def validate_readiness(
    root: Path, report_rows: list[dict[str, str]], expected: list[dict[str, str]]
) -> Counter[str]:
    if [row["legacy_id"] for row in report_rows] != [
        row["legacy_id"] for row in expected
    ]:
        raise ReadinessError(
            "readiness rows must cover active replacement inventory IDs exactly in inventory order"
        )
    evidence_classes: Counter[str] = Counter()
    # Keep this validator runnable on the Python 3.9 system interpreter shipped
    # by the exact Rocky/Alma 9 evidence targets. The ordered ID equality above
    # already proves equal lengths, so Python 3.10's zip(strict=True) is not needed.
    for observed, derived in zip(report_rows, expected):
        legacy_id = derived["legacy_id"]
        for key in READINESS_HEADER:
            if (
                derived["evidence_class"] == "none"
                and key in {"evidence_class", "evidence_reference"}
            ):
                continue
            if observed[key] != derived[key]:
                raise ReadinessError(
                    f"{legacy_id} readiness field {key} is mismatched: "
                    f"expected {derived[key]!r}, found {observed[key]!r}"
                )
        evidence_class = observed["evidence_class"]
        evidence_reference = observed["evidence_reference"]
        if derived["evidence_class"] == "accepted":
            if evidence_class != "accepted":
                raise ReadinessError(
                    f"{legacy_id} has admitted evidence but is not marked accepted"
                )
        elif evidence_class == "none":
            if evidence_reference != "-":
                raise ReadinessError(
                    f"{legacy_id} has an evidence reference but class none"
                )
        elif evidence_class == "provisional":
            if not valid_reference(root, evidence_reference):
                raise ReadinessError(
                    f"{legacy_id} provisional evidence is not a durable docs/ or HTTPS reference"
                )
        elif evidence_class == "accepted":
            raise ReadinessError(
                f"{legacy_id} claims accepted evidence without an admission registry entry"
            )
        else:
            raise ReadinessError(
                f"{legacy_id} has unknown evidence class: {evidence_class}"
            )
        evidence_classes[evidence_class] += 1
    return evidence_classes


def emit_rows(rows: list[dict[str, str]]) -> None:
    writer = csv.DictWriter(
        sys.stdout,
        fieldnames=READINESS_HEADER,
        delimiter="\t",
        lineterminator="\n",
        quoting=csv.QUOTE_NONE,
        extrasaction="ignore",
    )
    writer.writeheader()
    writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root", type=Path, default=Path(__file__).resolve().parents[1]
    )
    parser.add_argument("--emit", action="store_true")
    parser.add_argument("--inventory", type=Path)
    parser.add_argument("--readiness", type=Path)
    parser.add_argument("--admissions", type=Path)
    parser.add_argument("--report-root", type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    try:
        expected, summary = expected_rows_and_summary(
            root, args.inventory, args.admissions, args.report_root
        )
        baseline_summary = {
            key: summary[key] for key in EXPECTED_CATALOG_INVARIANTS
        }
        if baseline_summary != EXPECTED_CATALOG_INVARIANTS:
            raise ReadinessError(
                "promotion-readiness catalog invariants drifted: expected "
                f"{EXPECTED_CATALOG_INVARIANTS}, "
                f"found {baseline_summary}"
            )
        if args.emit:
            emit_rows(expected)
            return 0
        report_rows = read_tsv(
            args.readiness or root / "docs" / "legacy-promotion-readiness.tsv",
            READINESS_HEADER,
            "legacy promotion readiness report",
        )
        evidence_classes = validate_readiness(root, report_rows, expected)
    except ReadinessError as error:
        print(f"legacy promotion readiness validation failed: {error}", file=sys.stderr)
        return 1

    print(
        "Legacy promotion readiness valid: "
        f"{summary['active_rows']} active rows ({summary['planned_rows']} planned) -> "
        f"{summary['modules']} modules / "
        f"{summary['module_family_pairs']} family contracts / "
        f"{summary['standalone_cells']} standalone cells."
    )
    print(
        "Review routes: "
        f"{summary['implemented_candidates']} implemented candidates, "
        f"{summary['superseded_candidates']} superseded candidates."
    )
    print(
        "Systemd closure: "
        f"{summary['service_rows']} rows -> {summary['service_modules']} modules / "
        f"{summary['service_pairs']} family contracts / "
        f"{summary['systemd_executions']} executions."
    )
    print(
        "Evidence classes: "
        f"{evidence_classes['none']} none, "
        f"{evidence_classes['provisional']} provisional, "
        f"{evidence_classes['accepted']} accepted; "
        f"{sum(row['promotion_ready'] == 'yes' for row in expected)} active rows promotion-ready."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
