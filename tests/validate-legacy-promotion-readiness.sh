#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
if command -v python3 > /dev/null 2>&1; then
  PYTHON=python3
elif command -v python > /dev/null 2>&1; then
  PYTHON=python
else
  printf 'Python is required for the legacy promotion readiness validator.\n' >&2
  exit 2
fi

exec "$PYTHON" "$ROOT_DIR/tests/validate-legacy-promotion-readiness.py" \
  --root "$ROOT_DIR" "$@"
