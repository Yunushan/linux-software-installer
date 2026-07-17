#!/usr/bin/env bash
MODULE_ID='overridden'
MODULE_NAME='Target package override fixture'
MODULE_DESCRIPTION='Uses a different package on an exact supported target'
MODULE_CATEGORY='test'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(git)
MODULE_TARGET_PACKAGE_OVERRIDES=(ubuntu:24.04:x86_64=git-minimal)
MODULE_VERIFY_BINARIES=(git)
