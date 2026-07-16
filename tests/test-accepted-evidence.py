#!/usr/bin/env python3
"""Adversarial tests for accepted-evidence admission records."""

from __future__ import annotations

import importlib.util
import json
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "tests" / "validate-legacy-promotion-readiness.py"
SPEC = importlib.util.spec_from_file_location("promotion_readiness", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
READINESS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(READINESS)

COMMIT = "a" * 40
SHA = "b" * 64
INDEX_SHA = "c" * 64
RUN_URL = "https://github.com/Yunushan/linux-software-installer/actions/runs/123"
ARTIFACT_URL = RUN_URL + "/artifacts/456"


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as stream:
        stream.write(text)


def make_root() -> Path:
    root = Path(tempfile.mkdtemp(prefix="lsi-accepted-evidence-"))
    write(root / "docs" / "parity.md", "# reviewed parity\n")
    write(
        root / "docs" / "verified-nginx.json",
        json.dumps(
            {
                "schema": READINESS.VERIFICATION_SCHEMA,
                "artifact_sha256": SHA,
                "index_sha256": INDEX_SHA,
                "commit_sha": COMMIT,
                "run_url": RUN_URL,
                "expected_cells": 2,
                "module": "nginx",
                "target_cells": ["debian-12", "ubuntu-24-04"],
                "cell_ids": ["debian-12/nginx", "ubuntu-24-04/nginx"],
                "result": "verified-awaiting-parity-review-and-systemd-attestation",
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
    )
    write(
        root / "tests" / "evidence-targets.tsv",
        "\t".join(READINESS.TARGET_HEADER)
        + "\n"
        + "ubuntu-24-04\tUBUNTU\tUbuntu\tdebian\tubuntu:24.04\tlinux/amd64\tubuntu\t24.04\tx86_64\n"
        + "debian-12\tDEBIAN\tDebian\tdebian\tdebian:12\tlinux/amd64\tdebian\t12\tx86_64\n"
        + "rocky-9-8\tROCKY\tRocky\trhel\trocky:9.8\tlinux/amd64\trocky\t9.8\tx86_64\n"
        + "alma-9-8\tALMA\tAlma\trhel\talma:9.8\tlinux/amd64\talmalinux\t9.8\tx86_64\n",
    )
    return root


def expected_row(service: str = "no") -> dict[str, str]:
    return {
        "evidence_key": "debian/nginx",
        "target_family": "debian",
        "replacement": "nginx",
        "service_contract": service,
    }


def record(service: bool = False) -> dict[str, str]:
    return {
        "evidence_key": "debian/nginx",
        "commit_sha": COMMIT,
        "run_url": RUN_URL,
        "artifact_url": ARTIFACT_URL,
        "artifact_digest": "sha256:" + SHA,
        "index_sha256": INDEX_SHA,
        "target_cells": "debian-12,ubuntu-24-04",
        "parity_report": "docs/parity.md",
        "systemd_run_url": "https://evidence.example.invalid/systemd/1" if service else "-",
        "systemd_artifact_url": "https://evidence.example.invalid/systemd/1/artifact" if service else "-",
        "systemd_artifact_digest": "sha256:" + SHA if service else "-",
        "verification_report": "docs/verified-nginx.json",
    }


def write_registry(root: Path, rows: list[dict[str, str]]) -> None:
    lines = ["\t".join(READINESS.ADMISSION_HEADER)]
    lines.extend("\t".join(row[field] for field in READINESS.ADMISSION_HEADER) for row in rows)
    write(root / "docs" / "accepted-evidence.tsv", "\n".join(lines) + "\n")


def expect_failure(root: Path, rows: list[dict[str, str]], service: str = "no") -> bool:
    write_registry(root, rows)
    try:
        READINESS.load_accepted_admissions(root, [expected_row(service)], commit=COMMIT)
    except READINESS.ReadinessError:
        return True
    return False


def main() -> int:
    root = make_root()
    valid = record()
    write_registry(root, [valid])
    admissions = READINESS.load_accepted_admissions(root, [expected_row()], commit=COMMIT)
    assert admissions == {"debian/nginx": valid}
    assert READINESS.admission_reference(valid).endswith("artifact-digest=" + SHA)

    wrong_targets = record()
    wrong_targets["target_cells"] = "ubuntu-24-04"
    assert expect_failure(root, [wrong_targets])

    wrong_url = record()
    wrong_url["artifact_url"] = "https://github.com/Yunushan/linux-software-installer/actions/runs/999/artifacts/456"
    assert expect_failure(root, [wrong_url])

    wrong_report = record()
    wrong_report["verification_report"] = "docs/parity.md"
    assert expect_failure(root, [wrong_report])

    duplicate = record()
    assert expect_failure(root, [valid, duplicate])

    assert expect_failure(root, [record()], service="yes")
    service_record = record(service=True)
    write_registry(root, [service_record])
    assert READINESS.load_accepted_admissions(root, [expected_row("yes")], commit=COMMIT)

    (root / "docs" / "accepted-evidence.tsv").write_bytes(
        "\t".join(READINESS.ADMISSION_HEADER).encode("utf-8")
    )
    try:
        READINESS.load_accepted_admissions(root, [expected_row()], commit=COMMIT)
    except READINESS.ReadinessError as error:
        assert "NUL-free and end with a newline" in str(error)
    else:
        raise AssertionError("accepted-evidence registry without a final newline was accepted")

    print("accepted-evidence admission tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
