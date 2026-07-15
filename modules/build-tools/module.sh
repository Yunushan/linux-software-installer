#!/usr/bin/env bash
MODULE_ID='build-tools'
MODULE_NAME='Native build toolchain'
MODULE_DESCRIPTION='Compiler, build utility, CMake and pkg-config'
MODULE_CATEGORY='developer'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(build-essential cmake pkg-config)
MODULE_RHEL_PACKAGES=(gcc gcc-c++ make cmake pkgconf-pkg-config)
MODULE_VERIFY_BINARIES=(gcc g++ make cmake pkg-config)
