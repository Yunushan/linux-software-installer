#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=${1:-}
shift || true
[[ -n $ROOT_DIR ]] || {
  printf 'Usage: %s ROOT --evidence DIR [validator options]\n' "$0" >&2
  exit 2
}
if command -v python3 > /dev/null 2>&1; then
  PYTHON=python3
elif command -v python > /dev/null 2>&1; then
  PYTHON=python
elif [[ -x /usr/libexec/platform-python ]]; then
  PYTHON=/usr/libexec/platform-python
else
  printf 'Python is required for systemd evidence validation.\n' >&2
  exit 2
fi

exec "$PYTHON" "$ROOT_DIR/tests/validate-systemd-evidence.py" --root "$ROOT_DIR" "$@"
