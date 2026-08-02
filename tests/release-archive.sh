#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
export LC_ALL=C

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
VERSION=$(tr -d '\r\n' < "$ROOT_DIR/VERSION")

[[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  printf 'VERSION is not a semantic release version: %s\n' "$VERSION" >&2
  exit 1
}

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/lsi-release-archive.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT

archive="$tmp_dir/linux-software-installer-$VERSION.tar.gz"
archive_repeat="$tmp_dir/linux-software-installer-$VERSION-repeat.tar.gz"
prefix="linux-software-installer-$VERSION/"

build_archive() {
  local destination=$1
  git -C "$ROOT_DIR" archive --format=tar --prefix="$prefix" HEAD |
    gzip -n > "$destination"
}

build_archive "$archive"
build_archive "$archive_repeat"

first_hash=$(sha256sum "$archive" | awk '{print $1}')
repeat_hash=$(sha256sum "$archive_repeat" | awk '{print $1}')
[[ $first_hash == "$repeat_hash" ]] || {
  printf 'release archive is not deterministic: %s != %s\n' \
    "$first_hash" "$repeat_hash" >&2
  exit 1
}

tar -tzf "$archive" > "$tmp_dir/contents.txt"
for required in LICENSE README.md VERSION; do
  grep -Fqx "$prefix$required" "$tmp_dir/contents.txt" || {
    printf 'release archive is missing required file: %s\n' "$required" >&2
    exit 1
  }
done

if grep -Eq '(^|/)\.git(/|$)' "$tmp_dir/contents.txt"; then
  printf 'release archive unexpectedly contains a .git tree\n' >&2
  exit 1
fi

printf 'Release archive reproducibility valid: sha256=%s\n' "$first_hash"
