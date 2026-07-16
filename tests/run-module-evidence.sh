#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
export LC_ALL=C

ROOT_DIR=${1:-}
SCOPE=${2:-}
MODULE=${3:-}
OUTPUT_DIR=${4:-}
TARGETS_FILE="$ROOT_DIR/tests/evidence-targets.tsv"
RAW_ROOT=${LSI_RAW_EVIDENCE_ROOT:-${OUTPUT_DIR}.raw}
export LSI_PROJECT_ROOT="$ROOT_DIR"

[[ -n $ROOT_DIR && -n $MODULE && -n $OUTPUT_DIR ]] || {
  printf 'Usage: %s ROOT {all|debian|rhel} MODULE OUTPUT_DIR\n' "$0" >&2
  exit 2
}
# shellcheck source=python.sh
source "$ROOT_DIR/tests/python.sh"
[[ $SCOPE == all || $SCOPE == debian || $SCOPE == rhel ]] || {
  printf 'Invalid evidence scope: %s\n' "$SCOPE" >&2
  exit 2
}
command -v docker > /dev/null 2>&1 || {
  printf 'docker is required for standalone module evidence.\n' >&2
  exit 2
}
PYTHON=$(lsi_find_python) || {
  printf 'Python 3.8 or newer is required for standalone module evidence.\n' >&2
  exit 2
}
command -v timeout > /dev/null 2>&1 || {
  printf 'timeout is required for bounded standalone module evidence.\n' >&2
  exit 2
}

# shellcheck source=../lib/common.sh
source "$ROOT_DIR/lib/common.sh"
# shellcheck source=../lib/catalog.sh
source "$ROOT_DIR/lib/catalog.sh"

lsi_valid_slug "$MODULE" || lsi_die "Invalid module: $MODULE" 2
lsi_load_module "$MODULE"
if [[ $SCOPE != all ]]; then
  lsi_module_supports_family "$SCOPE" ||
    lsi_die "Module $MODULE does not support evidence scope $SCOPE." 2
fi
[[ -r $TARGETS_FILE ]] || lsi_die "Cannot read evidence targets: $TARGETS_FILE" 3
if ! "$PYTHON" - "$OUTPUT_DIR" "$RAW_ROOT" << 'PY'; then
import os
import sys

output = os.path.realpath(sys.argv[1])
raw = os.path.realpath(sys.argv[2])
common = os.path.commonpath((output, raw))
raise SystemExit(1 if common in {output, raw} else 0)
PY
  lsi_die 'Raw and uploadable evidence roots must be disjoint.' 3
fi
mkdir -p "$OUTPUT_DIR/cells" "$RAW_ROOT"
[[ -d $OUTPUT_DIR && ! -L $OUTPUT_DIR && -d $RAW_ROOT && ! -L $RAW_ROOT ]] ||
  lsi_die 'Evidence output paths must be real directories, not symlinks.' 3

expected_targets_header=$'target_id\tref_env\tdisplay_name\tfamily\timage\tplatform\texpected_os_id\texpected_version_id\texpected_arch'
IFS= read -r targets_header < "$TARGETS_FILE" || lsi_die 'Evidence target table is empty.' 3
targets_header=${targets_header%$'\r'}
[[ $targets_header == "$expected_targets_header" ]] ||
  lsi_die 'Evidence target table has an unexpected header.' 3

artifact_name=${LSI_ARTIFACT_NAME:-module-cell-$MODULE}
repository=${GITHUB_REPOSITORY:-local/repository}
commit=${GITHUB_SHA:-local-uncommitted}
source_ref=${GITHUB_REF:-local}
run_id=${GITHUB_RUN_ID:-local}
run_attempt=${GITHUB_RUN_ATTEMPT:-0}
run_url=${LSI_RUN_URL:-local}
active_container=''
failures=0
selected=0
runner_uid=$(id -u)
runner_gid=$(id -g)
declare -A seen_targets=()

cleanup_active_container() {
  [[ -z $active_container ]] ||
    bash "$ROOT_DIR/tests/remove-evidence-container.sh" "$active_container" \
      > /dev/null 2>&1 || true
}
trap cleanup_active_container EXIT

remove_current_container() {
  [[ -n $active_container ]] || return 0
  bash "$ROOT_DIR/tests/remove-evidence-container.sh" "$active_container" || return 1
  active_container=''
}

sanitize_cell() {
  local source=$1 destination=$2
  local -a command=("$PYTHON" "$ROOT_DIR/tests/evidence-record.py")
  if [[ ${LSI_SANITIZE_WITH_SUDO:-0} == 1 ]]; then
    command=(sudo --non-interactive "$PYTHON" "$ROOT_DIR/tests/evidence-record.py")
  fi
  "${command[@]}" sanitize-tree \
    --source "$source" \
    --destination "$destination" \
    --owner-uid "$runner_uid" \
    --owner-gid "$runner_gid"
}

validate_target_row() {
  local line=$1 rest=$1 fields=1
  while [[ $rest == *$'\t'* ]]; do
    rest=${rest#*$'\t'}
    fields=$((fields + 1))
  done
  [[ $fields -eq 9 && $line != *$'\r'* && $line != *$'\t\t'* ]] || return 1
  lsi_valid_slug "$target_id" && [[ -z ${seen_targets[$target_id]+x} ]] || return 1
  [[ $ref_env =~ ^[A-Z][A-Z0-9_]*$ ]] || return 1
  [[ -n $display_name && ! $display_name =~ [[:cntrl:]] ]] || return 1
  [[ $family == debian || $family == rhel ]] || return 1
  [[ $image =~ ^[A-Za-z0-9][A-Za-z0-9./:_-]*$ && $image != *..* ]] || return 1
  [[ $platform == linux/amd64 ]] || return 1
  lsi_valid_slug "$expected_os_id" || return 1
  [[ $expected_version_id =~ ^[0-9][A-Za-z0-9._-]*$ ]] || return 1
  [[ $expected_arch == x86_64 ]] || return 1
  seen_targets["$target_id"]=1
}

write_runner_record() {
  local destination=$1 runner_stage=$2 pull_exit=$3 container_exit=$4
  local image_id=$5 image_arch=$6 started_at=$7
  {
    printf 'field\tvalue\n'
    printf 'started_at\t%s\n' "$started_at"
    printf 'runner_stage\t%s\n' "$runner_stage"
    printf 'pull_exit_code\t%s\n' "$pull_exit"
    printf 'container_exit_code\t%s\n' "$container_exit"
    printf 'image_id\t%s\n' "$image_id"
    printf 'image_architecture\t%s\n' "$image_arch"
  } > "$destination"
}

while IFS= read -r target_row || [[ -n $target_row ]]; do
  [[ -n $target_row ]] || lsi_die 'Evidence target table contains a blank row.' 3
  IFS=$'\t' read -r target_id ref_env display_name family image platform \
    expected_os_id expected_version_id expected_arch <<< "$target_row"
  validate_target_row "$target_row" ||
    lsi_die "Invalid or duplicate evidence target row: ${target_id:-unknown}" 3
  [[ $SCOPE == all || $SCOPE == "$family" ]] || continue
  lsi_load_module "$MODULE"
  lsi_module_supports_target \
    "$family" "$expected_os_id" "$expected_version_id" "$expected_arch" || continue
  selected=$((selected + 1))

  cell_dir="$OUTPUT_DIR/cells/$target_id/$MODULE"
  raw_cell_dir="$RAW_ROOT/$target_id/$MODULE"
  raw_logs_dir="$raw_cell_dir/installer-logs"
  mkdir -p "$cell_dir" "$raw_logs_dir"
  bash "$ROOT_DIR/tests/evidence-contract.sh" "$ROOT_DIR" "$MODULE" "$family" \
    "$expected_os_id" "$expected_version_id" "$expected_arch" \
    > "$cell_dir/expected-module-contract.tsv"
  chmod 0644 "$cell_dir/expected-module-contract.tsv"
  started_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  image_ref=$(printenv "$ref_env" || true)
  image_id=''
  image_arch=''
  pull_status=125
  container_status=125
  runner_stage='image-reference'

  if [[ ! $image_ref =~ @sha256:[0-9a-f]{64}$ ]]; then
    printf 'Resolved image reference is missing or invalid for %s: %s\n' \
      "$target_id" "${image_ref:-missing}" | tee "$cell_dir/pull.log" >&2
  else
    runner_stage='image-pull'
    set +e
    timeout --signal=TERM --kill-after=30s 10m \
      docker pull --platform "$platform" "$image_ref" 2>&1 |
      tee "$cell_dir/pull.log"
    pull_status=${PIPESTATUS[0]}
    set -e

    if ((pull_status == 0)); then
      runner_stage='image-inspect'
      if image_id=$(docker image inspect --format '{{.Id}}' "$image_ref") &&
        image_arch=$(docker image inspect --format '{{.Architecture}}' "$image_ref"); then
        runner_stage='container-run'
        container_name="lsi-${target_id}-${MODULE}-${run_id}-${run_attempt}"
        active_container=$container_name
        set +e
        timeout --signal=TERM --kill-after=30s 40m \
          docker run --name "$container_name" --platform "$platform" \
          -v "$ROOT_DIR:/workspace:ro" \
          -v "$raw_cell_dir:/evidence" \
          -v "$raw_logs_dir:/var/log/linux-software-installer" \
          -e LSI_EVIDENCE_DIR=/evidence \
          -e LSI_TESTED_COMMIT="$commit" \
          -e LSI_TARGET_ID="$target_id" \
          -e LSI_IMAGE_REF="$image_ref" \
          -e LSI_IMAGE_ID="$image_id" \
          -e LSI_RUN_URL="$run_url" \
          "$image_ref" \
          bash /workspace/tests/module-evidence.sh /workspace "$MODULE" 2>&1 |
          tee "$cell_dir/container.log"
        container_status=${PIPESTATUS[0]}
        set -e
        if remove_current_container; then
          ((container_status == 0)) && runner_stage='container-complete'
        else
          runner_stage='container-cleanup'
        fi
      fi
    fi
  fi

  if [[ -z $active_container ]]; then
    if ! sanitize_cell "$raw_cell_dir" "$cell_dir"; then
      runner_stage='evidence-sanitization'
    fi
  else
    runner_stage='container-cleanup'
  fi

  write_runner_record "$cell_dir/runner.tsv" "$runner_stage" "$pull_status" \
    "$container_status" "$image_id" "$image_arch" "$started_at"

  finalize_args=(
    "$PYTHON" "$ROOT_DIR/tests/evidence-record.py" finalize-cell
    --cell-dir "$cell_dir"
    --repo-root "$ROOT_DIR"
    --target-id "$target_id"
    --display-name "$display_name"
    --family "$family"
    --module "$MODULE"
    --image-tag "$image"
    --image-ref "$image_ref"
    --image-id "$image_id"
    --image-arch "$image_arch"
    --platform "$platform"
    --expected-os-id "$expected_os_id"
    --expected-version-id "$expected_version_id"
    --expected-arch "$expected_arch"
    --repository "$repository"
    --commit "$commit"
    --ref "$source_ref"
    --run-id "$run_id"
    --run-attempt "$run_attempt"
    --run-url "$run_url"
    --artifact-name "$artifact_name"
    --runner-stage "$runner_stage"
    --container-exit "$container_status"
  )
  if ! "${finalize_args[@]}"; then
    failures=$((failures + 1))
  fi
  [[ -z $active_container ]] || break
done < <(tail -n +2 "$TARGETS_FILE")

((selected > 0)) || lsi_die "No evidence targets apply to $MODULE in scope $SCOPE." 2
if ((failures > 0)); then
  printf '%d of %d standalone evidence cells failed for %s.\n' \
    "$failures" "$selected" "$MODULE" >&2
  exit 1
fi
printf 'All %d standalone evidence cells passed for %s.\n' "$selected" "$MODULE"
