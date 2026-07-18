#!/usr/bin/env bash

declare -ga LSI_DIRECT_MODULES=()
declare -ga LSI_REQUESTED_PROFILES=()
declare -ga LSI_FINAL_MODULES=()
declare -gA LSI_ALLOWED_FOREIGN_ARCHITECTURES=()

lsi_usage() {
  cat << 'EOF'
linux-software-installer - safe, distro-aware package installation

Usage:
  ./install.sh                         Interactive selection
  ./install.sh list                    List stable modules
  ./install.sh profiles                List module profiles
  ./install.sh info MODULE             Show module details
  ./install.sh migrations              List all read-only legacy guidance
  ./install.sh migrate LEGACY_ID       Show read-only guidance for one legacy entry
  ./install.sh retirement-status       Show whether the old repositories can be retired
  ./install.sh doctor                  Check the local environment
  ./install.sh plan MODULE...          Preview commands without changes
  ./install.sh plan --profile PROFILE  Preview a profile
  sudo ./install.sh install MODULE...  Install one or more modules
  sudo ./install.sh install --profile PROFILE

Options:
  --profile NAME        Add a predefined module profile (repeatable)
  --yes, -y             Skip the normal confirmation prompt
  --enable-services     Enable and start declared services after installation
  --allow-foreign-architecture ARCH
                       Explicitly permit a reviewed global Debian multiarch change
  --no-refresh          Do not refresh package repository metadata
  --dry-run             Print commands without executing them
  --force-unsupported   Bypass the legacy-version guard
  --verbose             Enable diagnostic output
  --no-color            Disable colored output
  --help, -h            Show this help
  --version             Show the project version

Only active OS repositories are used. The reference scripts under legacy/ are
never invoked by this command.
EOF
}

lsi_parse_module_csv() {
  local value=$1 item
  local IFS=', '
  local -a items=()
  read -r -a items <<< "$value"
  for item in "${items[@]}"; do
    [[ -n $item ]] || continue
    lsi_append_unique LSI_DIRECT_MODULES "$item"
  done
}

lsi_parse_options() {
  while (($# > 0)); do
    case "$1" in
      --profile)
        (($# >= 2)) || lsi_die '--profile requires a value.' 2
        lsi_append_unique LSI_REQUESTED_PROFILES "$2"
        shift 2
        ;;
      --profile=*)
        lsi_append_unique LSI_REQUESTED_PROFILES "${1#*=}"
        shift
        ;;
      --yes | -y)
        LSI_ASSUME_YES=true
        shift
        ;;
      --enable-services)
        LSI_ENABLE_SERVICES=true
        shift
        ;;
      --allow-foreign-architecture)
        (($# >= 2)) || lsi_die '--allow-foreign-architecture requires an architecture.' 2
        lsi_valid_debian_foreign_architecture "$2" ||
          lsi_die "Unsupported foreign architecture: $2" 2
        [[ -z ${LSI_ALLOWED_FOREIGN_ARCHITECTURES[$2]+x} ]] ||
          lsi_die "Duplicate foreign-architecture acknowledgement: $2" 2
        LSI_ALLOWED_FOREIGN_ARCHITECTURES["$2"]=1
        shift 2
        ;;
      --allow-foreign-architecture=*)
        lsi_die '--allow-foreign-architecture requires a separate architecture argument.' 2
        ;;
      --no-refresh)
        LSI_NO_REFRESH=true
        shift
        ;;
      --dry-run)
        LSI_DRY_RUN=true
        shift
        ;;
      --force-unsupported)
        LSI_FORCE_UNSUPPORTED=true
        shift
        ;;
      --verbose)
        LSI_VERBOSE=true
        shift
        ;;
      --no-color)
        lsi_disable_color
        shift
        ;;
      --help | -h)
        lsi_usage
        exit 0
        ;;
      --version)
        printf '%s\n' "$LSI_VERSION"
        exit 0
        ;;
      --)
        shift
        while (($# > 0)); do
          lsi_parse_module_csv "$1"
          shift
        done
        ;;
      -*) lsi_die "Unknown option: $1" 2 ;;
      *)
        lsi_parse_module_csv "$1"
        shift
        ;;
    esac
  done
}

lsi_expand_requests() {
  local module profile
  LSI_FINAL_MODULES=()
  for module in "${LSI_DIRECT_MODULES[@]}"; do
    lsi_load_module "$module"
    lsi_module_supports_current_target ||
      lsi_die "Module $module does not support target $(lsi_current_target_label) ($LSI_OS_FAMILY family)." 3
    lsi_append_unique LSI_FINAL_MODULES "$module"
  done

  for profile in "${LSI_REQUESTED_PROFILES[@]}"; do
    while IFS= read -r module; do
      lsi_load_module "$module"
      if lsi_module_supports_current_target; then
        lsi_append_unique LSI_FINAL_MODULES "$module"
      else
        lsi_warn "Profile $profile: skipping $module on $LSI_OS_FAMILY (target $(lsi_current_target_label))."
      fi
    done < <(lsi_profile_modules "$profile")
  done

  ((${#LSI_FINAL_MODULES[@]} > 0)) || lsi_die 'No installable modules were selected.' 2
}

lsi_check_conflicts() {
  local id conflict selected
  for id in "${LSI_FINAL_MODULES[@]}"; do
    lsi_load_module "$id"
    for conflict in "${MODULE_CONFLICTS[@]}"; do
      for selected in "${LSI_FINAL_MODULES[@]}"; do
        [[ $selected != "$conflict" ]] || lsi_die "Conflicting modules selected: $id and $conflict." 2
      done
    done
  done
}

lsi_required_foreign_architectures() {
  local id architecture
  local -A required=()

  for id in "${LSI_FINAL_MODULES[@]}"; do
    lsi_load_module "$id"
    while IFS= read -r architecture; do
      [[ -n $architecture ]] && required["$architecture"]=1
    done < <(lsi_module_debian_foreign_architectures)
  done
  ((${#required[@]} == 0)) || printf '%s\n' "${!required[@]}" | LC_ALL=C sort
}

lsi_check_foreign_architecture_acknowledgements() {
  local architecture
  local -A required=()

  while IFS= read -r architecture; do
    [[ -n $architecture ]] && required["$architecture"]=1
  done < <(lsi_required_foreign_architectures)
  for architecture in "${!required[@]}"; do
    [[ -n ${LSI_ALLOWED_FOREIGN_ARCHITECTURES[$architecture]+x} ]] ||
      lsi_die "Module selection requires --allow-foreign-architecture $architecture; this changes global Debian package-architecture state." 2
  done
  for architecture in "${!LSI_ALLOWED_FOREIGN_ARCHITECTURES[@]}"; do
    [[ -n ${required[$architecture]+x} ]] ||
      lsi_die "Foreign-architecture acknowledgement is not used by the selected modules: $architecture" 2
  done
}

lsi_show_plan() {
  local id architecture
  local -a foreign_architectures=()
  printf '\n%sInstallation plan%s\n' "$LSI_COLOR_BOLD" "$LSI_COLOR_RESET"
  lsi_print_os_info
  printf 'Refresh repos : %s\n' "$([[ $LSI_NO_REFRESH == true ]] && printf 'no' || printf 'yes')"
  printf 'Start services: %s\n' "$([[ $LSI_ENABLE_SERVICES == true ]] && printf 'yes' || printf 'no')"
  mapfile -t foreign_architectures < <(lsi_required_foreign_architectures)
  if ((${#foreign_architectures[@]} > 0)); then
    for architecture in "${foreign_architectures[@]}"; do
      printf 'Foreign arch  : %s (requires --allow-foreign-architecture %s)\n' \
        "$architecture" "$architecture"
    done
  fi
  printf 'Modules:\n'
  for id in "${LSI_FINAL_MODULES[@]}"; do
    lsi_plan_module "$id"
  done
  printf '\n'
}

lsi_interactive_select() {
  local id selection token index
  local -a available=() selections=()
  lsi_discover_modules
  printf '\nAvailable modules for %s:\n\n' "$LSI_OS_FAMILY"
  for id in "${LSI_MODULE_IDS[@]}"; do
    lsi_load_module "$id"
    if lsi_module_supports_current_target; then
      available+=("$id")
      printf '  %2d) %-18s %s\n' "${#available[@]}" "$id" "$MODULE_DESCRIPTION"
    fi
  done
  printf '\nEnter numbers or module names separated by spaces/commas: '
  read -r selection
  IFS=', ' read -r -a selections <<< "$selection"
  for token in "${selections[@]}"; do
    [[ -n $token ]] || continue
    if [[ $token =~ ^[0-9]+$ ]]; then
      index=$((token - 1))
      ((index >= 0 && index < ${#available[@]})) || lsi_die "Invalid selection number: $token" 2
      id=${available[$index]}
    else
      id=$token
    fi
    lsi_append_unique LSI_DIRECT_MODULES "$id"
  done
}

lsi_doctor() {
  local failures=0
  lsi_detect_os
  lsi_validate_os_support
  lsi_print_os_info
  printf 'Bash         : %s\n' "$BASH_VERSION"
  if command -v "$LSI_PACKAGE_MANAGER" > /dev/null 2>&1; then
    printf 'Package tool : available\n'
  else
    printf 'Package tool : missing (%s)\n' "$LSI_PACKAGE_MANAGER"
    failures=$((failures + 1))
  fi
  if ((EUID == 0)); then
    printf 'Privileges   : root\n'
  else
    printf 'Privileges   : unprivileged (fine for plan/list; use sudo for install)\n'
  fi
  command -v systemctl > /dev/null 2>&1 && printf 'systemctl    : available\n' || printf 'systemctl    : unavailable\n'
  lsi_discover_modules
  printf 'Modules      : %d discovered\n' "${#LSI_MODULE_IDS[@]}"
  ((failures == 0))
}

lsi_execute() {
  local id
  lsi_expand_requests
  lsi_check_conflicts
  lsi_show_plan

  if [[ $LSI_DRY_RUN == true ]]; then
    for id in "${LSI_FINAL_MODULES[@]}"; do
      lsi_install_module "$id"
    done
    lsi_success 'Dry run completed; no system changes were made.'
    return 0
  fi

  lsi_check_foreign_architecture_acknowledgements
  lsi_confirm 'Apply this installation plan?' || lsi_die 'Installation cancelled.' 130
  lsi_require_root
  lsi_acquire_lock
  lsi_initialize_log
  lsi_preflight
  for id in "${LSI_FINAL_MODULES[@]}"; do
    lsi_install_module "$id"
  done
  lsi_success "All modules completed. Log: $LSI_LOG_FILE"
}

lsi_main() {
  local command=${1:-interactive}
  if (($# > 0)); then shift; fi

  case "$command" in
    help | --help | -h) lsi_usage ;;
    version | --version) printf '%s\n' "$LSI_VERSION" ;;
    list)
      lsi_parse_options "$@"
      lsi_list_modules
      ;;
    profiles)
      lsi_parse_options "$@"
      lsi_list_profiles
      ;;
    info)
      (($# >= 1)) || lsi_die 'info requires a module name.' 2
      lsi_show_module "$1"
      ;;
    migrations)
      (($# == 0)) || lsi_die 'migrations does not accept arguments.' 2
      lsi_migration_list
      ;;
    retirement-status)
      (($# == 0)) || lsi_die 'retirement-status does not accept arguments.' 2
      lsi_migration_retirement_status
      ;;
    migrate)
      (($# == 1)) || lsi_die 'migrate requires exactly one legacy ID.' 2
      lsi_migration_show "$1"
      ;;
    doctor)
      lsi_parse_options "$@"
      lsi_doctor
      ;;
    plan)
      LSI_DRY_RUN=true
      lsi_parse_options "$@"
      lsi_detect_os
      lsi_validate_os_support
      lsi_execute
      ;;
    install)
      lsi_parse_options "$@"
      lsi_detect_os
      lsi_validate_os_support
      lsi_execute
      ;;
    interactive)
      [[ -t 0 ]] || {
        lsi_usage
        lsi_die 'No command was supplied in a non-interactive session.' 2
      }
      lsi_detect_os
      lsi_validate_os_support
      lsi_interactive_select
      lsi_execute
      ;;
    *) lsi_die "Unknown command: $command" 2 ;;
  esac
}
