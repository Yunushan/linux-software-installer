#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
BACKLOG="$ROOT_DIR/docs/provider-backlog.tsv"
EMIT=false

case "${1:-}" in
  '') ;;
  --emit) EMIT=true ;;
  *)
    printf 'Usage: %s [--emit]\n' "$0" >&2
    exit 2
    ;;
esac

declare -A audit_documents=(
  [epel]="$ROOT_DIR/docs/EPEL_AUDIT.md"
  [rpm_fusion]="$ROOT_DIR/docs/RPM_FUSION_AUDIT.md"
  [snap]="$ROOT_DIR/docs/SNAP_PROVIDER_AUDIT.md"
  [public_artifact]="$ROOT_DIR/docs/PUBLIC_ARTIFACT_PROVIDER_AUDIT.md"
  [jenkins]="$ROOT_DIR/docs/JENKINS_PROVIDER_AUDIT.md"
  [anydesk]="$ROOT_DIR/docs/ANYDESK_PROVIDER_AUDIT.md"
  [kubectl]="$ROOT_DIR/docs/KUBECTL_PROVIDER_AUDIT.md"
  [vscode]="$ROOT_DIR/docs/VSCODE_PROVIDER_AUDIT.md"
  [vendor_apt]="$ROOT_DIR/docs/VENDOR_REPOSITORY_PROVIDER_AUDIT.md"
)

declare -A expected_counts=(
  [epel]=35
  [rpm_fusion]=10
  [snap]=25
  [public_artifact]=15
  [jenkins]=5
  [anydesk]=2
  [kubectl]=3
  [vscode]=2
  [vendor_apt]=5
)

die() {
  printf 'provider audit coverage validation failed: %s\n' "$*" >&2
  exit 1
}

[[ -r $BACKLOG ]] || die "cannot read $BACKLOG"
for document in "${audit_documents[@]}"; do
  [[ -s $document ]] || die "missing or empty audit document: $document"
done

declare -A actual_counts=()
declare -a audit_rows=()
total=0

while IFS=$'\t' read -r legacy_id capability strategy action outcome rationale; do
  [[ $legacy_id == legacy_id ]] && continue
  group=
  case "$strategy:$capability" in
    epel-package:*) group=epel ;;
    rpm-fusion:*) group=rpm_fusion ;;
    snap-bootstrap:* | snap-store:*) group=snap ;;
    public-artifact:*) group=public_artifact ;;
    vendor-apt:jenkins | vendor-rpm:jenkins) group=jenkins ;;
    vendor-apt:anydesk | vendor-rpm:anydesk) group=anydesk ;;
    vendor-apt:kubectl | vendor-rpm:kubectl) group=kubectl ;;
    vendor-apt:visual-studio-code | vendor-rpm:visual-studio-code) group=vscode ;;
    vendor-apt:sublime-text-3 | vendor-apt:brave | vendor-apt:vivaldi | vendor-apt:google-chrome | vendor-apt:pgadmin)
      group=vendor_apt
      ;;
    *) die "no audit group for $legacy_id ($strategy/$capability)" ;;
  esac
  case "$group" in
    jenkins | anydesk | kubectl | vscode | vendor_apt | public_artifact)
      document=${audit_documents[$group]}
      grep -Fq "\`$legacy_id\`" "$document" ||
        die "$legacy_id is not explicitly named in $document"
      ;;
  esac
  audit_rows+=("$legacy_id"$'\t'"$group"$'\t'"${audit_documents[$group]#"$ROOT_DIR/"}")
  actual_counts["$group"]=$(( ${actual_counts[$group]:-0} + 1 ))
  total=$((total + 1))
done < "$BACKLOG"

for group in "${!expected_counts[@]}"; do
  actual=${actual_counts[$group]:-0}
  expected=${expected_counts[$group]}
  [[ $actual -eq $expected ]] ||
    die "$group has $actual covered rows; expected $expected"
done

[[ $total -eq 102 ]] || die "backlog has $total rows; expected 102"

if [[ $EMIT == true ]]; then
  printf 'legacy_id\taudit_group\taudit_document\n'
  printf '%s\n' "${audit_rows[@]}" | LC_ALL=C sort
  exit 0
fi

printf 'Provider audit coverage valid: %d unresolved routes mapped to %d audit documents.\n' \
  "$total" "${#audit_documents[@]}"
