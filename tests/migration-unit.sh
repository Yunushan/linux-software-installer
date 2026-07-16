#!/usr/bin/env bash
# shellcheck disable=SC2329 # Hostile functions are invoked only if isolation fails.
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/lsi-migration-unit.XXXXXX")
trap 'rm -rf -- "$TEST_TMP"' EXIT

export LC_ALL=C
export LSI_PROJECT_ROOT="$ROOT_DIR"
# shellcheck source=../lib/common.sh
source "$ROOT_DIR/lib/common.sh"
# shellcheck source=../lib/catalog.sh
source "$ROOT_DIR/lib/catalog.sh"
# shellcheck source=../lib/migration.sh
source "$ROOT_DIR/lib/migration.sh"

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

prepare_case() {
  local case_dir
  case_dir=$(mktemp -d "$TEST_TMP/case.XXXXXX")
  cp "$ROOT_DIR/docs/legacy-inventory.tsv" "$case_dir/legacy-inventory.tsv"
  cp "$ROOT_DIR/docs/provider-backlog.tsv" "$case_dir/provider-backlog.tsv"
  printf '%s\n' "$case_dir"
}

use_case() {
  LSI_MIGRATION_INVENTORY=$1/legacy-inventory.tsv
  LSI_MIGRATION_BACKLOG=$1/provider-backlog.tsv
  lsi_migration_reset
}

test_canonical_catalog_loads() (
  lsi_migration_load || return 1
  [[ $LSI_MIGRATION_TOTAL -eq 355 &&
    $LSI_MIGRATION_TERMINAL -eq 84 &&
    $LSI_MIGRATION_PLANNED -eq 142 &&
    $LSI_MIGRATION_BLOCKED -eq 129 ]]
)

test_planned_lookup_is_provisional() (
  local output
  output=$(lsi_migration_show ubuntu-002) || return 1
  grep -q '^Legacy entry  : Nginx (PPA)$' <<< "$output" &&
    grep -q '^Disposition   : planned$' <<< "$output" &&
    grep -q '^Replacement   : nginx$' <<< "$output" &&
    grep -q 'provisional candidate' <<< "$output" &&
    grep -q '^Inspect       : ./install.sh info nginx$' <<< "$output" &&
    grep -q 'never execute' <<< "$output"
)

test_terminal_lookup_is_handoff() (
  local output
  output=$(lsi_migration_show ubuntu-013) || return 1
  grep -q '^Legacy entry  : Skype$' <<< "$output" &&
    grep -q '^Disposition   : retired$' <<< "$output" &&
    grep -q 'terminal documented handoff' <<< "$output" &&
    ! grep -q '^Inspect       :' <<< "$output"
)

test_blocked_lookup_is_not_installable() (
  local output
  output=$(lsi_migration_show ubuntu-005) || return 1
  grep -q '^Disposition   : blocked-third-party$' <<< "$output" &&
    grep -q '^Route strategy: vendor-apt$' <<< "$output" &&
    grep -q '^Proposed result: visual-studio-code$' <<< "$output" &&
    grep -q 'unresolved; no supported automated replacement exists yet' <<< "$output" &&
    ! grep -q '^Inspect       :' <<< "$output" &&
    ! grep -Eq '(apt-get|dnf)[[:space:]]+(install|-y)' <<< "$output"
)

test_list_is_complete_and_nonclaiming() (
  local output count
  output=$(lsi_migration_list) || return 1
  count=$(grep -Ec '^(ubuntu|rhel)-[a-z0-9-]+[[:space:]]+' <<< "$output")
  [[ $count -eq 355 ]] &&
    grep -q '355 entries: 84 terminal, 142 provisional, 129 unresolved third-party' <<< "$output" &&
    grep -q 'not support claims' <<< "$output" &&
    grep -q 'Read-only migration guidance' <<< "$output"
)

test_retirement_status_reports_exact_blockers() (
  local output
  output=$(lsi_migration_retirement_status) || return 1
  grep -q '^Tracked legacy entries        : 355$' <<< "$output" &&
    grep -q '^Terminal dispositions         : 84$' <<< "$output" &&
    grep -q '^Provisional module candidates : 142$' <<< "$output" &&
    grep -q '^Unresolved third-party routes : 129$' <<< "$output" &&
    grep -q '^Accepted evidence admissions  : 0$' <<< "$output" &&
    grep -q '^Registered live providers     : 0$' <<< "$output" &&
    grep -q '^Retirement decision           : NOT READY$' <<< "$output" &&
    grep -q 'Candidate module mappings do not become replacements' <<< "$output"
)

test_unknown_and_unsafe_ids_fail() (
  ! lsi_migration_show does-not-exist > /dev/null 2>&1 &&
    ! lsi_migration_show ../../legacy > /dev/null 2>&1 &&
    ! lsi_migration_show 'Ubuntu-002' > /dev/null 2>&1
)

test_bad_header_fails_closed() (
  local case_dir
  case_dir=$(prepare_case)
  sed -i '1s/^legacy_id/bad_id/' "$case_dir/legacy-inventory.tsv"
  use_case "$case_dir"
  ! lsi_migration_load > /dev/null 2>&1 &&
    [[ $LSI_MIGRATION_TOTAL -eq 0 && ${#LSI_MIGRATION_ROWS[@]} -eq 0 ]]
)

test_duplicate_id_fails_closed() (
  local case_dir
  case_dir=$(prepare_case)
  sed -i '3s/^ubuntu-002/ubuntu-001/' "$case_dir/legacy-inventory.tsv"
  use_case "$case_dir"
  ! lsi_migration_load > /dev/null 2>&1
)

test_empty_middle_field_fails_closed() (
  local case_dir
  case_dir=$(prepare_case)
  sed -i $'2s/\tPHP7.3 (PPA)\t/\t\t/' "$case_dir/legacy-inventory.tsv"
  use_case "$case_dir"
  ! lsi_migration_load > /dev/null 2>&1
)

test_unsafe_source_path_fails_closed() (
  local case_dir rhel_case
  case_dir=$(prepare_case)
  sed -i '2s#legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh#legacy/../escape.sh#' \
    "$case_dir/legacy-inventory.tsv"
  use_case "$case_dir"
  ! lsi_migration_load > /dev/null 2>&1 || return 1

  rhel_case=$(prepare_case)
  sed -i \
    '161s#legacy/rhel-family/AlmaLinux-8/scripts/1-Php.sh#legacy/rhel-family/../scripts/foo.sh#' \
    "$rhel_case/legacy-inventory.tsv"
  use_case "$rhel_case"
  ! lsi_migration_load > /dev/null 2>&1
)

test_unsafe_evidence_references_fail_closed() (
  local project
  lsi_migration_validate_evidence \
    test-row retired 'https://example.com/evidence/report' > /dev/null 2>&1 || return 1
  ! lsi_migration_validate_evidence test-row retired 'https://' > /dev/null 2>&1 || return 1
  ! lsi_migration_validate_evidence \
    test-row retired 'https://example.com/bad url' > /dev/null 2>&1 || return 1
  ! lsi_migration_validate_evidence \
    test-row retired 'docs/../README.md' > /dev/null 2>&1 || return 1

  project=$(mktemp -d "$TEST_TMP/evidence-project.XXXXXX")
  mkdir -p "$project/docs/real"
  printf 'test evidence\n' > "$project/docs/real/report.md"
  ln -s real "$project/docs/linked"
  LSI_PROJECT_ROOT=$project
  ! lsi_migration_validate_evidence \
    test-row retired 'docs/linked/report.md' > /dev/null 2>&1 || return 1

  mkdir "$project/docs/hardlinked"
  printf 'test evidence\n' > "$project/docs/hardlinked/report.md"
  ln "$project/docs/hardlinked/report.md" "$project/docs/hardlinked/report-peer.md"
  ! lsi_migration_validate_evidence \
    test-row retired 'docs/hardlinked/report.md' > /dev/null 2>&1
)

test_linked_module_manifests_fail_closed() (
  local catalog source
  catalog=$(mktemp -d "$TEST_TMP/module-catalog.XXXXXX")
  source=$ROOT_DIR/modules/nginx/module.sh

  ln -s "$ROOT_DIR/modules/nginx" "$catalog/nginx"
  LSI_MODULE_DIR=$catalog
  ! lsi_module_manifest_is_safe nginx || return 1

  rm "$catalog/nginx"
  mkdir "$catalog/nginx"
  cp "$source" "$catalog/nginx/module.sh"
  ln "$catalog/nginx/module.sh" "$catalog/nginx/module-peer.sh"
  if lsi_module_manifest_is_safe nginx; then
    return 1
  fi
  rm "$catalog/nginx/module.sh" "$catalog/nginx/module-peer.sh"
)

test_unvalidated_terminal_replacement_fails_closed() (
  local case_dir
  case_dir=$(prepare_case)
  sed -i $'3s#\tplanned\tnginx\tintent\t-\t#\timplemented\tnginx\tintent\tdocs/MIGRATION.md\t#' \
    "$case_dir/legacy-inventory.tsv"
  use_case "$case_dir"
  ! lsi_migration_load > /dev/null 2>&1
)

test_binary_or_unterminated_input_fails_closed() (
  local case_dir
  case_dir=$(prepare_case)
  printf '\0' >> "$case_dir/legacy-inventory.tsv"
  use_case "$case_dir"
  ! lsi_migration_load > /dev/null 2>&1
)

test_backlog_join_and_action_fail_closed() (
  local missing_case bad_action_case
  missing_case=$(prepare_case)
  sed -i '/^ubuntu-005/d' "$missing_case/provider-backlog.tsv"
  use_case "$missing_case"
  ! lsi_migration_load > /dev/null 2>&1 || return 1

  bad_action_case=$(prepare_case)
  sed -i $'2s/\timplement\t/\tterminal-handoff\t/' \
    "$bad_action_case/provider-backlog.tsv"
  use_case "$bad_action_case"
  ! lsi_migration_load > /dev/null 2>&1
)

test_symlink_and_hardlink_ledgers_fail_closed() (
  local symlink_case hardlink_case
  symlink_case=$(prepare_case)
  rm "$symlink_case/legacy-inventory.tsv"
  ln -s "$ROOT_DIR/docs/legacy-inventory.tsv" "$symlink_case/legacy-inventory.tsv"
  use_case "$symlink_case"
  ! lsi_migration_load > /dev/null 2>&1 || return 1

  hardlink_case=$(prepare_case)
  mv "$hardlink_case/legacy-inventory.tsv" "$hardlink_case/inventory-origin.tsv"
  ln "$hardlink_case/inventory-origin.tsv" "$hardlink_case/legacy-inventory.tsv"
  use_case "$hardlink_case"
  ! lsi_migration_load > /dev/null 2>&1
)

test_failed_reload_clears_previous_state() (
  local case_dir
  lsi_migration_load || return 1
  [[ $LSI_MIGRATION_TOTAL -eq 355 ]] || return 1

  case_dir=$(prepare_case)
  sed -i '1s/^legacy_id/bad_id/' "$case_dir/legacy-inventory.tsv"
  use_case "$case_dir"
  ! lsi_migration_load > /dev/null 2>&1 || return 1
  [[ $LSI_MIGRATION_TOTAL -eq 0 &&
    ${#LSI_MIGRATION_IDS[@]} -eq 0 &&
    ${#LSI_MIGRATION_ROWS[@]} -eq 0 &&
    ${#LSI_MIGRATION_BACKLOG_ROWS[@]} -eq 0 ]]
)

test_public_cli_is_exact_and_location_independent() (
  local output
  output=$(cd "$TEST_TMP" && "$ROOT_DIR/install.sh" migrate ubuntu-005) || return 1
  grep -q '^Legacy ID     : ubuntu-005$' <<< "$output" &&
    output=$(cd "$TEST_TMP" && "$ROOT_DIR/install.sh" retirement-status) &&
    grep -q '^Retirement decision           : NOT READY$' <<< "$output" &&
    ! "$ROOT_DIR/install.sh" migrate > /dev/null 2>&1 &&
    ! "$ROOT_DIR/install.sh" migrate ubuntu-005 extra > /dev/null 2>&1 &&
    ! "$ROOT_DIR/install.sh" migrations extra > /dev/null 2>&1 &&
    ! "$ROOT_DIR/install.sh" retirement-status extra > /dev/null 2>&1
)

test_public_cli_ignores_exported_shell_functions() (
  local output marker="$TEST_TMP/hostile-function-ran"
  export LSI_MIGRATION_TEST_MARKER=$marker
  stat() {
    /usr/bin/touch "$LSI_MIGRATION_TEST_MARKER"
    return 9
  }
  lsi_load_module() {
    /usr/bin/touch "$LSI_MIGRATION_TEST_MARKER"
    return 9
  }
  export -f stat lsi_load_module

  output=$("$ROOT_DIR/install.sh" migrate ubuntu-002) || return 1
  grep -q '^Legacy ID     : ubuntu-002$' <<< "$output" && [[ ! -e $marker ]]
)

run_test 'canonical 355-row migration catalog loads' test_canonical_catalog_loads
run_test 'planned lookup remains explicitly provisional' test_planned_lookup_is_provisional
run_test 'terminal lookup is a documented handoff' test_terminal_lookup_is_handoff
run_test 'blocked lookup cannot become an install command' test_blocked_lookup_is_not_installable
run_test 'complete list reports counts without support claims' test_list_is_complete_and_nonclaiming
run_test 'retirement status reports exact remaining blockers' test_retirement_status_reports_exact_blockers
run_test 'unknown and unsafe legacy IDs are rejected' test_unknown_and_unsafe_ids_fail
run_test 'unexpected inventory header fails closed' test_bad_header_fails_closed
run_test 'duplicate legacy IDs fail closed' test_duplicate_id_fails_closed
run_test 'empty middle fields fail closed' test_empty_middle_field_fails_closed
run_test 'unsafe source locators fail closed' test_unsafe_source_path_fails_closed
run_test 'unsafe evidence references fail closed' test_unsafe_evidence_references_fail_closed
run_test 'linked module manifests fail closed' test_linked_module_manifests_fail_closed
run_test 'unvalidated terminal replacements fail closed' test_unvalidated_terminal_replacement_fails_closed
run_test 'binary or unterminated input fails closed' test_binary_or_unterminated_input_fails_closed
run_test 'backlog coverage and action mapping fail closed' test_backlog_join_and_action_fail_closed
run_test 'symlinked and hardlinked ledgers fail closed' test_symlink_and_hardlink_ledgers_fail_closed
run_test 'failed reload clears all partial state' test_failed_reload_clears_previous_state
run_test 'public CLI arity and working directory are deterministic' test_public_cli_is_exact_and_location_independent
run_test 'public CLI ignores exported shell functions' test_public_cli_ignores_exported_shell_functions

printf '\n%d passed, %d failed\n' "$PASS_COUNT" "$FAIL_COUNT"
((FAIL_COUNT == 0))
