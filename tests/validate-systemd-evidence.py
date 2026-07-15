#!/usr/bin/env python3
"""Validate one complete systemd-VM evidence directory against repository truth."""

from __future__ import annotations

import argparse
import csv
import hashlib
import io
import os
import re
import subprocess
import sys
from pathlib import Path


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
EXECUTION_FIELDS = {
    "schema_version",
    "started_at",
    "execution_id",
    "target_id",
    "display_name",
    "family",
    "module",
    "mode",
    "standalone_image_tag",
    "vm_image_ref",
    "tested_commit",
    "boot_id",
    "virtualization",
    "systemd_state",
    "container_detection",
    "chroot_detection",
    "private_users_detection",
    "test_mode",
    "explicit_activation_requested",
    "finished_at",
    "result",
    "failure_stage",
    "exit_code",
    "acceptance_eligible",
}
MARKER_FIELDS = {
    "schema",
    "ephemeral",
    "single_use",
    "execution_id",
    "target_id",
    "tested_commit",
    "vm_image_ref",
    "boot_id",
    "nonce",
}
REQUIRED_CHECKS = {
    "host_identity",
    "systemd_vm",
    "systemd_post_install",
    "provisioning_marker",
    "source_commit",
    "source_unchanged_after_install",
    "installer_plan",
    "installer_exit",
    "module_packages",
    "service_attribution",
    "critical_system_state",
    "firewall_state",
}
SECURITY_FIELDS = {
    "kernel_release",
    "selinux_mode",
    "ssh_config_sha256",
    "ssh_listeners_sha256",
    "firewall_zones_sha256",
    "nft_rules_sha256",
    "iptables_rules_sha256",
}
EXPECTED_FILES = {
    "execution.tsv",
    "checks.tsv",
    "os-release.txt",
    "provision-marker.tsv",
    "failed-units-before.txt",
    "failed-units-after.txt",
    "plan-row.tsv",
    "module-contract.tsv",
    "security-before.tsv",
    "critical-packages-before.tsv",
    "protected-packages-before.tsv",
    "module-packages-before.tsv",
    "services-before.tsv",
    "ssh-units-before.tsv",
    "installer-plan.txt",
    "installer.log",
    "installer-trace.log",
    "security-after.tsv",
    "critical-packages-after.tsv",
    "protected-packages-after.tsv",
    "module-packages-after.tsv",
    "services-after.tsv",
    "ssh-units-after.tsv",
    "service-attribution.tsv",
    "files.sha256",
}
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
COMMIT_RE = re.compile(r"^(?:[0-9a-f]{40}|[0-9a-f]{64})$")
IMAGE_RE = re.compile(r"^[^\s@]+@sha256:[0-9a-f]{64}$")
BOOT_RE = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
)
NONCE_RE = re.compile(r"^[0-9a-f]{32,64}$")
TIME_RE = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$")


class ValidationError(Exception):
    """Evidence is incomplete, inconsistent, or ineligible."""


def read_tsv(path: Path, header: list[str], label: str) -> list[dict[str, str]]:
    try:
        with path.open("r", encoding="utf-8", newline="") as stream:
            reader = csv.DictReader(stream, delimiter="\t", quoting=csv.QUOTE_NONE)
            if reader.fieldnames != header:
                raise ValidationError(f"{label} has an unexpected header")
            rows = list(reader)
    except (OSError, UnicodeDecodeError, csv.Error) as error:
        raise ValidationError(f"cannot read {label}: {error}") from None
    if any(None in row or any(value is None for value in row.values()) for row in rows):
        raise ValidationError(f"{label} contains a malformed row")
    return rows


def unique_map(
    rows: list[dict[str, str]], key: str, label: str
) -> dict[str, dict[str, str]]:
    result: dict[str, dict[str, str]] = {}
    for row in rows:
        value = row[key]
        if not value or value in result:
            raise ValidationError(f"{label} has an empty or repeated {key}")
        result[value] = row
    return result


def read_fields(path: Path, label: str) -> dict[str, str]:
    rows = read_tsv(path, ["field", "value"], label)
    return {key: row["value"] for key, row in unique_map(rows, "field", label).items()}


def run_checked(command: list[str], root: Path, label: str) -> str:
    try:
        completed = subprocess.run(
            command,
            cwd=root,
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=120,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        raise ValidationError(f"cannot derive {label}: {error}") from None
    if completed.returncode != 0:
        raise ValidationError(
            f"cannot derive {label}: {completed.stderr.strip() or 'unknown error'}"
        )
    return completed.stdout


def trusted_plan(root: Path) -> dict[str, dict[str, str]]:
    output = run_checked(
        ["bash", str(root / "tests" / "systemd-evidence-matrix.sh"), str(root), "plan"],
        root,
        "trusted systemd evidence plan",
    )
    reader = csv.DictReader(io.StringIO(output), delimiter="\t", quoting=csv.QUOTE_NONE)
    if reader.fieldnames != PLAN_HEADER:
        raise ValidationError("trusted systemd evidence plan has a bad header")
    return unique_map(list(reader), "execution_id", "trusted systemd evidence plan")


def validate_tree(evidence: Path) -> None:
    if not evidence.is_absolute() or evidence.resolve() != evidence:
        raise ValidationError("evidence directory must be an absolute canonical path")
    if not evidence.is_dir() or evidence.is_symlink():
        raise ValidationError("evidence path is not a real directory")
    found: set[str] = set()
    for path in evidence.iterdir():
        if path.is_symlink() or not path.is_file() or os.stat(path).st_nlink != 1:
            raise ValidationError(f"unsafe evidence entry: {path.name}")
        found.add(path.name)
    if found != EXPECTED_FILES:
        missing = sorted(EXPECTED_FILES - found)
        extra = sorted(found - EXPECTED_FILES)
        raise ValidationError(f"evidence file set mismatch; missing={missing}, extra={extra}")


def validate_manifest(evidence: Path) -> None:
    entries: dict[str, str] = {}
    try:
        lines = (evidence / "files.sha256").read_text(encoding="ascii").splitlines()
    except (OSError, UnicodeDecodeError) as error:
        raise ValidationError(f"cannot read evidence manifest: {error}") from None
    for line in lines:
        parts = line.split("  ", 1)
        if (
            len(parts) != 2
            or not SHA256_RE.fullmatch(parts[0])
            or not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", parts[1])
            or parts[1] in entries
        ):
            raise ValidationError("evidence manifest contains a malformed row")
        entries[parts[1]] = parts[0]
    expected_names = EXPECTED_FILES - {"files.sha256"}
    if set(entries) != expected_names or list(entries) != sorted(entries):
        raise ValidationError("evidence manifest file set or order is mismatched")
    for name, expected in entries.items():
        actual = hashlib.sha256((evidence / name).read_bytes()).hexdigest()
        if actual != expected:
            raise ValidationError(f"evidence manifest digest mismatch: {name}")


def parse_os_release(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    try:
        for raw in path.read_text(encoding="utf-8").splitlines():
            if not raw or raw.startswith("#") or "=" not in raw:
                continue
            key, value = raw.split("=", 1)
            if value[:1] == value[-1:] and value[:1] in {'"', "'"}:
                value = value[1:-1]
            values[key] = value
    except (OSError, UnicodeDecodeError) as error:
        raise ValidationError(f"cannot read captured os-release: {error}") from None
    return values


def phase_rows(path: Path, phase: str, label: str) -> list[tuple[str, str]]:
    rows = read_tsv(path, ["phase", "package", "version"], label)
    result: list[tuple[str, str]] = []
    for row in rows:
        if row["phase"] != phase or not row["package"] or not row["version"]:
            raise ValidationError(f"{label} contains an invalid row")
        result.append((row["package"], row["version"]))
    return result


def validate_complete(
    root: Path,
    evidence: Path,
    require_real: bool,
    pinned_commit: str | None,
    pinned_image: str | None,
) -> None:
    validate_tree(evidence)
    validate_manifest(evidence)
    plan = trusted_plan(root)

    execution = read_fields(evidence / "execution.tsv", "execution identity")
    if set(execution) != EXECUTION_FIELDS:
        raise ValidationError("execution identity field set is mismatched")
    execution_id = execution["execution_id"]
    if execution_id not in plan:
        raise ValidationError("execution is absent from the trusted plan")
    expected = plan[execution_id]
    expected_pairs = {
        "target_id": expected["target_id"],
        "display_name": expected["display_name"],
        "family": expected["family"],
        "module": expected["module"],
        "mode": expected["mode"],
        "standalone_image_tag": expected["standalone_image_tag"],
        "explicit_activation_requested": str(expected["mode"] == "enable-services").lower(),
    }
    for field, value in expected_pairs.items():
        if execution[field] != value:
            raise ValidationError(f"execution identity mismatches trusted {field}")
    if execution["schema_version"] != "1":
        raise ValidationError("execution schema is unsupported")
    if not TIME_RE.fullmatch(execution["started_at"]) or not TIME_RE.fullmatch(
        execution["finished_at"]
    ):
        raise ValidationError("execution timestamps are malformed")
    if not COMMIT_RE.fullmatch(execution["tested_commit"]):
        raise ValidationError("tested commit is malformed")
    if not IMAGE_RE.fullmatch(execution["vm_image_ref"]):
        raise ValidationError("immutable VM image reference is malformed")
    if not BOOT_RE.fullmatch(execution["boot_id"]):
        raise ValidationError("VM boot ID is malformed")
    if execution["systemd_state"] != "running":
        raise ValidationError("captured systemd state is not operational")
    if not execution["virtualization"] or execution["virtualization"] == "none":
        raise ValidationError("captured virtualization identity is invalid")
    if (
        execution["container_detection"] != "none"
        or execution["chroot_detection"] != "false"
        or execution["private_users_detection"] != "false"
    ):
        raise ValidationError("container/chroot/private-user-namespace refusal is unproved")
    if pinned_commit is not None and execution["tested_commit"] != pinned_commit:
        raise ValidationError("tested commit does not match the caller's trust anchor")
    if pinned_image is not None and execution["vm_image_ref"] != pinned_image:
        raise ValidationError("VM image does not match the caller's trust anchor")

    test_mode = execution["test_mode"]
    if test_mode == "0":
        terminal = ("provisional", "false")
    elif test_mode == "1":
        terminal = ("test-only", "false")
    else:
        raise ValidationError("test_mode must be 0 or 1")
    if (
        execution["result"],
        execution["acceptance_eligible"],
    ) != terminal or execution["failure_stage"] != "-" or execution["exit_code"] != "0":
        raise ValidationError("execution terminal state is inconsistent")
    if require_real and test_mode != "0":
        raise ValidationError("mocked/test-mode evidence is not a real VM observation")

    plan_rows = read_tsv(evidence / "plan-row.tsv", PLAN_HEADER, "captured plan row")
    if len(plan_rows) != 1 or plan_rows[0] != expected:
        raise ValidationError("captured plan row mismatches repository truth")

    marker = read_fields(evidence / "provision-marker.tsv", "provisioning marker")
    if set(marker) != MARKER_FIELDS:
        raise ValidationError("provisioning marker field set is mismatched")
    marker_expected = {
        "schema": "linux-software-installer/systemd-evidence-vm/v1",
        "ephemeral": "true",
        "single_use": "true",
        "execution_id": execution_id,
        "target_id": expected["target_id"],
        "tested_commit": execution["tested_commit"],
        "vm_image_ref": execution["vm_image_ref"],
        "boot_id": execution["boot_id"],
    }
    for field, value in marker_expected.items():
        if marker[field] != value:
            raise ValidationError(f"provisioning marker mismatches {field}")
    if not NONCE_RE.fullmatch(marker["nonce"]):
        raise ValidationError("provisioning marker nonce is malformed")

    os_release = parse_os_release(evidence / "os-release.txt")
    observed_version = os_release.get("VERSION_ID", "")
    expected_version_id = expected["expected_version_id"]
    if (
        os_release.get("ID", "").lower() != expected["expected_os_id"]
        or observed_version != expected_version_id
    ):
        raise ValidationError("captured OS identity mismatches the exact target")

    contract = run_checked(
        [
            "bash",
            str(root / "tests" / "evidence-contract.sh"),
            str(root),
            expected["module"],
            expected["family"],
            expected["expected_os_id"],
            expected["expected_version_id"],
            expected["expected_arch"],
        ],
        root,
        "trusted module contract",
    )
    try:
        captured_contract = (evidence / "module-contract.tsv").read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as error:
        raise ValidationError(f"cannot read captured module contract: {error}") from None
    if captured_contract != contract:
        raise ValidationError("captured module contract mismatches repository truth")
    contract_rows = read_tsv(
        evidence / "module-contract.tsv", ["type", "value"], "module contract"
    )
    packages = [row["value"] for row in contract_rows if row["type"] == "package"]
    services = [row["value"] for row in contract_rows if row["type"] == "service"]
    if not packages or not services or len(packages) != len(set(packages)) or len(services) != len(set(services)):
        raise ValidationError("module contract package/service set is invalid")
    if ",".join(services) != expected["services"]:
        raise ValidationError("module contract services mismatch the trusted plan")

    checks = unique_map(
        read_tsv(evidence / "checks.tsv", ["check", "status", "detail"], "checks"),
        "check",
        "checks",
    )
    if set(checks) != REQUIRED_CHECKS or any(row["status"] != "passed" for row in checks.values()):
        raise ValidationError("required checks are missing or not passed")
    if checks["host_identity"]["detail"] != (
        f"{expected['expected_os_id']}/{observed_version}/{expected['expected_arch']}"
    ):
        raise ValidationError("host identity check detail is mismatched")
    if checks["systemd_vm"]["detail"] != (
        f"{execution['systemd_state']}/{execution['virtualization']}"
    ):
        raise ValidationError("systemd VM check detail is mismatched")
    if checks["systemd_post_install"]["detail"] != "running":
        raise ValidationError("post-install systemd health check is mismatched")
    if checks["source_commit"]["detail"] != execution["tested_commit"] or checks[
        "source_unchanged_after_install"
    ]["detail"] != execution["tested_commit"]:
        raise ValidationError("source identity checks are mismatched")
    expected_check_details = {
        "provisioning_marker": f"single-use/{marker['nonce']}",
        "installer_plan": expected["mode"],
        "installer_exit": "0",
        "module_packages": "installed",
        "service_attribution": expected["mode"],
        "critical_system_state": "unchanged",
        "firewall_state": (
            "captured-for-firewall-module"
            if expected["module"] == "firewalld"
            else "unchanged"
        ),
    }
    for check, detail in expected_check_details.items():
        if checks[check]["detail"] != detail:
            raise ValidationError(f"check detail is mismatched: {check}")
    for name in ("failed-units-before.txt", "failed-units-after.txt"):
        if (evidence / name).read_bytes() != b"":
            raise ValidationError(f"systemd failed-unit capture is not empty: {name}")

    package_tables: dict[str, dict[str, dict[str, str]]] = {}
    for phase in ("before", "after"):
        rows = read_tsv(
            evidence / f"module-packages-{phase}.tsv",
            ["package", "status", "version"],
            f"module packages {phase}",
        )
        mapped = unique_map(rows, "package", f"module packages {phase}")
        if set(mapped) != set(packages):
            raise ValidationError(f"module package set is mismatched {phase}")
        for package, row in mapped.items():
            if row["status"] not in {"installed", "absent"}:
                raise ValidationError(f"module package status is invalid: {package}")
            if (row["status"] == "absent") != (row["version"] == "-"):
                raise ValidationError(f"module package version is inconsistent: {package}")
            if phase == "after" and row["status"] != "installed":
                raise ValidationError(f"module package is not installed: {package}")
        package_tables[phase] = mapped

    service_tables: dict[str, dict[str, dict[str, str]]] = {}
    for phase in ("before", "after"):
        rows = read_tsv(
            evidence / f"services-{phase}.tsv",
            ["service", "enabled_state", "enabled_exit", "active_state", "active_exit"],
            f"services {phase}",
        )
        mapped = unique_map(rows, "service", f"services {phase}")
        if set(mapped) != set(services):
            raise ValidationError(f"service set is mismatched {phase}")
        for row in mapped.values():
            if not row["enabled_exit"].isdigit() or not row["active_exit"].isdigit():
                raise ValidationError(f"service exit status is malformed {phase}")
        service_tables[phase] = mapped

    attribution = unique_map(
        read_tsv(
            evidence / "service-attribution.tsv",
            [
                "service",
                "explicit_activation_requested",
                "enabled_changed",
                "active_changed",
                "attribution",
            ],
            "service attribution",
        ),
        "service",
        "service attribution",
    )
    if set(attribution) != set(services):
        raise ValidationError("service attribution set is mismatched")
    installer_trace = (evidence / "installer-trace.log").read_text(
        encoding="utf-8", errors="strict"
    )
    installer_plan = (evidence / "installer-plan.txt").read_text(encoding="utf-8", errors="strict")
    for service in services:
        before = service_tables["before"][service]
        after = service_tables["after"][service]
        enabled_changed = str(before["enabled_state"] != after["enabled_state"]).lower()
        active_changed = str(before["active_state"] != after["active_state"]).lower()
        row = attribution[service]
        if row["enabled_changed"] != enabled_changed or row["active_changed"] != active_changed:
            raise ValidationError(f"service state attribution is inconsistent: {service}")
        if expected["mode"] == "enable-services":
            if (
                row["explicit_activation_requested"] != "true"
                or row["attribution"] != "installer-explicit-activation-requested"
                or after["enabled_exit"] != "0"
                or after["active_exit"] != "0"
                or after["enabled_state"] != "enabled"
                or after["active_state"] != "active"
                or not re.search(
                    rf": systemctl enable --now {re.escape(service)}$",
                    installer_trace,
                    re.MULTILINE,
                )
            ):
                raise ValidationError(f"explicit service activation is unproved: {service}")
        else:
            expected_attribution = (
                "package-maintainer-or-system-policy"
                if enabled_changed == "true" or active_changed == "true"
                else "no-state-change"
            )
            if (
                row["explicit_activation_requested"] != "false"
                or row["attribution"] != expected_attribution
                or re.search(
                    r": (?:/usr/bin/|/bin/)?(?:systemctl|service) "
                    r"(?:enable|disable|start|stop|restart|try-restart|reload|mask|unmask)(?: |$)",
                    installer_trace,
                    re.MULTILINE,
                )
            ):
                raise ValidationError(f"default-mode service attribution is inconsistent: {service}")
    activation_text = "; enable: " + ", ".join(services)
    if (expected["mode"] == "enable-services") != (activation_text in installer_plan):
        raise ValidationError("installer plan service activation intent is inconsistent")
    if expected["mode"] == "default" and "; enable:" in installer_plan:
        raise ValidationError("default installer plan contains service activation")

    ssh_units: dict[str, list[dict[str, str]]] = {}
    for phase in ("before", "after"):
        rows = read_tsv(
            evidence / f"ssh-units-{phase}.tsv",
            ["unit", "enabled_state", "enabled_exit", "active_state", "active_exit"],
            f"SSH units {phase}",
        )
        mapped = unique_map(rows, "unit", f"SSH units {phase}")
        if set(mapped) != {"ssh.service", "ssh.socket", "sshd.service", "sshd.socket"}:
            raise ValidationError(f"SSH unit set is mismatched {phase}")
        ssh_units[phase] = rows
    if ssh_units["before"] != ssh_units["after"]:
        raise ValidationError("SSH unit enabled/active state changed")

    security: dict[str, dict[str, dict[str, str]]] = {}
    for phase in ("before", "after"):
        mapped = unique_map(
            read_tsv(
                evidence / f"security-{phase}.tsv",
                ["field", "value", "exit_code"],
                f"security {phase}",
            ),
            "field",
            f"security {phase}",
        )
        if set(mapped) != SECURITY_FIELDS or any(
            not row["exit_code"].isdigit() or not row["value"]
            for row in mapped.values()
        ):
            raise ValidationError(f"security snapshot is malformed {phase}")
        for field in (
            "ssh_listeners_sha256",
            "firewall_zones_sha256",
            "nft_rules_sha256",
            "iptables_rules_sha256",
        ):
            row = mapped[field]
            if row["value"] == "unavailable":
                if row["exit_code"] != "127":
                    raise ValidationError(f"unavailable probe status is inconsistent: {field}")
            elif not SHA256_RE.fullmatch(row["value"]):
                raise ValidationError(f"probe digest is malformed: {field}")
        ssh_config = mapped["ssh_config_sha256"]
        if ssh_config["exit_code"] != "0" or not (
            ssh_config["value"] == "absent"
            or SHA256_RE.fullmatch(ssh_config["value"])
        ):
            raise ValidationError("SSH configuration digest is malformed")
        if mapped["kernel_release"]["exit_code"] != "0":
            raise ValidationError("kernel release capture failed")
        if expected["family"] == "rhel" and mapped["selinux_mode"]["exit_code"] != "0":
            raise ValidationError("RHEL SELinux enforcement probe failed")
        security[phase] = mapped
    invariant_fields = {
        "kernel_release",
        "selinux_mode",
        "ssh_config_sha256",
        "ssh_listeners_sha256",
    }
    if expected["module"] != "firewalld":
        invariant_fields |= {
            "firewall_zones_sha256",
            "nft_rules_sha256",
            "iptables_rules_sha256",
        }
    for field in invariant_fields:
        if security["before"][field] != security["after"][field]:
            raise ValidationError(f"protected security state changed: {field}")

    phase_rows(
        evidence / "critical-packages-before.tsv", "before", "critical packages before"
    )
    phase_rows(
        evidence / "critical-packages-after.tsv", "after", "critical packages after"
    )
    protected_before = phase_rows(
        evidence / "protected-packages-before.tsv", "before", "protected packages before"
    )
    protected_after = phase_rows(
        evidence / "protected-packages-after.tsv", "after", "protected packages after"
    )
    if protected_before != protected_after:
        raise ValidationError("kernel/OpenSSL/OpenSSH package state changed")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    parser.add_argument("--require-real", action="store_true")
    parser.add_argument("--require-accepted", action="store_true")
    parser.add_argument("--tested-commit")
    parser.add_argument("--vm-image-ref")
    args = parser.parse_args()
    if args.tested_commit is not None and not COMMIT_RE.fullmatch(args.tested_commit):
        parser.error("--tested-commit must be a full lowercase hexadecimal object ID")
    if args.vm_image_ref is not None and not IMAGE_RE.fullmatch(args.vm_image_ref):
        parser.error("--vm-image-ref must be an immutable sha256 reference")
    try:
        if args.require_accepted:
            raise ValidationError(
                "local bundles are provisional: no external provisioning attestation "
                "verifier or durable trust anchor is implemented"
            )
        validate_complete(
            args.root.resolve(),
            args.evidence,
            args.require_real,
            args.tested_commit,
            args.vm_image_ref,
        )
    except (ValidationError, OSError, UnicodeDecodeError) as error:
        print(f"systemd evidence validation failed: {error}", file=sys.stderr)
        return 1
    print(f"Provisional systemd evidence structurally validated: {args.evidence.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
