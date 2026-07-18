#!/usr/bin/env python3
"""Derive the exact systemd evidence executions from reviewed repository data."""

from __future__ import annotations

import argparse
import csv
import io
import json
import subprocess
import sys
from pathlib import Path


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
PLAN_HEADER = [
    "execution_id",
    "target_id",
    "display_name",
    "family",
    "module",
    "mode",
    "standalone_image_tag",
    "platform",
    "expected_os_id",
    "expected_version_id",
    "expected_arch",
    "services",
]
MODES = ("default", "enable-services")


class MatrixError(Exception):
    """A deterministic plan-generation failure."""


def read_tsv(path: Path, header: list[str], label: str) -> list[dict[str, str]]:
    try:
        with path.open("r", encoding="utf-8", newline="") as stream:
            reader = csv.DictReader(stream, delimiter="\t", quoting=csv.QUOTE_NONE)
            if reader.fieldnames != header:
                raise MatrixError(f"{label} has an unexpected header")
            rows = list(reader)
    except (OSError, UnicodeDecodeError, csv.Error) as error:
        raise MatrixError(f"cannot read {label}: {error}") from None
    if any(None in row or any(value is None for value in row.values()) for row in rows):
        raise MatrixError(f"{label} contains a malformed row")
    return rows


def validate_readiness(root: Path) -> None:
    completed = subprocess.run(
        ["bash", str(root / "tests" / "validate-legacy-promotion-readiness.sh")],
        cwd=root,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
        timeout=120,
    )
    if completed.returncode != 0:
        raise MatrixError(
            "legacy promotion readiness validation failed before systemd planning: "
            + (completed.stderr.strip() or "unknown error")
        )


def services_for(
    root: Path,
    module: str,
    family: str,
    os_id: str,
    version_id: str,
    architecture: str,
) -> tuple[str, ...]:
    completed = subprocess.run(
        [
            "bash",
            str(root / "tests" / "evidence-contract.sh"),
            str(root),
            module,
            family,
            os_id,
            version_id,
            architecture,
        ],
        cwd=root,
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
        timeout=30,
    )
    if completed.returncode != 0:
        raise MatrixError(f"cannot derive service contract for {family}/{module}")
    reader = csv.DictReader(io.StringIO(completed.stdout), delimiter="\t")
    if reader.fieldnames != ["type", "value"]:
        raise MatrixError(f"service contract for {family}/{module} has a bad header")
    rows = list(reader)
    services = tuple(row["value"] for row in rows if row.get("type") == "service")
    if (
        not services
        or any(not service for service in services)
        or len(services) != len(set(services))
    ):
        raise MatrixError(f"service contract for {family}/{module} is empty")
    return services


def build_plan(root: Path) -> list[dict[str, str]]:
    validate_readiness(root)
    readiness = read_tsv(
        root / "docs" / "legacy-promotion-readiness.tsv",
        READINESS_HEADER,
        "legacy promotion readiness report",
    )
    targets = read_tsv(
        root / "tests" / "evidence-targets.tsv", TARGET_HEADER, "evidence target table"
    )
    evidence_keys = sorted(
        {
            (row["target_family"], row["replacement"])
            for row in readiness
            if row["service_contract"] == "yes"
        }
    )
    if len(evidence_keys) != 14 or len({module for _, module in evidence_keys}) != 12:
        raise MatrixError("service-bearing readiness coverage drifted from 14 contracts / 12 modules")

    target_ids = [row["target_id"] for row in targets]
    if len(target_ids) != len(set(target_ids)):
        raise MatrixError("evidence target table repeats a target ID")

    rows: list[dict[str, str]] = []
    for family, module in evidence_keys:
        family_targets = [row for row in targets if row["family"] == family]
        expected_target_count = {"debian": 3, "rhel": 2}[family]
        if len(family_targets) != expected_target_count:
            raise MatrixError(
                f"{family} must have exactly {expected_target_count} evidence targets"
            )
        for target in family_targets:
            service_values = services_for(
                root,
                module,
                family,
                target["expected_os_id"],
                target["expected_version_id"],
                target["expected_arch"],
            )
            for mode in MODES:
                rows.append(
                    {
                        "execution_id": f"{target['target_id']}-{module}-{mode}",
                        "target_id": target["target_id"],
                        "display_name": target["display_name"],
                        "family": family,
                        "module": module,
                        "mode": mode,
                        # This is the existing standalone/container catalog tag.
                        # It is selection metadata, never VM provenance.
                        "standalone_image_tag": target["image"],
                        "platform": target["platform"],
                        "expected_os_id": target["expected_os_id"],
                        "expected_version_id": target["expected_version_id"],
                        "expected_arch": target["expected_arch"],
                        "services": ",".join(service_values),
                    }
                )
    execution_ids = [row["execution_id"] for row in rows]
    if len(rows) != 64 or len(execution_ids) != len(set(execution_ids)):
        raise MatrixError("systemd evidence plan must contain 64 unique executions")
    return rows


def emit_plan(rows: list[dict[str, str]]) -> None:
    writer = csv.DictWriter(
        sys.stdout,
        fieldnames=PLAN_HEADER,
        delimiter="\t",
        lineterminator="\n",
        quoting=csv.QUOTE_NONE,
    )
    writer.writeheader()
    writer.writerows(rows)


def emit_matrix(rows: list[dict[str, str]]) -> None:
    print(json.dumps({"include": rows}, separators=(",", ":"), sort_keys=True))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("format", choices=("plan", "matrix"))
    args = parser.parse_args()
    try:
        rows = build_plan(args.root.resolve())
    except (MatrixError, OSError, UnicodeDecodeError, subprocess.TimeoutExpired) as error:
        print(f"systemd evidence matrix failed: {error}", file=sys.stderr)
        return 1
    if args.format == "plan":
        emit_plan(rows)
    else:
        emit_matrix(rows)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
