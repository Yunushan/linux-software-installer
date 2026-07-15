#!/usr/bin/env bash
set -Eeuo pipefail

container_name=${1:-}
[[ $container_name =~ ^lsi-[a-z0-9-]+$ ]] || {
  printf 'Invalid evidence container name: %s\n' "${container_name:-missing}" >&2
  exit 2
}
command -v docker > /dev/null 2>&1 || {
  printf 'docker is required to remove an evidence container.\n' >&2
  exit 2
}
command -v timeout > /dev/null 2>&1 || {
  printf 'timeout is required to remove an evidence container.\n' >&2
  exit 2
}

if docker container inspect "$container_name" > /dev/null 2>&1; then
  timeout --signal=TERM --kill-after=10s 2m \
    docker rm -f "$container_name" > /dev/null || {
    printf 'Failed to remove evidence container: %s\n' "$container_name" >&2
    exit 1
  }
fi

remaining=$(docker container ls -aq --filter "name=^/${container_name}$") || {
  printf 'Could not verify evidence container absence: %s\n' "$container_name" >&2
  exit 1
}
[[ -z $remaining ]] || {
  printf 'Evidence container is still present: %s\n' "$container_name" >&2
  exit 1
}
