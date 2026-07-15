#!/usr/bin/env bash

LSI_VERSION="$(< "$LSI_PROJECT_ROOT/VERSION")"
LSI_DRY_RUN=${LSI_DRY_RUN:-false}
LSI_ASSUME_YES=${LSI_ASSUME_YES:-false}
LSI_ENABLE_SERVICES=${LSI_ENABLE_SERVICES:-false}
LSI_NO_REFRESH=${LSI_NO_REFRESH:-false}
LSI_FORCE_UNSUPPORTED=${LSI_FORCE_UNSUPPORTED:-false}
LSI_VERBOSE=${LSI_VERBOSE:-false}
LSI_LOG_FILE=${LSI_LOG_FILE:-}
LSI_LOG_INITIALIZED=false

if [[ -t 1 && -z ${NO_COLOR:-} ]]; then
  LSI_COLOR_BLUE=$'\033[34m'
  LSI_COLOR_GREEN=$'\033[32m'
  LSI_COLOR_YELLOW=$'\033[33m'
  LSI_COLOR_RED=$'\033[31m'
  LSI_COLOR_BOLD=$'\033[1m'
  LSI_COLOR_RESET=$'\033[0m'
else
  LSI_COLOR_BLUE=''
  LSI_COLOR_GREEN=''
  LSI_COLOR_YELLOW=''
  LSI_COLOR_RED=''
  LSI_COLOR_BOLD=''
  LSI_COLOR_RESET=''
fi

lsi_timestamp() {
  date -u '+%Y-%m-%dT%H:%M:%SZ'
}

lsi_log() {
  local level=$1
  shift
  [[ $LSI_LOG_INITIALIZED == true && -n $LSI_LOG_FILE ]] || return 0
  printf '%s [%s] %s\n' "$(lsi_timestamp)" "$level" "$*" >> "$LSI_LOG_FILE"
}

lsi_info() {
  printf '%s==>%s %s\n' "$LSI_COLOR_BLUE" "$LSI_COLOR_RESET" "$*"
  lsi_log INFO "$*"
}

lsi_success() {
  printf '%s==>%s %s\n' "$LSI_COLOR_GREEN" "$LSI_COLOR_RESET" "$*"
  lsi_log SUCCESS "$*"
}

lsi_warn() {
  printf '%sWarning:%s %s\n' "$LSI_COLOR_YELLOW" "$LSI_COLOR_RESET" "$*" >&2
  lsi_log WARNING "$*"
}

lsi_error() {
  printf '%sError:%s %s\n' "$LSI_COLOR_RED" "$LSI_COLOR_RESET" "$*" >&2
  lsi_log ERROR "$*"
}

lsi_die() {
  local message=$1
  local code=${2:-1}
  lsi_error "$message"
  exit "$code"
}

lsi_debug() {
  [[ $LSI_VERBOSE == true ]] || return 0
  printf 'DEBUG: %s\n' "$*" >&2
  lsi_log DEBUG "$*"
}

lsi_disable_color() {
  LSI_COLOR_BLUE=''
  LSI_COLOR_GREEN=''
  LSI_COLOR_YELLOW=''
  LSI_COLOR_RED=''
  LSI_COLOR_BOLD=''
  LSI_COLOR_RESET=''
}

lsi_trim() {
  local value=$1
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

lsi_join_by() {
  local delimiter=$1
  shift
  local first=true item
  for item in "$@"; do
    if [[ $first == true ]]; then
      first=false
    else
      printf '%s' "$delimiter"
    fi
    printf '%s' "$item"
  done
}

lsi_shell_join() {
  local output='' quoted arg key redact_next=false
  for arg in "$@"; do
    if [[ $redact_next == true ]]; then
      arg='[REDACTED]'
      redact_next=false
    elif [[ $arg == *=* ]]; then
      key=${arg%%=*}
      if lsi_sensitive_key "$key"; then
        arg="$key=[REDACTED]"
      fi
    elif [[ $arg == --* || $arg == -* ]]; then
      key=${arg#-}
      key=${key#-}
      if lsi_sensitive_key "$key"; then
        redact_next=true
      fi
    fi
    printf -v quoted '%q' "$arg"
    output+="${output:+ }$quoted"
  done
  printf '%s' "$output"
}

lsi_sensitive_key() {
  local key=${1^^}
  key=${key//-/_}
  [[ $key == *PASSWORD* || $key == *PASSWD* || $key == *TOKEN* ||
    $key == *SECRET* || $key == *CREDENTIAL* || $key == *API_KEY* ||
    $key == *PRIVATE_KEY* || $key == *ACCESS_KEY* ]]
}

lsi_run() {
  local display
  display=$(lsi_shell_join "$@")
  lsi_info "+ $display"
  if [[ $LSI_DRY_RUN == true ]]; then
    return 0
  fi
  "$@"
}

lsi_confirm() {
  local prompt=${1:-Continue?}
  local reply
  [[ $LSI_ASSUME_YES == true ]] && return 0
  [[ -t 0 ]] || lsi_die 'Confirmation required in non-interactive mode; pass --yes.' 2
  read -r -p "$prompt [y/N] " reply
  [[ $reply == [yY] || $reply == [yY][eE][sS] ]]
}

lsi_require_root() {
  ((EUID == 0)) || lsi_die 'Installation requires root. Re-run the command with sudo.' 4
}

lsi_acquire_lock() {
  local lock_file=${1:-/run/lock/linux-software-installer.lock}
  local lock_dir=${lock_file%/*}
  [[ $lock_dir != "$lock_file" ]] || lock_dir='.'
  command -v flock > /dev/null 2>&1 ||
    lsi_die 'Required concurrent-run protection is unavailable: flock.' 4
  mkdir -p "$lock_dir" ||
    lsi_die "Unable to create the runtime lock directory: $lock_dir" 4
  exec 9> "$lock_file" ||
    lsi_die 'Unable to open the installer lock file.' 4
  flock -n 9 || lsi_die 'Another linux-software-installer process is running.' 4
}

lsi_initialize_log() {
  [[ $LSI_DRY_RUN == false ]] || return 0
  local log_dir=${1:-/var/log/linux-software-installer}
  local log_name owner link_count
  log_dir=${log_dir%/}
  [[ -n $log_dir ]] || lsi_die 'The installer log directory cannot be empty.' 4

  if [[ -L $log_dir || (-e $log_dir && ! -d $log_dir) ]]; then
    lsi_die "Refusing unsafe installer log directory: $log_dir" 4
  fi
  mkdir -p "$log_dir" || lsi_die "Unable to create installer log directory: $log_dir" 4
  [[ ! -L $log_dir && -d $log_dir ]] ||
    lsi_die "Refusing unsafe installer log directory: $log_dir" 4
  owner=$(stat -c '%u' -- "$log_dir") || lsi_die 'Unable to inspect installer log directory ownership.' 4
  [[ $owner == "$EUID" ]] || lsi_die 'Installer log directory is not owned by the effective user.' 4
  chmod 0750 "$log_dir" || lsi_die 'Unable to protect installer log directory.' 4

  if [[ -z $LSI_LOG_FILE ]]; then
    LSI_LOG_FILE="$log_dir/run-$(date -u '+%Y%m%dT%H%M%SZ')-$$.log"
  fi
  case "$LSI_LOG_FILE" in
    "$log_dir"/*) ;;
    *) lsi_die 'Refusing installer log path outside the protected log directory.' 4 ;;
  esac
  log_name=${LSI_LOG_FILE#"$log_dir"/}
  [[ $log_name != */* && $log_name =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] ||
    lsi_die 'Refusing unsafe installer log file name.' 4
  [[ ! -e $LSI_LOG_FILE && ! -L $LSI_LOG_FILE ]] ||
    lsi_die 'Refusing to reuse an existing installer log path.' 4

  (
    set -o noclobber
    : > "$LSI_LOG_FILE"
  ) 2> /dev/null ||
    lsi_die 'Unable to create a new installer log file safely.' 4
  [[ ! -L $LSI_LOG_FILE && -f $LSI_LOG_FILE ]] ||
    lsi_die 'Refusing non-regular installer log file.' 4
  owner=$(stat -c '%u' -- "$LSI_LOG_FILE") || lsi_die 'Unable to inspect installer log ownership.' 4
  link_count=$(stat -c '%h' -- "$LSI_LOG_FILE") || lsi_die 'Unable to inspect installer log link count.' 4
  [[ $owner == "$EUID" && $link_count == 1 ]] ||
    lsi_die 'Refusing installer log file with unsafe ownership or links.' 4
  chmod 0600 "$LSI_LOG_FILE" || lsi_die 'Unable to protect installer log file.' 4
  LSI_LOG_INITIALIZED=true
}

lsi_append_unique() {
  local -n target=$1
  local candidate=$2 existing
  for existing in "${target[@]}"; do
    [[ $existing == "$candidate" ]] && return 0
  done
  target+=("$candidate")
}
