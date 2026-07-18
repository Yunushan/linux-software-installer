#!/usr/bin/env python3
"""Verify a downloaded GitHub standalone-evidence artifact before admission.

This verifier deliberately does not edit ``accepted-evidence.tsv``. A human
still has to review parity and supply any required systemd attestation. It
proves that a downloaded artifact matches GitHub's published ZIP digest and
contains a successful aggregate index for the stated commit and workflow run.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import re
import stat
import sys
import tarfile
import zipfile
from pathlib import PurePosixPath, Path
from typing import Any


SCHEMA = "linux-software-installer/module-install-evidence-index/v1"
VERIFICATION_SCHEMA = "linux-software-installer/accepted-evidence-verification/v2"
REPOSITORY = "Yunushan/linux-software-installer"
SHA256 = re.compile(r"^[0-9a-f]{64}$")
COMMIT = re.compile(r"^[0-9a-f]{40}$")
RUN_URL = re.compile(
    r"^https://github\.com/Yunushan/linux-software-installer/actions/runs/([1-9][0-9]*)$"
)
REQUIRED_FILES = {
    "index.json",
    "index.json.sha256",
    "summary.tsv",
    "expected-cells.tsv",
    "resolved-targets.tsv",
    "module-evidence-cells.tar.gz",
    "module-evidence-cells.tar.gz.sha256",
}
SUMMARY_HEADER = [
    "cell_id",
    "target_id",
    "family",
    "module",
    "result",
    "failure_stage",
    "validation_errors",
]
EXPECTED_CELLS_HEADER = [
    "cell_id",
    "target_id",
    "family",
    "module",
    "image",
    "platform",
    "expected_os_id",
    "expected_version_id",
    "expected_arch",
]
SLUG = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")


class EvidenceError(ValueError):
    """A downloaded artifact cannot be used for evidence admission."""


def digest_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def safe_relative(name: str) -> PurePosixPath:
    path = PurePosixPath(name)
    if not name or path.is_absolute() or ".." in path.parts or str(path) in {".", ""}:
        raise EvidenceError(f"artifact contains an unsafe path: {name!r}")
    return path


def zip_payload(path: Path, maximum_size: int = 512 * 1024 * 1024) -> tuple[bytes, dict[str, bytes]]:
    try:
        raw = path.read_bytes()
    except OSError as error:
        raise EvidenceError(f"cannot read artifact ZIP: {error}") from None
    if not raw or len(raw) > maximum_size:
        raise EvidenceError("artifact ZIP is empty or exceeds the 512 MiB admission limit")
    try:
        archive = zipfile.ZipFile(io.BytesIO(raw))
    except (OSError, zipfile.BadZipFile) as error:
        raise EvidenceError(f"artifact is not a valid ZIP file: {error}") from None

    entries: dict[str, bytes] = {}
    total_uncompressed = 0
    for member in archive.infolist():
        name = member.filename
        safe_relative(name.rstrip("/"))
        if member.is_dir():
            continue
        mode = member.external_attr >> 16
        if stat.S_ISLNK(mode) or member.flag_bits & 0x1:
            raise EvidenceError(f"artifact contains a link or encrypted entry: {name}")
        if member.file_size > 128 * 1024 * 1024:
            raise EvidenceError(f"artifact entry exceeds the 128 MiB admission limit: {name}")
        total_uncompressed += member.file_size
        if total_uncompressed > maximum_size:
            raise EvidenceError("artifact uncompressed content exceeds the 512 MiB admission limit")
        if name in entries:
            raise EvidenceError(f"artifact repeats an entry: {name}")
        entries[name] = archive.read(member)
    if not entries:
        raise EvidenceError("artifact ZIP contains no regular files")

    prefixes = {PurePosixPath(name).parts[0] for name in entries if len(PurePosixPath(name).parts) > 1}
    roots = {PurePosixPath(name).parts[0] for name in entries}
    if len(prefixes) == 1 and roots == prefixes:
        prefix = next(iter(prefixes)) + "/"
        entries = {name.removeprefix(prefix): value for name, value in entries.items()}
    if set(entries) != REQUIRED_FILES:
        missing = sorted(REQUIRED_FILES - set(entries))
        extra = sorted(set(entries) - REQUIRED_FILES)
        raise EvidenceError(f"artifact file set is unexpected; missing={missing}, extra={extra}")
    return raw, entries


def require_sha_line(payload: bytes, filename: str) -> str:
    try:
        line = payload.decode("ascii", errors="strict")
    except UnicodeDecodeError as error:
        raise EvidenceError(f"{filename} checksum is not ASCII: {error}") from None
    expected = f"  {filename.removesuffix('.sha256')}\n"
    if not line.endswith(expected) or not SHA256.fullmatch(line[:64]) or len(line) != 64 + len(expected):
        raise EvidenceError(f"{filename} has an invalid checksum record")
    return line[:64]


def parse_index(payload: bytes, commit: str, run_url: str) -> dict[str, Any]:
    try:
        index = json.loads(payload.decode("utf-8", errors="strict"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise EvidenceError(f"aggregate index is not strict UTF-8 JSON: {error}") from None
    if not isinstance(index, dict) or index.get("schema") != SCHEMA:
        raise EvidenceError("aggregate index has an unexpected schema")
    if index.get("tested_commit") != commit or not COMMIT.fullmatch(commit):
        raise EvidenceError("aggregate index is not bound to the requested full commit")
    source = index.get("source")
    if not isinstance(source, dict) or source.get("repository") != REPOSITORY or source.get("run_url") != run_url:
        raise EvidenceError("aggregate index source does not match the requested repository or run URL")
    match = RUN_URL.fullmatch(run_url)
    if match is None or str(source.get("run_id")) != match.group(1):
        raise EvidenceError("aggregate index run ID is not bound to its run URL")
    if index.get("validation_passed") is not True or index.get("issues") != []:
        raise EvidenceError("aggregate index does not report a successful validation")
    expected = index.get("expected_cells")
    found = index.get("found_cells")
    cells = index.get("cells")
    if not isinstance(expected, int) or expected <= 0 or found != expected or not isinstance(cells, list) or len(cells) != expected:
        raise EvidenceError("aggregate index has inconsistent evidence-cell coverage")
    seen: set[str] = set()
    for cell in cells:
        if not isinstance(cell, dict):
            raise EvidenceError("aggregate index contains a non-object cell")
        cell_id = cell.get("cell_id")
        if not isinstance(cell_id, str) or not re.fullmatch(
            r"[a-z0-9]+(?:-[a-z0-9]+)*/[a-z0-9]+(?:-[a-z0-9]+)*", cell_id
        ) or cell_id in seen:
            raise EvidenceError("aggregate index has an invalid or duplicate cell ID")
        seen.add(cell_id)
        if (
            cell.get("result") != "passed"
            or cell.get("failure_stage") != "-"
            or cell.get("validation_errors") != "0"
        ):
            raise EvidenceError(f"aggregate index cell {cell_id} is not a clean pass")
        if not isinstance(cell.get("result_sha256"), str) or not SHA256.fullmatch(cell["result_sha256"]):
            raise EvidenceError(f"aggregate index cell {cell_id} lacks a result digest")
    return index


def verify_summary(payload: bytes, index: dict[str, Any]) -> None:
    try:
        rows = list(csv.DictReader(io.StringIO(payload.decode("utf-8", errors="strict")), delimiter="\t"))
    except UnicodeDecodeError as error:
        raise EvidenceError(f"summary TSV is not UTF-8: {error}") from None
    if not rows or list(rows[0]) != SUMMARY_HEADER or len(rows) != len(index["cells"]):
        raise EvidenceError("summary TSV has an unexpected schema or row count")
    by_id = {row["cell_id"]: row for row in rows}
    if len(by_id) != len(rows):
        raise EvidenceError("summary TSV repeats a cell ID")
    for cell in index["cells"]:
        row = by_id.get(cell["cell_id"])
        if row is None or any(row[field] != str(cell[field]) for field in SUMMARY_HEADER):
            raise EvidenceError(f"summary TSV disagrees with aggregate index for {cell['cell_id']}")


def parse_expected_cells(payload: bytes, index: dict[str, Any]) -> list[dict[str, str]]:
    try:
        reader = csv.DictReader(io.StringIO(payload.decode("utf-8", errors="strict")), delimiter="\t")
        rows = list(reader)
    except UnicodeDecodeError as error:
        raise EvidenceError(f"expected-cells TSV is not UTF-8: {error}") from None
    if reader.fieldnames != EXPECTED_CELLS_HEADER or len(rows) != len(index["cells"]):
        raise EvidenceError("expected-cells TSV has an unexpected schema or row count")
    by_id = {row.get("cell_id", ""): row for row in rows}
    if len(by_id) != len(rows) or any(set(row) != set(EXPECTED_CELLS_HEADER) for row in rows):
        raise EvidenceError("expected-cells TSV has invalid or duplicate rows")
    for cell in index["cells"]:
        row = by_id.get(cell["cell_id"])
        if row is None or any(row[key] != str(cell[key]) for key in ("target_id", "family", "module")):
            raise EvidenceError(f"expected-cells TSV disagrees with aggregate index for {cell['cell_id']}")
    return rows


def verify_requested_module_cells(
    rows: list[dict[str, str]], module: str, requested_targets: list[str]
) -> list[str]:
    if not SLUG.fullmatch(module):
        raise EvidenceError("requested module is invalid")
    if not requested_targets or len(requested_targets) != len(set(requested_targets)) or any(
        not SLUG.fullmatch(target) for target in requested_targets
    ):
        raise EvidenceError("requested target cells are invalid or duplicated")
    available_targets = {row["target_id"] for row in rows if row["module"] == module}
    if not set(requested_targets).issubset(available_targets):
        raise EvidenceError("artifact does not contain every requested module target cell")
    return [f"{target}/{module}" for target in sorted(requested_targets)]


def verify_bundle(payload: bytes, commit: str, index: dict[str, Any]) -> None:
    try:
        archive = tarfile.open(fileobj=io.BytesIO(payload), mode="r:gz")
    except (OSError, tarfile.TarError) as error:
        raise EvidenceError(f"evidence bundle is not a valid gzip tar archive: {error}") from None
    tested_commit: bytes | None = None
    seen_regular = 0
    seen_names: set[str] = set()
    expected_results = {
        f"module-cells/cells/{cell['target_id']}/{cell['module']}/result.json": cell[
            "result_sha256"
        ]
        for cell in index["cells"]
    }
    found_results: set[str] = set()
    for member in archive.getmembers():
        safe_relative(member.name)
        if member.issym() or member.islnk() or member.isdev() or member.isfifo():
            raise EvidenceError(f"evidence bundle contains an unsafe entry: {member.name}")
        if member.isfile():
            if member.name in seen_names:
                raise EvidenceError(f"evidence bundle repeats an entry: {member.name}")
            seen_names.add(member.name)
            seen_regular += 1
            if member.size > 128 * 1024 * 1024:
                raise EvidenceError(f"evidence bundle entry is too large: {member.name}")
            if member.name == "module-evidence-plan/tested-commit.txt":
                handle = archive.extractfile(member)
                tested_commit = handle.read() if handle is not None else None
            expected_digest = expected_results.get(member.name)
            if expected_digest is not None:
                handle = archive.extractfile(member)
                content = handle.read() if handle is not None else None
                if content is None or digest_bytes(content) != expected_digest:
                    raise EvidenceError(
                        f"evidence bundle result does not match aggregate digest: {member.name}"
                    )
                found_results.add(member.name)
    if not seen_regular or tested_commit != (commit + "\n").encode("ascii"):
        raise EvidenceError("evidence bundle lacks the exact tested-commit marker")
    if found_results != set(expected_results):
        raise EvidenceError("evidence bundle lacks an indexed cell result")


def verify_artifact(args: argparse.Namespace) -> tuple[str, str, dict[str, Any], list[dict[str, str]]]:
    expected_digest = args.artifact_digest.removeprefix("sha256:")
    if not SHA256.fullmatch(expected_digest) or not COMMIT.fullmatch(args.commit) or RUN_URL.fullmatch(args.run_url) is None:
        raise EvidenceError("commit, run URL, or artifact digest has an invalid format")
    raw, entries = zip_payload(Path(args.artifact_zip))
    observed_digest = digest_bytes(raw)
    if observed_digest != expected_digest:
        raise EvidenceError("downloaded artifact ZIP does not match the published artifact digest")
    index_digest = require_sha_line(entries["index.json.sha256"], "index.json.sha256")
    if index_digest != digest_bytes(entries["index.json"]):
        raise EvidenceError("aggregate index checksum does not match index.json")
    bundle_digest = require_sha_line(
        entries["module-evidence-cells.tar.gz.sha256"], "module-evidence-cells.tar.gz.sha256"
    )
    if bundle_digest != digest_bytes(entries["module-evidence-cells.tar.gz"]):
        raise EvidenceError("evidence bundle checksum does not match its payload")
    index = parse_index(entries["index.json"], args.commit, args.run_url)
    verify_summary(entries["summary.tsv"], index)
    expected_rows = parse_expected_cells(entries["expected-cells.tsv"], index)
    verify_bundle(entries["module-evidence-cells.tar.gz"], args.commit, index)
    return observed_digest, index_digest, index, expected_rows


def make_report(
    artifact_digest: str,
    index_digest: str,
    index: dict[str, Any],
    commit: str,
    run_url: str,
    module: str,
    target_cells: list[str],
) -> dict[str, Any]:
    cell_ids = verify_requested_module_cells(
        [row for row in index["expected_rows"]], module, target_cells
    )
    return {
        "schema": VERIFICATION_SCHEMA,
        "artifact_sha256": artifact_digest,
        "index_sha256": index_digest,
        "commit_sha": commit,
        "run_url": run_url,
        "expected_cells": index["expected_cells"],
        "module": module,
        "target_cells": sorted(target_cells),
        "cell_ids": cell_ids,
        "result": "verified-awaiting-parity-review-and-systemd-attestation",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--artifact-zip", required=True)
    parser.add_argument("--artifact-digest", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--run-url", required=True)
    parser.add_argument("--module")
    parser.add_argument("--target-cell", action="append", default=[])
    parser.add_argument("--evidence-key", action="append", default=[])
    parser.add_argument("--output")
    parser.add_argument("--output-dir", type=Path)
    args = parser.parse_args()
    try:
        artifact_digest, index_digest, index, expected_rows = verify_artifact(args)
        index["expected_rows"] = expected_rows
        if args.module:
            if args.evidence_key or args.output is None or args.output_dir is not None:
                raise EvidenceError("single-module mode requires --output and no --evidence-key or --output-dir")
            report = make_report(
                artifact_digest, index_digest, index, args.commit, args.run_url, args.module, args.target_cell
            )
            Path(args.output).write_text(
                json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8"
            )
        else:
            if not args.evidence_key or args.output_dir is None or args.output is not None or args.target_cell:
                raise EvidenceError("batch mode requires --evidence-key and --output-dir only")
            keys = sorted(set(args.evidence_key))
            if len(keys) != len(args.evidence_key):
                raise EvidenceError("batch evidence keys are duplicated")
            reports: list[tuple[str, dict[str, Any]]] = []
            for key in keys:
                family, separator, module = key.partition("/")
                if separator != "/" or family not in {"debian", "rhel"} or not SLUG.fullmatch(module):
                    raise EvidenceError("batch evidence key is invalid")
                targets = sorted(
                    row["target_id"]
                    for row in expected_rows
                    if row["family"] == family and row["module"] == module
                )
                report = make_report(
                    artifact_digest, index_digest, index, args.commit, args.run_url, module, targets
                )
                reports.append((f"{family}-{module}.json", report))
            args.output_dir.mkdir(parents=True, exist_ok=False)
            for filename, report in reports:
                (args.output_dir / filename).write_text(
                    json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8"
                )
            report = {"expected_cells": index["expected_cells"]}
    except (EvidenceError, OSError) as error:
        print(f"accepted-evidence artifact verification failed: {error}", file=sys.stderr)
        return 1
    print(f"Verified downloaded evidence artifact for {report['expected_cells']} cells.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
