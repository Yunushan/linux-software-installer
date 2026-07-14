#!/usr/bin/env bash
MODULE_ID='base-tools'
MODULE_NAME='Base command-line tools'
MODULE_DESCRIPTION='Common download, archive, JSON and synchronization utilities'
MODULE_CATEGORY='utility'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(ca-certificates curl wget gnupg jq unzip zip rsync tar)
MODULE_RHEL_PACKAGES=(ca-certificates curl wget gnupg2 jq unzip zip rsync tar)
MODULE_VERIFY_BINARIES=(curl wget jq unzip rsync)
