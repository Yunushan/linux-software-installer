#!/usr/bin/env bash
MODULE_ID='docker'
MODULE_NAME='Docker Engine (distribution package)'
MODULE_DESCRIPTION='Docker engine packaged by Debian or Ubuntu'
MODULE_CATEGORY='container'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(docker.io)
MODULE_DEBIAN_SERVICES=(docker)
MODULE_VERIFY_BINARIES=(docker)
MODULE_NOTES='This module does not add Docker third-party repositories. RHEL-family users should choose podman.'
