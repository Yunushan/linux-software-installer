#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
export LC_ALL=C
umask 0077

ROOT_DIR=''
EXECUTION_ID=''
OUTPUT_DIR=''
TESTED_COMMIT=''
VM_IMAGE_REF=''
MARKER_FILE='/etc/linux-software-installer/systemd-evidence-vm.tsv'
TEST_MODE=${LSI_SYSTEMD_EVIDENCE_TEST_MODE:-0}

usage() {
  printf 'Usage: %s --root ROOT --execution-id ID --output DIR --tested-commit SHA --vm-image-ref REF [--marker FILE]\n' "$0" >&2
}

die() {
  printf 'systemd evidence runner failed: %s\n' "$*" >&2
  exit 1
}

while (($# > 0)); do
  case "$1" in
    --root | --execution-id | --output | --tested-commit | --vm-image-ref | --marker)
      (($# >= 2)) || {
        usage
        exit 2
      }
      case "$1" in
        --root) ROOT_DIR=$2 ;;
        --execution-id) EXECUTION_ID=$2 ;;
        --output) OUTPUT_DIR=$2 ;;
        --tested-commit) TESTED_COMMIT=$2 ;;
        --vm-image-ref) VM_IMAGE_REF=$2 ;;
        --marker) MARKER_FILE=$2 ;;
      esac
      shift 2
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

[[ -n $ROOT_DIR && -n $EXECUTION_ID && -n $OUTPUT_DIR && -n $TESTED_COMMIT && -n $VM_IMAGE_REF ]] || {
  usage
  exit 2
}
[[ $TEST_MODE == 0 || $TEST_MODE == 1 ]] || die 'test mode must be 0 or 1'
[[ $EXECUTION_ID =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || die 'execution ID is not a safe slug'
[[ $TESTED_COMMIT =~ ^([0-9a-f]{40}|[0-9a-f]{64})$ ]] || die 'tested commit is not a full Git object ID'
[[ $VM_IMAGE_REF =~ ^[^[:space:]@]+@sha256:[0-9a-f]{64}$ ]] ||
  die 'VM image reference must be an immutable sha256 digest'
[[ -d $ROOT_DIR && ! -L $ROOT_DIR ]] || die 'repository root is not a real directory'
ROOT_DIR=$(CDPATH='' cd -- "$ROOT_DIR" && pwd -P)
[[ -f $ROOT_DIR/install.sh && -f $ROOT_DIR/tests/systemd-evidence-matrix.sh ]] ||
  die 'repository root lacks the evidence runner dependencies'
for trusted_path in \
  "$ROOT_DIR/install.sh" \
  "$ROOT_DIR/lib/common.sh" \
  "$ROOT_DIR/lib/os.sh" \
  "$ROOT_DIR/tests/evidence-contract.sh" \
  "$ROOT_DIR/tests/systemd-evidence-matrix.sh" \
  "$ROOT_DIR/tests/systemd-evidence-matrix.py" \
  "$ROOT_DIR/tests/validate-legacy-promotion-readiness.sh" \
  "$ROOT_DIR/tests/validate-legacy-promotion-readiness.py"; do
  [[ -f $trusted_path && ! -L $trusted_path ]] ||
    die "trusted runner dependency is missing or symlinked: $trusted_path"
done

if [[ $TEST_MODE == 0 ]]; then
  [[ $MARKER_FILE == /etc/linux-software-installer/systemd-evidence-vm.tsv ]] ||
    die '--marker is allowed only for explicitly test-only evidence'
  for hook in \
    LSI_SYSTEMD_EVIDENCE_PROC_ROOT LSI_SYSTEMD_EVIDENCE_SYSTEMD_RUNTIME \
    LSI_SYSTEMD_EVIDENCE_OS_RELEASE_FILE LSI_SYSTEMD_EVIDENCE_BOOT_ID_FILE \
    LSI_SYSTEMD_EVIDENCE_SSH_ROOT LSI_SYSTEMD_EVIDENCE_INSTALLER \
    LSI_SYSTEMD_EVIDENCE_TEST_EUID; do
    [[ -z ${!hook:-} ]] || die "$hook is allowed only in marked test evidence"
  done
  PATH=/usr/sbin:/usr/bin:/sbin:/bin
  export PATH
  shopt -u expand_aliases
  unalias -a 2> /dev/null || true
  for command_name in git systemctl systemd-detect-virt dpkg-query rpm \
    sha256sum stat find sort cmp sed grep tee cut date mktemp env timeout ss; do
    if declare -F "$command_name" > /dev/null; then
      unset -f "$command_name" || die "could not clear unsafe command function: $command_name"
    fi
  done
  hash -r
  for unsafe_prefix in GIT_ PYTHON SYSTEMD_ DPKG_ RPM_ APT_ DNF_; do
    while IFS= read -r variable_name; do
      unset "$variable_name" ||
        die "could not clear unsafe environment variable: $variable_name"
    done < <(compgen -A variable "$unsafe_prefix")
  done
  while IFS= read -r variable_name; do
    unset "$variable_name" || die "could not clear installer environment variable: $variable_name"
  done < <(compgen -A variable LSI_)
  unset BASH_ENV ENV PYTHONHOME PYTHONPATH PYTHONSTARTUP PYTHONINSPECT PYTHONSAFEPATH \
    LD_AUDIT LD_LIBRARY_PATH LD_PRELOAD \
    CDPATH GREP_OPTIONS POSIXLY_CORRECT APT_CONFIG DNF_SYSTEM_UPGRADE_NO_REBOOT ||
    die 'could not clear unsafe process-control environment variables'
fi

PROC_ROOT=/proc
SYSTEMD_RUNTIME=/run/systemd/system
OS_RELEASE_FILE=/etc/os-release
BOOT_ID_FILE=/proc/sys/kernel/random/boot_id
SSH_ROOT=/etc/ssh
INSTALLER=$ROOT_DIR/install.sh
EFFECTIVE_UID=$EUID
if [[ $TEST_MODE == 1 ]]; then
  PROC_ROOT=${LSI_SYSTEMD_EVIDENCE_PROC_ROOT:-$PROC_ROOT}
  SYSTEMD_RUNTIME=${LSI_SYSTEMD_EVIDENCE_SYSTEMD_RUNTIME:-$SYSTEMD_RUNTIME}
  OS_RELEASE_FILE=${LSI_SYSTEMD_EVIDENCE_OS_RELEASE_FILE:-$OS_RELEASE_FILE}
  BOOT_ID_FILE=${LSI_SYSTEMD_EVIDENCE_BOOT_ID_FILE:-$BOOT_ID_FILE}
  SSH_ROOT=${LSI_SYSTEMD_EVIDENCE_SSH_ROOT:-$SSH_ROOT}
  INSTALLER=${LSI_SYSTEMD_EVIDENCE_INSTALLER:-$INSTALLER}
  EFFECTIVE_UID=${LSI_SYSTEMD_EVIDENCE_TEST_EUID:-$EFFECTIVE_UID}
fi

[[ $EFFECTIVE_UID == 0 ]] || die 'the VM evidence runner requires root'
for command_name in bash git sha256sum stat find sort systemctl systemd-detect-virt \
  cmp sed grep tee cut date mktemp env tail tr chmod mkdir cp rm uname; do
  command -v "$command_name" > /dev/null 2>&1 || die "required command is unavailable: $command_name"
done
if [[ $TEST_MODE == 0 ]]; then
  command -v timeout > /dev/null 2>&1 || die 'required command is unavailable: timeout'
  command -v ss > /dev/null 2>&1 || die 'required command is unavailable: ss'
fi

verify_source_checkout() {
  local actual_commit
  actual_commit=$(git -C "$ROOT_DIR" rev-parse HEAD 2> /dev/null) ||
    die 'repository has no checked-out commit'
  actual_commit=${actual_commit%$'\r'}
  [[ $actual_commit == "$TESTED_COMMIT" ]] ||
    die 'checked-out commit does not match tested commit'
  git -C "$ROOT_DIR" diff --quiet -- ||
    die 'checked-out source has unstaged modifications'
  git -C "$ROOT_DIR" diff --cached --quiet -- ||
    die 'checked-out source has staged modifications'
  [[ -z $(git -C "$ROOT_DIR" status --porcelain --untracked-files=all) ]] ||
    die 'checked-out source contains untracked files'
}

verify_source_checkout

PLAN_FILE=$(mktemp)
cleanup_plan() { rm -f "$PLAN_FILE"; }
trap cleanup_plan EXIT
bash "$ROOT_DIR/tests/systemd-evidence-matrix.sh" "$ROOT_DIR" plan > "$PLAN_FILE" ||
  die 'could not derive the trusted systemd evidence plan'
expected_plan_header=$'execution_id\ttarget_id\tdisplay_name\tfamily\tmodule\tmode\tstandalone_image_tag\tplatform\texpected_os_id\texpected_version_id\texpected_arch\tservices'
IFS= read -r plan_header < "$PLAN_FILE" || die 'systemd evidence plan is empty'
[[ $plan_header == "$expected_plan_header" ]] || die 'systemd evidence plan header is mismatched'

FOUND=0
TARGET_ID=''
DISPLAY_NAME=''
FAMILY=''
MODULE=''
MODE=''
STANDALONE_IMAGE_TAG=''
PLATFORM=''
EXPECTED_OS_ID=''
EXPECTED_VERSION_ID=''
EXPECTED_ARCH=''
SERVICE_CSV=''
while IFS=$'\t' read -r execution_id target_id display_name family module mode standalone_image_tag \
  platform expected_os_id expected_version_id expected_arch services; do
  [[ $execution_id == "$EXECUTION_ID" ]] || continue
  FOUND=$((FOUND + 1))
  TARGET_ID=$target_id
  DISPLAY_NAME=$display_name
  FAMILY=$family
  MODULE=$module
  MODE=$mode
  STANDALONE_IMAGE_TAG=$standalone_image_tag
  PLATFORM=$platform
  EXPECTED_OS_ID=$expected_os_id
  EXPECTED_VERSION_ID=$expected_version_id
  EXPECTED_ARCH=$expected_arch
  SERVICE_CSV=$services
done < <(tail -n +2 "$PLAN_FILE")
[[ $FOUND -eq 1 ]] || die 'execution ID is missing or duplicated in the trusted plan'
[[ $MODE == default || $MODE == enable-services ]] || die 'trusted plan contains an invalid mode'
[[ $PLATFORM == linux/amd64 && $EXPECTED_ARCH == x86_64 ]] ||
  die 'trusted plan contains an unsupported platform'
[[ -n $SERVICE_CSV ]] || die 'trusted plan contains an empty service contract'
[[ -f $ROOT_DIR/modules/$MODULE/module.sh && ! -L $ROOT_DIR/modules/$MODULE/module.sh ]] ||
  die 'planned module manifest is missing or symlinked'
case "$FAMILY" in
  debian) command -v dpkg-query > /dev/null 2>&1 || die 'dpkg-query is unavailable on the Debian-family target' ;;
  rhel) command -v rpm > /dev/null 2>&1 || die 'rpm is unavailable on the RHEL-family target' ;;
  *) die 'trusted plan contains an unsupported family' ;;
esac

[[ -r $PROC_ROOT/1/comm ]] || die 'cannot inspect PID 1'
PID1_COMM=$(tr -d '\r\n' < "$PROC_ROOT/1/comm")
[[ $PID1_COMM == systemd ]] || die 'PID 1 is not systemd; containers and non-systemd hosts are refused'
[[ -d $SYSTEMD_RUNTIME ]] || die 'systemd runtime directory is absent'
set +e
SYSTEMD_STATE=$(systemctl is-system-running 2> /dev/null)
SYSTEMD_STATE_EXIT=$?
set -e
[[ $SYSTEMD_STATE == running && $SYSTEMD_STATE_EXIT -eq 0 ]] ||
  die "systemd is not operational: ${SYSTEMD_STATE:-unknown} ($SYSTEMD_STATE_EXIT)"
set +e
VIRTUALIZATION=$(systemd-detect-virt --vm 2> /dev/null)
VIRTUALIZATION_EXIT=$?
set -e
[[ $VIRTUALIZATION_EXIT -eq 0 && -n $VIRTUALIZATION && $VIRTUALIZATION != none ]] ||
  die 'host is not identified as a virtual machine'
set +e
CONTAINER_DETECTION=$(systemd-detect-virt --container 2> /dev/null)
CONTAINER_EXIT=$?
CHROOT_DETECTION=$(systemd-detect-virt --chroot 2> /dev/null)
CHROOT_EXIT=$?
PRIVATE_USERS_DETECTION=$(systemd-detect-virt --private-users 2> /dev/null)
PRIVATE_USERS_EXIT=$?
FAILED_UNITS_BEFORE=$(systemctl --failed --no-legend --plain --no-pager 2>&1)
FAILED_UNITS_BEFORE_EXIT=$?
set -e
[[ $CONTAINER_EXIT -eq 1 && ($CONTAINER_DETECTION == none || -z $CONTAINER_DETECTION) ]] ||
  die 'containers are refused even when their underlying host is a VM'
[[ $CHROOT_EXIT -eq 1 ]] || die 'chroot environments are refused'
[[ $PRIVATE_USERS_EXIT -eq 1 ]] || die 'private user-namespace environments are refused'
[[ $FAILED_UNITS_BEFORE_EXIT -eq 0 && -z $FAILED_UNITS_BEFORE ]] ||
  die 'fresh evidence VM begins with failed systemd units'

export LSI_PROJECT_ROOT="$ROOT_DIR"
export LSI_OS_RELEASE_FILE="$OS_RELEASE_FILE"
# shellcheck source=../lib/common.sh
source "$ROOT_DIR/lib/common.sh"
# shellcheck source=../lib/os.sh
source "$ROOT_DIR/lib/os.sh"
LSI_FORCE_UNSUPPORTED=false
lsi_detect_os
[[ $LSI_OS_ID == "$EXPECTED_OS_ID" ]] || die "expected OS ID $EXPECTED_OS_ID, found $LSI_OS_ID"
[[ $LSI_OS_VERSION_ID == "$EXPECTED_VERSION_ID" ]] ||
  die "expected OS version ID $EXPECTED_VERSION_ID, found $LSI_OS_VERSION_ID"
[[ $LSI_OS_FAMILY == "$FAMILY" ]] || die "expected family $FAMILY, found $LSI_OS_FAMILY"
[[ $LSI_ARCH == "$EXPECTED_ARCH" ]] || die "expected architecture $EXPECTED_ARCH, found $LSI_ARCH"

if [[ $TEST_MODE == 0 ]]; then
  MARKER_PARENT=${MARKER_FILE%/*}
  [[ -d $MARKER_PARENT && ! -L $MARKER_PARENT &&
    $(CDPATH='' cd -- "$MARKER_PARENT" && pwd -P) == "$MARKER_PARENT" ]] ||
    die 'VM marker parent must be a canonical real directory'
  MARKER_PARENT_UID=$(stat -c '%u' -- "$MARKER_PARENT") ||
    die 'cannot inspect VM marker parent owner'
  MARKER_PARENT_MODE=$(stat -c '%a' -- "$MARKER_PARENT") ||
    die 'cannot inspect VM marker parent mode'
  [[ $MARKER_PARENT_UID == 0 && $MARKER_PARENT_MODE =~ ^[0-7]{3,4}$ ]] ||
    die 'VM marker parent must be root-owned with a valid mode'
  (((8#$MARKER_PARENT_MODE & 8#022) == 0)) ||
    die 'VM marker parent must not be group/world writable'
fi
[[ -f $MARKER_FILE && ! -L $MARKER_FILE ]] || die 'single-use VM provisioning marker is missing or unsafe'
MARKER_MODE=$(stat -c '%a' -- "$MARKER_FILE") || die 'cannot inspect VM marker mode'
MARKER_UID=$(stat -c '%u' -- "$MARKER_FILE") || die 'cannot inspect VM marker owner'
MARKER_LINKS=$(stat -c '%h' -- "$MARKER_FILE") || die 'cannot inspect VM marker links'
[[ $MARKER_MODE == 600 && $MARKER_LINKS == 1 ]] || die 'VM marker must be mode 0600 with one link'
[[ $TEST_MODE == 1 || $MARKER_UID == 0 ]] || die 'VM marker must be owned by root'

declare -A MARKER=()
IFS= read -r marker_header < "$MARKER_FILE" || die 'VM marker is empty'
[[ $marker_header == $'field\tvalue' ]] || die 'VM marker has an unexpected header'
while IFS= read -r marker_line; do
  [[ $marker_line == *$'\t'* && $marker_line != *$'\t'*$'\t'* &&
    $marker_line != $'\t'* && $marker_line != *$'\t' ]] ||
    die 'VM marker contains a malformed row'
  field=${marker_line%%$'\t'*}
  value=${marker_line#*$'\t'}
  [[ -z ${MARKER[$field]+x} ]] || die "VM marker repeats field: $field"
  MARKER["$field"]=$value
done < <(tail -n +2 "$MARKER_FILE")
EXPECTED_MARKER_FIELDS=(schema ephemeral single_use execution_id target_id tested_commit vm_image_ref boot_id nonce)
[[ ${#MARKER[@]} -eq ${#EXPECTED_MARKER_FIELDS[@]} ]] || die 'VM marker field set is incomplete'
for field in "${EXPECTED_MARKER_FIELDS[@]}"; do
  [[ -n ${MARKER[$field]+x} ]] || die "VM marker lacks field: $field"
done
[[ ${MARKER[schema]} == linux-software-installer/systemd-evidence-vm/v1 ]] || die 'VM marker schema is unsupported'
[[ ${MARKER[ephemeral]} == true && ${MARKER[single_use]} == true ]] ||
  die 'VM marker does not declare an ephemeral single-use host'
[[ ${MARKER[execution_id]} == "$EXECUTION_ID" && ${MARKER[target_id]} == "$TARGET_ID" ]] ||
  die 'VM marker execution or target identity is mismatched'
[[ ${MARKER[tested_commit]} == "$TESTED_COMMIT" ]] || die 'VM marker commit is mismatched'
[[ ${MARKER[vm_image_ref]} == "$VM_IMAGE_REF" ]] || die 'VM marker image identity is mismatched'
[[ ${MARKER[nonce]} =~ ^[0-9a-f]{32,64}$ ]] || die 'VM marker nonce is invalid'
[[ -r $BOOT_ID_FILE ]] || die 'cannot read VM boot ID'
BOOT_ID=$(tr -d '\r\n' < "$BOOT_ID_FILE")
[[ $BOOT_ID =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]] ||
  die 'VM boot ID is invalid'
[[ ${MARKER[boot_id]} == "$BOOT_ID" ]] || die 'VM marker belongs to a different boot'

[[ $OUTPUT_DIR == /* ]] || die 'output directory must be absolute'
OUTPUT_PARENT=${OUTPUT_DIR%/*}
OUTPUT_NAME=${OUTPUT_DIR##*/}
[[ -n $OUTPUT_PARENT && -n $OUTPUT_NAME && $OUTPUT_NAME =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] ||
  die 'output directory has an unsafe name'
[[ -d $OUTPUT_PARENT && ! -L $OUTPUT_PARENT ]] || die 'output parent must be an existing real directory'
CANONICAL_OUTPUT_PARENT=$(CDPATH='' cd -- "$OUTPUT_PARENT" && pwd -P) ||
  die 'cannot resolve output parent'
[[ $CANONICAL_OUTPUT_PARENT == "$OUTPUT_PARENT" ]] ||
  die 'output parent must be an absolute canonical path without symlink traversal'
[[ ! -e $OUTPUT_DIR && ! -L $OUTPUT_DIR ]] || die 'output directory already exists'

CONSUMED_MARKER=$MARKER_FILE.consumed
[[ ! -e $CONSUMED_MARKER && ! -L $CONSUMED_MARKER ]] || die 'VM provisioning marker was already consumed'
(
  set -o noclobber
  printf '%s\t%s\n' "$EXECUTION_ID" "${MARKER[nonce]}" > "$CONSUMED_MARKER"
) 2> /dev/null || die 'could not consume the single-use VM marker atomically'
chmod 0600 "$CONSUMED_MARKER"

mkdir "$OUTPUT_DIR" || die 'could not create evidence output directory'
chmod 0700 "$OUTPUT_DIR"
rm -f "$PLAN_FILE"
trap - EXIT

EXECUTION_FILE=$OUTPUT_DIR/execution.tsv
CHECKS_FILE=$OUTPUT_DIR/checks.tsv
CURRENT_STAGE=initialize
RESULT=failed
ACCEPTANCE_ELIGIBLE=false
STARTED_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

sanitize_value() {
  local value=$1
  value=${value//$'\t'/ }
  value=${value//$'\r'/ }
  value=${value//$'\n'/ }
  printf '%s' "$value"
}

record() {
  printf '%s\t%s\n' "$1" "$(sanitize_value "$2")" >> "$EXECUTION_FILE"
}

check_pass() {
  printf '%s\tpassed\t%s\n' "$1" "$(sanitize_value "$2")" >> "$CHECKS_FILE"
}

file_sha256() {
  local output digest
  output=$(sha256sum -- "$1") || return 1
  digest=${output%% *}
  [[ $digest =~ ^[0-9a-f]{64}$ ]] || return 1
  printf '%s' "$digest"
}

write_manifest() {
  local path relative digest
  [[ -z $(find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 ! -type f -print -quit) ]] ||
    return 1
  : > "$OUTPUT_DIR/files.sha256"
  while IFS= read -r path; do
    [[ -f $path && ! -L $path && $(stat -c '%h' -- "$path") == 1 ]] || return 1
    chmod 0644 "$path"
    relative=${path#"$OUTPUT_DIR"/}
    digest=$(file_sha256 "$path") || return 1
    printf '%s  %s\n' "$digest" "$relative" >> "$OUTPUT_DIR/files.sha256"
  done < <(find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -type f \
    ! -name files.sha256 -print | sort)
  chmod 0644 "$OUTPUT_DIR/files.sha256"
}

finish_record() {
  local code=$?
  trap - EXIT
  if [[ $RESULT == provisional || $RESULT == test-only ]]; then
    code=0
  else
    ((code != 0)) || code=1
  fi
  record finished_at "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  record result "$RESULT"
  record failure_stage "$([[ $RESULT == provisional || $RESULT == test-only ]] && printf '-' || printf '%s' "$CURRENT_STAGE")"
  record exit_code "$code"
  record acceptance_eligible "$ACCEPTANCE_ELIGIBLE"
  write_manifest || {
    printf 'systemd evidence runner failed: could not finalize evidence manifest\n' >&2
    code=1
  }
  exit "$code"
}
trap finish_record EXIT

printf 'field\tvalue\n' > "$EXECUTION_FILE"
printf 'check\tstatus\tdetail\n' > "$CHECKS_FILE"
record schema_version 1
record started_at "$STARTED_AT"
record execution_id "$EXECUTION_ID"
record target_id "$TARGET_ID"
record display_name "$DISPLAY_NAME"
record family "$FAMILY"
record module "$MODULE"
record mode "$MODE"
record standalone_image_tag "$STANDALONE_IMAGE_TAG"
record vm_image_ref "$VM_IMAGE_REF"
record tested_commit "$TESTED_COMMIT"
record boot_id "$BOOT_ID"
record virtualization "$VIRTUALIZATION"
record systemd_state "$SYSTEMD_STATE"
record container_detection none
record chroot_detection false
record private_users_detection false
record test_mode "$TEST_MODE"
record explicit_activation_requested "$([[ $MODE == enable-services ]] && printf true || printf false)"

cp -L "$OS_RELEASE_FILE" "$OUTPUT_DIR/os-release.txt"
cp "$MARKER_FILE" "$OUTPUT_DIR/provision-marker.tsv"
printf '%s' "$FAILED_UNITS_BEFORE" > "$OUTPUT_DIR/failed-units-before.txt"
printf '%s\n' "$expected_plan_header" > "$OUTPUT_DIR/plan-row.tsv"
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$EXECUTION_ID" "$TARGET_ID" "$DISPLAY_NAME" "$FAMILY" "$MODULE" "$MODE" \
  "$STANDALONE_IMAGE_TAG" "$PLATFORM" "$EXPECTED_OS_ID" "$EXPECTED_VERSION_ID" \
  "$EXPECTED_ARCH" "$SERVICE_CSV" >> "$OUTPUT_DIR/plan-row.tsv"
bash "$ROOT_DIR/tests/evidence-contract.sh" "$ROOT_DIR" "$MODULE" "$FAMILY" \
  "$EXPECTED_OS_ID" "$EXPECTED_VERSION_ID" "$EXPECTED_ARCH" \
  > "$OUTPUT_DIR/module-contract.tsv"

declare -a PACKAGES=() SERVICES=()
while IFS=$'\t' read -r type value; do
  [[ $type != type ]] || continue
  case "$type" in
    package) PACKAGES+=("$value") ;;
    service) SERVICES+=("$value") ;;
  esac
done < "$OUTPUT_DIR/module-contract.tsv"
[[ ${#PACKAGES[@]} -gt 0 && ${#SERVICES[@]} -gt 0 ]] || die 'module contract lacks packages or services'
[[ $(
  IFS=,
  printf '%s' "${SERVICES[*]}"
) == "$SERVICE_CSV" ]] || die 'module contract disagrees with trusted plan services'

check_pass host_identity "$LSI_OS_ID/$LSI_OS_VERSION_ID/$LSI_ARCH"
check_pass systemd_vm "$SYSTEMD_STATE/$VIRTUALIZATION"
check_pass provisioning_marker "single-use/${MARKER[nonce]}"
check_pass source_commit "$TESTED_COMMIT"

ssh_config_digest() {
  local file relative listing digest metadata
  if [[ ! -e $SSH_ROOT ]]; then
    printf 'absent'
    return 0
  fi
  [[ -d $SSH_ROOT && ! -L $SSH_ROOT ]] || return 1
  [[ -z $(find "$SSH_ROOT" -xdev \( -type l -o ! -type f ! -type d \) -print -quit) ]] || return 1
  listing=$(mktemp)
  : > "$listing"
  while IFS= read -r file; do
    relative=${file#"$SSH_ROOT"/}
    [[ $file != "$SSH_ROOT" ]] || relative=.
    metadata=$(stat -c '%a:%u:%g' -- "$file") || {
      rm -f "$listing"
      return 1
    }
    printf 'directory\t%s\t%s\n' "$metadata" "$relative" >> "$listing"
  done < <(find "$SSH_ROOT" -xdev -type d -print | sort)
  while IFS= read -r file; do
    [[ $(stat -c '%h' -- "$file") == 1 ]] || {
      rm -f "$listing"
      return 1
    }
    relative=${file#"$SSH_ROOT"/}
    metadata=$(stat -c '%a:%u:%g:%s' -- "$file") || {
      rm -f "$listing"
      return 1
    }
    digest=$(file_sha256 "$file") || {
      rm -f "$listing"
      return 1
    }
    printf 'file\t%s\t%s\t%s\n' "$metadata" "$digest" "$relative" >> "$listing"
  done < <(find "$SSH_ROOT" -xdev -type f -print | sort)
  digest=$(file_sha256 "$listing") || {
    rm -f "$listing"
    return 1
  }
  printf '%s' "$digest"
  rm -f "$listing"
}

command_digest() {
  local output_file status digest
  if ! command -v "$1" > /dev/null 2>&1; then
    printf 'unavailable\t127'
    return 0
  fi
  output_file=$(mktemp)
  set +e
  "$@" > "$output_file" 2>&1
  status=$?
  set -e
  digest=$(file_sha256 "$output_file") || {
    rm -f "$output_file"
    return 1
  }
  rm -f "$output_file"
  printf '%s\t%s' "$digest" "$status"
}

capture_security() {
  local destination=$1 value status
  printf 'field\tvalue\texit_code\n' > "$destination"
  printf 'kernel_release\t%s\t0\n' "$(sanitize_value "$(uname -r)")" >> "$destination"
  if command -v getenforce > /dev/null 2>&1; then
    set +e
    value=$(getenforce 2>&1)
    status=$?
    set -e
  else
    value=unavailable
    status=127
  fi
  printf 'selinux_mode\t%s\t%s\n' "$(sanitize_value "$value")" "$status" >> "$destination"
  value=$(ssh_config_digest) || die 'SSH configuration tree is unsafe or unreadable'
  printf 'ssh_config_sha256\t%s\t0\n' "$value" >> "$destination"
  value=$(command_digest ss -H -ltnp 'sport = :22')
  printf 'ssh_listeners_sha256\t%s\n' "$value" >> "$destination"
  value=$(command_digest firewall-cmd --list-all-zones)
  printf 'firewall_zones_sha256\t%s\n' "$value" >> "$destination"
  value=$(command_digest nft list ruleset)
  printf 'nft_rules_sha256\t%s\n' "$value" >> "$destination"
  value=$(command_digest iptables-save)
  printf 'iptables_rules_sha256\t%s\n' "$value" >> "$destination"
}

capture_package_sets() {
  local phase=$1 all_file=$2 critical_file=$3 protected_file=$4 line package version
  : > "$all_file"
  case "$FAMILY" in
    debian) dpkg-query -W -f='${Package}\t${Version}\n' > "$all_file" ;;
    rhel) rpm -qa --qf '%{NAME}\t%{EPOCHNUM}:%{VERSION}-%{RELEASE}.%{ARCH}\n' > "$all_file" ;;
  esac
  sort -o "$all_file" "$all_file"
  printf 'phase\tpackage\tversion\n' > "$critical_file"
  printf 'phase\tpackage\tversion\n' > "$protected_file"
  while IFS=$'\t' read -r package version; do
    [[ -n $package && -n $version ]] || continue
    if [[ $package =~ ^(openssh|openssl|linux-image|linux-headers|kernel|selinux-policy|apparmor|firewalld|nftables|iptables|ufw) ]]; then
      printf '%s\t%s\t%s\n' "$phase" "$package" "$version" >> "$critical_file"
    fi
    if [[ $package =~ ^(openssh|openssl|linux-image|linux-headers|kernel) ]]; then
      printf '%s\t%s\t%s\n' "$phase" "$package" "$version" >> "$protected_file"
    fi
  done < "$all_file"
  rm -f "$all_file"
}

capture_module_packages() {
  local destination=$1 package output status version
  printf 'package\tstatus\tversion\n' > "$destination"
  for package in "${PACKAGES[@]}"; do
    output=''
    case "$FAMILY" in
      debian)
        set +e
        output=$(dpkg-query -W -f='${Status}\t${Version}' -- "$package" 2> /dev/null)
        status=$?
        set -e
        if [[ $status -eq 0 && $output == 'install ok installed'$'\t'* ]]; then
          version=${output#*$'\t'}
          printf '%s\tinstalled\t%s\n' "$package" "$(sanitize_value "$version")" >> "$destination"
        else
          printf '%s\tabsent\t-\n' "$package" >> "$destination"
        fi
        ;;
      rhel)
        set +e
        output=$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}' "$package" 2> /dev/null)
        status=$?
        set -e
        if [[ $status -eq 0 && -n $output ]]; then
          printf '%s\tinstalled\t%s\n' "$package" "$(sanitize_value "$output")" >> "$destination"
        else
          printf '%s\tabsent\t-\n' "$package" >> "$destination"
        fi
        ;;
    esac
  done
}

capture_services() {
  local destination=$1 service enabled active enabled_exit active_exit
  printf 'service\tenabled_state\tenabled_exit\tactive_state\tactive_exit\n' > "$destination"
  for service in "${SERVICES[@]}"; do
    set +e
    enabled=$(systemctl is-enabled "$service" 2>&1)
    enabled_exit=$?
    active=$(systemctl is-active "$service" 2>&1)
    active_exit=$?
    set -e
    printf '%s\t%s\t%s\t%s\t%s\n' "$service" \
      "$(sanitize_value "$enabled")" "$enabled_exit" \
      "$(sanitize_value "$active")" "$active_exit" >> "$destination"
  done
}

capture_ssh_units() {
  local destination=$1 unit enabled active enabled_exit active_exit
  printf 'unit\tenabled_state\tenabled_exit\tactive_state\tactive_exit\n' > "$destination"
  for unit in ssh.service ssh.socket sshd.service sshd.socket; do
    set +e
    enabled=$(systemctl is-enabled "$unit" 2>&1)
    enabled_exit=$?
    active=$(systemctl is-active "$unit" 2>&1)
    active_exit=$?
    set -e
    printf '%s\t%s\t%s\t%s\t%s\n' "$unit" \
      "$(sanitize_value "$enabled")" "$enabled_exit" \
      "$(sanitize_value "$active")" "$active_exit" >> "$destination"
  done
}

CURRENT_STAGE=capture-before
capture_security "$OUTPUT_DIR/security-before.tsv"
capture_package_sets before "$OUTPUT_DIR/.packages-all-before" \
  "$OUTPUT_DIR/critical-packages-before.tsv" "$OUTPUT_DIR/protected-packages-before.tsv"
capture_module_packages "$OUTPUT_DIR/module-packages-before.tsv"
capture_services "$OUTPUT_DIR/services-before.tsv"
capture_ssh_units "$OUTPUT_DIR/ssh-units-before.tsv"

CURRENT_STAGE=installer-plan
PLAN_ARGS=(plan --no-refresh "$MODULE")
INSTALL_ARGS=(install --yes "$MODULE")
if [[ $MODE == enable-services ]]; then
  PLAN_ARGS=(plan --no-refresh --enable-services "$MODULE")
  INSTALL_ARGS=(install --yes --enable-services "$MODULE")
fi
"$INSTALLER" "${PLAN_ARGS[@]}" > "$OUTPUT_DIR/installer-plan.txt" 2>&1 ||
  die 'installer plan failed on the exact VM'
if [[ $MODE == enable-services ]]; then
  grep -F -q -- "; enable: ${SERVICE_CSV//,/, }" "$OUTPUT_DIR/installer-plan.txt" ||
    die 'installer plan does not declare the expected service activation'
else
  ! grep -q '; enable:' "$OUTPUT_DIR/installer-plan.txt" ||
    die 'default installer plan unexpectedly declares service activation'
fi
check_pass installer_plan "$MODE"

CURRENT_STAGE=installer-run
INSTALLER_TRACE=$OUTPUT_DIR/installer-trace.log
exec 9> "$INSTALLER_TRACE"
set +e
if [[ $TEST_MODE == 1 ]]; then
  # shellcheck disable=SC2016 # PS4 is expanded by the traced child Bash process.
  env BASH_XTRACEFD=9 PS4='+${BASH_SOURCE}:${LINENO}: ' \
    bash -x "$INSTALLER" "${INSTALL_ARGS[@]}" 2>&1 | tee "$OUTPUT_DIR/installer.log"
  PIPE_STATUSES=("${PIPESTATUS[@]}")
  INSTALL_STATUS=${PIPE_STATUSES[0]}
  TEE_STATUS=${PIPE_STATUSES[1]}
else
  # shellcheck disable=SC2016 # PS4 is expanded by the traced child Bash process.
  timeout --signal=TERM --kill-after=30s 45m \
    env BASH_XTRACEFD=9 PS4='+${BASH_SOURCE}:${LINENO}: ' \
    bash -x "$INSTALLER" "${INSTALL_ARGS[@]}" 2>&1 | tee "$OUTPUT_DIR/installer.log"
  PIPE_STATUSES=("${PIPESTATUS[@]}")
  INSTALL_STATUS=${PIPE_STATUSES[0]}
  TEE_STATUS=${PIPE_STATUSES[1]}
fi
set -e
exec 9>&-
((TEE_STATUS == 0)) || die "could not capture installer output (tee exit $TEE_STATUS)"

CURRENT_STAGE=capture-after
capture_security "$OUTPUT_DIR/security-after.tsv"
capture_package_sets after "$OUTPUT_DIR/.packages-all-after" \
  "$OUTPUT_DIR/critical-packages-after.tsv" "$OUTPUT_DIR/protected-packages-after.tsv"
capture_module_packages "$OUTPUT_DIR/module-packages-after.tsv"
capture_services "$OUTPUT_DIR/services-after.tsv"
capture_ssh_units "$OUTPUT_DIR/ssh-units-after.tsv"
set +e
SYSTEMD_STATE_AFTER=$(systemctl is-system-running 2> /dev/null)
SYSTEMD_STATE_AFTER_EXIT=$?
FAILED_UNITS_AFTER=$(systemctl --failed --no-legend --plain --no-pager 2>&1)
FAILED_UNITS_AFTER_EXIT=$?
set -e
printf '%s' "$FAILED_UNITS_AFTER" > "$OUTPUT_DIR/failed-units-after.txt"
[[ $SYSTEMD_STATE_AFTER == running && $SYSTEMD_STATE_AFTER_EXIT -eq 0 ]] ||
  die "systemd became non-operational: ${SYSTEMD_STATE_AFTER:-unknown} ($SYSTEMD_STATE_AFTER_EXIT)"
[[ $FAILED_UNITS_AFTER_EXIT -eq 0 && -z $FAILED_UNITS_AFTER ]] ||
  die 'installation left failed systemd units'
cmp -s "$OUTPUT_DIR/ssh-units-before.tsv" "$OUTPUT_DIR/ssh-units-after.tsv" ||
  die 'SSH unit enabled/active state changed during installation'
check_pass systemd_post_install running
if ((INSTALL_STATUS != 0)); then
  printf 'installer_exit\tfailed\t%s\n' "$INSTALL_STATUS" >> "$CHECKS_FILE"
  exit "$INSTALL_STATUS"
fi
check_pass installer_exit 0

declare -A EXPECTED_PACKAGES=() AFTER_PACKAGES_SEEN=()
for package in "${PACKAGES[@]}"; do
  [[ -n $package && -z ${EXPECTED_PACKAGES[$package]+x} ]] ||
    die 'module contract contains an empty or repeated package'
  EXPECTED_PACKAGES["$package"]=1
done
while IFS=$'\t' read -r package package_status version extra; do
  [[ $package != package ]] || continue
  [[ -n ${EXPECTED_PACKAGES[$package]+x} && -z ${AFTER_PACKAGES_SEEN[$package]+x} &&
    -z ${extra:-} ]] || die "module package evidence has an unexpected row: $package"
  AFTER_PACKAGES_SEEN["$package"]=1
  [[ $package_status == installed && -n $version && $version != '-' ]] ||
    die "declared module package is not installed after the run: $package"
done < "$OUTPUT_DIR/module-packages-after.tsv"
[[ ${#AFTER_PACKAGES_SEEN[@]} -eq ${#EXPECTED_PACKAGES[@]} ]] ||
  die 'module package evidence is incomplete after the run'
check_pass module_packages installed

CURRENT_STAGE='service-attribution'
declare -A BEFORE_ENABLED=() BEFORE_ACTIVE=() AFTER_ENABLED=() AFTER_ACTIVE=()
declare -A AFTER_ENABLED_EXIT=() AFTER_ACTIVE_EXIT=()
while IFS=$'\t' read -r service enabled enabled_exit active active_exit; do
  [[ $service != service ]] || continue
  BEFORE_ENABLED["$service"]=$enabled
  BEFORE_ACTIVE["$service"]=$active
done < "$OUTPUT_DIR/services-before.tsv"
while IFS=$'\t' read -r service enabled enabled_exit active active_exit; do
  [[ $service != service ]] || continue
  AFTER_ENABLED["$service"]=$enabled
  AFTER_ACTIVE["$service"]=$active
  AFTER_ENABLED_EXIT["$service"]=$enabled_exit
  AFTER_ACTIVE_EXIT["$service"]=$active_exit
done < "$OUTPUT_DIR/services-after.tsv"
printf 'service\texplicit_activation_requested\tenabled_changed\tactive_changed\tattribution\n' \
  > "$OUTPUT_DIR/service-attribution.tsv"
for service in "${SERVICES[@]}"; do
  enabled_changed=false
  active_changed=false
  [[ ${BEFORE_ENABLED[$service]} == "${AFTER_ENABLED[$service]}" ]] || enabled_changed=true
  [[ ${BEFORE_ACTIVE[$service]} == "${AFTER_ACTIVE[$service]}" ]] || active_changed=true
  if [[ $MODE == enable-services ]]; then
    [[ ${AFTER_ENABLED_EXIT[$service]} == 0 && ${AFTER_ACTIVE_EXIT[$service]} == 0 &&
      ${AFTER_ENABLED[$service]} == enabled && ${AFTER_ACTIVE[$service]} == active ]] ||
      die "explicit activation did not leave $service enabled and active"
    grep -E -q -- ": systemctl enable --now ${service}$" "$INSTALLER_TRACE" ||
      die "trusted installer trace lacks explicit activation attribution for $service"
    attribution=installer-explicit-activation-requested
    explicit=true
  else
    ! grep -E -q -- ': (/usr/bin/|/bin/)?(systemctl|service) (enable|disable|start|stop|restart|try-restart|reload|mask|unmask)( |$)' \
      "$INSTALLER_TRACE" || die 'default-mode trusted trace contains service mutation'
    explicit=false
    if [[ $enabled_changed == true || $active_changed == true ]]; then
      attribution='package-maintainer-or-system-policy'
    else
      attribution=no-state-change
    fi
  fi
  printf '%s\t%s\t%s\t%s\t%s\n' "$service" "$explicit" \
    "$enabled_changed" "$active_changed" "$attribution" \
    >> "$OUTPUT_DIR/service-attribution.tsv"
done
check_pass service_attribution "$MODE"

CURRENT_STAGE=safety-comparison
security_field_value() {
  local path=$1 wanted=$2 field value status extra count=0 result=''
  while IFS=$'\t' read -r field value status extra; do
    [[ $field != field ]] || continue
    [[ $field == "$wanted" ]] || continue
    count=$((count + 1))
    [[ -n $value && $status =~ ^[0-9]+$ && -z ${extra:-} ]] || return 1
    result=$value$'\t'$status
  done < "$path"
  [[ $count -eq 1 ]] || return 1
  printf '%s' "$result"
}
security_field_equal() {
  local field=$1 before after
  before=$(security_field_value "$OUTPUT_DIR/security-before.tsv" "$field") || return 1
  after=$(security_field_value "$OUTPUT_DIR/security-after.tsv" "$field") || return 1
  [[ $before == "$after" ]]
}
security_field_equal kernel_release || die 'running kernel changed during installation'
security_field_equal selinux_mode || die 'SELinux enforcement state changed during installation'
security_field_equal ssh_config_sha256 || die 'SSH configuration changed during installation'
security_field_equal ssh_listeners_sha256 || die 'SSH listening sockets changed during installation'
if [[ $FAMILY == rhel ]]; then
  [[ $(security_field_value "$OUTPUT_DIR/security-before.tsv" selinux_mode) == *$'\t0' ]] ||
    die 'RHEL-family evidence requires a successful SELinux enforcement probe'
fi
cmp -s "$OUTPUT_DIR/protected-packages-before.tsv" \
  <(sed 's/^after\t/before\t/' "$OUTPUT_DIR/protected-packages-after.tsv") ||
  die 'kernel/OpenSSL/OpenSSH package state changed during installation'
check_pass critical_system_state unchanged
if [[ $MODULE == firewalld ]]; then
  check_pass firewall_state 'captured-for-firewall-module'
else
  security_field_equal firewall_zones_sha256 || die 'firewall zone state changed during installation'
  security_field_equal nft_rules_sha256 || die 'nftables state changed during installation'
  security_field_equal iptables_rules_sha256 || die 'iptables state changed during installation'
  check_pass firewall_state unchanged
fi

CURRENT_STAGE=source-recheck
verify_source_checkout
check_pass source_unchanged_after_install "$TESTED_COMMIT"

CURRENT_STAGE=complete
if [[ $TEST_MODE == 1 ]]; then
  RESULT=test-only
else
  # The local root-writable provisioning marker cannot authenticate VM
  # freshness or image provenance. Only an external trust-anchor workflow can
  # promote this structurally complete bundle; no such workflow exists here.
  RESULT=provisional
fi
printf 'Systemd evidence %s: %s\n' "$RESULT" "$EXECUTION_ID"
