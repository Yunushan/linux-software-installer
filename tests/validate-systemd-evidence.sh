#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=${1:-}
shift || true
[[ -n $ROOT_DIR ]] || {
  printf 'Usage: %s ROOT --evidence DIR [validator options]\n' "$0" >&2
  exit 2
}
source "$ROOT_DIR/tests/python.sh"
PYTHON=$(lsi_find_python) || {
  printf 'Python 3.8 or newer is required for systemd evidence validation.\n' >&2
  exit 2
}

exec "$PYTHON" "$ROOT_DIR/tests/validate-systemd-evidence.py" --root "$ROOT_DIR" "$@"
