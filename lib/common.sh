#!/usr/bin/env bash

LSI_VERSION="$(< "$LSI_PROJECT_ROOT/VERSION")"
LSI_DRY_RUN=${LSI_DRY_RUN:-false}
LSI_ASSUME_YES=${LSI_ASSUME_YES:-false}
LSI_ENABLE_SERVICES=${LSI_ENABLE_SERVICES:-false}
LSI_NO_REFRESH=${LSI_NO_REFRESH:-false}
LSI_FORCE_UNSUPPORTED=${LSI_FORCE_UNSUPPORTED:-false}
LSI_VERBOSE=${LSI_VERBOSE:-false}
LSI_LOG_FILE=${LSI_LOG_FILE:-}

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
  [[ -n $LSI_LOG_FILE ]] || return 0
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
  local output='' quoted arg
  for arg in "$@"; do
    printf -v quoted '%q' "$arg"
    output+="${output:+ }$quoted"
  done
  printf '%s' "$output"
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
  command -v flock > /dev/null 2>&1 || {
    lsi_warn 'flock is unavailable; concurrent-run protection is disabled.'
    return 0
  }
  exec 9> /run/lock/linux-software-installer.lock
  flock -n 9 || lsi_die 'Another linux-software-installer process is running.' 4
}

lsi_initialize_log() {
  [[ $LSI_DRY_RUN == false ]] || return 0
  local log_dir='/var/log/linux-software-installer'
  mkdir -p "$log_dir"
  chmod 0750 "$log_dir"
  if [[ -z $LSI_LOG_FILE ]]; then
    LSI_LOG_FILE="$log_dir/run-$(date -u '+%Y%m%dT%H%M%SZ').log"
  fi
  touch "$LSI_LOG_FILE"
  chmod 0600 "$LSI_LOG_FILE"
}

lsi_append_unique() {
  local -n target=$1
  local candidate=$2 existing
  for existing in "${target[@]}"; do
    [[ $existing == "$candidate" ]] && return 0
  done
  target+=("$candidate")
}
