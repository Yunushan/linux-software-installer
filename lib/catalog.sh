#!/usr/bin/env bash

LSI_MODULE_DIR="$LSI_PROJECT_ROOT/modules"
LSI_PROFILE_DIR="$LSI_PROJECT_ROOT/profiles"
declare -ga LSI_MODULE_IDS=()

lsi_valid_slug() {
  [[ $1 =~ ^[a-z0-9][a-z0-9-]*$ ]]
}

lsi_module_reset() {
  unset MODULE_ID MODULE_NAME MODULE_DESCRIPTION MODULE_CATEGORY MODULE_STATUS MODULE_RISK MODULE_NOTES
  declare -g MODULE_ID=''
  declare -g MODULE_NAME=''
  declare -g MODULE_DESCRIPTION=''
  declare -g MODULE_CATEGORY='utility'
  declare -g MODULE_STATUS='stable'
  declare -g MODULE_RISK='low'
  declare -g MODULE_NOTES=''
  declare -ga MODULE_FAMILIES=()
  declare -ga MODULE_DEBIAN_PACKAGES=()
  declare -ga MODULE_RHEL_PACKAGES=()
  declare -ga MODULE_TARGET_PACKAGE_OVERRIDES=()
  declare -ga MODULE_DEBIAN_SERVICES=()
  declare -ga MODULE_RHEL_SERVICES=()
  declare -ga MODULE_VERIFY_BINARIES=()
  declare -ga MODULE_DEBIAN_VERIFY_BINARIES=()
  declare -ga MODULE_RHEL_VERIFY_BINARIES=()
  declare -ga MODULE_CONFLICTS=()
  declare -ga MODULE_TARGET_CELLS=()
}

lsi_module_path() {
  local id=$1
  lsi_valid_slug "$id" || return 1
  printf '%s/%s/module.sh' "$LSI_MODULE_DIR" "$id"
}

lsi_module_manifest_is_safe() {
  local requested_id=$1 path module_dir link_count
  path=$(lsi_module_path "$requested_id") || return 1
  module_dir=${path%/*}

  [[ -d $LSI_MODULE_DIR && ! -L $LSI_MODULE_DIR &&
    -d $module_dir && ! -L $module_dir &&
    -f $path && ! -L $path && -x /usr/bin/stat ]] || return 1
  link_count=$(/usr/bin/stat -c '%h' -- "$path") || return 1
  [[ $link_count == 1 ]]
}

lsi_load_module() {
  local requested_id=$1 path
  path=$(lsi_module_path "$requested_id") || lsi_die "Invalid module name: $requested_id" 2
  [[ -e $path || -L $path ]] || lsi_die "Unknown module: $requested_id" 2
  lsi_module_manifest_is_safe "$requested_id" ||
    lsi_die "Unsafe module manifest: $requested_id" 3
  lsi_module_reset
  # Module manifests are maintained in this repository and contain metadata only.
  # shellcheck disable=SC1090
  source "$path"
  [[ $MODULE_ID == "$requested_id" ]] || lsi_die "Module ID mismatch in $path." 3
  [[ -n $MODULE_NAME && ${#MODULE_FAMILIES[@]} -gt 0 ]] || lsi_die "Incomplete module metadata: $requested_id" 3
  lsi_validate_module_target_cells
  lsi_validate_module_target_package_overrides
}

lsi_discover_modules() {
  local path id
  LSI_MODULE_IDS=()
  [[ -d $LSI_MODULE_DIR && ! -L $LSI_MODULE_DIR ]] ||
    lsi_die "Unsafe module catalog directory: $LSI_MODULE_DIR" 3
  for path in "$LSI_MODULE_DIR"/*/module.sh; do
    [[ -f $path ]] || continue
    id=${path%/module.sh}
    id=${id##*/}
    LSI_MODULE_IDS+=("$id")
  done
}

lsi_module_supports_family() {
  local family=$1 supported
  for supported in "${MODULE_FAMILIES[@]}"; do
    [[ $supported == "$family" ]] && return 0
  done
  return 1
}

lsi_target_id_family() {
  case "$1" in
    debian | ubuntu | linuxmint) printf 'debian' ;;
    almalinux | centos | fedora | ol | rhel | rocky) printf 'rhel' ;;
    *) return 1 ;;
  esac
}

lsi_known_target_architecture() {
  case "$1" in
    aarch64 | armv7l | ppc64le | riscv64 | s390x | x86_64) return 0 ;;
    *) return 1 ;;
  esac
}

lsi_parse_target_cell() {
  local cell=$1
  local -n id_ref=$2 version_ref=$3 arch_ref=$4
  local extra=''
  IFS=':' read -r id_ref version_ref arch_ref extra <<< "$cell"
  [[ -z $extra && $cell == *:*:* && $cell != *:*:*:* ]] || return 1
  lsi_valid_slug "$id_ref" || return 1
  [[ $version_ref =~ ^[0-9][a-zA-Z0-9._-]*$ ]] || return 1
  [[ $arch_ref =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]] || return 1
}

lsi_validate_module_target_cells() {
  local cell id version arch family declared_family
  local -A seen_cells=() covered_families=()
  ((${#MODULE_TARGET_CELLS[@]} > 0)) || return 0

  for cell in "${MODULE_TARGET_CELLS[@]}"; do
    id=''
    version=''
    arch=''
    lsi_parse_target_cell "$cell" id version arch ||
      lsi_die "Malformed target cell in $MODULE_ID: $cell" 3
    [[ -z ${seen_cells[$cell]+x} ]] ||
      lsi_die "Duplicate target cell in $MODULE_ID: $cell" 3
    seen_cells["$cell"]=1
    family=$(lsi_target_id_family "$id") ||
      lsi_die "Unknown target OS ID in $MODULE_ID: $id" 3
    lsi_known_target_architecture "$arch" ||
      lsi_die "Unknown target architecture in $MODULE_ID: $arch" 3
    lsi_module_supports_family "$family" ||
      lsi_die "Target cell $cell is outside the declared families for $MODULE_ID." 3
    covered_families["$family"]=1
  done

  for declared_family in "${MODULE_FAMILIES[@]}"; do
    [[ -n ${covered_families[$declared_family]+x} ]] ||
      lsi_die "Restricted module $MODULE_ID has no target cell for $declared_family." 3
  done
}

lsi_module_has_target_restrictions() {
  ((${#MODULE_TARGET_CELLS[@]} > 0))
}

lsi_package_token_is_safe() {
  [[ $1 =~ ^[a-zA-Z0-9][a-zA-Z0-9+._:@/-]*$ ]]
}

lsi_parse_target_package_override() {
  local override=$1
  local -n cell_ref=$2 packages_ref=$3
  local extra=''
  IFS='=' read -r cell_ref packages_ref extra <<< "$override"
  [[ -n $cell_ref && -n $packages_ref && -z $extra && $override == *=* ]]
}

lsi_validate_module_target_package_overrides() {
  local override cell package_csv id version arch family package
  local -a packages=()
  local -A seen_cells=() seen_packages=()

  for override in "${MODULE_TARGET_PACKAGE_OVERRIDES[@]}"; do
    cell=''
    package_csv=''
    lsi_parse_target_package_override "$override" cell package_csv ||
      lsi_die "Malformed target package override in $MODULE_ID: $override" 3
    lsi_parse_target_cell "$cell" id version arch ||
      lsi_die "Malformed target package override cell in $MODULE_ID: $cell" 3
    [[ -z ${seen_cells[$cell]+x} ]] ||
      lsi_die "Duplicate target package override in $MODULE_ID: $cell" 3
    seen_cells["$cell"]=1
    family=$(lsi_target_id_family "$id") ||
      lsi_die "Unknown target OS ID in package override for $MODULE_ID: $id" 3
    lsi_known_target_architecture "$arch" ||
      lsi_die "Unknown target architecture in package override for $MODULE_ID: $arch" 3
    lsi_module_supports_family "$family" ||
      lsi_die "Target package override $cell is outside the declared families for $MODULE_ID." 3
    if lsi_module_has_target_restrictions; then
      lsi_module_supports_target "$family" "$id" "$version" "$arch" ||
        lsi_die "Target package override $cell is outside the declared target cells for $MODULE_ID." 3
    fi

    IFS=, read -r -a packages <<< "$package_csv"
    ((${#packages[@]} > 0)) ||
      lsi_die "Target package override has no packages in $MODULE_ID: $cell" 3
    seen_packages=()
    for package in "${packages[@]}"; do
      if [[ -z $package ]] || ! lsi_package_token_is_safe "$package"; then
        lsi_die "Unsafe target package override token in $MODULE_ID: $package" 3
      fi
      [[ -z ${seen_packages[$package]+x} ]] ||
        lsi_die "Duplicate target package override token in $MODULE_ID: $package" 3
      seen_packages["$package"]=1
    done
  done
}

lsi_module_supports_target() {
  local family=$1 id=$2 version=$3 arch=$4 cell
  lsi_module_supports_family "$family" || return 1
  lsi_module_has_target_restrictions || return 0
  for cell in "${MODULE_TARGET_CELLS[@]}"; do
    [[ $cell == "$id:$version:$arch" ]] && return 0
  done
  return 1
}

lsi_module_supports_current_target() {
  lsi_module_supports_target \
    "$LSI_OS_FAMILY" "$LSI_OS_ID" "$LSI_OS_VERSION_ID" "$LSI_ARCH"
}

lsi_module_packages_for_target() {
  local family=$1 id=$2 version=$3 arch=$4 override cell package_csv
  local -a packages=()

  lsi_module_supports_target "$family" "$id" "$version" "$arch" || return 1
  for override in "${MODULE_TARGET_PACKAGE_OVERRIDES[@]}"; do
    cell=''
    package_csv=''
    lsi_parse_target_package_override "$override" cell package_csv || return 1
    [[ $cell == "$id:$version:$arch" ]] || continue
    IFS=, read -r -a packages <<< "$package_csv"
    printf '%s\n' "${packages[@]}"
    return 0
  done

  case "$family" in
    debian) printf '%s\n' "${MODULE_DEBIAN_PACKAGES[@]}" ;;
    rhel) printf '%s\n' "${MODULE_RHEL_PACKAGES[@]}" ;;
    *) return 1 ;;
  esac
}

lsi_module_packages() {
  lsi_module_packages_for_target \
    "$LSI_OS_FAMILY" "$LSI_OS_ID" "$LSI_OS_VERSION_ID" "$LSI_ARCH"
}

lsi_current_target_label() {
  printf '%s:%s:%s' "$LSI_OS_ID" "${LSI_OS_VERSION_ID:-unknown}" "$LSI_ARCH"
}

lsi_module_target_summary() {
  if lsi_module_has_target_restrictions; then
    lsi_join_by ',' "${MODULE_TARGET_CELLS[@]}"
  else
    printf 'family-wide'
  fi
}

lsi_catalog_batch_modules() {
  local family=$1 requested_batch=$2 batch_count=${3:-2}
  local argument_count=$# target_id=${4:-} target_version=${5:-} target_arch=${6:-}
  local id conflict color selected_color blocked
  local -a ordered_modules=() conflicts=()
  local -A assigned_batches=()

  [[ $family == debian || $family == rhel ]] ||
    lsi_die "Unknown catalog batch family: $family" 3
  ((argument_count == 2 || argument_count == 3 || argument_count == 6)) ||
    lsi_die 'Catalog target selection requires OS ID, version and architecture together.' 3
  [[ $requested_batch =~ ^[0-9]+$ && $batch_count =~ ^[1-9][0-9]*$ ]] ||
    lsi_die 'Catalog batch indexes must be non-negative integers.' 3
  ((requested_batch < batch_count)) ||
    lsi_die "Catalog batch $requested_batch is outside 0..$((batch_count - 1))." 3

  lsi_discover_modules
  mapfile -t ordered_modules < <(printf '%s\n' "${LSI_MODULE_IDS[@]}" | LC_ALL=C sort)
  for id in "${ordered_modules[@]}"; do
    lsi_load_module "$id"
    if ((argument_count == 6)); then
      lsi_module_supports_target "$family" "$target_id" "$target_version" "$target_arch" || continue
    else
      lsi_module_supports_family "$family" || continue
    fi
    conflicts=("${MODULE_CONFLICTS[@]}")
    selected_color=-1

    for ((color = 0; color < batch_count; color++)); do
      blocked=false
      for conflict in "${conflicts[@]}"; do
        if [[ -n ${assigned_batches[$conflict]+x} && ${assigned_batches[$conflict]} -eq $color ]]; then
          blocked=true
          break
        fi
      done
      if [[ $blocked == false ]]; then
        selected_color=$color
        break
      fi
    done

    ((selected_color >= 0)) ||
      lsi_die "Catalog conflicts require more than $batch_count install batches near $id." 3
    assigned_batches["$id"]=$selected_color
    ((selected_color == requested_batch)) && printf '%s\n' "$id"
  done
  return 0
}

lsi_list_modules() {
  local id families targets
  lsi_discover_modules
  printf '%-18s %-11s %-16s %-38s %s\n' 'MODULE' 'CATEGORY' 'FAMILIES' 'TARGETS' 'DESCRIPTION'
  printf '%-18s %-11s %-16s %-38s %s\n' '------' '--------' '--------' '-------' '-----------'
  for id in "${LSI_MODULE_IDS[@]}"; do
    lsi_load_module "$id"
    families=$(lsi_join_by ',' "${MODULE_FAMILIES[@]}")
    targets=$(lsi_module_target_summary)
    printf '%-18s %-11s %-16s %-38s %s\n' \
      "$MODULE_ID" "$MODULE_CATEGORY" "$families" "$targets" "$MODULE_DESCRIPTION"
  done
}

lsi_show_module() {
  local id=$1
  lsi_load_module "$id"
  printf 'Module      : %s\n' "$MODULE_ID"
  printf 'Name        : %s\n' "$MODULE_NAME"
  printf 'Description : %s\n' "$MODULE_DESCRIPTION"
  printf 'Category    : %s\n' "$MODULE_CATEGORY"
  printf 'Status      : %s\n' "$MODULE_STATUS"
  printf 'Risk        : %s\n' "$MODULE_RISK"
  printf 'Families    : %s\n' "$(lsi_join_by ', ' "${MODULE_FAMILIES[@]}")"
  printf 'Targets     : %s\n' "$(lsi_module_target_summary)"
  printf 'APT packages: %s\n' "$(lsi_join_by ', ' "${MODULE_DEBIAN_PACKAGES[@]}")"
  printf 'DNF packages: %s\n' "$(lsi_join_by ', ' "${MODULE_RHEL_PACKAGES[@]}")"
  [[ -z $MODULE_NOTES ]] || printf 'Notes       : %s\n' "$MODULE_NOTES"
}

lsi_list_profiles() {
  local file profile description
  printf '%-14s %s\n' 'PROFILE' 'DESCRIPTION'
  printf '%-14s %s\n' '-------' '-----------'
  for file in "$LSI_PROFILE_DIR"/*.list; do
    [[ -f $file ]] || continue
    profile=${file##*/}
    profile=${profile%.list}
    description=$(sed -n 's/^# Description: //p' "$file" | head -n 1)
    printf '%-14s %s\n' "$profile" "${description:-Module bundle}"
  done
}

lsi_profile_modules() {
  local profile=$1 file line
  lsi_valid_slug "$profile" || lsi_die "Invalid profile name: $profile" 2
  file="$LSI_PROFILE_DIR/$profile.list"
  [[ -f $file ]] || lsi_die "Unknown profile: $profile" 2
  while IFS= read -r line || [[ -n $line ]]; do
    line=${line%%#*}
    line=$(lsi_trim "$line")
    [[ -n $line ]] && printf '%s\n' "$line"
  done < "$file"
}
