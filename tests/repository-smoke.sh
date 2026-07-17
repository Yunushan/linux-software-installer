#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
export LC_ALL=C

ROOT_DIR=${1:-/workspace}
export LSI_PROJECT_ROOT="$ROOT_DIR"

# shellcheck source=../lib/common.sh
source "$ROOT_DIR/lib/common.sh"
# shellcheck source=../lib/os.sh
source "$ROOT_DIR/lib/os.sh"
# shellcheck source=../lib/catalog.sh
source "$ROOT_DIR/lib/catalog.sh"

declare -A seen_packages=()
declare -a packages=() module_packages=() missing=()
resolved_modules=0

lsi_detect_os
lsi_validate_os_support
lsi_discover_modules

for module in "${LSI_MODULE_IDS[@]}"; do
  lsi_load_module "$module"
  lsi_module_supports_current_target || continue
  mapfile -t module_packages < <(lsi_module_packages_for_target \
    "$LSI_OS_FAMILY" "$LSI_OS_ID" "$LSI_OS_VERSION_ID" "$LSI_ARCH")
  for package in "${module_packages[@]}"; do
    [[ -z ${seen_packages[$package]+x} ]] || continue
    seen_packages[$package]=1
    packages+=("$package")
  done
done

printf 'Resolving %d unique packages for %s (%s)\n' \
  "${#packages[@]}" "$LSI_OS_PRETTY_NAME" "$LSI_ARCH"

case "$LSI_OS_FAMILY" in
  debian)
    apt-get -o Acquire::Retries=3 update -qq
    for package in "${packages[@]}"; do
      apt-cache show --no-all-versions "$package" > /dev/null 2>&1 || missing+=("$package")
    done
    ;;
  rhel)
    dnf -q -y --setopt=retries=3 makecache
    for package in "${packages[@]}"; do
      dnf -q list "$package" > /dev/null 2>&1 || missing+=("$package")
    done
    ;;
esac

if ((${#missing[@]} > 0)); then
  printf 'Packages unavailable from enabled repositories:\n' >&2
  printf '  - %s\n' "${missing[@]}" >&2
  exit 1
fi

for module in "${LSI_MODULE_IDS[@]}"; do
  lsi_load_module "$module"
  lsi_module_supports_current_target || continue
  case "$LSI_OS_FAMILY" in
    debian)
      mapfile -t module_packages < <(lsi_module_packages_for_target \
        "$LSI_OS_FAMILY" "$LSI_OS_ID" "$LSI_OS_VERSION_ID" "$LSI_ARCH")
      if ! apt-get install --simulate --no-install-recommends \
        "${module_packages[@]}" > /dev/null 2>&1; then
        printf 'Dependency solving failed for %s: %s\n' \
          "$module" "${module_packages[*]}" >&2
        exit 1
      fi
      ;;
    rhel)
      mapfile -t module_packages < <(lsi_module_packages_for_target \
        "$LSI_OS_FAMILY" "$LSI_OS_ID" "$LSI_OS_VERSION_ID" "$LSI_ARCH")
      solver_output=''
      if solver_output=$(dnf -q --setopt=retries=3 \
        --setopt=install_weak_deps=False --assumeno install \
        "${module_packages[@]}" 2>&1); then
        :
      elif [[ $solver_output == *'Operation aborted.'* ]]; then
        :
      else
        printf 'Dependency solving failed for %s: %s\n%s\n' \
          "$module" "${module_packages[*]}" "$solver_output" >&2
        exit 1
      fi
      ;;
  esac
  resolved_modules=$((resolved_modules + 1))
done

printf 'Repository availability and dependency solving passed for %d packages across %d modules.\n' \
  "${#packages[@]}" "$resolved_modules"
