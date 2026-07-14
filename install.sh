#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
exec "$ROOT_DIR/bin/linux-software-installer" "$@"
