#!/usr/bin/env bash
MODULE_ID='malformed'
MODULE_NAME='Malformed target fixture'
MODULE_DESCRIPTION='Invalid target-cell shape'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(git)
MODULE_VERIFY_BINARIES=(git)
MODULE_TARGET_CELLS=(ubuntu:24.04)
