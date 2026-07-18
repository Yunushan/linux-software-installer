#!/usr/bin/env python3
"""Finalize and validate standalone module-install evidence using the stdlib."""

from __future__ import annotations

import argparse
import csv
import errno
import hashlib
import json
import os
import re
import shutil
import stat
import subprocess
import sys
import unicodedata
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path, PurePosixPath
from typing import Any


SCHEMA = "linux-software-installer/module-install-evidence/v1"
INDEX_SCHEMA = "linux-software-installer/module-install-evidence-index/v1"
GENERATED_FILES = {"files.sha256", "result.json", "result.json.sha256"}
SANITIZE_SCHEMA = "linux-software-installer/sanitize-tree-report/v1"
SANITIZE_REPORT_NAME = "sanitize-report.json"
MAX_SANITIZE_FILE_BYTES = 256 * 1024 * 1024
MAX_SANITIZE_FILES = 10_000
MAX_SANITIZE_DIRECTORIES = 10_000
MAX_SANITIZE_PATH_DEPTH = 64
MAX_SANITIZE_TOTAL_BYTES = 1024 * 1024 * 1024
COPY_CHUNK_BYTES = 1024 * 1024
HEX64_PATTERN = re.compile(r"^[0-9a-f]{64}$")
COMMIT_PATTERN = re.compile(r"^(?:[0-9a-f]{40}|[0-9a-f]{64})$")
IMAGE_REF_PATTERN = re.compile(r"^[^\s@]+@sha256:[0-9a-f]{64}$")
IMAGE_ID_PATTERN = re.compile(r"^sha256:[0-9a-f]{64}$")
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
TARGETS_HEADER = [
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
RESOLVED_TARGETS_HEADER = TARGETS_HEADER + ["image_ref"]
SUCCESS_STAGE_ORDER = [
    "detect-and-contract",
    "snapshot-before-install",
    "initial-install",
    "foreign-architecture-check-after-install",
    "binary-check-after-install",
    "snapshot-after-install",
    "package-source-capture",
    "repeat-install",
    "foreign-architecture-check-after-repeat",
    "binary-check-after-repeat",
    "snapshot-after-repeat",
    "repeat-state-compare",
]
FINAL_CHECK_KEYS = {
    "container_exit",
    "runner_complete",
    "runner_identity",
    "raw_identity",
    "metadata_format",
    "table_format",
    "sanitization",
    "manifest_binding",
    "contract_binding",
    "binary_evidence",
    "package_source_evidence",
    "package_snapshot_evidence",
    "foreign_architecture_evidence",
    "payload_complete",
    "target_identity",
    "stage_sequence",
    "initial_install",
    "binary_presence_after_install",
    "package_source_capture",
    "repeat_install",
    "binary_presence_after_repeat",
    "package_snapshot_unchanged",
}
MAX_SEMANTIC_TABLE_BYTES = 16 * 1024 * 1024


@dataclass(frozen=True)
class SourceMetadata:
    """Immutable source identity captured without following links."""

    relative: tuple[str, ...]
    device: int
    inode: int
    size: int
    mtime_ns: int
    ctime_ns: int


class SanitizeRejection(Exception):
    """A deliberately terse error that is safe to include in a report."""

    def __init__(self, code: str, relative: tuple[str, ...] = (), detail: str = "") -> None:
        super().__init__(code)
        self.code = code
        self.relative = relative
        self.detail = detail


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_table(path: Path) -> list[dict[str, str]]:
    if not path.is_file():
        return []
    with path.open("r", encoding="utf-8", newline="") as stream:
        return [
            {
                key: (value or "").rstrip("\r")
                for key, value in row.items()
                if key is not None
            }
            for row in csv.DictReader(stream, delimiter="\t")
        ]


def read_header(path: Path) -> list[str]:
    if not path.is_file():
        return []
    with path.open("r", encoding="utf-8", newline="") as stream:
        line = stream.readline().rstrip("\r\n")
    return line.split("\t") if line else []


def read_json_object(path: Path) -> dict[str, Any] | None:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        return None
    return value if isinstance(value, dict) else None


def read_fields(path: Path) -> dict[str, list[str]]:
    fields: dict[str, list[str]] = {}
    for row in read_table(path):
        key = row.get("field", "")
        if key:
            fields.setdefault(key, []).append(row.get("value", ""))
    return fields


def last_field(fields: dict[str, list[str]], key: str, default: str = "") -> str:
    values = fields.get(key, [])
    return values[-1] if values else default


def require_exact_field(
    fields: dict[str, list[str]],
    key: str,
    expected: str,
    errors: list[str],
    label: str,
) -> None:
    values = fields.get(key, [])
    if len(values) != 1:
        errors.append(f"{label} field {key} must occur exactly once")
    elif values[0] != expected:
        errors.append(f"{label} field {key} is mismatched")


def require_single_nonempty_field(
    fields: dict[str, list[str]], key: str, errors: list[str], label: str
) -> None:
    values = fields.get(key, [])
    if len(values) != 1 or not values[0]:
        errors.append(f"{label} field {key} must occur exactly once and be nonempty")


def version_id_matches(observed: str, expected: str) -> bool:
    return observed == expected


def snapshot(path: Path) -> dict[str, str | None]:
    return {
        "path": path.name,
        "sha256": sha256_file(path) if path.is_file() else None,
    }


def regular_tree_files(
    root: Path, excluded_root_names: set[str] | frozenset[str] = frozenset()
) -> list[Path]:
    """Return regular files without following links or accepting special/hard-linked files."""

    try:
        root_stat = os.lstat(root)
    except OSError as error:
        raise ValueError(f"cannot inspect evidence directory: {root}: {error.strerror}") from None
    if not stat.S_ISDIR(root_stat.st_mode):
        raise ValueError(f"evidence root is not a real directory: {root}")

    files: list[Path] = []
    stack: list[tuple[Path, tuple[str, ...]]] = [(root, ())]
    while stack:
        directory, relative_parent = stack.pop()
        try:
            entries = sorted(os.scandir(directory), key=lambda entry: entry.name, reverse=True)
        except OSError as error:
            raise ValueError(
                f"cannot scan evidence directory: {directory}: {error.strerror}"
            ) from None
        for entry in entries:
            relative = relative_parent + (entry.name,)
            if not component_is_safe(entry.name):
                raise ValueError(f"evidence payload contains an unsafe path: {relative_label(relative)}")
            try:
                observed = entry.stat(follow_symlinks=False)
            except OSError as error:
                raise ValueError(
                    f"cannot inspect evidence payload: {relative_label(relative)}: {error.strerror}"
                ) from None
            path = Path(entry.path)
            if stat.S_ISDIR(observed.st_mode):
                stack.append((path, relative))
            elif stat.S_ISREG(observed.st_mode):
                if observed.st_nlink != 1:
                    raise ValueError(
                        f"evidence payload contains a multiply linked file: {relative_label(relative)}"
                    )
                if len(relative) == 1 and entry.name in excluded_root_names:
                    continue
                files.append(path)
            else:
                raise ValueError(
                    "evidence payload contains an unsupported file type: "
                    f"{relative_label(relative)} ({file_type_label(observed.st_mode)})"
                )
    return sorted(files, key=lambda item: item.relative_to(root).as_posix())


def validate_sanitize_report(cell_dir: Path, require_posix_modes: bool = True) -> list[str]:
    errors: list[str] = []
    report_path = cell_dir / SANITIZE_REPORT_NAME
    report = read_json_object(report_path)
    if report is None:
        return ["missing or invalid sanitizer report"]
    if report.get("schema") != SANITIZE_SCHEMA:
        errors.append("unsupported sanitizer report schema")
    if report.get("result") != "passed":
        errors.append("sanitizer did not pass")
    if report.get("errors") != []:
        errors.append("sanitizer report contains errors")
    if report.get("partial_output") is not False:
        errors.append("sanitizer report marks partial output")
    expected_limits = {
        "maximum_file_bytes": MAX_SANITIZE_FILE_BYTES,
        "maximum_files": MAX_SANITIZE_FILES,
        "maximum_directories": MAX_SANITIZE_DIRECTORIES,
        "maximum_path_depth": MAX_SANITIZE_PATH_DEPTH,
        "maximum_total_bytes": MAX_SANITIZE_TOTAL_BYTES,
    }
    if report.get("limits") != expected_limits:
        errors.append("sanitizer limit contract is mismatched")
    observed = report.get("observed") if isinstance(report.get("observed"), dict) else {}
    counter_names = {
        "expected_files",
        "expected_bytes",
        "expected_directories",
        "copied_files",
        "copied_bytes",
        "created_directories",
    }
    if set(observed) != counter_names or any(
        type(observed.get(name)) is not int or observed.get(name, -1) < 0
        for name in counter_names
    ):
        errors.append("sanitizer counters are invalid")
    if observed.get("expected_files") != observed.get("copied_files"):
        errors.append("sanitizer file count is incomplete")
    if observed.get("expected_bytes") != observed.get("copied_bytes"):
        errors.append("sanitizer byte count is incomplete")
    if (
        isinstance(observed.get("expected_files"), int)
        and observed["expected_files"] > MAX_SANITIZE_FILES
    ) or (
        isinstance(observed.get("expected_bytes"), int)
        and observed["expected_bytes"] > MAX_SANITIZE_TOTAL_BYTES
    ) or (
        isinstance(observed.get("expected_directories"), int)
        and observed["expected_directories"] > MAX_SANITIZE_DIRECTORIES
    ):
        errors.append("sanitizer counters exceed declared limits")
    if (
        type(observed.get("created_directories")) is int
        and type(observed.get("expected_directories")) is int
        and observed["created_directories"] > observed["expected_directories"]
    ):
        errors.append("sanitizer created-directory count is invalid")
    if report.get("normalized_modes") != {"directory": "0755", "file": "0644"}:
        errors.append("sanitizer mode contract is mismatched")
    if require_posix_modes:
        try:
            report_stat = os.lstat(report_path)
            root_stat = os.lstat(cell_dir)
            if (
                not stat.S_ISREG(report_stat.st_mode)
                or report_stat.st_nlink != 1
                or stat.S_IMODE(report_stat.st_mode) != 0o644
                or not stat.S_ISDIR(root_stat.st_mode)
                or stat.S_IMODE(root_stat.st_mode) != 0o755
            ):
                errors.append("sanitizer output modes are not normalized")
        except OSError:
            errors.append("cannot inspect sanitizer output modes")
    return errors


def relative_label(parts: tuple[str, ...]) -> str:
    return PurePosixPath(*parts).as_posix() if parts else "."


def file_type_label(mode: int) -> str:
    if stat.S_ISLNK(mode):
        return "symlink"
    if stat.S_ISFIFO(mode):
        return "fifo"
    if stat.S_ISSOCK(mode):
        return "socket"
    if stat.S_ISBLK(mode):
        return "block-device"
    if stat.S_ISCHR(mode):
        return "character-device"
    if stat.S_ISDIR(mode):
        return "directory"
    if stat.S_ISREG(mode):
        return "regular-file"
    return "unknown"


def component_is_safe(name: str) -> bool:
    if not name or name in {".", ".."} or "/" in name or "\\" in name:
        return False
    return all(unicodedata.category(character) not in {"Cc", "Cf", "Cs"} for character in name)


def directory_open_flags() -> int:
    return (
        os.O_RDONLY
        | os.O_DIRECTORY
        | os.O_NOFOLLOW
        | getattr(os, "O_CLOEXEC", 0)
    )


def source_file_open_flags() -> int:
    return os.O_RDONLY | os.O_NOFOLLOW | getattr(os, "O_CLOEXEC", 0)


def require_secure_walk_support() -> None:
    required_constants = ("O_DIRECTORY", "O_NOFOLLOW")
    if any(not hasattr(os, name) for name in required_constants):
        raise SanitizeRejection("secure-walk-unsupported")
    if os.open not in os.supports_dir_fd or os.scandir not in os.supports_fd:
        raise SanitizeRejection("secure-walk-unsupported")


def same_identity(left: os.stat_result, right: os.stat_result) -> bool:
    return left.st_dev == right.st_dev and left.st_ino == right.st_ino


def inspect_source_tree(
    source: Path,
) -> tuple[int, dict[tuple[str, ...], tuple[int, int]], list[SourceMetadata], list[tuple[str, ...]], int]:
    """Inspect source through directory descriptors without following any link."""

    require_secure_walk_support()
    try:
        root_lstat = os.lstat(source)
    except OSError as error:
        raise SanitizeRejection("source-lstat-failed", detail=errno.errorcode.get(error.errno, "OSERROR")) from None
    if not stat.S_ISDIR(root_lstat.st_mode):
        raise SanitizeRejection("unsupported-source-root", detail=file_type_label(root_lstat.st_mode))

    try:
        root_fd = os.open(source, directory_open_flags())
    except OSError as error:
        raise SanitizeRejection("source-open-failed", detail=errno.errorcode.get(error.errno, "OSERROR")) from None
    root_opened = os.fstat(root_fd)
    if not stat.S_ISDIR(root_opened.st_mode) or not same_identity(root_lstat, root_opened):
        os.close(root_fd)
        raise SanitizeRejection("source-changed")

    directories: dict[tuple[str, ...], tuple[int, int]] = {
        (): (root_opened.st_dev, root_opened.st_ino)
    }
    directory_order: list[tuple[str, ...]] = []
    files: list[SourceMetadata] = []
    total_bytes = 0

    def inspect_directory(directory_fd: int, relative: tuple[str, ...]) -> None:
        nonlocal total_bytes
        try:
            with os.scandir(directory_fd) as iterator:
                entries = []
                for entry in iterator:
                    if len(entries) >= MAX_SANITIZE_FILES + MAX_SANITIZE_DIRECTORIES:
                        raise SanitizeRejection("directory-entry-limit", relative)
                    entries.append(entry)
                entries.sort(key=lambda item: item.name)
        except SanitizeRejection:
            raise
        except OSError as error:
            raise SanitizeRejection(
                "directory-scan-failed",
                relative,
                errno.errorcode.get(error.errno, "OSERROR"),
            ) from None

        for entry in entries:
            child_relative = relative + (entry.name,)
            if not component_is_safe(entry.name):
                raise SanitizeRejection("unsafe-path-component", child_relative)
            if child_relative == (SANITIZE_REPORT_NAME,):
                raise SanitizeRejection("reserved-report-path", child_relative)
            try:
                observed = entry.stat(follow_symlinks=False)
            except OSError as error:
                raise SanitizeRejection(
                    "source-lstat-failed",
                    child_relative,
                    errno.errorcode.get(error.errno, "OSERROR"),
                ) from None

            if stat.S_ISDIR(observed.st_mode):
                if len(child_relative) > MAX_SANITIZE_PATH_DEPTH:
                    raise SanitizeRejection("path-depth-limit", child_relative)
                if len(directory_order) >= MAX_SANITIZE_DIRECTORIES:
                    raise SanitizeRejection("directory-count-limit", child_relative)
                try:
                    child_fd = os.open(entry.name, directory_open_flags(), dir_fd=directory_fd)
                except OSError as error:
                    raise SanitizeRejection(
                        "source-directory-open-failed",
                        child_relative,
                        errno.errorcode.get(error.errno, "OSERROR"),
                    ) from None
                try:
                    opened = os.fstat(child_fd)
                    if not stat.S_ISDIR(opened.st_mode) or not same_identity(observed, opened):
                        raise SanitizeRejection("source-changed", child_relative)
                    directories[child_relative] = (opened.st_dev, opened.st_ino)
                    directory_order.append(child_relative)
                    inspect_directory(child_fd, child_relative)
                finally:
                    os.close(child_fd)
                continue

            if not stat.S_ISREG(observed.st_mode):
                raise SanitizeRejection(
                    "unsupported-file-type",
                    child_relative,
                    file_type_label(observed.st_mode),
                )
            if observed.st_nlink != 1:
                raise SanitizeRejection("multiple-hard-links", child_relative)
            if observed.st_size > MAX_SANITIZE_FILE_BYTES:
                raise SanitizeRejection("file-size-limit", child_relative)
            if len(files) >= MAX_SANITIZE_FILES:
                raise SanitizeRejection("file-count-limit", child_relative)
            total_bytes += observed.st_size
            if total_bytes > MAX_SANITIZE_TOTAL_BYTES:
                raise SanitizeRejection("total-size-limit", child_relative)
            files.append(
                SourceMetadata(
                    relative=child_relative,
                    device=observed.st_dev,
                    inode=observed.st_ino,
                    size=observed.st_size,
                    mtime_ns=observed.st_mtime_ns,
                    ctime_ns=observed.st_ctime_ns,
                )
            )

    try:
        inspect_directory(root_fd, ())
    except Exception:
        os.close(root_fd)
        raise
    return root_fd, directories, files, directory_order, total_bytes


def lstat_or_none(path: Path) -> os.stat_result | None:
    try:
        return os.lstat(path)
    except FileNotFoundError:
        return None


def apply_owner_to_fd(file_fd: int, owner_uid: int | None, owner_gid: int | None) -> None:
    if owner_uid is not None or owner_gid is not None:
        os.fchown(
            file_fd,
            owner_uid if owner_uid is not None else -1,
            owner_gid if owner_gid is not None else -1,
        )


def apply_owner_to_path(path: Path, owner_uid: int | None, owner_gid: int | None) -> None:
    if owner_uid is not None or owner_gid is not None:
        os.chown(
            path,
            owner_uid if owner_uid is not None else -1,
            owner_gid if owner_gid is not None else -1,
            follow_symlinks=False,
        )


def prepare_destination(
    destination: Path, owner_uid: int | None, owner_gid: int | None
) -> None:
    observed = lstat_or_none(destination)
    if observed is not None:
        if not stat.S_ISDIR(observed.st_mode):
            raise SanitizeRejection(
                "unsupported-destination-root", detail=file_type_label(observed.st_mode)
            )
        try:
            os.chmod(destination, 0o755, follow_symlinks=False)
            apply_owner_to_path(destination, owner_uid, owner_gid)
        except OSError as error:
            raise SanitizeRejection(
                "destination-normalize-failed",
                detail=errno.errorcode.get(error.errno, "OSERROR"),
            ) from None
        return
    try:
        destination.mkdir(parents=True, mode=0o755)
        os.chmod(destination, 0o755, follow_symlinks=False)
        apply_owner_to_path(destination, owner_uid, owner_gid)
    except OSError as error:
        raise SanitizeRejection(
            "destination-create-failed", detail=errno.errorcode.get(error.errno, "OSERROR")
        ) from None


def preflight_destination(
    destination: Path,
    directories: list[tuple[str, ...]],
    files: list[SourceMetadata],
) -> None:
    for relative in sorted(directories, key=lambda item: (len(item), item)):
        observed = lstat_or_none(destination.joinpath(*relative))
        if observed is not None and not stat.S_ISDIR(observed.st_mode):
            raise SanitizeRejection(
                "destination-directory-collision",
                relative,
                file_type_label(observed.st_mode),
            )
    for source_file in files:
        if lstat_or_none(destination.joinpath(*source_file.relative)) is not None:
            raise SanitizeRejection("destination-file-collision", source_file.relative)


def create_destination_directories(
    destination: Path,
    directories: list[tuple[str, ...]],
    owner_uid: int | None,
    owner_gid: int | None,
) -> int:
    created = 0
    for relative in sorted(directories, key=lambda item: (len(item), item)):
        target = destination.joinpath(*relative)
        observed = lstat_or_none(target)
        if observed is not None:
            if not stat.S_ISDIR(observed.st_mode):
                raise SanitizeRejection("destination-directory-collision", relative)
            try:
                os.chmod(target, 0o755, follow_symlinks=False)
                apply_owner_to_path(target, owner_uid, owner_gid)
            except OSError as error:
                raise SanitizeRejection(
                    "destination-directory-normalize-failed",
                    relative,
                    errno.errorcode.get(error.errno, "OSERROR"),
                ) from None
            continue
        try:
            os.mkdir(target, 0o755)
            os.chmod(target, 0o755, follow_symlinks=False)
            apply_owner_to_path(target, owner_uid, owner_gid)
            created += 1
        except OSError as error:
            raise SanitizeRejection(
                "destination-directory-create-failed",
                relative,
                errno.errorcode.get(error.errno, "OSERROR"),
            ) from None
    return created


def open_inspected_source_file(
    root_fd: int,
    directories: dict[tuple[str, ...], tuple[int, int]],
    source_file: SourceMetadata,
) -> int:
    directory_fd = os.dup(root_fd)
    traversed: tuple[str, ...] = ()
    try:
        for component in source_file.relative[:-1]:
            traversed += (component,)
            next_fd = os.open(component, directory_open_flags(), dir_fd=directory_fd)
            os.close(directory_fd)
            directory_fd = next_fd
            observed = os.fstat(directory_fd)
            expected = directories[traversed]
            if not stat.S_ISDIR(observed.st_mode) or (observed.st_dev, observed.st_ino) != expected:
                raise SanitizeRejection("source-changed", traversed)
        try:
            return os.open(
                source_file.relative[-1],
                source_file_open_flags(),
                dir_fd=directory_fd,
            )
        except OSError as error:
            raise SanitizeRejection(
                "source-file-open-failed",
                source_file.relative,
                errno.errorcode.get(error.errno, "OSERROR"),
            ) from None
    finally:
        os.close(directory_fd)


def metadata_matches(source_file: SourceMetadata, observed: os.stat_result) -> bool:
    return (
        stat.S_ISREG(observed.st_mode)
        and observed.st_nlink == 1
        and observed.st_dev == source_file.device
        and observed.st_ino == source_file.inode
        and observed.st_size == source_file.size
        and observed.st_mtime_ns == source_file.mtime_ns
        and observed.st_ctime_ns == source_file.ctime_ns
    )


def copy_source_file(
    root_fd: int,
    directories: dict[tuple[str, ...], tuple[int, int]],
    source_file: SourceMetadata,
    destination: Path,
    owner_uid: int | None,
    owner_gid: int | None,
) -> int:
    source_fd = open_inspected_source_file(root_fd, directories, source_file)
    target = destination.joinpath(*source_file.relative)
    destination_fd: int | None = None
    created = False
    completed = False
    try:
        if not metadata_matches(source_file, os.fstat(source_fd)):
            raise SanitizeRejection("source-changed", source_file.relative)
        flags = (
            os.O_WRONLY
            | os.O_CREAT
            | os.O_EXCL
            | os.O_NOFOLLOW
            | getattr(os, "O_CLOEXEC", 0)
        )
        try:
            destination_fd = os.open(target, flags, 0o600)
            created = True
        except OSError as error:
            code = "destination-file-collision" if error.errno == errno.EEXIST else "destination-file-create-failed"
            raise SanitizeRejection(
                code,
                source_file.relative,
                errno.errorcode.get(error.errno, "OSERROR") if code.endswith("failed") else "",
            ) from None

        copied = 0
        while True:
            chunk = os.read(source_fd, COPY_CHUNK_BYTES)
            if not chunk:
                break
            copied += len(chunk)
            if copied > source_file.size or copied > MAX_SANITIZE_FILE_BYTES:
                raise SanitizeRejection("source-changed", source_file.relative)
            view = memoryview(chunk)
            while view:
                written = os.write(destination_fd, view)
                if written <= 0:
                    raise SanitizeRejection("destination-write-failed", source_file.relative)
                view = view[written:]

        if copied != source_file.size or not metadata_matches(source_file, os.fstat(source_fd)):
            raise SanitizeRejection("source-changed", source_file.relative)
        apply_owner_to_fd(destination_fd, owner_uid, owner_gid)
        os.fchmod(destination_fd, 0o644)
        os.fsync(destination_fd)
        completed = True
        return copied
    except OSError as error:
        raise SanitizeRejection(
            "copy-failed",
            source_file.relative,
            errno.errorcode.get(error.errno, "OSERROR"),
        ) from None
    except SanitizeRejection:
        raise
    finally:
        os.close(source_fd)
        if destination_fd is not None:
            os.close(destination_fd)
        if created and not completed:
            try:
                if lstat_or_none(target) is not None:
                    os.unlink(target)
            except OSError:
                pass


def write_sanitize_report(
    destination: Path,
    report: dict[str, Any],
    owner_uid: int | None,
    owner_gid: int | None,
) -> str:
    encoded = (json.dumps(report, indent=2, sort_keys=True) + "\n").encode("utf-8")
    target = destination / SANITIZE_REPORT_NAME
    flags = (
        os.O_WRONLY
        | os.O_CREAT
        | os.O_EXCL
        | os.O_NOFOLLOW
        | getattr(os, "O_CLOEXEC", 0)
    )
    report_fd = os.open(target, flags, 0o600)
    try:
        view = memoryview(encoded)
        while view:
            written = os.write(report_fd, view)
            if written <= 0:
                raise OSError(errno.EIO, "short report write")
            view = view[written:]
        apply_owner_to_fd(report_fd, owner_uid, owner_gid)
        os.fchmod(report_fd, 0o644)
        os.fsync(report_fd)
    finally:
        os.close(report_fd)
    return SANITIZE_REPORT_NAME


def paths_overlap(source: Path, destination: Path) -> bool:
    try:
        source_real = os.path.realpath(source)
        destination_real = os.path.realpath(destination)
        common = os.path.commonpath((source_real, destination_real))
    except ValueError:
        return False
    return common in {source_real, destination_real}


def path_has_symlink_component(path: Path) -> bool:
    absolute = path.absolute()
    parts = absolute.parts
    if not parts:
        return False
    current = Path(parts[0])
    for part in parts[1:]:
        current /= part
        try:
            observed = os.lstat(current)
        except FileNotFoundError:
            break
        except OSError:
            return True
        if stat.S_ISLNK(observed.st_mode):
            return True
    return False


def command_sanitize_tree(args: argparse.Namespace) -> int:
    source = Path(args.source).absolute()
    destination = Path(args.destination).absolute()
    owner_uid: int | None = args.owner_uid
    owner_gid: int | None = args.owner_gid
    root_fd: int | None = None
    copied_files = 0
    copied_bytes = 0
    created_directories = 0
    expected_files = 0
    expected_bytes = 0
    expected_directories = 0
    rejection: SanitizeRejection | None = None

    try:
        if path_has_symlink_component(destination):
            raise SanitizeRejection("symlinked-destination-component")
        prepare_destination(destination, owner_uid, owner_gid)
        if lstat_or_none(destination / SANITIZE_REPORT_NAME) is not None:
            raise SanitizeRejection("destination-report-collision")
        if path_has_symlink_component(source):
            raise SanitizeRejection("symlinked-source-component")
        if paths_overlap(source, destination):
            raise SanitizeRejection("source-destination-overlap")
        root_fd, directories, files, directory_order, expected_bytes = inspect_source_tree(source)
        expected_files = len(files)
        expected_directories = len(directory_order)
        preflight_destination(destination, directory_order, files)
        created_directories = create_destination_directories(
            destination, directory_order, owner_uid, owner_gid
        )
        for source_file in files:
            copied_bytes += copy_source_file(
                root_fd,
                directories,
                source_file,
                destination,
                owner_uid,
                owner_gid,
            )
            copied_files += 1
    except SanitizeRejection as error:
        rejection = error
    except OSError as error:
        rejection = SanitizeRejection(
            "sanitizer-os-error", detail=errno.errorcode.get(error.errno, "OSERROR")
        )
    except Exception:
        rejection = SanitizeRejection("sanitizer-internal-error")
    finally:
        if root_fd is not None:
            os.close(root_fd)

    report: dict[str, Any] = {
        "schema": SANITIZE_SCHEMA,
        "result": "rejected" if rejection else "passed",
        "limits": {
            "maximum_file_bytes": MAX_SANITIZE_FILE_BYTES,
            "maximum_files": MAX_SANITIZE_FILES,
            "maximum_directories": MAX_SANITIZE_DIRECTORIES,
            "maximum_path_depth": MAX_SANITIZE_PATH_DEPTH,
            "maximum_total_bytes": MAX_SANITIZE_TOTAL_BYTES,
        },
        "observed": {
            "expected_files": expected_files,
            "expected_bytes": expected_bytes,
            "expected_directories": expected_directories,
            "copied_files": copied_files,
            "copied_bytes": copied_bytes,
            "created_directories": created_directories,
        },
        "normalized_modes": {"directory": "0755", "file": "0644"},
        "partial_output": bool(rejection and (copied_files or created_directories)),
        "errors": [],
    }
    if rejection is not None:
        error_record = {
            "code": rejection.code,
            "path": relative_label(rejection.relative),
        }
        if rejection.detail:
            error_record["detail"] = rejection.detail
        report["errors"].append(error_record)

    try:
        report_name = write_sanitize_report(
            destination, report, owner_uid, owner_gid
        )
    except OSError:
        print("sanitize-tree: could not write a non-overwriting report", file=sys.stderr)
        return 2

    if rejection is not None:
        print(
            f"rejected: {rejection.code} ({relative_label(rejection.relative)}); report={report_name}",
            file=sys.stderr,
        )
        return 1
    print(
        f"passed: copied {copied_files} files ({copied_bytes} bytes); report={report_name}"
    )
    return 0


def payload_files(cell_dir: Path) -> list[Path]:
    return regular_tree_files(cell_dir, GENERATED_FILES)


def write_payload_manifest(cell_dir: Path) -> str:
    manifest = cell_dir / "files.sha256"
    with manifest.open("w", encoding="utf-8", newline="\n") as stream:
        for path in payload_files(cell_dir):
            relative = path.relative_to(cell_dir).as_posix()
            stream.write(f"{sha256_file(path)}  {relative}\n")
    return sha256_file(manifest)


def stage_statuses(stage_rows: list[dict[str, str]]) -> dict[str, str]:
    statuses: dict[str, str] = {}
    for row in stage_rows:
        stage = row.get("stage", "")
        status = row.get("status", "")
        if stage and status != "running":
            statuses[stage] = status
    return statuses


def validate_success_stage_rows(stage_rows: list[dict[str, str]]) -> list[str]:
    errors: list[str] = []
    expected_rows: list[tuple[str, str, str]] = []
    for stage_name in SUCCESS_STAGE_ORDER:
        expected_rows.extend(
            ((stage_name, "running", "-"), (stage_name, "passed", "0"))
        )
    if len(stage_rows) != len(expected_rows):
        return ["successful stage evidence has an unexpected row count"]
    for row, expected in zip(stage_rows, expected_rows, strict=True):
        observed = (row.get("stage", ""), row.get("status", ""), row.get("exit_code", ""))
        if observed != expected or not row.get("timestamp", ""):
            errors.append("successful stage sequence is mismatched")
            break
    return errors


def command_finalize(args: argparse.Namespace) -> int:
    cell_dir = Path(args.cell_dir).resolve()
    repo_root = Path(args.repo_root).resolve()
    cell_dir.mkdir(parents=True, exist_ok=True)
    for generated in GENERATED_FILES:
        (cell_dir / generated).unlink(missing_ok=True)

    table_errors: list[str] = []
    raw_rows, raw_table_errors = read_strict_tsv(
        cell_dir / "raw-execution.tsv", ["field", "value"], "raw execution"
    )
    runner_rows, runner_table_errors = read_strict_tsv(
        cell_dir / "runner.tsv", ["field", "value"], "runner"
    )
    stages, stage_table_errors = read_strict_tsv(
        cell_dir / "stages.tsv",
        ["stage", "status", "timestamp", "exit_code"],
        "stage evidence",
    )
    contract_rows, contract_table_errors = read_strict_tsv(
        cell_dir / "module-contract.tsv", ["type", "value"], "module contract"
    )
    expected_contract_rows, expected_contract_table_errors = read_strict_tsv(
        cell_dir / "expected-module-contract.tsv",
        ["type", "value"],
        "host-derived module contract",
    )
    table_errors.extend(
        raw_table_errors
        + runner_table_errors
        + stage_table_errors
        + contract_table_errors
        + expected_contract_table_errors
    )
    raw: dict[str, list[str]] = {}
    runner: dict[str, list[str]] = {}
    for row in raw_rows:
        raw.setdefault(row["field"], []).append(row["value"])
    for row in runner_rows:
        runner.setdefault(row["field"], []).append(row["value"])
    statuses = stage_statuses(stages)
    stage_errors = validate_success_stage_rows(stages)

    raw_identity_errors: list[str] = []
    for key, expected in (
        ("schema_version", "1"),
        ("tested_commit", args.commit),
        ("workflow_run_url", args.run_url),
        ("target_id", args.target_id),
        ("image_ref", args.image_ref),
        ("image_id", args.image_id),
        ("module", args.module),
        ("result", "success"),
        ("exit_code", "0"),
        ("failure_stage", "-"),
    ):
        require_exact_field(raw, key, expected, raw_identity_errors, "raw execution")
    require_single_nonempty_field(raw, "started_at", raw_identity_errors, "raw execution")
    require_single_nonempty_field(raw, "finished_at", raw_identity_errors, "raw execution")

    runner_identity_errors: list[str] = []
    for key, expected in (
        ("runner_stage", args.runner_stage),
        ("pull_exit_code", "0"),
        ("container_exit_code", str(args.container_exit)),
        ("image_id", args.image_id),
        ("image_architecture", args.image_arch),
    ):
        require_exact_field(runner, key, expected, runner_identity_errors, "runner")
    require_single_nonempty_field(runner, "started_at", runner_identity_errors, "runner")

    metadata_errors: list[str] = []
    if args.commit != "local-uncommitted" and not COMMIT_PATTERN.fullmatch(args.commit):
        metadata_errors.append("tested commit is not a full Git object ID")
    if not IMAGE_REF_PATTERN.fullmatch(args.image_ref):
        metadata_errors.append("image reference is not an immutable sha256 digest")
    if not IMAGE_ID_PATTERN.fullmatch(args.image_id):
        metadata_errors.append("image ID is not a sha256 object ID")
    if args.platform != "linux/amd64" or args.image_arch != "amd64":
        metadata_errors.append("runner image platform or architecture is mismatched")

    manifest_path = cell_dir / "module.sh"
    trusted_manifest = repo_root / "modules" / args.module / "module.sh"
    manifest_errors: list[str] = []
    if not trusted_manifest.is_file() or trusted_manifest.is_symlink():
        manifest_errors.append("trusted module manifest is missing or unsafe")
    if not manifest_path.is_file() or manifest_path.is_symlink():
        manifest_errors.append("captured module manifest is missing or unsafe")
    if not manifest_errors and sha256_file(manifest_path) != sha256_file(trusted_manifest):
        manifest_errors.append("captured module manifest does not match the checked-out commit")

    sanitizer_errors = validate_sanitize_report(
        cell_dir, require_posix_modes=args.commit != "local-uncommitted"
    )

    contracts: dict[str, list[str]] = {
        "package": [],
        "verification_binary": [],
        "service": [],
        "foreign_architecture": [],
    }
    contract_errors: list[str] = []
    trusted_contract_text, trusted_contract_error = derive_trusted_contract(
        repo_root,
        args.module,
        args.family,
        args.expected_os_id,
        args.expected_version_id,
        args.expected_arch,
    )
    if trusted_contract_error:
        contract_errors.append(trusted_contract_error)
    else:
        for contract_path, label in (
            (cell_dir / "module-contract.tsv", "container module contract"),
            (cell_dir / "expected-module-contract.tsv", "host-derived module contract"),
        ):
            try:
                contract_text = contract_path.read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError) as error:
                contract_errors.append(f"cannot read {label}: {error}")
                continue
            if contract_text != trusted_contract_text:
                contract_errors.append(
                    f"{label} disagrees with the exact checked-out target contract"
                )
    for row in contract_rows:
        kind = row.get("type", "")
        value = row.get("value", "")
        if kind in contracts and value:
            contracts[kind].append(value)
        else:
            contract_errors.append("module contract contains an invalid row")
    if contract_rows != expected_contract_rows:
        contract_errors.append("container module contract disagrees with the host-derived contract")
    if not contracts["package"] or not contracts["verification_binary"]:
        contract_errors.append("module contract lacks packages or verification binaries")
    binary_errors = validate_binary_table(
        cell_dir / "binary-paths-after-install.tsv",
        contracts["verification_binary"],
        "post-install binary evidence",
    )
    binary_errors.extend(
        validate_binary_table(
            cell_dir / "binary-paths-after-repeat.tsv",
            contracts["verification_binary"],
            "post-repeat binary evidence",
        )
    )
    package_source_errors = validate_package_sources(
        cell_dir / "package-sources.txt", contracts["package"]
    )

    before = cell_dir / "packages-before-install.tsv"
    after = cell_dir / "packages-after-install.tsv"
    repeat = cell_dir / "packages-after-repeat.tsv"
    package_snapshot_errors = validate_package_snapshot(
        before, [], "pre-install package snapshot"
    )
    package_snapshot_errors.extend(
        validate_package_snapshot(
            after, contracts["package"], "post-install package snapshot"
        )
    )
    package_snapshot_errors.extend(
        validate_package_snapshot(
            repeat, contracts["package"], "post-repeat package snapshot"
        )
    )
    foreign_architecture_errors = validate_foreign_architectures(
        cell_dir / "foreign-architectures-after-install.txt",
        contracts["foreign_architecture"],
        "post-install foreign-architecture evidence",
    )
    foreign_architecture_errors.extend(
        validate_foreign_architectures(
            cell_dir / "foreign-architectures-after-repeat.txt",
            contracts["foreign_architecture"],
            "post-repeat foreign-architecture evidence",
        )
    )
    repeated_state_unchanged = (
        after.is_file()
        and repeat.is_file()
        and sha256_file(after) == sha256_file(repeat)
    )

    required_files = [
        "raw-execution.tsv",
        "stages.tsv",
        "runner.tsv",
        "os-release.txt",
        "module.sh",
        "module-contract.tsv",
        "expected-module-contract.tsv",
        "packages-before-install.tsv",
        "packages-after-install.tsv",
        "packages-after-repeat.tsv",
        "binary-paths-after-install.tsv",
        "binary-paths-after-repeat.tsv",
        "package-sources.txt",
        "foreign-architectures-after-install.txt",
        "foreign-architectures-after-repeat.txt",
        "container.log",
        SANITIZE_REPORT_NAME,
    ]
    missing_files = [name for name in required_files if not (cell_dir / name).is_file()]

    observed = {
        "os_id": last_field(raw, "os_id"),
        "os_version": last_field(raw, "os_version"),
        "architecture": last_field(raw, "architecture"),
        "family": last_field(raw, "family"),
    }
    target_errors: list[str] = []
    if observed["os_id"] != args.expected_os_id:
        target_errors.append(f"expected os_id {args.expected_os_id}, observed {observed['os_id'] or 'missing'}")
    if not version_id_matches(observed["os_version"], args.expected_version_id):
        target_errors.append(
            f"expected version ID {args.expected_version_id}, observed {observed['os_version'] or 'missing'}"
        )
    if observed["architecture"] != args.expected_arch:
        target_errors.append(
            f"expected architecture {args.expected_arch}, observed {observed['architecture'] or 'missing'}"
        )
    if observed["family"] != args.family:
        target_errors.append(f"expected family {args.family}, observed {observed['family'] or 'missing'}")
    if last_field(raw, "module") != args.module:
        target_errors.append("module identity is missing or mismatched")

    validations = {
        "container_exit": args.container_exit == 0,
        "runner_complete": args.runner_stage == "container-complete",
        "runner_identity": not runner_identity_errors,
        "raw_identity": not raw_identity_errors,
        "metadata_format": not metadata_errors,
        "table_format": not table_errors,
        "sanitization": not sanitizer_errors,
        "manifest_binding": not manifest_errors,
        "contract_binding": not contract_errors,
        "binary_evidence": not binary_errors,
        "package_source_evidence": not package_source_errors,
        "package_snapshot_evidence": not package_snapshot_errors,
        "foreign_architecture_evidence": not foreign_architecture_errors,
        "payload_complete": not missing_files,
        "target_identity": not target_errors,
        "stage_sequence": not stage_errors,
        "initial_install": statuses.get("initial-install") == "passed",
        "binary_presence_after_install": statuses.get("binary-check-after-install") == "passed",
        "package_source_capture": statuses.get("package-source-capture") == "passed",
        "repeat_install": statuses.get("repeat-install") == "passed",
        "binary_presence_after_repeat": statuses.get("binary-check-after-repeat") == "passed",
        "package_snapshot_unchanged": repeated_state_unchanged,
    }
    if set(validations) != FINAL_CHECK_KEYS:
        raise RuntimeError("final evidence check contract drifted")
    passed = all(validations.values())

    failure_stage: str | None = None
    if not passed:
        raw_failure = last_field(raw, "failure_stage")
        if raw_failure and raw_failure != "-":
            failure_stage = raw_failure
        elif args.runner_stage != "container-complete":
            failure_stage = args.runner_stage
        else:
            failure_stage = "runner-validation"

    payload_manifest_sha = write_payload_manifest(cell_dir)
    checks = {key: "passed" if value else "failed" for key, value in validations.items()}
    validation_errors = (
        target_errors
        + raw_identity_errors
        + runner_identity_errors
        + metadata_errors
        + table_errors
        + sanitizer_errors
        + manifest_errors
        + contract_errors
        + binary_errors
        + package_source_errors
        + package_snapshot_errors
        + foreign_architecture_errors
        + stage_errors
        + [f"missing payload: {name}" for name in missing_files]
    )
    if not repeated_state_unchanged:
        validation_errors.append("post-install and post-repeat package snapshots differ or are missing")

    result: dict[str, Any] = {
        "schema": SCHEMA,
        "cell_id": f"{args.target_id}/{args.module}",
        "result": "passed" if passed else "failed",
        "failure_stage": failure_stage,
        "source": {
            "repository": args.repository,
            "commit": args.commit,
            "ref": args.ref,
            "run_id": args.run_id,
            "run_attempt": args.run_attempt,
            "run_url": args.run_url,
            "artifact": args.artifact_name,
        },
        "target": {
            "target_id": args.target_id,
            "display_name": args.display_name,
            "family": args.family,
            "image_tag": args.image_tag,
            "image_ref": args.image_ref,
            "image_id": args.image_id or None,
            "platform": args.platform,
            "runner_image_architecture": args.image_arch or None,
            "expected": {
                "os_id": args.expected_os_id,
                "version_id": args.expected_version_id,
                "architecture": args.expected_arch,
            },
            "observed": observed,
        },
        "module": {
            "id": args.module,
            "manifest_path": f"modules/{args.module}/module.sh",
            "manifest_sha256": (
                sha256_file(manifest_path)
                if manifest_path.is_file() and not manifest_path.is_symlink()
                else None
            ),
            "packages": contracts["package"],
            "verification_binaries": contracts["verification_binary"],
            "services": contracts["service"],
            "foreign_architectures": contracts["foreign_architecture"],
            "explicit_service_activation_requested": False,
        },
        "execution": {
            "started_at": last_field(raw, "started_at") or last_field(runner, "started_at"),
            "completed_at": last_field(raw, "finished_at") or utc_now(),
            "container_exit_code": args.container_exit,
            "runner_stage": args.runner_stage,
            "initial_refresh_requested": True,
            "repeat_no_refresh_requested": True,
            "stages": stages,
        },
        "sanitization": {
            "report": SANITIZE_REPORT_NAME,
            "report_sha256": (
                sha256_file(cell_dir / SANITIZE_REPORT_NAME)
                if (cell_dir / SANITIZE_REPORT_NAME).is_file()
                else None
            ),
        },
        "checks": checks,
        "validation_errors": validation_errors,
        "snapshots": {
            "before_install": snapshot(before),
            "after_install": snapshot(after),
            "after_repeat": snapshot(repeat),
        },
        "files_manifest": "files.sha256",
        "files_manifest_sha256": payload_manifest_sha,
    }

    result_path = cell_dir / "result.json"
    result_path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    result_sha = sha256_file(result_path)
    (cell_dir / "result.json.sha256").write_text(
        f"{result_sha}  result.json\n", encoding="utf-8", newline="\n"
    )
    print(f"{result['result']}: {result['cell_id']}")
    return 0 if passed else 1


def parse_checksum_manifest(path: Path) -> tuple[dict[str, str], list[str]]:
    entries: dict[str, str] = {}
    errors: list[str] = []
    if not path.is_file():
        return entries, ["missing files.sha256"]
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if "  " not in line:
            errors.append(f"files.sha256 line {line_number} is malformed")
            continue
        digest, relative = line.split("  ", 1)
        pure = PurePosixPath(relative)
        safe_parts = (
            bool(pure.parts)
            and all(component_is_safe(part) for part in pure.parts)
            and relative == pure.as_posix()
        )
        if not HEX64_PATTERN.fullmatch(digest):
            errors.append(f"files.sha256 line {line_number} has an invalid digest")
        elif (
            pure.is_absolute()
            or not safe_parts
            or (len(pure.parts) == 1 and relative in GENERATED_FILES)
            or relative in entries
        ):
            errors.append(f"files.sha256 line {line_number} has an unsafe or duplicate path")
        else:
            entries[relative] = digest
    return entries, errors


def verify_integrity(result_path: Path, result: dict[str, Any]) -> list[str]:
    cell_dir = result_path.parent
    errors: list[str] = []
    result_sha_path = cell_dir / "result.json.sha256"
    expected_result_sha = ""
    if result_sha_path.is_file() and not result_sha_path.is_symlink():
        try:
            result_sha_lines = result_sha_path.read_text(encoding="utf-8").splitlines()
        except (OSError, UnicodeDecodeError):
            result_sha_lines = []
        match = (
            re.fullmatch(r"([0-9a-f]{64})  result\.json", result_sha_lines[0])
            if len(result_sha_lines) == 1
            else None
        )
        if match:
            expected_result_sha = match.group(1)
        else:
            errors.append("result.json.sha256 is malformed")
    else:
        errors.append("missing result.json.sha256")
    if expected_result_sha != sha256_file(result_path):
        errors.append("result.json checksum mismatch")

    manifest_path = cell_dir / "files.sha256"
    if not manifest_path.is_file() or result.get("files_manifest_sha256") != sha256_file(manifest_path):
        errors.append("files.sha256 checksum mismatch")
    entries, manifest_errors = parse_checksum_manifest(manifest_path)
    errors.extend(manifest_errors)

    try:
        actual_files = {
            path.relative_to(cell_dir).as_posix(): path for path in payload_files(cell_dir)
        }
    except ValueError as error:
        errors.append(str(error))
        actual_files = {}
    if set(entries) != set(actual_files):
        errors.append("payload file set does not match files.sha256")
    for relative, expected_digest in entries.items():
        path = actual_files.get(relative)
        if path is not None and sha256_file(path) != expected_digest:
            errors.append(f"payload checksum mismatch: {relative}")

    sanitization = (
        result.get("sanitization")
        if isinstance(result.get("sanitization"), dict)
        else {}
    )
    sanitize_path = cell_dir / SANITIZE_REPORT_NAME
    if sanitization.get("report") != SANITIZE_REPORT_NAME:
        errors.append("sanitizer report path is mismatched")
    if (
        not sanitize_path.is_file()
        or sanitize_path.is_symlink()
        or sanitization.get("report_sha256") != sha256_file(sanitize_path)
    ):
        errors.append("sanitizer report checksum mismatch")
    errors.extend(validate_sanitize_report(cell_dir))
    return errors


def read_strict_tsv(path: Path, header: list[str], label: str) -> tuple[list[dict[str, str]], list[str]]:
    errors: list[str] = []
    rows: list[dict[str, str]] = []
    try:
        observed = os.lstat(path)
        if not stat.S_ISREG(observed.st_mode) or observed.st_nlink != 1:
            return rows, [f"{label} is not a safe regular file"]
        if observed.st_size > MAX_SEMANTIC_TABLE_BYTES:
            return rows, [f"{label} exceeds the semantic table size limit"]
        with path.open("r", encoding="utf-8", newline="") as stream:
            reader = csv.reader(stream, delimiter="\t", quoting=csv.QUOTE_NONE)
            observed_header = next(reader, [])
            if observed_header != header:
                errors.append(f"{label} has an unexpected header")
                return rows, errors
            for line_number, values in enumerate(reader, 2):
                if len(values) != len(header):
                    errors.append(f"{label} line {line_number} has an unexpected field count")
                    continue
                if any(
                    unicodedata.category(character) in {"Cc", "Cf", "Cs"}
                    for value in values
                    for character in value
                ):
                    errors.append(f"{label} line {line_number} contains control text")
                    continue
                rows.append(dict(zip(header, values, strict=True)))
    except (OSError, UnicodeDecodeError, csv.Error) as error:
        errors.append(f"cannot read {label}: {error}")
    return rows, errors


def strict_fields(path: Path, label: str, errors: list[str]) -> dict[str, list[str]]:
    rows, table_errors = read_strict_tsv(path, ["field", "value"], label)
    errors.extend(table_errors)
    fields: dict[str, list[str]] = {}
    for row in rows:
        key = row["field"]
        if not key:
            errors.append(f"{label} contains an empty field name")
            continue
        fields.setdefault(key, []).append(row["value"])
    return fields


def validate_binary_table(path: Path, expected_binaries: list[str], label: str) -> list[str]:
    rows, errors = read_strict_tsv(path, ["binary", "path"], label)
    if [row["binary"] for row in rows] != expected_binaries:
        errors.append(f"{label} does not cover the trusted binary contract exactly")
    for row in rows:
        binary_path = PurePosixPath(row["path"])
        if not binary_path.is_absolute() or ".." in binary_path.parts:
            errors.append(f"{label} contains an unsafe binary path")
            break
    return errors


def validate_package_sources(path: Path, expected_packages: list[str]) -> list[str]:
    errors: list[str] = []
    try:
        observed = os.lstat(path)
        if not stat.S_ISREG(observed.st_mode) or observed.st_nlink != 1:
            return ["package source evidence is not a safe regular file"]
        if observed.st_size > MAX_SEMANTIC_TABLE_BYTES:
            return ["package source evidence exceeds the semantic size limit"]
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError) as error:
        return [f"cannot read package source evidence: {error}"]

    marker_pattern = re.compile(r"^===== (.+) =====$")
    markers: list[tuple[int, str]] = []
    for index, line in enumerate(lines):
        match = marker_pattern.fullmatch(line)
        if match:
            markers.append((index, match.group(1)))
    if [package for _, package in markers] != expected_packages:
        errors.append("package source sections do not match the trusted package contract")
        return errors
    for marker_index, (line_index, _) in enumerate(markers):
        end = markers[marker_index + 1][0] if marker_index + 1 < len(markers) else len(lines)
        if not any(line.strip() for line in lines[line_index + 1 : end]):
            errors.append("package source evidence contains an empty package section")
            break
    return errors


def validate_package_snapshot(
    path: Path, expected_packages: list[str], label: str
) -> list[str]:
    errors: list[str] = []
    try:
        observed = os.lstat(path)
        if not stat.S_ISREG(observed.st_mode) or observed.st_nlink != 1:
            return [f"{label} is not a safe regular file"]
        if observed.st_size > MAX_SEMANTIC_TABLE_BYTES:
            return [f"{label} exceeds the semantic size limit"]
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError) as error:
        return [f"cannot read {label}: {error}"]
    packages: list[str] = []
    for line_number, line in enumerate(lines, 1):
        values = line.split("\t")
        if len(values) != 2 or not values[0] or not values[1]:
            errors.append(f"{label} line {line_number} is malformed")
            continue
        packages.append(values[0])
    if packages != sorted(packages) or len(packages) != len(set(packages)):
        errors.append(f"{label} is not a sorted unique package snapshot")
    missing = sorted(set(expected_packages) - set(packages))
    if missing:
        errors.append(f"{label} lacks trusted contract packages: {', '.join(missing)}")
    return errors


def validate_foreign_architectures(
    path: Path, expected_architectures: list[str], label: str
) -> list[str]:
    errors: list[str] = []
    try:
        if not path.is_file() or path.is_symlink():
            return [f"{label} is not a safe regular file"]
        if path.stat().st_size > MAX_SEMANTIC_TABLE_BYTES:
            return [f"{label} exceeds the semantic size limit"]
        observed = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError) as error:
        return [f"cannot read {label}: {error}"]
    if any(not architecture or not re.fullmatch(r"[a-z0-9][a-z0-9-]*", architecture) for architecture in observed):
        errors.append(f"{label} contains an invalid architecture token")
    if observed != sorted(set(observed)):
        errors.append(f"{label} is not sorted and unique")
    expected = sorted(expected_architectures)
    if observed != expected:
        errors.append(f"{label} does not match the trusted foreign-architecture contract")
    return errors


def derive_trusted_contract(
    repo_root: Path,
    module_id: str,
    family: str,
    os_id: str,
    version_id: str,
    architecture: str,
) -> tuple[str | None, str | None]:
    try:
        completed = subprocess.run(
            [
                "bash",
                str(repo_root / "tests" / "evidence-contract.sh"),
                str(repo_root),
                module_id,
                family,
                os_id,
                version_id,
                architecture,
            ],
            cwd=repo_root,
            check=False,
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=30,
        )
    except (OSError, UnicodeDecodeError, subprocess.TimeoutExpired) as error:
        return None, f"cannot derive trusted module contract: {error}"
    if completed.returncode != 0:
        return None, "checked-out catalog rejected trusted module contract derivation"
    return completed.stdout, None


def command_validate(args: argparse.Namespace) -> int:
    artifacts_root = Path(args.artifacts_root).resolve()
    repo_root = Path(args.repo_root).resolve()
    output = Path(args.output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    issues: list[str] = []

    expected_rows, expected_errors = read_strict_tsv(
        Path(args.expected_cells), EXPECTED_CELLS_HEADER, "expected-cell plan"
    )
    resolved_rows, resolved_errors = read_strict_tsv(
        Path(args.resolved_targets), RESOLVED_TARGETS_HEADER, "resolved-target plan"
    )
    trusted_target_rows, trusted_target_errors = read_strict_tsv(
        repo_root / "tests" / "evidence-targets.tsv",
        TARGETS_HEADER,
        "checked-out target table",
    )
    issues.extend(expected_errors + resolved_errors + trusted_target_errors)

    expected = {row["cell_id"]: row for row in expected_rows if row["cell_id"]}
    resolved = {row["target_id"]: row for row in resolved_rows if row["target_id"]}
    trusted_targets = {
        row["target_id"]: row for row in trusted_target_rows if row["target_id"]
    }
    if len(expected) != len(expected_rows):
        issues.append("expected-cell plan contains missing or duplicate IDs")
    if len(resolved) != len(resolved_rows):
        issues.append("resolved-target plan contains missing or duplicate IDs")
    if len(trusted_targets) != len(trusted_target_rows):
        issues.append("checked-out target table contains missing or duplicate IDs")
    if set(resolved) != set(trusted_targets):
        issues.append("resolved-target plan does not cover the checked-out target table exactly")
    if not COMMIT_PATTERN.fullmatch(args.commit):
        issues.append("tested commit is not a full Git object ID")

    slug_pattern = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
    for target_id, row in resolved.items():
        trusted = trusted_targets.get(target_id)
        if not slug_pattern.fullmatch(target_id):
            issues.append(f"resolved target has an invalid ID: {target_id}")
        if trusted is not None:
            for key in TARGETS_HEADER:
                if row.get(key) != trusted.get(key):
                    issues.append(f"resolved target {target_id} mismatches checked-out field {key}")
        if not IMAGE_REF_PATTERN.fullmatch(row.get("image_ref", "")):
            issues.append(f"resolved target {target_id} lacks an immutable image reference")

    expected_paths: dict[str, str] = {}
    for cell_id, row in expected.items():
        target_id = row["target_id"]
        module_id = row["module"]
        canonical_id = f"{target_id}/{module_id}"
        if cell_id != canonical_id:
            issues.append(f"expected cell has a noncanonical ID: {cell_id}")
        if not slug_pattern.fullmatch(target_id) or not slug_pattern.fullmatch(module_id):
            issues.append(f"expected cell has an invalid target or module ID: {cell_id}")
        target_plan = resolved.get(target_id)
        if target_plan is None:
            issues.append(f"expected cell references an unresolved target: {cell_id}")
        else:
            for expected_key, target_key in (
                ("family", "family"),
                ("image", "image"),
                ("platform", "platform"),
                ("expected_os_id", "expected_os_id"),
                ("expected_version_id", "expected_version_id"),
                ("expected_arch", "expected_arch"),
            ):
                if row[expected_key] != target_plan[target_key]:
                    issues.append(f"expected cell {cell_id} mismatches target field {target_key}")
        trusted_manifest = repo_root / "modules" / module_id / "module.sh"
        if not trusted_manifest.is_file() or trusted_manifest.is_symlink():
            issues.append(f"expected cell lacks a safe checked-out module manifest: {cell_id}")
        expected_paths[
            PurePosixPath("cells", target_id, module_id, "result.json").as_posix()
        ] = cell_id

    artifact_files: list[Path] = []
    try:
        artifact_files = regular_tree_files(artifacts_root)
    except ValueError as error:
        issues.append(str(error))

    found: dict[str, tuple[Path, dict[str, Any]]] = {}
    for result_path in (path for path in artifact_files if path.name == "result.json"):
        relative = result_path.relative_to(artifacts_root).as_posix()
        expected_cell_id = expected_paths.get(relative)
        if expected_cell_id is None:
            issues.append(f"result is outside its canonical cell path: {relative}")
            continue
        try:
            if result_path.stat().st_size > 16 * 1024 * 1024:
                raise ValueError("result exceeds the 16 MiB validation limit")
            result_value = json.loads(result_path.read_text(encoding="utf-8"))
            if not isinstance(result_value, dict):
                raise ValueError("result is not a JSON object")
        except (OSError, UnicodeDecodeError, json.JSONDecodeError, ValueError) as error:
            issues.append(f"cannot parse {relative}: {error}")
            continue
        if expected_cell_id in found:
            issues.append(f"duplicate result for {expected_cell_id}")
        else:
            found[expected_cell_id] = (result_path, result_value)

    missing = sorted(set(expected) - set(found))
    issues.extend(f"missing cell: {cell_id}" for cell_id in missing)

    summary_rows: list[dict[str, str]] = []
    index_cells: list[dict[str, Any]] = []
    for cell_id in sorted(expected):
        expected_row = expected[cell_id]
        located = found.get(cell_id)
        cell_issues: list[str] = []
        if located is None:
            status = "missing"
            failure_stage = "missing-result"
            result_sha = None
        else:
            result_path, result = located
            cell_dir = result_path.parent
            status = str(result.get("result", "invalid"))
            failure_stage = result.get("failure_stage")
            result_sha = sha256_file(result_path)
            source = result.get("source") if isinstance(result.get("source"), dict) else {}
            target = result.get("target") if isinstance(result.get("target"), dict) else {}
            module = result.get("module") if isinstance(result.get("module"), dict) else {}
            execution = (
                result.get("execution")
                if isinstance(result.get("execution"), dict)
                else {}
            )
            checks = result.get("checks") if isinstance(result.get("checks"), dict) else {}
            target_plan = resolved.get(expected_row["target_id"], {})
            expected_target = {
                "os_id": expected_row["expected_os_id"],
                "version_id": expected_row["expected_version_id"],
                "architecture": expected_row["expected_arch"],
            }

            if result.get("schema") != SCHEMA:
                cell_issues.append("unsupported result schema")
            if result.get("cell_id") != cell_id:
                cell_issues.append("cell ID does not match its canonical path")
            if status not in {"passed", "failed"}:
                cell_issues.append("cell result has an invalid status")
            if status == "passed" and failure_stage is not None:
                cell_issues.append("passed cell declares a failure stage")
            for key, expected_value in (
                ("repository", args.repository),
                ("commit", args.commit),
                ("ref", args.ref),
                ("run_id", args.run_id),
                ("run_attempt", args.run_attempt),
                ("run_url", args.run_url),
                ("artifact", f"module-cell-{expected_row['module']}"),
            ):
                if source.get(key) != expected_value:
                    cell_issues.append(f"source field {key} is mismatched")

            target_expectations = (
                ("target_id", expected_row["target_id"]),
                ("display_name", target_plan.get("display_name")),
                ("family", expected_row["family"]),
                ("image_tag", expected_row["image"]),
                ("image_ref", target_plan.get("image_ref")),
                ("platform", expected_row["platform"]),
                ("runner_image_architecture", "amd64"),
            )
            for key, expected_value in target_expectations:
                if target.get(key) != expected_value:
                    cell_issues.append(f"target field {key} is mismatched")
            image_id = target.get("image_id")
            if not isinstance(image_id, str) or not IMAGE_ID_PATTERN.fullmatch(image_id):
                cell_issues.append("target image ID is invalid")
            if target.get("expected") != expected_target:
                cell_issues.append("target expectation contract is mismatched")
            observed = target.get("observed") if isinstance(target.get("observed"), dict) else {}
            if observed.get("os_id") != expected_target["os_id"]:
                cell_issues.append("observed OS ID is mismatched")
            if not version_id_matches(
                str(observed.get("os_version", "")), expected_target["version_id"]
            ):
                cell_issues.append("observed OS version is mismatched")
            if observed.get("architecture") != expected_target["architecture"]:
                cell_issues.append("observed architecture is mismatched")
            if observed.get("family") != expected_row["family"]:
                cell_issues.append("observed family is mismatched")

            manifest_relative = f"modules/{expected_row['module']}/module.sh"
            trusted_manifest = repo_root / manifest_relative
            captured_manifest = cell_dir / "module.sh"
            trusted_manifest_sha = (
                sha256_file(trusted_manifest)
                if trusted_manifest.is_file() and not trusted_manifest.is_symlink()
                else None
            )
            captured_manifest_sha = (
                sha256_file(captured_manifest)
                if captured_manifest.is_file() and not captured_manifest.is_symlink()
                else None
            )
            if module.get("id") != expected_row["module"]:
                cell_issues.append("module ID is mismatched")
            if module.get("manifest_path") != manifest_relative:
                cell_issues.append("module manifest path is mismatched")
            if (
                trusted_manifest_sha is None
                or captured_manifest_sha != trusted_manifest_sha
                or module.get("manifest_sha256") != trusted_manifest_sha
            ):
                cell_issues.append("module manifest is not bound to the checked-out commit")
            if module.get("explicit_service_activation_requested") is not False:
                cell_issues.append("service-activation request metadata is invalid")

            if execution.get("container_exit_code") != 0:
                cell_issues.append("container exit metadata is not successful")
            if execution.get("runner_stage") != "container-complete":
                cell_issues.append("runner did not complete container cleanup")
            if execution.get("initial_refresh_requested") is not True:
                cell_issues.append("initial refresh request metadata is invalid")
            if execution.get("repeat_no_refresh_requested") is not True:
                cell_issues.append("repeat no-refresh request metadata is invalid")
            expected_checks = {key: "passed" for key in FINAL_CHECK_KEYS}
            if checks != expected_checks:
                cell_issues.append("finalized check set is incomplete or not fully passed")
            if status == "passed" and result.get("validation_errors") != []:
                cell_issues.append("passed result contains validation errors")

            raw_errors: list[str] = []
            raw = strict_fields(cell_dir / "raw-execution.tsv", "raw execution", raw_errors)
            for key, expected_value in (
                ("schema_version", "1"),
                ("tested_commit", args.commit),
                ("workflow_run_url", args.run_url),
                ("target_id", expected_row["target_id"]),
                ("image_ref", str(target_plan.get("image_ref", ""))),
                ("image_id", str(image_id or "")),
                ("module", expected_row["module"]),
                ("result", "success"),
                ("exit_code", "0"),
                ("failure_stage", "-"),
                ("os_id", expected_target["os_id"]),
                ("architecture", expected_target["architecture"]),
                ("family", expected_row["family"]),
            ):
                require_exact_field(raw, key, expected_value, raw_errors, "raw execution")
            require_single_nonempty_field(raw, "started_at", raw_errors, "raw execution")
            require_single_nonempty_field(raw, "finished_at", raw_errors, "raw execution")
            raw_os_versions = raw.get("os_version", [])
            if len(raw_os_versions) != 1 or not version_id_matches(
                raw_os_versions[0] if raw_os_versions else "",
                expected_target["version_id"],
            ):
                raw_errors.append("raw execution field os_version is missing or mismatched")
            for observed_key, raw_key in (
                ("os_id", "os_id"),
                ("os_version", "os_version"),
                ("architecture", "architecture"),
                ("family", "family"),
            ):
                raw_values = raw.get(raw_key, [])
                if len(raw_values) == 1 and observed.get(observed_key) != raw_values[0]:
                    raw_errors.append(
                        f"result observed field {observed_key} disagrees with raw execution"
                    )

            stage_errors: list[str] = []
            stage_rows, stage_table_errors = read_strict_tsv(
                cell_dir / "stages.tsv",
                ["stage", "status", "timestamp", "exit_code"],
                "stage evidence",
            )
            stage_errors.extend(stage_table_errors)
            expected_stage_rows: list[tuple[str, str, str]] = []
            for stage_name in SUCCESS_STAGE_ORDER:
                expected_stage_rows.extend(
                    ((stage_name, "running", "-"), (stage_name, "passed", "0"))
                )
            if len(stage_rows) != len(expected_stage_rows):
                stage_errors.append("successful stage evidence has an unexpected row count")
            else:
                for row, expected_stage_row in zip(
                    stage_rows, expected_stage_rows, strict=True
                ):
                    observed_stage_row = (
                        row["stage"],
                        row["status"],
                        row["exit_code"],
                    )
                    if observed_stage_row != expected_stage_row or not row["timestamp"]:
                        stage_errors.append("successful stage sequence is mismatched")
                        break
            if execution.get("stages") != stage_rows:
                stage_errors.append("result stage metadata disagrees with stages.tsv")

            contract_errors: list[str] = []
            contract_rows, contract_table_errors = read_strict_tsv(
                cell_dir / "module-contract.tsv",
                ["type", "value"],
                "module contract",
            )
            contract_errors.extend(contract_table_errors)
            expected_contract_rows, expected_contract_table_errors = read_strict_tsv(
                cell_dir / "expected-module-contract.tsv",
                ["type", "value"],
                "host-derived module contract",
            )
            contract_errors.extend(expected_contract_table_errors)
            trusted_contract_text, trusted_contract_error = derive_trusted_contract(
                repo_root,
                expected_row["module"],
                expected_row["family"],
                expected_row["expected_os_id"],
                expected_row["expected_version_id"],
                expected_row["expected_arch"],
            )
            if trusted_contract_error:
                contract_errors.append(trusted_contract_error)
            else:
                try:
                    captured_contract_text = (cell_dir / "module-contract.tsv").read_text(
                        encoding="utf-8"
                    )
                    host_contract_text = (
                        cell_dir / "expected-module-contract.tsv"
                    ).read_text(encoding="utf-8")
                except (OSError, UnicodeDecodeError) as error:
                    contract_errors.append(f"cannot compare trusted module contracts: {error}")
                else:
                    if (
                        captured_contract_text != trusted_contract_text
                        or host_contract_text != trusted_contract_text
                        or contract_rows != expected_contract_rows
                    ):
                        contract_errors.append(
                            "module contracts disagree with the checked-out catalog"
                        )
            contract_values: dict[str, list[str]] = {
                "package": [],
                "verification_binary": [],
                "service": [],
                "foreign_architecture": [],
            }
            for row in contract_rows:
                kind = row["type"]
                value = row["value"]
                if kind not in contract_values or not value:
                    contract_errors.append("module contract contains an invalid row")
                else:
                    contract_values[kind].append(value)
            for result_key, contract_key in (
                ("packages", "package"),
                ("verification_binaries", "verification_binary"),
                ("services", "service"),
                ("foreign_architectures", "foreign_architecture"),
            ):
                if module.get(result_key) != contract_values[contract_key]:
                    contract_errors.append(
                        f"result module field {result_key} disagrees with module-contract.tsv"
                    )
            if not contract_values["package"] or not contract_values["verification_binary"]:
                contract_errors.append("module contract lacks packages or verification binaries")
            binary_errors = validate_binary_table(
                cell_dir / "binary-paths-after-install.tsv",
                contract_values["verification_binary"],
                "post-install binary evidence",
            )
            binary_errors.extend(
                validate_binary_table(
                    cell_dir / "binary-paths-after-repeat.tsv",
                    contract_values["verification_binary"],
                    "post-repeat binary evidence",
                )
            )
            package_source_errors = validate_package_sources(
                cell_dir / "package-sources.txt", contract_values["package"]
            )
            package_snapshot_errors = validate_package_snapshot(
                cell_dir / "packages-before-install.tsv",
                [],
                "pre-install package snapshot",
            )
            package_snapshot_errors.extend(
                validate_package_snapshot(
                    cell_dir / "packages-after-install.tsv",
                    contract_values["package"],
                    "post-install package snapshot",
                )
            )
            package_snapshot_errors.extend(
                validate_package_snapshot(
                    cell_dir / "packages-after-repeat.tsv",
                    contract_values["package"],
                    "post-repeat package snapshot",
                )
            )
            foreign_architecture_errors = validate_foreign_architectures(
                cell_dir / "foreign-architectures-after-install.txt",
                contract_values["foreign_architecture"],
                "post-install foreign-architecture evidence",
            )
            foreign_architecture_errors.extend(
                validate_foreign_architectures(
                    cell_dir / "foreign-architectures-after-repeat.txt",
                    contract_values["foreign_architecture"],
                    "post-repeat foreign-architecture evidence",
                )
            )

            snapshot_errors: list[str] = []
            snapshots = (
                result.get("snapshots")
                if isinstance(result.get("snapshots"), dict)
                else {}
            )
            for snapshot_key, filename in (
                ("before_install", "packages-before-install.tsv"),
                ("after_install", "packages-after-install.tsv"),
                ("after_repeat", "packages-after-repeat.tsv"),
            ):
                snapshot_path = cell_dir / filename
                expected_snapshot = {
                    "path": filename,
                    "sha256": (
                        sha256_file(snapshot_path)
                        if snapshot_path.is_file() and not snapshot_path.is_symlink()
                        else None
                    ),
                }
                if snapshots.get(snapshot_key) != expected_snapshot:
                    snapshot_errors.append(
                        f"result snapshot {snapshot_key} disagrees with its payload"
                    )
            if execution.get("started_at") != last_field(raw, "started_at"):
                raw_errors.append("execution start time disagrees with raw execution")
            if execution.get("completed_at") != last_field(raw, "finished_at"):
                raw_errors.append("execution completion time disagrees with raw execution")

            runner_errors: list[str] = []
            runner = strict_fields(cell_dir / "runner.tsv", "runner", runner_errors)
            for key, expected_value in (
                ("runner_stage", "container-complete"),
                ("pull_exit_code", "0"),
                ("container_exit_code", "0"),
                ("image_id", str(image_id or "")),
                ("image_architecture", "amd64"),
            ):
                require_exact_field(runner, key, expected_value, runner_errors, "runner")
            require_single_nonempty_field(runner, "started_at", runner_errors, "runner")
            cell_issues.extend(
                raw_errors
                + runner_errors
                + stage_errors
                + contract_errors
                + binary_errors
                + package_source_errors
                + package_snapshot_errors
                + foreign_architecture_errors
                + snapshot_errors
            )
            cell_issues.extend(verify_integrity(result_path, result))
            if args.require_pass and status != "passed":
                cell_issues.append(f"cell result is {status}")

        issues.extend(f"{cell_id}: {message}" for message in cell_issues)
        summary_rows.append(
            {
                "cell_id": cell_id,
                "target_id": expected_row["target_id"],
                "family": expected_row["family"],
                "module": expected_row["module"],
                "result": status,
                "failure_stage": str(failure_stage or "-"),
                "validation_errors": str(len(cell_issues)),
            }
        )
        index_cells.append({**summary_rows[-1], "result_sha256": result_sha})

    index = {
        "schema": INDEX_SCHEMA,
        "tested_commit": args.commit,
        "source": {
            "repository": args.repository,
            "ref": args.ref,
            "run_id": args.run_id,
            "run_attempt": args.run_attempt,
            "run_url": args.run_url,
        },
        "generated_at": utc_now(),
        "expected_cells": len(expected),
        "found_cells": len(found),
        "validation_passed": not issues,
        "issues": issues,
        "cells": index_cells,
    }
    (output / "index.json").write_text(
        json.dumps(index, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    with (output / "summary.tsv").open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(
            stream,
            fieldnames=list(summary_rows[0]) if summary_rows else ["cell_id"],
            delimiter="\t",
        )
        writer.writeheader()
        writer.writerows(summary_rows)
    if Path(args.expected_cells).is_file():
        shutil.copy2(args.expected_cells, output / "expected-cells.tsv")
    if Path(args.resolved_targets).is_file():
        shutil.copy2(args.resolved_targets, output / "resolved-targets.tsv")
    (output / "index.json.sha256").write_text(
        f"{sha256_file(output / 'index.json')}  index.json\n",
        encoding="utf-8",
        newline="\n",
    )

    if issues:
        for issue in issues:
            print(f"evidence validation failed: {issue}", file=sys.stderr)
        return 1
    print(f"Validated {len(expected)} standalone module-image evidence cells.")
    return 0


def nonnegative_int(value: str) -> int:
    parsed = int(value)
    if parsed < 0:
        raise argparse.ArgumentTypeError("must be a non-negative integer")
    return parsed


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)

    finalize = subparsers.add_parser("finalize-cell")
    for name in (
        "cell_dir",
        "repo_root",
        "target_id",
        "display_name",
        "family",
        "module",
        "image_tag",
        "image_ref",
        "image_id",
        "image_arch",
        "platform",
        "expected_os_id",
        "expected_version_id",
        "expected_arch",
        "repository",
        "commit",
        "ref",
        "run_id",
        "run_attempt",
        "run_url",
        "artifact_name",
        "runner_stage",
    ):
        finalize.add_argument("--" + name.replace("_", "-"), required=True)
    finalize.add_argument("--container-exit", type=int, required=True)
    finalize.set_defaults(handler=command_finalize)

    validate = subparsers.add_parser("validate-run")
    validate.add_argument("--artifacts-root", required=True)
    validate.add_argument("--expected-cells", required=True)
    validate.add_argument("--resolved-targets", required=True)
    validate.add_argument("--repo-root", required=True)
    validate.add_argument("--repository", required=True)
    validate.add_argument("--commit", required=True)
    validate.add_argument("--ref", required=True)
    validate.add_argument("--run-id", required=True)
    validate.add_argument("--run-attempt", required=True)
    validate.add_argument("--run-url", required=True)
    validate.add_argument("--output", required=True)
    validate.add_argument("--require-pass", action="store_true")
    validate.set_defaults(handler=command_validate)

    sanitize = subparsers.add_parser("sanitize-tree")
    sanitize.add_argument("--source", required=True)
    sanitize.add_argument("--destination", required=True)
    sanitize.add_argument("--owner-uid", type=nonnegative_int)
    sanitize.add_argument("--owner-gid", type=nonnegative_int)
    sanitize.set_defaults(handler=command_sanitize_tree)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    return int(args.handler(args))


if __name__ == "__main__":
    raise SystemExit(main())
