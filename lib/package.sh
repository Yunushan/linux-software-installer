#!/usr/bin/env bash

LSI_REFRESHED=false
declare -gA LSI_COMPLETED_MODULES=()
declare -gA LSI_CONFIGURED_FOREIGN_ARCHITECTURES=()

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

lsi_configure_debian_foreign_architectures() {
  local architecture existing
  local -a architectures=() existing_architectures=()
  local -A configured=()

  [[ $LSI_OS_FAMILY == debian ]] || return 0
  mapfile -t architectures < <(lsi_module_debian_foreign_architectures)
  ((${#architectures[@]} > 0)) || return 0
  command -v dpkg > /dev/null 2>&1 ||
    lsi_die 'dpkg is required to configure a declared foreign architecture.' 4
  mapfile -t existing_architectures < <(dpkg --print-foreign-architectures)
  for existing in "${existing_architectures[@]}"; do
    [[ -n $existing ]] && configured["$existing"]=1
  done

  for architecture in "${architectures[@]}"; do
    [[ -n ${configured[$architecture]+x} ||
      -n ${LSI_CONFIGURED_FOREIGN_ARCHITECTURES[$architecture]+x} ]] && continue
    lsi_info "Configuring foreign Debian package architecture: $architecture"
    lsi_run dpkg --add-architecture "$architecture"
    LSI_CONFIGURED_FOREIGN_ARCHITECTURES["$architecture"]=1
  done
}

lsi_install_packages() {
  local package
  local -a packages=("$@") filtered_packages=()
  (($# > 0)) || return 0
  case "$LSI_OS_FAMILY" in
    debian)
      lsi_run env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${packages[@]}"
      ;;
    rhel)
      # Rocky/Alma minimal installations use curl-minimal, which conflicts with
      # the full curl RPM. Conversely, do not replace a full curl RPM already
      # selected by an administrator merely because a module names the minimal
      # provider.
      if [[ ${LSI_DRY_RUN:-false} == false ]] &&
        command -v rpm > /dev/null 2>&1 &&
        rpm -q curl > /dev/null 2>&1; then
        for package in "${packages[@]}"; do
          [[ $package == curl-minimal ]] || filtered_packages+=("$package")
        done
        packages=("${filtered_packages[@]}")
      fi
      [[ ${#packages[@]} -gt 0 ]] || return 0
      lsi_run dnf -y install "${packages[@]}"
      ;;
    *)
      lsi_die "No package installation implementation for $LSI_OS_FAMILY." 3
      ;;
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
    if ! lsi_resolve_verification_binary "$binary" > /dev/null; then
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
  lsi_module_supports_current_target ||
    lsi_die "Module $id does not support target $(lsi_current_target_label) ($LSI_OS_FAMILY family)." 3
  mapfile -t packages < <(lsi_module_packages)
  [[ ${#packages[@]} -gt 0 && -n ${packages[0]} ]] || lsi_die "Module $id has no package mapping for $LSI_OS_FAMILY." 3

  if [[ $LSI_DRY_RUN == true ]]; then
    lsi_info "Planning $MODULE_NAME"
  else
    lsi_info "Installing $MODULE_NAME"
  fi
  lsi_configure_debian_foreign_architectures
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
