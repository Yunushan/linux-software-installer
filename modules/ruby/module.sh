#!/usr/bin/env bash
MODULE_ID='ruby'
MODULE_NAME='Ruby'
MODULE_DESCRIPTION='Distribution-provided Ruby language runtime and tools'
MODULE_CATEGORY='developer'
MODULE_FAMILIES=(debian rhel)
MODULE_DEBIAN_PACKAGES=(ruby-full)
MODULE_RHEL_PACKAGES=(ruby rubygems)
MODULE_VERIFY_BINARIES=(ruby gem)
MODULE_NOTES='Installs the maintained distribution release instead of compiling a pinned legacy version.'
