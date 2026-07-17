#!/usr/bin/env bash

MODULE_ID='override-unsafe'
MODULE_NAME='Unsafe package override fixture'
MODULE_DESCRIPTION='Rejects unsafe package names in target overrides'
MODULE_CATEGORY='test'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(git)
MODULE_TARGET_PACKAGE_OVERRIDES=('ubuntu:24.04:x86_64=git;curl')
MODULE_VERIFY_BINARIES=(git)
