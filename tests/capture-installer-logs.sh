#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

EVIDENCE_DIR=${1:-}
[[ -n $EVIDENCE_DIR && $# -ge 2 ]] || {
  printf 'Usage: %s EVIDENCE_DIR COMMAND [ARG ...]\n' "$0" >&2
  exit 2
}
shift

LOG_SOURCE=${LSI_EVIDENCE_LOG_SOURCE:-/var/log/linux-software-installer}
[[ $EVIDENCE_DIR == /* && $LOG_SOURCE == /* ]] || {
  printf 'Evidence and installer log paths must be absolute.\n' >&2
  exit 2
}
[[ -d $EVIDENCE_DIR && ! -L $EVIDENCE_DIR ]] || {
  printf 'Evidence directory is missing or unsafe: %s\n' "$EVIDENCE_DIR" >&2
  exit 2
}

set +e
"$@"
command_status=$?
set -e

capture_status=0
destination="$EVIDENCE_DIR/installer-logs"
if [[ ! -d $LOG_SOURCE || -L $LOG_SOURCE || -e $destination || -L $destination ]]; then
  printf 'Installer logs are missing or evidence destination is unsafe.\n' >&2
  capture_status=70
elif ! mkdir "$destination" || ! cp -a -- "$LOG_SOURCE/." "$destination/"; then
  printf 'Unable to copy installer logs into evidence.\n' >&2
  capture_status=70
fi

if ((command_status == 0 && capture_status != 0)); then
  exit "$capture_status"
fi
exit "$command_status"
