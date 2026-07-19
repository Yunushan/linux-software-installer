#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
export LC_ALL=C

EVIDENCE_DIR=${1:-}
RUN_URL=${LSI_RUN_URL:-local}
TESTED_COMMIT=${LSI_TESTED_COMMIT:-local-uncommitted}
TARGET_ID=${LSI_TARGET_ID:-ubuntu-24-04}
IMAGE_REF=${LSI_IMAGE_REF:-local}
EVIDENCE_USER=lsi-tor-evidence
EVIDENCE_HOME=/tmp/lsi-tor-evidence-home
DOWNLOAD_DIR="$EVIDENCE_HOME/.cache/torbrowser/download"
DATA_DIR="$EVIDENCE_HOME/.local/share/torbrowser/tbb/x86_64/tor-browser"
LOG_FILE=
LAUNCHER_PID=
VERIFY_HOME=
RESULT=failed
CURRENT_STAGE=bootstrap

[[ -n $EVIDENCE_DIR ]] || {
  printf 'Usage: %s EVIDENCE_DIR\n' "$0" >&2
  exit 2
}

mkdir -p "$EVIDENCE_DIR"
chmod 700 "$EVIDENCE_DIR"
printf 'field\tvalue\n' > "$EVIDENCE_DIR/first-run.tsv"
printf 'stage\tstatus\ttimestamp\texit_code\n' > "$EVIDENCE_DIR/stages.tsv"

sanitize_field() {
  local value=$1
  value=${value//$'\t'/ }
  value=${value//$'\r'/ }
  value=${value//$'\n'/ }
  printf '%s' "$value"
}

metadata() {
  printf '%s\t%s\n' "$1" "$(sanitize_field "$2")" >> "$EVIDENCE_DIR/first-run.tsv"
}

stage_begin() {
  CURRENT_STAGE=$1
  printf '%s\trunning\t%s\t-\n' "$CURRENT_STAGE" \
    "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EVIDENCE_DIR/stages.tsv"
}

stage_pass() {
  printf '%s\tpassed\t%s\t0\n' "$CURRENT_STAGE" \
    "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$EVIDENCE_DIR/stages.tsv"
}

finish_record() {
  local code=$?
  trap - EXIT
  if [[ -n ${LAUNCHER_PID:-} ]]; then
    kill "$LAUNCHER_PID" > /dev/null 2>&1 || true
    wait "$LAUNCHER_PID" > /dev/null 2>&1 || true
  fi
  if [[ -n ${VERIFY_HOME:-} ]]; then
    rm -rf -- "$VERIFY_HOME"
  fi
  if [[ $RESULT != success ]]; then
    ((code != 0)) || code=1
    printf '%s\tfailed\t%s\t%d\n' "$CURRENT_STAGE" \
      "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$code" >> "$EVIDENCE_DIR/stages.tsv"
    rm -f -- "$EVIDENCE_DIR/tor-browser.tar.xz" \
      "$EVIDENCE_DIR/tor-browser.tar.xz.asc"
  fi
  metadata finished_at "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  metadata result "$RESULT"
  metadata exit_code "$code"
  if [[ $RESULT == success ]]; then
    metadata failure_stage '-'
  else
    metadata failure_stage "$CURRENT_STAGE"
  fi
  chmod -R a+rX "$EVIDENCE_DIR"
  exit "$code"
}
trap finish_record EXIT

metadata schema_version 1
metadata started_at "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
metadata tested_commit "$TESTED_COMMIT"
metadata workflow_run_url "$RUN_URL"
metadata target_id "$TARGET_ID"
metadata image_ref "$IMAGE_REF"
metadata expected_tor_signing_fingerprint EF6E286DDA85EA2A4BA7DE684E2C6E8793298290

stage_begin install-launcher
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates gnupg torbrowser-launcher xauth xvfb xz-utils
dpkg-query -W -f='${binary:Package}\t${Version}\n' torbrowser-launcher \
  > "$EVIDENCE_DIR/launcher-package.tsv"
command -v torbrowser-launcher > "$EVIDENCE_DIR/launcher-path.txt"
stage_pass

stage_begin prepare-disposable-user
id "$EVIDENCE_USER" > /dev/null 2>&1 || \
  useradd --create-home --user-group --home-dir "$EVIDENCE_HOME" --shell /usr/sbin/nologin "$EVIDENCE_USER"
install -d -m 700 -o "$EVIDENCE_USER" -g "$EVIDENCE_USER" \
  "$EVIDENCE_HOME/.cache" \
  "$EVIDENCE_HOME/.cache/torbrowser" \
  "$DOWNLOAD_DIR" \
  "$EVIDENCE_HOME/.config" \
  "$EVIDENCE_HOME/.local/share"
LOG_FILE="$EVIDENCE_DIR/launcher.log"
stage_pass

stage_begin first-launch-download-and-extract
runuser -u "$EVIDENCE_USER" -- env \
  HOME="$EVIDENCE_HOME" \
  XDG_CACHE_HOME="$EVIDENCE_HOME/.cache" \
  XDG_CONFIG_HOME="$EVIDENCE_HOME/.config" \
  XDG_DATA_HOME="$EVIDENCE_HOME/.local/share" \
  QT_QPA_PLATFORM=xcb \
  timeout --signal=TERM --kill-after=30s 20m \
  xvfb-run -a torbrowser-launcher > "$LOG_FILE" 2>&1 &
LAUNCHER_PID=$!

captured_archive=
captured_signature=
for _ in $(seq 1 1200); do
  shopt -s nullglob
  archives=("$DOWNLOAD_DIR"/tor-browser-linux-x86_64-*.tar.xz)
  signatures=("$DOWNLOAD_DIR"/tor-browser-linux-x86_64-*.tar.xz.asc)
  shopt -u nullglob
  if [[ ${#archives[@]} -eq 1 && ${#signatures[@]} -eq 1 && \
    -s ${archives[0]} && -s ${signatures[0]} ]]; then
    size_before=$(stat -c '%s' "${archives[0]}")
    sleep 2
    size_after=$(stat -c '%s' "${archives[0]}")
    if [[ $size_before == "$size_after" ]]; then
      cp -- "${archives[0]}" "$EVIDENCE_DIR/tor-browser.tar.xz"
      cp -- "${signatures[0]}" "$EVIDENCE_DIR/tor-browser.tar.xz.asc"
      captured_archive=1
      captured_signature=1
    fi
  fi
  [[ -n $captured_archive && -n $captured_signature && \
    -x "$DATA_DIR/start-tor-browser.desktop" ]] && break
  kill -0 "$LAUNCHER_PID" > /dev/null 2>&1 || break
  sleep 1
done

[[ -n $captured_archive && -n $captured_signature ]] || {
  printf 'The launcher did not leave one complete signed Tor Browser archive for verification.\n' >&2
  exit 1
}
[[ -x "$DATA_DIR/start-tor-browser.desktop" ]] || {
  printf 'The launcher did not extract an executable Tor Browser start entrypoint.\n' >&2
  exit 1
}
cp -- "$DATA_DIR/start-tor-browser.desktop" "$EVIDENCE_DIR/start-tor-browser.desktop"
tar -tJf "$EVIDENCE_DIR/tor-browser.tar.xz" \
  | grep -Fx 'tor-browser/start-tor-browser.desktop' \
  > "$EVIDENCE_DIR/archive-layout.txt"
stage_pass

stage_begin independent-signature-verification
VERIFY_HOME=$(mktemp -d)
chmod 700 "$VERIFY_HOME"
REFRESHED_KEY="$EVIDENCE_HOME/.cache/torbrowser/torbrowser.gpg"
[[ -s $REFRESHED_KEY ]] || {
  printf 'The launcher did not retain the refreshed Tor Browser signing key.\n' >&2
  exit 1
}
sha256sum "$REFRESHED_KEY" > "$EVIDENCE_DIR/refreshed-key.sha256"
gpg --batch --homedir "$VERIFY_HOME" --import \
  /usr/share/torbrowser-launcher/tor-browser-developers.asc "$REFRESHED_KEY" \
  > "$EVIDENCE_DIR/key-import.log" 2>&1
gpg --batch --homedir "$VERIFY_HOME" --with-colons --list-keys \
  > "$EVIDENCE_DIR/key-listing.txt"
mapfile -t fingerprints < <(awk -F: '
  $1 == "pub" { awaiting_primary_fingerprint = 1; next }
  awaiting_primary_fingerprint && $1 == "fpr" {
    print $10
    awaiting_primary_fingerprint = 0
  }
' "$EVIDENCE_DIR/key-listing.txt")
[[ ${#fingerprints[@]} -eq 1 && \
  ${fingerprints[0]} == EF6E286DDA85EA2A4BA7DE684E2C6E8793298290 ]] || {
  printf 'The launcher key does not contain exactly the documented Tor Browser signing fingerprint.\n' >&2
  exit 1
}
gpg --batch --homedir "$VERIFY_HOME" --status-fd 1 --verify \
  "$EVIDENCE_DIR/tor-browser.tar.xz.asc" \
  "$EVIDENCE_DIR/tor-browser.tar.xz" \
  > "$EVIDENCE_DIR/signature-verification.log" 2>&1
awk -v expected_primary=EF6E286DDA85EA2A4BA7DE684E2C6E8793298290 '
  /^\[GNUPG:\] VALIDSIG / && $NF == expected_primary { verified = 1 }
  END { exit verified ? 0 : 1 }
' "$EVIDENCE_DIR/signature-verification.log" || {
  printf 'The payload signature was not bound to the expected Tor Browser primary key.\n' >&2
  exit 1
}
sha256sum "$EVIDENCE_DIR/tor-browser.tar.xz" \
  > "$EVIDENCE_DIR/tor-browser.tar.xz.sha256"
sha256sum "$EVIDENCE_DIR/tor-browser.tar.xz.asc" \
  > "$EVIDENCE_DIR/tor-browser.tar.xz.asc.sha256"
rm -rf -- "$VERIFY_HOME"
VERIFY_HOME=
stage_pass

stage_begin cleanup
kill "$LAUNCHER_PID" > /dev/null 2>&1 || true
wait "$LAUNCHER_PID" > /dev/null 2>&1 || true
LAUNCHER_PID=
rm -f -- "$EVIDENCE_DIR/tor-browser.tar.xz" "$EVIDENCE_DIR/tor-browser.tar.xz.asc"
find "$EVIDENCE_HOME" -maxdepth 4 -type f -printf '%P\n' | LC_ALL=C sort \
  > "$EVIDENCE_DIR/disposable-home-files.txt"
rm -rf -- "$EVIDENCE_HOME"
[[ ! -e $EVIDENCE_HOME ]]
stage_pass

CURRENT_STAGE=complete
RESULT=success
printf 'Tor Browser Launcher first-run evidence passed for %s.\n' "$TARGET_ID"
