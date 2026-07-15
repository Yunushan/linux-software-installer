#!/usr/bin/env bash
MODULE_ID='playonlinux'
MODULE_NAME='PlayOnLinux'
MODULE_DESCRIPTION='Graphical Wine front-end from Ubuntu repositories'
MODULE_CATEGORY='desktop'
MODULE_STATUS='stable'
MODULE_RISK='low'
MODULE_NOTES='Applications selected inside PlayOnLinux may require additional downloads.'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(playonlinux)
MODULE_VERIFY_BINARIES=(playonlinux)
MODULE_TARGET_CELLS=(ubuntu:24.04:x86_64)
