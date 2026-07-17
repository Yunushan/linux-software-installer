#!/usr/bin/env bash

MODULE_ID='override-outside-target'
MODULE_NAME='Out-of-target package override fixture'
MODULE_DESCRIPTION='Rejects package overrides that evade target restrictions'
MODULE_CATEGORY='test'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(git)
MODULE_TARGET_CELLS=(ubuntu:24.04:x86_64)
MODULE_TARGET_PACKAGE_OVERRIDES=(debian:12:x86_64=git-minimal)
MODULE_VERIFY_BINARIES=(git)
