#!/usr/bin/env bash
MODULE_ID='timeshift'
MODULE_NAME='Timeshift'
MODULE_DESCRIPTION='System snapshot and restore utility'
MODULE_CATEGORY='utility'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(timeshift)
MODULE_VERIFY_BINARIES=(timeshift)
MODULE_NOTES='Installs the tool only; it does not create, schedule or restore snapshots.'
