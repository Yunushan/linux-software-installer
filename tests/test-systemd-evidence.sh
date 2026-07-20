#!/usr/bin/env bash
# shellcheck disable=SC2016 # Single-quoted arguments below are literal generated mock-script source.
set -Eeuo pipefail
IFS=$'\n\t'
export LC_ALL=C

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
# shellcheck source=python.sh
source "$ROOT_DIR/tests/python.sh"
PYTHON=$(lsi_find_python) || {
  printf 'Python 3.8 or newer is required for the systemd evidence contract test.\n' >&2
  exit 2
}
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT
MOCK_BIN=$TEMP_DIR/mock-bin
FIXTURE=$TEMP_DIR/fixture
mkdir -p "$MOCK_BIN" "$FIXTURE/proc/1" "$FIXTURE/run/systemd/system" \
  "$FIXTURE/ssh/sshd_config.d" "$TEMP_DIR/output"

COMMIT=${LSI_TESTED_COMMIT:-$(awk -F $'\t' '$1 == "debian/tor-browser" { print $2; exit }' \
  "$ROOT_DIR/docs/accepted-evidence.tsv")}
[[ $COMMIT =~ ^[0-9a-f]{40}$ ]] || {
  printf 'The systemd evidence test could not resolve an admitted evidence commit.\n' >&2
  exit 2
}
IMAGE_REF=ubuntu-vm@sha256:2222222222222222222222222222222222222222222222222222222222222222
BOOT_ID=33333333-3333-4333-8333-333333333333
export MOCK_COMMIT=$COMMIT
export MOCK_STATE=$FIXTURE/state.tsv

write_executable() {
  local path=$1
  shift
  printf '%s\n' "$@" > "$path"
  chmod 0755 "$path"
}

write_executable "$MOCK_BIN/git" '#!/usr/bin/env bash' \
  'case " $* " in' \
  '  *" rev-parse HEAD "*) printf "%s\n" "$MOCK_COMMIT" ;;' \
  '  *" diff "*) exit 0 ;;' \
  '  *" status "*) exit 0 ;;' \
  '  *) printf "unexpected mocked git arguments: %s\n" "$*" >&2; exit 2 ;;' \
  'esac'
write_executable "$MOCK_BIN/systemd-detect-virt" '#!/usr/bin/env bash' \
  'case "${1:-}" in' \
  '  --vm) printf "kvm\n" ;;' \
  '  --container)' \
  '    if [[ ${MOCK_CONTAINER:-0} == 1 ]]; then printf "docker\n"; else printf "none\n"; exit 1; fi ;;' \
  '  --chroot | --private-users) exit 1 ;;' \
  '  *) exit 2 ;;' \
  'esac'
write_executable "$MOCK_BIN/systemctl" '#!/usr/bin/env bash' \
  'state_value() { sed -n "s/^$1=//p" "$MOCK_STATE"; }' \
  'case "${1:-}" in' \
  '  is-system-running) printf "running\n" ;;' \
  '  is-enabled)' \
  '    if [[ ${2:-} == ssh* ]]; then printf "enabled\n"' \
  '    elif [[ $(state_value enabled) == 1 ]]; then printf "enabled\n"; else printf "disabled\n"; exit 1; fi ;;' \
  '  is-active)' \
  '    if [[ ${2:-} == ssh* ]]; then printf "active\n"' \
  '    elif [[ $(state_value active) == 1 ]]; then printf "active\n"; else printf "inactive\n"; exit 3; fi ;;' \
  '  --failed) exit 0 ;;' \
  '  enable) exit 0 ;;' \
  '  *) printf "unexpected mocked systemctl arguments: %s\n" "$*" >&2; exit 2 ;;' \
  'esac'
write_executable "$MOCK_BIN/uname" '#!/usr/bin/env bash' \
  'case "${1:-}" in -m) printf "x86_64\n" ;; -r) printf "6.8.0-test\n" ;; *) exit 2 ;; esac'
write_executable "$MOCK_BIN/dpkg-query" '#!/usr/bin/env bash' \
  'last=${!#}' \
  'if [[ $last == apache2 ]]; then' \
  '  [[ $(sed -n "s/^installed=//p" "$MOCK_STATE") == 1 ]] || exit 1' \
  '  printf "install ok installed\t2.4.58-test"' \
  'else' \
  '  printf "linux-image-generic\t6.8.0-test\nopenssh-server\t1:9.6-test\nopenssl\t3.0-test\n"' \
  'fi'
write_executable "$MOCK_BIN/getenforce" '#!/usr/bin/env bash' 'printf "Enforcing\n"'
write_executable "$MOCK_BIN/firewall-cmd" '#!/usr/bin/env bash' 'printf "public: unchanged\n"'
write_executable "$MOCK_BIN/nft" '#!/usr/bin/env bash' 'printf "table inet filter {}\n"'
write_executable "$MOCK_BIN/iptables-save" '#!/usr/bin/env bash' 'printf "*filter\nCOMMIT\n"'
write_executable "$MOCK_BIN/ss" '#!/usr/bin/env bash' 'printf "LISTEN 0 128 0.0.0.0:22 0.0.0.0:* users:sshd\n"'
write_executable "$MOCK_BIN/installer" '#!/usr/bin/env bash' \
  'mode=${1:-}' \
  'enable=false' \
  'for argument in "$@"; do [[ $argument == --enable-services ]] && enable=true; done' \
  'if [[ $mode == plan ]]; then' \
  '  if [[ $enable == true ]]; then printf "Install apache; enable: apache2\n"; else printf "Install apache\n"; fi' \
  '  exit 0' \
  'fi' \
  '[[ $mode == install ]] || exit 2' \
  'printf "installed=1\nenabled=1\nactive=1\n" > "$MOCK_STATE"' \
  'printf "+ apt-get install apache2\n"' \
  '[[ $enable == false ]] || systemctl enable --now apache2'
write_executable "$MOCK_BIN/installer-forged-output" '#!/usr/bin/env bash' \
  'enable=false' \
  'for argument in "$@"; do [[ $argument == --enable-services ]] && enable=true; done' \
  'if [[ ${1:-} == plan ]]; then printf "Install apache; enable: apache2\n"; exit 0; fi' \
  'printf "installed=1\nenabled=1\nactive=1\n" > "$MOCK_STATE"' \
  'printf "+ systemctl enable --now apache2\n"'

printf 'systemd\n' > "$FIXTURE/proc/1/comm"
printf '%s\n' \
  'NAME="Ubuntu"' \
  'ID=ubuntu' \
  'ID_LIKE=debian' \
  'VERSION_ID="24.04"' \
  'PRETTY_NAME="Ubuntu 24.04 LTS"' > "$FIXTURE/os-release"
printf '%s\n' "$BOOT_ID" > "$FIXTURE/boot-id"
printf 'PermitRootLogin prohibit-password\n' > "$FIXTURE/ssh/sshd_config"
printf 'PasswordAuthentication no\n' > "$FIXTURE/ssh/sshd_config.d/hardening.conf"

make_marker() {
  local path=$1 execution_id=$2 nonce=$3
  printf '%s\n' \
    $'field\tvalue' \
    $'schema\tlinux-software-installer/systemd-evidence-vm/v1' \
    $'ephemeral\ttrue' \
    $'single_use\ttrue' \
    $'execution_id\t'"$execution_id" \
    $'target_id\tubuntu-24-04' \
    $'tested_commit\t'"$COMMIT" \
    $'vm_image_ref\t'"$IMAGE_REF" \
    $'boot_id\t'"$BOOT_ID" \
    $'nonce\t'"$nonce" > "$path"
  chmod 0600 "$path"
}

run_fixture() {
  local execution_id=$1 marker=$2 output=$3 installer=${4:-$MOCK_BIN/installer}
  PATH="$MOCK_BIN:$PATH" \
    LSI_SYSTEMD_EVIDENCE_TEST_MODE=1 \
    LSI_SYSTEMD_EVIDENCE_TEST_EUID=0 \
    LSI_SYSTEMD_EVIDENCE_PROC_ROOT="$FIXTURE/proc" \
    LSI_SYSTEMD_EVIDENCE_SYSTEMD_RUNTIME="$FIXTURE/run/systemd/system" \
    LSI_SYSTEMD_EVIDENCE_OS_RELEASE_FILE="$FIXTURE/os-release" \
    LSI_SYSTEMD_EVIDENCE_BOOT_ID_FILE="$FIXTURE/boot-id" \
    LSI_SYSTEMD_EVIDENCE_SSH_ROOT="$FIXTURE/ssh" \
    LSI_SYSTEMD_EVIDENCE_INSTALLER="$installer" \
    timeout 120s bash "$ROOT_DIR/tests/run-systemd-evidence.sh" \
    --root "$ROOT_DIR" \
    --execution-id "$execution_id" \
    --output "$output" \
    --tested-commit "$COMMIT" \
    --vm-image-ref "$IMAGE_REF" \
    --marker "$marker"
}

PLAN=$TEMP_DIR/plan.tsv
MATRIX=$TEMP_DIR/matrix.json
bash "$ROOT_DIR/tests/systemd-evidence-matrix.sh" "$ROOT_DIR" plan > "$PLAN"
bash "$ROOT_DIR/tests/systemd-evidence-matrix.sh" "$ROOT_DIR" matrix > "$MATRIX"
"$PYTHON" -B - "$PLAN" "$MATRIX" << 'PY'
import csv
import json
import sys

with open(sys.argv[1], encoding="utf-8", newline="") as stream:
    rows = list(csv.DictReader(stream, delimiter="\t"))
assert len(rows) == 64
assert len({row["execution_id"] for row in rows}) == 64
assert len({(row["family"], row["module"]) for row in rows}) == 14
assert len({row["module"] for row in rows}) == 12
assert {row["mode"] for row in rows} == {"default", "enable-services"}
assert sum(row["mode"] == "default" for row in rows) == 32
assert {row["target_id"] for row in rows} == {
    "ubuntu-24-04",
    "ubuntu-26-04",
    "debian-12",
    "rocky-9-8",
    "alma-9-8",
}
assert {
    (row["target_id"], row["expected_version_id"])
    for row in rows
    if row["family"] == "rhel"
} == {("rocky-9-8", "9.8"), ("alma-9-8", "9.8")}
with open(sys.argv[2], encoding="utf-8") as stream:
    matrix = json.load(stream)
assert matrix == {"include": rows}
PY

DEFAULT_ID=ubuntu-24-04-apache-default
DEFAULT_MARKER=$FIXTURE/default-marker.tsv
DEFAULT_OUTPUT=$TEMP_DIR/output/default
printf 'installed=0\nenabled=0\nactive=0\n' > "$MOCK_STATE"
make_marker "$DEFAULT_MARKER" "$DEFAULT_ID" aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
run_fixture "$DEFAULT_ID" "$DEFAULT_MARKER" "$DEFAULT_OUTPUT" > /dev/null
grep -q $'^result\ttest-only$' "$DEFAULT_OUTPUT/execution.tsv"
grep -q $'^acceptance_eligible\tfalse$' "$DEFAULT_OUTPUT/execution.tsv"
grep -q $'^apache2\tfalse\ttrue\ttrue\tpackage-maintainer-or-system-policy$' \
  "$DEFAULT_OUTPUT/service-attribution.tsv"
[[ -f $DEFAULT_MARKER.consumed ]]
bash "$ROOT_DIR/tests/validate-systemd-evidence.sh" "$ROOT_DIR" \
  --evidence "$DEFAULT_OUTPUT" --tested-commit "$COMMIT" --vm-image-ref "$IMAGE_REF" \
  > /dev/null
NEAR_VERSION_VALIDATOR_OUTPUT=$TEMP_DIR/output/near-version-validator
cp -a "$DEFAULT_OUTPUT" "$NEAR_VERSION_VALIDATOR_OUTPUT"
sed -i 's/^VERSION_ID="24.04"$/VERSION_ID="24.04.1"/' \
  "$NEAR_VERSION_VALIDATOR_OUTPUT/os-release.txt"
NEAR_VERSION_DIGEST=$(sha256sum "$NEAR_VERSION_VALIDATOR_OUTPUT/os-release.txt")
NEAR_VERSION_DIGEST=${NEAR_VERSION_DIGEST%% *}
sed -i \
  "s/^[0-9a-f]\{64\}  os-release\.txt$/$NEAR_VERSION_DIGEST  os-release.txt/" \
  "$NEAR_VERSION_VALIDATOR_OUTPUT/files.sha256"
if bash "$ROOT_DIR/tests/validate-systemd-evidence.sh" "$ROOT_DIR" \
  --evidence "$NEAR_VERSION_VALIDATOR_OUTPUT" > /dev/null 2>&1; then
  printf 'A self-consistent near-match observed version unexpectedly validated.\n' >&2
  exit 1
fi
if bash "$ROOT_DIR/tests/validate-systemd-evidence.sh" "$ROOT_DIR" \
  --evidence "$DEFAULT_OUTPUT" --require-real > /dev/null 2>&1; then
  printf 'Mocked evidence unexpectedly passed the real-evidence acceptance gate.\n' >&2
  exit 1
fi
if bash "$ROOT_DIR/tests/validate-systemd-evidence.sh" "$ROOT_DIR" \
  --evidence "$DEFAULT_OUTPUT" --require-accepted > /dev/null 2>&1; then
  printf 'A local self-attested bundle unexpectedly passed the acceptance gate.\n' >&2
  exit 1
fi
if run_fixture "$DEFAULT_ID" "$DEFAULT_MARKER" "$TEMP_DIR/output/reused" > /dev/null 2>&1; then
  printf 'A consumed VM marker unexpectedly ran twice.\n' >&2
  exit 1
fi

ENABLE_ID=ubuntu-24-04-apache-enable-services
ENABLE_MARKER=$FIXTURE/enable-marker.tsv
ENABLE_OUTPUT=$TEMP_DIR/output/enable
printf 'installed=0\nenabled=0\nactive=0\n' > "$MOCK_STATE"
make_marker "$ENABLE_MARKER" "$ENABLE_ID" bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
run_fixture "$ENABLE_ID" "$ENABLE_MARKER" "$ENABLE_OUTPUT" > /dev/null
grep -q $'^apache2\ttrue\ttrue\ttrue\tinstaller-explicit-activation-requested$' \
  "$ENABLE_OUTPUT/service-attribution.tsv"
grep -E -q ': systemctl enable --now apache2$' "$ENABLE_OUTPUT/installer-trace.log"
bash "$ROOT_DIR/tests/validate-systemd-evidence.sh" "$ROOT_DIR" \
  --evidence "$ENABLE_OUTPUT" > /dev/null

NON_SYSTEMD_MARKER=$FIXTURE/non-systemd-marker.tsv
make_marker "$NON_SYSTEMD_MARKER" "$DEFAULT_ID" cccccccccccccccccccccccccccccccc
printf 'init\n' > "$FIXTURE/proc/1/comm"
if run_fixture "$DEFAULT_ID" "$NON_SYSTEMD_MARKER" "$TEMP_DIR/output/non-systemd" \
  > /dev/null 2>&1; then
  printf 'A non-systemd PID 1 unexpectedly produced evidence.\n' >&2
  exit 1
fi
[[ -f $NON_SYSTEMD_MARKER && ! -e $NON_SYSTEMD_MARKER.consumed ]]
printf 'systemd\n' > "$FIXTURE/proc/1/comm"

CONTAINER_MARKER=$FIXTURE/container-marker.tsv
make_marker "$CONTAINER_MARKER" "$DEFAULT_ID" eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
export MOCK_CONTAINER=1
if run_fixture "$DEFAULT_ID" "$CONTAINER_MARKER" "$TEMP_DIR/output/container" \
  > /dev/null 2>&1; then
  printf 'A systemd container on a VM unexpectedly produced VM evidence.\n' >&2
  exit 1
fi
unset MOCK_CONTAINER
[[ -f $CONTAINER_MARKER && ! -e $CONTAINER_MARKER.consumed ]]

FORGED_MARKER=$FIXTURE/forged-output-marker.tsv
make_marker "$FORGED_MARKER" "$ENABLE_ID" ffffffffffffffffffffffffffffffff
printf 'installed=0\nenabled=0\nactive=0\n' > "$MOCK_STATE"
if run_fixture "$ENABLE_ID" "$FORGED_MARKER" "$TEMP_DIR/output/forged-output" \
  "$MOCK_BIN/installer-forged-output" > /dev/null 2>&1; then
  printf 'Package/stdout text unexpectedly forged explicit installer attribution.\n' >&2
  exit 1
fi

NEAR_VERSION_MARKER=$FIXTURE/near-version-marker.tsv
make_marker "$NEAR_VERSION_MARKER" "$DEFAULT_ID" 0123456789abcdef0123456789abcdef
sed -i 's/^VERSION_ID="24.04"$/VERSION_ID="24.04.1"/' "$FIXTURE/os-release"
if run_fixture "$DEFAULT_ID" "$NEAR_VERSION_MARKER" "$TEMP_DIR/output/near-version" \
  > /dev/null 2>&1; then
  printf 'A near-match observed version unexpectedly produced evidence.\n' >&2
  exit 1
fi
[[ -f $NEAR_VERSION_MARKER && ! -e $NEAR_VERSION_MARKER.consumed ]]
sed -i 's/^VERSION_ID="24.04.1"$/VERSION_ID="24.04"/' "$FIXTURE/os-release"

WRONG_OS_MARKER=$FIXTURE/wrong-os-marker.tsv
make_marker "$WRONG_OS_MARKER" "$DEFAULT_ID" dddddddddddddddddddddddddddddddd
sed -i 's/^ID=ubuntu$/ID=debian/; s/^VERSION_ID="24.04"$/VERSION_ID="12"/' \
  "$FIXTURE/os-release"
if run_fixture "$DEFAULT_ID" "$WRONG_OS_MARKER" "$TEMP_DIR/output/wrong-os" \
  > /dev/null 2>&1; then
  printf 'A mismatched exact OS unexpectedly produced evidence.\n' >&2
  exit 1
fi
[[ -f $WRONG_OS_MARKER && ! -e $WRONG_OS_MARKER.consumed ]]

printf '# tamper\n' >> "$ENABLE_OUTPUT/installer.log"
if bash "$ROOT_DIR/tests/validate-systemd-evidence.sh" "$ROOT_DIR" \
  --evidence "$ENABLE_OUTPUT" > /dev/null 2>&1; then
  printf 'Tampered structured evidence unexpectedly validated.\n' >&2
  exit 1
fi

printf 'Systemd evidence contract tests passed.\n'
