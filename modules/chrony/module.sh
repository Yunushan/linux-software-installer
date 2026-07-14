#!/usr/bin/env bash
MODULE_ID='chrony'
MODULE_NAME='Chrony'
MODULE_DESCRIPTION='Network time synchronization service'
MODULE_CATEGORY='server'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(chrony)
MODULE_RHEL_PACKAGES=(chrony)
MODULE_DEBIAN_SERVICES=(chrony)
MODULE_RHEL_SERVICES=(chronyd)
MODULE_VERIFY_BINARIES=(chronyc)
