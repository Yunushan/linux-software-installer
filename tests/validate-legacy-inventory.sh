#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
INVENTORY="$ROOT_DIR/docs/legacy-inventory.tsv"
SOURCE_DEFECTS="$ROOT_DIR/docs/legacy-source-defects.tsv"
UBUNTU_SOURCE="$ROOT_DIR/legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh"
RHEL_SOURCE_DIR="$ROOT_DIR/legacy/rhel-family"

export LSI_PROJECT_ROOT="$ROOT_DIR"
# shellcheck source=../lib/common.sh
source "$ROOT_DIR/lib/common.sh"
# shellcheck source=../lib/catalog.sh
source "$ROOT_DIR/lib/catalog.sh"

EXPECTED_UBUNTU=159
EXPECTED_RHEL=196
EXPECTED_RHEL_CAPABILITIES=87
EXPECTED_TOTAL=355
EXPECTED_SOURCE_DEFECTS=9
EXPECTED_TERMINAL=84
EXPECTED_NONTERMINAL=271
EXPECTED_PLANNED=142
EXPECTED_BLOCKED_THIRD_PARTY=129
EXPECTED_IMPLEMENTED=0
EXPECTED_SUPERSEDED=0
EXPECTED_RETIRED=25
EXPECTED_BLOCKED_SAFETY=20
EXPECTED_OUT_OF_SCOPE=39
EXPECTED_HEADER=$'legacy_id\tsource_set\tsource_path\tsource_item\tdisplay_name\tnormalized_capability\ttarget_family\tdisposition\treplacement\tparity_level\tevidence\trationale'
EXPECTED_DEFECT_HEADER=$'defect_id\tlegacy_id\tsource_path\tsource_line\tobserved_fragment\texpected_behavior\trationale'

die() {
  printf 'legacy inventory validation failed: %s\n' "$*" >&2
  exit 1
}

[[ -r $INVENTORY ]] || die "cannot read $INVENTORY"
[[ -r $SOURCE_DEFECTS ]] || die "cannot read $SOURCE_DEFECTS"
[[ -r $UBUNTU_SOURCE ]] || die "cannot read $UBUNTU_SOURCE"
[[ -d $RHEL_SOURCE_DIR ]] || die "cannot read $RHEL_SOURCE_DIR"

IFS= read -r header < "$INVENTORY" || die 'inventory is empty'
header=${header%$'\r'}
[[ $header == "$EXPECTED_HEADER" ]] || die 'unexpected TSV header'

awk -F '\t' '
  NR > 1 && NF != 12 {
    printf "legacy inventory validation failed: line %d has %d fields, expected 12\n", NR, NF > "/dev/stderr"
    exit 1
  }
' "$INVENTORY" || exit 1

IFS= read -r defect_header < "$SOURCE_DEFECTS" || die 'source-defect ledger is empty'
defect_header=${defect_header%$'\r'}
[[ $defect_header == "$EXPECTED_DEFECT_HEADER" ]] || die 'unexpected source-defect TSV header'

declare -A seen_defect_ids=()
declare -A seen_defect_rows=()
defect_count=0
defect_line_number=1
while IFS=$'\t' read -r defect_id defect_legacy_id defect_source_path \
  defect_source_line observed_fragment expected_behavior defect_rationale; do
  defect_line_number=$((defect_line_number + 1))
  defect_rationale=${defect_rationale%$'\r'}
  [[ $defect_id =~ ^source-defect-[0-9]{3}$ ]] ||
    die "source-defect line $defect_line_number has invalid ID: $defect_id"
  [[ -z ${seen_defect_ids[$defect_id]+x} ]] || die "duplicate source defect: $defect_id"
  seen_defect_ids["$defect_id"]=1
  [[ $defect_legacy_id =~ ^[a-z0-9][a-z0-9-]*$ ]] ||
    die "source defect $defect_id has invalid legacy ID: $defect_legacy_id"
  [[ -z ${seen_defect_rows[$defect_legacy_id]+x} ]] ||
    die "legacy row has multiple unreviewed source defects: $defect_legacy_id"
  seen_defect_rows["$defect_legacy_id"]=1
  grep -q "^${defect_legacy_id}"$'\t' "$INVENTORY" ||
    die "source defect $defect_id references missing inventory row: $defect_legacy_id"
  [[ $defect_source_path == legacy/* && -f $ROOT_DIR/$defect_source_path ]] ||
    die "source defect $defect_id references missing source: $defect_source_path"
  [[ $defect_source_line =~ ^[1-9][0-9]*$ ]] ||
    die "source defect $defect_id has invalid line number: $defect_source_line"
  preserved_line=$(sed -n "${defect_source_line}p" "$ROOT_DIR/$defect_source_path")
  [[ $preserved_line == *"$observed_fragment"* ]] ||
    die "source defect $defect_id no longer matches its preserved source line"
  [[ -n $expected_behavior && -n $defect_rationale ]] ||
    die "source defect $defect_id lacks expected behavior or rationale"
  defect_count=$((defect_count + 1))
done < <(tail -n +2 "$SOURCE_DEFECTS")

[[ $defect_count -eq $EXPECTED_SOURCE_DEFECTS ]] ||
  die "source-defect ledger has $defect_count rows; expected $EXPECTED_SOURCE_DEFECTS"

mapfile -t ubuntu_option_ids < <(
  awk '
    /^[[:space:]]*options=\(/ { in_options = 1 }
    in_options { print }
    in_options && /"Done \$\{opts\[160\]\}"\)/ { exit }
  ' "$UBUNTU_SOURCE" |
    grep -Eo '\$\{opts\[[0-9]+\]\}' |
    sed -E 's/[^0-9]//g' |
    sort -n -u
)

[[ ${#ubuntu_option_ids[@]} -eq 160 ]] ||
  die "Ubuntu source menu has ${#ubuntu_option_ids[@]} indexed options including Done; expected 160"

for ((expected = 1; expected <= 160; expected++)); do
  index=$((expected - 1))
  [[ ${ubuntu_option_ids[$index]} == "$expected" ]] ||
    die "Ubuntu source menu is missing or reorders option $expected"
done

declare -A actual_rhel_sources=()
declare -A actual_rhel_capabilities=()
while IFS= read -r -d '' source_file; do
  relative_path=${source_file#"$ROOT_DIR/"}
  actual_rhel_sources["$relative_path"]=1
  source_name=${source_file##*/}
  capability_name=${source_name#*-}
  capability_name=${capability_name%.sh}
  actual_rhel_capabilities["$capability_name"]=1
done < <(find "$RHEL_SOURCE_DIR" -type f -path '*/scripts/*.sh' -print0)

[[ ${#actual_rhel_sources[@]} -eq $EXPECTED_RHEL ]] ||
  die "RHEL snapshot has ${#actual_rhel_sources[@]} scripts; expected $EXPECTED_RHEL"
[[ ${#actual_rhel_capabilities[@]} -eq $EXPECTED_RHEL_CAPABILITIES ]] ||
  die "RHEL snapshot has ${#actual_rhel_capabilities[@]} capability names; expected $EXPECTED_RHEL_CAPABILITIES"

declare -A seen_ids=()
declare -A seen_locators=()
declare -A seen_ubuntu_choices=()
declare -A seen_rhel_sources=()

ubuntu_count=0
rhel_count=0
total_count=0
terminal_count=0
nonterminal_count=0
planned_count=0
blocked_third_party_count=0
implemented_count=0
superseded_count=0
retired_count=0
blocked_safety_count=0
out_of_scope_count=0
line_number=1

while IFS=$'\t' read -r \
  legacy_id source_set source_path source_item display_name \
  normalized_capability target_family disposition replacement \
  parity_level evidence rationale; do
  line_number=$((line_number + 1))
  rationale=${rationale%$'\r'}

  [[ -n $legacy_id && $legacy_id =~ ^[a-z0-9][a-z0-9-]*$ ]] ||
    die "line $line_number has an invalid legacy_id: $legacy_id"
  [[ -z ${seen_ids[$legacy_id]+x} ]] || die "duplicate legacy_id: $legacy_id"
  seen_ids["$legacy_id"]=1

  [[ -n $display_name ]] || die "line $line_number has an empty display_name"
  [[ $normalized_capability =~ ^[a-z0-9][a-z0-9-]*$ ]] ||
    die "line $line_number has an invalid normalized_capability: $normalized_capability"
  [[ $target_family == debian || $target_family == rhel ]] ||
    die "line $line_number has an invalid target_family: $target_family"
  [[ -n $rationale && $rationale != '-' ]] ||
    die "line $line_number must include a rationale"

  case "$parity_level" in
    unassessed | intent | package | behavioral) ;;
    *) die "line $line_number has an invalid parity_level: $parity_level" ;;
  esac

  is_terminal=false
  case "$disposition" in
    planned)
      planned_count=$((planned_count + 1))
      nonterminal_count=$((nonterminal_count + 1))
      ;;
    blocked-third-party)
      blocked_third_party_count=$((blocked_third_party_count + 1))
      nonterminal_count=$((nonterminal_count + 1))
      ;;
    implemented)
      implemented_count=$((implemented_count + 1))
      is_terminal=true
      terminal_count=$((terminal_count + 1))
      ;;
    superseded)
      superseded_count=$((superseded_count + 1))
      is_terminal=true
      terminal_count=$((terminal_count + 1))
      ;;
    retired)
      retired_count=$((retired_count + 1))
      is_terminal=true
      terminal_count=$((terminal_count + 1))
      ;;
    blocked-safety)
      blocked_safety_count=$((blocked_safety_count + 1))
      is_terminal=true
      terminal_count=$((terminal_count + 1))
      ;;
    out-of-scope)
      out_of_scope_count=$((out_of_scope_count + 1))
      is_terminal=true
      terminal_count=$((terminal_count + 1))
      ;;
    *) die "line $line_number has an invalid disposition: $disposition" ;;
  esac

  if [[ $disposition == planned ]]; then
    [[ $replacement != '-' && $parity_level != unassessed ]] ||
      die "line $line_number must classify an unmapped provider gap as blocked-third-party"
  elif [[ $disposition == blocked-third-party ]]; then
    [[ $replacement == '-' && $parity_level == unassessed ]] ||
      die "line $line_number cannot claim a replacement for an unresolved third-party provider"
  fi

  if [[ $disposition == implemented || $disposition == superseded ]]; then
    [[ $replacement != '-' ]] ||
      die "line $line_number requires a replacement for $disposition"
    [[ $parity_level != unassessed ]] ||
      die "line $line_number requires an assessed parity level for $disposition"
  fi

  if [[ $replacement != '-' ]]; then
    lsi_valid_slug "$replacement" ||
      die "line $line_number has an invalid replacement ID: $replacement"
    [[ -f $ROOT_DIR/modules/$replacement/module.sh ]] ||
      die "line $line_number references an unknown replacement module: $replacement"
    lsi_load_module "$replacement"
    lsi_module_supports_family "$target_family" ||
      die "line $line_number maps $replacement to unsupported family $target_family"
    [[ $parity_level != unassessed || $is_terminal == true ]] ||
      die "line $line_number has a candidate replacement without an assessed parity level"
  fi

  if [[ $is_terminal == true ]]; then
    [[ $evidence != '-' ]] ||
      die "line $line_number requires evidence for terminal disposition $disposition"
    if [[ $evidence == http://* ]]; then
      die "line $line_number uses an insecure evidence URL"
    elif [[ $evidence != https://* ]]; then
      evidence_path=${evidence%%#*}
      [[ $evidence_path == docs/* && -f $ROOT_DIR/$evidence_path ]] ||
        die "line $line_number references missing local evidence: $evidence"
    fi
  fi

  [[ -f $ROOT_DIR/$source_path ]] ||
    die "line $line_number references a missing source: $source_path"
  locator="$source_path#$source_item"
  [[ -z ${seen_locators[$locator]+x} ]] || die "duplicate source locator: $locator"
  seen_locators["$locator"]=1

  case "$source_set" in
    ubuntu)
      [[ $source_path == legacy/ubuntu-16.04/Ubuntu16-04-install-script.sh ]] ||
        die "line $line_number has an unexpected Ubuntu source path"
      [[ $target_family == debian ]] ||
        die "line $line_number must map the Ubuntu source to the Debian family"
      [[ $source_item =~ ^menu:([0-9]{3})$ ]] ||
        die "line $line_number has an invalid Ubuntu source_item: $source_item"
      choice_number=$((10#${BASH_REMATCH[1]}))
      ((choice_number >= 1 && choice_number <= EXPECTED_UBUNTU)) ||
        die "line $line_number has an out-of-range Ubuntu choice: $choice_number"
      printf -v expected_id 'ubuntu-%03d' "$choice_number"
      [[ $legacy_id == "$expected_id" ]] ||
        die "line $line_number uses $legacy_id; expected $expected_id"
      [[ -z ${seen_ubuntu_choices[$choice_number]+x} ]] ||
        die "duplicate Ubuntu menu choice: $choice_number"
      seen_ubuntu_choices["$choice_number"]=1
      ubuntu_count=$((ubuntu_count + 1))
      ;;
    rhel)
      [[ $source_path == legacy/rhel-family/*/scripts/*.sh ]] ||
        die "line $line_number has an unexpected RHEL source path: $source_path"
      [[ $source_item == script ]] ||
        die "line $line_number has an invalid RHEL source_item: $source_item"
      [[ $target_family == rhel ]] ||
        die "line $line_number must map the RHEL source to the RHEL family"
      [[ -n ${actual_rhel_sources[$source_path]+x} ]] ||
        die "line $line_number references a non-inventory RHEL script: $source_path"
      seen_rhel_sources["$source_path"]=1
      rhel_count=$((rhel_count + 1))
      ;;
    *) die "line $line_number has an invalid source_set: $source_set" ;;
  esac

  total_count=$((total_count + 1))
done < <(tail -n +2 "$INVENTORY")

[[ $ubuntu_count -eq $EXPECTED_UBUNTU ]] ||
  die "inventory has $ubuntu_count Ubuntu rows; expected $EXPECTED_UBUNTU"
[[ $rhel_count -eq $EXPECTED_RHEL ]] ||
  die "inventory has $rhel_count RHEL rows; expected $EXPECTED_RHEL"
[[ $total_count -eq $EXPECTED_TOTAL ]] ||
  die "inventory has $total_count total rows; expected $EXPECTED_TOTAL"

for ((expected = 1; expected <= EXPECTED_UBUNTU; expected++)); do
  [[ -n ${seen_ubuntu_choices[$expected]+x} ]] ||
    die "inventory is missing Ubuntu menu choice $expected"
done

for source_path in "${!actual_rhel_sources[@]}"; do
  [[ -n ${seen_rhel_sources[$source_path]+x} ]] ||
    die "inventory is missing RHEL script $source_path"
done

[[ $((terminal_count + nonterminal_count)) -eq $EXPECTED_TOTAL ]] ||
  die 'terminal and non-terminal disposition totals do not reconcile'
[[ $terminal_count -eq $EXPECTED_TERMINAL ]] ||
  die "inventory has $terminal_count terminal rows; expected $EXPECTED_TERMINAL"
[[ $nonterminal_count -eq $EXPECTED_NONTERMINAL ]] ||
  die "inventory has $nonterminal_count non-terminal rows; expected $EXPECTED_NONTERMINAL"
[[ $planned_count -eq $EXPECTED_PLANNED ]] ||
  die "inventory has $planned_count planned rows; expected $EXPECTED_PLANNED"
[[ $blocked_third_party_count -eq $EXPECTED_BLOCKED_THIRD_PARTY ]] ||
  die "inventory has $blocked_third_party_count blocked-third-party rows; expected $EXPECTED_BLOCKED_THIRD_PARTY"
[[ $implemented_count -eq $EXPECTED_IMPLEMENTED ]] ||
  die "inventory has $implemented_count implemented rows; expected $EXPECTED_IMPLEMENTED"
[[ $superseded_count -eq $EXPECTED_SUPERSEDED ]] ||
  die "inventory has $superseded_count superseded rows; expected $EXPECTED_SUPERSEDED"
[[ $retired_count -eq $EXPECTED_RETIRED ]] ||
  die "inventory has $retired_count retired rows; expected $EXPECTED_RETIRED"
[[ $blocked_safety_count -eq $EXPECTED_BLOCKED_SAFETY ]] ||
  die "inventory has $blocked_safety_count blocked-safety rows; expected $EXPECTED_BLOCKED_SAFETY"
[[ $out_of_scope_count -eq $EXPECTED_OUT_OF_SCOPE ]] ||
  die "inventory has $out_of_scope_count out-of-scope rows; expected $EXPECTED_OUT_OF_SCOPE"

printf 'Legacy inventory valid: %d Ubuntu choices + %d RHEL scripts = %d entries.\n' \
  "$ubuntu_count" "$rhel_count" "$total_count"
printf 'RHEL source capabilities: %d distinct filename-derived names.\n' \
  "${#actual_rhel_capabilities[@]}"
printf 'Disposition coverage: %d terminal, %d non-terminal (%d planned, %d blocked-third-party).\n' \
  "$terminal_count" "$nonterminal_count" "$planned_count" "$blocked_third_party_count"
printf 'Terminal dispositions: %d implemented, %d superseded, %d retired, %d blocked-safety, %d out-of-scope.\n' \
  "$implemented_count" "$superseded_count" "$retired_count" "$blocked_safety_count" "$out_of_scope_count"
printf 'Preserved source defects: %d exact launcher/menu mistakes.\n' "$defect_count"
