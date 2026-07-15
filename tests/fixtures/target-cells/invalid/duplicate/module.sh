#!/usr/bin/env bash
MODULE_ID='duplicate'
MODULE_NAME='Duplicate target fixture'
MODULE_DESCRIPTION='Duplicate exact target cell'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(git)
MODULE_VERIFY_BINARIES=(git)
MODULE_TARGET_CELLS=(ubuntu:24.04:x86_64 ubuntu:24.04:x86_64)
