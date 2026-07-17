#!/usr/bin/env bash

MODULE_ID='override-duplicate'
MODULE_NAME='Duplicate package override fixture'
MODULE_DESCRIPTION='Rejects more than one package override for a target'
MODULE_CATEGORY='test'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(git)
MODULE_TARGET_PACKAGE_OVERRIDES=(
  ubuntu:24.04:x86_64=git-minimal
  ubuntu:24.04:x86_64=git
)
MODULE_VERIFY_BINARIES=(git)
