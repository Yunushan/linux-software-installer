#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
export LC_ALL=C

ROOT_DIR=${1:-}
MODULE=${2:-}
FAMILY=${3:-}
TARGET_OS_ID=${4:-}
TARGET_VERSION_ID=${5:-}
TARGET_ARCH=${6:-}
export LSI_PROJECT_ROOT="$ROOT_DIR"

[[ -n $ROOT_DIR && -n $MODULE && ($FAMILY == debian || $FAMILY == rhel) &&
  ($# -eq 3 || $# -eq 6) ]] || {
  printf 'Usage: %s ROOT MODULE {debian|rhel} [OS_ID VERSION_ID ARCH]\n' "$0" >&2
  exit 2
}

# shellcheck source=../lib/common.sh
source "$ROOT_DIR/lib/common.sh"
# shellcheck source=../lib/catalog.sh
source "$ROOT_DIR/lib/catalog.sh"

lsi_valid_slug "$MODULE" || lsi_die "Invalid module: $MODULE" 2
lsi_load_module "$MODULE"
lsi_module_supports_family "$FAMILY" ||
  lsi_die "Module $MODULE does not support $FAMILY." 2
if (($# == 6)); then
  lsi_module_supports_target \
    "$FAMILY" "$TARGET_OS_ID" "$TARGET_VERSION_ID" "$TARGET_ARCH" ||
    lsi_die "Module $MODULE does not support target $TARGET_OS_ID:$TARGET_VERSION_ID:$TARGET_ARCH." 2
elif lsi_module_has_target_restrictions; then
  lsi_die "Restricted module $MODULE requires an exact target cell for evidence contracts." 2
fi

declare -a packages=() binaries=() services=()
case "$FAMILY" in
  debian)
    binaries=("${MODULE_DEBIAN_VERIFY_BINARIES[@]}")
    services=("${MODULE_DEBIAN_SERVICES[@]}")
    ;;
  rhel)
    binaries=("${MODULE_RHEL_VERIFY_BINARIES[@]}")
    services=("${MODULE_RHEL_SERVICES[@]}")
    ;;
esac
mapfile -t packages < <(lsi_module_packages_for_target \
  "$FAMILY" "$TARGET_OS_ID" "$TARGET_VERSION_ID" "$TARGET_ARCH")
((${#binaries[@]} > 0)) || binaries=("${MODULE_VERIFY_BINARIES[@]}")

printf 'type\tvalue\n'
printf 'package\t%s\n' "${packages[@]}"
printf 'verification_binary\t%s\n' "${binaries[@]}"
((${#services[@]} == 0)) || printf 'service\t%s\n' "${services[@]}"
