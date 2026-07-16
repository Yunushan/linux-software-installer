#!/usr/bin/env bash

# A command name alone is insufficient on Windows hosts: the Microsoft Store
# python3 app-execution alias can be present but exits unsuccessfully. The
# evidence tools require a usable, POSIX Python 3 standard-library interpreter.
# Their no-follow filesystem checks are security controls and must not be
# silently weakened on a host whose Python cannot provide os.O_NOFOLLOW.
lsi_find_python() {
  local candidate
  for candidate in python3 python /usr/libexec/platform-python; do
    command -v "$candidate" > /dev/null 2>&1 || continue
    if "$candidate" -B -c \
      'import os, sys; raise SystemExit(0 if sys.version_info >= (3, 8) and os.name == "posix" and hasattr(os, "O_NOFOLLOW") else 1)' \
      > /dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}
