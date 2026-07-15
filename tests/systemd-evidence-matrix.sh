#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR=${1:-}
FORMAT=${2:-}
[[ -n $ROOT_DIR && ($FORMAT == plan || $FORMAT == matrix) ]] || {
  printf 'Usage: %s ROOT {plan|matrix}\n' "$0" >&2
  exit 2
}
if command -v python3 > /dev/null 2>&1; then
  PYTHON=python3
elif command -v python > /dev/null 2>&1; then
  PYTHON=python
elif [[ -x /usr/libexec/platform-python ]]; then
  PYTHON=/usr/libexec/platform-python
else
  printf 'Python is required for the systemd evidence matrix.\n' >&2
  exit 2
fi

exec "$PYTHON" "$ROOT_DIR/tests/systemd-evidence-matrix.py" \
  --root "$ROOT_DIR" "$FORMAT"
