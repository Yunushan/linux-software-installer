#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
EXPECTED_TREE='eb0defa2000f7e37c6cb83abce3a6124c4a92b7a'
EXPECTED_FILES=207

die() {
  printf 'legacy quarantine validation failed: %s\n' "$*" >&2
  exit 1
}

GIT_COMMAND='git'
GIT_ROOT="$ROOT_DIR"
if ! command -v git > /dev/null 2>&1; then
  command -v git.exe > /dev/null 2>&1 || die 'git is required to verify the pinned snapshot'
  GIT_COMMAND='git.exe'
  command -v wslpath > /dev/null 2>&1 ||
    die 'wslpath is required when validating with Windows Git from WSL'
  GIT_ROOT=$(wslpath -w "$ROOT_DIR")
fi

run_git() {
  "$GIT_COMMAND" -C "$GIT_ROOT" "$@"
}

actual_tree=$(run_git rev-parse HEAD:legacy 2> /dev/null) ||
  die 'the current commit does not contain the legacy snapshot'
actual_tree=${actual_tree%$'\r'}
[[ $actual_tree == "$EXPECTED_TREE" ]] ||
  die "legacy tree changed: expected $EXPECTED_TREE, found $actual_tree"

run_git diff --quiet -- legacy ||
  die 'tracked legacy files differ from the pinned commit'

mapfile -t legacy_files < <(run_git ls-files legacy | tr -d '\r')
[[ ${#legacy_files[@]} -eq $EXPECTED_FILES ]] ||
  die "expected $EXPECTED_FILES tracked legacy files, found ${#legacy_files[@]}"

[[ -z $(run_git ls-files --others --exclude-standard -- legacy) ]] ||
  die 'untracked files were added under legacy/'

while read -r mode _object _stage path; do
  [[ $mode == 100644 ]] || die "legacy file is executable or has an unexpected mode: $path ($mode)"
done < <(run_git ls-files -s legacy | tr -d '\r')

if grep -R -n -E '(source|bash|sh|exec)[[:space:]][^#]*legacy/|[[:space:]]\.[[:space:]][^#]*legacy/' \
  "$ROOT_DIR/install.sh" "$ROOT_DIR/bin" "$ROOT_DIR/lib" \
  "$ROOT_DIR/modules" "$ROOT_DIR/profiles" > /dev/null 2>&1; then
  die 'active installer code executes or sources the quarantined legacy path'
fi

# The read-only migration parser is the sole active file allowed to contain
# literal archived .sh locators. Every other active-code occurrence remains a
# quarantine violation, and the parser itself may only compare/print locators.
mapfile -t active_reference_files < <(find \
  "$ROOT_DIR/install.sh" "$ROOT_DIR/bin" "$ROOT_DIR/lib" \
  "$ROOT_DIR/modules" "$ROOT_DIR/profiles" -type f \
  ! -path "$ROOT_DIR/lib/migration.sh" -print)
if grep -n -E 'legacy/[^[:space:]]+\.sh' "${active_reference_files[@]}" > /dev/null 2>&1; then
  die 'active installer code outside the migration parser references a legacy script'
fi

if grep -n -E '(^|[;[:space:]])(source|bash|sh|exec)[[:space:]][^#]*(source_path|LSI_MIGRATION)|(^|[;[:space:]])eval[[:space:]]' \
  "$ROOT_DIR/lib/migration.sh" > /dev/null 2>&1; then
  die 'the read-only migration parser can execute or evaluate ledger content'
fi

printf 'Legacy quarantine valid: %d non-executable files at tree %s.\n' \
  "${#legacy_files[@]}" "$actual_tree"
