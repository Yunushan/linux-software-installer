#!/usr/bin/env bash

LSI_MIGRATION_INVENTORY="$LSI_PROJECT_ROOT/docs/legacy-inventory.tsv"
LSI_MIGRATION_BACKLOG="$LSI_PROJECT_ROOT/docs/provider-backlog.tsv"
LSI_MIGRATION_ACCEPTED_EVIDENCE="$LSI_PROJECT_ROOT/docs/accepted-evidence.tsv"
LSI_MIGRATION_PROVIDER_REGISTRY="$LSI_PROJECT_ROOT/providers/registry.tsv"
LSI_MIGRATION_INVENTORY_HEADER=$'legacy_id\tsource_set\tsource_path\tsource_item\tdisplay_name\tnormalized_capability\ttarget_family\tdisposition\treplacement\tparity_level\tevidence\trationale'
LSI_MIGRATION_BACKLOG_HEADER=$'legacy_id\tnormalized_capability\tstrategy\trecommended_action\treplacement_outcome\trationale'
LSI_MIGRATION_ACCEPTED_EVIDENCE_HEADER=$'evidence_key\tcommit_sha\trun_url\tartifact_url\tartifact_digest\tindex_sha256\ttarget_cells\tparity_report\tsystemd_run_url\tsystemd_artifact_url\tsystemd_artifact_digest'
LSI_MIGRATION_PROVIDER_REGISTRY_HEADER=$'provider_id\tcatalog_revision\tcatalog_sha256'

declare -ga LSI_MIGRATION_IDS=()
declare -gA LSI_MIGRATION_ROWS=()
declare -gA LSI_MIGRATION_BACKLOG_ROWS=()
declare -g LSI_MIGRATION_TOTAL=0
declare -g LSI_MIGRATION_PLANNED=0
declare -g LSI_MIGRATION_BLOCKED=0
declare -g LSI_MIGRATION_TERMINAL=0
declare -g LSI_MIGRATION_ACCEPTED_EVIDENCE_COUNT=0
declare -g LSI_MIGRATION_REGISTERED_PROVIDER_COUNT=0
declare -g LSI_MIGRATION_LOADED=false

lsi_migration_error() {
  printf 'Migration catalog error: %s\n' "$1" >&2
  return "${2:-1}"
}

lsi_migration_reset() {
  LSI_MIGRATION_IDS=()
  LSI_MIGRATION_ROWS=()
  LSI_MIGRATION_BACKLOG_ROWS=()
  LSI_MIGRATION_TOTAL=0
  LSI_MIGRATION_PLANNED=0
  LSI_MIGRATION_BLOCKED=0
  LSI_MIGRATION_TERMINAL=0
  LSI_MIGRATION_ACCEPTED_EVIDENCE_COUNT=0
  LSI_MIGRATION_REGISTERED_PROVIDER_COUNT=0
  LSI_MIGRATION_LOADED=false
}

lsi_migration_count_exact_tsv_rows() {
  local path=$1 label=$2 header=$3 fields=$4 maximum_size=$5 line expected_size=0 observed_size=0
  local line_number=0 count=0
  local -a row=()
  local -n output=$6

  lsi_migration_validate_file "$path" "$label" "$maximum_size" expected_size || return
  {
    IFS= read -r line || {
      lsi_migration_error "$label is empty."
      return 1
    }
    [[ $line == "$header" ]] || {
      lsi_migration_error "$label header does not match the canonical schema."
      return 1
    }
    observed_size=$((${#line} + 1))
    line_number=1
    while IFS= read -r line; do
      line_number=$((line_number + 1))
      observed_size=$((observed_size + ${#line} + 1))
      ((${#line} <= 4096)) || {
        lsi_migration_error "$label line $line_number is too long."
        return 1
      }
      lsi_migration_split_tsv "$line" "$fields" row || {
        lsi_migration_error "$label line $line_number has an unexpected field count."
        return 1
      }
      count=$((count + 1))
      ((count <= 512)) || {
        lsi_migration_error "$label has too many rows."
        return 1
      }
    done
  } < "$path" || return
  [[ $observed_size -eq $expected_size ]] || {
    lsi_migration_error "$label byte count is inconsistent (missing newline or binary data)."
    return 1
  }
  output=$count
}

lsi_migration_split_tsv() {
  local line=$1 expected_fields=$2 rest field
  local -n output=$3
  output=()
  rest=$line

  while [[ $rest == *$'\t'* ]]; do
    field=${rest%%$'\t'*}
    output+=("$field")
    rest=${rest#*$'\t'}
  done
  output+=("$rest")

  ((${#output[@]} == expected_fields))
}

lsi_migration_validate_file() {
  local path=$1 label=$2 maximum_size=$3 parent link_count size
  local -n validated_size=$4
  parent=${path%/*}

  [[ -d $parent && ! -L $parent ]] || {
    lsi_migration_error "$label parent must be a regular, non-symlink directory."
    return 1
  }
  [[ -f $path && ! -L $path ]] || {
    lsi_migration_error "$label must be a regular, non-symlink file."
    return 1
  }
  [[ -x /usr/bin/stat ]] || {
    lsi_migration_error 'required system tool is unavailable: /usr/bin/stat.'
    return 1
  }
  link_count=$(/usr/bin/stat -c '%h' -- "$path") || {
    lsi_migration_error "$label metadata could not be read."
    return 1
  }
  size=$(/usr/bin/stat -c '%s' -- "$path") || {
    lsi_migration_error "$label size could not be read."
    return 1
  }
  [[ $link_count == 1 && $size =~ ^[0-9]+$ && $size -le maximum_size ]] || {
    lsi_migration_error "$label must be single-linked and no larger than $maximum_size bytes."
    return 1
  }
  validated_size=$size
}

lsi_migration_validate_text() {
  local label=$1 value=$2 maximum=$3
  [[ -n $value && $value != '-' ]] || {
    lsi_migration_error "$label must not be empty or '-'."
    return 1
  }
  ((${#value} <= maximum)) || {
    lsi_migration_error "$label exceeds the $maximum-character limit."
    return 1
  }
  [[ ! $value =~ [[:cntrl:]] ]] || {
    lsi_migration_error "$label contains a control character."
    return 1
  }
}

lsi_migration_validate_local_evidence() {
  local legacy_id=$1 evidence_path=$2 current part link_count index
  local -a parts=()

  [[ $evidence_path =~ ^docs/[A-Za-z0-9._/-]+$ &&
    $evidence_path != *'//'* ]] || {
    lsi_migration_error "$legacy_id has an unsafe local evidence reference."
    return 1
  }
  IFS='/' read -r -a parts <<< "$evidence_path"
  ((${#parts[@]} >= 2)) || {
    lsi_migration_error "$legacy_id has an incomplete local evidence reference."
    return 1
  }

  current=$LSI_PROJECT_ROOT
  [[ -d $current && ! -L $current ]] || {
    lsi_migration_error 'project root must be a physical directory.'
    return 1
  }
  for ((index = 0; index < ${#parts[@]}; index++)); do
    part=${parts[index]}
    [[ -n $part && $part != '.' && $part != '..' ]] || {
      lsi_migration_error "$legacy_id has a non-canonical local evidence reference."
      return 1
    }
    current="$current/$part"
    if ((index + 1 < ${#parts[@]})); then
      [[ -d $current && ! -L $current ]] || {
        lsi_migration_error "$legacy_id references a missing or linked evidence directory."
        return 1
      }
    else
      [[ -f $current && ! -L $current ]] || {
        lsi_migration_error "$legacy_id references missing or linked evidence: $evidence_path."
        return 1
      }
    fi
  done

  link_count=$(/usr/bin/stat -c '%h' -- "$current") || {
    lsi_migration_error "$legacy_id evidence metadata could not be read."
    return 1
  }
  [[ $link_count == 1 ]] || {
    lsi_migration_error "$legacy_id evidence must be a single-linked regular file."
    return 1
  }
}

lsi_migration_validate_evidence() {
  local legacy_id=$1 disposition=$2 evidence=$3 evidence_path

  if [[ $evidence == '-' ]]; then
    case "$disposition" in
      implemented | superseded | retired | blocked-safety | out-of-scope)
        lsi_migration_error "$legacy_id requires evidence for terminal disposition $disposition."
        return 1
        ;;
      *) return 0 ;;
    esac
  fi

  [[ ! $evidence =~ [[:cntrl:]] && ${#evidence} -le 512 ]] || {
    lsi_migration_error "$legacy_id has invalid evidence text."
    return 1
  }
  [[ $evidence != http://* ]] || {
    lsi_migration_error "$legacy_id uses an insecure evidence URL."
    return 1
  }
  if [[ $evidence == https://* ]]; then
    [[ $evidence =~ ^https://[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?(:[0-9]{1,5})?([/?#][^[:space:]]*)?$ ]] || {
      lsi_migration_error "$legacy_id has an invalid HTTPS evidence URL."
      return 1
    }
    return 0
  fi

  [[ $evidence =~ ^docs/[A-Za-z0-9._/-]+(#[a-z0-9][a-z0-9-]*)?$ ]] || {
    lsi_migration_error "$legacy_id has an unsafe local evidence reference."
    return 1
  }
  evidence_path=${evidence%%#*}
  lsi_migration_validate_local_evidence "$legacy_id" "$evidence_path"
}

lsi_migration_load_inventory() {
  local header line legacy_id source_set source_path source_item display_name
  local capability family disposition replacement parity evidence rationale row
  local line_number=1 expected_size=0 observed_size=0
  local -a fields=()

  lsi_migration_validate_file \
    "$LSI_MIGRATION_INVENTORY" 'legacy inventory' 1048576 expected_size || return 1

  {
    IFS= read -r header || {
      lsi_migration_error 'legacy inventory is empty.'
      return 1
    }
    [[ $header == "$LSI_MIGRATION_INVENTORY_HEADER" ]] || {
      lsi_migration_error 'legacy inventory header does not match the canonical schema.'
      return 1
    }
    observed_size=$((${#header} + 1))

    while IFS= read -r line; do
      line_number=$((line_number + 1))
      observed_size=$((observed_size + ${#line} + 1))
      ((${#line} <= 4096)) || {
        lsi_migration_error "legacy inventory line $line_number is too long."
        return 1
      }
      lsi_migration_split_tsv "$line" 12 fields || {
        lsi_migration_error "legacy inventory line $line_number must contain exactly 12 fields."
        return 1
      }

      legacy_id=${fields[0]}
      source_set=${fields[1]}
      source_path=${fields[2]}
      source_item=${fields[3]}
      display_name=${fields[4]}
      capability=${fields[5]}
      family=${fields[6]}
      disposition=${fields[7]}
      replacement=${fields[8]}
      parity=${fields[9]}
      evidence=${fields[10]}
      rationale=${fields[11]}

      [[ $legacy_id =~ ^[a-z0-9][a-z0-9-]{0,79}$ ]] || {
        lsi_migration_error "legacy inventory line $line_number has an invalid legacy_id."
        return 1
      }
      [[ -z ${LSI_MIGRATION_ROWS[$legacy_id]+x} ]] || {
        lsi_migration_error "legacy inventory repeats legacy_id $legacy_id."
        return 1
      }
      lsi_migration_validate_text "$legacy_id display name" "$display_name" 256 || return 1
      [[ $capability =~ ^[a-z0-9][a-z0-9-]{0,79}$ ]] || {
        lsi_migration_error "$legacy_id has an invalid normalized capability."
        return 1
      }
      [[ $replacement == '-' || $replacement =~ ^[a-z0-9][a-z0-9-]{0,79}$ ]] || {
        lsi_migration_error "$legacy_id has an invalid replacement ID."
        return 1
      }
      [[ $parity == unassessed || $parity == intent || $parity == package || $parity == behavioral ]] || {
        lsi_migration_error "$legacy_id has an invalid parity level."
        return 1
      }
      lsi_migration_validate_text "$legacy_id rationale" "$rationale" 1024 || return 1

      case "$source_set" in
        ubuntu)
          [[ $source_path == legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh &&
            $source_item =~ ^menu:[0-9]{3}$ && $family == debian ]] || {
            lsi_migration_error "$legacy_id has an invalid Ubuntu source locator or family."
            return 1
          }
          ;;
        rhel)
          [[ $source_path =~ ^legacy/rhel-family/[A-Za-z0-9][A-Za-z0-9.-]*/scripts/[A-Za-z0-9][A-Za-z0-9.+-]*\.sh$ &&
            $source_item == script && $family == rhel ]] || {
            lsi_migration_error "$legacy_id has an invalid RHEL-family source locator or family."
            return 1
          }
          ;;
        *)
          lsi_migration_error "$legacy_id has an invalid source set."
          return 1
          ;;
      esac
      [[ $legacy_id == "$source_set"-* ]] || {
        lsi_migration_error "$legacy_id does not match source set $source_set."
        return 1
      }

      case "$disposition" in
        planned)
          [[ $replacement != '-' && $parity != unassessed && $evidence == '-' ]] || {
            lsi_migration_error "$legacy_id has an invalid provisional replacement contract."
            return 1
          }
          LSI_MIGRATION_PLANNED=$((LSI_MIGRATION_PLANNED + 1))
          ;;
        blocked-third-party)
          [[ $replacement == '-' && $parity == unassessed && $evidence == '-' ]] || {
            lsi_migration_error "$legacy_id cannot claim an unresolved third-party replacement."
            return 1
          }
          LSI_MIGRATION_BLOCKED=$((LSI_MIGRATION_BLOCKED + 1))
          ;;
        implemented | superseded)
          lsi_migration_error \
            "$legacy_id cannot claim $disposition until an accepted-evidence admission record is validated."
          return 1
          ;;
        retired | blocked-safety | out-of-scope)
          LSI_MIGRATION_TERMINAL=$((LSI_MIGRATION_TERMINAL + 1))
          ;;
        *)
          lsi_migration_error "$legacy_id has an invalid disposition: $disposition."
          return 1
          ;;
      esac

      if [[ $replacement != '-' ]]; then
        [[ $LSI_MODULE_DIR == "$LSI_PROJECT_ROOT/modules" ]] || {
          lsi_migration_error "$legacy_id references an unsafe module catalog."
          return 1
        }
        lsi_module_manifest_is_safe "$replacement" || {
          lsi_migration_error "$legacy_id references an unsafe module manifest: $replacement."
          return 1
        }
        lsi_load_module "$replacement"
        lsi_module_supports_family "$family" || {
          lsi_migration_error "$legacy_id maps module $replacement to unsupported family $family."
          return 1
        }
      fi
      lsi_migration_validate_evidence "$legacy_id" "$disposition" "$evidence" || return 1

      printf -v row '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
        "$source_set" "$source_path" "$source_item" "$display_name" "$capability" \
        "$family" "$disposition" "$replacement" "$parity" "$evidence" "$rationale"
      LSI_MIGRATION_IDS+=("$legacy_id")
      LSI_MIGRATION_ROWS["$legacy_id"]=$row
      LSI_MIGRATION_TOTAL=$((LSI_MIGRATION_TOTAL + 1))
      ((LSI_MIGRATION_TOTAL <= 355)) || {
        lsi_migration_error 'legacy inventory contains more than 355 rows.'
        return 1
      }
    done
  } < "$LSI_MIGRATION_INVENTORY"

  [[ $LSI_MIGRATION_TOTAL -eq 355 ]] || {
    lsi_migration_error "legacy inventory has $LSI_MIGRATION_TOTAL rows; expected 355."
    return 1
  }
  [[ $observed_size -eq $expected_size ]] || {
    lsi_migration_error 'legacy inventory byte count is inconsistent (missing newline or binary data).'
    return 1
  }
}

lsi_migration_load_backlog() {
  local header line legacy_id capability strategy recommended_action outcome rationale
  local inventory_row source_set source_path source_item display_name inventory_capability
  local family disposition replacement parity evidence inventory_rationale row expected_action
  local line_number=1 backlog_count=0 expected_size=0 observed_size=0
  local -a fields=()

  lsi_migration_validate_file \
    "$LSI_MIGRATION_BACKLOG" 'provider backlog' 524288 expected_size || return 1

  {
    IFS= read -r header || {
      lsi_migration_error 'provider backlog is empty.'
      return 1
    }
    [[ $header == "$LSI_MIGRATION_BACKLOG_HEADER" ]] || {
      lsi_migration_error 'provider backlog header does not match the canonical schema.'
      return 1
    }
    observed_size=$((${#header} + 1))

    while IFS= read -r line; do
      line_number=$((line_number + 1))
      observed_size=$((observed_size + ${#line} + 1))
      ((${#line} <= 4096)) || {
        lsi_migration_error "provider backlog line $line_number is too long."
        return 1
      }
      lsi_migration_split_tsv "$line" 6 fields || {
        lsi_migration_error "provider backlog line $line_number must contain exactly 6 fields."
        return 1
      }

      legacy_id=${fields[0]}
      capability=${fields[1]}
      strategy=${fields[2]}
      recommended_action=${fields[3]}
      outcome=${fields[4]}
      rationale=${fields[5]}

      [[ $legacy_id =~ ^[a-z0-9][a-z0-9-]{0,79}$ ]] || {
        lsi_migration_error "provider backlog line $line_number has an invalid legacy_id."
        return 1
      }
      [[ -z ${LSI_MIGRATION_BACKLOG_ROWS[$legacy_id]+x} ]] || {
        lsi_migration_error "provider backlog repeats legacy_id $legacy_id."
        return 1
      }
      [[ $capability =~ ^[a-z0-9][a-z0-9-]{0,79}$ &&
        $outcome =~ ^[a-z0-9][a-z0-9-]{0,79}$ ]] || {
        lsi_migration_error "$legacy_id has an invalid backlog capability or outcome."
        return 1
      }
      lsi_migration_validate_text "$legacy_id backlog rationale" "$rationale" 1024 || return 1

      case "$strategy" in
        distro-component | epel-package | rpm-fusion | snap-bootstrap | snap-store | vendor-apt | vendor-rpm)
          expected_action=implement
          ;;
        public-artifact)
          expected_action=conditional-artifact
          ;;
        authenticated-download | community-client-handoff | infrastructure-handoff | maintenance-handoff | retired-review)
          expected_action=terminal-handoff
          ;;
        *)
          lsi_migration_error "$legacy_id has an invalid backlog strategy: $strategy."
          return 1
          ;;
      esac
      [[ $recommended_action == "$expected_action" ]] || {
        lsi_migration_error "$legacy_id maps $strategy to invalid action $recommended_action."
        return 1
      }

      [[ -n ${LSI_MIGRATION_ROWS[$legacy_id]+x} ]] || {
        lsi_migration_error "provider backlog references missing legacy row $legacy_id."
        return 1
      }
      inventory_row=${LSI_MIGRATION_ROWS[$legacy_id]}
      IFS=$'\t' read -r source_set source_path source_item display_name \
        inventory_capability family disposition replacement parity evidence \
        inventory_rationale <<< "$inventory_row"
      [[ $disposition == blocked-third-party ]] || {
        lsi_migration_error "provider backlog references non-blocked legacy row $legacy_id."
        return 1
      }
      [[ $capability == "$inventory_capability" ]] || {
        lsi_migration_error "provider backlog capability does not match $legacy_id."
        return 1
      }

      printf -v row '%s\t%s\t%s\t%s\t%s' \
        "$capability" "$strategy" "$recommended_action" "$outcome" "$rationale"
      LSI_MIGRATION_BACKLOG_ROWS["$legacy_id"]=$row
      backlog_count=$((backlog_count + 1))
      ((backlog_count <= LSI_MIGRATION_BLOCKED)) || {
        lsi_migration_error 'provider backlog contains too many rows.'
        return 1
      }
    done
  } < "$LSI_MIGRATION_BACKLOG"

  [[ $backlog_count -eq $LSI_MIGRATION_BLOCKED ]] || {
    lsi_migration_error "provider backlog has $backlog_count rows; expected $LSI_MIGRATION_BLOCKED."
    return 1
  }
  [[ $observed_size -eq $expected_size ]] || {
    lsi_migration_error 'provider backlog byte count is inconsistent (missing newline or binary data).'
    return 1
  }
  for legacy_id in "${LSI_MIGRATION_IDS[@]}"; do
    inventory_row=${LSI_MIGRATION_ROWS[$legacy_id]}
    IFS=$'\t' read -r source_set source_path source_item display_name \
      inventory_capability family disposition replacement parity evidence \
      inventory_rationale <<< "$inventory_row"
    if [[ $disposition == blocked-third-party ]]; then
      [[ -n ${LSI_MIGRATION_BACKLOG_ROWS[$legacy_id]+x} ]] || {
        lsi_migration_error "provider backlog is missing blocked legacy row $legacy_id."
        return 1
      }
    fi
  done
}

lsi_migration_load() {
  [[ $LSI_MIGRATION_LOADED == false ]] || return 0
  lsi_migration_reset
  lsi_migration_load_inventory || {
    lsi_migration_reset
    return 1
  }
  lsi_migration_load_backlog || {
    lsi_migration_reset
    return 1
  }
  LSI_MIGRATION_LOADED=true
}

lsi_migration_list() {
  local legacy_id row source_set source_path source_item display_name capability
  local family disposition replacement parity evidence rationale successor
  local backlog_row backlog_capability strategy recommended_action outcome backlog_rationale

  lsi_migration_load || return 1
  printf '%s\n\n' 'Read-only migration guidance; no system changes are made.'
  printf '%-58s %-21s %s\n' 'LEGACY ID' 'DISPOSITION' 'SUCCESSOR / HANDOFF'
  for legacy_id in "${LSI_MIGRATION_IDS[@]}"; do
    row=${LSI_MIGRATION_ROWS[$legacy_id]}
    IFS=$'\t' read -r source_set source_path source_item display_name capability \
      family disposition replacement parity evidence rationale <<< "$row"
    case "$disposition" in
      blocked-third-party)
        backlog_row=${LSI_MIGRATION_BACKLOG_ROWS[$legacy_id]}
        IFS=$'\t' read -r backlog_capability strategy recommended_action outcome \
          backlog_rationale <<< "$backlog_row"
        successor="proposed:$outcome ($strategy)"
        ;;
      planned) successor="candidate:$replacement" ;;
      implemented | superseded) successor="module:$replacement" ;;
      *)
        if [[ $replacement == '-' ]]; then
          successor='documented handoff'
        else
          successor="handoff:$replacement"
        fi
        ;;
    esac
    printf '%-58s %-21s %s\n' "$legacy_id" "$disposition" "$successor"
  done
  printf '\n%d entries: %d terminal, %d provisional, %d unresolved third-party.\n' \
    "$LSI_MIGRATION_TOTAL" "$LSI_MIGRATION_TERMINAL" \
    "$LSI_MIGRATION_PLANNED" "$LSI_MIGRATION_BLOCKED"
  printf '%s\n' \
    'Candidates and proposed routes are not support claims; inspect one with ./install.sh migrate LEGACY_ID.'
}

lsi_migration_retirement_status() {
  lsi_migration_load || return 1
  lsi_migration_count_exact_tsv_rows \
    "$LSI_MIGRATION_ACCEPTED_EVIDENCE" 'accepted-evidence admission registry' \
    "$LSI_MIGRATION_ACCEPTED_EVIDENCE_HEADER" 11 1048576 \
    LSI_MIGRATION_ACCEPTED_EVIDENCE_COUNT || return 1
  lsi_migration_count_exact_tsv_rows \
    "$LSI_MIGRATION_PROVIDER_REGISTRY" 'provider admission registry' \
    "$LSI_MIGRATION_PROVIDER_REGISTRY_HEADER" 3 1048576 \
    LSI_MIGRATION_REGISTERED_PROVIDER_COUNT || return 1

  printf '%s\n\n' 'Legacy replacement retirement status (read-only; no system changes are made).'
  printf 'Tracked legacy entries        : %d\n' "$LSI_MIGRATION_TOTAL"
  printf 'Terminal dispositions         : %d\n' "$LSI_MIGRATION_TERMINAL"
  printf 'Provisional module candidates : %d\n' "$LSI_MIGRATION_PLANNED"
  printf 'Unresolved third-party routes : %d\n' "$LSI_MIGRATION_BLOCKED"
  printf 'Accepted evidence admissions  : %d\n' "$LSI_MIGRATION_ACCEPTED_EVIDENCE_COUNT"
  printf 'Registered live providers     : %d\n' "$LSI_MIGRATION_REGISTERED_PROVIDER_COUNT"
  printf '\n%s\n' 'Retirement decision           : NOT READY'
  printf '%s\n' \
    'The old repositories remain necessary for any requested capability that is' \
    'still provisional or third-party blocked. Candidate module mappings do not' \
    'become replacements until accepted evidence is recorded for their exact' \
    'target cells. Third-party routes require a reviewed provider or documented' \
    'terminal handoff before they can leave the backlog.'
  printf '\n%s\n' \
    'Next checks: ./install.sh migrations; ./install.sh migrate LEGACY_ID; see docs/REPLACEMENT.md.'
}

lsi_migration_show() {
  local legacy_id=$1 row source_set source_path source_item display_name capability
  local family disposition replacement parity evidence rationale
  local backlog_row backlog_capability strategy recommended_action outcome backlog_rationale

  [[ $legacy_id =~ ^[a-z0-9][a-z0-9-]{0,79}$ ]] || {
    lsi_migration_error 'legacy ID must contain only lowercase letters, digits and hyphens.' 2
    return 2
  }
  lsi_migration_load || return 1
  [[ -n ${LSI_MIGRATION_ROWS[$legacy_id]+x} ]] || {
    lsi_migration_error "unknown legacy ID: $legacy_id." 2
    return 2
  }

  row=${LSI_MIGRATION_ROWS[$legacy_id]}
  IFS=$'\t' read -r source_set source_path source_item display_name capability \
    family disposition replacement parity evidence rationale <<< "$row"
  printf '%s\n' 'Read-only migration guidance; no system changes are made.'
  printf 'Legacy ID     : %s\n' "$legacy_id"
  printf 'Legacy entry  : %s\n' "$display_name"
  printf 'Source locator: %s#%s (provenance only; never execute)\n' "$source_path" "$source_item"
  printf 'Capability    : %s\n' "$capability"
  printf 'Target family : %s\n' "$family"
  printf 'Disposition   : %s\n' "$disposition"
  printf 'Parity        : %s\n' "$parity"
  printf 'Replacement   : %s\n' "$replacement"
  printf 'Evidence      : %s\n' "$evidence"
  printf 'Rationale     : %s\n' "$rationale"

  case "$disposition" in
    blocked-third-party)
      backlog_row=${LSI_MIGRATION_BACKLOG_ROWS[$legacy_id]}
      IFS=$'\t' read -r backlog_capability strategy recommended_action outcome \
        backlog_rationale <<< "$backlog_row"
      printf 'Route strategy: %s\n' "$strategy"
      printf 'Proposed result: %s\n' "$outcome"
      printf 'Engineering action: %s\n' "$recommended_action"
      printf 'Route rationale: %s\n' "$backlog_rationale"
      printf '%s\n' 'Status        : unresolved; no supported automated replacement exists yet.'
      printf '%s\n' 'Safety        : do not run the quarantined legacy installer.'
      ;;
    planned)
      printf '%s\n' 'Status        : provisional candidate; accepted replacement evidence is still pending.'
      printf 'Inspect       : ./install.sh info %s\n' "$replacement"
      printf '%s\n' 'Safety        : review the current module scope; do not run the quarantined legacy installer.'
      ;;
    implemented | superseded)
      printf '%s\n' 'Status        : terminal replacement recorded with assessed parity and evidence.'
      printf 'Inspect       : ./install.sh info %s\n' "$replacement"
      ;;
    retired | blocked-safety | out-of-scope)
      printf '%s\n' 'Status        : terminal documented handoff; no legacy execution is required.'
      printf '%s\n' 'Safety        : follow the rationale and evidence; do not run the quarantined installer.'
      ;;
  esac
}
