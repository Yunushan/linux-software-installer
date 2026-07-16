#!/usr/bin/env bash
set -uo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=python.sh
source "$ROOT_DIR/tests/python.sh"
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
TEST_COUNT=0

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  TEST_COUNT=$((TEST_COUNT + 1))
  printf 'ok %d - %s\n' "$TEST_COUNT" "$1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf 'not ok - %s\n' "$1" >&2
}

skip() {
  SKIP_COUNT=$((SKIP_COUNT + 1))
  TEST_COUNT=$((TEST_COUNT + 1))
  printf 'ok %d - %s # SKIP %s\n' "$TEST_COUNT" "$1" "$2"
}

run_test() {
  local name=$1 status
  shift
  "$@"
  status=$?
  if [[ $status -eq 0 ]]; then
    pass "$name"
  elif [[ $status -eq 77 ]]; then
    skip "$name" 'POSIX Python 3.8+ with O_NOFOLLOW is unavailable'
  elif [[ $status -eq 78 ]]; then
    skip "$name" 'Git is unavailable (legacy snapshot integrity cannot be checked)'
  else
    fail "$name"
  fi
}

test_python_available() {
  lsi_find_python > /dev/null
}

test_syntax() {
  local file
  bash -n "$ROOT_DIR/bin/linux-software-installer" "$ROOT_DIR/bin/provider-catalog" || return 1
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
  count=$(grep -Ec '^[a-z0-9][a-z0-9-]*[[:space:]]+' <<< "$output")
  [[ $count -eq 103 ]] && grep -q '^nginx' <<< "$output" && grep -q '^postgresql' <<< "$output"
}

test_all_declared_module_plans() (
  local module family fixture output target_id ref_env display_name target_family
  local image platform expected_os_id expected_version expected_arch
  local -a families=()
  export LSI_PROJECT_ROOT="$ROOT_DIR"
  # shellcheck source=../lib/common.sh
  source "$ROOT_DIR/lib/common.sh"
  # shellcheck source=../lib/catalog.sh
  source "$ROOT_DIR/lib/catalog.sh"

  lsi_discover_modules
  for module in "${LSI_MODULE_IDS[@]}"; do
    lsi_load_module "$module"
    families=("${MODULE_FAMILIES[@]}")
    for family in "${families[@]}"; do
      fixture=''
      while IFS=$'\t' read -r target_id ref_env display_name target_family image \
        platform expected_os_id expected_version expected_arch; do
        [[ $target_id != target_id && $target_family == "$family" ]] || continue
        lsi_module_supports_target "$family" "$expected_os_id" \
          "$expected_version" "$expected_arch" || continue
        case "$target_id" in
          ubuntu-24-04) fixture="$ROOT_DIR/tests/fixtures/ubuntu.env" ;;
          ubuntu-26-04) fixture="$ROOT_DIR/tests/fixtures/ubuntu26.env" ;;
          debian-12) fixture="$ROOT_DIR/tests/fixtures/debian.env" ;;
          rocky-9-8) fixture="$ROOT_DIR/tests/fixtures/rocky.env" ;;
          alma-9-8) fixture="$ROOT_DIR/tests/fixtures/almalinux.env" ;;
          *) continue ;;
        esac
        break
      done < "$ROOT_DIR/tests/evidence-targets.tsv"
      [[ -n $fixture ]] || {
        printf 'No declared Tier-1 target can plan %s for %s\n' "$module" "$family" >&2
        return 1
      }

      if ! output=$(LSI_OS_RELEASE_FILE="$fixture" \
        "$ROOT_DIR/install.sh" plan --no-refresh "$module" 2>&1); then
        printf 'Planning failed for %s on %s\n%s\n' "$module" "$family" "$output" >&2
        return 1
      fi

      case "$family" in
        debian) grep -q 'apt-get install' <<< "$output" || return 1 ;;
        rhel) grep -q 'dnf -y install' <<< "$output" || return 1 ;;
      esac
    done
  done
)

test_module_schema_and_safety() (
  local module family token conflict
  local -a families=() packages=() binaries=() conflicts=()
  local -A seen_families=()
  export LSI_PROJECT_ROOT="$ROOT_DIR"
  # shellcheck source=../lib/common.sh
  source "$ROOT_DIR/lib/common.sh"
  # shellcheck source=../lib/catalog.sh
  source "$ROOT_DIR/lib/catalog.sh"

  lsi_discover_modules
  for module in "${LSI_MODULE_IDS[@]}"; do
    lsi_load_module "$module"
    [[ $MODULE_STATUS == stable && $MODULE_RISK == low ]] || {
      printf '%s must be a stable, low-risk active module\n' "$module" >&2
      return 1
    }

    families=("${MODULE_FAMILIES[@]}")
    conflicts=("${MODULE_CONFLICTS[@]}")
    seen_families=()
    for family in "${families[@]}"; do
      [[ $family == debian || $family == rhel ]] || {
        printf '%s declares unknown family: %s\n' "$module" "$family" >&2
        return 1
      }
      [[ -z ${seen_families[$family]+x} ]] || {
        printf '%s declares family twice: %s\n' "$module" "$family" >&2
        return 1
      }
      seen_families[$family]=1

      case "$family" in
        debian)
          packages=("${MODULE_DEBIAN_PACKAGES[@]}")
          binaries=("${MODULE_DEBIAN_VERIFY_BINARIES[@]}")
          ;;
        rhel)
          packages=("${MODULE_RHEL_PACKAGES[@]}")
          binaries=("${MODULE_RHEL_VERIFY_BINARIES[@]}")
          ;;
      esac
      ((${#packages[@]} > 0)) || {
        printf '%s has no package mapping for %s\n' "$module" "$family" >&2
        return 1
      }
      ((${#binaries[@]} > 0)) || binaries=("${MODULE_VERIFY_BINARIES[@]}")
      ((${#binaries[@]} > 0)) || {
        printf '%s has no verification-binary declaration for %s\n' "$module" "$family" >&2
        return 1
      }
    done

    [[ -n ${seen_families[debian]+x} || ${#MODULE_DEBIAN_PACKAGES[@]} -eq 0 ]] || return 1
    [[ -n ${seen_families[rhel]+x} || ${#MODULE_RHEL_PACKAGES[@]} -eq 0 ]] || return 1

    for token in \
      "${MODULE_DEBIAN_PACKAGES[@]}" "${MODULE_RHEL_PACKAGES[@]}" \
      "${MODULE_DEBIAN_SERVICES[@]}" "${MODULE_RHEL_SERVICES[@]}" \
      "${MODULE_VERIFY_BINARIES[@]}" "${MODULE_DEBIAN_VERIFY_BINARIES[@]}" \
      "${MODULE_RHEL_VERIFY_BINARIES[@]}"; do
      [[ -z $token || $token =~ ^[a-zA-Z0-9][a-zA-Z0-9+._:@/-]*$ ]] || {
        printf '%s contains an unsafe manifest token: %s\n' "$module" "$token" >&2
        return 1
      }
    done

    for conflict in "${conflicts[@]}"; do
      if ! lsi_valid_slug "$conflict" || [[ ! -f "$ROOT_DIR/modules/$conflict/module.sh" ]]; then
        printf '%s declares an invalid conflict: %s\n' "$module" "$conflict" >&2
        return 1
      fi
      (
        lsi_load_module "$conflict"
        [[ " ${MODULE_CONFLICTS[*]} " == *" $module "* ]]
      ) || {
        printf 'Conflict must be symmetric: %s <-> %s\n' "$module" "$conflict" >&2
        return 1
      }
    done
  done
)

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

test_conflict_safe_catalog_batches() (
  local family batch module conflict expected_count batch_output
  local -a conflicts=()
  local -A expected=() seen=() in_batch=()
  export LSI_PROJECT_ROOT="$ROOT_DIR"
  source "$ROOT_DIR/lib/common.sh"
  source "$ROOT_DIR/lib/catalog.sh"

  for family in debian rhel; do
    expected=()
    seen=()
    lsi_discover_modules
    for module in "${LSI_MODULE_IDS[@]}"; do
      lsi_load_module "$module"
      lsi_module_supports_family "$family" && expected["$module"]=1
    done
    expected_count=${#expected[@]}

    for batch in 0 1; do
      batch_output=$(lsi_catalog_batch_modules "$family" "$batch" 2) || return 1
      in_batch=()
      while IFS= read -r module; do
        [[ -n $module && -n ${expected[$module]+x} && -z ${seen[$module]+x} ]] || return 1
        seen["$module"]=1
        in_batch["$module"]=1
      done <<< "$batch_output"

      for module in "${!in_batch[@]}"; do
        lsi_load_module "$module"
        conflicts=("${MODULE_CONFLICTS[@]}")
        for conflict in "${conflicts[@]}"; do
          [[ -z ${in_batch[$conflict]+x} ]] || return 1
        done
      done
    done

    [[ ${#seen[@]} -eq $expected_count ]] || return 1
  done
)

test_standalone_evidence_matrices() {
  local all debian rhel filtered all_cells debian_cells rhel_cells
  local all_count debian_count rhel_count filtered_count
  local all_cell_count debian_cell_count rhel_cell_count unique_cell_count
  local cell_id target_id family module image platform expected_os_id
  local expected_version_id expected_arch contract contract_key
  declare -A checked_contracts=()
  all=$(bash "$ROOT_DIR/tests/evidence-matrix.sh" "$ROOT_DIR" matrix all) || return 1
  debian=$(bash "$ROOT_DIR/tests/evidence-matrix.sh" "$ROOT_DIR" matrix debian) || return 1
  rhel=$(bash "$ROOT_DIR/tests/evidence-matrix.sh" "$ROOT_DIR" matrix rhel) || return 1
  filtered=$(bash "$ROOT_DIR/tests/evidence-matrix.sh" "$ROOT_DIR" matrix all git) || return 1
  all_cells=$(bash "$ROOT_DIR/tests/evidence-matrix.sh" "$ROOT_DIR" cells all) || return 1
  debian_cells=$(bash "$ROOT_DIR/tests/evidence-matrix.sh" "$ROOT_DIR" cells debian) || return 1
  rhel_cells=$(bash "$ROOT_DIR/tests/evidence-matrix.sh" "$ROOT_DIR" cells rhel) || return 1
  all_count=$(grep -o '"module":' <<< "$all" | wc -l)
  debian_count=$(grep -o '"module":' <<< "$debian" | wc -l)
  rhel_count=$(grep -o '"module":' <<< "$rhel" | wc -l)
  filtered_count=$(grep -o '"module":' <<< "$filtered" | wc -l)
  all_cell_count=$(tail -n +2 <<< "$all_cells" | wc -l)
  debian_cell_count=$(tail -n +2 <<< "$debian_cells" | wc -l)
  rhel_cell_count=$(tail -n +2 <<< "$rhel_cells" | wc -l)
  unique_cell_count=$(tail -n +2 <<< "$all_cells" | cut -f 1 | sort -u | wc -l)
  while IFS=$'\t' read -r cell_id target_id family module image platform \
    expected_os_id expected_version_id expected_arch; do
    [[ -n $cell_id && -n $target_id && -n $image && -n $platform &&
      -n $expected_os_id && -n $expected_version_id && -n $expected_arch ]] || return 1
    contract_key="$family/$module"
    [[ -z ${checked_contracts[$contract_key]+x} ]] || continue
    checked_contracts["$contract_key"]=1
    contract=$(bash "$ROOT_DIR/tests/evidence-contract.sh" \
      "$ROOT_DIR" "$module" "$family" "$expected_os_id" \
      "$expected_version_id" "$expected_arch") || return 1
    [[ $(head -n 1 <<< "$contract") == $'type\tvalue' ]] || return 1
    grep -Eq $'^package\t[^[:space:]]+$' <<< "$contract" || return 1
    grep -Eq $'^verification_binary\t[^[:space:]]+$' <<< "$contract" || return 1
    ! grep -q $'\t$' <<< "$contract" || return 1
  done < <(tail -n +2 <<< "$all_cells")
  [[ ${#checked_contracts[@]} -eq 138 ]] &&
    [[ $all_count -eq 103 && $debian_count -eq 100 && $rhel_count -eq 38 ]] &&
    [[ $filtered_count -eq 1 && $all_cell_count -eq 370 ]] &&
    [[ $debian_cell_count -eq 294 && $rhel_cell_count -eq 76 ]] &&
    [[ $unique_cell_count -eq 370 ]] &&
    ! bash "$ROOT_DIR/tests/evidence-matrix.sh" \
      "$ROOT_DIR" matrix debian firewalld > /dev/null 2>&1
}

test_evidence_record_integrity() {
  test_python_available || return 77
  bash "$ROOT_DIR/tests/test-evidence-record.sh"
}

test_python_runtime_resolver() {
  bash "$ROOT_DIR/tests/python-unit.sh"
}

test_workflow_security_contract() {
  bash "$ROOT_DIR/tests/validate-workflow-security.sh" > /dev/null
}

test_evidence_container_cleanup_contract() {
  bash "$ROOT_DIR/tests/test-container-cleanup.sh"
}

test_evidence_log_capture_contract() {
  bash "$ROOT_DIR/tests/test-evidence-log-capture.sh"
}

test_legacy_inventory_contract() {
  bash "$ROOT_DIR/tests/validate-legacy-inventory.sh" > /dev/null
}

test_legacy_promotion_readiness_contract() {
  test_python_available || return 77
  bash "$ROOT_DIR/tests/validate-legacy-promotion-readiness.sh" > /dev/null
}

test_accepted_evidence_admission_contract() {
  local python
  python=$(lsi_find_python) || return 77
  "$python" "$ROOT_DIR/tests/test-accepted-evidence.py" > /dev/null
}

test_downloaded_evidence_artifact_contract() {
  local python
  python=$(lsi_find_python) || return 77
  "$python" "$ROOT_DIR/tests/test-accepted-evidence-artifact.py" > /dev/null
}

test_legacy_quarantine_contract() {
  command -v git > /dev/null 2>&1 || return 78
  bash "$ROOT_DIR/tests/validate-legacy-quarantine.sh" > /dev/null
}

test_provider_backlog_contract() {
  bash "$ROOT_DIR/tests/validate-provider-backlog.sh" > /dev/null
}

test_migration_lookup_contract() {
  bash "$ROOT_DIR/tests/migration-unit.sh" > /dev/null
}

test_provider_catalog_contract() {
  bash "$ROOT_DIR/tests/provider-unit.sh" > /dev/null
}

test_operational_safety_contract() {
  bash "$ROOT_DIR/tests/operational-unit.sh" > /dev/null
}

test_systemd_evidence_contract() {
  test_python_available || return 77
  bash "$ROOT_DIR/tests/test-systemd-evidence.sh" > /dev/null
}

test_exact_target_cell_contract() {
  test_python_available || return 77
  bash "$ROOT_DIR/tests/target-cell-unit.sh" > /dev/null
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

test_rhel_curl_uses_minimal_provider() {
  local output
  output=$(LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/rocky.env" \
    "$ROOT_DIR/install.sh" plan --no-refresh base-tools curl 2>&1) || return 1
  grep -q 'dnf -y install ca-certificates curl-minimal' <<< "$output" &&
    grep -q 'dnf -y install curl-minimal ca-certificates' <<< "$output" &&
    ! grep -q 'dnf -y install curl ' <<< "$output"
}

test_rhel_container_smoke_contract() {
  LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/rocky.env" \
    LSI_PACKAGE_MANAGER=true \
    bash "$ROOT_DIR/tests/container-smoke.sh" "$ROOT_DIR" > /dev/null 2>&1
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

test_ubuntu16_guard() {
  ! LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu16.env" \
    "$ROOT_DIR/install.sh" plan --no-refresh git > /dev/null 2>&1
}

test_ubuntu16_explicit_override() {
  LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu16.env" \
    "$ROOT_DIR/install.sh" plan --no-refresh --force-unsupported git > /dev/null 2>&1
}

test_repository_refresh_once() {
  local output count
  output=$(LSI_OS_RELEASE_FILE="$ROOT_DIR/tests/fixtures/ubuntu.env" \
    "$ROOT_DIR/install.sh" plan nginx git 2>&1) || return 1
  count=$(grep -c 'apt-get update' <<< "$output")
  [[ $count -eq 1 ]]
}

test_explicit_service_activation_is_opt_in() {
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
run_test 'module catalog count and discoverability match' test_module_catalog
run_test 'every module plans for every declared family' test_all_declared_module_plans
run_test 'module manifests satisfy schema and token safety rules' test_module_schema_and_safety
run_test 'all profile entries resolve to module manifests' test_all_profile_modules_exist
run_test 'legacy inventory reconciles all 355 source entries' test_legacy_inventory_contract
run_test 'planned legacy rows have a fail-closed promotion ledger' test_legacy_promotion_readiness_contract
run_test 'accepted evidence admissions bind external artifacts to exact contracts' test_accepted_evidence_admission_contract
run_test 'downloaded GitHub evidence artifacts are revalidated before admission' test_downloaded_evidence_artifact_contract
run_test 'legacy snapshot is pinned and excluded from the active path' test_legacy_quarantine_contract
run_test 'provider backlog covers every unresolved third-party row' test_provider_backlog_contract
run_test 'read-only migration lookup fails closed on ledger drift' test_migration_lookup_contract
run_test 'read-only provider catalog rejects unsafe trust metadata' test_provider_catalog_contract
run_test 'operational behavior fails closed without Docker or systemd' test_operational_safety_contract
run_test 'systemd VM evidence is exact, single-use and provisional only' test_systemd_evidence_contract
run_test 'exact target cells gate runtime and evidence support' test_exact_target_cell_contract
run_test 'Ubuntu dry run emits apt-get commands' test_ubuntu_plan
run_test 'Rocky dry run emits dnf commands' test_rocky_plan
run_test 'RHEL curl modules use the non-conflicting minimal provider' test_rhel_curl_uses_minimal_provider
run_test 'RHEL plans satisfy the container smoke contract' test_rhel_container_smoke_contract
run_test 'profiles filter modules by distro family' test_profile_family_filter
run_test 'unknown modules are rejected' test_unknown_module_rejected
run_test 'module path traversal is rejected' test_path_traversal_rejected
run_test 'declared module conflicts are rejected' test_conflict_rejected
run_test 'real-install catalog batches cover every module without conflicts' test_conflict_safe_catalog_batches
run_test 'standalone evidence matrices cover every module-image cell' test_standalone_evidence_matrices
run_test 'standalone evidence records detect payload tampering' test_evidence_record_integrity
run_test 'Python runtime resolver rejects broken command aliases' test_python_runtime_resolver
run_test 'container workflows preserve the evidence trust boundary' test_workflow_security_contract
run_test 'evidence cleanup verifies exact container absence' test_evidence_container_cleanup_contract
run_test 'evidence log capture preserves installer ownership checks' test_evidence_log_capture_contract
run_test 'CentOS 7 is blocked from the active installer' test_centos7_guard
run_test 'legacy-version bypass must be explicit' test_centos7_explicit_override
run_test 'Ubuntu 16.04 is blocked from the active installer' test_ubuntu16_guard
run_test 'Ubuntu legacy-version bypass must be explicit' test_ubuntu16_explicit_override
run_test 'repository metadata refreshes only once per plan' test_repository_refresh_once
run_test 'explicit systemctl activation is opt-in' test_explicit_service_activation_is_opt_in
run_test 'family-incompatible direct modules are rejected' test_unsupported_direct_module_rejected
run_test 'comma-separated module input is supported' test_csv_module_input

printf '\n%d passed, %d skipped, %d failed\n' "$PASS_COUNT" "$SKIP_COUNT" "$FAIL_COUNT"
((FAIL_COUNT == 0))
