#!/usr/bin/env bash
MODULE_ID='wget'
MODULE_NAME='GNU Wget'
MODULE_DESCRIPTION='Non-interactive network downloader'
MODULE_CATEGORY='utility'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(wget ca-certificates)
MODULE_RHEL_PACKAGES=(wget ca-certificates)
MODULE_VERIFY_BINARIES=(wget)
