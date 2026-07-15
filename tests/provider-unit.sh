#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2329 # Hostile functions are invoked indirectly after export to a child shell.
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
FIXTURE_DIR="$ROOT_DIR/tests/fixtures/providers"
TEST_TMP=$(mktemp -d "${TMPDIR:-/tmp}/lsi-provider-unit.XXXXXX")
trap 'rm -rf -- "$TEST_TMP"' EXIT

if ! command -v gpg > /dev/null 2>&1; then
  if [[ ${LSI_REQUIRE_REAL_GPG:-0} == 1 ]]; then
    printf '%s\n' 'ERROR: LSI_REQUIRE_REAL_GPG=1 but no real GnuPG executable is available.' >&2
    exit 2
  fi
  printf '%s\n' \
    'NOTE: GnuPG is unavailable; provider-unit.sh is using the explicit on-disk fixture parser.' \
    'NOTE: Real OpenPGP parsing is not covered by this local run; production remains fail-closed.' >&2
  mkdir -p "$TEST_TMP/tools"
  cp "$FIXTURE_DIR/tools/gpg" "$TEST_TMP/tools/gpg"
  chmod 0700 "$TEST_TMP/tools/gpg"
  export PATH="$TEST_TMP/tools:$PATH"
fi

export LSI_PROJECT_ROOT="$ROOT_DIR"
export LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid"
# shellcheck source=../lib/common.sh
source "$ROOT_DIR/lib/common.sh"
# shellcheck source=../lib/os.sh
source "$ROOT_DIR/lib/os.sh"
# shellcheck source=../lib/provider_catalog.sh
source "$ROOT_DIR/lib/provider_catalog.sh"

PASS_COUNT=0
FAIL_COUNT=0
CASE_COUNT=0
CASE_ROOT=''

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
  CASE_COUNT=$((CASE_COUNT + 1))
  CASE_ROOT="$TEST_TMP/case-$CASE_COUNT"
  mkdir -p "$CASE_ROOT"
  cp -R "$FIXTURE_DIR/valid/." "$CASE_ROOT/"
  LSI_PROVIDER_ROOT=$CASE_ROOT
}

refresh_registry() {
  local root=$1 token provider_id revision digest
  local temporary_registry="$root/.registry.tsv.new"
  shift
  {
    printf 'provider_id\tcatalog_revision\tcatalog_sha256\n'
    for token in "$@"; do
      [[ $token =~ ^([a-z0-9][a-z0-9-]*)@([A-Za-z0-9][A-Za-z0-9._-]*)$ ]] || return 2
      provider_id=${BASH_REMATCH[1]}
      revision=${BASH_REMATCH[2]}
      digest=$(lsi_provider_tree_digest "$root/$provider_id") || return
      printf '%s\t%s\t%s\n' "$provider_id" "$revision" "$digest"
    done
  } > "$temporary_registry"
  mv -- "$temporary_registry" "$root/registry.tsv"
}

corrupt_provider_text_file() {
  local mode=$1 target_file=$2 path content
  case "$target_file" in
    registry.tsv) path="$CASE_ROOT/registry.tsv" ;;
    provider.tsv | cells.tsv | locks.tsv) path="$CASE_ROOT/demo-provider/$target_file" ;;
    *) return 2 ;;
  esac
  case "$mode" in
    nul) printf '\0' >> "$path" ;;
    unterminated)
      content=$(< "$path")
      printf '%s' "$content" > "$path"
      ;;
    nul-unterminated)
      content=$(< "$path")
      printf '%s\0' "$content" > "$path"
      ;;
    *) return 2 ;;
  esac
}

test_invalid_provider_text_bytes() {
  local mode=$1 target_file=$2 output
  prepare_case
  corrupt_provider_text_file "$mode" "$target_file" || return
  if [[ $target_file != registry.tsv ]]; then
    refresh_registry "$CASE_ROOT" demo-provider@2026-01 || return
  fi
  if [[ $target_file == registry.tsv ]]; then
    output=$(lsi_provider_registry_load 2>&1) && return 1
  else
    output=$(lsi_provider_load demo-provider 2>&1) && return 1
  fi
  grep -q 'byte count is inconsistent' <<< "$output"
}

test_schema_documented() {
  local header
  IFS= read -r header < "$ROOT_DIR/providers/schema.tsv"
  [[ $header == $'file_name\tcolumn_index\tcolumn_name\trequired\tvalidation' ]] &&
    grep -q $'^registry.tsv\t1\tprovider_id\tyes\t' "$ROOT_DIR/providers/schema.tsv" &&
    grep -q $'^registry.tsv\t2\tcatalog_revision\tyes\t' "$ROOT_DIR/providers/schema.tsv" &&
    grep -q $'^registry.tsv\t3\tcatalog_sha256\tyes\t64-lowercase-hex-provider-tree-digest$' \
      "$ROOT_DIR/providers/schema.tsv"
}

test_valid_provider_loads() {
  LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid"
  lsi_provider_load demo-provider > /dev/null &&
    [[ $LSI_PROVIDER_ID == demo-provider && ${#LSI_PROVIDER_CELL_ROWS[@]} -eq 2 && ${#LSI_PROVIDER_LOCK_ROWS[@]} -eq 2 ]]
}

test_provider_parser_preserves_glob_options() (
  LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid"
  shopt -u nullglob dotglob
  lsi_provider_tree_digest "$FIXTURE_DIR/valid/demo-provider" > /dev/null || return
  lsi_provider_registry_load || return
  ! shopt -q nullglob && ! shopt -q dotglob || return 1

  shopt -s nullglob dotglob
  lsi_provider_tree_digest "$FIXTURE_DIR/valid/demo-provider" > /dev/null || return
  lsi_provider_registry_load || return
  shopt -q nullglob && shopt -q dotglob
)

test_provider_list_is_read_only_metadata() {
  local output
  LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid"
  output=$(lsi_provider_list) || return 1
  grep -q '^demo-provider' <<< "$output" && grep -q 'Test-only signed repository provider' <<< "$output"
}

test_provider_info_exposes_trust_contract() {
  local output
  LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid"
  output=$(lsi_provider_info demo-provider) || return 1
  grep -q '^WARNING      : local catalog inspection only; no live repository or publisher verification$' <<< "$output" &&
    grep -q '^Revision     : 2026-01$' <<< "$output" &&
    grep -Eq '^Tree SHA-256 : [0-9a-f]{64}$' <<< "$output" &&
    grep -q '^License      : explicit-ack' <<< "$output" &&
    grep -q '^Local key check: declared primary fingerprints match provider-local OpenPGP keys$' <<< "$output" &&
    grep -q '^Live verification: not performed; repository metadata, packages, origin and publisher are unauthenticated$' <<< "$output" &&
    grep -q 'FF8AD1344597106ECE813B918A3872BF3228467C' <<< "$output" &&
    grep -q 'demo-tool=1.2.3-1' <<< "$output"
}

test_exact_cell_matches() {
  local row
  LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid"
  row=$(lsi_provider_select_cell demo-provider ubuntu 24.04 amd64 apt-get) || return 1
  [[ $row == ubuntu-24-04-amd64$'\t'* ]]
}

test_cell_version_is_exact() {
  LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid"
  ! lsi_provider_cell_supported demo-provider ubuntu 24.10 amd64 apt-get > /dev/null 2>&1 &&
    ! lsi_provider_cell_supported demo-provider rocky 9 x86_64 dnf > /dev/null 2>&1
}

test_cell_architecture_is_exact() {
  LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid"
  ! lsi_provider_cell_supported demo-provider rocky 9.8 aarch64 dnf > /dev/null 2>&1
}

test_cell_manager_is_exact() {
  LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid"
  ! lsi_provider_cell_supported demo-provider rocky 9.8 x86_64 apt-get > /dev/null 2>&1
}

test_flat_apt_cell_loads_and_renders() {
  local output
  prepare_case
  sed -i $'s#https://packages.example.invalid/apt/ubuntu/24.04\tstable\tmain#https://packages.example.invalid/apt/flat/\t/\t-#' \
    "$CASE_ROOT/demo-provider/cells.tsv"
  refresh_registry "$CASE_ROOT" demo-provider@2026-01 || return
  output=$(valid_provider_plan "$CASE_ROOT" demo-tool) || return 1
  grep -q '^    repository: https://packages.example.invalid/apt/flat/; channel: stable$' <<< "$output" &&
    grep -q '^    suite: /; components: none (flat repository)$' <<< "$output"
}

test_invalid_normal_apt_coordinates() {
  local field=$1
  prepare_case
  case "$field" in
    suite)
      sed -i $'2s#\tstable\tmain\t#\tstable/\tmain\t#' \
        "$CASE_ROOT/demo-provider/cells.tsv"
      ;;
    component)
      sed -i $'2s#\tstable\tmain\t#\tstable\tmain/\t#' \
        "$CASE_ROOT/demo-provider/cells.tsv"
      ;;
    multiple-suites)
      sed -i $'2s#\tstable\tmain\t#\tstable,testing\tmain\t#' \
        "$CASE_ROOT/demo-provider/cells.tsv"
      ;;
    trailing-component-separator)
      sed -i $'2s#\tstable\tmain\t#\tstable\tmain,\t#' \
        "$CASE_ROOT/demo-provider/cells.tsv"
      ;;
    *) return 2 ;;
  esac
  refresh_registry "$CASE_ROOT" demo-provider@2026-01 || return
  ! lsi_provider_load demo-provider > /dev/null 2>&1
}

valid_provider_plan() {
  LSI_PROVIDER_ROOT=${1:-$FIXTURE_DIR/valid} \
    LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    lsi_provider_plan_current demo-provider \
    --allow-provider demo-provider@2026-01 \
    --allow-preview-provider demo-provider \
    --accept-provider-license demo-provider@2026-01 \
    "${@:2}"
}

snapshot_provider_tree() (
  local sha256_bin
  sha256_bin=$(builtin type -P sha256sum) || return
  cd -- "$1"
  find . -mindepth 1 -printf '%y\t%m\t%n\t%s\t%P\n' | LC_ALL=C sort
  find . -type f -print0 | LC_ALL=C sort -z | xargs -0 "$sha256_bin"
)

test_provider_plan_is_explicit_and_non_mutating() {
  local output before after
  before=$(snapshot_provider_tree "$FIXTURE_DIR/valid") || return 1
  output=$(valid_provider_plan "$FIXTURE_DIR/valid" demo-tool) || return 1
  after=$(snapshot_provider_tree "$FIXTURE_DIR/valid") || return 1
  [[ $before == "$after" ]] &&
    grep -q '^Provider transaction plan (non-mutating)$' <<< "$output" &&
    grep -q '^Host target    : ubuntu 24.04 x86_64 (apt-get)$' <<< "$output" &&
    grep -q '^Authorization .*--yes is not accepted$' <<< "$output" &&
    grep -Eq '^    catalog revision/tree: 2026-01 / [0-9a-f]{64}$' <<< "$output" &&
    grep -q 'demo-tool=1.2.3-1 (amd64)' <<< "$output" &&
    grep -q 'sha256 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa' <<< "$output" &&
    grep -q '^Repository mutation: disabled;' <<< "$output" &&
    grep -Eq '^Plan SHA-256 \(body\): [0-9a-f]{64}$' <<< "$output"
}

test_provider_plan_requires_distinct_authorization() {
  ! LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid" \
    LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    lsi_provider_plan_current demo-provider \
    --allow-preview-provider demo-provider \
    --accept-provider-license demo-provider@2026-01 \
    demo-tool > /dev/null 2>&1
}

test_provider_plan_rejects_yes_alias() {
  ! LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid" \
    LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    lsi_provider_plan_current demo-provider \
    --yes \
    --allow-provider demo-provider@2026-01 \
    --allow-preview-provider demo-provider \
    --accept-provider-license demo-provider@2026-01 \
    demo-tool > /dev/null 2>&1
}

test_provider_plan_requires_preview_ack() {
  ! LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid" \
    LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    lsi_provider_plan_current demo-provider \
    --allow-provider demo-provider@2026-01 \
    --accept-provider-license demo-provider@2026-01 \
    demo-tool > /dev/null 2>&1
}

test_provider_plan_requires_exact_license_revision() {
  ! LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid" \
    LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    lsi_provider_plan_current demo-provider \
    --allow-provider demo-provider@2026-01 \
    --allow-preview-provider demo-provider \
    --accept-provider-license demo-provider@wrong-revision \
    demo-tool > /dev/null 2>&1
}

test_provider_plan_requires_exact_target_cell() {
  ! LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid" \
    LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/debian.env" \
    lsi_provider_plan_current demo-provider \
    --allow-provider demo-provider@2026-01 \
    --allow-preview-provider demo-provider \
    --accept-provider-license demo-provider@2026-01 \
    demo-tool > /dev/null 2>&1
}

test_provider_plan_ignores_package_manager_environment() {
  local output
  output=$(LSI_PACKAGE_MANAGER=dnf valid_provider_plan "$FIXTURE_DIR/valid" demo-tool) || return 1
  grep -q '^Host target    : ubuntu 24.04 x86_64 (apt-get)$' <<< "$output"
}

test_provider_plan_cannot_force_legacy_os() {
  local output
  prepare_case
  sed -i 's/ubuntu-24-04-amd64/ubuntu-16-04-amd64/g; s/\t24[.]04\t/\t16.04\t/g' \
    "$CASE_ROOT/demo-provider/cells.tsv" "$CASE_ROOT/demo-provider/locks.tsv"
  refresh_registry "$CASE_ROOT" demo-provider@2026-01 || return
  if output=$(LSI_FORCE_UNSUPPORTED=true \
    LSI_PROVIDER_ROOT="$CASE_ROOT" \
    LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu16.env" \
    lsi_provider_plan_current demo-provider \
    --allow-provider demo-provider@2026-01 \
    --allow-preview-provider demo-provider \
    --accept-provider-license demo-provider@2026-01 \
    demo-tool 2>&1); then
    return 1
  fi
  grep -q 'Ubuntu 16.04 is legacy-only' <<< "$output"
}

test_provider_plan_rejects_disabled_provider() {
  prepare_case
  sed -i $'s/\trepository\tpreview\tdisabled\t/\trepository\tdisabled\tdisabled\t/' \
    "$CASE_ROOT/demo-provider/provider.tsv"
  refresh_registry "$CASE_ROOT" demo-provider@2026-01 || return
  ! valid_provider_plan "$CASE_ROOT" demo-tool > /dev/null 2>&1
}

test_provider_plan_requires_exact_catalog_revision() {
  ! LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid" \
    LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    lsi_provider_plan_current demo-provider \
    --allow-provider demo-provider@wrong-revision \
    --allow-preview-provider demo-provider \
    --accept-provider-license demo-provider@2026-01 \
    demo-tool > /dev/null 2>&1
}

test_provider_plan_rejects_duplicate_authorization() {
  ! LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid" \
    LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    lsi_provider_plan_current demo-provider \
    --allow-provider demo-provider@2026-01 \
    --allow-provider demo-provider@2026-01 \
    --allow-preview-provider demo-provider \
    --accept-provider-license demo-provider@2026-01 \
    demo-tool > /dev/null 2>&1
}

test_provider_plan_rejects_unrelated_acknowledgement() {
  ! LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid" \
    LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    lsi_provider_plan_current demo-provider \
    --allow-provider demo-provider@2026-01 \
    --allow-preview-provider demo-provider \
    --accept-provider-license demo-provider@2026-01 \
    --allow-provider unrelated-provider@2026-01 \
    demo-tool > /dev/null 2>&1
}

test_provider_plan_requires_auth_acknowledgement() {
  prepare_case
  sed -i $'s/\tnone\t-\t-\tTest-only/\tcredential-file\thttps:\/\/provider.example.invalid\/auth\t-\tTest-only/' \
    "$CASE_ROOT/demo-provider/provider.tsv"
  refresh_registry "$CASE_ROOT" demo-provider@2026-01 || return
  ! valid_provider_plan "$CASE_ROOT" demo-tool > /dev/null 2>&1
}

test_provider_plan_accepts_auth_acknowledgement() {
  local output
  prepare_case
  sed -i $'s/\tnone\t-\t-\tTest-only/\tcredential-file\thttps:\/\/provider.example.invalid\/auth\t-\tTest-only/' \
    "$CASE_ROOT/demo-provider/provider.tsv"
  refresh_registry "$CASE_ROOT" demo-provider@2026-01 || return
  output=$(valid_provider_plan "$CASE_ROOT" --ack-provider-auth demo-provider demo-tool) || return 1
  grep -q '^    authentication: credential-file ' <<< "$output"
}

test_provider_plan_requires_persistence_acknowledgement() {
  prepare_case
  sed -i $'s/\trepository\tpreview\tdisabled\texplicit-ack\t/\trepository\tpreview\tenabled\texplicit-ack\t/' \
    "$CASE_ROOT/demo-provider/provider.tsv"
  refresh_registry "$CASE_ROOT" demo-provider@2026-01 || return
  ! valid_provider_plan "$CASE_ROOT" demo-tool > /dev/null 2>&1
}

test_provider_plan_accepts_persistence_acknowledgement() {
  local output
  prepare_case
  sed -i $'s/\trepository\tpreview\tdisabled\texplicit-ack\t/\trepository\tpreview\tenabled\texplicit-ack\t/' \
    "$CASE_ROOT/demo-provider/provider.tsv"
  refresh_registry "$CASE_ROOT" demo-provider@2026-01 || return
  output=$(valid_provider_plan "$CASE_ROOT" --persist-provider demo-provider demo-tool) || return 1
  grep -q '^    persistence after transaction: enabled$' <<< "$output"
}

test_provider_plan_rejects_missing_package_lock() {
  ! valid_provider_plan "$FIXTURE_DIR/valid" missing-tool > /dev/null 2>&1
}

prepare_dependency_case() {
  prepare_case
  cp -R "$CASE_ROOT/demo-provider" "$CASE_ROOT/base-provider"
  sed -i 's/^demo-provider\t/base-provider\t/' \
    "$CASE_ROOT/base-provider/provider.tsv"
  sed -i $'s/\tnone\t-\t-\tTest-only/\tnone\t-\tbase-provider\tTest-only/' \
    "$CASE_ROOT/demo-provider/provider.tsv"
  refresh_registry "$CASE_ROOT" base-provider@2026-01 demo-provider@2026-01 || return
}

test_provider_dependencies_require_explicit_authorization() {
  prepare_dependency_case
  ! valid_provider_plan "$CASE_ROOT" demo-tool > /dev/null 2>&1
}

test_provider_dependency_closure_is_validated() {
  local output
  prepare_dependency_case
  output=$(LSI_PROVIDER_ROOT="$CASE_ROOT" \
    LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    lsi_provider_plan_current demo-provider \
    --allow-provider demo-provider@2026-01 \
    --allow-provider base-provider@2026-01 \
    --allow-preview-provider demo-provider \
    --allow-preview-provider base-provider \
    --accept-provider-license demo-provider@2026-01 \
    --accept-provider-license base-provider@2026-01 \
    demo-tool) || return 1
  grep -q '^  - base-provider ' <<< "$output" &&
    grep -q '^  - demo-provider ' <<< "$output" &&
    [[ $(grep -c '^Locked primary-provider packages:$' <<< "$output") -eq 1 ]]
}

test_provider_dependency_cycle_is_rejected() {
  prepare_dependency_case
  sed -i $'s/\tnone\t-\t-\tTest-only/\tnone\t-\tdemo-provider\tTest-only/' \
    "$CASE_ROOT/base-provider/provider.tsv"
  refresh_registry "$CASE_ROOT" base-provider@2026-01 demo-provider@2026-01 || return
  ! LSI_PROVIDER_ROOT="$CASE_ROOT" \
    LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    lsi_provider_plan_current demo-provider \
    --allow-provider demo-provider@2026-01 \
    --allow-provider base-provider@2026-01 \
    --allow-preview-provider demo-provider \
    --allow-preview-provider base-provider \
    --accept-provider-license demo-provider@2026-01 \
    --accept-provider-license base-provider@2026-01 \
    demo-tool > /dev/null 2>&1
}

test_provider_path_traversal_rejected() {
  LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid"
  ! lsi_provider_load '../demo-provider' > /dev/null 2>&1
}

test_unknown_provider_rejected() {
  LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid"
  ! lsi_provider_load missing-provider > /dev/null 2>&1
}

test_unregistered_provider_directory_rejected() {
  local output
  prepare_case
  cp -R "$CASE_ROOT/demo-provider" "$CASE_ROOT/unregistered-provider"
  if output=$(lsi_provider_list 2>&1); then
    return 1
  fi
  grep -q 'unregistered' <<< "$output"
}

test_registered_provider_tree_drift_rejected() {
  local output
  prepare_case
  sed -i 's/Test-only signed repository provider/Test-only drifted repository provider/' \
    "$CASE_ROOT/demo-provider/provider.tsv"
  if output=$(lsi_provider_load demo-provider 2>&1); then
    return 1
  fi
  grep -q 'digest is mismatched' <<< "$output"
}

test_invalid_manifest_file() {
  local invalid_file=$1 target_file=$2
  prepare_case
  cp "$FIXTURE_DIR/invalid/$invalid_file" "$CASE_ROOT/demo-provider/$target_file"
  refresh_registry "$CASE_ROOT" demo-provider@2026-01 || return
  ! lsi_provider_load demo-provider > /dev/null 2>&1
}

test_invalid_key_material() {
  prepare_case
  cp "$FIXTURE_DIR/invalid/key-not-openpgp.asc" "$CASE_ROOT/demo-provider/keys/test-only.asc"
  refresh_registry "$CASE_ROOT" demo-provider@2026-01 || return
  ! lsi_provider_load demo-provider > /dev/null 2>&1
}

test_mismatched_key_fingerprint() {
  prepare_case
  sed -i 's/FF8AD1344597106ECE813B918A3872BF3228467C/0000000000000000000000000000000000000000/g' \
    "$CASE_ROOT/demo-provider/cells.tsv"
  refresh_registry "$CASE_ROOT" demo-provider@2026-01 || return
  ! lsi_provider_load demo-provider > /dev/null 2>&1
}

test_public_provider_entry_isolates_caller_environment() (
  local marker="$TEST_TMP/exported-function-ran" output
  trap - EXIT
  export LSI_HOSTILE_MARKER=$marker
  gpg() {
    printf 'gpg\n' >> "$LSI_HOSTILE_MARKER"
    return 99
  }
  mktemp() {
    printf 'mktemp\n' >> "$LSI_HOSTILE_MARKER"
    return 99
  }
  rm() {
    printf 'rm\n' >> "$LSI_HOSTILE_MARKER"
    return 99
  }
  sha256sum() {
    printf 'sha256sum\n' >> "$LSI_HOSTILE_MARKER"
    return 99
  }
  stat() {
    printf 'stat\n' >> "$LSI_HOSTILE_MARKER"
    return 99
  }
  uname() {
    printf 'uname\n' >> "$LSI_HOSTILE_MARKER"
    printf 'malicious\n'
  }
  exec() {
    printf 'exec\n' >> "$LSI_HOSTILE_MARKER"
    return 99
  }
  dirname() {
    printf 'dirname\n' >> "$LSI_HOSTILE_MARKER"
    return 99
  }
  readlink() {
    printf 'readlink\n' >> "$LSI_HOSTILE_MARKER"
    return 99
  }
  export -f gpg mktemp rm sha256sum stat uname exec dirname readlink
  output=$(LSI_PROJECT_ROOT="$FIXTURE_DIR" \
    LSI_PROVIDER_ROOT="$FIXTURE_DIR/valid" \
    LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    LSI_PACKAGE_MANAGER=dnf \
    LSI_FORCE_UNSUPPORTED=true \
    "$ROOT_DIR/install.sh" providers) || return 1
  grep -q '(no registered providers)' <<< "$output" && [[ ! -e $marker ]]
)

test_empty_live_catalog_command() {
  local output
  output=$("$ROOT_DIR/install.sh" providers) || return 1
  grep -q '(no registered providers)' <<< "$output"
}

test_live_provider_info_rejects_untrusted_id() {
  ! "$ROOT_DIR/install.sh" provider-info '../demo-provider' > /dev/null 2>&1
}

test_existing_install_dispatch_is_unchanged() {
  local wrapper_version direct_version
  wrapper_version=$("$ROOT_DIR/install.sh" --version) || return 1
  direct_version=$("$ROOT_DIR/bin/linux-software-installer" --version) || return 1
  [[ $wrapper_version == "$direct_version" ]]
}

test_help_exposes_provider_commands() {
  local output
  output=$("$ROOT_DIR/install.sh" --help) || return 1
  grep -q '^Read-only provider catalog commands:' <<< "$output" &&
    grep -q './install.sh provider-info PROVIDER' <<< "$output" &&
    grep -q './install.sh provider-plan PROVIDER --allow-provider PROVIDER@CATALOG_REVISION' <<< "$output"
}

run_test 'provider schema columns are documented' test_schema_documented
run_test 'valid fixed-column provider catalog loads' test_valid_provider_loads
run_test 'provider registry rejects embedded NUL bytes' test_invalid_provider_text_bytes nul registry.tsv
run_test 'provider registry requires a terminating newline' test_invalid_provider_text_bytes unterminated registry.tsv
run_test 'provider manifest rejects embedded NUL bytes' test_invalid_provider_text_bytes nul provider.tsv
run_test 'provider manifest requires a terminating newline' test_invalid_provider_text_bytes unterminated provider.tsv
run_test 'provider cells reject embedded NUL bytes' test_invalid_provider_text_bytes nul cells.tsv
run_test 'provider cells require a terminating newline' test_invalid_provider_text_bytes unterminated cells.tsv
run_test 'provider locks reject embedded NUL bytes' test_invalid_provider_text_bytes nul locks.tsv
run_test 'provider locks require a terminating newline' test_invalid_provider_text_bytes unterminated locks.tsv
run_test 'registry NUL cannot cancel a missing newline' test_invalid_provider_text_bytes nul-unterminated registry.tsv
run_test 'manifest NUL cannot cancel a missing newline' test_invalid_provider_text_bytes nul-unterminated provider.tsv
run_test 'cells NUL cannot cancel a missing newline' test_invalid_provider_text_bytes nul-unterminated cells.tsv
run_test 'locks NUL cannot cancel a missing newline' test_invalid_provider_text_bytes nul-unterminated locks.tsv
run_test 'provider parsing preserves caller glob options' test_provider_parser_preserves_glob_options
run_test 'provider list exposes read-only metadata' test_provider_list_is_read_only_metadata
run_test 'provider info exposes trust and lock data' test_provider_info_exposes_trust_contract
run_test 'exact OS/version/arch/manager cell matches' test_exact_cell_matches
run_test 'different OS version is rejected' test_cell_version_is_exact
run_test 'different architecture is rejected' test_cell_architecture_is_exact
run_test 'different package manager is rejected' test_cell_manager_is_exact
run_test 'valid flat APT coordinates load and render unambiguously' test_flat_apt_cell_loads_and_renders
run_test 'normal APT suites cannot use exact-path syntax' test_invalid_normal_apt_coordinates suite
run_test 'normal APT components cannot contain path separators' test_invalid_normal_apt_coordinates component
run_test 'normal APT cells require one exact suite' test_invalid_normal_apt_coordinates multiple-suites
run_test 'normal APT component lists cannot end with an empty item' test_invalid_normal_apt_coordinates trailing-component-separator
run_test 'provider plan is explicit and non-mutating' test_provider_plan_is_explicit_and_non_mutating
run_test 'provider plan requires per-provider authorization' test_provider_plan_requires_distinct_authorization
run_test 'provider plan rejects the global --yes alias' test_provider_plan_rejects_yes_alias
run_test 'preview provider requires a separate acknowledgement' test_provider_plan_requires_preview_ack
run_test 'license acknowledgement is revision-bound' test_provider_plan_requires_exact_license_revision
run_test 'provider plan requires an exact target cell' test_provider_plan_requires_exact_target_cell
run_test 'provider plan derives rather than inherits its package manager' test_provider_plan_ignores_package_manager_environment
run_test 'provider plan cannot inherit the legacy-OS escape hatch' test_provider_plan_cannot_force_legacy_os
run_test 'disabled provider cannot be planned' test_provider_plan_rejects_disabled_provider
run_test 'provider authorization is catalog-revision-bound' test_provider_plan_requires_exact_catalog_revision
run_test 'duplicate provider authorization is rejected' test_provider_plan_rejects_duplicate_authorization
run_test 'unrelated provider acknowledgement is rejected' test_provider_plan_rejects_unrelated_acknowledgement
run_test 'credential provider requires an authentication acknowledgement' test_provider_plan_requires_auth_acknowledgement
run_test 'credential provider accepts its exact authentication acknowledgement' test_provider_plan_accepts_auth_acknowledgement
run_test 'persistent provider requires a persistence acknowledgement' test_provider_plan_requires_persistence_acknowledgement
run_test 'persistent provider accepts its exact persistence acknowledgement' test_provider_plan_accepts_persistence_acknowledgement
run_test 'requested provider module requires an exact package lock' test_provider_plan_rejects_missing_package_lock
run_test 'dependencies require explicit authorization' test_provider_dependencies_require_explicit_authorization
run_test 'authorized dependency closure validates deterministically' test_provider_dependency_closure_is_validated
run_test 'provider dependency cycles are rejected' test_provider_dependency_cycle_is_rejected
run_test 'provider ID path traversal is rejected' test_provider_path_traversal_rejected
run_test 'unknown provider is rejected' test_unknown_provider_rejected
run_test 'valid but unregistered provider directory is rejected' test_unregistered_provider_directory_rejected
run_test 'registered provider tree drift is rejected' test_registered_provider_tree_drift_rejected
run_test 'unknown manifest field is rejected' test_invalid_manifest_file provider-unknown-field.tsv provider.tsv
run_test 'self-referencing provider dependency is rejected' test_invalid_manifest_file provider-self-dependency.tsv provider.tsv
run_test 'duplicate provider dependency is rejected' test_invalid_manifest_file provider-duplicate-dependency.tsv provider.tsv
run_test 'non-HTTPS repository is rejected' test_invalid_manifest_file cells-http.tsv cells.tsv
run_test 'short signing fingerprint is rejected' test_invalid_manifest_file cells-short-fingerprint.tsv cells.tsv
run_test 'provider key traversal is rejected' test_invalid_manifest_file cells-key-traversal.tsv cells.tsv
run_test 'wildcard target version is rejected' test_invalid_manifest_file cells-wildcard-version.tsv cells.tsv
run_test 'flat APT repositories cannot declare components' test_invalid_manifest_file cells-flat-components.tsv cells.tsv
run_test 'flat APT repositories require a trailing-slash URI' test_invalid_manifest_file cells-flat-uri.tsv cells.tsv
run_test 'normal APT repositories require components' test_invalid_manifest_file cells-normal-no-components.tsv cells.tsv
run_test 'duplicate target cell is rejected' test_invalid_manifest_file cells-duplicate.tsv cells.tsv
run_test 'duplicate exact target tuple is rejected' test_invalid_manifest_file cells-duplicate-target.tsv cells.tsv
run_test 'DNF package-only signature policy is rejected' test_invalid_manifest_file cells-rpm-package-only.tsv cells.tsv
run_test 'latest package version is rejected' test_invalid_manifest_file locks-latest.tsv locks.tsv
run_test 'short package digest is rejected' test_invalid_manifest_file locks-short-sha.tsv locks.tsv
run_test 'shell-shaped package-lock cell is rejected before lookup' test_invalid_manifest_file locks-invalid-cell.tsv locks.tsv
run_test 'unknown package-lock cell is rejected' test_invalid_manifest_file locks-unknown-cell.tsv locks.tsv
run_test 'non-OpenPGP key material is rejected' test_invalid_key_material
run_test 'declared key fingerprint must match the parsed primary key' test_mismatched_key_fingerprint
run_test 'live provider list has no third-party entries' test_empty_live_catalog_command
run_test 'live provider info rejects path traversal' test_live_provider_info_rejects_untrusted_id
run_test 'public provider entry isolates caller environment and exported functions' test_public_provider_entry_isolates_caller_environment
run_test 'existing package-only dispatch is unchanged' test_existing_install_dispatch_is_unchanged
run_test 'normal help exposes read-only provider commands' test_help_exposes_provider_commands

printf '\n%d passed, %d failed\n' "$PASS_COUNT" "$FAIL_COUNT"
((FAIL_COUNT == 0))
