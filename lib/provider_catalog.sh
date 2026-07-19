#!/usr/bin/env bash

# Third-party provider manifests are deliberately parsed as fixed-column TSV.
# They are never sourced and cannot supply commands or executable hooks. This
# discovery layer validates full fingerprint declarations and binds them to the
# primary OpenPGP keys in each provider-local key file. The configuration
# activation layer still must not be treated as repository-metadata or package
# verification.

LSI_PROVIDER_ROOT=${LSI_PROVIDER_ROOT:-${LSI_PROJECT_ROOT:+$LSI_PROJECT_ROOT/providers}}

LSI_PROVIDER_MANIFEST_HEADER=$'provider_id\tdisplay_name\tpublisher\thomepage\tbackend\tstatus\tdefault_persistence\tlicense_mode\tlicense_url\tlicense_revision\tauth_mode\tauth_url\tdependencies\tdescription'
LSI_PROVIDER_CELLS_HEADER=$'cell_id\tos_id\tversion_id\tarch\tmanager\tchannel\trepository_uri\tsuite\tcomponents\tkey_file\tkey_fingerprints\texpected_origin\tmetadata_signature'
LSI_PROVIDER_LOCKS_HEADER=$'module_id\tcell_id\tpackage\tversion\tarch\tsha256\tverify_binary'
LSI_PROVIDER_REGISTRY_HEADER=$'provider_id\tcatalog_revision\tcatalog_sha256'

LSI_PROVIDER_ID=''
LSI_PROVIDER_DISPLAY_NAME=''
LSI_PROVIDER_PUBLISHER=''
LSI_PROVIDER_HOMEPAGE=''
LSI_PROVIDER_BACKEND=''
LSI_PROVIDER_STATUS=''
LSI_PROVIDER_DEFAULT_PERSISTENCE=''
LSI_PROVIDER_LICENSE_MODE=''
LSI_PROVIDER_LICENSE_URL=''
LSI_PROVIDER_LICENSE_REVISION=''
LSI_PROVIDER_AUTH_MODE=''
LSI_PROVIDER_AUTH_URL=''
LSI_PROVIDER_DEPENDENCIES=''
LSI_PROVIDER_DESCRIPTION=''
LSI_PROVIDER_CATALOG_REVISION=''
LSI_PROVIDER_CATALOG_SHA256=''
LSI_PROVIDER_REGISTRY_FILE_SHA256=''
LSI_PROVIDER_TSV_FIELD_COUNT=0
declare -ga LSI_PROVIDER_CELL_ROWS=()
declare -ga LSI_PROVIDER_LOCK_ROWS=()
declare -gA LSI_PROVIDER_CELL_BY_ID=()
declare -gA LSI_PROVIDER_CELL_ARCH=()
declare -gA LSI_PROVIDER_CELL_LOCK_COUNT=()
declare -ga LSI_PROVIDER_REGISTRY_IDS=()
declare -gA LSI_PROVIDER_REGISTRY_REVISION=()
declare -gA LSI_PROVIDER_REGISTRY_SHA256=()
declare -gA LSI_PROVIDER_PLAN_ALLOWED=()
declare -gA LSI_PROVIDER_PLAN_PREVIEW=()
declare -gA LSI_PROVIDER_PLAN_LICENSE=()
declare -gA LSI_PROVIDER_PLAN_AUTH=()
declare -gA LSI_PROVIDER_PLAN_PERSIST=()
declare -gA LSI_PROVIDER_PLAN_VISITING=()
declare -gA LSI_PROVIDER_PLAN_VALIDATED=()
declare -ga LSI_PROVIDER_PLAN_ORDER=()
declare -ga LSI_PROVIDER_PLAN_MODULES=()
declare -gA LSI_PROVIDER_PLAN_ACTIVATION=()
declare -gA LSI_PROVIDER_PLAN_STATUS=()
declare -gA LSI_PROVIDER_PLAN_LICENSE_MODE=()
declare -gA LSI_PROVIDER_PLAN_LICENSE_URL=()
declare -gA LSI_PROVIDER_PLAN_LICENSE_REVISION=()
declare -gA LSI_PROVIDER_PLAN_AUTH_MODE=()
declare -gA LSI_PROVIDER_PLAN_AUTH_URL=()
declare -gA LSI_PROVIDER_PLAN_CATALOG_REVISION=()
declare -gA LSI_PROVIDER_PLAN_CATALOG_SHA256=()
declare -ga LSI_PROVIDER_PLAN_PRIMARY_LOCK_ROWS=()
LSI_PROVIDER_PLAN_PRIMARY=''
LSI_PROVIDER_PLAN_REGISTRY_SHA256=''
LSI_PROVIDER_PLAN_BODY=''
LSI_PROVIDER_PLAN_DIGEST=''
LSI_PROVIDER_APPLY_EXPECTED_DIGEST=''

lsi_provider_error() {
  printf 'Provider error: %s\n' "$*" >&2
  return 1
}

lsi_provider_reset() {
  LSI_PROVIDER_ID=''
  LSI_PROVIDER_DISPLAY_NAME=''
  LSI_PROVIDER_PUBLISHER=''
  LSI_PROVIDER_HOMEPAGE=''
  LSI_PROVIDER_BACKEND=''
  LSI_PROVIDER_STATUS=''
  LSI_PROVIDER_DEFAULT_PERSISTENCE=''
  LSI_PROVIDER_LICENSE_MODE=''
  LSI_PROVIDER_LICENSE_URL=''
  LSI_PROVIDER_LICENSE_REVISION=''
  LSI_PROVIDER_AUTH_MODE=''
  LSI_PROVIDER_AUTH_URL=''
  LSI_PROVIDER_DEPENDENCIES=''
  LSI_PROVIDER_DESCRIPTION=''
  LSI_PROVIDER_CATALOG_REVISION=''
  LSI_PROVIDER_CATALOG_SHA256=''
  LSI_PROVIDER_CELL_ROWS=()
  LSI_PROVIDER_LOCK_ROWS=()
  LSI_PROVIDER_CELL_BY_ID=()
  LSI_PROVIDER_CELL_ARCH=()
  LSI_PROVIDER_CELL_LOCK_COUNT=()
}

lsi_provider_valid_slug() {
  [[ $1 =~ ^[a-z0-9][a-z0-9-]*$ ]]
}

lsi_provider_valid_version() {
  [[ $1 =~ ^[0-9][A-Za-z0-9._-]*$ ]]
}

lsi_provider_valid_arch() {
  [[ $1 =~ ^[A-Za-z0-9_][A-Za-z0-9._-]*$ ]]
}

lsi_provider_valid_safe_text() {
  [[ -n $1 && ! $1 =~ [[:cntrl:]] ]]
}

lsi_provider_valid_https_url() {
  local value=$1 location authority path=''
  [[ $value == https://* ]] || return 1
  [[ $value != *[[:space:]]* && $value != *'@'* && $value != *'?'* && $value != *'#'* && $value != *\\* ]] || return 1

  location=${value#https://}
  [[ -n $location ]] || return 1
  authority=${location%%/*}
  if [[ $location == */* ]]; then
    path=/${location#*/}
  fi

  [[ $authority =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?([:][0-9]{1,5})?$ ]] || return 1
  [[ $authority != *..* ]] || return 1
  [[ $path =~ ^(/[A-Za-z0-9._~%+,:=/@-]*)?$ ]] || return 1
  [[ $path != *..* ]]
}

lsi_provider_valid_apt_suite() {
  local value=$1
  [[ $value =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ && $value != *..* ]]
}

lsi_provider_valid_apt_components() {
  local value=$1 item normalized=','
  local -a items=()
  [[ $value != '-' && $value != ,* && $value != *, && $value != *,,* ]] || return 1
  IFS=',' read -r -a items <<< "$value"
  ((${#items[@]} > 0)) || return 1
  for item in "${items[@]}"; do
    [[ $item =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ && $item != *..* ]] || return 1
    [[ $normalized != *",$item,"* ]] || return 1
    normalized+="$item,"
  done
}

lsi_provider_valid_apt_coordinates() {
  local repository_uri=$1 suite=$2 components=$3
  if [[ $suite == / ]]; then
    [[ $components == '-' && $repository_uri == */ ]]
    return
  fi
  lsi_provider_valid_apt_suite "$suite" &&
    lsi_provider_valid_apt_components "$components"
}

lsi_provider_valid_dependencies() {
  local value=$1 provider_id=$2 dependency normalized=','
  local -a dependencies=()
  [[ $value != '-' ]] || return 0
  IFS=',' read -r -a dependencies <<< "$value"
  ((${#dependencies[@]} > 0)) || return 1
  for dependency in "${dependencies[@]}"; do
    lsi_provider_valid_slug "$dependency" || return 1
    [[ $dependency != "$provider_id" && $normalized != *",$dependency,"* ]] || return 1
    normalized+="$dependency,"
  done
}

lsi_provider_valid_fingerprints() {
  local value=$1 fingerprint canonical normalized=','
  local -a fingerprints=()
  IFS=',' read -r -a fingerprints <<< "$value"
  ((${#fingerprints[@]} > 0)) || return 1
  for fingerprint in "${fingerprints[@]}"; do
    [[ $fingerprint =~ ^([A-Fa-f0-9]{40}|[A-Fa-f0-9]{64})$ ]] || return 1
    canonical=${fingerprint^^}
    [[ $normalized != *",$canonical,"* ]] || return 1
    normalized+="$canonical,"
  done
}

lsi_provider_remove_gpg_home() {
  local path=$1 rm_bin=$2 stat_bin=$3 owner mode
  [[ $path =~ ^/tmp/lsi-provider-gpg[.][A-Za-z0-9]+$ && -d $path && ! -L $path ]] || return 0
  owner=$("$stat_bin" -c '%u' -- "$path" 2> /dev/null) || return 0
  mode=$("$stat_bin" -c '%a' -- "$path" 2> /dev/null) || return 0
  [[ $owner == "$EUID" && $mode == 700 ]] || return 0
  "$rm_bin" -rf -- "$path"
}

lsi_provider_key_fingerprints() (
  local key_path=$1 gpg_home output record fingerprint
  local gpg_bin mktemp_bin rm_bin stat_bin owner mode
  local expect_primary=false found=0
  local -a fields=()

  gpg_bin=$(lsi_provider_system_tool gpg) || return
  mktemp_bin=$(lsi_provider_system_tool mktemp) || return
  rm_bin=$(lsi_provider_system_tool rm) || return
  stat_bin=$(lsi_provider_system_tool stat) || return

  umask 077
  gpg_home=$("$mktemp_bin" -d '/tmp/lsi-provider-gpg.XXXXXX') || {
    lsi_provider_error 'Unable to create an isolated GnuPG directory.'
    return 3
  }
  trap 'lsi_provider_remove_gpg_home "$gpg_home" "$rm_bin" "$stat_bin"' EXIT
  trap 'exit 130' HUP INT TERM
  [[ $gpg_home =~ ^/tmp/lsi-provider-gpg[.][A-Za-z0-9]+$ && -d $gpg_home && ! -L $gpg_home ]] || {
    lsi_provider_error 'GnuPG temporary directory escaped its dedicated parent.'
    return 3
  }
  owner=$("$stat_bin" -c '%u' -- "$gpg_home") || return 3
  mode=$("$stat_bin" -c '%a' -- "$gpg_home") || return 3
  [[ $owner == "$EUID" && $mode == 700 ]] || {
    lsi_provider_error 'GnuPG temporary directory has unsafe ownership or mode.'
    return 3
  }

  if ! output=$("$gpg_bin" --batch --no-options --homedir "$gpg_home" \
    --no-auto-key-locate --with-colons --import-options show-only \
    --dry-run --import "$key_path" 2> /dev/null); then
    lsi_provider_error "Provider key is not parseable OpenPGP public-key material: ${key_path##*/}"
    return 3
  fi

  while IFS= read -r record || [[ -n $record ]]; do
    IFS=':' read -r -a fields <<< "$record"
    case "${fields[0]:-}" in
      pub)
        expect_primary=true
        ;;
      sub)
        expect_primary=false
        ;;
      fpr)
        [[ $expect_primary == true ]] || continue
        fingerprint=${fields[9]:-}
        [[ $fingerprint =~ ^([A-Fa-f0-9]{40}|[A-Fa-f0-9]{64})$ ]] || {
          lsi_provider_error "GnuPG returned an invalid provider-key fingerprint: ${key_path##*/}"
          return 3
        }
        printf '%s\n' "${fingerprint^^}"
        found=$((found + 1))
        expect_primary=false
        ;;
    esac
  done <<< "$output"

  ((found > 0)) || {
    lsi_provider_error "Provider key contains no primary public key: ${key_path##*/}"
    return 3
  }
)

lsi_provider_bind_key_fingerprints() {
  local key_path=$1 declared=$2 fingerprint actual
  local actual_set=','
  local declared_count=0 actual_count=0
  local -a declared_fingerprints=()

  IFS=',' read -r -a declared_fingerprints <<< "$declared"
  declared_count=${#declared_fingerprints[@]}

  actual=$(lsi_provider_key_fingerprints "$key_path") || return
  while IFS= read -r fingerprint || [[ -n $fingerprint ]]; do
    [[ -n $fingerprint ]] || continue
    [[ $actual_set != *",$fingerprint,"* ]] || {
      lsi_provider_error "Provider key repeats a primary fingerprint: ${key_path##*/}"
      return 3
    }
    actual_set+="$fingerprint,"
    actual_count=$((actual_count + 1))
  done <<< "$actual"

  if [[ $actual_count -ne $declared_count ]]; then
    lsi_provider_error "Provider key fingerprint count does not match its declaration: ${key_path##*/}"
    return 3
  fi
  for fingerprint in "${declared_fingerprints[@]}"; do
    fingerprint=${fingerprint^^}
    [[ $actual_set == *",$fingerprint,"* ]] || {
      lsi_provider_error "Provider key fingerprint does not match its declaration: ${key_path##*/}"
      return 3
    }
  done
}

lsi_provider_count_tsv_fields() {
  local rest=$1
  LSI_PROVIDER_TSV_FIELD_COUNT=1
  while [[ $rest == *$'\t'* ]]; do
    rest=${rest#*$'\t'}
    LSI_PROVIDER_TSV_FIELD_COUNT=$((LSI_PROVIDER_TSV_FIELD_COUNT + 1))
  done
}

lsi_provider_validate_tsv_row() {
  local path=$1 line_number=$2 line=$3 expected_fields=$4
  if [[ -z $line || $line == *$'\r'* || $line == $'\t'* || $line == *$'\t' || $line == *$'\t\t'* ]]; then
    lsi_provider_error "$path:$line_number contains an empty field, blank row or carriage return."
    return
  fi
  lsi_provider_count_tsv_fields "$line"
  if [[ $LSI_PROVIDER_TSV_FIELD_COUNT -ne $expected_fields ]]; then
    lsi_provider_error "$path:$line_number has $LSI_PROVIDER_TSV_FIELD_COUNT fields; expected $expected_fields."
    return
  fi
}

lsi_provider_validate_text_file_bytes() {
  local path=$1 label=$2 maximum_size=$3 line
  local expected_size observed_size=0 stat_bin
  local unterminated=false
  local LC_ALL=C

  stat_bin=$(lsi_provider_system_tool stat) || return
  expected_size=$("$stat_bin" -c '%s' -- "$path") || {
    lsi_provider_error "Unable to inspect $label size."
    return 3
  }
  [[ $expected_size =~ ^[0-9]+$ && $expected_size -le maximum_size ]] || {
    lsi_provider_error "$label has invalid or oversized size metadata."
    return 3
  }

  while true; do
    line=''
    if IFS= read -r line; then
      observed_size=$((observed_size + ${#line} + 1))
      continue
    fi
    if [[ -n $line ]]; then
      observed_size=$((observed_size + ${#line}))
      unterminated=true
    fi
    break
  done < "$path"
  [[ $unterminated == false && $observed_size -eq $expected_size ]] || {
    lsi_provider_error "$label byte count is inconsistent (NUL data or missing terminating newline)."
    return 3
  }
}

lsi_provider_directory_for_id() {
  local provider_id=$1 directory
  lsi_provider_valid_slug "$provider_id" || {
    lsi_provider_error "Invalid provider ID: $provider_id"
    return 2
  }
  [[ -n ${LSI_PROVIDER_ROOT:-} && -d $LSI_PROVIDER_ROOT && ! -L $LSI_PROVIDER_ROOT ]] || {
    lsi_provider_error 'The provider catalog root is unavailable or unsafe.'
    return 3
  }
  directory="$LSI_PROVIDER_ROOT/$provider_id"
  [[ -d $directory && ! -L $directory ]] || {
    lsi_provider_error "Unknown provider: $provider_id"
    return 2
  }
  printf '%s\n' "$directory"
}

lsi_provider_system_tool() {
  local tool=$1 resolved
  resolved=$(builtin type -P "$tool" 2> /dev/null) || {
    lsi_provider_error "Required provider tool is unavailable: $tool"
    return 3
  }
  [[ $resolved == /* && -x $resolved && ! -L $resolved ]] || {
    lsi_provider_error "Required provider tool is unsafe: $tool"
    return 3
  }
  printf '%s\n' "$resolved"
}

lsi_provider_tree_digest() (
  local provider_directory=$1 entry name relative path size link_count digest record
  local sha256_bin stat_bin sort_bin sorted total_size=0 key_count=0 records=''
  local -a entries=() files=() key_entries=()
  local -A seen=()

  sha256_bin=$(lsi_provider_system_tool sha256sum) || return
  stat_bin=$(lsi_provider_system_tool stat) || return
  sort_bin=$(lsi_provider_system_tool sort) || return
  [[ -d $provider_directory && ! -L $provider_directory ]] || {
    lsi_provider_error 'Provider tree root is unavailable or unsafe.'
    return 3
  }

  shopt -s nullglob dotglob
  entries=("$provider_directory"/*)
  shopt -u nullglob dotglob
  for entry in "${entries[@]}"; do
    name=${entry##*/}
    case "$name" in
      provider.tsv | cells.tsv | locks.tsv)
        [[ -f $entry && ! -L $entry ]] || {
          lsi_provider_error "Provider tree entry is not a direct regular file: $name"
          return 3
        }
        seen["$name"]=1
        files+=("$name")
        ;;
      keys)
        [[ -d $entry && ! -L $entry ]] || {
          lsi_provider_error 'Provider keys entry is not a direct directory.'
          return 3
        }
        seen[keys]=1
        shopt -s nullglob dotglob
        key_entries=("$entry"/*)
        shopt -u nullglob dotglob
        for path in "${key_entries[@]}"; do
          name=${path##*/}
          [[ $name =~ ^[A-Za-z0-9][A-Za-z0-9._-]*[.](asc|gpg)$ && -f $path && ! -L $path ]] || {
            lsi_provider_error "Provider key tree contains an unknown or unsafe entry: $name"
            return 3
          }
          files+=("keys/$name")
          key_count=$((key_count + 1))
        done
        ;;
      *)
        lsi_provider_error "Provider tree contains an unregistered entry: $name"
        return 3
        ;;
    esac
  done
  [[ -n ${seen[provider.tsv]+x} && -n ${seen[cells.tsv]+x} &&
    -n ${seen[locks.tsv]+x} && -n ${seen[keys]+x} && $key_count -gt 0 ]] || {
    lsi_provider_error 'Provider tree is missing a required catalog file or key.'
    return 3
  }

  sorted=$(printf '%s\n' "${files[@]}" | "$sort_bin") || {
    lsi_provider_error 'Unable to sort provider tree entries.'
    return 3
  }
  mapfile -t files <<< "$sorted"
  ((${#files[@]} <= 64)) || {
    lsi_provider_error 'Provider tree exceeds the 64-file admission limit.'
    return 3
  }
  for relative in "${files[@]}"; do
    path="$provider_directory/$relative"
    link_count=$("$stat_bin" -c '%h' -- "$path") || return 3
    size=$("$stat_bin" -c '%s' -- "$path") || return 3
    [[ $link_count == 1 && $size =~ ^[0-9]+$ ]] || {
      lsi_provider_error "Provider tree file has unsafe links or size metadata: $relative"
      return 3
    }
    if [[ $relative == keys/* ]]; then
      ((size <= 16 * 1024 * 1024)) || {
        lsi_provider_error "Provider key exceeds the 16 MiB admission limit: $relative"
        return 3
      }
    else
      ((size <= 1024 * 1024)) || {
        lsi_provider_error "Provider catalog file exceeds the 1 MiB admission limit: $relative"
        return 3
      }
    fi
    total_size=$((total_size + size))
    ((total_size <= 32 * 1024 * 1024)) || {
      lsi_provider_error 'Provider tree exceeds the 32 MiB admission limit.'
      return 3
    }
    digest=$("$sha256_bin" -- "$path") || return 3
    digest=${digest%% *}
    [[ $digest =~ ^[0-9a-f]{64}$ ]] || {
      lsi_provider_error "Unable to hash provider tree file: $relative"
      return 3
    }
    printf -v record 'regular\t0644\t%s\t%s\t%s\n' "$relative" "$size" "$digest"
    records+=$record
  done
  digest=$(printf '%s' "$records" | "$sha256_bin") || return 3
  digest=${digest%% *}
  [[ $digest =~ ^[0-9a-f]{64}$ ]] || {
    lsi_provider_error 'Unable to hash the canonical provider tree.'
    return 3
  }
  printf '%s\n' "$digest"
)

lsi_provider_registry_load() {
  local root=${LSI_PROVIDER_ROOT:-} registry line provider_id revision digest entry name
  local line_number=0 row_count=0 link_count size stat_bin sha256_bin before_digest after_digest
  local nullglob_was_set=false dotglob_was_set=false
  local -a entries=()

  LSI_PROVIDER_REGISTRY_IDS=()
  LSI_PROVIDER_REGISTRY_REVISION=()
  LSI_PROVIDER_REGISTRY_SHA256=()
  LSI_PROVIDER_REGISTRY_FILE_SHA256=''
  [[ -n $root && -d $root && ! -L $root ]] || {
    lsi_provider_error 'The provider catalog root is unavailable or unsafe.'
    return 3
  }
  registry="$root/registry.tsv"
  [[ -f $registry && ! -L $registry ]] || {
    lsi_provider_error 'The provider admission registry is missing or unsafe.'
    return 3
  }
  stat_bin=$(lsi_provider_system_tool stat) || return
  sha256_bin=$(lsi_provider_system_tool sha256sum) || return
  link_count=$("$stat_bin" -c '%h' -- "$registry") || return 3
  size=$("$stat_bin" -c '%s' -- "$registry") || return 3
  [[ $link_count == 1 && $size =~ ^[0-9]+$ && $size -le 1048576 ]] || {
    lsi_provider_error 'The provider admission registry must be single-link and no larger than 1 MiB.'
    return 3
  }
  before_digest=$("$sha256_bin" -- "$registry") || return 3
  before_digest=${before_digest%% *}
  [[ $before_digest =~ ^[0-9a-f]{64}$ ]] || {
    lsi_provider_error 'Unable to hash the provider admission registry.'
    return 3
  }
  lsi_provider_validate_text_file_bytes "$registry" \
    'The provider admission registry' 1048576 || return

  # shellcheck disable=SC2094 # registry is only read; the path appears in validation diagnostics.
  while IFS= read -r line || [[ -n $line ]]; do
    line_number=$((line_number + 1))
    if ((line_number == 1)); then
      [[ $line == "$LSI_PROVIDER_REGISTRY_HEADER" ]] || {
        lsi_provider_error 'The provider admission registry has an unexpected header.'
        return 3
      }
      continue
    fi
    lsi_provider_validate_tsv_row "$registry" "$line_number" "$line" 3 || return
    IFS=$'\t' read -r provider_id revision digest <<< "$line"
    lsi_provider_valid_slug "$provider_id" || {
      lsi_provider_error "The provider registry contains an invalid ID: $provider_id"
      return 3
    }
    [[ $revision =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ && $digest =~ ^[0-9a-f]{64}$ ]] || {
      lsi_provider_error "The provider registry contains an invalid revision or digest: $provider_id"
      return 3
    }
    [[ -z ${LSI_PROVIDER_REGISTRY_REVISION[$provider_id]+x} ]] || {
      lsi_provider_error "The provider registry repeats an ID: $provider_id"
      return 3
    }
    LSI_PROVIDER_REGISTRY_IDS+=("$provider_id")
    LSI_PROVIDER_REGISTRY_REVISION["$provider_id"]=$revision
    LSI_PROVIDER_REGISTRY_SHA256["$provider_id"]=$digest
    row_count=$((row_count + 1))
    ((row_count <= 128)) || {
      lsi_provider_error 'The provider registry exceeds the 128-entry admission limit.'
      return 3
    }
  done < "$registry"
  ((line_number > 0)) || {
    lsi_provider_error 'The provider admission registry is empty.'
    return 3
  }

  shopt -q nullglob && nullglob_was_set=true
  shopt -q dotglob && dotglob_was_set=true
  shopt -s nullglob dotglob
  entries=("$root"/*)
  [[ $nullglob_was_set == true ]] || shopt -u nullglob
  [[ $dotglob_was_set == true ]] || shopt -u dotglob
  for entry in "${entries[@]}"; do
    name=${entry##*/}
    case "$name" in
      registry.tsv | schema.tsv)
        [[ -f $entry && ! -L $entry ]] || {
          lsi_provider_error "Unsafe provider root metadata entry: $name"
          return 3
        }
        ;;
      *)
        lsi_provider_valid_slug "$name" || {
          lsi_provider_error "Provider root contains an invalid entry name: $name"
          return 3
        }
        [[ -d $entry && ! -L $entry && -n ${LSI_PROVIDER_REGISTRY_REVISION[$name]+x} ]] || {
          lsi_provider_error "Provider root contains an unregistered or unsafe entry: $name"
          return 3
        }
        ;;
    esac
  done
  for provider_id in "${LSI_PROVIDER_REGISTRY_IDS[@]}"; do
    [[ -d $root/$provider_id && ! -L $root/$provider_id ]] || {
      lsi_provider_error "Registered provider directory is missing or unsafe: $provider_id"
      return 3
    }
  done
  after_digest=$("$sha256_bin" -- "$registry") || return 3
  after_digest=${after_digest%% *}
  [[ $after_digest == "$before_digest" ]] || {
    lsi_provider_error 'The provider admission registry changed during validation.'
    return 3
  }
  LSI_PROVIDER_REGISTRY_FILE_SHA256=$before_digest
}

lsi_provider_registry_lookup() {
  local provider_id=$1
  lsi_provider_valid_slug "$provider_id" || {
    lsi_provider_error "Invalid provider ID: $provider_id"
    return 2
  }
  lsi_provider_registry_load || return
  [[ -n ${LSI_PROVIDER_REGISTRY_REVISION[$provider_id]+x} ]] || {
    lsi_provider_error "Provider is not admitted by registry: $provider_id"
    return 2
  }
  LSI_PROVIDER_CATALOG_REVISION=${LSI_PROVIDER_REGISTRY_REVISION[$provider_id]}
  LSI_PROVIDER_CATALOG_SHA256=${LSI_PROVIDER_REGISTRY_SHA256[$provider_id]}
}

lsi_provider_validate_key_file() {
  local provider_directory=$1 key_file=$2 key_fingerprints=$3
  local key_directory key_path first_line='' last_line='' line
  [[ $key_file =~ ^keys/[A-Za-z0-9][A-Za-z0-9._-]*[.](asc|gpg)$ ]] || {
    lsi_provider_error "Invalid provider key path: $key_file"
    return 3
  }
  key_directory="$provider_directory/keys"
  [[ -d $key_directory && ! -L $key_directory ]] || {
    lsi_provider_error 'Provider key directory is missing or unsafe.'
    return 3
  }
  key_path="$provider_directory/$key_file"
  [[ -f $key_path && ! -L $key_path && -s $key_path ]] || {
    lsi_provider_error "Provider key is missing, empty or unsafe: $key_file"
    return 3
  }

  if [[ $key_file == *.asc ]]; then
    while IFS= read -r line || [[ -n $line ]]; do
      [[ -n $first_line ]] || first_line=$line
      last_line=$line
    done < "$key_path"
    [[ $first_line == '-----BEGIN PGP PUBLIC KEY BLOCK-----' && $last_line == '-----END PGP PUBLIC KEY BLOCK-----' ]] || {
      lsi_provider_error "Provider key is not an ASCII-armored public key: $key_file"
      return 3
    }
  fi

  lsi_provider_bind_key_fingerprints "$key_path" "$key_fingerprints" || return
}

lsi_provider_read_manifest() {
  local provider_id=$1 provider_directory=$2 path line
  local line_number=0 row_count=0
  local parsed_id display_name publisher homepage backend status default_persistence
  local license_mode license_url license_revision auth_mode auth_url dependencies description
  path="$provider_directory/provider.tsv"
  [[ -f $path && ! -L $path ]] || {
    lsi_provider_error "Provider manifest is missing or unsafe: $path"
    return 3
  }
  lsi_provider_validate_text_file_bytes "$path" \
    'The provider manifest' 1048576 || return

  # shellcheck disable=SC2094 # path is passed to validation only as an error label.
  while IFS= read -r line || [[ -n $line ]]; do
    line_number=$((line_number + 1))
    if ((line_number == 1)); then
      [[ $line == "$LSI_PROVIDER_MANIFEST_HEADER" ]] || {
        lsi_provider_error "$path has an unknown, reordered or incomplete header."
        return 3
      }
      continue
    fi
    lsi_provider_validate_tsv_row "$path" "$line_number" "$line" 14 || return
    row_count=$((row_count + 1))
    ((row_count == 1)) || {
      lsi_provider_error "$path must contain exactly one provider row."
      return 3
    }
    IFS=$'\t' read -r parsed_id display_name publisher homepage backend status default_persistence license_mode license_url license_revision auth_mode auth_url dependencies description <<< "$line"

    [[ $parsed_id == "$provider_id" ]] || {
      lsi_provider_error "Provider ID $parsed_id does not match directory $provider_id."
      return 3
    }
    lsi_provider_valid_slug "$parsed_id" || {
      lsi_provider_error "Invalid provider ID in $path: $parsed_id"
      return 3
    }
    if ! lsi_provider_valid_safe_text "$display_name" ||
      ! lsi_provider_valid_safe_text "$publisher" ||
      ! lsi_provider_valid_safe_text "$description"; then
      lsi_provider_error "$path contains invalid display metadata."
      return 3
    fi
    lsi_provider_valid_https_url "$homepage" || {
      lsi_provider_error "$path contains a non-HTTPS or unsafe homepage."
      return 3
    }
    [[ $backend == repository && $status =~ ^(preview|stable|disabled)$ && $default_persistence =~ ^(disabled|enabled)$ ]] || {
      lsi_provider_error "$path contains an unsupported backend, status or persistence value."
      return 3
    }
    [[ $license_mode =~ ^(none|notice|explicit-ack|external-handoff)$ ]] || {
      lsi_provider_error "$path contains an unsupported license mode."
      return 3
    }
    if [[ $license_mode == none ]]; then
      [[ $license_url == '-' && $license_revision == '-' ]] || {
        lsi_provider_error "$path must use '-' for an absent license URL and revision."
        return 3
      }
    else
      if ! lsi_provider_valid_https_url "$license_url" || [[ ! $license_revision =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
        lsi_provider_error "$path contains an unsafe or unversioned license reference."
        return 3
      fi
    fi
    [[ $auth_mode =~ ^(none|credential-file|external-handoff)$ ]] || {
      lsi_provider_error "$path contains an unsupported authentication mode."
      return 3
    }
    if [[ $auth_mode == none ]]; then
      [[ $auth_url == '-' ]] || {
        lsi_provider_error "$path must use '-' for an absent authentication URL."
        return 3
      }
    else
      lsi_provider_valid_https_url "$auth_url" || {
        lsi_provider_error "$path contains a non-HTTPS authentication handoff."
        return 3
      }
    fi
    lsi_provider_valid_dependencies "$dependencies" "$parsed_id" || {
      lsi_provider_error "$path contains an invalid, duplicate or self-referencing dependency."
      return 3
    }

    LSI_PROVIDER_ID=$parsed_id
    LSI_PROVIDER_DISPLAY_NAME=$display_name
    LSI_PROVIDER_PUBLISHER=$publisher
    LSI_PROVIDER_HOMEPAGE=$homepage
    LSI_PROVIDER_BACKEND=$backend
    LSI_PROVIDER_STATUS=$status
    LSI_PROVIDER_DEFAULT_PERSISTENCE=$default_persistence
    LSI_PROVIDER_LICENSE_MODE=$license_mode
    LSI_PROVIDER_LICENSE_URL=$license_url
    LSI_PROVIDER_LICENSE_REVISION=$license_revision
    LSI_PROVIDER_AUTH_MODE=$auth_mode
    LSI_PROVIDER_AUTH_URL=$auth_url
    LSI_PROVIDER_DEPENDENCIES=$dependencies
    LSI_PROVIDER_DESCRIPTION=$description
  done < "$path"

  [[ $line_number -gt 0 && $row_count -eq 1 ]] || {
    lsi_provider_error "$path is empty or has no provider row."
    return 3
  }
}

lsi_provider_read_cells() {
  local provider_directory=$1 path line target_key
  local line_number=0 row_count=0
  local cell_id os_id version_id arch manager channel repository_uri suite components
  local key_file key_fingerprints expected_origin metadata_signature
  local -A seen_targets=()
  path="$provider_directory/cells.tsv"
  [[ -f $path && ! -L $path ]] || {
    lsi_provider_error "Provider cells file is missing or unsafe: $path"
    return 3
  }
  lsi_provider_validate_text_file_bytes "$path" \
    'The provider cells file' 1048576 || return

  # shellcheck disable=SC2094 # path is passed to validation only as an error label.
  while IFS= read -r line || [[ -n $line ]]; do
    line_number=$((line_number + 1))
    if ((line_number == 1)); then
      [[ $line == "$LSI_PROVIDER_CELLS_HEADER" ]] || {
        lsi_provider_error "$path has an unknown, reordered or incomplete header."
        return 3
      }
      continue
    fi
    lsi_provider_validate_tsv_row "$path" "$line_number" "$line" 13 || return
    IFS=$'\t' read -r cell_id os_id version_id arch manager channel repository_uri suite components key_file key_fingerprints expected_origin metadata_signature <<< "$line"
    row_count=$((row_count + 1))
    ((row_count <= 128)) || {
      lsi_provider_error "$path exceeds the 128-cell admission limit."
      return 3
    }

    if ! lsi_provider_valid_slug "$cell_id" || ! lsi_provider_valid_slug "$os_id" ||
      ! lsi_provider_valid_version "$version_id" || ! lsi_provider_valid_arch "$arch"; then
      lsi_provider_error "$path:$line_number contains an invalid or non-exact target cell."
      return 3
    fi
    [[ -z ${LSI_PROVIDER_CELL_BY_ID[$cell_id]+x} ]] || {
      lsi_provider_error "$path contains duplicate cell ID: $cell_id"
      return 3
    }
    [[ $manager == apt-get || $manager == dnf ]] || {
      lsi_provider_error "$path:$line_number contains an unsupported package manager."
      return 3
    }
    target_key="$os_id/$version_id/$arch/$manager"
    [[ -z ${seen_targets[$target_key]+x} ]] || {
      lsi_provider_error "$path contains duplicate exact target tuple: $target_key"
      return 3
    }
    seen_targets["$target_key"]=1
    if ! lsi_provider_valid_slug "$channel" || ! lsi_provider_valid_https_url "$repository_uri"; then
      lsi_provider_error "$path:$line_number contains an unsafe channel or non-HTTPS repository."
      return 3
    fi
    if [[ $manager == apt-get ]]; then
      if ! lsi_provider_valid_apt_coordinates "$repository_uri" "$suite" "$components" ||
        [[ $metadata_signature != apt-release ]]; then
        lsi_provider_error "$path:$line_number has an invalid APT suite, component or signature policy."
        return 3
      fi
    else
      [[ $suite == '-' && $components == '-' && $metadata_signature == rpm-repodata-and-package ]] || {
        lsi_provider_error "$path:$line_number has an invalid DNF repository or signature policy."
        return 3
      }
    fi
    lsi_provider_valid_fingerprints "$key_fingerprints" || {
      lsi_provider_error "$path:$line_number must declare unique full OpenPGP fingerprints."
      return 3
    }
    lsi_provider_validate_key_file "$provider_directory" "$key_file" "$key_fingerprints" || return
    if ! lsi_provider_valid_safe_text "$expected_origin" || [[ $expected_origin == '-' ]]; then
      lsi_provider_error "$path:$line_number must declare the expected package origin."
      return 3
    fi

    LSI_PROVIDER_CELL_ROWS+=("$line")
    LSI_PROVIDER_CELL_BY_ID["$cell_id"]=$line
    LSI_PROVIDER_CELL_ARCH["$cell_id"]=$arch
    LSI_PROVIDER_CELL_LOCK_COUNT["$cell_id"]=0
  done < "$path"

  [[ $line_number -gt 0 && $row_count -gt 0 ]] || {
    lsi_provider_error "$path is empty or has no target cells."
    return 3
  }
}

lsi_provider_read_locks() {
  local provider_directory=$1 path line lock_key expected_arch cell_id
  local line_number=0 row_count=0
  local module_id package version arch sha256 verify_binary
  local -A seen_locks=()
  path="$provider_directory/locks.tsv"
  [[ -f $path && ! -L $path ]] || {
    lsi_provider_error "Provider lock file is missing or unsafe: $path"
    return 3
  }
  lsi_provider_validate_text_file_bytes "$path" \
    'The provider lock file' 1048576 || return

  # shellcheck disable=SC2094 # path is passed to validation only as an error label.
  while IFS= read -r line || [[ -n $line ]]; do
    line_number=$((line_number + 1))
    if ((line_number == 1)); then
      [[ $line == "$LSI_PROVIDER_LOCKS_HEADER" ]] || {
        lsi_provider_error "$path has an unknown, reordered or incomplete header."
        return 3
      }
      continue
    fi
    lsi_provider_validate_tsv_row "$path" "$line_number" "$line" 7 || return
    IFS=$'\t' read -r module_id cell_id package version arch sha256 verify_binary <<< "$line"
    row_count=$((row_count + 1))
    ((row_count <= 4096)) || {
      lsi_provider_error "$path exceeds the 4096-lock admission limit."
      return 3
    }

    if ! lsi_provider_valid_slug "$module_id" || ! lsi_provider_valid_slug "$cell_id" ||
      [[ ! $package =~ ^[A-Za-z0-9][A-Za-z0-9+._:@-]*$ ]]; then
      lsi_provider_error "$path:$line_number contains an invalid module, cell or package token."
      return 3
    fi
    [[ -n ${LSI_PROVIDER_CELL_BY_ID[$cell_id]+x} ]] || {
      lsi_provider_error "$path:$line_number references unknown cell: $cell_id"
      return 3
    }
    [[ $version =~ ^[A-Za-z0-9][A-Za-z0-9.+:~_-]*$ && ${version,,} != latest && ${version,,} != stable ]] || {
      lsi_provider_error "$path:$line_number does not pin an exact package version."
      return 3
    }
    expected_arch=${LSI_PROVIDER_CELL_ARCH[$cell_id]}
    [[ $arch == "$expected_arch" || $arch == all ]] || {
      lsi_provider_error "$path:$line_number package architecture does not match cell $cell_id."
      return 3
    }
    [[ $sha256 =~ ^[A-Fa-f0-9]{64}$ ]] || {
      lsi_provider_error "$path:$line_number must pin a full SHA-256 digest."
      return 3
    }
    [[ $verify_binary =~ ^[A-Za-z0-9][A-Za-z0-9+._-]*$ ]] || {
      lsi_provider_error "$path:$line_number contains an invalid verification binary."
      return 3
    }
    lock_key="$cell_id/$module_id/$package"
    [[ -z ${seen_locks[$lock_key]+x} ]] || {
      lsi_provider_error "$path contains duplicate package lock: $lock_key"
      return 3
    }
    seen_locks["$lock_key"]=1
    LSI_PROVIDER_LOCK_ROWS+=("$line")
    LSI_PROVIDER_CELL_LOCK_COUNT["$cell_id"]=$((LSI_PROVIDER_CELL_LOCK_COUNT[$cell_id] + 1))
  done < "$path"

  [[ $line_number -gt 0 && $row_count -gt 0 ]] || {
    lsi_provider_error "$path is empty or has no package locks."
    return 3
  }
  for cell_id in "${!LSI_PROVIDER_CELL_BY_ID[@]}"; do
    ((LSI_PROVIDER_CELL_LOCK_COUNT[$cell_id] > 0)) || {
      lsi_provider_error "$path has no package lock for cell: $cell_id"
      return 3
    }
  done
}

lsi_provider_load() {
  local provider_id=$1 provider_directory before_digest after_digest
  lsi_provider_reset
  lsi_provider_registry_lookup "$provider_id" || return
  provider_directory=$(lsi_provider_directory_for_id "$provider_id") || return
  before_digest=$(lsi_provider_tree_digest "$provider_directory") || return
  [[ $before_digest == "$LSI_PROVIDER_CATALOG_SHA256" ]] || {
    lsi_provider_error "Registered provider tree digest is mismatched: $provider_id"
    return 3
  }
  lsi_provider_read_manifest "$provider_id" "$provider_directory" || return
  lsi_provider_read_cells "$provider_directory" || return
  lsi_provider_read_locks "$provider_directory" || return
  after_digest=$(lsi_provider_tree_digest "$provider_directory") || return
  [[ $after_digest == "$before_digest" ]] || {
    lsi_provider_error "Provider tree changed during validation: $provider_id"
    return 3
  }
}

lsi_provider_select_loaded_cell() {
  local os_id=$1 version_id=$2 arch=$3 requested_manager=${4:-}
  local row cell_id cell_os cell_version cell_arch manager _remainder
  for row in "${LSI_PROVIDER_CELL_ROWS[@]}"; do
    IFS=$'\t' read -r cell_id cell_os cell_version cell_arch manager _remainder <<< "$row"
    [[ $cell_os == "$os_id" && $cell_version == "$version_id" && $cell_arch == "$arch" ]] || continue
    [[ -z $requested_manager || $manager == "$requested_manager" ]] || continue
    printf '%s\n' "$row"
    return 0
  done
  lsi_provider_error "$LSI_PROVIDER_ID has no exact cell for $os_id $version_id $arch${requested_manager:+ ($requested_manager)}."
  return 4
}

lsi_provider_select_cell() {
  local provider_id=$1 os_id=$2 version_id=$3 arch=$4 requested_manager=${5:-}
  lsi_provider_load "$provider_id" || return
  lsi_provider_select_loaded_cell "$os_id" "$version_id" "$arch" "$requested_manager"
}

lsi_provider_package_arch() {
  local manager=$1 machine_arch=$2
  case "$manager/$machine_arch" in
    apt-get/x86_64) printf 'amd64\n' ;;
    apt-get/aarch64 | apt-get/arm64) printf 'arm64\n' ;;
    dnf/amd64) printf 'x86_64\n' ;;
    *) printf '%s\n' "$machine_arch" ;;
  esac
}

lsi_provider_cell_supported() {
  lsi_provider_select_cell "$@" > /dev/null
}

lsi_provider_list() (
  local LC_ALL=C
  local provider_id
  lsi_provider_registry_load || return

  printf '%-24s %-14s %-10s %-7s %s\n' 'PROVIDER' 'BACKEND' 'STATUS' 'CELLS' 'DESCRIPTION'
  printf '%-24s %-14s %-10s %-7s %s\n' '--------' '-------' '------' '-----' '-----------'
  if ((${#LSI_PROVIDER_REGISTRY_IDS[@]} == 0)); then
    printf '%s\n' '(no registered providers)'
    return 0
  fi

  for provider_id in "${LSI_PROVIDER_REGISTRY_IDS[@]}"; do
    lsi_provider_load "$provider_id" || return
    printf '%-24s %-14s %-10s %-7d %s\n' "$LSI_PROVIDER_ID" "$LSI_PROVIDER_BACKEND" "$LSI_PROVIDER_STATUS" "${#LSI_PROVIDER_CELL_ROWS[@]}" "$LSI_PROVIDER_DESCRIPTION"
  done
)

lsi_provider_info() {
  local provider_id=$1 row
  local cell_id os_id version_id arch manager channel repository_uri _suite _components key_file key_fingerprints expected_origin metadata_signature
  local module_id package version sha256 verify_binary
  lsi_provider_load "$provider_id" || return

  printf 'WARNING      : local catalog inspection only; no live repository or publisher verification\n'
  printf 'Provider     : %s\n' "$LSI_PROVIDER_ID"
  printf 'Revision     : %s\n' "$LSI_PROVIDER_CATALOG_REVISION"
  printf 'Registry SHA-256: %s\n' "$LSI_PROVIDER_REGISTRY_FILE_SHA256"
  printf 'Tree SHA-256 : %s\n' "$LSI_PROVIDER_CATALOG_SHA256"
  printf 'Name         : %s\n' "$LSI_PROVIDER_DISPLAY_NAME"
  printf 'Publisher    : %s\n' "$LSI_PROVIDER_PUBLISHER"
  printf 'Homepage     : %s\n' "$LSI_PROVIDER_HOMEPAGE"
  printf 'Backend      : %s\n' "$LSI_PROVIDER_BACKEND"
  printf 'Status       : %s\n' "$LSI_PROVIDER_STATUS"
  printf 'Persistence  : %s\n' "$LSI_PROVIDER_DEFAULT_PERSISTENCE"
  printf 'License      : %s' "$LSI_PROVIDER_LICENSE_MODE"
  [[ $LSI_PROVIDER_LICENSE_URL == '-' ]] || printf ' (%s, revision %s)' "$LSI_PROVIDER_LICENSE_URL" "$LSI_PROVIDER_LICENSE_REVISION"
  printf '\n'
  printf 'Authentication: %s' "$LSI_PROVIDER_AUTH_MODE"
  [[ $LSI_PROVIDER_AUTH_URL == '-' ]] || printf ' (%s)' "$LSI_PROVIDER_AUTH_URL"
  printf '\n'
  printf 'Dependencies : %s\n' "$LSI_PROVIDER_DEPENDENCIES"
  printf 'Local key check: declared primary fingerprints match provider-local OpenPGP keys\n'
  printf 'Live verification: not performed; repository metadata, packages, origin and publisher are unauthenticated\n'
  printf 'Description  : %s\n' "$LSI_PROVIDER_DESCRIPTION"
  printf 'Target cells :\n'
  for row in "${LSI_PROVIDER_CELL_ROWS[@]}"; do
    IFS=$'\t' read -r cell_id os_id version_id arch manager channel repository_uri _suite _components key_file key_fingerprints expected_origin metadata_signature <<< "$row"
    printf '  - %s: %s %s %s; %s; channel %s\n' "$cell_id" "$os_id" "$version_id" "$arch" "$manager" "$channel"
    printf '    repository: %s\n' "$repository_uri"
    printf '    key: %s; fingerprints: %s\n' "$key_file" "$key_fingerprints"
    printf '    expected origin: %s; signature: %s\n' "$expected_origin" "$metadata_signature"
  done
  printf 'Package locks:\n'
  for row in "${LSI_PROVIDER_LOCK_ROWS[@]}"; do
    IFS=$'\t' read -r module_id cell_id package version arch sha256 verify_binary <<< "$row"
    printf '  - %s/%s: %s=%s (%s); sha256 %s; verify %s\n' "$cell_id" "$module_id" "$package" "$version" "$arch" "$sha256" "$verify_binary"
  done
}

lsi_provider_plan_reset() {
  LSI_PROVIDER_PLAN_ALLOWED=()
  LSI_PROVIDER_PLAN_PREVIEW=()
  LSI_PROVIDER_PLAN_LICENSE=()
  LSI_PROVIDER_PLAN_AUTH=()
  LSI_PROVIDER_PLAN_PERSIST=()
  LSI_PROVIDER_PLAN_VISITING=()
  LSI_PROVIDER_PLAN_VALIDATED=()
  LSI_PROVIDER_PLAN_ORDER=()
  LSI_PROVIDER_PLAN_MODULES=()
  LSI_PROVIDER_PLAN_ACTIVATION=()
  LSI_PROVIDER_PLAN_STATUS=()
  LSI_PROVIDER_PLAN_LICENSE_MODE=()
  LSI_PROVIDER_PLAN_LICENSE_URL=()
  LSI_PROVIDER_PLAN_LICENSE_REVISION=()
  LSI_PROVIDER_PLAN_AUTH_MODE=()
  LSI_PROVIDER_PLAN_AUTH_URL=()
  LSI_PROVIDER_PLAN_CATALOG_REVISION=()
  LSI_PROVIDER_PLAN_CATALOG_SHA256=()
  LSI_PROVIDER_PLAN_PRIMARY_LOCK_ROWS=()
  LSI_PROVIDER_PLAN_PRIMARY=''
  LSI_PROVIDER_PLAN_REGISTRY_SHA256=''
  LSI_PROVIDER_PLAN_BODY=''
  LSI_PROVIDER_PLAN_DIGEST=''
}

lsi_provider_plan_add_once() {
  local map_name=$1 provider_id=$2 value=$3 label=$4
  local -n destination=$map_name
  lsi_provider_valid_slug "$provider_id" || {
    lsi_provider_error "$label has an invalid provider ID: $provider_id"
    return 2
  }
  [[ -z ${destination[$provider_id]+x} ]] || {
    lsi_provider_error "$label was supplied more than once for $provider_id."
    return 2
  }
  destination["$provider_id"]=$value
}

lsi_provider_plan_add_module() {
  local module_id=$1 existing
  lsi_provider_valid_slug "$module_id" || {
    lsi_provider_error "Invalid provider module ID: $module_id"
    return 2
  }
  for existing in "${LSI_PROVIDER_PLAN_MODULES[@]}"; do
    [[ $existing != "$module_id" ]] || {
      lsi_provider_error "Provider module was selected more than once: $module_id"
      return 2
    }
  done
  LSI_PROVIDER_PLAN_MODULES+=("$module_id")
}

lsi_provider_plan_parse_options() {
  local token provider_id revision
  lsi_provider_plan_reset
  while (($# > 0)); do
    case "$1" in
      --allow-provider | --allow-preview-provider | --accept-provider-license | --ack-provider-auth | --persist-provider)
        (($# >= 2)) || {
          lsi_provider_error "$1 requires a value."
          return 2
        }
        token=$2
        case "$1" in
          --allow-provider)
            [[ $token =~ ^([a-z0-9][a-z0-9-]*)@([A-Za-z0-9][A-Za-z0-9._-]*)$ ]] || {
              lsi_provider_error '--allow-provider requires PROVIDER@CATALOG_REVISION.'
              return 2
            }
            provider_id=${BASH_REMATCH[1]}
            revision=${BASH_REMATCH[2]}
            lsi_provider_plan_add_once LSI_PROVIDER_PLAN_ALLOWED "$provider_id" "$revision" "$1" || return
            ;;
          --allow-preview-provider)
            lsi_provider_plan_add_once LSI_PROVIDER_PLAN_PREVIEW "$token" yes "$1" || return
            ;;
          --accept-provider-license)
            [[ $token =~ ^([a-z0-9][a-z0-9-]*)@([A-Za-z0-9][A-Za-z0-9._-]*)$ ]] || {
              lsi_provider_error '--accept-provider-license requires PROVIDER@REVISION.'
              return 2
            }
            provider_id=${BASH_REMATCH[1]}
            revision=${BASH_REMATCH[2]}
            lsi_provider_plan_add_once LSI_PROVIDER_PLAN_LICENSE "$provider_id" "$revision" "$1" || return
            ;;
          --ack-provider-auth)
            lsi_provider_plan_add_once LSI_PROVIDER_PLAN_AUTH "$token" yes "$1" || return
            ;;
          --persist-provider)
            lsi_provider_plan_add_once LSI_PROVIDER_PLAN_PERSIST "$token" yes "$1" || return
            ;;
        esac
        shift 2
        ;;
      --)
        shift
        while (($# > 0)); do
          lsi_provider_plan_add_module "$1" || return
          shift
        done
        ;;
      -*)
        lsi_provider_error "Unknown provider-plan option: $1"
        return 2
        ;;
      *)
        lsi_provider_plan_add_module "$1" || return
        shift
        ;;
    esac
  done
  ((${#LSI_PROVIDER_PLAN_MODULES[@]} > 0)) || {
    lsi_provider_error 'provider-plan requires at least one provider module ID.'
    return 2
  }
}

lsi_provider_plan_validate_policy() {
  local provider_id=$1
  [[ ${LSI_PROVIDER_PLAN_ALLOWED[$provider_id]:-} == "$LSI_PROVIDER_CATALOG_REVISION" ]] || {
    lsi_provider_error "Provider $provider_id requires --allow-provider $provider_id@$LSI_PROVIDER_CATALOG_REVISION."
    return 5
  }

  case "$LSI_PROVIDER_STATUS" in
    disabled)
      lsi_provider_error "Provider $provider_id is disabled and cannot be planned."
      return 5
      ;;
    preview)
      [[ -n ${LSI_PROVIDER_PLAN_PREVIEW[$provider_id]+x} ]] || {
        lsi_provider_error "Preview provider $provider_id requires --allow-preview-provider $provider_id."
        return 5
      }
      ;;
    stable)
      [[ -z ${LSI_PROVIDER_PLAN_PREVIEW[$provider_id]+x} ]] || {
        lsi_provider_error "$provider_id is stable; a preview-provider acknowledgement is invalid."
        return 2
      }
      ;;
  esac

  case "$LSI_PROVIDER_LICENSE_MODE" in
    explicit-ack)
      [[ ${LSI_PROVIDER_PLAN_LICENSE[$provider_id]:-} == "$LSI_PROVIDER_LICENSE_REVISION" ]] || {
        lsi_provider_error "Provider $provider_id requires --accept-provider-license $provider_id@$LSI_PROVIDER_LICENSE_REVISION."
        return 5
      }
      ;;
    external-handoff)
      lsi_provider_error "Provider $provider_id requires an external license handoff: $LSI_PROVIDER_LICENSE_URL"
      return 5
      ;;
    none | notice)
      [[ -z ${LSI_PROVIDER_PLAN_LICENSE[$provider_id]+x} ]] || {
        lsi_provider_error "$provider_id does not accept an explicit license revision acknowledgement."
        return 2
      }
      ;;
  esac

  case "$LSI_PROVIDER_AUTH_MODE" in
    credential-file)
      [[ -n ${LSI_PROVIDER_PLAN_AUTH[$provider_id]+x} ]] || {
        lsi_provider_error "Provider $provider_id requires --ack-provider-auth $provider_id."
        return 5
      }
      ;;
    external-handoff)
      lsi_provider_error "Provider $provider_id requires an external authentication handoff: $LSI_PROVIDER_AUTH_URL"
      return 5
      ;;
    none)
      [[ -z ${LSI_PROVIDER_PLAN_AUTH[$provider_id]+x} ]] || {
        lsi_provider_error "$provider_id does not use provider authentication."
        return 2
      }
      ;;
  esac

  if [[ $LSI_PROVIDER_DEFAULT_PERSISTENCE == enabled && -z ${LSI_PROVIDER_PLAN_PERSIST[$provider_id]+x} ]]; then
    lsi_provider_error "Provider $provider_id declares persistence and requires --persist-provider $provider_id."
    return 5
  fi
}

lsi_provider_plan_visit() {
  local provider_id=$1 os_id=$2 version_id=$3 arch=$4 manager=$5
  local dependencies dependency selected_row
  local -a dependency_ids=()

  [[ -z ${LSI_PROVIDER_PLAN_VALIDATED[$provider_id]+x} ]] || return 0
  [[ -z ${LSI_PROVIDER_PLAN_VISITING[$provider_id]+x} ]] || {
    lsi_provider_error "Provider dependency cycle detected at $provider_id."
    return 5
  }
  LSI_PROVIDER_PLAN_VISITING["$provider_id"]=1

  lsi_provider_load "$provider_id" || return
  if [[ -z $LSI_PROVIDER_PLAN_REGISTRY_SHA256 ]]; then
    LSI_PROVIDER_PLAN_REGISTRY_SHA256=$LSI_PROVIDER_REGISTRY_FILE_SHA256
  elif [[ $LSI_PROVIDER_REGISTRY_FILE_SHA256 != "$LSI_PROVIDER_PLAN_REGISTRY_SHA256" ]]; then
    lsi_provider_error 'The provider admission registry changed while resolving the plan.'
    return 3
  fi
  lsi_provider_plan_validate_policy "$provider_id" || return
  selected_row=$(lsi_provider_select_loaded_cell "$os_id" "$version_id" "$arch" "$manager") || return
  dependencies=$LSI_PROVIDER_DEPENDENCIES
  LSI_PROVIDER_PLAN_ACTIVATION["$provider_id"]=$selected_row
  LSI_PROVIDER_PLAN_STATUS["$provider_id"]=$LSI_PROVIDER_STATUS
  LSI_PROVIDER_PLAN_LICENSE_MODE["$provider_id"]=$LSI_PROVIDER_LICENSE_MODE
  LSI_PROVIDER_PLAN_LICENSE_URL["$provider_id"]=$LSI_PROVIDER_LICENSE_URL
  LSI_PROVIDER_PLAN_LICENSE_REVISION["$provider_id"]=$LSI_PROVIDER_LICENSE_REVISION
  LSI_PROVIDER_PLAN_AUTH_MODE["$provider_id"]=$LSI_PROVIDER_AUTH_MODE
  LSI_PROVIDER_PLAN_AUTH_URL["$provider_id"]=$LSI_PROVIDER_AUTH_URL
  LSI_PROVIDER_PLAN_CATALOG_REVISION["$provider_id"]=$LSI_PROVIDER_CATALOG_REVISION
  LSI_PROVIDER_PLAN_CATALOG_SHA256["$provider_id"]=$LSI_PROVIDER_CATALOG_SHA256
  if [[ $provider_id == "$LSI_PROVIDER_PLAN_PRIMARY" ]]; then
    LSI_PROVIDER_PLAN_PRIMARY_LOCK_ROWS=("${LSI_PROVIDER_LOCK_ROWS[@]}")
  fi
  if [[ $dependencies != '-' ]]; then
    IFS=',' read -r -a dependency_ids <<< "$dependencies"
    for dependency in "${dependency_ids[@]}"; do
      lsi_provider_plan_visit "$dependency" "$os_id" "$version_id" "$arch" "$manager" || return
    done
  fi

  unset 'LSI_PROVIDER_PLAN_VISITING[$provider_id]'
  LSI_PROVIDER_PLAN_VALIDATED["$provider_id"]=1
  LSI_PROVIDER_PLAN_ORDER+=("$provider_id")
}

lsi_provider_plan_reject_unused() {
  local map_name=$1 label=$2 provider_id
  local -n values=$map_name
  for provider_id in "${!values[@]}"; do
    [[ -n ${LSI_PROVIDER_PLAN_VALIDATED[$provider_id]+x} ]] || {
      lsi_provider_error "$label was supplied for unrelated provider $provider_id."
      return 2
    }
  done
}

lsi_provider_plan_print_activation() {
  local provider_id=$1
  local row cell_id cell_os cell_version cell_arch cell_manager channel repository_uri
  local suite components key_file key_fingerprints expected_origin metadata_signature
  local persistence=disabled

  row=${LSI_PROVIDER_PLAN_ACTIVATION[$provider_id]:-}
  [[ -n $row ]] || {
    lsi_provider_error "Provider plan snapshot is missing activation data: $provider_id"
    return 3
  }
  IFS=$'\t' read -r cell_id cell_os cell_version cell_arch cell_manager channel repository_uri \
    suite components key_file key_fingerprints expected_origin metadata_signature <<< "$row"
  [[ -z ${LSI_PROVIDER_PLAN_PERSIST[$provider_id]+x} ]] || persistence=enabled

  printf '  - %s (%s, %s)\n' "$provider_id" "${LSI_PROVIDER_PLAN_STATUS[$provider_id]}" "$cell_id"
  printf '    catalog revision/tree: %s / %s\n' \
    "${LSI_PROVIDER_PLAN_CATALOG_REVISION[$provider_id]}" \
    "${LSI_PROVIDER_PLAN_CATALOG_SHA256[$provider_id]}"
  printf '    target: %s %s %s via %s\n' "$cell_os" "$cell_version" "$cell_arch" "$cell_manager"
  printf '    repository: %s; channel: %s\n' "$repository_uri" "$channel"
  if [[ $cell_manager == apt-get && $suite == / ]]; then
    printf '    suite: /; components: none (flat repository)\n'
  else
    printf '    suite/components: %s / %s\n' "$suite" "$components"
  fi
  printf '    key: %s; primary fingerprints: %s\n' "$key_file" "$key_fingerprints"
  printf '    expected origin/signature: %s / %s\n' "$expected_origin" "$metadata_signature"
  printf '    license: %s' "${LSI_PROVIDER_PLAN_LICENSE_MODE[$provider_id]}"
  [[ ${LSI_PROVIDER_PLAN_LICENSE_URL[$provider_id]} == '-' ]] ||
    printf ' (%s, revision %s)' "${LSI_PROVIDER_PLAN_LICENSE_URL[$provider_id]}" \
      "${LSI_PROVIDER_PLAN_LICENSE_REVISION[$provider_id]}"
  printf '\n'
  printf '    authentication: %s' "${LSI_PROVIDER_PLAN_AUTH_MODE[$provider_id]}"
  [[ ${LSI_PROVIDER_PLAN_AUTH_URL[$provider_id]} == '-' ]] ||
    printf ' (%s)' "${LSI_PROVIDER_PLAN_AUTH_URL[$provider_id]}"
  printf '\n'
  printf '    persistence after transaction: %s\n' "$persistence"
}

lsi_provider_plan_print_packages() {
  local provider_id=$1 cell_id=$2 row module_id lock_cell package version arch sha256 verify_binary selected
  local -A requested=() seen=()

  for selected in "${LSI_PROVIDER_PLAN_MODULES[@]}"; do
    requested["$selected"]=1
  done
  printf 'Locked primary-provider packages:\n'
  for row in "${LSI_PROVIDER_PLAN_PRIMARY_LOCK_ROWS[@]}"; do
    IFS=$'\t' read -r module_id lock_cell package version arch sha256 verify_binary <<< "$row"
    [[ $lock_cell == "$cell_id" && -n ${requested[$module_id]+x} ]] || continue
    printf '  - %s: %s=%s (%s); sha256 %s; verify %s\n' \
      "$module_id" "$package" "$version" "$arch" "$sha256" "$verify_binary"
    seen["$module_id"]=1
  done
  for selected in "${LSI_PROVIDER_PLAN_MODULES[@]}"; do
    [[ -n ${seen[$selected]+x} ]] || {
      lsi_provider_error "$provider_id has no package lock for $selected in cell $cell_id."
      return 4
    }
  done
}

lsi_provider_plan_render() {
  local provider_id=$1 manager=$2 provider row cell_id _remainder

  printf 'WARNING: local, non-mutating validation only; no live repository, package or publisher verification is performed.\n'
  printf 'Provider transaction plan (non-mutating)\n'
  printf 'Host target    : %s %s %s (%s)\n' "$LSI_OS_ID" "$LSI_OS_VERSION_ID" "$LSI_ARCH" "$manager"
  printf 'Registry SHA-256: %s\n' "$LSI_PROVIDER_PLAN_REGISTRY_SHA256"
  printf 'Authorization  : explicit provider@catalog-revision acknowledgements; --yes is not accepted\n'
  printf 'Provider closure (dependencies first; dependency providers are repository prerequisites only):\n'
  for provider in "${LSI_PROVIDER_PLAN_ORDER[@]}"; do
    lsi_provider_plan_print_activation "$provider" || return
  done

  row=${LSI_PROVIDER_PLAN_ACTIVATION[$provider_id]:-}
  [[ -n $row ]] || {
    lsi_provider_error "Provider plan snapshot is missing primary activation data: $provider_id"
    return 3
  }
  IFS=$'\t' read -r cell_id _remainder <<< "$row"
  lsi_provider_plan_print_packages "$provider_id" "$cell_id" || return
  printf 'Dependency packages: none; dependency providers are repository prerequisites only.\n'
  printf 'Repository mutation: disabled; this command only validates and displays the exact transaction contract.\n'
}

lsi_provider_plan_prepare() {
  local provider_id=${1:-} manager package_arch sha256_bin
  (($# > 0)) && shift
  lsi_provider_valid_slug "$provider_id" || {
    lsi_provider_error 'provider-plan requires a valid provider ID.'
    return 2
  }
  declare -F lsi_detect_os > /dev/null 2>&1 || {
    lsi_provider_error 'OS detection is unavailable for provider-plan.'
    return 3
  }
  lsi_provider_plan_parse_options "$@" || return
  # Provider authorization never inherits the ordinary installer's legacy-OS
  # escape hatch or a caller-supplied package-manager override.
  LSI_FORCE_UNSUPPORTED=false
  LSI_PACKAGE_MANAGER=''
  lsi_detect_os
  lsi_validate_os_support
  manager=$LSI_PACKAGE_MANAGER
  package_arch=$(lsi_provider_package_arch "$manager" "$LSI_ARCH") || return

  LSI_PROVIDER_PLAN_PRIMARY=$provider_id
  lsi_provider_plan_visit "$provider_id" "$LSI_OS_ID" "$LSI_OS_VERSION_ID" "$package_arch" "$manager" || return
  lsi_provider_plan_reject_unused LSI_PROVIDER_PLAN_ALLOWED '--allow-provider' || return
  lsi_provider_plan_reject_unused LSI_PROVIDER_PLAN_PREVIEW '--allow-preview-provider' || return
  lsi_provider_plan_reject_unused LSI_PROVIDER_PLAN_LICENSE '--accept-provider-license' || return
  lsi_provider_plan_reject_unused LSI_PROVIDER_PLAN_AUTH '--ack-provider-auth' || return
  lsi_provider_plan_reject_unused LSI_PROVIDER_PLAN_PERSIST '--persist-provider' || return

  lsi_provider_registry_load || return
  [[ $LSI_PROVIDER_REGISTRY_FILE_SHA256 == "$LSI_PROVIDER_PLAN_REGISTRY_SHA256" ]] || {
    lsi_provider_error 'The provider admission registry changed before plan rendering.'
    return 3
  }

  LSI_PROVIDER_PLAN_BODY=$(lsi_provider_plan_render "$provider_id" "$manager") || return
  sha256_bin=$(lsi_provider_system_tool sha256sum) || return
  LSI_PROVIDER_PLAN_DIGEST=$(printf '%s\n' "$LSI_PROVIDER_PLAN_BODY" | "$sha256_bin") || {
    lsi_provider_error 'Unable to hash the provider plan snapshot.'
    return 3
  }
  LSI_PROVIDER_PLAN_DIGEST=${LSI_PROVIDER_PLAN_DIGEST%% *}
  [[ $LSI_PROVIDER_PLAN_DIGEST =~ ^[0-9a-f]{64}$ ]] || {
    lsi_provider_error 'Provider plan snapshot produced an invalid SHA-256 digest.'
    return 3
  }
}

lsi_provider_plan_current() {
  lsi_provider_plan_prepare "$@" || return
  printf '%s\n' "$LSI_PROVIDER_PLAN_BODY"
  printf 'Plan SHA-256 (body): %s\n' "$LSI_PROVIDER_PLAN_DIGEST"
}

lsi_provider_config_render_provider() {
  local provider_id=$1 row cell_id cell_os cell_version cell_arch cell_manager channel
  local repository_uri suite components key_file key_fingerprints expected_origin metadata_signature
  local component
  local -a provider_components=()

  row=${LSI_PROVIDER_PLAN_ACTIVATION[$provider_id]:-}
  [[ -n $row ]] || {
    lsi_provider_error "Provider configuration snapshot is missing activation data: $provider_id"
    return 3
  }
  IFS=$'\t' read -r cell_id cell_os cell_version cell_arch cell_manager channel repository_uri \
    suite components key_file key_fingerprints expected_origin metadata_signature <<< "$row"

  printf '\n# Provider: %s; catalog revision: %s\n' "$provider_id" \
    "${LSI_PROVIDER_PLAN_CATALOG_REVISION[$provider_id]}"
  printf '# Checked-in key: providers/%s/%s\n' "$provider_id" "$key_file"
  case "$cell_manager" in
    apt-get)
      printf '# Target keyring: /usr/share/keyrings/linux-software-installer-%s.asc\n' "$provider_id"
      printf '# Target source: /etc/apt/sources.list.d/linux-software-installer-%s.sources\n' "$provider_id"
      printf 'Types: deb\nURIs: %s\nSuites: %s\n' "$repository_uri" "$suite"
      if [[ $suite != / ]]; then
        printf 'Components:'
        IFS=',' read -r -a provider_components <<< "$components"
        for component in "${provider_components[@]}"; do
          printf ' %s' "$component"
        done
        printf '\n'
      fi
      printf 'Architectures: %s\nSigned-By: /usr/share/keyrings/linux-software-installer-%s.asc\n' \
        "$cell_arch" "$provider_id"
      ;;
    dnf)
      printf '# Target keyring: /etc/pki/rpm-gpg/RPM-GPG-KEY-linux-software-installer-%s\n' "$provider_id"
      printf '# Target repository: /etc/yum.repos.d/linux-software-installer-%s.repo\n' "$provider_id"
      printf '[linux-software-installer-%s]\nname=%s\nbaseurl=%s\nenabled=1\n' \
        "$provider_id" "$provider_id" "$repository_uri"
      printf 'gpgcheck=1\nrepo_gpgcheck=1\ngpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-linux-software-installer-%s\n' \
        "$provider_id"
      ;;
    *)
      lsi_provider_error "Provider configuration uses an unsupported package manager: $cell_manager"
      return 3
      ;;
  esac
  printf '# Expected origin: %s; metadata signature policy: %s\n' \
    "$expected_origin" "$metadata_signature"
}

lsi_provider_config_current() {
  local provider_id=${1:-} provider
  (($# > 0)) && shift
  lsi_provider_plan_prepare "$provider_id" "$@" || return
  printf '%s\n' 'Provider repository configuration (read-only; no system changes are made).'
  printf 'Plan SHA-256 (body): %s\n' "$LSI_PROVIDER_PLAN_DIGEST"
  printf '%s\n' 'Do not enable a rendered configuration until a provider apply command and accepted evidence are available.'
  for provider in "${LSI_PROVIDER_PLAN_ORDER[@]}"; do
    lsi_provider_config_render_provider "$provider" || return
  done
}

lsi_provider_apply_parse_args() {
  local token
  LSI_PROVIDER_APPLY_EXPECTED_DIGEST=''
  LSI_PROVIDER_APPLY_ARGS=()
  while (($# > 0)); do
    case "$1" in
      --plan-sha256)
        (($# >= 2)) || {
          lsi_provider_error '--plan-sha256 requires the exact reviewed plan SHA-256.'
          return 2
        }
        token=$2
        [[ $token =~ ^[0-9a-f]{64}$ && -z $LSI_PROVIDER_APPLY_EXPECTED_DIGEST ]] || {
          lsi_provider_error '--plan-sha256 must be supplied exactly once as 64 lowercase hexadecimal characters.'
          return 2
        }
        LSI_PROVIDER_APPLY_EXPECTED_DIGEST=$token
        shift 2
        ;;
      *)
        LSI_PROVIDER_APPLY_ARGS+=("$1")
        shift
        ;;
    esac
  done
  [[ -n $LSI_PROVIDER_APPLY_EXPECTED_DIGEST ]] || {
    lsi_provider_error 'provider-apply requires --plan-sha256 from an immediately reviewed provider-plan.'
    return 2
  }
}

lsi_provider_apply_check_directory() {
  local directory=$1 stat_bin owner mode
  stat_bin=$(lsi_provider_system_tool stat) || return
  [[ -d $directory && ! -L $directory ]] || {
    lsi_provider_error "Provider activation directory is unavailable or unsafe: $directory"
    return 3
  }
  if [[ ${LSI_PROVIDER_APPLY_ALLOW_NONROOT_TEST:-false} == true ]]; then
    return 0
  fi
  owner=$("$stat_bin" -c '%u' -- "$directory") || return 3
  mode=$("$stat_bin" -c '%a' -- "$directory") || return 3
  [[ $owner == 0 && $mode =~ ^[0-7]{3,4}$ && $((8#${mode: -2:1})) -lt 2 && $((8#${mode: -1})) -lt 2 ]] || {
    lsi_provider_error "Provider activation directory has unsafe ownership or mode: $directory"
    return 3
  }
}

lsi_provider_apply_write_file() {
  local source=$1 target_path=$2 directory=$3 label=$4
  local stat_bin mktemp_bin chmod_bin cmp_bin mv_bin rm_bin tmp link_count

  lsi_provider_apply_check_file_destination "$source" "$target_path" "$directory" "$label" || return
  [[ ! -e $target_path && ! -L $target_path ]] || return 0

  stat_bin=$(lsi_provider_system_tool stat) || return
  chmod_bin=$(lsi_provider_system_tool chmod) || return
  cmp_bin=$(lsi_provider_system_tool cmp) || return
  mv_bin=$(lsi_provider_system_tool mv) || return
  rm_bin=$(lsi_provider_system_tool rm) || return
  mktemp_bin=$(lsi_provider_system_tool mktemp) || return
  tmp=$(
    umask 077
    "$mktemp_bin" "$directory/.linux-software-installer-provider.XXXXXX"
  ) || {
    lsi_provider_error "Unable to create provider activation temporary file in $directory"
    return 3
  }
  [[ -f $tmp && ! -L $tmp && ${tmp#"$directory"/} == .linux-software-installer-provider.* ]] || {
    lsi_provider_error 'Provider activation temporary file is unsafe.'
    return 3
  }
  if ! /bin/cat -- "$source" > "$tmp" || ! "$chmod_bin" 0644 -- "$tmp"; then
    "$rm_bin" -f -- "$tmp"
    lsi_provider_error "Unable to prepare provider activation file: $target_path"
    return 3
  fi
  if ! "$cmp_bin" -s -- "$source" "$tmp" || ! "$mv_bin" -n -- "$tmp" "$target_path"; then
    "$rm_bin" -f -- "$tmp"
    lsi_provider_error "Unable to install provider activation file safely: $target_path"
    return 3
  fi
  [[ -f $target_path && ! -L $target_path ]] || {
    "$rm_bin" -f -- "$tmp"
    lsi_provider_error "Provider activation output is unsafe: $target_path"
    return 3
  }
  link_count=$("$stat_bin" -c '%h' -- "$target_path") || return 3
  [[ $link_count == 1 ]] || {
    "$rm_bin" -f -- "$tmp"
    lsi_provider_error "Provider activation output has unsafe links: $target_path"
    return 3
  }
  if ! "$cmp_bin" -s -- "$source" "$target_path"; then
    "$rm_bin" -f -- "$tmp"
    lsi_provider_error "Provider activation output changed during installation: $target_path"
    return 3
  fi
  "$rm_bin" -f -- "$tmp"
}

lsi_provider_apply_check_file_destination() {
  local source=$1 target_path=$2 directory=$3 label=$4
  local stat_bin cmp_bin link_count

  [[ -f $source && ! -L $source ]] || {
    lsi_provider_error "Provider activation source is unavailable or unsafe: $label"
    return 3
  }
  lsi_provider_apply_check_directory "$directory" || return
  stat_bin=$(lsi_provider_system_tool stat) || return
  cmp_bin=$(lsi_provider_system_tool cmp) || return
  if [[ -e $target_path || -L $target_path ]]; then
    [[ -f $target_path && ! -L $target_path ]] || {
      lsi_provider_error "Refusing unsafe existing provider activation file: $target_path"
      return 3
    }
    link_count=$("$stat_bin" -c '%h' -- "$target_path") || return 3
    [[ $link_count == 1 ]] || {
      lsi_provider_error "Refusing multiply-linked provider activation file: $target_path"
      return 3
    }
    if "$cmp_bin" -s -- "$source" "$target_path"; then
      return 0
    fi
    lsi_provider_error "Refusing to replace provider activation drift: $target_path"
    return 3
  fi
}

lsi_provider_apply_config_file() {
  local provider_id=$1 root=$2 row cell_id _os_id _version_id _arch manager _channel
  local _repository_uri _suite _components key_file _key_fingerprints _expected_origin _metadata_signature
  local config_dir config_file key_dir key_target key_source temporary mktemp_bin rm_bin status=0

  row=${LSI_PROVIDER_PLAN_ACTIVATION[$provider_id]:-}
  [[ -n $row ]] || {
    lsi_provider_error "Provider apply snapshot is missing activation data: $provider_id"
    return 3
  }
  IFS=$'\t' read -r cell_id _os_id _version_id _arch manager _channel _repository_uri \
    _suite _components key_file _key_fingerprints _expected_origin _metadata_signature <<< "$row"
  key_source="$LSI_PROVIDER_ROOT/$provider_id/$key_file"
  case "$manager" in
    apt-get)
      key_dir="$root/usr/share/keyrings"
      config_dir="$root/etc/apt/sources.list.d"
      key_target="$key_dir/linux-software-installer-$provider_id.asc"
      config_file="$config_dir/linux-software-installer-$provider_id.sources"
      ;;
    dnf)
      key_dir="$root/etc/pki/rpm-gpg"
      config_dir="$root/etc/yum.repos.d"
      key_target="$key_dir/RPM-GPG-KEY-linux-software-installer-$provider_id"
      config_file="$config_dir/linux-software-installer-$provider_id.repo"
      ;;
    *)
      lsi_provider_error "Provider apply uses an unsupported package manager: $manager"
      return 3
      ;;
  esac
  mktemp_bin=$(lsi_provider_system_tool mktemp) || return
  rm_bin=$(lsi_provider_system_tool rm) || return
  temporary=$(
    umask 077
    "$mktemp_bin" '/tmp/lsi-provider-config.XXXXXX'
  ) || return 3
  if ! lsi_provider_config_render_provider "$provider_id" | /usr/bin/sed '/^#/d; /^$/d' > "$temporary"; then
    "$rm_bin" -f -- "$temporary"
    return 3
  fi
  lsi_provider_apply_check_file_destination "$key_source" "$key_target" "$key_dir" "key for $provider_id" || status=$?
  if ((status == 0)); then
    lsi_provider_apply_check_file_destination "$temporary" "$config_file" "$config_dir" \
      "repository configuration for $provider_id" || status=$?
  fi
  if ((status == 0)); then
    lsi_provider_apply_write_file "$key_source" "$key_target" "$key_dir" "key for $provider_id" || status=$?
  fi
  if ((status == 0)); then
    lsi_provider_apply_write_file "$temporary" "$config_file" "$config_dir" \
      "repository configuration for $provider_id" || status=$?
  fi
  "$rm_bin" -f -- "$temporary"
  return "$status"
}

lsi_provider_deactivate_remove_file() {
  local source=$1 target_path=$2 directory=$3 label=$4 rm_bin
  lsi_provider_apply_check_file_destination "$source" "$target_path" "$directory" "$label" || return
  [[ -e $target_path || -L $target_path ]] || return 0
  rm_bin=$(lsi_provider_system_tool rm) || return
  "$rm_bin" -f -- "$target_path" || {
    lsi_provider_error "Unable to remove provider repository file: $target_path"
    return 3
  }
  [[ ! -e $target_path && ! -L $target_path ]] || {
    lsi_provider_error "Provider repository file remains after removal: $target_path"
    return 3
  }
}

lsi_provider_deactivate_config_file() {
  local provider_id=$1 root=$2 row cell_id _os_id _version_id _arch manager _channel
  local _repository_uri _suite _components key_file _key_fingerprints _expected_origin _metadata_signature
  local config_dir config_file key_dir key_target key_source temporary mktemp_bin rm_bin status=0

  row=${LSI_PROVIDER_PLAN_ACTIVATION[$provider_id]:-}
  [[ -n $row ]] || {
    lsi_provider_error "Provider deactivation snapshot is missing activation data: $provider_id"
    return 3
  }
  IFS=$'\t' read -r cell_id _os_id _version_id _arch manager _channel _repository_uri \
    _suite _components key_file _key_fingerprints _expected_origin _metadata_signature <<< "$row"
  key_source="$LSI_PROVIDER_ROOT/$provider_id/$key_file"
  case "$manager" in
    apt-get)
      key_dir="$root/usr/share/keyrings"
      config_dir="$root/etc/apt/sources.list.d"
      key_target="$key_dir/linux-software-installer-$provider_id.asc"
      config_file="$config_dir/linux-software-installer-$provider_id.sources"
      ;;
    dnf)
      key_dir="$root/etc/pki/rpm-gpg"
      config_dir="$root/etc/yum.repos.d"
      key_target="$key_dir/RPM-GPG-KEY-linux-software-installer-$provider_id"
      config_file="$config_dir/linux-software-installer-$provider_id.repo"
      ;;
    *)
      lsi_provider_error "Provider deactivation uses an unsupported package manager: $manager"
      return 3
      ;;
  esac
  mktemp_bin=$(lsi_provider_system_tool mktemp) || return
  rm_bin=$(lsi_provider_system_tool rm) || return
  temporary=$(
    umask 077
    "$mktemp_bin" '/tmp/lsi-provider-config.XXXXXX'
  ) || return 3
  if ! lsi_provider_config_render_provider "$provider_id" | /usr/bin/sed '/^#/d; /^$/d' > "$temporary"; then
    "$rm_bin" -f -- "$temporary"
    return 3
  fi
  # Validate both destinations before deleting either. A drifted source file
  # remains untouched, and a configuration is removed before its key so a
  # partial failure cannot leave the repository enabled without its key.
  lsi_provider_apply_check_file_destination "$temporary" "$config_file" "$config_dir" \
    "repository configuration for $provider_id" || status=$?
  if ((status == 0)); then
    lsi_provider_apply_check_file_destination "$key_source" "$key_target" "$key_dir" \
      "key for $provider_id" || status=$?
  fi
  if ((status == 0)); then
    lsi_provider_deactivate_remove_file "$temporary" "$config_file" "$config_dir" \
      "repository configuration for $provider_id" || status=$?
  fi
  if ((status == 0)); then
    lsi_provider_deactivate_remove_file "$key_source" "$key_target" "$key_dir" \
      "key for $provider_id" || status=$?
  fi
  "$rm_bin" -f -- "$temporary"
  return "$status"
}

lsi_provider_apply_current() {
  local provider_id=${1:-} root=${LSI_PROVIDER_APPLY_ROOT:-/} provider
  (($# > 0)) && shift
  lsi_provider_valid_slug "$provider_id" || {
    lsi_provider_error 'provider-apply requires a valid provider ID.'
    return 2
  }
  lsi_provider_apply_parse_args "$@" || return
  lsi_provider_plan_prepare "$provider_id" "${LSI_PROVIDER_APPLY_ARGS[@]}" || return
  [[ $LSI_PROVIDER_PLAN_DIGEST == "$LSI_PROVIDER_APPLY_EXPECTED_DIGEST" ]] || {
    lsi_provider_error 'Reviewed provider plan SHA-256 does not match the current exact plan; refusing activation.'
    return 5
  }
  [[ $root == /* && -d $root && ! -L $root ]] || {
    lsi_provider_error 'Provider activation root must be an existing absolute, non-symlink directory.'
    return 3
  }
  [[ ${LSI_PROVIDER_APPLY_ALLOW_NONROOT_TEST:-false} == true || $root == / ]] || {
    lsi_provider_error 'A non-system provider activation root is test-only.'
    return 3
  }
  [[ ${LSI_PROVIDER_APPLY_ALLOW_NONROOT_TEST:-false} == true ]] || lsi_require_root
  if [[ ${LSI_PROVIDER_APPLY_ALLOW_NONROOT_TEST:-false} == true ]]; then
    : # Test-only fake roots do not require the host's Linux flock facility.
  else
    lsi_acquire_lock
  fi
  for provider in "${LSI_PROVIDER_PLAN_ORDER[@]}"; do
    lsi_provider_apply_config_file "$provider" "$root" || return
  done
  printf 'Provider repository files activated from reviewed plan SHA-256: %s\n' "$LSI_PROVIDER_PLAN_DIGEST"
  printf '%s\n' \
    'No repository metadata refresh or package installation was performed; run provider-deactivate to remove these files.'
}

lsi_provider_deactivate_current() {
  local provider_id=${1:-} root=${LSI_PROVIDER_APPLY_ROOT:-/} provider index
  (($# > 0)) && shift
  lsi_provider_valid_slug "$provider_id" || {
    lsi_provider_error 'provider-deactivate requires a valid provider ID.'
    return 2
  }
  lsi_provider_apply_parse_args "$@" || return
  lsi_provider_plan_prepare "$provider_id" "${LSI_PROVIDER_APPLY_ARGS[@]}" || return
  [[ $LSI_PROVIDER_PLAN_DIGEST == "$LSI_PROVIDER_APPLY_EXPECTED_DIGEST" ]] || {
    lsi_provider_error 'Reviewed provider plan SHA-256 does not match the current exact plan; refusing deactivation.'
    return 5
  }
  [[ $root == /* && -d $root && ! -L $root ]] || {
    lsi_provider_error 'Provider deactivation root must be an existing absolute, non-symlink directory.'
    return 3
  }
  [[ ${LSI_PROVIDER_APPLY_ALLOW_NONROOT_TEST:-false} == true || $root == / ]] || {
    lsi_provider_error 'A non-system provider deactivation root is test-only.'
    return 3
  }
  [[ ${LSI_PROVIDER_APPLY_ALLOW_NONROOT_TEST:-false} == true ]] || lsi_require_root
  [[ ${LSI_PROVIDER_APPLY_ALLOW_NONROOT_TEST:-false} == true ]] || lsi_acquire_lock
  for ((index = ${#LSI_PROVIDER_PLAN_ORDER[@]} - 1; index >= 0; index--)); do
    provider=${LSI_PROVIDER_PLAN_ORDER[index]}
    lsi_provider_deactivate_config_file "$provider" "$root" || return
  done
  printf 'Provider repository files deactivated from reviewed plan SHA-256: %s\n' "$LSI_PROVIDER_PLAN_DIGEST"
  printf '%s\n' 'No repository metadata refresh, package removal or package installation was performed.'
}

lsi_provider_apt_install_locked_package() (
  local row=$1 package version arch expected_sha256 verify_binary expected_origin
  local apt_get apt_cache dpkg_deb sha256_bin stat_bin find_bin mktemp_bin rm_bin
  local cache_root archive_dir artifact candidate package_fields field_package field_version field_arch
  local observed_sha256 origin_line origin_found=false
  local -a candidates=()

  IFS=$'\t' read -r _module_id _cell_id package version arch expected_sha256 verify_binary <<< "$row"
  [[ -n $LSI_PROVIDER_PLAN_PRIMARY ]] || {
    lsi_provider_error 'Provider install has no primary provider snapshot.'
    return 3
  }
  IFS=$'\t' read -r _cell_id _os_id _version_id _cell_arch _manager _channel _repository_uri \
    _suite _components _key_file _key_fingerprints expected_origin _metadata_signature \
    <<< "${LSI_PROVIDER_PLAN_ACTIVATION[$LSI_PROVIDER_PLAN_PRIMARY]}"

  apt_get=$(lsi_provider_system_tool apt-get) || return
  apt_cache=$(lsi_provider_system_tool apt-cache) || return
  dpkg_deb=$(lsi_provider_system_tool dpkg-deb) || return
  sha256_bin=$(lsi_provider_system_tool sha256sum) || return
  stat_bin=$(lsi_provider_system_tool stat) || return
  find_bin=$(lsi_provider_system_tool find) || return
  mktemp_bin=$(lsi_provider_system_tool mktemp) || return
  rm_bin=$(lsi_provider_system_tool rm) || return
  verify_binary=$(lsi_provider_system_tool "$verify_binary") || return

  cache_root=$(
    umask 077
    "$mktemp_bin" -d '/tmp/lsi-provider-install.XXXXXX'
  ) || {
    lsi_provider_error 'Unable to create the isolated provider package cache.'
    return 3
  }
  trap '"$rm_bin" -rf -- "$cache_root"' EXIT HUP INT TERM
  [[ -d $cache_root && ! -L $cache_root && ${cache_root#/tmp/} == lsi-provider-install.* ]] || {
    lsi_provider_error 'The isolated provider package cache is unsafe.'
    return 3
  }
  if [[ ${LSI_PROVIDER_APPLY_ALLOW_NONROOT_TEST:-false} != true ]]; then
    [[ $("$stat_bin" -c '%u:%a' -- "$cache_root") == '0:700' ]] || {
      lsi_provider_error 'The isolated provider package cache has unsafe ownership or mode.'
      return 3
    }
  fi
  archive_dir="$cache_root/archives"
  /bin/mkdir -p -- "$archive_dir/partial" || return 3

  # These options are explicit rather than relying on APT defaults: a provider
  # transaction must never downgrade to insecure repository metadata or an
  # unauthenticated package merely because a host-wide setting says otherwise.
  "$apt_get" \
    -o Acquire::AllowInsecureRepositories=false \
    -o Acquire::AllowDowngradeToInsecureRepositories=false \
    -o APT::Get::AllowUnauthenticated=false \
    update || {
    lsi_provider_error "Signed metadata refresh failed for provider $LSI_PROVIDER_PLAN_PRIMARY."
    return 4
  }

  # APT exposes the Release ``Origin`` field from signed repository metadata
  # through its policy view. It is checked before downloading so a
  # same-version package from another configured source cannot satisfy the
  # provider's lock. Package stanzas themselves need not repeat this field.
  origin_line=$("$apt_cache" policy "$package" 2> /dev/null || true)
  while IFS= read -r candidate || [[ -n $candidate ]]; do
    [[ $candidate == *"release o=$expected_origin"* ]] && origin_found=true
  done <<< "$origin_line"
  [[ $origin_found == true ]] || {
    lsi_provider_error "Signed APT metadata does not declare the expected Release origin for $package=$version."
    return 4
  }

  "$apt_get" \
    -o Acquire::AllowInsecureRepositories=false \
    -o Acquire::AllowDowngradeToInsecureRepositories=false \
    -o APT::Get::AllowUnauthenticated=false \
    -o "Dir::Cache::archives=$archive_dir" \
    -o "Dir::Cache::archives/partial=$archive_dir/partial" \
    --download-only --yes --no-install-recommends install "$package=$version" || {
    lsi_provider_error "Locked package download failed for $package=$version."
    return 4
  }

  while IFS= read -r candidate || [[ -n $candidate ]]; do
    [[ -f $candidate && ! -L $candidate ]] || continue
    # shellcheck disable=SC2016 # dpkg-deb, not Bash, expands its format fields.
    package_fields=$("$dpkg_deb" --show --showformat '${Package}\t${Version}\t${Architecture}\n' -- "$candidate" 2> /dev/null) || continue
    IFS=$'\t' read -r field_package field_version field_arch <<< "$package_fields"
    [[ $field_package == "$package" && $field_version == "$version" && $field_arch == "$arch" ]] || continue
    candidates+=("$candidate")
  done < <("$find_bin" "$archive_dir" -maxdepth 1 -type f -name '*.deb' -print)
  ((${#candidates[@]} == 1)) || {
    lsi_provider_error "Locked package cache does not contain exactly one matching artifact for $package=$version."
    return 4
  }
  artifact=${candidates[0]}
  [[ $("$stat_bin" -c '%h' -- "$artifact") == 1 ]] || {
    lsi_provider_error 'Downloaded provider package has unsafe links.'
    return 3
  }
  if [[ ${LSI_PROVIDER_APPLY_ALLOW_NONROOT_TEST:-false} != true ]]; then
    [[ $("$stat_bin" -c '%u:%a' -- "$artifact") =~ ^0:[0-7]{3,4}$ ]] || {
      lsi_provider_error 'Downloaded provider package has unsafe ownership or mode.'
      return 3
    }
  fi
  observed_sha256=$("$sha256_bin" -- "$artifact") || return 3
  observed_sha256=${observed_sha256%% *}
  [[ $observed_sha256 == "$expected_sha256" ]] || {
    lsi_provider_error "Downloaded provider package digest does not match the reviewed lock for $package=$version."
    return 4
  }

  # Install the already verified local artifact. APT may resolve ordinary
  # distribution dependencies, but it cannot substitute the locked provider
  # package with an unreviewed repository result.
  "$apt_get" \
    -o Acquire::AllowInsecureRepositories=false \
    -o Acquire::AllowDowngradeToInsecureRepositories=false \
    -o APT::Get::AllowUnauthenticated=false \
    --yes --no-install-recommends install "$artifact" || {
    lsi_provider_error "Installation failed for verified provider package $package=$version."
    return 4
  }
  "$verify_binary" --version > /dev/null || {
    lsi_provider_error "Installed provider binary did not verify: ${verify_binary##*/}."
    return 4
  }
)

lsi_provider_dnf_install_locked_package() (
  local row=$1 package version arch expected_sha256 verify_binary expected_origin
  local dnf rpm sha256_bin stat_bin find_bin mktemp_bin rm_bin
  local cache_root archive_dir rpm_db artifact candidate package_fields field_package field_version field_arch
  local observed_sha256 requested_nevra key_source
  local -a candidates=()

  IFS=$'\t' read -r _module_id _cell_id package version arch expected_sha256 verify_binary <<< "$row"
  [[ -n $LSI_PROVIDER_PLAN_PRIMARY ]] || {
    lsi_provider_error 'Provider install has no primary provider snapshot.'
    return 3
  }

  dnf=$(lsi_provider_system_tool dnf) || return
  rpm=$(lsi_provider_system_tool rpm) || return
  sha256_bin=$(lsi_provider_system_tool sha256sum) || return
  stat_bin=$(lsi_provider_system_tool stat) || return
  find_bin=$(lsi_provider_system_tool find) || return
  mktemp_bin=$(lsi_provider_system_tool mktemp) || return
  rm_bin=$(lsi_provider_system_tool rm) || return
  verify_binary=$(lsi_provider_system_tool "$verify_binary") || return

  cache_root=$(
    umask 077
    "$mktemp_bin" -d '/tmp/lsi-provider-install.XXXXXX'
  ) || {
    lsi_provider_error 'Unable to create the isolated provider package cache.'
    return 3
  }
  trap '"$rm_bin" -rf -- "$cache_root"' EXIT HUP INT TERM
  [[ -d $cache_root && ! -L $cache_root && ${cache_root#/tmp/} == lsi-provider-install.* ]] || {
    lsi_provider_error 'The isolated provider package cache is unsafe.'
    return 3
  }
  if [[ ${LSI_PROVIDER_APPLY_ALLOW_NONROOT_TEST:-false} != true ]]; then
    [[ $("$stat_bin" -c '%u:%a' -- "$cache_root") == '0:700' ]] || {
      lsi_provider_error 'The isolated provider package cache has unsafe ownership or mode.'
      return 3
    }
  fi
  archive_dir="$cache_root/archives"
  rpm_db="$cache_root/rpmdb"
  /bin/mkdir -p -- "$archive_dir" "$rpm_db" || return 3

  # DNF must authenticate both repository metadata and packages.  The
  # transient cache makes the exact downloaded RPM set observable and avoids
  # trusting a host cache or a stale artifact from another transaction.
  requested_nevra="$package-$version.$arch"
  "$dnf" \
    --setopt=gpgcheck=1 \
    --setopt=repo_gpgcheck=1 \
    --setopt=localpkg_gpgcheck=1 \
    --setopt=install_weak_deps=False \
    --setopt=keepcache=False \
    --setopt="cachedir=$cache_root/cache" \
    --setopt="persistdir=$cache_root/persist" \
    --setopt="logdir=$cache_root/log" \
    --assumeyes --downloadonly --downloaddir="$archive_dir" install "$requested_nevra" || {
    lsi_provider_error "Signed DNF metadata refresh or locked package download failed for $requested_nevra."
    return 4
  }

  while IFS= read -r candidate || [[ -n $candidate ]]; do
    [[ -f $candidate && ! -L $candidate ]] || continue
    package_fields=$("$rpm" -qp --qf '%{NAME}\t%{VERSION}-%{RELEASE}\t%{ARCH}\n' -- "$candidate" 2> /dev/null) || continue
    IFS=$'\t' read -r field_package field_version field_arch <<< "$package_fields"
    [[ $field_package == "$package" && $field_version == "$version" && $field_arch == "$arch" ]] || continue
    candidates+=("$candidate")
  done < <("$find_bin" "$archive_dir" -maxdepth 1 -type f -name '*.rpm' -print)
  ((${#candidates[@]} == 1)) || {
    lsi_provider_error "Locked package cache does not contain exactly one matching artifact for $requested_nevra."
    return 4
  }
  artifact=${candidates[0]}
  [[ $("$stat_bin" -c '%h' -- "$artifact") == 1 ]] || {
    lsi_provider_error 'Downloaded provider package has unsafe links.'
    return 3
  }
  if [[ ${LSI_PROVIDER_APPLY_ALLOW_NONROOT_TEST:-false} != true ]]; then
    [[ $("$stat_bin" -c '%u:%a' -- "$artifact") =~ ^0:[0-7]{3,4}$ ]] || {
      lsi_provider_error 'Downloaded provider package has unsafe ownership or mode.'
      return 3
    }
  fi
  observed_sha256=$("$sha256_bin" -- "$artifact") || return 3
  observed_sha256=${observed_sha256%% *}
  [[ $observed_sha256 == "$expected_sha256" ]] || {
    lsi_provider_error "Downloaded provider package digest does not match the reviewed lock for $requested_nevra."
    return 4
  }

  # Verify the RPM signature against an isolated RPM database containing only
  # the provider's checked-in key.  This remains independent from any key the
  # host might already have imported.
  IFS=$'\t' read -r _cell_id _os_id _version_id _arch _manager _channel _repository_uri \
    _suite _components key_file _key_fingerprints expected_origin _metadata_signature \
    <<< "${LSI_PROVIDER_PLAN_ACTIVATION[$LSI_PROVIDER_PLAN_PRIMARY]}"
  key_source="$LSI_PROVIDER_ROOT/$LSI_PROVIDER_PLAN_PRIMARY/$key_file"
  "$rpm" --dbpath "$rpm_db" --initdb || {
    lsi_provider_error 'Unable to initialize the isolated RPM verification database.'
    return 3
  }
  "$rpm" --dbpath "$rpm_db" --import "$key_source" || {
    lsi_provider_error 'Unable to import the checked-in provider RPM key into the isolated verification database.'
    return 3
  }
  "$rpm" --dbpath "$rpm_db" --checksig --verbose -- "$artifact" > /dev/null || {
    lsi_provider_error "Downloaded provider package signature did not verify for $requested_nevra."
    return 4
  }

  # Install the exact verified local RPM.  DNF can resolve ordinary
  # distribution dependencies, but it cannot replace the locked provider RPM
  # with an unreviewed repository result.
  "$dnf" \
    --setopt=gpgcheck=1 \
    --setopt=repo_gpgcheck=1 \
    --setopt=localpkg_gpgcheck=1 \
    --setopt=install_weak_deps=False \
    --assumeyes install "$artifact" || {
    lsi_provider_error "Installation failed for verified provider package $requested_nevra."
    return 4
  }
  "$verify_binary" --version > /dev/null || {
    lsi_provider_error "Installed provider binary did not verify: ${verify_binary##*/}."
    return 4
  }
)

lsi_provider_cleanup_transient_configurations() {
  local root=$1 provider index status=0
  for ((index = ${#LSI_PROVIDER_PLAN_ORDER[@]} - 1; index >= 0; index--)); do
    provider=${LSI_PROVIDER_PLAN_ORDER[index]}
    [[ -z ${LSI_PROVIDER_PLAN_PERSIST[$provider]+x} ]] || continue
    lsi_provider_deactivate_config_file "$provider" "$root" || status=$?
  done
  return "$status"
}

lsi_provider_install_current() {
  local provider_id=${1:-} root=${LSI_PROVIDER_APPLY_ROOT:-/} provider row cell_id manager
  local selected lock_row lock_cell status=0 cleanup_status=0
  local -A requested=()
  (($# > 0)) && shift
  lsi_provider_valid_slug "$provider_id" || {
    lsi_provider_error 'provider-install requires a valid provider ID.'
    return 2
  }
  lsi_provider_apply_parse_args "$@" || return
  lsi_provider_plan_prepare "$provider_id" "${LSI_PROVIDER_APPLY_ARGS[@]}" || return
  [[ $LSI_PROVIDER_PLAN_DIGEST == "$LSI_PROVIDER_APPLY_EXPECTED_DIGEST" ]] || {
    lsi_provider_error 'Reviewed provider plan SHA-256 does not match the current exact plan; refusing installation.'
    return 5
  }
  [[ $root == /* && -d $root && ! -L $root ]] || {
    lsi_provider_error 'Provider installation root must be an existing absolute, non-symlink directory.'
    return 3
  }
  [[ ${LSI_PROVIDER_APPLY_ALLOW_NONROOT_TEST:-false} == true || $root == / ]] || {
    lsi_provider_error 'A non-system provider installation root is test-only.'
    return 3
  }
  [[ ${LSI_PROVIDER_APPLY_ALLOW_NONROOT_TEST:-false} == true ]] || lsi_require_root
  [[ ${LSI_PROVIDER_APPLY_ALLOW_NONROOT_TEST:-false} == true ]] || lsi_acquire_lock

  for provider in "${LSI_PROVIDER_PLAN_ORDER[@]}"; do
    lsi_provider_apply_config_file "$provider" "$root" || {
      status=$?
      lsi_provider_cleanup_transient_configurations "$root" > /dev/null 2>&1 || :
      return "$status"
    }
  done

  row=${LSI_PROVIDER_PLAN_ACTIVATION[$provider_id]:-}
  IFS=$'\t' read -r cell_id _os_id _version_id _arch manager _remainder <<< "$row"
  case "$manager" in
    apt-get)
      for selected in "${LSI_PROVIDER_PLAN_MODULES[@]}"; do
        requested["$selected"]=1
      done
      for lock_row in "${LSI_PROVIDER_PLAN_PRIMARY_LOCK_ROWS[@]}"; do
        IFS=$'\t' read -r _module_id lock_cell _remainder <<< "$lock_row"
        [[ $lock_cell == "$cell_id" && -n ${requested[$_module_id]+x} ]] || continue
        lsi_provider_apt_install_locked_package "$lock_row" || {
          status=$?
          break
        }
      done
      ;;
    dnf)
      for selected in "${LSI_PROVIDER_PLAN_MODULES[@]}"; do
        requested["$selected"]=1
      done
      for lock_row in "${LSI_PROVIDER_PLAN_PRIMARY_LOCK_ROWS[@]}"; do
        IFS=$'\t' read -r _module_id lock_cell _remainder <<< "$lock_row"
        [[ $lock_cell == "$cell_id" && -n ${requested[$_module_id]+x} ]] || continue
        lsi_provider_dnf_install_locked_package "$lock_row" || {
          status=$?
          break
        }
      done
      ;;
    *)
      lsi_provider_error "Provider installation has no safe implementation for package manager: $manager"
      status=4
      ;;
  esac

  lsi_provider_cleanup_transient_configurations "$root" || cleanup_status=$?
  ((status == 0)) || return "$status"
  ((cleanup_status == 0)) || {
    lsi_provider_error 'Verified provider package installed, but transient repository cleanup failed.'
    return "$cleanup_status"
  }
  printf 'Verified provider package transaction completed from reviewed plan SHA-256: %s\n' "$LSI_PROVIDER_PLAN_DIGEST"
  printf '%s\n' 'Repository files were removed unless persistence was explicitly acknowledged.'
}

lsi_provider_usage() {
  cat << 'EOF'
Provider catalog commands:
  ./install.sh providers
  ./install.sh provider-info PROVIDER
  ./install.sh provider-plan PROVIDER --allow-provider PROVIDER@CATALOG_REVISION [ACK...] MODULE...
  ./install.sh provider-config PROVIDER --allow-provider PROVIDER@CATALOG_REVISION [ACK...] MODULE...
  sudo ./install.sh provider-apply PROVIDER --plan-sha256 PLAN_SHA256 --allow-provider PROVIDER@CATALOG_REVISION [ACK...] MODULE...
  sudo ./install.sh provider-deactivate PROVIDER --plan-sha256 PLAN_SHA256 --allow-provider PROVIDER@CATALOG_REVISION [ACK...] MODULE...
  sudo ./install.sh provider-install PROVIDER --plan-sha256 PLAN_SHA256 --allow-provider PROVIDER@CATALOG_REVISION [ACK...] MODULE...

Provider-plan acknowledgements (repeat for dependencies):
  --allow-preview-provider PROVIDER
  --accept-provider-license PROVIDER@REVISION
  --ack-provider-auth PROVIDER
  --persist-provider PROVIDER
EOF
}

lsi_provider_main() {
  local command=${1:-}
  (($# > 0)) && shift
  case "$command" in
    providers)
      (($# == 0)) || {
        lsi_provider_usage >&2
        return 2
      }
      lsi_provider_list
      ;;
    provider-info)
      (($# == 1)) || {
        lsi_provider_usage >&2
        return 2
      }
      lsi_provider_info "$1"
      ;;
    provider-plan)
      lsi_provider_plan_current "$@"
      ;;
    provider-config)
      lsi_provider_config_current "$@"
      ;;
    provider-apply)
      lsi_provider_apply_current "$@"
      ;;
    provider-deactivate)
      lsi_provider_deactivate_current "$@"
      ;;
    provider-install)
      lsi_provider_install_current "$@"
      ;;
    *)
      lsi_provider_usage >&2
      return 2
      ;;
  esac
}
