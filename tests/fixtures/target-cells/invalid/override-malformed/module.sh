#!/usr/bin/env bash

MODULE_ID='override-malformed'
MODULE_NAME='Malformed package override fixture'
MODULE_DESCRIPTION='Rejects package overrides with multiple separators'
MODULE_CATEGORY='test'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(git)
MODULE_TARGET_PACKAGE_OVERRIDES=(ubuntu:24.04:x86_64=git=git-minimal)
MODULE_VERIFY_BINARIES=(git)
