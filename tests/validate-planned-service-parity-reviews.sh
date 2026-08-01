#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
READINESS="$ROOT_DIR/docs/legacy-promotion-readiness.tsv"
INVENTORY="$ROOT_DIR/docs/legacy-inventory.tsv"

[[ -f $READINESS && ! -L $READINESS ]] || {
  printf 'missing or unsafe promotion readiness ledger\n' >&2
  exit 1
}
[[ -f $INVENTORY && ! -L $INVENTORY ]] || {
  printf 'missing or unsafe legacy inventory\n' >&2
  exit 1
}

declare -A source_locators=()
while IFS=$'\t' read -r inventory_legacy_id source_set source_path source_item rest; do
  [[ $inventory_legacy_id == legacy_id ]] && continue
  source_locators["$inventory_legacy_id"]="$source_path#$source_item"
done < "$INVENTORY"

count=0
while IFS=$'\t' read -r legacy_id evidence_key service_contract promotion_ready; do
  [[ $legacy_id != legacy_id ]] || continue
  [[ $service_contract == yes && $promotion_ready == no ]] || continue
  family=${evidence_key%%/*}
  module=${evidence_key#*/}
  review="$ROOT_DIR/docs/parity-reviews/$family-$module.md"
  verification="$ROOT_DIR/docs/evidence-verification/$family-$module.json"
  [[ -f $review && ! -L $review ]] || {
    printf 'missing pre-admission service parity review: %s\n' "$evidence_key" >&2
    exit 1
  }
  grep -Fqx "# Pre-admission parity review: \`$evidence_key\`" "$review" || {
    printf 'parity review has an unexpected title: %s\n' "$review" >&2
    exit 1
  }
  grep -Fq 'Admission status: **pending disposable-VM/systemd attestation**' "$review" || {
    printf 'parity review does not preserve the pending VM-evidence boundary: %s\n' "$review" >&2
    exit 1
  }
  grep -Fq "\`$legacy_id\`" "$review" || {
    printf 'parity review does not explicitly name planned legacy row %s: %s\n' \
      "$legacy_id" "$review" >&2
    exit 1
  }
  source_locator=${source_locators[$legacy_id]:-}
  [[ -n $source_locator ]] || {
    printf 'planned legacy row is missing from the immutable inventory: %s\n' "$legacy_id" >&2
    exit 1
  }
  grep -Fq "\`$source_locator\`" "$review" || {
    printf 'parity review does not contain the immutable source locator for %s: %s\n' \
      "$legacy_id" "$review" >&2
    exit 1
  }
  [[ -f $verification && ! -L $verification ]] || {
    printf 'missing stored evidence-verification report: %s\n' "$verification" >&2
    exit 1
  }
  grep -Fq "\"module\": \"$module\"" "$verification" || {
    printf 'evidence-verification report has a mismatched module: %s\n' "$verification" >&2
    exit 1
  }
  grep -Fq '"result": "verified-awaiting-parity-review-and-systemd-attestation"' "$verification" || {
    printf 'evidence-verification report does not preserve pending service attestation: %s\n' \
      "$verification" >&2
    exit 1
  }
  ((count += 1))
done < <(awk -F '\t' 'NR == 1 { next } { print $1 "\t" $4 "\t" $8 "\t" $12 }' "$READINESS")

[[ $count -eq 37 ]] || {
  printf 'expected 37 planned service rows with parity reviews, found %s\n' "$count" >&2
  exit 1
}

printf 'Pending service parity reviews valid: %s planned rows across 14 exact module-family contracts.\n' "$count"
