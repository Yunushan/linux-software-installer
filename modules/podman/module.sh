#!/usr/bin/env bash
MODULE_ID='podman'
MODULE_NAME='Podman'
MODULE_DESCRIPTION='Daemonless OCI container engine'
MODULE_CATEGORY='container'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(podman)
MODULE_RHEL_PACKAGES=(podman)
MODULE_VERIFY_BINARIES=(podman)
