#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

ROOT_DIR=${1:-/workspace}
shift || true

declare -a modules=() foreign_options=()
export LSI_PROJECT_ROOT="$ROOT_DIR"
EVIDENCE_DIR=${LSI_EVIDENCE_DIR:-/tmp}
mkdir -p "$EVIDENCE_DIR"
command -v sha256sum > /dev/null 2>&1 || {
  printf 'sha256sum is required for package-state comparison.\n' >&2
  exit 2
}

# shellcheck source=../lib/common.sh
source "$ROOT_DIR/lib/common.sh"
# shellcheck source=../lib/os.sh
source "$ROOT_DIR/lib/os.sh"
# shellcheck source=../lib/catalog.sh
source "$ROOT_DIR/lib/catalog.sh"

lsi_detect_os
lsi_validate_os_support

snapshot_packages() {
  local destination=$1
  case "$LSI_OS_FAMILY" in
    debian)
      dpkg-query -W -f='${Package}\t${Version}\n' | LC_ALL=C sort > "$destination"
      ;;
    rhel)
      rpm -qa --qf '%{NAME}\t%{EPOCHNUM}:%{VERSION}-%{RELEASE}.%{ARCH}\n' |
        LC_ALL=C sort > "$destination"
      ;;
  esac
}

if [[ ${1:-} == --catalog-batch ]]; then
  [[ ${2:-} =~ ^[0-9]+$ ]] || {
    printf '%s\n' 'A numeric catalog batch index is required.' >&2
    exit 2
  }
  batch_output=$(lsi_catalog_batch_modules "$LSI_OS_FAMILY" "$2" 2 \
    "$LSI_OS_ID" "$LSI_OS_VERSION_ID" "$LSI_ARCH") || exit
  mapfile -t modules <<< "$batch_output"
elif [[ ${1:-} == --all-except ]]; then
  shift
  declare -A excluded=()
  for module in "$@"; do
    excluded["$module"]=1
  done

  lsi_discover_modules
  for module in "${LSI_MODULE_IDS[@]}"; do
    [[ -z ${excluded[$module]+x} ]] || continue
    lsi_load_module "$module"
    lsi_module_supports_current_target && modules+=("$module")
  done
else
  modules=("$@")
fi

((${#modules[@]} > 0)) || {
  printf 'Usage: %s ROOT MODULE... | ROOT --catalog-batch INDEX | ROOT --all-except MODULE...\n' "$0" >&2
  exit 2
}

declare -A requested_foreign_architectures=()
for module in "${modules[@]}"; do
  lsi_load_module "$module"
  while IFS= read -r architecture; do
    [[ -n $architecture ]] && requested_foreign_architectures["$architecture"]=1
  done < <(lsi_module_debian_foreign_architectures)
done
for architecture in "${!requested_foreign_architectures[@]}"; do
  foreign_options+=(--allow-foreign-architecture "$architecture")
done

printf 'Installing %d modules: %s\n' "${#modules[@]}" "${modules[*]}"
printf '%s\n' "${modules[@]}" > "$EVIDENCE_DIR/selected-modules.txt"
"$ROOT_DIR/install.sh" install --yes "${foreign_options[@]}" "${modules[@]}"
snapshot_packages "$EVIDENCE_DIR/packages-before-repeat.tsv"

printf 'Repeating the same installation and comparing package state.\n'
"$ROOT_DIR/install.sh" install --yes --no-refresh "${foreign_options[@]}" "${modules[@]}"
snapshot_packages "$EVIDENCE_DIR/packages-after-repeat.tsv"

before_digest=$(sha256sum "$EVIDENCE_DIR/packages-before-repeat.tsv")
before_digest=${before_digest%% *}
after_digest=$(sha256sum "$EVIDENCE_DIR/packages-after-repeat.tsv")
after_digest=${after_digest%% *}

if [[ $before_digest != "$after_digest" ]]; then
  printf 'Package state changed during the repeat installation:\n' >&2
  printf '  before: %s\n  after:  %s\n' \
    "$before_digest" "$after_digest" >&2
  if command -v diff > /dev/null 2>&1; then
    diff -u \
      "$EVIDENCE_DIR/packages-before-repeat.tsv" \
      "$EVIDENCE_DIR/packages-after-repeat.tsv" >&2 || true
  fi
  exit 1
fi

printf 'Real-install, binary-presence and repeat-state smoke test passed for %d modules.\n' \
  "${#modules[@]}"
