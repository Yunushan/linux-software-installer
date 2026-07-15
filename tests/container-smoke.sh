#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=${1:-/workspace}
PLAN_FILE=$(mktemp "${TMPDIR:-/tmp}/linux-software-installer-plan.XXXXXX")
trap 'rm -f "$PLAN_FILE"' EXIT

assert_plan_contains() {
  local pattern=$1 description=$2
  if grep -Eq -- "$pattern" "$PLAN_FILE"; then
    return 0
  fi

  printf 'Smoke assertion failed: %s\n' "$description" >&2
  printf '%s\n' '--- generated plan ---' >&2
  cat "$PLAN_FILE" >&2
  return 1
}

"$ROOT_DIR/install.sh" doctor
"$ROOT_DIR/install.sh" list > /dev/null
"$ROOT_DIR/install.sh" plan --no-refresh base-tools git > "$PLAN_FILE"
assert_plan_contains '(apt-get install|dnf -y install)' 'plan contains the expected family package-install command'
assert_plan_contains 'no system changes were made' 'plan confirms that the smoke test is read-only'
