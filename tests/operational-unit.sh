#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEMP_DIR=$(mktemp -d)
LOCK_HOLDER_PID=''

cleanup() {
  if [[ -n $LOCK_HOLDER_PID ]] && kill -0 "$LOCK_HOLDER_PID" 2> /dev/null; then
    kill "$LOCK_HOLDER_PID" 2> /dev/null || true
    wait "$LOCK_HOLDER_PID" 2> /dev/null || true
  fi
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

fail() {
  printf 'Operational test failed: %s\n' "$1" >&2
  return 1
}

load_common() {
  export LSI_PROJECT_ROOT="$ROOT_DIR"
  # shellcheck source=../lib/common.sh
  source "$ROOT_DIR/lib/common.sh"
}

test_root_enforcement() {
  local output status
  local -a command_line=()
  if ((EUID == 0)); then
    command -v setpriv > /dev/null 2>&1 ||
      fail 'setpriv is required to exercise root refusal when the test runner is root'
    command_line=(setpriv --reuid=65534 --regid=65534 --clear-groups)
  fi
  # shellcheck disable=SC2016 # Expanded by the deliberately isolated child Bash.
  command_line+=(env LSI_PROJECT_ROOT="$ROOT_DIR" bash -c '
    set -uo pipefail
    source "$LSI_PROJECT_ROOT/lib/common.sh"
    lsi_require_root
  ')
  set +e
  output=$("${command_line[@]}" 2>&1)
  status=$?
  set -e
  [[ $status -eq 4 ]] || fail "unprivileged root check returned $status instead of 4"
  grep -q 'Installation requires root' <<< "$output" ||
    fail 'unprivileged root check did not explain the sudo requirement'
}

test_confirmation_contract() {
  local output status
  set +e
  # shellcheck disable=SC2016 # Expanded by the deliberately isolated child Bash.
  output=$(env LSI_PROJECT_ROOT="$ROOT_DIR" bash -c '
    set -uo pipefail
    source "$LSI_PROJECT_ROOT/lib/common.sh"
    LSI_ASSUME_YES=false
    lsi_confirm "test confirmation"
  ' < /dev/null 2>&1)
  status=$?
  set -e
  [[ $status -eq 2 ]] ||
    fail "non-interactive confirmation returned $status instead of 2"
  grep -q 'Confirmation required in non-interactive mode' <<< "$output" ||
    fail 'non-interactive confirmation did not require --yes'

  # shellcheck disable=SC2016 # Expanded by the deliberately isolated child Bash.
  env LSI_PROJECT_ROOT="$ROOT_DIR" bash -c '
    set -Eeuo pipefail
    source "$LSI_PROJECT_ROOT/lib/common.sh"
    source "$LSI_PROJECT_ROOT/lib/cli.sh"
    lsi_parse_options --yes
    lsi_confirm "test confirmation"
  ' < /dev/null || fail '--yes did not bypass the prompt in a non-interactive session'
}

test_lock_contention() {
  local lock_file="$TEMP_DIR/lock/installer.lock"
  local ready="$TEMP_DIR/lock-ready"
  local release="$TEMP_DIR/lock-release"
  local output status attempt

  # shellcheck disable=SC2016 # Expanded by the deliberately isolated child Bash.
  env LSI_PROJECT_ROOT="$ROOT_DIR" LOCK_FILE="$lock_file" READY="$ready" RELEASE="$release" \
    bash -c '
      set -Eeuo pipefail
      source "$LSI_PROJECT_ROOT/lib/common.sh"
      lsi_acquire_lock "$LOCK_FILE"
      : > "$READY"
      for ((attempt = 0; attempt < 1000; attempt++)); do
        [[ ! -e $RELEASE ]] || exit 0
        sleep 0.01
      done
      exit 70
    ' &
  LOCK_HOLDER_PID=$!

  for ((attempt = 0; attempt < 500; attempt++)); do
    [[ ! -e $ready ]] || break
    kill -0 "$LOCK_HOLDER_PID" 2> /dev/null ||
      fail 'the first lock holder exited before acquiring the lock'
    sleep 0.01
  done
  [[ -e $ready ]] || fail 'timed out waiting for the first lock holder'

  set +e
  # shellcheck disable=SC2016 # Expanded by the deliberately isolated child Bash.
  output=$(env LSI_PROJECT_ROOT="$ROOT_DIR" LOCK_FILE="$lock_file" bash -c '
    set -uo pipefail
    source "$LSI_PROJECT_ROOT/lib/common.sh"
    lsi_acquire_lock "$LOCK_FILE"
  ' 2>&1)
  status=$?
  set -e
  [[ $status -eq 4 ]] || fail "contending lock returned $status instead of 4"
  grep -q 'Another linux-software-installer process is running' <<< "$output" ||
    fail 'lock contention did not report the active installer'

  : > "$release"
  wait "$LOCK_HOLDER_PID" || fail 'the first lock holder did not exit cleanly'
  LOCK_HOLDER_PID=''
}

test_lock_requires_flock() {
  local bash_path output status
  bash_path=$(command -v bash) || fail 'bash path is unavailable'
  mkdir -p "$TEMP_DIR/no-tools"
  set +e
  # shellcheck disable=SC2016 # Expanded by the deliberately isolated child Bash.
  output=$(LSI_PROJECT_ROOT="$ROOT_DIR" PATH="$TEMP_DIR/no-tools" \
    "$bash_path" -c '
      set -uo pipefail
      source "$LSI_PROJECT_ROOT/lib/common.sh"
      lsi_acquire_lock "/unused/installer.lock"
    ' 2>&1)
  status=$?
  set -e
  [[ $status -eq 4 ]] || fail "missing flock returned $status instead of 4"
  grep -q 'Required concurrent-run protection is unavailable: flock' <<< "$output" ||
    fail 'missing flock did not fail closed with an actionable error'
}

test_protected_log_initialization() {
  local log_dir="$TEMP_DIR/protected-logs"
  local log_file="$log_dir/operational.log"
  local external="$TEMP_DIR/external-secret"
  local before_mode status output

  (
    load_common
    LSI_DRY_RUN=false
    LSI_LOG_FILE="$log_file"
    lsi_initialize_log "$log_dir"
    lsi_info 'protected logging initialized'
  ) > /dev/null
  [[ -d $log_dir && ! -L $log_dir ]] || fail 'protected log directory is not a real directory'
  [[ -f $log_file && ! -L $log_file ]] || fail 'protected log is not a regular file'
  [[ $(stat -c '%a' -- "$log_dir") == 750 ]] || fail 'protected log directory mode is not 0750'
  [[ $(stat -c '%a' -- "$log_file") == 600 ]] || fail 'protected log mode is not 0600'
  [[ $(stat -c '%h' -- "$log_file") == 1 ]] || fail 'protected log has multiple hard links'
  grep -q 'protected logging initialized' "$log_file" || fail 'initialized logger did not append its message'

  printf 'do not modify\n' > "$external"
  chmod 0640 "$external"
  before_mode=$(stat -c '%a' -- "$external")
  mkdir -p "$TEMP_DIR/symlink-logs"
  ln -s "$external" "$TEMP_DIR/symlink-logs/linked.log"
  set +e
  output=$(
    LSI_PROJECT_ROOT="$ROOT_DIR" \
      LSI_LOG_FILE="$TEMP_DIR/symlink-logs/linked.log" \
      LOG_DIR="$TEMP_DIR/symlink-logs" \
      bash -c '
        set -uo pipefail
        source "$LSI_PROJECT_ROOT/lib/common.sh"
        LSI_DRY_RUN=false
        lsi_initialize_log "$LOG_DIR"
      ' 2>&1
  )
  status=$?
  set -e
  [[ $status -eq 4 ]] || fail "symlink log refusal returned $status instead of 4"
  grep -q 'Refusing to reuse an existing installer log path' <<< "$output" ||
    fail 'symlink log path was not explicitly refused'
  grep -qx 'do not modify' "$external" || fail 'symlink target content was modified'
  [[ $(stat -c '%a' -- "$external") == "$before_mode" ]] || fail 'symlink target mode was modified'

  mkdir -p "$TEMP_DIR/fifo-logs"
  mkfifo "$TEMP_DIR/fifo-logs/special.log"
  set +e
  LSI_PROJECT_ROOT="$ROOT_DIR" \
    LSI_LOG_FILE="$TEMP_DIR/fifo-logs/special.log" \
    LOG_DIR="$TEMP_DIR/fifo-logs" \
    bash -c '
      set -uo pipefail
      source "$LSI_PROJECT_ROOT/lib/common.sh"
      LSI_DRY_RUN=false
      lsi_initialize_log "$LOG_DIR"
    ' > /dev/null 2>&1
  status=$?
  set -e
  [[ $status -eq 4 ]] || fail "special-file log refusal returned $status instead of 4"

  mkdir -p "$TEMP_DIR/existing-logs"
  printf 'preserve existing\n' > "$TEMP_DIR/existing-logs/existing.log"
  set +e
  LSI_PROJECT_ROOT="$ROOT_DIR" \
    LSI_LOG_FILE="$TEMP_DIR/existing-logs/existing.log" \
    LOG_DIR="$TEMP_DIR/existing-logs" \
    bash -c '
      set -uo pipefail
      source "$LSI_PROJECT_ROOT/lib/common.sh"
      LSI_DRY_RUN=false
      lsi_initialize_log "$LOG_DIR"
    ' > /dev/null 2>&1
  status=$?
  set -e
  [[ $status -eq 4 ]] || fail "existing log refusal returned $status instead of 4"
  grep -qx 'preserve existing' "$TEMP_DIR/existing-logs/existing.log" ||
    fail 'existing log content was overwritten'

  set +e
  LSI_PROJECT_ROOT="$ROOT_DIR" \
    LSI_LOG_FILE="$external" \
    LOG_DIR="$TEMP_DIR/foreign-logs" \
    bash -c '
      set -uo pipefail
      source "$LSI_PROJECT_ROOT/lib/common.sh"
      lsi_info "must not write before initialization"
      LSI_DRY_RUN=false
      lsi_initialize_log "$LOG_DIR"
    ' > /dev/null 2>&1
  status=$?
  set -e
  [[ $status -eq 4 ]] || fail "foreign log path refusal returned $status instead of 4"
  grep -qx 'do not modify' "$external" || fail 'foreign log was written before initialization'
}

test_secret_redaction() {
  local log_dir="$TEMP_DIR/redacted-logs"
  local log_file="$log_dir/redacted.log"
  local secret='LSI-SECRET-DO-NOT-LOG-918273645'
  local output
  output=$(
    (
      local SECRET_VALUE="$secret"
      local LOG_DIR="$log_dir"
      local LOG_FILE="$log_file"
      load_common
      LSI_DRY_RUN=false
      LSI_LOG_FILE="$LOG_FILE"
      lsi_initialize_log "$LOG_DIR"
      # shellcheck disable=SC2317,SC2329 # Invoked indirectly through lsi_run.
      secret_sink() { :; }
      lsi_run secret_sink --token "$SECRET_VALUE" \
        "API_PASSWORD=$SECRET_VALUE" "--api-key=$SECRET_VALUE"
    )
  )
  ! grep -F -q -- "$secret" <<< "$output" || fail 'secret appeared in command output'
  ! grep -F -q -- "$secret" "$log_file" || fail 'secret appeared in the protected log'
  grep -q 'REDACTED' "$log_file" || fail 'sensitive command values were not visibly redacted'
}

test_package_failure_propagates() {
  local trace="$TEMP_DIR/package-failure.trace"
  local status
  set +e
  LSI_PROJECT_ROOT="$ROOT_DIR" TRACE="$trace" bash -c '
    set -Eeuo pipefail
    source "$LSI_PROJECT_ROOT/lib/common.sh"
    source "$LSI_PROJECT_ROOT/lib/catalog.sh"
    source "$LSI_PROJECT_ROOT/lib/package.sh"
    LSI_OS_FAMILY=debian
    LSI_OS_ID=fixture
    LSI_OS_VERSION_ID=1
    LSI_ARCH=x86_64
    LSI_DRY_RUN=false
    LSI_NO_REFRESH=true
    LSI_ENABLE_SERVICES=false
    lsi_load_module() {
      MODULE_ID=$1
      MODULE_NAME="Package failure fixture"
      MODULE_FAMILIES=(debian)
      MODULE_DEBIAN_PACKAGES=(fixture-package)
      MODULE_RHEL_PACKAGES=()
      MODULE_VERIFY_BINARIES=(fixture-binary)
      MODULE_DEBIAN_VERIFY_BINARIES=(fixture-binary)
      MODULE_RHEL_VERIFY_BINARIES=()
      MODULE_DEBIAN_SERVICES=()
      MODULE_RHEL_SERVICES=()
      MODULE_TARGET_CELLS=()
    }
    lsi_module_supports_family() { return 0; }
    lsi_run() {
      printf "%s\n" "$*" >> "$TRACE"
      return 23
    }
    lsi_install_module package-failure
    printf "continued-after-package-failure\n" >> "$TRACE"
  ' > /dev/null 2>&1
  status=$?
  set -e
  [[ $status -eq 23 ]] || fail "package failure returned $status instead of 23"
  grep -q 'fixture-package' "$trace" || fail 'package failure fixture did not reach the package command'
  ! grep -q 'continued-after-package-failure' "$trace" || fail 'execution continued after package failure'
}

test_verification_failure_propagates() {
  local trace="$TEMP_DIR/verification-failure.trace"
  local output status
  set +e
  output=$(LSI_PROJECT_ROOT="$ROOT_DIR" TRACE="$trace" bash -c '
    set -Eeuo pipefail
    source "$LSI_PROJECT_ROOT/lib/common.sh"
    source "$LSI_PROJECT_ROOT/lib/catalog.sh"
    source "$LSI_PROJECT_ROOT/lib/package.sh"
    LSI_OS_FAMILY=debian
    LSI_OS_ID=fixture
    LSI_OS_VERSION_ID=1
    LSI_ARCH=x86_64
    LSI_DRY_RUN=false
    LSI_NO_REFRESH=true
    LSI_ENABLE_SERVICES=false
    lsi_load_module() {
      MODULE_ID=$1
      MODULE_NAME="Verification failure fixture"
      MODULE_FAMILIES=(debian)
      MODULE_DEBIAN_PACKAGES=(fixture-package)
      MODULE_RHEL_PACKAGES=()
      MODULE_VERIFY_BINARIES=(lsi-binary-that-must-not-exist-918273645)
      MODULE_DEBIAN_VERIFY_BINARIES=(lsi-binary-that-must-not-exist-918273645)
      MODULE_RHEL_VERIFY_BINARIES=()
      MODULE_DEBIAN_SERVICES=()
      MODULE_RHEL_SERVICES=()
      MODULE_TARGET_CELLS=()
    }
    lsi_module_supports_family() { return 0; }
    lsi_run() {
      printf "%s\n" "$*" >> "$TRACE"
      return 0
    }
    lsi_install_module verification-failure
    printf "continued-after-verification-failure\n" >> "$TRACE"
  ' 2>&1)
  status=$?
  set -e
  [[ $status -eq 6 ]] || fail "verification failure returned $status instead of 6"
  grep -q 'Verification failed for verification-failure' <<< "$output" ||
    fail 'missing verification binary was not identified'
  grep -q 'Module verification failed: verification-failure' <<< "$output" ||
    fail 'verification failure was not attributed to its module'
  ! grep -q 'continued-after-verification-failure' "$trace" ||
    fail 'execution continued after verification failure'
}

test_stop_on_error() {
  local trace="$TEMP_DIR/stop-on-error.trace"
  local status
  set +e
  LSI_PROJECT_ROOT="$ROOT_DIR" TRACE="$trace" bash -c '
    set -Eeuo pipefail
    source "$LSI_PROJECT_ROOT/lib/common.sh"
    source "$LSI_PROJECT_ROOT/lib/cli.sh"
    LSI_DRY_RUN=false
    lsi_expand_requests() { LSI_FINAL_MODULES=(first second); }
    lsi_check_conflicts() { :; }
    lsi_show_plan() { :; }
    lsi_confirm() { :; }
    lsi_require_root() { :; }
    lsi_acquire_lock() { :; }
    lsi_initialize_log() { :; }
    lsi_preflight() { :; }
    lsi_install_module() {
      printf "%s\n" "$1" >> "$TRACE"
      [[ $1 != first ]] || return 31
    }
    lsi_execute
  ' > /dev/null 2>&1
  status=$?
  set -e
  [[ $status -eq 31 ]] || fail "first-module failure returned $status instead of 31"
  [[ $(wc -l < "$trace") -eq 1 ]] || fail 'a later module ran after the first module failed'
  grep -qx 'first' "$trace" || fail 'stop-on-error trace does not contain only the first module'
}

test_refresh_once_execution() (
  local trace="$TEMP_DIR/refresh.trace"
  load_common
  # shellcheck source=../lib/package.sh
  source "$ROOT_DIR/lib/package.sh"
  LSI_DRY_RUN=false
  LSI_NO_REFRESH=false
  LSI_REFRESHED=false
  LSI_OS_FAMILY=debian
  lsi_run() { printf '%s\n' "$*" >> "$trace"; }
  lsi_refresh_repositories
  lsi_refresh_repositories
  [[ $LSI_REFRESHED == true ]] || fail 'repository refresh state was not recorded'
  [[ $(wc -l < "$trace") -eq 1 ]] || fail 'repository metadata refreshed more than once'
  grep -qx 'apt-get update' "$trace" || fail 'Debian refresh command was not apt-get update'
)

test_explicit_service_activation() (
  local trace="$TEMP_DIR/services.trace"
  load_common
  # shellcheck source=../lib/package.sh
  source "$ROOT_DIR/lib/package.sh"
  LSI_OS_FAMILY=debian
  LSI_DRY_RUN=true
  MODULE_ID='service-fixture'
  MODULE_DEBIAN_SERVICES=(fixture.service)
  MODULE_RHEL_SERVICES=()
  lsi_run() { printf '%s\n' "$*" >> "$trace"; }

  LSI_ENABLE_SERVICES=false
  lsi_enable_module_services
  [[ ! -e $trace ]] || fail 'service activation ran without --enable-services'

  LSI_ENABLE_SERVICES=true
  lsi_enable_module_services
  [[ $(wc -l < "$trace") -eq 1 ]] || fail 'service activation did not run exactly once'
  grep -qx 'systemctl enable --now fixture.service' "$trace" ||
    fail 'explicit service activation used an unexpected command'
)

test_root_enforcement
test_confirmation_contract
test_lock_contention
test_lock_requires_flock
test_protected_log_initialization
test_secret_redaction
test_package_failure_propagates
test_verification_failure_propagates
test_stop_on_error
test_refresh_once_execution
test_explicit_service_activation

printf 'Operational safety contract passed: root, confirmation, lock, logs, failures, refresh and services.\n'
