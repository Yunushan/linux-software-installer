#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
FIXTURE_ROOT="$ROOT_DIR/tests/fixtures/target-cells"
VALID_MODULES="$FIXTURE_ROOT/valid"
INVALID_MODULES="$FIXTURE_ROOT/invalid"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

fail() {
  printf 'Target-cell test failed: %s\n' "$1" >&2
  return 1
}

load_catalog() {
  export LSI_PROJECT_ROOT="$ROOT_DIR"
  # shellcheck source=../lib/common.sh
  source "$ROOT_DIR/lib/common.sh"
  # shellcheck source=../lib/catalog.sh
  source "$ROOT_DIR/lib/catalog.sh"
  LSI_MODULE_DIR="$VALID_MODULES"
}

expect_invalid_module() {
  local module=$1 expected=$2 output status
  set +e
  output=$(LSI_PROJECT_ROOT="$ROOT_DIR" MODULE_DIR="$INVALID_MODULES" \
    bash -c '
      set -uo pipefail
      source "$LSI_PROJECT_ROOT/lib/common.sh"
      source "$LSI_PROJECT_ROOT/lib/catalog.sh"
      LSI_MODULE_DIR=$MODULE_DIR
      lsi_load_module "$1"
    ' _ "$module" 2>&1)
  status=$?
  set -e
  [[ $status -eq 3 ]] || fail "$module metadata returned $status instead of 3"
  grep -q "$expected" <<< "$output" ||
    fail "$module metadata did not report the expected schema error"
}

run_fixture_cli() {
  local os_release=$1
  shift
  LSI_PROJECT_ROOT="$ROOT_DIR" MODULE_DIR="$VALID_MODULES" OS_RELEASE="$os_release" \
    bash -c '
      set -Eeuo pipefail
      source "$LSI_PROJECT_ROOT/lib/common.sh"
      source "$LSI_PROJECT_ROOT/lib/os.sh"
      source "$LSI_PROJECT_ROOT/lib/catalog.sh"
      source "$LSI_PROJECT_ROOT/lib/package.sh"
      source "$LSI_PROJECT_ROOT/lib/cli.sh"
      LSI_MODULE_DIR=$MODULE_DIR
      LSI_OS_RELEASE_FILE=$OS_RELEASE
      lsi_main "$@"
    ' _ "$@"
}

test_manifest_schema_and_matching() (
  load_catalog

  lsi_load_module restricted
  lsi_module_has_target_restrictions || fail 'restricted fixture did not retain its target policy'
  lsi_module_supports_target debian ubuntu 24.04 x86_64 ||
    fail 'exact declared target did not match'
  ! lsi_module_supports_target debian ubuntu 24.04 aarch64 ||
    fail 'architecture mismatch unexpectedly matched'
  ! lsi_module_supports_target debian ubuntu 24.04.1 x86_64 ||
    fail 'near-match VERSION_ID unexpectedly matched an exact declaration'
  ! lsi_module_supports_target debian debian 24.04 x86_64 ||
    fail 'same-family OS ID mismatch unexpectedly matched'

  lsi_load_module family-wide
  ! lsi_module_has_target_restrictions || fail 'family-wide default became restricted'
  lsi_module_supports_target debian compatible-derivative 999 aarch64 ||
    fail 'an existing-style family-wide manifest lost best-effort family support'
  ((${#MODULE_TARGET_CELLS[@]} == 0)) ||
    fail 'target restrictions leaked from the previously loaded manifest'
)

test_schema_rejections() {
  expect_invalid_module malformed 'Malformed target cell'
  expect_invalid_module duplicate 'Duplicate target cell'
  expect_invalid_module unknown 'Unknown target OS ID'
  expect_invalid_module unknown-arch 'Unknown target architecture'
  expect_invalid_module wrong-family 'outside the declared families'
}

test_runtime_plan_and_install_gates() {
  local supported unsupported status
  supported=$(run_fixture_cli "$ROOT_DIR/tests/fixtures/ubuntu.env" \
    plan --no-refresh restricted 2>&1) || fail 'declared Ubuntu target did not plan'
  grep -q 'apt-get install.*git' <<< "$supported" ||
    fail 'declared target plan lacked its package command'

  set +e
  unsupported=$(run_fixture_cli "$ROOT_DIR/tests/fixtures/debian.env" \
    plan --no-refresh restricted 2>&1)
  status=$?
  set -e
  [[ $status -eq 3 ]] || fail "unsupported same-family plan returned $status instead of 3"
  grep -q 'does not support target debian:12:' <<< "$unsupported" ||
    fail 'same-family plan rejection did not name the detected target'

  set +e
  unsupported=$(run_fixture_cli "$ROOT_DIR/tests/fixtures/debian.env" \
    install --yes --no-refresh restricted 2>&1)
  status=$?
  set -e
  [[ $status -eq 3 ]] || fail "unsupported install returned $status instead of 3"
  grep -q 'does not support target debian:12:' <<< "$unsupported" ||
    fail 'install rejection did not occur at the exact target gate'

  run_fixture_cli "$ROOT_DIR/tests/fixtures/debian.env" \
    plan --no-refresh family-wide > /dev/null ||
    fail 'family-wide compatibility was not preserved'
}

test_catalog_disclosure() (
  local list info
  load_catalog
  list=$(lsi_list_modules)
  grep -q 'TARGETS' <<< "$list" || fail 'module list does not expose target policy'
  grep -Eq '^restricted[[:space:]].*ubuntu:24\.04:x86_64' <<< "$list" ||
    fail 'module list does not expose the exact restriction'
  grep -Eq '^family-wide[[:space:]].*family-wide' <<< "$list" ||
    fail 'module list does not identify the family-wide default'

  info=$(lsi_show_module restricted)
  grep -q '^Targets     : ubuntu:24.04:x86_64$' <<< "$info" ||
    fail 'module info does not expose exact target cells'
)

prepare_evidence_fixture() {
  local fixture_repo=$1
  mkdir -p "$fixture_repo/lib" "$fixture_repo/tests" "$fixture_repo/modules"
  cp "$ROOT_DIR/VERSION" "$fixture_repo/VERSION"
  cp "$ROOT_DIR/lib/common.sh" "$fixture_repo/lib/common.sh"
  cp "$ROOT_DIR/lib/catalog.sh" "$fixture_repo/lib/catalog.sh"
  cp "$ROOT_DIR/tests/evidence-matrix.sh" "$fixture_repo/tests/evidence-matrix.sh"
  cp "$ROOT_DIR/tests/evidence-contract.sh" "$fixture_repo/tests/evidence-contract.sh"
  cp "$ROOT_DIR/tests/evidence-targets.tsv" "$fixture_repo/tests/evidence-targets.tsv"
  cp -R "$VALID_MODULES/." "$fixture_repo/modules/"
}

test_evidence_filtering() {
  local fixture_repo="$TEMP_DIR/evidence-repo"
  local matrix cells restricted_cells contract status
  prepare_evidence_fixture "$fixture_repo"

  matrix=$(bash "$fixture_repo/tests/evidence-matrix.sh" \
    "$fixture_repo" matrix all) || fail 'fixture evidence matrix failed'
  grep -q '"module":"restricted"' <<< "$matrix" ||
    fail 'supported restricted module was omitted from the evidence matrix'
  grep -q '"module":"family-wide"' <<< "$matrix" ||
    fail 'family-wide module was omitted from the evidence matrix'
  ! grep -q '"module":"unlisted"' <<< "$matrix" ||
    fail 'module with no configured evidence cell was scheduled'

  cells=$(bash "$fixture_repo/tests/evidence-matrix.sh" \
    "$fixture_repo" cells all) || fail 'fixture evidence cells failed'
  [[ $(head -n 1 <<< "$cells") == $'cell_id\ttarget_id\tfamily\tmodule\timage\tplatform\texpected_os_id\texpected_version_id\texpected_arch' ]] ||
    fail 'evidence cells do not expose the exact version-ID contract'
  [[ $(tail -n +2 <<< "$cells" | wc -l) -eq 5 ]] ||
    fail 'evidence cells did not equal four family-wide plus one restricted cell'
  grep -q $'^ubuntu-24-04/restricted\t' <<< "$cells" ||
    fail 'declared Ubuntu evidence cell was omitted'
  ! grep -q $'^debian-12/restricted\t' <<< "$cells" ||
    fail 'unsupported Debian evidence cell was generated'
  ! grep -q $'/unlisted\t' <<< "$cells" ||
    fail 'unconfigured exact target generated an evidence cell'
  grep -q $'^rocky-9-8/family-wide\trocky-9-8\trhel\tfamily-wide\t.*\tlinux/amd64\trocky\t9\.8\tx86_64$' \
    <<< "$cells" || fail 'Rocky 9.8 exact evidence target was omitted or broadened'
  grep -q $'^alma-9-8/family-wide\talma-9-8\trhel\tfamily-wide\t.*\tlinux/amd64\talmalinux\t9\.8\tx86_64$' \
    <<< "$cells" || fail 'AlmaLinux 9.8 exact evidence target was omitted or broadened'

  restricted_cells=$(bash "$fixture_repo/tests/evidence-matrix.sh" \
    "$fixture_repo" cells debian restricted) ||
    fail 'filtered restricted evidence cells failed'
  [[ $(tail -n +2 <<< "$restricted_cells" | wc -l) -eq 1 ]] ||
    fail 'filtered restricted module generated more than its one exact cell'

  contract=$(bash "$fixture_repo/tests/evidence-contract.sh" \
    "$fixture_repo" restricted debian ubuntu 24.04 x86_64) ||
    fail 'supported exact evidence contract was rejected'
  grep -q $'^package\tgit$' <<< "$contract" ||
    fail 'supported exact evidence contract lacked package metadata'

  set +e
  bash "$fixture_repo/tests/evidence-contract.sh" \
    "$fixture_repo" restricted debian debian 12 x86_64 > /dev/null 2>&1
  status=$?
  set -e
  [[ $status -eq 2 ]] || fail 'unsupported same-family evidence contract was accepted'

  set +e
  bash "$fixture_repo/tests/evidence-contract.sh" \
    "$fixture_repo" restricted debian > /dev/null 2>&1
  status=$?
  set -e
  [[ $status -eq 2 ]] || fail 'restricted family-only evidence contract was accepted'

  bash "$fixture_repo/tests/evidence-contract.sh" \
    "$fixture_repo" family-wide debian > /dev/null ||
    fail 'family-wide evidence contract compatibility was not preserved'

  if ! python3 -B - "$ROOT_DIR/tests/evidence-record.py" "$fixture_repo" << 'PY'; then
import importlib.util
import sys
from pathlib import Path

module_path = Path(sys.argv[1])
repo_root = Path(sys.argv[2])
spec = importlib.util.spec_from_file_location("evidence_record", module_path)
if spec is None or spec.loader is None:
    raise SystemExit("cannot load evidence-record.py")
evidence_record = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = evidence_record
spec.loader.exec_module(evidence_record)

contract, error = evidence_record.derive_trusted_contract(
    repo_root, "restricted", "debian", "ubuntu", "24.04", "x86_64"
)
if error or not contract or "package\tgit\n" not in contract:
    raise SystemExit("supported restricted target contract was not derived")

contract, error = evidence_record.derive_trusted_contract(
    repo_root, "restricted", "debian", "debian", "12", "x86_64"
)
if contract is not None or error is None:
    raise SystemExit("unsupported restricted target contract was derived")
PY
    fail 'Python trusted-contract derivation did not enforce the exact target'
  fi
}

test_manifest_schema_and_matching
test_schema_rejections
test_runtime_plan_and_install_gates
test_catalog_disclosure
test_evidence_filtering

printf 'Exact target-cell contract passed: schema, runtime gates, disclosure and evidence filtering.\n'
