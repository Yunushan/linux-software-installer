#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=python.sh
source "$ROOT_DIR/tests/python.sh"
PYTHON=$(lsi_find_python) || {
  printf 'Python 3.8 or newer is required for the evidence-record self-test.\n' >&2
  exit 2
}

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
CELL_DIR="$TEMP_DIR/artifacts/cells/ubuntu-24-04/git"
RAW_CELL_DIR="$TEMP_DIR/raw-cell"
PLAN_DIR="$TEMP_DIR/plan"
OUTPUT_DIR="$TEMP_DIR/output"
mkdir -p "$CELL_DIR" "$RAW_CELL_DIR" "$PLAN_DIR"

COMMIT=1111111111111111111111111111111111111111
IMAGE_REF="ubuntu@sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
IMAGE_ID=sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
RUN_URL=local

printf '%s\n' \
  $'field\tvalue' \
  $'schema_version\t1' \
  $'started_at\t2026-01-01T00:00:00Z' \
  $'tested_commit\t'"$COMMIT" \
  $'workflow_run_url\t'"$RUN_URL" \
  $'target_id\tubuntu-24-04' \
  $'image_ref\t'"$IMAGE_REF" \
  $'image_id\t'"$IMAGE_ID" \
  $'module\tgit' \
  $'finished_at\t2026-01-01T00:01:00Z' \
  $'result\tsuccess' \
  $'exit_code\t0' \
  $'failure_stage\t-' \
  $'os_id\tubuntu' \
  $'os_version\t24.04' \
  $'architecture\tx86_64' \
  $'family\tdebian' > "$RAW_CELL_DIR/raw-execution.tsv"

printf '%s\n' $'stage\tstatus\ttimestamp\texit_code' \
  $'detect-and-contract\trunning\t2026-01-01T00:00:01Z\t-' \
  $'detect-and-contract\tpassed\t2026-01-01T00:00:02Z\t0' \
  $'snapshot-before-install\trunning\t2026-01-01T00:00:03Z\t-' \
  $'snapshot-before-install\tpassed\t2026-01-01T00:00:04Z\t0' \
  $'initial-install\trunning\t2026-01-01T00:00:05Z\t-' \
  $'initial-install\tpassed\t2026-01-01T00:00:10Z\t0' \
  $'foreign-architecture-check-after-install\trunning\t2026-01-01T00:00:11Z\t-' \
  $'foreign-architecture-check-after-install\tpassed\t2026-01-01T00:00:12Z\t0' \
  $'binary-check-after-install\trunning\t2026-01-01T00:00:11Z\t-' \
  $'binary-check-after-install\tpassed\t2026-01-01T00:00:20Z\t0' \
  $'snapshot-after-install\trunning\t2026-01-01T00:00:21Z\t-' \
  $'snapshot-after-install\tpassed\t2026-01-01T00:00:22Z\t0' \
  $'package-source-capture\trunning\t2026-01-01T00:00:23Z\t-' \
  $'package-source-capture\tpassed\t2026-01-01T00:00:30Z\t0' \
  $'repeat-install\trunning\t2026-01-01T00:00:31Z\t-' \
  $'repeat-install\tpassed\t2026-01-01T00:00:40Z\t0' \
  $'foreign-architecture-check-after-repeat\trunning\t2026-01-01T00:00:41Z\t-' \
  $'foreign-architecture-check-after-repeat\tpassed\t2026-01-01T00:00:42Z\t0' \
  $'binary-check-after-repeat\trunning\t2026-01-01T00:00:41Z\t-' \
  $'binary-check-after-repeat\tpassed\t2026-01-01T00:00:50Z\t0' \
  $'snapshot-after-repeat\trunning\t2026-01-01T00:00:51Z\t-' \
  $'snapshot-after-repeat\tpassed\t2026-01-01T00:00:52Z\t0' \
  $'repeat-state-compare\trunning\t2026-01-01T00:00:53Z\t-' \
  $'repeat-state-compare\tpassed\t2026-01-01T00:00:54Z\t0' \
  > "$RAW_CELL_DIR/stages.tsv"

printf '%s\n' $'field\tvalue' $'started_at\t2026-01-01T00:00:00Z' \
  $'runner_stage\tcontainer-complete' $'container_exit_code\t0' \
  $'pull_exit_code\t0' $'image_id\t'"$IMAGE_ID" $'image_architecture\tamd64' \
  > "$CELL_DIR/runner.tsv"
printf '%s\n' $'type\tvalue' $'package\tgit' $'verification_binary\tgit' \
  > "$RAW_CELL_DIR/module-contract.tsv"
bash "$ROOT_DIR/tests/evidence-contract.sh" "$ROOT_DIR" git debian \
  ubuntu 24.04 x86_64 \
  > "$CELL_DIR/expected-module-contract.tsv"
if grep -q $'^service\t$' "$CELL_DIR/expected-module-contract.tsv"; then
  printf 'A no-service module emitted an empty service contract row.\n' >&2
  exit 1
fi
printf 'NAME=Ubuntu\nID=ubuntu\nVERSION_ID="24.04"\n' > "$RAW_CELL_DIR/os-release.txt"
cp "$ROOT_DIR/modules/git/module.sh" "$RAW_CELL_DIR/module.sh"
printf 'base\t1\n' > "$RAW_CELL_DIR/packages-before-install.tsv"
printf 'base\t1\ngit\t1\n' > "$RAW_CELL_DIR/packages-after-install.tsv"
printf 'base\t1\ngit\t1\n' > "$RAW_CELL_DIR/packages-after-repeat.tsv"
printf '%s\n' $'binary\tpath' $'git\t/usr/bin/git' \
  > "$RAW_CELL_DIR/binary-paths-after-install.tsv"
printf '%s\n' $'binary\tpath' $'git\t/usr/bin/git' \
  > "$RAW_CELL_DIR/binary-paths-after-repeat.tsv"
printf '===== git =====\ngit package source\n' > "$RAW_CELL_DIR/package-sources.txt"
: > "$RAW_CELL_DIR/foreign-architectures-after-install.txt"
: > "$RAW_CELL_DIR/foreign-architectures-after-repeat.txt"
printf 'container completed\n' > "$CELL_DIR/container.log"
"$PYTHON" "$ROOT_DIR/tests/evidence-record.py" sanitize-tree \
  --source "$RAW_CELL_DIR" --destination "$CELL_DIR" \
  --owner-uid "$(id -u)" --owner-gid "$(id -g)" \
  > /dev/null

finalize_cell() {
  local cell=$1
  "$PYTHON" "$ROOT_DIR/tests/evidence-record.py" finalize-cell \
    --cell-dir "$cell" \
    --repo-root "$ROOT_DIR" \
    --target-id ubuntu-24-04 \
    --display-name 'Ubuntu 24.04' \
    --family debian \
    --module git \
    --image-tag ubuntu:24.04 \
    --image-ref "$IMAGE_REF" \
    --image-id "$IMAGE_ID" \
    --image-arch amd64 \
    --platform linux/amd64 \
    --expected-os-id ubuntu \
    --expected-version-id 24.04 \
    --expected-arch x86_64 \
    --repository local/repository \
    --commit "$COMMIT" \
    --ref refs/heads/test \
    --run-id 1 \
    --run-attempt 1 \
    --run-url "$RUN_URL" \
    --artifact-name module-cell-git \
    --runner-stage container-complete \
    --container-exit 0
}

finalize_cell "$CELL_DIR" > /dev/null
"$PYTHON" -B - "$CELL_DIR/result.json" << 'PY'
import json
import sys
from pathlib import Path

result = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
expected = result.get("target", {}).get("expected", {})
if expected != {
    "architecture": "x86_64",
    "os_id": "ubuntu",
    "version_id": "24.04",
}:
    raise SystemExit("finalized target does not expose an exact version-ID contract")
PY

FINALIZER_FORGED_CELL="$TEMP_DIR/finalizer-forged-cell"
cp -a "$CELL_DIR" "$FINALIZER_FORGED_CELL"
printf '%s\n' $'type\tvalue' $'package\tforged-package' \
  $'verification_binary\tforged-binary' \
  > "$FINALIZER_FORGED_CELL/module-contract.tsv"
cp "$FINALIZER_FORGED_CELL/module-contract.tsv" \
  "$FINALIZER_FORGED_CELL/expected-module-contract.tsv"
if finalize_cell "$FINALIZER_FORGED_CELL" > /dev/null 2>&1; then
  printf 'Finalizer accepted matching forged host/container contracts.\n' >&2
  exit 1
fi
"$PYTHON" -B - "$FINALIZER_FORGED_CELL/result.json" << 'PY'
import json
import sys
from pathlib import Path

result = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if result.get("checks", {}).get("contract_binding") != "failed":
    raise SystemExit("forged finalizer contract was not attributed to contract_binding")
if not any(
    "exact checked-out target contract" in error
    for error in result.get("validation_errors", [])
):
    raise SystemExit("forged finalizer contract lacks an exact-target diagnostic")
PY

printf '%s\n' \
  $'cell_id\ttarget_id\tfamily\tmodule\timage\tplatform\texpected_os_id\texpected_version_id\texpected_arch' \
  $'ubuntu-24-04/git\tubuntu-24-04\tdebian\tgit\tubuntu:24.04\tlinux/amd64\tubuntu\t24.04\tx86_64' \
  > "$PLAN_DIR/expected-cells.tsv"
printf '%s\n' \
  $'target_id\tref_env\tdisplay_name\tfamily\timage\tplatform\texpected_os_id\texpected_version_id\texpected_arch\timage_ref' \
  "ubuntu-24-04"$'\t'"UBUNTU_24_04_IMAGE_REF"$'\t'"Ubuntu 24.04"$'\t'"debian"$'\t'"ubuntu:24.04"$'\t'"linux/amd64"$'\t'"ubuntu"$'\t'"24.04"$'\t'"x86_64"$'\t'"$IMAGE_REF" \
  "ubuntu-26-04"$'\t'"UBUNTU_26_04_IMAGE_REF"$'\t'"Ubuntu 26.04"$'\t'"debian"$'\t'"ubuntu:26.04"$'\t'"linux/amd64"$'\t'"ubuntu"$'\t'"26.04"$'\t'"x86_64"$'\t'"ubuntu@sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" \
  "debian-12"$'\t'"DEBIAN_12_IMAGE_REF"$'\t'"Debian 12"$'\t'"debian"$'\t'"debian:12"$'\t'"linux/amd64"$'\t'"debian"$'\t'"12"$'\t'"x86_64"$'\t'"debian@sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc" \
  "rocky-9-8"$'\t'"ROCKY_9_8_IMAGE_REF"$'\t'"Rocky Linux 9.8"$'\t'"rhel"$'\t'"rockylinux/rockylinux:9.8@sha256:8101994123cf3d0a8fee517bee7f39e555c7d92bd2d9eb3303cc988a0eeed00f"$'\t'"linux/amd64"$'\t'"rocky"$'\t'"9.8"$'\t'"x86_64"$'\t'"rockylinux@sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd" \
  "alma-9-8"$'\t'"ALMA_9_8_IMAGE_REF"$'\t'"AlmaLinux 9.8"$'\t'"rhel"$'\t'"almalinux:9.8@sha256:d2515c769e7b73f95c4fde38c0a505336ff38f14990c0b7253b77060a049a743"$'\t'"linux/amd64"$'\t'"almalinux"$'\t'"9.8"$'\t'"x86_64"$'\t'"almalinux@sha256:eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee" \
  > "$PLAN_DIR/resolved-targets.tsv"

validate_artifacts() {
  local artifacts=$1 output=$2
  "$PYTHON" "$ROOT_DIR/tests/evidence-record.py" validate-run \
    --artifacts-root "$artifacts" \
    --expected-cells "$PLAN_DIR/expected-cells.tsv" \
    --resolved-targets "$PLAN_DIR/resolved-targets.tsv" \
    --repo-root "$ROOT_DIR" \
    --repository local/repository \
    --commit "$COMMIT" \
    --ref refs/heads/test \
    --run-id 1 \
    --run-attempt 1 \
    --run-url "$RUN_URL" \
    --output "$output" \
    --require-pass
}

validate_artifacts "$TEMP_DIR/artifacts" "$OUTPUT_DIR" > /dev/null

GOOD_ARTIFACTS="$TEMP_DIR/good-artifacts"
mkdir -p "$GOOD_ARTIFACTS"
cp -a "$TEMP_DIR/artifacts/." "$GOOD_ARTIFACTS/"

NEAR_VERSION_ARTIFACTS="$TEMP_DIR/near-version-artifacts"
cp -a "$GOOD_ARTIFACTS" "$NEAR_VERSION_ARTIFACTS"
NEAR_VERSION_CELL="$NEAR_VERSION_ARTIFACTS/cells/ubuntu-24-04/git"
"$PYTHON" -B - "$NEAR_VERSION_CELL" << 'PY'
import hashlib
import json
import sys
from pathlib import Path


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


cell = Path(sys.argv[1])
raw_path = cell / "raw-execution.tsv"
raw = raw_path.read_text(encoding="utf-8")
old = "os_version\t24.04\n"
if raw.count(old) != 1:
    raise SystemExit("raw version fixture is not singular")
raw_path.write_text(raw.replace(old, "os_version\t24.04.1\n"), encoding="utf-8")

report_path = cell / "sanitize-report.json"
report = json.loads(report_path.read_text(encoding="utf-8"))
report["observed"]["expected_bytes"] += 2
report["observed"]["copied_bytes"] += 2
report_path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")

manifest_path = cell / "files.sha256"
entries = {}
for line in manifest_path.read_text(encoding="utf-8").splitlines():
    digest, relative = line.split("  ", 1)
    entries[relative] = digest
entries["raw-execution.tsv"] = sha256(raw_path)
entries["sanitize-report.json"] = sha256(report_path)
manifest_path.write_text(
    "".join(f"{entries[relative]}  {relative}\n" for relative in sorted(entries)),
    encoding="utf-8",
)

result_path = cell / "result.json"
result = json.loads(result_path.read_text(encoding="utf-8"))
result["target"]["observed"]["os_version"] = "24.04.1"
result["sanitization"]["report_sha256"] = sha256(report_path)
result["files_manifest_sha256"] = sha256(manifest_path)
result_path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
(cell / "result.json.sha256").write_text(
    f"{sha256(result_path)}  result.json\n", encoding="utf-8"
)
PY
if validate_artifacts "$NEAR_VERSION_ARTIFACTS" "$TEMP_DIR/near-version-output" \
  > /dev/null 2>&1; then
  printf 'A self-consistent near-match observed version unexpectedly validated.\n' >&2
  exit 1
fi

FORGED_CONTRACT_ARTIFACTS="$TEMP_DIR/forged-contract-artifacts"
cp -a "$GOOD_ARTIFACTS" "$FORGED_CONTRACT_ARTIFACTS"
FORGED_CONTRACT_CELL="$FORGED_CONTRACT_ARTIFACTS/cells/ubuntu-24-04/git"
printf '%s\n' $'type\tvalue' $'package\tforged-package' \
  $'verification_binary\tforged-binary' \
  > "$FORGED_CONTRACT_CELL/module-contract.tsv"
cp "$FORGED_CONTRACT_CELL/module-contract.tsv" \
  "$FORGED_CONTRACT_CELL/expected-module-contract.tsv"
printf '%s\n' $'binary\tpath' $'forged-binary\t/usr/bin/forged-binary' \
  > "$FORGED_CONTRACT_CELL/binary-paths-after-install.tsv"
cp "$FORGED_CONTRACT_CELL/binary-paths-after-install.tsv" \
  "$FORGED_CONTRACT_CELL/binary-paths-after-repeat.tsv"
printf '===== forged-package =====\nforged package source\n' \
  > "$FORGED_CONTRACT_CELL/package-sources.txt"
printf 'base\t1\nforged-package\t1\n' \
  > "$FORGED_CONTRACT_CELL/packages-after-install.tsv"
cp "$FORGED_CONTRACT_CELL/packages-after-install.tsv" \
  "$FORGED_CONTRACT_CELL/packages-after-repeat.tsv"
if finalize_cell "$FORGED_CONTRACT_CELL" > /dev/null 2>&1; then
  printf 'A self-consistent forged module contract unexpectedly finalized.\n' >&2
  exit 1
fi
if validate_artifacts "$FORGED_CONTRACT_ARTIFACTS" "$TEMP_DIR/forged-contract-output" \
  > /dev/null 2>&1; then
  printf 'A self-consistent forged module contract unexpectedly validated.\n' >&2
  exit 1
fi

REDUCED_CHECKS_ARTIFACTS="$TEMP_DIR/reduced-checks-artifacts"
cp -a "$GOOD_ARTIFACTS" "$REDUCED_CHECKS_ARTIFACTS"
REDUCED_RESULT="$REDUCED_CHECKS_ARTIFACTS/cells/ubuntu-24-04/git/result.json"
"$PYTHON" - "$REDUCED_RESULT" << 'PY'
import hashlib
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
result = json.loads(path.read_text(encoding="utf-8"))
result["checks"] = {"forged": "passed"}
path.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n", encoding="utf-8")
digest = hashlib.sha256(path.read_bytes()).hexdigest()
(path.parent / "result.json.sha256").write_text(
    f"{digest}  result.json\n", encoding="utf-8"
)
PY
if validate_artifacts "$REDUCED_CHECKS_ARTIFACTS" "$TEMP_DIR/reduced-checks-output" \
  > /dev/null 2>&1; then
  printf 'A reduced forged checks map unexpectedly validated.\n' >&2
  exit 1
fi

MANIFEST_MISMATCH_CELL="$TEMP_DIR/manifest-mismatch/cells/ubuntu-24-04/git"
mkdir -p "$(dirname "$MANIFEST_MISMATCH_CELL")"
cp -a "$GOOD_ARTIFACTS/cells/ubuntu-24-04/git" "$MANIFEST_MISMATCH_CELL"
printf '# forged manifest change\n' >> "$MANIFEST_MISMATCH_CELL/module.sh"
if finalize_cell "$MANIFEST_MISMATCH_CELL" > /dev/null 2>&1; then
  printf 'A cell with a mismatched checked-out module manifest unexpectedly finalized.\n' >&2
  exit 1
fi

RAW_MISMATCH_CELL="$TEMP_DIR/raw-mismatch/cells/ubuntu-24-04/git"
mkdir -p "$(dirname "$RAW_MISMATCH_CELL")"
cp -a "$GOOD_ARTIFACTS/cells/ubuntu-24-04/git" "$RAW_MISMATCH_CELL"
sed -i 's/^target_id\tubuntu-24-04$/target_id\tdebian-12/' \
  "$RAW_MISMATCH_CELL/raw-execution.tsv"
if finalize_cell "$RAW_MISMATCH_CELL" > /dev/null 2>&1; then
  printf 'A cell with mismatched raw target metadata unexpectedly finalized.\n' >&2
  exit 1
fi

VERSION_MISMATCH_CELL="$TEMP_DIR/version-mismatch/cells/ubuntu-24-04/git"
mkdir -p "$(dirname "$VERSION_MISMATCH_CELL")"
cp -a "$GOOD_ARTIFACTS/cells/ubuntu-24-04/git" "$VERSION_MISMATCH_CELL"
sed -i 's/^os_version\t24\.04$/os_version\t24.04.1/' \
  "$VERSION_MISMATCH_CELL/raw-execution.tsv"
if finalize_cell "$VERSION_MISMATCH_CELL" > /dev/null 2>&1; then
  printf 'A near-match observed version unexpectedly finalized.\n' >&2
  exit 1
fi
"$PYTHON" -B - "$VERSION_MISMATCH_CELL/result.json" << 'PY'
import json
import sys
from pathlib import Path

result = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if result.get("checks", {}).get("target_identity") != "failed":
    raise SystemExit("near-match version failure was not attributed to target_identity")
if not any(
    "expected version ID 24.04, observed 24.04.1" in error
    for error in result.get("validation_errors", [])
):
    raise SystemExit("near-match version failure lacks an exact-version diagnostic")
PY

STAGE_MISMATCH_CELL="$TEMP_DIR/stage-mismatch/cells/ubuntu-24-04/git"
mkdir -p "$(dirname "$STAGE_MISMATCH_CELL")"
cp -a "$GOOD_ARTIFACTS/cells/ubuntu-24-04/git" "$STAGE_MISMATCH_CELL"
sed -i '0,/repeat-state-compare\tpassed/s//repeat-state-compare\trunning/' \
  "$STAGE_MISMATCH_CELL/stages.tsv"
if finalize_cell "$STAGE_MISMATCH_CELL" > /dev/null 2>&1; then
  printf 'A cell with a forged stage sequence unexpectedly finalized.\n' >&2
  exit 1
fi

MALFORMED_TABLE_CELL="$TEMP_DIR/malformed-table/cells/ubuntu-24-04/git"
mkdir -p "$(dirname "$MALFORMED_TABLE_CELL")"
cp -a "$GOOD_ARTIFACTS/cells/ubuntu-24-04/git" "$MALFORMED_TABLE_CELL"
printf '\xff' >> "$MALFORMED_TABLE_CELL/raw-execution.tsv"
if finalize_cell "$MALFORMED_TABLE_CELL" > /dev/null 2>&1; then
  printf 'A cell with invalid UTF-8 metadata unexpectedly finalized.\n' >&2
  exit 1
fi
[[ -f $MALFORMED_TABLE_CELL/result.json ]] || {
  printf 'Malformed metadata aborted finalization without a structured result.\n' >&2
  exit 1
}

NONCANONICAL_ARTIFACTS="$TEMP_DIR/noncanonical-artifacts"
cp -a "$GOOD_ARTIFACTS" "$NONCANONICAL_ARTIFACTS"
mkdir -p "$NONCANONICAL_ARTIFACTS/rogue"
cp "$GOOD_ARTIFACTS/cells/ubuntu-24-04/git/result.json" \
  "$NONCANONICAL_ARTIFACTS/rogue/result.json"
if validate_artifacts "$NONCANONICAL_ARTIFACTS" "$TEMP_DIR/noncanonical-output" \
  > /dev/null 2>&1; then
  printf 'A result outside its canonical cell path unexpectedly validated.\n' >&2
  exit 1
fi

NESTED_RESULT_ARTIFACTS="$TEMP_DIR/nested-result-artifacts"
cp -a "$GOOD_ARTIFACTS" "$NESTED_RESULT_ARTIFACTS"
mkdir -p "$NESTED_RESULT_ARTIFACTS/cells/ubuntu-24-04/git/nested"
printf '{}\n' > "$NESTED_RESULT_ARTIFACTS/cells/ubuntu-24-04/git/nested/result.json"
if validate_artifacts "$NESTED_RESULT_ARTIFACTS" "$TEMP_DIR/nested-result-output" \
  > /dev/null 2>&1; then
  printf 'A nested reserved result filename unexpectedly validated.\n' >&2
  exit 1
fi

SYMLINK_ARTIFACTS="$TEMP_DIR/symlink-artifacts"
cp -a "$GOOD_ARTIFACTS" "$SYMLINK_ARTIFACTS"
ln -s "$TEMP_DIR/external-artifact-secret" \
  "$SYMLINK_ARTIFACTS/cells/ubuntu-24-04/git/escape-link"
if validate_artifacts "$SYMLINK_ARTIFACTS" "$TEMP_DIR/symlink-output" \
  > /dev/null 2>&1; then
  printf 'An aggregate evidence symlink unexpectedly validated.\n' >&2
  exit 1
fi

printf 'tampered\n' >> "$CELL_DIR/container.log"
if validate_artifacts "$TEMP_DIR/artifacts" "$OUTPUT_DIR" > /dev/null 2>&1; then
  printf 'Tampered evidence unexpectedly passed validation.\n' >&2
  exit 1
fi

FAILURE_DIR="$TEMP_DIR/structured-failure"
if LSI_EVIDENCE_DIR="$FAILURE_DIR" \
  LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
  bash "$ROOT_DIR/tests/module-evidence.sh" "$ROOT_DIR" does-not-exist \
  > /dev/null 2>&1; then
  printf 'An invalid module unexpectedly produced successful evidence.\n' >&2
  exit 1
fi
grep -q $'^result\tfailed$' "$FAILURE_DIR/raw-execution.tsv"
grep -q $'^failure_stage\tdetect-and-contract$' "$FAILURE_DIR/raw-execution.tsv"
grep -Eq $'^exit_code\t[1-9][0-9]*$' "$FAILURE_DIR/raw-execution.tsv"

assert_sanitize_report() {
  local report=$1
  local expected_result=$2
  local expected_code=${3:-}
  "$PYTHON" - "$report" "$expected_result" "$expected_code" << 'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as stream:
    report = json.load(stream)
assert report["schema"] == "linux-software-installer/sanitize-tree-report/v1"
assert report["result"] == sys.argv[2]
if sys.argv[3]:
    assert report["errors"][0]["code"] == sys.argv[3]
else:
    assert report["errors"] == []
PY
}

SECRET_MARKER='SANITIZER-MUST-NOT-READ-THIS-EXTERNAL-SECRET'
SECRET_FILE="$TEMP_DIR/external-secret.txt"
SYMLINK_SOURCE="$TEMP_DIR/sanitize-symlink-source"
SYMLINK_DESTINATION="$TEMP_DIR/sanitize-symlink-destination"
mkdir -p "$SYMLINK_SOURCE"
printf '%s\n' "$SECRET_MARKER" > "$SECRET_FILE"
ln -s "$SECRET_FILE" "$SYMLINK_SOURCE/escape"
if "$PYTHON" "$ROOT_DIR/tests/evidence-record.py" sanitize-tree \
  --source "$SYMLINK_SOURCE" --destination "$SYMLINK_DESTINATION" \
  > /dev/null 2>&1; then
  printf 'A source symlink unexpectedly passed sanitization.\n' >&2
  exit 1
fi
assert_sanitize_report \
  "$SYMLINK_DESTINATION/sanitize-report.json" rejected unsupported-file-type
if [[ -e "$SYMLINK_DESTINATION/escape" || -L "$SYMLINK_DESTINATION/escape" ]]; then
  printf 'A rejected source symlink was copied.\n' >&2
  exit 1
fi
if grep -R -F -q -- "$SECRET_MARKER" "$SYMLINK_DESTINATION"; then
  printf 'External secret content leaked into sanitizer output.\n' >&2
  exit 1
fi

FIFO_SOURCE="$TEMP_DIR/sanitize-fifo-source"
FIFO_DESTINATION="$TEMP_DIR/sanitize-fifo-destination"
mkdir -p "$FIFO_SOURCE"
mkfifo "$FIFO_SOURCE/blocked.pipe"
set +e
if command -v timeout > /dev/null 2>&1; then
  timeout 5s "$PYTHON" "$ROOT_DIR/tests/evidence-record.py" sanitize-tree \
    --source "$FIFO_SOURCE" --destination "$FIFO_DESTINATION" \
    > /dev/null 2>&1
else
  "$PYTHON" "$ROOT_DIR/tests/evidence-record.py" sanitize-tree \
    --source "$FIFO_SOURCE" --destination "$FIFO_DESTINATION" \
    > /dev/null 2>&1
fi
FIFO_STATUS=$?
set -e
if [[ $FIFO_STATUS -eq 0 ]]; then
  printf 'A FIFO unexpectedly passed sanitization.\n' >&2
  exit 1
elif [[ $FIFO_STATUS -eq 124 ]]; then
  printf 'FIFO sanitization hung instead of rejecting the entry.\n' >&2
  exit 1
fi
assert_sanitize_report \
  "$FIFO_DESTINATION/sanitize-report.json" rejected unsupported-file-type

HARDLINK_SOURCE="$TEMP_DIR/sanitize-hardlink-source"
HARDLINK_DESTINATION="$TEMP_DIR/sanitize-hardlink-destination"
mkdir -p "$HARDLINK_SOURCE"
printf 'linked payload\n' > "$HARDLINK_SOURCE/original.txt"
ln "$HARDLINK_SOURCE/original.txt" "$HARDLINK_SOURCE/second-name.txt"
if "$PYTHON" "$ROOT_DIR/tests/evidence-record.py" sanitize-tree \
  --source "$HARDLINK_SOURCE" --destination "$HARDLINK_DESTINATION" \
  > /dev/null 2>&1; then
  printf 'A multiply linked regular file unexpectedly passed sanitization.\n' >&2
  exit 1
fi
assert_sanitize_report \
  "$HARDLINK_DESTINATION/sanitize-report.json" rejected multiple-hard-links
if [[ -e "$HARDLINK_DESTINATION/original.txt" || -e "$HARDLINK_DESTINATION/second-name.txt" ]]; then
  printf 'A rejected hard-linked file was copied.\n' >&2
  exit 1
fi

DEEP_SOURCE="$TEMP_DIR/sanitize-deep-source"
DEEP_DESTINATION="$TEMP_DIR/sanitize-deep-destination"
deep_path=$DEEP_SOURCE
mkdir -p "$deep_path"
for ((depth = 0; depth < 70; depth++)); do
  deep_path="$deep_path/d"
  mkdir "$deep_path"
done
if "$PYTHON" "$ROOT_DIR/tests/evidence-record.py" sanitize-tree \
  --source "$DEEP_SOURCE" --destination "$DEEP_DESTINATION" \
  > /dev/null 2>&1; then
  printf 'An over-deep source tree unexpectedly passed sanitization.\n' >&2
  exit 1
fi
assert_sanitize_report \
  "$DEEP_DESTINATION/sanitize-report.json" rejected path-depth-limit

SAFE_SOURCE="$TEMP_DIR/sanitize-safe-source"
SAFE_DESTINATION="$TEMP_DIR/sanitize-safe-destination"
mkdir -p "$SAFE_SOURCE/private"
mkdir -p "$SAFE_DESTINATION/private"
chmod 0700 "$SAFE_SOURCE/private"
chmod 0700 "$SAFE_DESTINATION" "$SAFE_DESTINATION/private"
printf 'safe private log\n' > "$SAFE_SOURCE/private/container.log"
chmod 0600 "$SAFE_SOURCE/private/container.log"
"$PYTHON" "$ROOT_DIR/tests/evidence-record.py" sanitize-tree \
  --source "$SAFE_SOURCE" \
  --destination "$SAFE_DESTINATION" \
  --owner-uid "$(id -u)" \
  --owner-gid "$(id -g)" \
  > /dev/null
cmp "$SAFE_SOURCE/private/container.log" "$SAFE_DESTINATION/private/container.log"
[[ $(stat -c '%a' "$SAFE_DESTINATION") == 755 ]]
[[ $(stat -c '%a' "$SAFE_DESTINATION/private") == 755 ]]
[[ $(stat -c '%a' "$SAFE_DESTINATION/private/container.log") == 644 ]]
[[ $(stat -c '%a' "$SAFE_DESTINATION/sanitize-report.json") == 644 ]]
assert_sanitize_report "$SAFE_DESTINATION/sanitize-report.json" passed
if "$PYTHON" "$ROOT_DIR/tests/evidence-record.py" sanitize-tree \
  --source "$SAFE_SOURCE" --destination "$SAFE_DESTINATION" \
  > /dev/null 2>&1; then
  printf 'A reused sanitizer destination unexpectedly returned success.\n' >&2
  exit 1
fi

COLLISION_SOURCE="$TEMP_DIR/sanitize-collision-source"
COLLISION_DESTINATION="$TEMP_DIR/sanitize-collision-destination"
mkdir -p "$COLLISION_SOURCE" "$COLLISION_DESTINATION"
printf 'new file\n' > "$COLLISION_SOURCE/new.txt"
printf 'replacement\n' > "$COLLISION_SOURCE/same.txt"
printf 'keep original\n' > "$COLLISION_DESTINATION/same.txt"
if "$PYTHON" "$ROOT_DIR/tests/evidence-record.py" sanitize-tree \
  --source "$COLLISION_SOURCE" --destination "$COLLISION_DESTINATION" \
  > /dev/null 2>&1; then
  printf 'A destination file collision unexpectedly passed sanitization.\n' >&2
  exit 1
fi
assert_sanitize_report \
  "$COLLISION_DESTINATION/sanitize-report.json" rejected destination-file-collision
grep -qx 'keep original' "$COLLISION_DESTINATION/same.txt"
if [[ -e "$COLLISION_DESTINATION/new.txt" ]]; then
  printf 'Sanitization copied files before rejecting a destination collision.\n' >&2
  exit 1
fi
