#!/usr/bin/env bash

LSI_OS_ID=''
LSI_OS_ID_LIKE=''
LSI_OS_VERSION_ID=''
LSI_OS_MAJOR=''
LSI_OS_PRETTY_NAME=''
LSI_OS_FAMILY=''
LSI_PACKAGE_MANAGER=${LSI_PACKAGE_MANAGER:-}
LSI_ARCH=''

lsi_os_value() {
  local value=$1
  if [[ $value == \"*\" && $value == *\" ]]; then
    value=${value:1:${#value}-2}
  elif [[ $value == \'*\' && $value == *\' ]]; then
    value=${value:1:${#value}-2}
  fi
  printf '%s' "$value"
}

lsi_detect_os() {
  local os_release=${LSI_OS_RELEASE_FILE:-/etc/os-release}
  local key value signature
  [[ -r $os_release ]] || lsi_die "Cannot read OS metadata: $os_release" 3

  while IFS='=' read -r key value; do
    [[ -n $key && $key != \#* ]] || continue
    value=$(lsi_os_value "$value")
    case "$key" in
      ID) LSI_OS_ID=${value,,} ;;
      ID_LIKE) LSI_OS_ID_LIKE=${value,,} ;;
      VERSION_ID) LSI_OS_VERSION_ID=$value ;;
      PRETTY_NAME) LSI_OS_PRETTY_NAME=$value ;;
    esac
  done < "$os_release"

  [[ -n $LSI_OS_ID ]] || lsi_die "OS metadata in $os_release does not define ID." 3
  LSI_OS_MAJOR=${LSI_OS_VERSION_ID%%.*}
  LSI_ARCH=$(uname -m)
  signature=" $LSI_OS_ID $LSI_OS_ID_LIKE "

  if [[ $signature == *' debian '* || $LSI_OS_ID == ubuntu || $LSI_OS_ID == linuxmint ]]; then
    LSI_OS_FAMILY=debian
    LSI_PACKAGE_MANAGER=${LSI_PACKAGE_MANAGER:-apt-get}
  elif [[ $signature == *' rhel '* || $signature == *' fedora '* || $LSI_OS_ID =~ ^(rhel|rocky|almalinux|centos|fedora|ol)$ ]]; then
    LSI_OS_FAMILY=rhel
    LSI_PACKAGE_MANAGER=${LSI_PACKAGE_MANAGER:-dnf}
  else
    lsi_die "Unsupported Linux distribution: $LSI_OS_ID (${LSI_OS_PRETTY_NAME:-unknown version})." 3
  fi

  lsi_debug "Detected id=$LSI_OS_ID family=$LSI_OS_FAMILY version=$LSI_OS_VERSION_ID arch=$LSI_ARCH"
}

lsi_validate_os_support() {
  if [[ $LSI_FORCE_UNSUPPORTED == true ]]; then
    lsi_warn 'Unsupported-version guard was bypassed with --force-unsupported.'
    return 0
  fi

  if [[ $LSI_OS_ID == centos && $LSI_OS_MAJOR =~ ^[0-9]+$ && $LSI_OS_MAJOR -lt 8 ]]; then
    lsi_die "CentOS $LSI_OS_VERSION_ID is legacy-only and is not supported by the active installer." 3
  fi
}

lsi_print_os_info() {
  printf 'Distribution : %s\n' "${LSI_OS_PRETTY_NAME:-$LSI_OS_ID}"
  printf 'ID           : %s\n' "$LSI_OS_ID"
  printf 'Family       : %s\n' "$LSI_OS_FAMILY"
  printf 'Version      : %s\n' "${LSI_OS_VERSION_ID:-unknown}"
  printf 'Architecture : %s\n' "$LSI_ARCH"
  printf 'Package tool : %s\n' "$LSI_PACKAGE_MANAGER"
}
