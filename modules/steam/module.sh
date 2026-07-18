#!/usr/bin/env bash
MODULE_ID='steam'
MODULE_NAME='Steam'
MODULE_DESCRIPTION='Steam client installer from Ubuntu repositories'
MODULE_CATEGORY='desktop'
MODULE_STATUS='stable'
MODULE_RISK='medium'
MODULE_NOTES='Requires explicit i386 multiarch acknowledgement; game content and account sign-in remain Steam-managed.'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(steam-installer)
MODULE_DEBIAN_FOREIGN_ARCHITECTURES=(i386)
MODULE_VERIFY_BINARIES=(steam)
MODULE_TARGET_CELLS=(ubuntu:24.04:x86_64)
