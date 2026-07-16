#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=python.sh
source "$ROOT_DIR/tests/python.sh"

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
FAKE_BIN="$TEMP_DIR/bin"
mkdir -p "$FAKE_BIN"

cat > "$FAKE_BIN/python3" << 'PYTHON3'
#!/usr/bin/env bash
exit 1
PYTHON3
cat > "$FAKE_BIN/python" << 'PYTHON'
#!/usr/bin/env bash
[[ ${1:-} == -B && ${2:-} == -c ]] || exit 64
exit 0
PYTHON
chmod 0755 "$FAKE_BIN/python3" "$FAKE_BIN/python"

resolved=$(PATH="$FAKE_BIN:$PATH" lsi_find_python)
[[ $resolved == python ]] || {
  printf 'Python resolver did not fall back from a broken python3 alias: %s\n' \
    "${resolved:-missing}" >&2
  exit 1
}
