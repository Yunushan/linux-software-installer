#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
INVENTORY="$ROOT_DIR/docs/legacy-inventory.tsv"

die() {
  printf 'admitted parity review validation failed: %s\n' "$*" >&2
  exit 1
}

[[ -f $INVENTORY && ! -L $INVENTORY ]] || die 'missing or unsafe legacy inventory'

count=0
while IFS=$'\t' read -r legacy_id source_set source_path source_item display_name \
  capability family disposition replacement parity evidence rationale; do
  [[ $legacy_id == legacy_id ]] && continue
  case "$disposition" in
    implemented | superseded) ;;
    *) continue ;;
  esac
  review="$ROOT_DIR/docs/parity-reviews/$family-$replacement.md"
  [[ -f $review && ! -L $review ]] ||
    die "$legacy_id is missing its admitted parity review: $review"
  grep -Fq "\`$legacy_id\`" "$review" ||
    die "$legacy_id is not explicitly named in $review"
  grep -Fq "$source_path" "$review" ||
    die "$legacy_id source path is not explicitly named in $review"
  ((count += 1))
done < "$INVENTORY"

[[ $count -gt 0 ]] || die 'no admitted legacy rows were checked'
printf 'Admitted parity reviews valid: %d implemented or superseded legacy rows.\n' "$count"
