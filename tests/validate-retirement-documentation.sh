#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
INVENTORY="$ROOT_DIR/docs/legacy-inventory.tsv"
MIGRATION="$ROOT_DIR/docs/MIGRATION.md"
REPLACEMENT="$ROOT_DIR/docs/REPLACEMENT.md"

die() {
  printf 'retirement documentation validation failed: %s\n' "$*" >&2
  exit 1
}

[[ -f $INVENTORY && ! -L $INVENTORY ]] || die 'missing or unsafe legacy inventory'
[[ -f $MIGRATION && ! -L $MIGRATION ]] || die 'missing or unsafe migration documentation'
[[ -f $REPLACEMENT && ! -L $REPLACEMENT ]] || die 'missing or unsafe replacement documentation'

read -r total terminal planned blocked implemented superseded retired safety handoff < <(
  awk -F '\t' '
    NR > 1 {
      total += 1
      if ($8 == "planned") planned += 1
      else if ($8 == "blocked-third-party") blocked += 1
      else if ($8 == "implemented") { implemented += 1; terminal += 1 }
      else if ($8 == "superseded") { superseded += 1; terminal += 1 }
      else if ($8 == "retired") { retired += 1; terminal += 1 }
      else if ($8 == "blocked-safety") { safety += 1; terminal += 1 }
      else if ($8 == "out-of-scope") { handoff += 1; terminal += 1 }
    }
    END { print total, terminal, planned, blocked, implemented, superseded, retired, safety, handoff }
  ' "$INVENTORY"
)
nonterminal=$((planned + blocked))
[[ $((terminal + nonterminal)) -eq $total ]] || die 'inventory counts do not reconcile'

grep -Fq "The current immutable denominator is $total entries: $planned provisional active-module" "$MIGRATION" ||
  die 'MIGRATION.md denominator or planned total is stale'
grep -Fq "candidates, $blocked unresolved third-party routes and $terminal terminal dispositions." "$MIGRATION" ||
  die 'MIGRATION.md blocked or terminal total is stale'

grep -Fq "The current inventory snapshot has $terminal terminal rows: $implemented" "$REPLACEMENT" ||
  die 'REPLACEMENT.md terminal total is stale'
grep -Fq "remaining $nonterminal rows are non-terminal: $planned" "$REPLACEMENT" ||
  die 'REPLACEMENT.md non-terminal or planned total is stale'
grep -Fq "$blocked \`blocked-third-party\`" "$REPLACEMENT" ||
  die 'REPLACEMENT.md blocked-third-party total is stale'
grep -Fq "$handoff \`out-of-scope\`" "$REPLACEMENT" ||
  die 'REPLACEMENT.md out-of-scope total is stale'
grep -Fq "remaining $planned planned rows" "$REPLACEMENT" ||
  die 'REPLACEMENT.md planned closure total is stale'

terminal_reviewed=0
while IFS=$'\t' read -r legacy_id source_set source_path source_item display_name \
  capability family disposition replacement parity evidence rationale; do
  [[ $legacy_id == legacy_id ]] && continue
  case "$disposition" in
    retired | blocked-safety | out-of-scope) ;;
    *) continue ;;
  esac
  evidence_file=${evidence%%#*}
  [[ $evidence_file == docs/LEGACY_DISPOSITIONS.md ]] ||
    die "$legacy_id terminal disposition does not cite the reviewed disposition record"
  grep -Fq "\`$legacy_id\`" "$ROOT_DIR/$evidence_file" ||
    die "$legacy_id is not explicitly named in its terminal disposition record"
  ((terminal_reviewed += 1))
done < "$INVENTORY"

[[ $terminal_reviewed -eq $((retired + safety + handoff)) ]] ||
  die 'terminal disposition review coverage does not match inventory counts'

printf 'Retirement documentation valid: %d total, %d terminal, %d planned, %d unresolved.\n' \
  "$total" "$terminal" "$planned" "$blocked"
printf 'Terminal disposition evidence valid: %d reviewed retirement, safety, or handoff rows.\n' \
  "$terminal_reviewed"
