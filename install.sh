#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
umask 022
export LC_ALL=C
export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'

ROOT_DIR=$(/usr/bin/readlink -f -- "${BASH_SOURCE[0]}")
ROOT_DIR=${ROOT_DIR%/*}

case "${1:-}" in
  migrations | migrate)
    # Migration guidance parses fixed local ledgers in a clean child process;
    # it never runs a legacy script or invokes a package manager.
    /usr/bin/env -i \
      PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
      LC_ALL=C \
      /usr/bin/bash "$ROOT_DIR/bin/linux-software-installer" "$@"
    ;;
  providers | provider-info | provider-plan)
    # Provider parsing runs in a clean child process so caller-controlled
    # Bash functions, BASH_ENV, TMPDIR, and installer test hooks cannot cross
    # the public command boundary.
    /usr/bin/env -i \
      PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' \
      LC_ALL=C \
      /usr/bin/bash "$ROOT_DIR/bin/provider-catalog" "$@"
    ;;
  help | --help | -h)
    "$ROOT_DIR/bin/linux-software-installer" "$@"
    printf '\n%s\n' 'Read-only provider catalog commands:' \
      '  ./install.sh providers' \
      '  ./install.sh provider-info PROVIDER' \
      '  ./install.sh provider-plan PROVIDER --allow-provider PROVIDER@CATALOG_REVISION [ACK...] MODULE...'
    exit 0
    ;;
  *)
    exec "$ROOT_DIR/bin/linux-software-installer" "$@"
    ;;
esac
