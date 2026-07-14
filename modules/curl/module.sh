#!/usr/bin/env bash
MODULE_ID='curl'
MODULE_NAME='curl'
MODULE_DESCRIPTION='Command-line URL transfer client'
MODULE_CATEGORY='utility'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(curl ca-certificates)
MODULE_RHEL_PACKAGES=(curl ca-certificates)
MODULE_VERIFY_BINARIES=(curl)
