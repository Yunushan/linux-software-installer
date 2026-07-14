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
  declare -ga MODULE_DEBIAN_SERVICES=()
  declare -ga MODULE_RHEL_SERVICES=()
  declare -ga MODULE_VERIFY_BINARIES=()
  declare -ga MODULE_DEBIAN_VERIFY_BINARIES=()
  declare -ga MODULE_RHEL_VERIFY_BINARIES=()
  declare -ga MODULE_CONFLICTS=()
}

lsi_module_path() {
  local id=$1
  lsi_valid_slug "$id" || return 1
  printf '%s/%s/module.sh' "$LSI_MODULE_DIR" "$id"
}

lsi_load_module() {
  local requested_id=$1 path
  path=$(lsi_module_path "$requested_id") || lsi_die "Invalid module name: $requested_id" 2
  [[ -f $path ]] || lsi_die "Unknown module: $requested_id" 2
  lsi_module_reset
  # Module manifests are maintained in this repository and contain metadata only.
  # shellcheck disable=SC1090
  source "$path"
  [[ $MODULE_ID == "$requested_id" ]] || lsi_die "Module ID mismatch in $path." 3
  [[ -n $MODULE_NAME && ${#MODULE_FAMILIES[@]} -gt 0 ]] || lsi_die "Incomplete module metadata: $requested_id" 3
}

lsi_discover_modules() {
  local path id
  LSI_MODULE_IDS=()
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

lsi_list_modules() {
  local id families
  lsi_discover_modules
  printf '%-18s %-11s %-16s %s\n' 'MODULE' 'CATEGORY' 'FAMILIES' 'DESCRIPTION'
  printf '%-18s %-11s %-16s %s\n' '------' '--------' '--------' '-----------'
  for id in "${LSI_MODULE_IDS[@]}"; do
    lsi_load_module "$id"
    families=$(lsi_join_by ',' "${MODULE_FAMILIES[@]}")
    printf '%-18s %-11s %-16s %s\n' "$MODULE_ID" "$MODULE_CATEGORY" "$families" "$MODULE_DESCRIPTION"
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
