#!/usr/bin/env bash
MODULE_ID='wrong-family'
MODULE_NAME='Wrong-family target fixture'
MODULE_DESCRIPTION='Target identity outside declared package family'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(git)
MODULE_VERIFY_BINARIES=(git)
MODULE_TARGET_CELLS=(rocky:9.5:x86_64)
