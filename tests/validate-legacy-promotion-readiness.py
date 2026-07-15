#!/usr/bin/env python3
"""Validate the derived readiness ledger for planned legacy replacements."""

from __future__ import annotations

import argparse
import csv
import io
import re
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
BASE_MISSING = (
    "G3-repository-resolution+G4-standalone-install+"
    "row-parity-review+durable-trust-anchor"
)
SERVICE_MISSING = (
    "G3-repository-resolution+G4-standalone-install+G5-systemd-behavior+"
    "row-parity-review+durable-trust-anchor"
)
EXPECTED_BASELINE = {
    "planned_rows": 142,
    "debian_rows": 70,
    "rhel_rows": 72,
    "implemented_candidates": 134,
    "superseded_candidates": 8,
    "modules": 80,
    "module_family_pairs": 90,
    "standalone_cells": 180,
    "service_rows": 32,
    "service_modules": 9,
    "service_pairs": 11,
    "systemd_executions": 44,
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
    if re.fullmatch(r"https://[^\s]+", reference):
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


def derive_contract(root: Path, module: str, family: str) -> tuple[str, ...]:
    try:
        completed = subprocess.run(
            [
                "bash",
                str(root / "tests" / "evidence-contract.sh"),
                str(root),
                module,
                family,
            ],
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
        row.get("type") not in {"package", "verification_binary", "service"}
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


def expected_rows_and_summary(root: Path) -> tuple[list[dict[str, str]], dict[str, int]]:
    inventory_path = root / "docs" / "legacy-inventory.tsv"
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
    planned = [row for row in inventory if row["disposition"] == "planned"]
    claimed_inventory_evidence = [
        row["legacy_id"] for row in planned if row["evidence"] != "-"
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
    if target_counts != {"debian": 2, "rhel": 2}:
        raise ReadinessError(
            f"evidence target family counts drifted: {dict(sorted(target_counts.items()))}"
        )

    pairs = sorted({(row["replacement"], row["target_family"]) for row in planned})
    services = {
        (module, family): derive_contract(root, module, family)
        for module, family in pairs
    }
    expected: list[dict[str, str]] = []
    for row in planned:
        module = row["replacement"]
        family = row["target_family"]
        key = (module, family)
        has_services = bool(services[key])
        expected.append(
            {
                "legacy_id": row["legacy_id"],
                "target_family": family,
                "replacement": module,
                "evidence_key": f"{family}/{module}",
                "review_route": review_route(row),
                "parity_level": row["parity_level"],
                "required_standalone_cells": str(target_counts[family]),
                "service_contract": "yes" if has_services else "no",
                "shared_systemd_executions": (
                    str(target_counts[family] * 2) if has_services else "0"
                ),
                "evidence_class": "none",
                "evidence_reference": "-",
                "promotion_ready": "no",
                "missing_acceptance": SERVICE_MISSING if has_services else BASE_MISSING,
            }
        )

    service_pairs = {key for key, values in services.items() if values}
    routes = Counter(row["review_route"] for row in expected)
    families = Counter(row["target_family"] for row in expected)
    summary = {
        "planned_rows": len(expected),
        "debian_rows": families["debian"],
        "rhel_rows": families["rhel"],
        "implemented_candidates": routes["implemented-candidate"],
        "superseded_candidates": routes["superseded-candidate"],
        "modules": len({row["replacement"] for row in expected}),
        "module_family_pairs": len(pairs),
        "standalone_cells": sum(target_counts[family] for _, family in pairs),
        "service_rows": sum(
            (row["replacement"], row["target_family"]) in service_pairs
            for row in planned
        ),
        "service_modules": len({module for module, _ in service_pairs}),
        "service_pairs": len(service_pairs),
        "systemd_executions": sum(
            target_counts[family] * 2 for _, family in service_pairs
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
            "readiness rows must cover planned inventory IDs exactly in inventory order"
        )
    evidence_classes: Counter[str] = Counter()
    # Keep this validator runnable on the Python 3.9 system interpreter shipped
    # by the exact Rocky/Alma 9 evidence targets. The ordered ID equality above
    # already proves equal lengths, so Python 3.10's zip(strict=True) is not needed.
    for observed, derived in zip(report_rows, expected):
        legacy_id = derived["legacy_id"]
        for key in READINESS_HEADER:
            if key in {"evidence_class", "evidence_reference"}:
                continue
            if observed[key] != derived[key]:
                raise ReadinessError(
                    f"{legacy_id} readiness field {key} is mismatched: "
                    f"expected {derived[key]!r}, found {observed[key]!r}"
                )
        evidence_class = observed["evidence_class"]
        evidence_reference = observed["evidence_reference"]
        if evidence_class == "none":
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
                f"{legacy_id} remains planned and cannot claim accepted evidence"
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
    )
    writer.writeheader()
    writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root", type=Path, default=Path(__file__).resolve().parents[1]
    )
    parser.add_argument("--emit", action="store_true")
    args = parser.parse_args()
    root = args.root.resolve()
    try:
        expected, summary = expected_rows_and_summary(root)
        if summary != EXPECTED_BASELINE:
            raise ReadinessError(
                f"promotion-readiness baseline drifted: expected {EXPECTED_BASELINE}, "
                f"found {summary}"
            )
        if args.emit:
            emit_rows(expected)
            return 0
        report_rows = read_tsv(
            root / "docs" / "legacy-promotion-readiness.tsv",
            READINESS_HEADER,
            "legacy promotion readiness report",
        )
        evidence_classes = validate_readiness(root, report_rows, expected)
    except ReadinessError as error:
        print(f"legacy promotion readiness validation failed: {error}", file=sys.stderr)
        return 1

    print(
        "Legacy promotion readiness valid: "
        f"{summary['planned_rows']} rows -> {summary['modules']} modules / "
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
        f"{evidence_classes['provisional']} provisional, 0 accepted; "
        "0 planned rows promotion-ready."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
