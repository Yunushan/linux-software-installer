#!/usr/bin/env python3
"""Adversarial tests for accepted-evidence admission records."""

from __future__ import annotations

import importlib.util
import json
import shutil
import subprocess
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
        root / "docs" / "evidence-verification" / "debian-nginx.json",
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
        "verification_report": "docs/evidence-verification/debian-nginx.json",
    }


def write_registry(root: Path, rows: list[dict[str, str]]) -> None:
    lines = ["\t".join(READINESS.ADMISSION_HEADER)]
    lines.extend("\t".join(row[field] for field in READINESS.ADMISSION_HEADER) for row in rows)
    write(root / "docs" / "accepted-evidence.tsv", "\n".join(lines) + "\n")


def git(root: Path, *args: str) -> str:
    completed = subprocess.run(
        ["git", *args],
        cwd=root,
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    return completed.stdout.strip()


def commit(root: Path, message: str) -> str:
    git(root, "add", ".")
    git(root, "commit", "-m", message)
    return git(root, "rev-parse", "HEAD")


def set_report_commit(root: Path, commit_sha: str) -> None:
    path = root / "docs" / "evidence-verification" / "debian-nginx.json"
    report = json.loads(path.read_text(encoding="utf-8"))
    report["commit_sha"] = commit_sha
    write(path, json.dumps(report, indent=2, sort_keys=True) + "\n")


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

    restricted = record()
    restricted["evidence_key"] = "debian/telegram"
    restricted["target_cells"] = "debian-12"
    restricted["verification_report"] = "docs/evidence-verification/debian-telegram.json"
    write(
        root / "docs" / "evidence-verification" / "debian-telegram.json",
        json.dumps(
            {
                "schema": READINESS.VERIFICATION_SCHEMA,
                "artifact_sha256": SHA,
                "index_sha256": INDEX_SHA,
                "commit_sha": COMMIT,
                "run_url": RUN_URL,
                "expected_cells": 2,
                "module": "telegram",
                "target_cells": ["debian-12"],
                "cell_ids": ["debian-12/telegram"],
                "result": "verified-awaiting-parity-review-and-systemd-attestation",
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
    )
    restricted_expected = {
        "evidence_key": "debian/telegram",
        "target_family": "debian",
        "replacement": "telegram",
        "service_contract": "no",
        "evidence_target_cells": ("debian-12",),
    }
    write_registry(root, [restricted])
    assert READINESS.load_accepted_admissions(
        root, [restricted_expected], commit=COMMIT
    ) == {"debian/telegram": restricted}
    restricted_wrong_targets = dict(restricted)
    restricted_wrong_targets["target_cells"] = "debian-12,ubuntu-24-04"
    write_registry(root, [restricted_wrong_targets])
    try:
        READINESS.load_accepted_admissions(root, [restricted_expected], commit=COMMIT)
    except READINESS.ReadinessError as error:
        assert "supported module contract" in str(error)
    else:
        raise AssertionError("restricted evidence was accepted for an extra target cell")

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

    if shutil.which("git") is None:
        print("accepted-evidence Git-history tests skipped: Git is unavailable")
    else:
        git(root, "init", "-q")
        git(root, "config", "user.email", "tests@example.invalid")
        git(root, "config", "user.name", "Evidence Tests")
        base_commit = commit(root, "tested installer state")
        set_report_commit(root, base_commit)
        docs_only = record()
        docs_only["commit_sha"] = base_commit
        write_registry(root, [docs_only])
        commit(root, "admit documentation evidence")
        assert READINESS.load_accepted_admissions(root, [expected_row()]) == {
            "debian/nginx": docs_only
        }

        write(
            root / "tests" / "validate-legacy-inventory.sh",
            "#!/usr/bin/env bash\n# admission-ledger accounting change\n",
        )
        commit(root, "adjust admission-ledger accounting")
        assert READINESS.load_accepted_admissions(root, [expected_row()]) == {
            "debian/nginx": docs_only
        }

        write(
            root / "docs" / "provider-backlog.tsv",
            "legacy_id\tnormalized_capability\tstrategy\trecommended_action\treplacement_outcome\trationale\n",
        )
        write(
            root / "tests" / "validate-provider-backlog.sh",
            "#!/usr/bin/env bash\n# provider-backlog accounting change\n",
        )
        commit(root, "adjust provider backlog accounting")
        assert READINESS.load_accepted_admissions(root, [expected_row()]) == {
            "debian/nginx": docs_only
        }

        write(root / "lib" / "installer.sh", "# untested runtime change\n")
        commit(root, "untested runtime change")
        try:
            READINESS.load_accepted_admissions(root, [expected_row()])
        except READINESS.ReadinessError as error:
            assert "intervening changes are not admission-only" in str(error)
            assert "lib/installer.sh" in str(error)
        else:
            raise AssertionError("accepted evidence survived an intervening runtime change")

    print("accepted-evidence admission tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
