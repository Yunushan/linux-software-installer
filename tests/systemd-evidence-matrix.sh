#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=${1:-}
FORMAT=${2:-}
[[ -n $ROOT_DIR && ($FORMAT == plan || $FORMAT == matrix) ]] || {
  printf 'Usage: %s ROOT {plan|matrix}\n' "$0" >&2
  exit 2
}
source "$ROOT_DIR/tests/python.sh"
PYTHON=$(lsi_find_python) || {
  printf 'Python 3.8 or newer is required for the systemd evidence matrix.\n' >&2
  exit 2
}

exec "$PYTHON" "$ROOT_DIR/tests/systemd-evidence-matrix.py" \
  --root "$ROOT_DIR" "$FORMAT"
