#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

ROOT_DIR=${1:-/workspace}
MODE=${2:-}
SCOPE=${3:-}
FILTER_MODULE=${4:-}
TARGETS_FILE="$ROOT_DIR/tests/evidence-targets.tsv"
export LSI_PROJECT_ROOT="$ROOT_DIR"

# shellcheck source=../lib/common.sh
source "$ROOT_DIR/lib/common.sh"
# shellcheck source=../lib/catalog.sh
source "$ROOT_DIR/lib/catalog.sh"

usage() {
  printf 'Usage: %s ROOT {matrix|cells} {all|debian|rhel} [MODULE]\n' "$0" >&2
  exit 2
}

[[ $MODE == matrix || $MODE == cells ]] || usage
[[ $SCOPE == all || $SCOPE == debian || $SCOPE == rhel ]] || usage
[[ -r $TARGETS_FILE ]] || lsi_die "Cannot read evidence targets: $TARGETS_FILE" 3

expected_header=$'target_id\tref_env\tdisplay_name\tfamily\timage\tplatform\texpected_os_id\texpected_version_id\texpected_arch'
IFS= read -r targets_header < "$TARGETS_FILE" || lsi_die 'Evidence target table is empty.' 3
targets_header=${targets_header%$'\r'}
[[ $targets_header == "$expected_header" ]] || lsi_die 'Evidence target table has an unexpected header.' 3

if [[ -n $FILTER_MODULE ]]; then
  lsi_valid_slug "$FILTER_MODULE" || lsi_die "Invalid module filter: $FILTER_MODULE" 2
  [[ -f $ROOT_DIR/modules/$FILTER_MODULE/module.sh ]] || lsi_die "Unknown module filter: $FILTER_MODULE" 2
fi

declare -a TARGET_IDS=() TARGET_REF_ENVS=() TARGET_DISPLAY_NAMES=()
declare -a TARGET_FAMILIES=() TARGET_IMAGES=() TARGET_PLATFORMS=()
declare -a TARGET_OS_IDS=() TARGET_VERSION_IDS=() TARGET_ARCHES=()
declare -A seen_targets=()

while IFS= read -r target_row || [[ -n $target_row ]]; do
  [[ -n $target_row ]] || lsi_die 'Evidence target table contains a blank row.' 3
  rest=$target_row
  fields=1
  while [[ $rest == *$'\t'* ]]; do
    rest=${rest#*$'\t'}
    fields=$((fields + 1))
  done
  [[ $fields -eq 9 && $target_row != *$'\r'* && $target_row != *$'\t\t'* ]] ||
    lsi_die 'Evidence target table contains an invalid row.' 3
  IFS=$'\t' read -r target_id ref_env display_name family image platform \
    expected_os_id expected_version_id expected_arch <<< "$target_row"
  lsi_valid_slug "$target_id" || lsi_die "Invalid evidence target ID: $target_id" 3
  [[ -z ${seen_targets[$target_id]+x} ]] || lsi_die "Duplicate evidence target: $target_id" 3
  seen_targets["$target_id"]=1
  [[ $ref_env =~ ^[A-Z][A-Z0-9_]*$ ]] || lsi_die "Invalid target ref environment name: $ref_env" 3
  [[ -n $display_name && ! $display_name =~ [[:cntrl:]] ]] ||
    lsi_die "Invalid target display name: $target_id" 3
  [[ $family == debian || $family == rhel ]] || lsi_die "Invalid target family: $family" 3
  [[ -n $image && $platform == linux/amd64 ]] || lsi_die "Incomplete evidence target: $target_id" 3
  lsi_valid_slug "$expected_os_id" || lsi_die "Invalid target OS ID: $target_id" 3
  [[ $expected_version_id =~ ^[0-9][a-zA-Z0-9._-]*$ ]] ||
    lsi_die "Invalid target version: $target_id" 3
  lsi_known_target_architecture "$expected_arch" ||
    lsi_die "Unknown target architecture: $expected_arch" 3
  target_family=$(lsi_target_id_family "$expected_os_id") ||
    lsi_die "Unknown target OS ID: $expected_os_id" 3
  [[ $target_family == "$family" ]] ||
    lsi_die "Target $target_id has inconsistent OS ID and family." 3

  TARGET_IDS+=("$target_id")
  TARGET_REF_ENVS+=("$ref_env")
  TARGET_DISPLAY_NAMES+=("$display_name")
  TARGET_FAMILIES+=("$family")
  TARGET_IMAGES+=("$image")
  TARGET_PLATFORMS+=("$platform")
  TARGET_OS_IDS+=("$expected_os_id")
  TARGET_VERSION_IDS+=("$expected_version_id")
  TARGET_ARCHES+=("$expected_arch")
done < <(tail -n +2 "$TARGETS_FILE")

module_has_scoped_target() {
  local index family
  for index in "${!TARGET_IDS[@]}"; do
    family=${TARGET_FAMILIES[$index]}
    [[ $SCOPE == all || $SCOPE == "$family" ]] || continue
    lsi_module_supports_target "$family" \
      "${TARGET_OS_IDS[$index]}" "${TARGET_VERSION_IDS[$index]}" \
      "${TARGET_ARCHES[$index]}" && return 0
  done
  return 1
}

declare -a ordered_modules=() selected_modules=()
lsi_discover_modules
mapfile -t ordered_modules < <(printf '%s\n' "${LSI_MODULE_IDS[@]}" | sort)

for module in "${ordered_modules[@]}"; do
  [[ -z $FILTER_MODULE || $module == "$FILTER_MODULE" ]] || continue
  lsi_load_module "$module"
  module_has_scoped_target && selected_modules+=("$module")
done

((${#selected_modules[@]} > 0)) ||
  lsi_die 'The requested module has no supported target in the selected scope.' 2

if [[ $MODE == matrix ]]; then
  first=true
  printf '{"include":['
  for module in "${selected_modules[@]}"; do
    [[ $first == true ]] || printf ','
    first=false
    printf '{"module":"%s"}' "$module"
  done
  printf ']}\n'
  exit 0
fi

printf 'cell_id\ttarget_id\tfamily\tmodule\timage\tplatform\texpected_os_id\texpected_version_id\texpected_arch\n'
for index in "${!TARGET_IDS[@]}"; do
  target_id=${TARGET_IDS[$index]}
  family=${TARGET_FAMILIES[$index]}
  [[ $SCOPE == all || $SCOPE == "$family" ]] || continue
  for module in "${selected_modules[@]}"; do
    lsi_load_module "$module"
    lsi_module_supports_target "$family" \
      "${TARGET_OS_IDS[$index]}" "${TARGET_VERSION_IDS[$index]}" \
      "${TARGET_ARCHES[$index]}" || continue
    printf '%s/%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$target_id" "$module" "$target_id" "$family" "$module" \
      "${TARGET_IMAGES[$index]}" "${TARGET_PLATFORMS[$index]}" \
      "${TARGET_OS_IDS[$index]}" "${TARGET_VERSION_IDS[$index]}" \
      "${TARGET_ARCHES[$index]}"
  done
done
