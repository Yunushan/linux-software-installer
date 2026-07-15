#!/usr/bin/env bash
MODULE_ID='unlisted'
MODULE_NAME='Unlisted target fixture'
MODULE_DESCRIPTION='Valid exact cell absent from the evidence target table'
MODULE_CATEGORY='test'
MODULE_FAMILIES=(debian)
MODULE_DEBIAN_PACKAGES=(git)
MODULE_VERIFY_BINARIES=(git)
MODULE_TARGET_CELLS=(ubuntu:22.04:x86_64)
