#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
INVENTORY="$ROOT_DIR/docs/legacy-inventory.tsv"
BACKLOG="$ROOT_DIR/docs/provider-backlog.tsv"

export LSI_PROJECT_ROOT="$ROOT_DIR"
# shellcheck source=../lib/common.sh
source "$ROOT_DIR/lib/common.sh"
# shellcheck source=../lib/catalog.sh
source "$ROOT_DIR/lib/catalog.sh"

EXPECTED_TOTAL=126
EXPECTED_IMPLEMENT=109
EXPECTED_CONDITIONAL_ARTIFACT=17
EXPECTED_TERMINAL_HANDOFF=0
EXPECTED_UNIQUE_CAPABILITIES=81
EXPECTED_UNIQUE_OUTCOMES=79
EXPECTED_ACTIVE_REUSE_ROWS=47
EXPECTED_ACTIVE_REUSE_OUTCOMES=20
EXPECTED_FAMILY_READY_REUSE_ROWS=1
EXPECTED_TARGET_RESTRICTED_REUSE_ROWS=1
EXPECTED_NONREUSE_ROWS=79
EXPECTED_NONREUSE_OUTCOMES=59
EXPECTED_EXTERNAL_ROUTE_ROWS=124
EXPECTED_DISTRO_ROUTE_ROWS=2
EXPECTED_INVENTORY_HEADER=$'legacy_id\tsource_set\tsource_path\tsource_item\tdisplay_name\tnormalized_capability\ttarget_family\tdisposition\treplacement\tparity_level\tevidence\trationale'
EXPECTED_BACKLOG_HEADER=$'legacy_id\tnormalized_capability\tstrategy\trecommended_action\treplacement_outcome\trationale'

die() {
  printf 'provider backlog validation failed: %s\n' "$*" >&2
  exit 1
}

[[ -r $INVENTORY ]] || die "cannot read $INVENTORY"
[[ -r $BACKLOG ]] || die "cannot read $BACKLOG"

IFS= read -r inventory_header < "$INVENTORY" || die 'legacy inventory is empty'
inventory_header=${inventory_header%$'\r'}
[[ $inventory_header == "$EXPECTED_INVENTORY_HEADER" ]] ||
  die 'unexpected legacy inventory TSV header'

IFS= read -r backlog_header < "$BACKLOG" || die 'provider backlog is empty'
backlog_header=${backlog_header%$'\r'}
[[ $backlog_header == "$EXPECTED_BACKLOG_HEADER" ]] ||
  die 'unexpected provider backlog TSV header'

awk -F '\t' '
  NR > 1 && NF != 6 {
    printf "provider backlog validation failed: line %d has %d fields, expected 6\n", NR, NF > "/dev/stderr"
    exit 1
  }
' "$BACKLOG" || exit 1

declare -A blocked_capabilities=()
declare -A blocked_families=()
blocked_count=0
while IFS=$'\t' read -r \
  inventory_id source_set source_path source_item display_name \
  inventory_capability target_family disposition replacement parity_level \
  evidence inventory_rationale; do
  inventory_rationale=${inventory_rationale%$'\r'}
  [[ $disposition == blocked-third-party ]] || continue
  [[ -z ${blocked_capabilities[$inventory_id]+x} ]] ||
    die "duplicate blocked legacy_id in inventory: $inventory_id"
  blocked_capabilities["$inventory_id"]=$inventory_capability
  blocked_families["$inventory_id"]=$target_family
  blocked_count=$((blocked_count + 1))
done < <(tail -n +2 "$INVENTORY")

[[ $blocked_count -eq $EXPECTED_TOTAL ]] ||
  die "legacy inventory has $blocked_count blocked-third-party rows; expected $EXPECTED_TOTAL"

declare -A expected_strategy_counts=(
  ['authenticated-download']=0
  ['community-client-handoff']=0
  ['distro-component']=2
  ['epel-package']=35
  ['infrastructure-handoff']=0
  ['maintenance-handoff']=0
  ['public-artifact']=17
  ['retired-review']=0
  ['rpm-fusion']=10
  ['snap-bootstrap']=2
  ['snap-store']=32
  ['vendor-apt']=12
  ['vendor-rpm']=16
)
declare -A strategy_counts=()
declare -A seen_backlog_ids=()
declare -A seen_capabilities=()
declare -A seen_outcomes=()
declare -A active_reuse_outcomes=()

backlog_count=0
implement_count=0
conditional_artifact_count=0
terminal_handoff_count=0
active_reuse_rows=0
family_ready_reuse_rows=0
target_restricted_reuse_rows=0
external_route_rows=0
distro_route_rows=0
line_number=1

while IFS=$'\t' read -r \
  legacy_id normalized_capability strategy recommended_action \
  replacement_outcome rationale; do
  line_number=$((line_number + 1))
  rationale=${rationale%$'\r'}

  [[ $legacy_id =~ ^[a-z0-9][a-z0-9-]*$ ]] ||
    die "line $line_number has an invalid legacy_id: $legacy_id"
  [[ -z ${seen_backlog_ids[$legacy_id]+x} ]] ||
    die "duplicate provider backlog legacy_id: $legacy_id"
  seen_backlog_ids["$legacy_id"]=1

  [[ -n ${blocked_capabilities[$legacy_id]+x} ]] ||
    die "line $line_number references a non-blocked or missing legacy row: $legacy_id"
  [[ $normalized_capability == "${blocked_capabilities[$legacy_id]}" ]] ||
    die "line $line_number capability mismatch for $legacy_id: $normalized_capability"
  [[ $replacement_outcome =~ ^[a-z0-9][a-z0-9-]*$ ]] ||
    die "line $line_number has an invalid replacement outcome: $replacement_outcome"
  [[ -n $rationale && $rationale != '-' ]] ||
    die "line $line_number must include a rationale"

  seen_capabilities["$normalized_capability"]=1
  seen_outcomes["$replacement_outcome"]=1

  if [[ $strategy == distro-component ]]; then
    distro_route_rows=$((distro_route_rows + 1))
  else
    external_route_rows=$((external_route_rows + 1))
  fi

  if [[ -f $ROOT_DIR/modules/$replacement_outcome/module.sh ]]; then
    active_reuse_rows=$((active_reuse_rows + 1))
    active_reuse_outcomes["$replacement_outcome"]=1
    lsi_load_module "$replacement_outcome"
    if lsi_module_supports_family "${blocked_families[$legacy_id]}"; then
      if lsi_module_has_target_restrictions; then
        target_restricted_reuse_rows=$((target_restricted_reuse_rows + 1))
      else
        family_ready_reuse_rows=$((family_ready_reuse_rows + 1))
      fi
    fi
  fi

  expected_action=
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
    *) die "line $line_number has an invalid strategy: $strategy" ;;
  esac

  [[ $recommended_action == "$expected_action" ]] ||
    die "line $line_number maps $strategy to $recommended_action; expected $expected_action"

  current_strategy_count=${strategy_counts[$strategy]:-0}
  strategy_counts["$strategy"]=$((current_strategy_count + 1))
  case "$recommended_action" in
    implement) implement_count=$((implement_count + 1)) ;;
    conditional-artifact) conditional_artifact_count=$((conditional_artifact_count + 1)) ;;
    terminal-handoff) terminal_handoff_count=$((terminal_handoff_count + 1)) ;;
    *) die "line $line_number has an invalid recommended action: $recommended_action" ;;
  esac

  backlog_count=$((backlog_count + 1))
done < <(tail -n +2 "$BACKLOG")

[[ $backlog_count -eq $EXPECTED_TOTAL ]] ||
  die "provider backlog has $backlog_count rows; expected $EXPECTED_TOTAL"

for legacy_id in "${!blocked_capabilities[@]}"; do
  [[ -n ${seen_backlog_ids[$legacy_id]+x} ]] ||
    die "provider backlog is missing blocked legacy row: $legacy_id"
done

for strategy in "${!expected_strategy_counts[@]}"; do
  actual_count=${strategy_counts[$strategy]:-0}
  expected_count=${expected_strategy_counts[$strategy]}
  [[ $actual_count -eq $expected_count ]] ||
    die "strategy $strategy has $actual_count rows; expected $expected_count"
done

[[ $implement_count -eq $EXPECTED_IMPLEMENT ]] ||
  die "implement has $implement_count rows; expected $EXPECTED_IMPLEMENT"
[[ $conditional_artifact_count -eq $EXPECTED_CONDITIONAL_ARTIFACT ]] ||
  die "conditional-artifact has $conditional_artifact_count rows; expected $EXPECTED_CONDITIONAL_ARTIFACT"
[[ $terminal_handoff_count -eq $EXPECTED_TERMINAL_HANDOFF ]] ||
  die "terminal-handoff has $terminal_handoff_count rows; expected $EXPECTED_TERMINAL_HANDOFF"

unique_capability_count=${#seen_capabilities[@]}
unique_outcome_count=${#seen_outcomes[@]}
active_reuse_outcome_count=${#active_reuse_outcomes[@]}
nonreuse_rows=$((backlog_count - active_reuse_rows))
nonreuse_outcomes=$((unique_outcome_count - active_reuse_outcome_count))

[[ $unique_capability_count -eq $EXPECTED_UNIQUE_CAPABILITIES ]] ||
  die "provider backlog has $unique_capability_count unique capabilities; expected $EXPECTED_UNIQUE_CAPABILITIES"
[[ $unique_outcome_count -eq $EXPECTED_UNIQUE_OUTCOMES ]] ||
  die "provider backlog has $unique_outcome_count unique outcomes; expected $EXPECTED_UNIQUE_OUTCOMES"
[[ $active_reuse_rows -eq $EXPECTED_ACTIVE_REUSE_ROWS ]] ||
  die "active-module reuse has $active_reuse_rows rows; expected $EXPECTED_ACTIVE_REUSE_ROWS"
[[ $active_reuse_outcome_count -eq $EXPECTED_ACTIVE_REUSE_OUTCOMES ]] ||
  die "active-module reuse has $active_reuse_outcome_count outcomes; expected $EXPECTED_ACTIVE_REUSE_OUTCOMES"
[[ $family_ready_reuse_rows -eq $EXPECTED_FAMILY_READY_REUSE_ROWS ]] ||
  die "family-ready active-module reuse has $family_ready_reuse_rows rows; expected $EXPECTED_FAMILY_READY_REUSE_ROWS"
[[ $target_restricted_reuse_rows -eq $EXPECTED_TARGET_RESTRICTED_REUSE_ROWS ]] ||
  die "target-restricted active-module reuse has $target_restricted_reuse_rows rows; expected $EXPECTED_TARGET_RESTRICTED_REUSE_ROWS"
[[ $nonreuse_rows -eq $EXPECTED_NONREUSE_ROWS ]] ||
  die "non-reuse backlog has $nonreuse_rows rows; expected $EXPECTED_NONREUSE_ROWS"
[[ $nonreuse_outcomes -eq $EXPECTED_NONREUSE_OUTCOMES ]] ||
  die "non-reuse backlog has $nonreuse_outcomes outcomes; expected $EXPECTED_NONREUSE_OUTCOMES"
[[ $external_route_rows -eq $EXPECTED_EXTERNAL_ROUTE_ROWS ]] ||
  die "external provider/artifact routes have $external_route_rows rows; expected $EXPECTED_EXTERNAL_ROUTE_ROWS"
[[ $distro_route_rows -eq $EXPECTED_DISTRO_ROUTE_ROWS ]] ||
  die "distribution-component routes have $distro_route_rows rows; expected $EXPECTED_DISTRO_ROUTE_ROWS"

printf 'Provider backlog valid: %d exact blocked-third-party rows.\n' "$backlog_count"
printf 'Recommended actions: %d implement, %d conditional-artifact, %d terminal-handoff.\n' \
  "$implement_count" "$conditional_artifact_count" "$terminal_handoff_count"
printf 'Strategy groups: %d machine-checked provider and handoff routes.\n' \
  "${#expected_strategy_counts[@]}"
printf 'Closure shape: %d capabilities, %d outcomes; %d rows reuse %d active modules.\n' \
  "$unique_capability_count" "$unique_outcome_count" "$active_reuse_rows" \
  "$active_reuse_outcome_count"
printf 'Family-ready reuse: %d rows; external provider/artifact routes: %d rows.\n' \
  "$family_ready_reuse_rows" "$external_route_rows"
printf 'Target-restricted reuse: %d rows; promotion still requires accepted evidence.\n' \
  "$target_restricted_reuse_rows"
