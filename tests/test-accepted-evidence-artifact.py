#!/usr/bin/env python3
"""Unit checks for the downloaded accepted-evidence artifact verifier."""

from __future__ import annotations

import hashlib
import io
import json
import subprocess
import sys
import tarfile
import tempfile
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VERIFIER = ROOT / "tests" / "verify-accepted-evidence-artifact.py"
COMMIT = "a" * 40
RUN_URL = "https://github.com/Yunushan/linux-software-installer/actions/runs/123"


def sha(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def checksum(name: str, value: bytes) -> bytes:
    return f"{sha(value)}  {name}\n".encode("ascii")


def bundle(result_payload: bytes) -> bytes:
    raw = io.BytesIO()
    with tarfile.open(fileobj=raw, mode="w:gz") as archive:
        payload = (COMMIT + "\n").encode("ascii")
        info = tarfile.TarInfo("module-evidence-plan/tested-commit.txt")
        info.size = len(payload)
        archive.addfile(info, io.BytesIO(payload))
        info = tarfile.TarInfo("module-cells/cells/ubuntu-24-04/demo/result.json")
        info.size = len(result_payload)
        archive.addfile(info, io.BytesIO(result_payload))
    return raw.getvalue()


def artifact(validation_passed: bool = True, result_sha: str | None = None) -> bytes:
    result_payload = b"{}\n"
    index = {
        "schema": "linux-software-installer/module-install-evidence-index/v1",
        "tested_commit": COMMIT,
        "source": {
            "repository": "Yunushan/linux-software-installer",
            "ref": "refs/heads/main",
            "run_id": "123",
            "run_attempt": "1",
            "run_url": RUN_URL,
        },
        "generated_at": "2026-07-16T00:00:00Z",
        "expected_cells": 1,
        "found_cells": 1,
        "validation_passed": validation_passed,
        "issues": [] if validation_passed else ["failed"],
        "cells": [
            {
                "cell_id": "demo-cell",
                "target_id": "ubuntu-24-04",
                "family": "debian",
                "module": "demo",
                "result": "passed",
                "failure_stage": "-",
                "validation_errors": 0,
                "result_sha256": result_sha or sha(result_payload),
            }
        ],
    }
    index_bytes = (json.dumps(index, indent=2, sort_keys=True) + "\n").encode("utf-8")
    summary = (
        "cell_id\ttarget_id\tfamily\tmodule\tresult\tfailure_stage\tvalidation_errors\n"
        "demo-cell\tubuntu-24-04\tdebian\tdemo\tpassed\t-\t0\n"
    ).encode("utf-8")
    archive = bundle(result_payload)
    raw = io.BytesIO()
    with zipfile.ZipFile(raw, "w", compression=zipfile.ZIP_DEFLATED) as output:
        prefix = "module-evidence-aggregate/"
        output.writestr(prefix + "index.json", index_bytes)
        output.writestr(prefix + "index.json.sha256", checksum("index.json", index_bytes))
        output.writestr(prefix + "summary.tsv", summary)
        output.writestr(
            prefix + "expected-cells.tsv",
            (
                "cell_id\ttarget_id\tfamily\tmodule\timage\tplatform\t"
                "expected_os_id\texpected_version_id\texpected_arch\n"
                "demo-cell\tubuntu-24-04\tdebian\tdemo\tubuntu:24.04\t"
                "linux/amd64\tubuntu\t24.04\tx86_64\n"
            ).encode("utf-8"),
        )
        output.writestr(prefix + "resolved-targets.tsv", b"target_id\n")
        output.writestr(prefix + "module-evidence-cells.tar.gz", archive)
        output.writestr(
            prefix + "module-evidence-cells.tar.gz.sha256",
            checksum("module-evidence-cells.tar.gz", archive),
        )
    return raw.getvalue()


def append_zip_entry(payload: bytes, name: str, value: bytes) -> bytes:
    raw = io.BytesIO()
    with zipfile.ZipFile(io.BytesIO(payload)) as original, zipfile.ZipFile(
        raw, "w", compression=zipfile.ZIP_DEFLATED
    ) as modified:
        for member in original.infolist():
            modified.writestr(member, original.read(member))
        modified.writestr(name, value)
    return raw.getvalue()


def invoke(
    path: Path, digest: str, output: Path, module: str = "demo", target: str = "ubuntu-24-04"
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            sys.executable,
            str(VERIFIER),
            "--artifact-zip",
            str(path),
            "--artifact-digest",
            "sha256:" + digest,
            "--commit",
            COMMIT,
            "--run-url",
            RUN_URL,
            "--module",
            module,
            "--target-cell",
            target,
            "--output",
            str(output),
        ],
        check=False,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="lsi-accepted-artifact-") as temporary:
        root = Path(temporary)
        good = artifact()
        good_path = root / "good.zip"
        good_path.write_bytes(good)
        report = root / "report.json"
        completed = invoke(good_path, sha(good), report)
        assert completed.returncode == 0, completed.stderr
        observed = json.loads(report.read_text(encoding="utf-8"))
        assert observed["index_sha256"] == sha(
            zipfile.ZipFile(io.BytesIO(good)).read("module-evidence-aggregate/index.json")
        )
        assert observed["module"] == "demo"
        assert observed["cell_ids"] == ["ubuntu-24-04/demo"]

        batch_dir = root / "batch"
        batch = subprocess.run(
            [
                sys.executable,
                str(VERIFIER),
                "--artifact-zip",
                str(good_path),
                "--artifact-digest",
                "sha256:" + sha(good),
                "--commit",
                COMMIT,
                "--run-url",
                RUN_URL,
                "--evidence-key",
                "debian/demo",
                "--output-dir",
                str(batch_dir),
            ],
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
        assert batch.returncode == 0, batch.stderr
        assert json.loads((batch_dir / "debian-demo.json").read_text(encoding="utf-8"))["module"] == "demo"

        stale_digest = invoke(good_path, "0" * 64, root / "stale.json")
        assert stale_digest.returncode != 0
        assert "does not match the published artifact digest" in stale_digest.stderr

        failed = artifact(validation_passed=False)
        failed_path = root / "failed.zip"
        failed_path.write_bytes(failed)
        rejected = invoke(failed_path, sha(failed), root / "failed.json")
        assert rejected.returncode != 0
        assert "does not report a successful validation" in rejected.stderr

        mismatched_result = artifact(result_sha="0" * 64)
        mismatched_result_path = root / "mismatched-result.zip"
        mismatched_result_path.write_bytes(mismatched_result)
        rejected = invoke(mismatched_result_path, sha(mismatched_result), root / "mismatch.json")
        assert rejected.returncode != 0
        assert "does not match aggregate digest" in rejected.stderr

        wrong_module = invoke(good_path, sha(good), root / "wrong-module.json", module="other")
        assert wrong_module.returncode != 0
        assert "does not contain exactly the requested module target cells" in wrong_module.stderr

        traversal = append_zip_entry(good, "../outside", b"unsafe\n")
        traversal_path = root / "traversal.zip"
        traversal_path.write_bytes(traversal)
        rejected = invoke(traversal_path, sha(traversal), root / "traversal.json")
        assert rejected.returncode != 0
        assert "unsafe path" in rejected.stderr

    print("accepted-evidence artifact verifier tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
