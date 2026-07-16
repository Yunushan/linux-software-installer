#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$ROOT_DIR/tests/python.sh"
PYTHON=$(lsi_find_python) || {
  printf 'Python 3.8 or newer is required for the legacy promotion readiness validator.\n' >&2
  exit 2
}

exec "$PYTHON" "$ROOT_DIR/tests/validate-legacy-promotion-readiness.py" \
  --root "$ROOT_DIR" "$@"
