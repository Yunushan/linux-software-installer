#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
export LC_ALL=C

ROOT_DIR=${1:-/workspace}
MODULE=${2:-}
EVIDENCE_DIR=${LSI_EVIDENCE_DIR:-/tmp/module-evidence}
RAW_FILE="$EVIDENCE_DIR/raw-execution.tsv"
STAGES_FILE="$EVIDENCE_DIR/stages.tsv"
CURRENT_STAGE=bootstrap
RESULT=failed
STARTED_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
export LSI_PROJECT_ROOT="$ROOT_DIR"

[[ -n $MODULE ]] || {
  printf 'Usage: %s ROOT MODULE\n' "$0" >&2
  exit 2
}
mkdir -p "$EVIDENCE_DIR"
printf 'field\tvalue\n' > "$RAW_FILE"
printf 'stage\tstatus\ttimestamp\texit_code\n' > "$STAGES_FILE"

sanitize_field() {
  local value=$1
  value=${value//$'\t'/ }
  value=${value//$'\r'/ }
  value=${value//$'\n'/ }
  printf '%s' "$value"
}

metadata() {
  printf '%s\t%s\n' "$1" "$(sanitize_field "$2")" >> "$RAW_FILE"
}

stage_begin() {
  CURRENT_STAGE=$1
  printf '%s\trunning\t%s\t-\n' "$CURRENT_STAGE" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$STAGES_FILE"
}

stage_pass() {
  printf '%s\tpassed\t%s\t0\n' "$CURRENT_STAGE" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$STAGES_FILE"
}

finish_record() {
  local code=$?
  trap - EXIT
  if [[ $RESULT != success ]]; then
    ((code != 0)) || code=1
    printf '%s\tfailed\t%s\t%d\n' "$CURRENT_STAGE" \
      "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$code" >> "$STAGES_FILE"
  fi
  metadata finished_at "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  metadata result "$RESULT"
  metadata exit_code "$code"
  if [[ $RESULT == success ]]; then
    metadata failure_stage '-'
  else
    metadata failure_stage "$CURRENT_STAGE"
  fi
  exit "$code"
}
trap finish_record EXIT

metadata schema_version '1'
metadata started_at "$STARTED_AT"
metadata tested_commit "${LSI_TESTED_COMMIT:-local-uncommitted}"
metadata workflow_run_url "${LSI_RUN_URL:-local}"
metadata target_id "${LSI_TARGET_ID:-local}"
metadata image_ref "${LSI_IMAGE_REF:-local}"
metadata image_id "${LSI_IMAGE_ID:-unknown}"
metadata module "$MODULE"

# shellcheck source=../lib/common.sh
source "$ROOT_DIR/lib/common.sh"
# shellcheck source=../lib/os.sh
source "$ROOT_DIR/lib/os.sh"
# shellcheck source=../lib/catalog.sh
source "$ROOT_DIR/lib/catalog.sh"

snapshot_packages() {
  local destination=$1
  case "$LSI_OS_FAMILY" in
    debian)
      # ${Package} omits the architecture suffix, which makes multiarch
      # package snapshots ambiguous (for example steam-libs on amd64+i386).
      # Preserve dpkg's canonical binary package identity for a sorted,
      # unambiguous evidence table.
      dpkg-query -W -f='${binary:Package}\t${Version}\n' | sort > "$destination"
      ;;
    rhel)
      rpm -qa --qf '%{NAME}\t%{EPOCHNUM}:%{VERSION}-%{RELEASE}.%{ARCH}\n' |
        sort > "$destination"
      ;;
  esac
}

snapshot_foreign_architectures() {
  local destination=$1
  case "$LSI_OS_FAMILY" in
    debian) dpkg --print-foreign-architectures | LC_ALL=C sort > "$destination" ;;
    rhel) : > "$destination" ;;
  esac
}

verify_binaries() {
  local destination=$1 binary path
  printf 'binary\tpath\n' > "$destination"
  for binary in "${binaries[@]}"; do
    path=$(lsi_resolve_verification_binary "$binary") || {
      printf 'Declared verification command is unavailable: %s\n' "$binary" >&2
      return 6
    }
    printf '%s\t%s\n' "$binary" "$path" >> "$destination"
  done
}

stage_begin detect-and-contract
lsi_detect_os
lsi_validate_os_support
lsi_load_module "$MODULE"
lsi_module_supports_current_target ||
  lsi_die "Module $MODULE does not support target $(lsi_current_target_label)." 3

declare -a packages=() binaries=() services=() foreign_architectures=() foreign_options=()
case "$LSI_OS_FAMILY" in
  debian)
    binaries=("${MODULE_DEBIAN_VERIFY_BINARIES[@]}")
    services=("${MODULE_DEBIAN_SERVICES[@]}")
    foreign_architectures=("${MODULE_DEBIAN_FOREIGN_ARCHITECTURES[@]}")
    ;;
  rhel)
    binaries=("${MODULE_RHEL_VERIFY_BINARIES[@]}")
    services=("${MODULE_RHEL_SERVICES[@]}")
    ;;
esac
mapfile -t packages < <(lsi_module_packages)
((${#binaries[@]} > 0)) || binaries=("${MODULE_VERIFY_BINARIES[@]}")

metadata os_id "$LSI_OS_ID"
metadata os_version "$LSI_OS_VERSION_ID"
metadata os_pretty_name "$LSI_OS_PRETTY_NAME"
metadata architecture "$LSI_ARCH"
metadata family "$LSI_OS_FAMILY"
cp /etc/os-release "$EVIDENCE_DIR/os-release.txt"
cp "$ROOT_DIR/modules/$MODULE/module.sh" "$EVIDENCE_DIR/module.sh"
{
  printf 'type\tvalue\n'
  printf 'package\t%s\n' "${packages[@]}"
  printf 'verification_binary\t%s\n' "${binaries[@]}"
  ((${#services[@]} == 0)) || printf 'service\t%s\n' "${services[@]}"
  ((${#foreign_architectures[@]} == 0)) ||
    printf 'foreign_architecture\t%s\n' "${foreign_architectures[@]}"
} > "$EVIDENCE_DIR/module-contract.tsv"
stage_pass

stage_begin snapshot-before-install
snapshot_packages "$EVIDENCE_DIR/packages-before-install.tsv"
stage_pass

stage_begin initial-install
for architecture in "${foreign_architectures[@]}"; do
  foreign_options+=(--allow-foreign-architecture "$architecture")
done
"$ROOT_DIR/install.sh" install --yes "${foreign_options[@]}" "$MODULE"
stage_pass

stage_begin foreign-architecture-check-after-install
snapshot_foreign_architectures "$EVIDENCE_DIR/foreign-architectures-after-install.txt"
stage_pass

stage_begin binary-check-after-install
verify_binaries "$EVIDENCE_DIR/binary-paths-after-install.tsv"
stage_pass

stage_begin snapshot-after-install
snapshot_packages "$EVIDENCE_DIR/packages-after-install.tsv"
stage_pass

stage_begin package-source-capture
: > "$EVIDENCE_DIR/package-sources.txt"
for package in "${packages[@]}"; do
  printf '===== %s =====\n' "$package" >> "$EVIDENCE_DIR/package-sources.txt"
  case "$LSI_OS_FAMILY" in
    debian) apt-cache policy "$package" >> "$EVIDENCE_DIR/package-sources.txt" ;;
    rhel) dnf -q info installed "$package" >> "$EVIDENCE_DIR/package-sources.txt" ;;
  esac
done
stage_pass

stage_begin repeat-install
"$ROOT_DIR/install.sh" install --yes --no-refresh "${foreign_options[@]}" "$MODULE"
stage_pass

stage_begin foreign-architecture-check-after-repeat
snapshot_foreign_architectures "$EVIDENCE_DIR/foreign-architectures-after-repeat.txt"
stage_pass

stage_begin binary-check-after-repeat
verify_binaries "$EVIDENCE_DIR/binary-paths-after-repeat.tsv"
stage_pass

stage_begin snapshot-after-repeat
snapshot_packages "$EVIDENCE_DIR/packages-after-repeat.tsv"
stage_pass

stage_begin repeat-state-compare
after_install_digest=$(sha256sum "$EVIDENCE_DIR/packages-after-install.tsv")
after_install_digest=${after_install_digest%% *}
after_repeat_digest=$(sha256sum "$EVIDENCE_DIR/packages-after-repeat.tsv")
after_repeat_digest=${after_repeat_digest%% *}
if [[ $after_install_digest != "$after_repeat_digest" ]]; then
  printf 'Package state changed during the repeat installation.\n' >&2
  if command -v diff > /dev/null 2>&1; then
    diff -u "$EVIDENCE_DIR/packages-after-install.tsv" \
      "$EVIDENCE_DIR/packages-after-repeat.tsv" >&2 || true
  fi
  exit 1
fi
stage_pass

CURRENT_STAGE=complete
RESULT=success
printf 'Standalone evidence passed for %s on %s.\n' "$MODULE" "$LSI_OS_PRETTY_NAME"
