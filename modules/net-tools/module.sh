#!/usr/bin/env bash
MODULE_ID='net-tools'
MODULE_NAME='Legacy network tools'
MODULE_DESCRIPTION='ifconfig, netstat and related compatibility utilities'
MODULE_CATEGORY='diagnostic'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(net-tools)
MODULE_RHEL_PACKAGES=(net-tools)
MODULE_VERIFY_BINARIES=(ifconfig netstat)
