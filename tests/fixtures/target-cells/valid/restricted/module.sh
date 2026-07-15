#!/usr/bin/env bash
MODULE_ID='restricted'
MODULE_NAME='Restricted fixture'
MODULE_DESCRIPTION='Fixture restricted to one exact Ubuntu cell'
MODULE_CATEGORY='test'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(git)
MODULE_VERIFY_BINARIES=(git)
MODULE_TARGET_CELLS=(ubuntu:24.04:x86_64)
