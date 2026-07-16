#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

source_dir="$TEMP_DIR/source-logs"
evidence_dir="$TEMP_DIR/evidence"
mkdir -p "$source_dir" "$evidence_dir"
printf 'installer log\n' > "$source_dir/run.log"

LSI_EVIDENCE_LOG_SOURCE="$source_dir" \
  bash "$ROOT_DIR/tests/capture-installer-logs.sh" "$evidence_dir" bash -c 'exit 0'
cmp "$source_dir/run.log" "$evidence_dir/installer-logs/run.log"

failure_evidence="$TEMP_DIR/failure-evidence"
mkdir "$failure_evidence"
set +e
LSI_EVIDENCE_LOG_SOURCE="$source_dir" \
  bash "$ROOT_DIR/tests/capture-installer-logs.sh" "$failure_evidence" bash -c 'exit 19'
status=$?
set -e
[[ $status -eq 19 ]]
cmp "$source_dir/run.log" "$failure_evidence/installer-logs/run.log"

missing_evidence="$TEMP_DIR/missing-evidence"
mkdir "$missing_evidence"
if LSI_EVIDENCE_LOG_SOURCE="$TEMP_DIR/missing-logs" \
  bash "$ROOT_DIR/tests/capture-installer-logs.sh" "$missing_evidence" bash -c 'exit 0'; then
  printf 'Log capture unexpectedly accepted a missing installer log directory.\n' >&2
  exit 1
fi

grep -Fq 'capture-installer-logs.sh /evidence' "$ROOT_DIR/tests/run-module-evidence.sh"
grep -Fq 'capture-installer-logs.sh /evidence' "$ROOT_DIR/.github/workflows/install-smoke.yml"
if grep -Fq ':/var/log/linux-software-installer' "$ROOT_DIR/tests/run-module-evidence.sh"; then
  printf 'Standalone evidence runner still bind-mounts the installer log directory.\n' >&2
  exit 1
fi

if grep -Fq ':/var/log/linux-software-installer' "$ROOT_DIR/.github/workflows/install-smoke.yml"; then
  printf 'Install-smoke workflow still bind-mounts the installer log directory.\n' >&2
  exit 1
fi
