#!/usr/bin/env bash
MODULE_ID='family-wide'
MODULE_NAME='Family-wide fixture'
MODULE_DESCRIPTION='Fixture retaining the default family-wide policy'
MODULE_CATEGORY='test'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(git)
MODULE_RHEL_PACKAGES=(git)
MODULE_VERIFY_BINARIES=(git)
