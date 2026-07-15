#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
FAKE_BIN="$TEMP_DIR/bin"
mkdir -p "$FAKE_BIN"

cat > "$FAKE_BIN/docker" << 'DOCKER'
#!/usr/bin/env bash
set -u
case "$*" in
  'container inspect '*) exit "${FAKE_INSPECT_STATUS:-1}" ;;
  'rm -f '*) exit "${FAKE_RM_STATUS:-0}" ;;
  'container ls -aq --filter '*)
    [[ -z ${FAKE_LIST_RESULT:-} ]] || printf '%s\n' "$FAKE_LIST_RESULT"
    exit "${FAKE_LIST_STATUS:-0}"
    ;;
  *) exit 64 ;;
esac
DOCKER
chmod +x "$FAKE_BIN/docker"

run_cleanup() {
  PATH="$FAKE_BIN:$PATH" \
    bash "$ROOT_DIR/tests/remove-evidence-container.sh" lsi-ubuntu-main
}

FAKE_INSPECT_STATUS=1 FAKE_LIST_RESULT='' run_cleanup > /dev/null

if FAKE_INSPECT_STATUS=0 FAKE_RM_STATUS=1 FAKE_LIST_RESULT=container-id \
  run_cleanup > /dev/null 2>&1; then
  printf 'Cleanup unexpectedly succeeded after docker rm failed.\n' >&2
  exit 1
fi

if FAKE_INSPECT_STATUS=1 FAKE_LIST_RESULT=container-id \
  run_cleanup > /dev/null 2>&1; then
  printf 'Cleanup unexpectedly treated an inspect failure as container absence.\n' >&2
  exit 1
fi

if FAKE_INSPECT_STATUS=1 FAKE_LIST_STATUS=1 \
  run_cleanup > /dev/null 2>&1; then
  printf 'Cleanup unexpectedly succeeded when absence verification failed.\n' >&2
  exit 1
fi

grep -Fq "[[ -z \$active_container ]] || break" \
  "$ROOT_DIR/tests/run-module-evidence.sh" || {
  printf 'The multi-target runner can overwrite an uncleared container name.\n' >&2
  exit 1
}

OVERLAP_ROOT="$TEMP_DIR/overlap"
if PATH="$FAKE_BIN:$PATH" LSI_RAW_EVIDENCE_ROOT="$OVERLAP_ROOT" \
  bash "$ROOT_DIR/tests/run-module-evidence.sh" \
  "$ROOT_DIR" debian git "$OVERLAP_ROOT" \
  > /dev/null 2> "$TEMP_DIR/overlap-error.log"; then
  printf 'The runner accepted overlapping raw and uploadable evidence roots.\n' >&2
  exit 1
fi
grep -Fq 'Raw and uploadable evidence roots must be disjoint.' \
  "$TEMP_DIR/overlap-error.log"
