#!/usr/bin/env bash

LSI_REFRESHED=false
declare -gA LSI_COMPLETED_MODULES=()

lsi_preflight() {
  [[ $LSI_DRY_RUN == true ]] && return 0
  command -v "$LSI_PACKAGE_MANAGER" > /dev/null 2>&1 || lsi_die "Required package manager not found: $LSI_PACKAGE_MANAGER" 4
  command -v getent > /dev/null 2>&1 || lsi_die 'Required command not found: getent' 4
}

lsi_refresh_repositories() {
  [[ $LSI_NO_REFRESH == false ]] || return 0
  [[ $LSI_REFRESHED == false ]] || return 0
  case "$LSI_OS_FAMILY" in
    debian) lsi_run apt-get update ;;
    rhel) lsi_run dnf -y makecache ;;
    *) lsi_die "No repository refresh implementation for $LSI_OS_FAMILY." 3 ;;
  esac
  LSI_REFRESHED=true
}

lsi_install_packages() {
  (($# > 0)) || return 0
  case "$LSI_OS_FAMILY" in
    debian)
      lsi_run env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
      ;;
    rhel)
      lsi_run dnf -y install "$@"
      ;;
    *)
      lsi_die "No package installation implementation for $LSI_OS_FAMILY." 3
      ;;
  esac
}

lsi_module_packages() {
  case "$LSI_OS_FAMILY" in
    debian) ((${#MODULE_DEBIAN_PACKAGES[@]} == 0)) || printf '%s\n' "${MODULE_DEBIAN_PACKAGES[@]}" ;;
    rhel) ((${#MODULE_RHEL_PACKAGES[@]} == 0)) || printf '%s\n' "${MODULE_RHEL_PACKAGES[@]}" ;;
  esac
}

lsi_module_services() {
  case "$LSI_OS_FAMILY" in
    debian) ((${#MODULE_DEBIAN_SERVICES[@]} == 0)) || printf '%s\n' "${MODULE_DEBIAN_SERVICES[@]}" ;;
    rhel) ((${#MODULE_RHEL_SERVICES[@]} == 0)) || printf '%s\n' "${MODULE_RHEL_SERVICES[@]}" ;;
  esac
}

lsi_plan_module() {
  local id=$1
  local -a packages=() services=()
  lsi_load_module "$id"
  mapfile -t packages < <(lsi_module_packages)
  mapfile -t services < <(lsi_module_services)
  printf '  - %-16s packages: %s' "$id" "$(lsi_join_by ', ' "${packages[@]}")"
  if [[ $LSI_ENABLE_SERVICES == true && ${#services[@]} -gt 0 && -n ${services[0]} ]]; then
    printf '; enable: %s' "$(lsi_join_by ', ' "${services[@]}")"
  fi
  printf '\n'
}

lsi_verify_module() {
  local binary missing=false
  local -a binaries=()
  [[ $LSI_DRY_RUN == false ]] || return 0
  binaries=("${MODULE_VERIFY_BINARIES[@]}")
  case "$LSI_OS_FAMILY" in
    debian)
      ((${#MODULE_DEBIAN_VERIFY_BINARIES[@]} == 0)) || binaries=("${MODULE_DEBIAN_VERIFY_BINARIES[@]}")
      ;;
    rhel)
      ((${#MODULE_RHEL_VERIFY_BINARIES[@]} == 0)) || binaries=("${MODULE_RHEL_VERIFY_BINARIES[@]}")
      ;;
  esac
  for binary in "${binaries[@]}"; do
    [[ -n $binary ]] || continue
    if ! command -v "$binary" > /dev/null 2>&1; then
      lsi_error "Verification failed for $MODULE_ID: command not found: $binary"
      missing=true
    fi
  done
  [[ $missing == false ]]
}

lsi_enable_module_services() {
  local service
  local -a services=()
  [[ $LSI_ENABLE_SERVICES == true ]] || return 0
  mapfile -t services < <(lsi_module_services)
  [[ ${#services[@]} -gt 0 && -n ${services[0]} ]] || return 0
  if [[ $LSI_DRY_RUN == false ]] && ! command -v systemctl > /dev/null 2>&1; then
    lsi_warn "systemctl is unavailable; services for $MODULE_ID were not enabled."
    return 0
  fi
  for service in "${services[@]}"; do
    [[ -n $service ]] && lsi_run systemctl enable --now "$service"
  done
}

lsi_install_module() {
  local id=$1
  local -a packages=()
  [[ -z ${LSI_COMPLETED_MODULES[$id]+x} ]] || {
    lsi_debug "Skipping duplicate module: $id"
    return 0
  }
  lsi_load_module "$id"
  lsi_module_supports_family "$LSI_OS_FAMILY" || lsi_die "Module $id does not support $LSI_OS_FAMILY systems." 3
  mapfile -t packages < <(lsi_module_packages)
  [[ ${#packages[@]} -gt 0 && -n ${packages[0]} ]] || lsi_die "Module $id has no package mapping for $LSI_OS_FAMILY." 3

  if [[ $LSI_DRY_RUN == true ]]; then
    lsi_info "Planning $MODULE_NAME"
  else
    lsi_info "Installing $MODULE_NAME"
  fi
  lsi_refresh_repositories
  lsi_install_packages "${packages[@]}"
  lsi_enable_module_services
  lsi_verify_module || lsi_die "Module verification failed: $id" 6
  LSI_COMPLETED_MODULES[$id]=1
  if [[ $LSI_DRY_RUN == true ]]; then
    lsi_success "Planned $MODULE_NAME"
  else
    lsi_success "Completed $MODULE_NAME"
  fi
}
