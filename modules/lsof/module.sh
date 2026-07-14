#!/usr/bin/env bash
MODULE_ID='lsof'
MODULE_NAME='lsof'
MODULE_DESCRIPTION='List open files and network sockets'
MODULE_CATEGORY='diagnostic'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(lsof)
MODULE_RHEL_PACKAGES=(lsof)
MODULE_VERIFY_BINARIES=(lsof)
