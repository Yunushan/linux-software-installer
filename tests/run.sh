#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
PASS_COUNT=0
FAIL_COUNT=0

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf 'ok %d - %s\n' "$PASS_COUNT" "$1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf 'not ok - %s\n' "$1" >&2
}

run_test() {
  local name=$1
  shift
  if "$@"; then
    pass "$name"
  else
    fail "$name"
  fi
}

test_syntax() {
  local file
  while IFS= read -r file; do
    bash -n "$file" || return 1
  done < <(find "$ROOT_DIR" \
    -path "$ROOT_DIR/legacy" -prune -o \
    -type f -name '*.sh' -print)
}

test_detect_ubuntu() (
  export LSI_PROJECT_ROOT="$ROOT_DIR"
  # shellcheck source=../lib/common.sh
  source "$ROOT_DIR/lib/common.sh"
  # shellcheck source=../lib/os.sh
  source "$ROOT_DIR/lib/os.sh"
  LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env"
  lsi_detect_os
  [[ $LSI_OS_ID == ubuntu && $LSI_OS_FAMILY == debian && $LSI_PACKAGE_MANAGER == apt-get ]]
)

test_detect_rocky() (
  export LSI_PROJECT_ROOT="$ROOT_DIR"
  source "$ROOT_DIR/lib/common.sh"
  source "$ROOT_DIR/lib/os.sh"
  LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/rocky.env"
  lsi_detect_os
  [[ $LSI_OS_ID == rocky && $LSI_OS_FAMILY == rhel && $LSI_PACKAGE_MANAGER == dnf ]]
)

test_module_catalog() {
  local output count
  output=$("$ROOT_DIR/install.sh" list)
  count=$(grep -Ec '^[a-z0-9-]+[[:space:]]+' <<< "$output")
  [[ $count -ge 40 ]] && grep -q '^nginx' <<< "$output" && grep -q '^postgresql' <<< "$output"
}

test_all_profile_modules_exist() {
  local file module
  for file in "$ROOT_DIR"/profiles/*.list; do
    while IFS= read -r module; do
      module=${module%%#*}
      module=${module//[[:space:]]/}
      [[ -z $module || -f "$ROOT_DIR/modules/$module/module.sh" ]] || return 1
    done < "$file"
  done
}

test_ubuntu_plan() {
  local output
  output=$(LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    "$ROOT_DIR/install.sh" plan --no-refresh nginx git 2>&1) || return 1
  grep -q 'Family       : debian' <<< "$output" &&
    grep -q 'apt-get install.*nginx' <<< "$output" &&
    grep -q 'no system changes were made' <<< "$output"
}

test_rocky_plan() {
  local output
  output=$(LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/rocky.env" \
    "$ROOT_DIR/install.sh" plan --no-refresh nginx git 2>&1) || return 1
  grep -q 'Family       : rhel' <<< "$output" &&
    grep -q 'dnf -y install nginx' <<< "$output"
}

test_profile_family_filter() {
  local output
  output=$(LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/rocky.env" \
    "$ROOT_DIR/install.sh" plan --no-refresh --profile security 2>&1) || return 1
  grep -q 'skipping ufw on rhel' <<< "$output" &&
    grep -q 'firewalld' <<< "$output"
}

test_unknown_module_rejected() {
  ! LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    "$ROOT_DIR/install.sh" plan --no-refresh does-not-exist > /dev/null 2>&1
}

test_path_traversal_rejected() {
  ! LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    "$ROOT_DIR/install.sh" plan --no-refresh ../../tmp/evil > /dev/null 2>&1
}

test_conflict_rejected() {
  ! LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    "$ROOT_DIR/install.sh" plan --no-refresh nginx apache > /dev/null 2>&1
}

test_centos7_guard() {
  ! LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/centos7.env" \
    "$ROOT_DIR/install.sh" plan --no-refresh git > /dev/null 2>&1
}

test_centos7_explicit_override() {
  LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/centos7.env" \
    "$ROOT_DIR/install.sh" plan --no-refresh --force-unsupported git > /dev/null 2>&1
}

test_repository_refresh_once() {
  local output count
  output=$(LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    "$ROOT_DIR/install.sh" plan nginx git 2>&1) || return 1
  count=$(grep -c 'apt-get update' <<< "$output")
  [[ $count -eq 1 ]]
}

test_services_are_opt_in() {
  local normal enabled
  normal=$(LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    "$ROOT_DIR/install.sh" plan --no-refresh nginx 2>&1) || return 1
  enabled=$(LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    "$ROOT_DIR/install.sh" plan --no-refresh --enable-services nginx 2>&1) || return 1
  ! grep -q 'systemctl enable' <<< "$normal" &&
    grep -q 'systemctl enable --now nginx' <<< "$enabled"
}

test_unsupported_direct_module_rejected() {
  ! LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/rocky.env" \
    "$ROOT_DIR/install.sh" plan --no-refresh docker > /dev/null 2>&1
}

test_csv_module_input() {
  local output
  output=$(LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    "$ROOT_DIR/install.sh" plan --no-refresh nginx,git 2>&1) || return 1
  grep -q 'packages: nginx' <<< "$output" && grep -q 'packages: git' <<< "$output"
}

run_test 'supported shell files pass bash -n' test_syntax
run_test 'Ubuntu maps to the Debian package family' test_detect_ubuntu
run_test 'Rocky Linux maps to the RHEL package family' test_detect_rocky
run_test 'module catalog is complete and discoverable' test_module_catalog
run_test 'all profile entries resolve to module manifests' test_all_profile_modules_exist
run_test 'Ubuntu dry run emits apt-get commands' test_ubuntu_plan
run_test 'Rocky dry run emits dnf commands' test_rocky_plan
run_test 'profiles filter modules by distro family' test_profile_family_filter
run_test 'unknown modules are rejected' test_unknown_module_rejected
run_test 'module path traversal is rejected' test_path_traversal_rejected
run_test 'declared module conflicts are rejected' test_conflict_rejected
run_test 'CentOS 7 is blocked from the active installer' test_centos7_guard
run_test 'legacy-version bypass must be explicit' test_centos7_explicit_override
run_test 'repository metadata refreshes only once per plan' test_repository_refresh_once
run_test 'service activation is explicitly opt-in' test_services_are_opt_in
run_test 'family-incompatible direct modules are rejected' test_unsupported_direct_module_rejected
run_test 'comma-separated module input is supported' test_csv_module_input

printf '\n%d passed, %d failed\n' "$PASS_COUNT" "$FAIL_COUNT"
((FAIL_COUNT == 0))
